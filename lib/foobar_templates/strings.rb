module FoobarTemplates
  HELP_MSG = <<-HEREDOC
                    Foobar Templates version #{FoobarTemplates::VERSION}
Use foobar_templates to start a new project folder based on a predefined template.

Usage Examples:

  # Download all my template files (configured in ~/.foobar/config)
  $ foobar_templates --install-public-templates

  # Create a personal mono-repo template for your projects
  $ foobar_templates --setup-personal-templates

  # Create a ruby gem project using the built in service template
  $ foobar_templates --template ruby-cli-gem your_project_name

  # Convert the current directory which represents a working project into a
  # template by replacing project name variants with foo-bar placeholders
  $ cd my_recently_built_project
  $ foobar_templates --copy-to-templates
  HEREDOC

end
