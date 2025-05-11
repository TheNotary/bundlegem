# This is the core logic for the app.  CLI stuff should eventually get pulled
# out so the app is neat and the way I do CLI stuff lately.
module Bundlegem::Core
end

# I saw someone on the internet do requires this way so am giving it a spin :)
# It's a little odd, right?  I'm not sure I like it yet but lets me go to
# town on namespaces and `class << self` definitions if I want...
require 'bundlegem/core/dir_to_template'
