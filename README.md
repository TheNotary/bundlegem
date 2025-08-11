# BundleGem: A Gem Project Generator with User Defined Templates
[![Gem Version](https://badge.fury.io/rb/bundlegem.svg)](https://badge.fury.io/rb/bundlegem)

BundleGem allow users to define project templates in the most native form to all technologist: Directory Structures, short commands, and helpful commands that make the tool's usage completely visible!

Programming often involves a lot of boilerplate and configuration "boot strapping" before you can get going actually writing any code.  To automate this aspect of creating new projects and microservices, bundlegem allows you to run a simple command `bundlegem -t my-c-embedded-template project-name` and it will clone a template you've made with exact specifications, update the names of files and references within the files to match your project name, run any commands specified in your template.  What once would have been a 5-10 minute distraction of remembering and implementing all those little patterns, testing dependencies, and pipeline definitions now happens immediately with a single command.

The most beneficial aspect of BundleGem is that it allows you to specify exactly how you want your 'default starting project' to look, rather than rely on what someone else thought would be generally helpful.

### Installation

```
gem install bundlegem
bundlegem --install-public-templates
```

#### List Available Templates

```
$  bundlegem -l
PREDEFINED:
  default - A basic ruby gem
  service - A gem that allows installation as a service to run as a daemon

MISC:
  my_service -

EMBEDDED:
  arduino
```

### Usage

These commands will create a new gem named `project_name` in `/tmp/project_name`:

```
$  cd /tmp
$  bundlegem -t arduino project_name
```

You'll find a project skeleton in ~/.bundlegem/templates/my_service that you can customize to your liking.

### Configuration

Configuration is optional and comes from your gitconfig file.  At the user level, this is set at `~/.gitconfig`.  These are the recommended minimal configurations to get the default templates to work ok:

```
[user]
  email = me@example.com
  name = Me
  repo-domain = github.com
```

Alternatively, run these commands:

```
git config --global user.email your-public-gh@email.com
git config --global user.name YOUR_GH_NAME
git config --global user.repo-domain github.com
```

#### Create Your Own Template

You can create a new template for a project class you expect to use more than once:

```
$  bundlegem --newtemplate
Specify a name for your gem template:  my_service
Specify description:
Specify template tag name [MISC]:
Cloning base project structure into ~/.bundlegem/templates/my_service
...
  Complete!
```

You can now get to work making changes to the my_service gem.  All you need to know is that any file that ends in .tt in that folder will be copied into new projects when you create a new project based on that template, however the .tt extension will obviously be stripped out of the resulting file name.

### Categorizing Your Template

Also, you can specify the `category` of the gem by editing the bundlegem.yml file in each template's root.  Categories are just used for organizing the output when you run `bundlegem --list`.  Here, I'll show you an example:


### Customizing Your Own Templates

Place your own templates in `~/.bunglegem/templates`.  You can populate it with examples by running `bundlegem --install-public-templates` which will effectively clone down a few sample git repos into the templates folder for you such as [Go-cli](https://github.com/TheNotary/template-go-cli) for instance.

You'll get a good idea as to the possibilities by inspecting the files in [templates](https://github.com/TheNotary/bundlegem/tree/master/lib/bundlegem/templates/cli_gem).  Check out the [reference](/spec/data/variable_manifest_test.rb) test file to see what kind of interpolations are possible.

Quick Tips:

- Files ending with a `.tt` extension will by written to new projects
- File **names** containing `#{name}` will have that symbol replaced by the project name defined on the CLI
- Within files, use `<%=config[:namespaced_path]%>` to have that reinterpreted as just the file name with underscores
- Have a look [under the hood](https://github.com/TheNotary/bundlegem/blob/master/lib/bundlegem/cli/gem.rb#L30-L43) to see other options and the context where the ERB.new takes place.
