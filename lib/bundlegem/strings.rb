module Bundlegem
  HELP_MSG = <<-HEREDOC
                    BundleGem version #{Bundlegem::VERSION}
Use bundlegem to start a new project folder based on a predefined template.

Usage Examples:

  # Download all my template files (configured in ~/.bundlegem/config)
  $ bundlegem --install-public-templates

  # List available teplates
  $  bundlegem --list

  # Create a ruby gem project using the built in service template
  $ bundlegem --template service your_gem_name

  # Convert the current directory which represents a working project into a
  # template meaning all files will be renamed to *.tt unless a *.tt of that
  # name already exists
  $ bundlegem --to-template

  # shows this message
  $ bundlegem --help
  HEREDOC

end
