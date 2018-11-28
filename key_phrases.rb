# frozen_string_literal: true

# TLから特徴語を抽出し、表示する

require_relative 'config/environment'
require_relative 'service/key_phrase_service'

key_phrase_service = KeyPhraseService.new
about_options = { program_name: Plugin::KeyPhrase::Environment::NAME,
                  version: Plugin::KeyPhrase::Environment::VERSION,
                  comments: Plugin::KeyPhrase::Environment::DESCRIPTION,
                  license: begin
                             path = File.expand_path('LICENSE', __dir__)
                             file_get_contents(path)
                           rescue StandardError
                             nil
                           end,
                  website: 'https://github.com/massongit/mikutter_key_phrases',
                  authors: [Plugin::KeyPhrase::Environment::AUTHOR] }

Plugin.create(:key_phrases) do
  defactivity(:key_phrases, '特徴語')

  settings('特徴語') do
    title = 'Yahoo! JAPAN Webサービス用アプリケーションID'
    inputpass(title, :key_phrases_yahoo_app_id).tooltip(title)
    title = '取得間隔 (秒)'
    adjustment(title, :key_phrases_interval, 2, 604_800).tooltip(title)
    about("#{Plugin::KeyPhrase::Environment::NAME}について", about_options)
  end

  on_update do |_service, messages|
    messages.each do |message|
      key_phrase_service << message[:message]
    end

    key_phrases = key_phrase_service.get

    unless key_phrases.empty?
      output = ['【特徴語】', '　スコア: 単語']

      key_phrases.each do |word, score|
        output.append(format('　%<score>6d: %<word>s', score: score, word: word))
      end

      activity(:key_phrases, output.join("\n"))
    end
  end
end
