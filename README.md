# BundleGem: A Gem Project Generator with User Defined Templates

Note: Alot of the code here was extracted from Bundler's `bundle gem` command, so credits to the Bundler folks.  Originally I planned to make the new features accessible to the Bundler team and so tried to keep the code as similar to their project as possible, but ultimately discovered that they don't want to grow this feature because good tools should do a single thing very well (manage dependencies), not many things (manage dependencies and also do random other helpful stuff). Also it's a profoundly common dependency meaning every change is high stakes.

The goal of the project is to allow users to define templates in the most native form to all technologist: Directory Structures, short commands, and helpful commands which make the gem's usage completely visible!

The benefits of using this repo to create gems rather than bundler is that you can choose to create 'classes' of gems.  By classes, I mean that there are different typs of 'gems', there are basic library gems, that are just code and can only be used from other code, there are command line application gems, those are gems that are run on the command line and include a binary file, and there are also web interface gems, those are gems which spin up a simple web interface and request that the user connect to it's server on what ever port it has spun up on.  Depending on your field of specialty, you may be able to imagine other classes of gems that will aid you in your work.

All of these 'classes of gems' as I refer to them, start out with a different code base, consistent with all other gems of the same class.  This 'class based' aproach to gem creation is different from the addative approach that other gem genorators are based on.

The most benificial aspect of this gem is that it allows users to specify exactly how they want their 'default starting gem' to look like, rather than rely on what someone else thought their default starting gem should look like.

### Installation and usage

First install it:
```
gem install bundlegem
```

Then create a new template for a gem class you expect to use more than once:
```
$  bundlegem --newtemplate
Specify a name for your gem template:  my_service
Specify description:
Specify template tag name [MISC]:
Cloning base project structure into ~/.bundlegem/templates/my_service
...
  Complete!
```
You can now get to work making changes to the my_service gem.  All you need to know is that any file that ends in .tt in that folder will be copied into new projects when you create a new project based on that template, however the .tt extension will obviously be stripped out of the resulting file name.  Also, you can specify the `category` of the gem by editing the .bundlegem file in each template's root.  Categories are just used for organizing the output when you run `bundlegem --list`.  Here, I'll show you an example:

```
$  bundlegem --list
PREDEFINED:
  default - A basic ruby gem
  service - A gem that allows installation as a service to run as a daemon

MISC:
  my_service -

EMBEDDED:
  arduino

```

You'll now find a project skeleton in ~/.bundlegem/templates/my_service that you can customize to your liking.


Finally, create a new gem using your new gem template:
```
$  cd /tmp
$  bundlegem project_name -t my_service
```

## Customizing Your Own Templates

Place your own templates in `~/.bunglegem/templates`.  You can populate it with examples by running `bundlegem --install-best-templates` which will effectively clone down a few sample git repos into the templates folder for you such as [Go-Cli](https://github.com/TheNotary/go-cli) for instance.

You'll get a good idea as to the possibilities by inspecting the files in [templates](https://github.com/TheNotary/bundlegem/tree/master/lib/bundlegem/templates/newgem).  Some quick tips follow:

- Files ending with a `.tt` extension will by written to new projects
- File **names** containing `#{name}` will have that symbol replaced by the project name defined on the CLI
- Within files, use `<%=config[:namespaced_path]%>` to have that reinterpreted as just the file name with underscores
- Have a look [under the hood](https://github.com/TheNotary/bundlegem/blob/master/lib/bundlegem/cli/gem.rb#L30-L43) to see other options and the context where the ERB.new takes place.

