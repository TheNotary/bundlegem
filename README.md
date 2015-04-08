
# BundleGem: a gem project genorator with user defined templates

I've more or less taken the code out of Bundler's `bundle gem` command, expanded on it and made it available as this repos.

The benefits of using this repo to create gems rather than bundler is that you can choose to create 'classes' of gems.  
By classes, I mean that there are different typs of 'gems', there are basic library gems, that are just code and can only be used from other code, there are command line application gems, those are gems that are run on the command line and include a binary file, and there are also web interface gems, those are gems which spin up a simple web interface and request that the user connect to it's server on what ever port it has spun up on.  

All of these 'classes of gems' as I refer to them, start out with a different code base, consistent with all other gems of there class.  
This 'class based' aproach to gem creation is different from the addative approach that other gem genorators are based on.  

The most benificial aspect of this gem is that it allows users to specify exactly how they want their 'default starting gem' to look like, rather than rely on what someone else thought their default starting gem should look like.  

### Installation and usage

First install it:
```
gem install bundlegem
```

Then create a new project structure:
```
$  bundlegem template new
Specify a name for your gem template:  my_service
Cloning base project structure into ~/.bundlegem/templates/my_service
...
Complete!
```

You'll now find a project skeleton in ~/.bundlegem/templates/my_service that you can customize to your liking.  


Finally, create a new gem using your new gem template:
```
$  cd /tmp
$  bundlegem project_name -t my_service
```

### Contributing

Please feel free to speak up using the issue section if there's anything on your mind :)  
Do the usual fork routine and issue a pull request by all means.  

