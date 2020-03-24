require 'sketchup'
require 'fileutils'

module M_foamKit

	module M_dialog
	
		@model = Sketchup.active_model	
	
		def self.dialog_boundary_conditions	

			#######################################################################################
			# Retrieve data from the domain for the current application
			mesh_settings = $domain['mesh_settings']			
			patch_names = mesh_settings[:patch_names]					
			
			# Create the boundary conditions dialog
			dlg = UI::WebDialog.new("Set Boundary Conditions", false, "foamKit", 400, 250, 0, 0, true);
			dlg.set_background_color("f3f0f0")									

			# Get required fields by the solver and the turbulence model
			required_fields = M_foamKit.get_required_fields			
			
			# Populate the patch list in the dialog with the available patch names in the database. Also,
			# create a javascript object to be used internally by the dialog to store boundary condition data
			patchList_block = ""	
			patchBC_block = ""
			patch_names_array = ""
			patch_names.each_with_index { |patch_name, index|	
				if index < patch_names.length-1
					patchBC_block = patchBC_block +
					"{
						index: #{index}, 
						name: #{'"'}#{patch_name}#{'"'},
						boundary_type: #{'"'}#{'"'}
					},\n"
				else
					patchBC_block = patchBC_block +
					"{
						index: #{index}, 
						name: #{'"'}#{patch_name}#{'"'},
						boundary_type: #{'"'}#{'"'}
					}\n"
				end				
				if index == 0
					patchList_block = patchList_block +
					"<option selected=#{'"'}selected#{'"'} value=#{'"'}#{patch_name}#{'"'}>#{patch_name}</option>\n"
					
					patch_names_array << "#{'"'}#{patch_name}#{'"'}"
				else
					patchList_block = patchList_block +
					"<option value=#{'"'}#{patch_name}#{'"'}>#{patch_name}</option>\n"
					
					patch_names_array << ", #{'"'}#{patch_name}#{'"'}"
				end				
			}
			
			# Update the html and set it to the current dialog
			html0 = File.read("#{@dir}/html/set_boundary_conditions.html")
			html1 = M_foamKit.update_html(html0, "--patchBC_block--", patchBC_block)
			html2 = M_foamKit.update_html(html1, "--patchList--", patchList_block)
			html3 = M_foamKit.update_html(html2, "--patch_names_array--", patch_names_array, "in_place")	
			dlg.set_html(html3)
			
			# This call back function edit the assigned boundary condition according to
			# the assigned solver
			dlg.add_action_callback("call_editBoundary") { |dialog, params|				
				patch_name = dialog.get_element_value("patchList")
				boundary_type = dialog.get_element_value("boundaryType")
				
				# Open boundary condition settings dialog
				M_foamKit::M_dialog.dialog_boundary_condition_settings(patch_name, boundary_type)
			}
			
			# Store the newly selected boundary type to the current patch
			dlg.add_action_callback("call_boundaryType") { |dialog, params|
				patch_name = dialog.get_element_value("patchList")
				boundary_type = dialog.get_element_value("boundaryType")				
				
				standard_bcs = M_foamKit.get_standard_bcs($domain['application']['name'])	
				
				# Update boundary condition
				required_fields.each { |field|										
					$domain['boundary_conditions'][field][patch_name] = standard_bcs[field][boundary_type]						
				}	
				
				# Store the selected boundary type
				$domain['boundary_types'][patch_name] = boundary_type
			}
			
			# This call back function closes the dialog and exports updated fields to 0 directory
			dlg.add_action_callback("call_applyChanges") { |dialog, params|				
				dlg.close				
				
				# Loop over all the required fields and export the correponding field initial 
				# conditions file to 0 folder in OpenFOAM directory
				required_fields.each { |field|
					M_foamKit.export_field(field, $domain['boundary_conditions'][field])
				}
				
				M_foamKit.update_milestones("boundary_conditions_assigned")	
				if M_foamKit.milestone_accomplished?("pre")
					M_foamKit.enable_tool_command("solve")
				end	

				# Update icon
				M_foamKit.adjust_icon("boundary_conditions", "done")
				
				M_foamKit.update_progress
			}		
			
			dlg.set_size(360, 440)
			dlg.set_position(150, 50)
			dlg.show			
		end

	end # module M_dialog
	
end # module M_foamKit	