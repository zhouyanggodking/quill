require "selenium-webdriver"
module ScribeDriver
  module JS
    def self.execute_js(src, args = nil)
      ScribeDriver.driver.switch_to.default_content
      result = ScribeDriver.driver.execute_script(src, *args)
      ScribeDriver.driver.switch_to.frame(ScribeDriver.driver.find_element(:tag_name, "iframe"))
      return result
    end

    def self.get_as_str(ref)
      return self.execute_js "return JSON.stringify(window.ScribeDriver['#{ref}'])"
    end

    def self.get_expected_as_str
      src = "return JSON.stringify(window.ScribeDriver.docDelta.compose(window.ScribeDriver.currentDelta));"
      return self.execute_js src
    end

    def self.get_cur_doc_delta_as_str
      return execute_js "return JSON.stringify(editor.getDelta());"
    end

    def self.set_scribe_delta(driver)
      return execute_js "window.ScribeDriver.initializeScribe()"
    end

    def self.editor_delta_equals(delta)
      return self.execute_js "return window.ScribeDriver.createDelta(#{delta.to_json}).isEqual(window.editor.getDelta())"
    end

    def self.make_insert_delta(startLength, index, value, attributes)
      return self.execute_js "return window.ScribeDriver.autoFormatDelta(window.Tandem.Delta.makeInsertDelta(#{startLength}, #{index}, '#{value}', #{attributes}));"
    end

    def self.set_scribe_delta(delta)
      self.execute_js "window.editor.setDelta(window.ScribeDriver.createDelta(#{delta.to_json}));"
    end

    def self.set_doc_delta(delta = nil)
      if not delta.nil?
        self.execute_js "window.ScribeDriver.docDelta = window.ScribeDriver.createDelta(#{delta.to_json});"
      else
        self.execute_js "window.ScribeDriver.docDelta = window.ScribeDriver.cleanup(editor.getDelta());"
      end
    end

    def self.get_doc_length
      return self.execute_js "return window.editor.getLength();"
    end

    def self.check_consistency
      return self.execute_js "return window.ScribeDriver.checkConsistency();"
    end

    def self.set_current_delta(delta)
      return self.execute_js "window.ScribeDriver.currentDelta = window.ScribeDriver.createDelta(#{delta.to_json})"
    end
  end

  def self.driver
    @@driver
  end

  #############################################################################
  # WebDriver helpers
  #############################################################################
  def setup_test_suite
    browser = :chrome
    browser = ARGV[0].to_sym if ARGV.length == 1
    editor_url = "file://#{File.join(File.expand_path(__FILE__),
      '../../../..', 'build/tests/webdriver/webdriver.html')}"
    @driver = ScribeDriver.create_scribe_driver(:chrome, editor_url)
    @editor = @driver.find_element(:class, "editor")
    @adapter = WebdriverAdapter.new @driver, @editor
    @adapter.focus()
  end

  def self.create_scribe_driver(browser, url)
    if browser == :firefox
      profile = Selenium::WebDriver::Firefox::Profile.new
      profile.native_events = true
      @@driver = Selenium::WebDriver.for browser, :profile => profile
    elsif browser== :chrome
      log_path = FileUtils.mkpath(File.join(File.dirname(File.expand_path(__FILE__)), "fuzzer_output"))
      log_path = log_path.first
      @@driver = Selenium::WebDriver.for browser, :service_log_path => log_path
    else
      @@driver = Selenium::WebDriver.for browser
    end
    @@driver.manage.timeouts.implicit_wait = 10
    @@driver.get url
    @@driver.switch_to.frame(@@driver.find_element(:tag_name, "iframe"))
    return @@driver
  end
end
