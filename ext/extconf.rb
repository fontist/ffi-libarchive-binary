$: << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require "ffi-libarchive-binary/libarchive_recipe"

recipe = LibarchiveBinary::LibarchiveRecipe.new
recipe.cook_if_not
