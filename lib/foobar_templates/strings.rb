module FoobarTemplates
  HELP_MSG = <<-HEREDOC
                    Foobar Templates version #{FoobarTemplates::VERSION}
Use foobar_templates to start a new project folder based on a predefined template.

Usage Examples:

  # Download all my template files (configured in ~/.foobar/config)
  $ foobar_templates --install-public-templates

  # Create a personal mono-repo template for your projects
  $ foobar_templates --setup-personal-templates

  # List available teplates
  $ foobar_templates --list

  # Create a ruby gem project using the built in service template
  $ foobar_templates --template ruby-cli-gem your_project_name

  # Convert the current directory which represents a working project into a
  # template by replacing project name variants with foo-bar placeholders
  $ foobar_templates --copy-to-templates

  # shows this message
  $ foobar_templates --help
  HEREDOC

end
