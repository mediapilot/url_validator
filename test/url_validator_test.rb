require 'test_helper'

class UrlValidatorTest < MiniTest::Spec
  describe "UrlValidator" do
    class Record
      include ActiveModel::Validations
      attr_accessor :url, :homepage
      validates :url, url: true
      validates :homepage, url: { message: 'INVALID' }
    end

    before do
      @record = Record.new
      @record.homepage = 'http://google.com'
      @record.url = 'http://google.com'
    end

    [
        'http://example.com',
        'http://example.com/',
        'http://www.example.com/',
        'http://sub.domain.example.com/',
        'http://bbc.co.uk',
        'http://example.com?foo',
        'http://example.com?url=http://example.com',
        'http://example.com:8000',
        'http://www.sub.example.com/page.html?foo=bar&baz=%23#anchor',
        'http://user:pass@example.com',
        'http://user:@example.com',
        'http://example.com/~user',
        'http://example.xy',  # Not a real TLD, but we're fine with anything of 2-6 chars
        'http://example.museum',
        'http://1.0.255.249',
        'http://1.2.3.4:80',
        'HttP://example.com',
        'https://example.com',
        'http://räksmörgås.nu',  # IDN
        'http://xn--rksmrgs-5wao1o.nu',  # Punycode
        'http://example.com.',  # Explicit TLD root period
        'http://example.com./foo'
    ].each do |url|
      it "is valid with the valid url #{url}" do
        @record.url = url

        assert @record.valid?
      end
    end

    [
        nil, 1, "", " ", "url",
        "www.example.com",
        "http://ex ample.com",
        "http://example.com/foo bar",
        'http://256.0.0.1',
        'http://u:u:u@example.com',
        'http://r?ksmorgas.com',

        # These can all be valid local/private URLs, but should not be considered valid
        # for public consumption. This is an incomplete list however
        # e.g., http://www.example.local passes
        "http://localhost",
        "http://127.0.0.1",
        "http://10.0.0.1",
        "http://169.254.1.2",
        "http://172.19.125.12",
        "http://192.168.12.124",
        "http://example",
        "http://example.c",
        'http://example.toolongtld'
    ].each do |url|
      it "is not valid for the invalid url #{url}" do
        @record.url = url

        refute @record.valid?
      end
    end

    it "can override message" do
      @record.homepage = 'fluff hamster'
      refute @record.valid?

      assert @record.errors[:homepage].include?("INVALID")
    end
  end
end
