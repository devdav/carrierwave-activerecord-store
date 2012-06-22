module CarrierWave
  module Storage

    ##
    # ActiveRecord storage stores file to the database.
    #
    class ActiveRecord < Abstract

      # HACK get rid of this
      attr_accessor :skip_callback

      ##
      # Store a file
      #
      # === Parameters
      #
      # [file (CarrierWave::SanitizedFile)] the file to store
      #
      # === Returns
      #
      # [bool] success
      #
      def store!(file)
        if self.skip_callback.blank?
          self.skip_callback = true
          model = uploader.model

          # fields added to model via migration
          # TODO make these fields configurable
          model.original_filename = file.original_filename # string
          model.content_type = file.content_type # string
          model.content = file.read # binary
          model.file_size = file.size # integer

          model.save!
        end
        true
      end

      ##
      # Retrieve a file
      #
      # === Parameters
      #
      # [identifier (String)] unique identifier for file (ignored)
      #
      # === Returns
      #
      # [CarrierWave::SanitizedFile] the stored file
      #
      def retrieve!(identifier = nil)
        # use StringIO to act as a File-like object
        CarrierWave::SanitizedFile.new(StringIO.new(uploader.model.content))
      end

    end # ActiveRecord
  end # Storage
end # CarrierWave
