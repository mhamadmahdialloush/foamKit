require 'sketchup'
require 'fileutils'

module M_foamKit
	module M_dialog
		@dir = File.dirname(__FILE__)
		@model = Sketchup.active_model
		
		# This module sets the right paths to OpenFOAM, ParaView and GNUPLOT
		
		def self.set_preferences
			dlg = UI::WebDialog.new("Preferences", false, "foamKit", 400, 250, 0, 0, true);
			dlg.set_background_color("f3f0f0")
			
			html = File.read("#{@dir}/html/preferences.html")
			
			dlg.add_action_callback("call_applyChanges") { |dialog, params|
				paraview_dir = M_foamKit.adjust_element_in_array(dialog.get_element_value("PVDir"), "\\", '/')
				M_foamKit.update_path("paraview_dir", paraview_dir)			
				M_foamKit.update_version("openfoam_version", dialog.get_element_value("OFVersion"))
			}
			
			dlg.set_html(html)
			dlg.set_size(600, 320)
			dlg.show
		end
		
		def self.display_about
			UI.messagebox("foamKit is a plugin for Sketchup, based on Ruby Programming. It is an easy and useful tool which allows the user to prepare a CFD case. In fact, what foamKit makes is that it allows the user to prepare an OpenFOAM case totally from inside Sketchup. foamKit makes use of Sketchup's libraries to prepare the geometry and set the meshing attributes. However, foamKit is application oriented and not solver oriented, which means that the developer has made available for the user certain types of applications such as indoor air in a room for example, or low speed aerodynamics. The developer will proceed in later versions of the plugin in providing additional applications of interest such as those related to compressible flows. Furthur technical details may be found on github.
			
Mhamad Mahdi Alloush
foamKit Developer")				
		end		
		
	end			
end