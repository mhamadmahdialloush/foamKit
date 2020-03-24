require 'sketchup'
require 'fileutils'

module M_foamKit

	module M_dialog
		@dir = File.dirname(__FILE__)				
		@model = Sketchup.active_model	
		
		def self.dialog_start
			result = UI.messagebox('Do you want to start a new OpenFOAM case?', MB_YESNO)
			if result == IDNO
				return nil
			end				

			Sketchup.status_text = "Starting foamKit..."

			dlg = UI::WebDialog.new("Start foamKit", false, "foamKit", 400, 250, 0, 0, true);
			dlg.set_background_color("f3f0f0")			
			
			# Build and update the html file which is executed in the background of the start dialog
			html0 = File.read("#{@dir}/html/start.html")
			standard_applications = M_foamKit.get_standard_applications			
			applications = ""
			descriptions = ""
			standard_applications.each_with_index { |(key, value), index|
				if index==0
					applications = applications + "'#{key}'"
					descriptions = descriptions + "'#{value['description']}'"
				else
					applications = applications + ", '#{key}'"
					descriptions = descriptions + ", '#{value['description']}'"
				end
			}						
			html1 = M_foamKit.update_html(html0, ["--applications--", "--descriptions--"], [applications, descriptions], "in_place")						
			dlg.set_html(html1)
			
			# This call back function sets the application type and its description in the project attributes
			# database.
			dlg.add_action_callback("call_create_case") { |dialog, params|									
				# Default problem attributes (application type, fluid type, transport properties, mesh settings, etc)
				# are stored at this point.
				M_foamKit.store_default_project_attributes(dialog.get_element_value('applicationList'))					
				
				# Create OpenFOAM folders in default directory
				M_foamKit.create_folders									

				# Open dialog to add patches
				M_foamKit.add_named_patches	
				
				M_foamKit.update_progress
				
				dlg.close				
			}
			dlg.set_size(460, 350)
			dlg.set_position(150, 150)
			dlg.show				
		end				
	
	end # module M_dialog
	
end # module M_foamKit	