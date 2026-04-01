# BundleGem: An Easy to Template Project Generator
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

Configuration is stored in `~/.bundlegem/config` (created automatically on first run). At minimum, you need your git user name and email configured:

```
git config --global user.email your-public-gh@email.com
git config --global user.name YOUR_GH_NAME
```

## Create Your Own Template

> **WIP:** We're actively refactoring the template system. `constant_array` has been dropped and this may cause the ruby template to break. `unprefixed_name` and `unprefixed_pascal` have also been removed.

###### Overview
- Define the project as a working codebase using `foo-bar` as the project name
- All name variants (`foo_bar`, `FooBar`, `FOO_BAR`, etc.) will be auto-replaced when generating a new project
- Use `FOO_` prefixed placeholders for non-name variables (e.g., `FOO_AUTHOR`, `FOO_EMAIL`)
- Add a `bundlegem.yml` file to the template to make it available for use
- Run `bundlegem --to-template` to convert an existing project's name variants into foo-bar placeholders
- Use the template to kick off a new project, `bundlegem -t my-template first-test`

To create your own template, just create a new project using the technologies you'd like.  Place this project in `~/.bundlegem/templates/my-template`.  Once it's done, it's a good idea to create a git commit.  Then run something to the effect...

```
$  echo "category: frontend"    > bundlegem.yml
$  echo "purpose: frontend"    >> bundlegem.yml
$  echo "language: javascript" >> bundlegem.yml

$  bundlegem --to-template
```

Change the bundlegem.yml contents to what makes sense for your template.  The `--to-template` command will replace all occurrences of your project's name variants with `foo-bar` template placeholders.  To keep you and I safe, it will only run if there is a `bundlegem.yml` file in the current directory.

#### Categorizing Your Template

You can specify the `category` of the gem by editing the `bundlegem.yml` file in each template's root.  Categories are just used for organizing the output when you run `bundlegem --list`.  Here's an [example](https://github.com/TheNotary/template-html-css-js/blob/main/bundlegem.yml).

#### Template Prefix Stripping

Some people sort their repos with prefixes...  For instance, you might want to create a repo named `tool-go-my-tool` but have the project file take on the name `my-tool` and ignore those descriptive prefixes?

You can do that!  Just setup your `bundlegem.yml` as below:
```yaml
purpose: tool
language: go
```

You can also set the prefix explicitly in `bundlegem.yml`:
```yaml
prefix: "my-custom-prefix-"
```

#### Customizing Your Own Templates

Place your own templates in `~/.bunglegem/templates`.  You can populate it with examples by running `bundlegem --install-public-templates` which will effectively clone down a few sample git repos into the templates folder for you such as [Go-cli](https://github.com/TheNotary/template-go-cli) for instance.

You'll get a good idea as to the possibilities by inspecting the various templates I've opensourced under my github org, e.g. [template-ruby-cli-gem](https://github.com/TheNotary/template-ruby-cli-gem).

To pull up a list of available variables, run this command

```
$  bundlegem --cheat-sheet
```

If you would find additional variables handy, set me up with a PR and assuming it seems widely helpful, I'll merge it right as soon as I can.   The implementation for the variables is largely found in [gem.rb](https://github.com/TheNotary/bundlegem/blob/main/lib/bundlegem/cli/gem.rb#L59).

#### Quick Tips Regarding Project Templates

- Templates are working code using `foo-bar` as the canonical project name
- Name variants (`foo_bar`, `FooBar`, `fooBar`, `FOO_BAR`, `Foo::Bar`, `Foo Bar`, `foo/bar`) are all auto-replaced
- Use `FOO_` prefixed placeholders for non-name variables: `FOO_AUTHOR`, `FOO_EMAIL`, `FOO_GIT_REPO_URL`, etc.
- Running `bundlegem --cheat-sheet` will list off available template variables
- File **names** containing `foo-bar` or `foo_bar` will have those replaced by the project name
