
# BundleGem: a gem project genorator with user defined templates

I've more or less taken the code out of Bundler's `bundle gem` command, expanded on it and made it available as this repos.

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

