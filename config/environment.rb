# frozen_string_literal: true

require 'yaml'

module Plugin::KeyPhrase
  # APIに関する情報
  module Environment
    setting = begin
                path = File.join('..', '.mikutter.yml')
                YAML.load_file(File.expand_path(path, __dir__))
              rescue StandardError
                nil
              end
    NAME = setting['name']
    VERSION = setting['version']
    DESCRIPTION = setting['description']
    AUTHOR = setting['author']
  end
end
