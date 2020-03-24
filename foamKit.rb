# Loader for as_plugins/foamKit/foamKit.rb

require 'sketchup.rb'
require 'extensions.rb'

foamKit = SketchupExtension.new "foamKit", "foamKit/foamKit.rb"
foamKit.creator = 'Mhamad Mahdi Alloush'
foamKit.version = '1.0'
foamKit.description = "This plugin links the geometry in sketchup to OpenFoam where various fluid dynamics simulations can be made. It is suitable for architects because it allows for easy and fast case preparation to conduct a CFD study for indoor air."
Sketchup.register_extension foamKit, true