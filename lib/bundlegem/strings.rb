module Bundlegem
  HELP_MSG = <<-HEREDOC
                    BundleGem version #{Bundlegem::VERSION}
Use bundlegem to start a new project folder based on a predefined template.

Usage Examples:

  # Download all my template files (configured in ~/.bundlegem/config)
  $ bundlegem --install-public-templates

  # Create a personal mono-repo template for your projects
  $ bundlegem --create-personal-templates

  # List available teplates
  $  bundlegem --list

  # Create a ruby gem project using the built in service template
  $ bundlegem --template ruby-cli-gem your_project_name

  # Convert the current directory which represents a working project into a
  # template by replacing project name variants with foo-bar placeholders
  $ bundlegem --to-template

  # shows this message
  $ bundlegem --help
  HEREDOC

end
