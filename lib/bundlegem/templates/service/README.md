== What's This?

This is a gem skeleton template.  Ideally you can define your own and place them into ~/.bundle/gem_templates and specify to use that template instead of the default template defined in bundler.  

This skelton would be helpful if you needed to create a new ruby app that ran as a service on the installed machine.  This skelton should include the base code required for building a daemon style ruby app, including an installation command, a start/stop/restart/status interface and of course a spot that says "# your daemon code goes here" where you could easily drop in, say, a write to a log file and a sleep 5000 instruction and you'd be pretty much set for rapidly spinning up a new gem of the daemon type.  


