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

## Create Your Own Template

###### Overview
- Define the project in a repo as you normally would
- Commit the project once it's building/ testing the way you'd like
- Add a `bundlegem.yml` file to the template to make it available for use
- Run `bundlegem --to-template` which adds a `.tt` suffix to the files
- Add any template variables to the project. See: `bundlegem --cheat-sheet`
- Use the template to kick off a new project, `bundlegem -t my-template first-test`

To create your own template, just create a new project using the technologies you'd like.  Place this project in `~/.bundlegem/templates/my-template`.  Once it's done, it's a good idea to create a git commit.  Then run something to the effect...

```
$  echo "category: frontend"    > bundlegem.yml
$  echo "purpose: frontend"    >> bundlegem.yml
$  echo "language: javascript" >> bundlegem.yml

$  bundlegem --to-template
```

Change the bundlegem.yml contents to what makes sense for your template.  The `--to-template` command will add a `.tt` to the end of all the files in the project.  To keep you and I safe, it will only run if there is a `bundlegem.yml` file in the current directory.

#### Categorizing Your Template

You can specify the `category` of the gem by editing the `bundlegem.yml` file in each template's root.  Categories are just used for organizing the output when you run `bundlegem --list`.  Here's an [example](https://github.com/TheNotary/template-html-css-js/blob/main/bundlegem.yml).

#### Customizing Your Own Templates

Place your own templates in `~/.bunglegem/templates`.  You can populate it with examples by running `bundlegem --install-public-templates` which will effectively clone down a few sample git repos into the templates folder for you such as [Go-cli](https://github.com/TheNotary/template-go-cli) for instance.

You'll get a good idea as to the possibilities by inspecting the various templates I've opensourced under my github org, e.g. [template-ruby-cli-gem](https://github.com/TheNotary/template-ruby-cli-gem).  

To pull up a list of available variables, run this command

```
$  bundlegem --cheat-sheet
```

If you would find additional variables handy, set me up with a PR and assuming it seems widely helpful, I'll merge it right as soon as I can.   The implementation for the variables is largely found in [gem.rb](https://github.com/TheNotary/bundlegem/blob/main/lib/bundlegem/cli/gem.rb#L59).

#### Quick Tips Regarding Project Templates

- Files ending with a `.tt` extension will by written to new projects
- Running `bundlegem --cheat-sheet` will list off available template variables
- File **names** containing `#{name}` will have that symbol replaced by the project name defined on the CLI
- Example: within a `.tt` file, use `<%=config[:namespaced_path]%>` to have that reinterpreted as just the file name with underscores
