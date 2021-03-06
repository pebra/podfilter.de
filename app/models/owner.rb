class Owner < ActiveRecord::Base
  has_many :opml_files
  mount_uploader :image, ImageUploader
  validate :only_100_owners_per_hour

  before_validation do
    self.token ||= SecureRandom.hex(64)
    if self.image.blank?
      self.image = RandomImageGenerator.generate(token)
    end
  end

  before_create :randomize_id

  private
  def only_100_owners_per_hour
    if Owner.where('created_at > ?', 1.hour.ago).count > 100
      errors.add(:base, 'es wurden schon zuviele neue Nutzer in der letzten Zeit angelegt. Bitte probiere es spaeter noch einmal')
    end
  end
  def randomize_id
    begin
      self.id = SecureRandom.random_number(1_000_000_000)
    end while OpmlFile.where(:id => self.id).exists?
  end

end
