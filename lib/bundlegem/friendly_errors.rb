# encoding: utf-8
require "cgi"
require "bundlegem/vendored_thor"

module Bundlegem
  def self.with_friendly_errors
    yield
  rescue Bundlegem::Dsl::DSLError => e
    Bundlegem.ui.error e.message
    exit e.status_code
  rescue Bundlegem::BundlegemError => e
    Bundlegem.ui.error e.message, :wrap => true
    Bundlegem.ui.trace e
    exit e.status_code
  rescue Thor::AmbiguousTaskError => e
    Bundlegem.ui.error e.message
    exit 15
  rescue Thor::UndefinedTaskError => e
    Bundlegem.ui.error e.message
    exit 15
  rescue Thor::Error => e
    Bundlegem.ui.error e.message
    exit 1
  rescue LoadError => e
    raise e unless e.message =~ /cannot load such file -- openssl|openssl.so|libcrypto.so/
    Bundlegem.ui.error "\nCould not load OpenSSL."
    Bundlegem.ui.warn <<-WARN, :wrap => true
      You must recompile Ruby with OpenSSL support or change the sources in your \
      Gemfile from 'https' to 'http'. Instructions for compiling with OpenSSL \
      using RVM are available at http://rvm.io/packages/openssl.
    WARN
    Bundlegem.ui.trace e
    exit 1
  rescue Interrupt => e
    Bundlegem.ui.error "\nQuitting..."
    Bundlegem.ui.trace e
    exit 1
  rescue SystemExit => e
    exit e.status
  rescue Exception => e
    request_issue_report_for(e)
    exit 1
  end

  def self.request_issue_report_for(e)
    Bundlegem.ui.info <<-EOS.gsub(/^ {6}/, '')
      #{'――― ERROR REPORT TEMPLATE ―――――――――――――――――――――――――――――――――――――――――――――――――――――――'}
      - What did you do?
      - What did you expect to happen?
      - What happened instead?

      Error details

          #{e.class}: #{e.message}
          #{e.backtrace.join("\n          ")}

      #{Bundlegem::Env.new.report(:print_gemfile => false).gsub(/\n/, "\n      ").strip}
      #{'――― TEMPLATE END ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――'}

    EOS

    Bundlegem.ui.error "Unfortunately, an unexpected error occurred, and Bundlegem cannot continue."

    Bundlegem.ui.warn <<-EOS.gsub(/^ {6}/, '')

      First, try this link to see if there are any existing issue reports for this error:
      #{issues_url(e)}

      If there aren't any reports for this error yet, please create copy and paste the report template above into a new issue. Don't forget to anonymize any private data! The new issue form is located at:
      TODO: Change the link that was here
    EOS
  end

  def self.issues_url(exception)
    'TODO: Change the link that was here' \
    "#{CGI.escape(exception.message)}&type=Issues"
  end

end
