module Bundlegem
  HELP_MSG = <<-HEREDOC
                    BundleGem version #{Bundlegem::VERSION}
Use bundlegem to start a new project folder based on a predefined template.

Usage Examples:

  # Make a new ruby gem
  $  bundlegem your_gem_name

  # List available teplates
  $  bundlegem --list

  # Create a ruby gem project using the built in service template
  $ bundlegem your_gem_name -t service

  # Download all my template files (configured in ~/.bundlegem/config)
  $ bundlegem --install-best-templates

  # Convert the current directory which represents a working project into a
  # template meaning all files will be renamed to *.tt unless a *.tt of that
  # name already exists
  $ bundlegem --to-template

  # shows this message
  $ bundlegem --help
  HEREDOC

end
