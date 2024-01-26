# frozen_string_literal: true

# This re-registration file is made because of problems with chromedriver v.120
# Selenium methods are undefined without this change
# More info in PR #12160

require "selenium-webdriver"

module Decidim
  Capybara.register_driver :headless_chrome do |app|
    options = ::Selenium::WebDriver::Chrome::Options.new
    options.args << "--headless=new"
    options.args << "--no-sandbox"
    options.args << if ENV["BIG_SCREEN_SIZE"].present?
                      "--window-size=1920,3000"
                    else
                      "--window-size=1920,1080"
                    end
    options.args << "--ignore-certificate-errors" if ENV["TEST_SSL"]
    Capybara::Selenium::Driver.new(
      app,
      browser: :chrome,
      capabilities: [options]
    )
  end
end
