require 'file_mime_type_validator'
class Source < ActiveRecord::Base
  has_and_belongs_to_many :opml_files
  has_many :owners, through: :opml_files
  has_many :episodes, dependent: :destroy
  mount_uploader :image, ImageUploader

  def self.active
    source_id = Episode.connection.execute(
      Episode.select('distinct source_id').
      where('pubdate > ?', 1.year.ago).to_sql
    ).to_a.map{|i| i['source_id']}
    where(id: source_id)
  end


  validates :url, presence: true, uniqueness: true, url: true
  validates :image,
    :file_mime_type => {
    :content_type => /image/
  }, if: ->(r) { r.image.present? and r.image_changed? }

  scope :recent, -> {
    active.
    listened.
    joins(:episodes).
    where('episodes.id = (select episodes.id from episodes where episodes.source_id = sources.id and pubdate is not null order by pubdate desc limit 1)').
    select('sources.*, episodes.id as episode_id, episodes.pubdate as pubdate').
    where('episodes.pubdate < ?', Time.zone.now).
    order('episodes.pubdate desc')
  }
  scope :error, -> { where('description is null and (offline is null or offline != ?)', true) }
  scope :offline,-> { where(offline: true) }
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :listened, -> { where("(select source_id from opml_files_sources where opml_files_sources.source_id = sources.id limit 1) is not null") }


  scope :inactive_live, -> { where(id: Episode.select('source_id').having('max(pubdate) <= ?', 1.year.ago).group(:source_id)) }
  scope :active_live,   -> { where(id: Episode.select('distinct source_id').where('pubdate > ?', 1.year.ago)) }

  def self.update_active_status
    active_live.update_all active: true
    inactive_live.update_all active: false
  end

  def full_refresh
    if parsed_feed.is_a?(Fixnum) or (parsed_feed.title.blank? and parsed_feed.entries.count == 0)
      self.update_attribute :offline, true
    else
      fetch_meta_information
      update_entries
    end
  end

  def self.enqueue
    pluck(:id).each do |id|
      SourceUpdateWorker.perform_async(id)
    end
  end

  def fetch_meta_information
    self.title = parsed_feed.title if parsed_feed.title
    self.description = take_first(parsed_feed, [:itunes_summary, :description, :title]).strip rescue nil
    # self.language ||= feed.language
    #itunes_categories
    image = take_first(parsed_feed, [:itunes_image, :image])
    self.remote_image_url = image if image
    self.offline = false

    if !self.save
      self.image = nil
      self.remote_image_url = nil
      self.image.remove!
      self.save!
    end
  end

  def parsed_feed
    Feedzirra::Feed.add_common_feed_element :"itunes:image", :value => :href, :as => :itunes_image
    Feedzirra::Feed.add_common_feed_element :"itunes:summary", :as => :itunes_summary
    Feedzirra::Feed.add_common_feed_element :"itunes:category", :as => :itunes_categories, :value => :text
    Feedzirra::Feed.add_common_feed_element "url", :as => :image

    @parse_feed ||=  Feedzirra::Feed.fetch_and_parse(url)
  end

  def update_entries
    parsed_feed.entries.each do |entry|
      guid = entry.respond_to?(:entry_id) ? entry.entry_id : entry.guid
      episode = episodes.where(guid: guid).first_or_initialize
      episode.title = entry.title
      episode.url   = entry.url
      episode.description = entry.summary
      episode.pubdate = entry.published
      episode.save
    end

  end

  def to_param
    "#{id}-#{title.to_url}"
  end

  private

  def take_first(object, methods)
    methods.select{|m| object.respond_to?(m)}.
      map{|m| object.send(m) }.
      find{|i|i}
  end
end
