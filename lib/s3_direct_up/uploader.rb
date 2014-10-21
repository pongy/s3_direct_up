require 'active_support/core_ext/numeric/bytes'

module S3DirectUp
  class Uploader
    DefaultOptions={
        expiration: 3600,
        min_file_size: 1,
        max_file_size: 10.megabytes
    }

    attr_reader :options, :uploader

    def initialize(uploader=nil, options={})
      @uploader=uploader||CarrierWave::Uploader::Base
      @options=DefaultOptions.merge(options)
    end

    def get_fog_storage
      @fog_storage||=Fog::Storage.new(@uploader.fog_credentials)
    end

    def get_bucket
      get_fog_storage.directories.get(@uploader.fog_directory)
    end

    def get_fog_file(file_path)
      bucket=self.get_bucket
      return bucket.files.get(file_path)
    end

    def move_file(original_file, dest_file)
      remote_file=get_fog_file(original_file)
      new_remote_file=remote_file.copy(@uploader.fog_directory, dest_file)
      new_remote_file.public=remote_file.public_url.present?
      new_remote_file.save
      remote_file.destroy
    end

    def direct_upload_url
      CarrierWave::Storage::Fog::File.new(uploader, CarrierWave::Storage::Fog.new(uploader), nil).public_url
    end

    def store_dir
      options[:store_dir]|| @uploader.respond_to?(:direct_store_dir) ? @uploader.direct_store_dir : nil
    end

    def policy_raw
      conditions = [ ["starts-with", "$key", self.store_dir] ]
      conditions << ["starts-with", "$Content-Type", ""] if options[:will_include_content_type]

      conditions += options[:policy_conditions] if options[:policy_conditions].present?

      conditions_sub_policy = [
          {"bucket" => uploader.fog_directory},
          {"acl" => uploader.fog_public ? 'public-read' : 'private'},
          ["content-length-range", options[:min_file_size], options[:max_file_size]]
      ]

      conditions_sub_policy << (options[:success_action_redirect].present? ? {"success_action_redirect"=>options[:success_action_redirect]} : {"success_action_status"=>(options[:success_action_status] || '201')})

      policy_hash={
          'expiration' => Time.now.utc + options[:expiration],
          'conditions' => conditions + conditions_sub_policy
      }

      return policy_hash
    end

    def plupload_params
      {
          key: "#{store_dir}/${filename}",
          AWSAccessKeyId: uploader.fog_credentials[:aws_access_key_id],
          acl: uploader.fog_public ? 'public-read' : 'private',
          success_action_status: '201',
          policy: encoded_policy,
          signature: signature
      }
    end

    def encoded_policy
      Base64.encode64(policy_raw.to_json).gsub(/\n|\r/, '')
    end

    def signature
      URI.unescape(
      Base64.encode64(
          OpenSSL::HMAC.digest(
              OpenSSL::Digest::Digest.new('sha1'),
              uploader.fog_credentials[:aws_secret_access_key], encoded_policy
          )
      ).gsub(/\n/,''))
    end

  end
end
