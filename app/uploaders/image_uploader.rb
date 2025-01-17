# frozen_string_literal: true

class ImageUploader < CarrierWave::Uploader::Base
  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/images/#{model.class.to_s.underscore}/#{model.id}/#{mounted_as}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.
  #       asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  process resize_to_limit: [1920, 1080]

  # Create different versions of your uploaded files:
  version :thumb do
    process resize_to_fit: [50, 50]
  end

  version :small do
    process resize_to_fit: [100, 100]
  end

  version :medium do
    process resize_to_fit: [200, 200]
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_whitelist
    %w[jpg jpeg gif png]
  end

  # Duplicate the image from the other uploader. Handles
  # both file storage and URL storage.
  #
  # @return [Boolean] Boolean on whether the duplication is successful.
  def duplicate_from(other_uploader)
    case other_uploader.send(:storage).class.name
    when 'CarrierWave::Storage::File'
      begin
        cache!(File.new(other_uploader.file.path))
      rescue Errno::ENOENT
        return false
      end
    when 'CarrierWave::Storage::Fog', 'CarrierWave::Storage::AWS'
      begin
        download!(other_uploader.url)
      rescue StandardError => _e
        begin
          download!(other_uploader.medium.url)
        rescue StandardError => _e
          return false
        end
      end
    end
    true
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end
end
