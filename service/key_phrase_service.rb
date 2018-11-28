# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

# 文章中から特徴語を抽出する
class KeyPhraseService
  def initialize
    uri = URI.parse('https://jlp.yahooapis.jp/KeyphraseService/V1/extract')
    @http = Net::HTTP.new(uri.host, uri.port)
    @http.use_ssl = true
    @request = Net::HTTP::Post.new(uri.request_uri)
    @sentences = []
    set_next_time
  end

  def <<(other)
    return unless other.is_a?(String)

    [/^RT +/, /[\w:@+-_.]+/, URI::DEFAULT_PARSER.make_regexp].each do |p|
      other = other.gsub(p, '')
    end

    @sentences.append(other.strip)
  end

  # 文章中から特徴語を抽出する
  # @return 特徴語一覧
  def get
    set_request
    key_phrases = {}

    if extract_request_or_set_time?
      unless @next_time.nil?
        key_phrases = JSON.parse(@http.request(@request).body)
        @sentences.clear
      end

      set_next_time
    end

    key_phrases
  end

  private

  # 特徴語の抽出や特徴語の次回取得時刻の設定を行うかどうか
  # @return 特徴語の抽出や特徴語の次回取得時刻の設定を行うかどうか
  def extract_request_or_set_time?
    !@request.body.empty? && (@next_time.nil? || @next_time <= Time.now)
  end

  # requestをセットする
  def set_request
    app_id = UserConfig[:key_phrases_yahoo_app_id]

    if app_id.nil? || app_id.empty?
      @request.form_data = {}
    else
      normalize_sentences(app_id)
    end
  end

  # リクエストのデータサイズが上限を超えないよう、sentenceの長さを調整する
  # @param app_id Yahoo! JAPAN Webサービス用アプリケーションID
  def normalize_sentences(app_id)
    until @sentences.empty?
      @request.form_data = { appid: app_id,
                             output: 'json',
                             sentence: @sentences.join }
      return if @request.body.length < 102_400

      @sentences.shift
    end
  end

  # 特徴語の次回取得時刻を設定する
  def set_next_time
    interval = UserConfig[:key_phrases_interval]
    @next_time = if interval.nil?
                   nil
                 else
                   Time.now + interval
                 end
  end
end
