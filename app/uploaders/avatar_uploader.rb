class WebAvatarUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  storage :fog
  process convert: 'jpg'

  def store_dir
    "a/#{id_partition}"
  end

  def default_url
    '/assets/avatar/default/:style.png'.gsub(':style', (version_name || :m).to_s)
  end

  version :xs do
    process resize_to_fill: [75,   75]
    process convert: 'jpg'
    def full_filename(for_file = model.avatar.file) 'xs.jpg' end     
  end
  version :s  do
    process resize_to_fill: [90,   90]
    process convert: 'jpg'
    def full_filename(for_file = model.avatar.file)  's.jpg' end     
  end
  version :m  do
    process resize_to_fill: [150, 150]
    process convert: 'jpg'
    def full_filename(for_file = model.avatar.file)  'm.jpg' end     
  end
  version :l  do
    process resize_to_fill: [320, 320]
    process convert: 'jpg'
    def full_filename(for_file = model.avatar.file)  'l.jpg' end     
  end

  def filename    
    "original.#{model.avatar.file.extension}" if original_filename
  end

  def extension_white_list
    %w(jpg jpeg gif png)
  end

  def id_partition
    ("%09d" % model.id.to_i).scan(/\d{3}/).join("/")
  end

end
