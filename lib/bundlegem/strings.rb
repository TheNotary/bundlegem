module Bundlegem
  HELP_MSG = <<-HEREDOC
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

  # not implemented, should create a new gem template in ~/.bundlegem/templates
  # that you'll love customizing to your personal preference
  $ bundlegem --newtemplate

  $ bundlegem --help              # shows this message
  HEREDOC



end
