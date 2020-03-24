require 'sketchup'
require 'fileutils'

module M_foamKit

	module M_dialog
		@dir = File.dirname(__FILE__)					
		@model = Sketchup.active_model	
	
		def self.dialog_mesh
			# Add Create Mesh UI to set the snappyHexMeshDict
			$dlg_m = UI::WebDialog.new("Start Mesh", false, "foamKit", 400, 250, 0, 0, true)
			$dlg_m.set_background_color("f3f0f0")
			
			#######################################################################################	
			# Create a string block which is to be inserted into the html file, to be read. This
			# string type block, in a way, populates the patch list in the create mesh dialog.
			stored_mesh_settings = $domain['mesh_settings']
			patch_names = stored_mesh_settings[:patch_names]
			patch_list_length = stored_mesh_settings[:number_of_patches]
			
			patchList_block = ""
			patchOptionList_block = ""				
			patch_names.each_with_index { |patch_name, index|
				if index < patch_list_length-1
					patchList_block = patchList_block +
					"{
						name: #{'"'}#{patch_name}#{'"'},
						min_refLevel: #{'"'}#{stored_mesh_settings[:min_refLevel][index]}#{'"'},
						max_refLevel: #{'"'}#{stored_mesh_settings[:max_refLevel][index]}#{'"'},
						addLayers: #{stored_mesh_settings[:addLayers][index]},
						numberOfLayers: #{'"'}#{stored_mesh_settings[:nSurfaceLayers][index]}#{'"'}
					},\n"
				else
					patchList_block = patchList_block +
					"{
						name: #{'"'}#{patch_name}#{'"'},
						min_refLevel: #{'"'}#{stored_mesh_settings[:min_refLevel][index]}#{'"'},
						max_refLevel: #{'"'}#{stored_mesh_settings[:max_refLevel][index]}#{'"'},
						addLayers: #{stored_mesh_settings[:addLayers][index]},
						numberOfLayers: #{'"'}#{stored_mesh_settings[:nSurfaceLayers][index]}#{'"'}
					}\n"
				end				
				if index == 0
					patchOptionList_block = patchOptionList_block +
					"<option selected=#{'"'}selected#{'"'} value=#{'"'}#{patch_name}#{'"'}>#{patch_name}</option>\n"
				else
					patchOptionList_block = patchOptionList_block +
					"<option value=#{'"'}#{patch_name}#{'"'}>#{patch_name}</option>\n"
				end
			}
			
			thickness = stored_mesh_settings[:thickness]
			expansionRatio = stored_mesh_settings[:expansionRatio]
			locationInMesh = stored_mesh_settings[:locationInMesh]
			
			# Read corresponding html file, update it to show the patch list, and set it to the dialog dlg_m
			html0 = File.read("#{@dir}/html/mesh.html")
			html1 = M_foamKit.update_html(html0, "--patchObjectList--", patchList_block)
			html2 = M_foamKit.update_html(html1, "--patchBoxList--", patchOptionList_block)
			html3 = M_foamKit.update_html(html2, ["--thickness--", "--expansionRatio--", "--locationInMesh--"], [thickness.to_s, expansionRatio.to_s, locationInMesh.to_s], "in_place")
			html4 = M_foamKit.update_html(html3, ["--thicknessVal--", "--xLoc--", "--yLoc--", "--zLoc--"], [thickness.to_s, locationInMesh[0].to_s, locationInMesh[1].to_s, locationInMesh[2].to_s], "in_place")
			unit = "[" + M_foamKit.get_model_units_symbol + "]"
			html5 = M_foamKit.update_html(html4, ["--u1--", "--u2--", "--u3--", "--u4--"], [unit, unit, unit, unit], "in_place")
			html6 = M_foamKit.update_html(html5, "--length_scale--", M_foamKit::M_calculations.get_length_scale.to_s, "in_place")
			
			$dlg_m.set_html(html6)		

			# Check if mesh already exists. If yes, then hide it and show the faces of the geometry
			if M_foamKit.milestone_accomplished?("mesh_created")
				mesh_group = M_foamKit.get_entity("mesh", "Group")
				if mesh_group
					mesh_group.hidden = false
					@model.entities.each { |entity|
						if entity.is_a?(Sketchup::Group)
							if entity.name!="mesh"
								entity.hidden = true
							end
						end
					}
				end
			end				

			#######################################################################################			
			$dlg_m.add_action_callback("call_createMesh") { |dialog, params|
				Sketchup::set_status_text("Creating Mesh ...")
				
				# Make necessary checks
				# Clear locationInMesh sphere if still exists
				@model.entities.each { |ent|
					if ent.is_a?(Sketchup::ComponentInstance)
						if ent.definition.name[0..5]=="sphere"
							ent.erase!
						end
					end					
				}				
				# Retrieve data assigned by user in a string type array mesh_settings
				mesh_settings = params.split(',') rescue []
				
				# Re-arrange settings assigned by the user and store them in the project attributes
				# database. The mesh settings assigned by the user are settings required by snappyHexMesh
				# utility in OpenFOAM
				stored_mesh_settings = $domain['mesh_settings']
				patch_names = stored_mesh_settings[:patch_names]
				patch_list_length = stored_mesh_settings[:number_of_patches]				
				
				min_refLevel = []
				max_refLevel = []
				addLayers = []
				nSurfaceLayers = []				
				patch_names.each_with_index { |patch_name, index|
					min_refLevel.push(mesh_settings[5*index + 1].to_i)
					max_refLevel.push(mesh_settings[5*index + 2].to_i)
					addLayers.push(M_foamKit.to_boolean(mesh_settings[5*index + 3]))
					nSurfaceLayers.push(mesh_settings[5*index + 4].to_i)											
				}
				
				thickness = mesh_settings[patch_list_length*5].to_f
				expansionRatio = mesh_settings[patch_list_length*5 + 1].to_f
				locationInMesh = [mesh_settings[patch_list_length*5 + 2].to_f,
							      mesh_settings[patch_list_length*5 + 3].to_f,
								  mesh_settings[patch_list_length*5 + 4].to_f]
				
				stored_mesh_settings[:min_refLevel] = min_refLevel
				stored_mesh_settings[:max_refLevel] = max_refLevel
				stored_mesh_settings[:addLayers] = addLayers
				stored_mesh_settings[:nSurfaceLayers] = nSurfaceLayers
				stored_mesh_settings[:thickness] = thickness
				stored_mesh_settings[:expansionRatio] = expansionRatio
				stored_mesh_settings[:locationInMesh] = locationInMesh												
				
				$domain['mesh_settings'] = stored_mesh_settings
				
				$domain['n_processors'] = dialog.get_element_value("nProcessors").to_i
				
				# The following commands are a set of functions that prepare some files that are
				# required to perform snappyHexMesh utility.
				result = UI.messagebox('Are you sure you want to create the mesh?', MB_YESNO)
				if result == IDYES
					# Get the export directory of OpenFOAM case
					export_dir = M_foamKit.get_export_dir
					
					# Clear mesh, if exists
					M_foamKit.clear_mesh
									
					# Export STL surfaces
					M_foamKit::M_exportSurfaces.exportSUGroupsAsSTLSurfaces(export_dir)
					
					# Create blockMeshDict, surfaceFeatureExtractDict, snappyHexMeshDict
					M_foamKit.export_blockMeshDict
					M_foamKit.export_surfaceFeatureExtractDict
					M_foamKit.export_decomposeParDict if $domain['n_processors'] > 1
					M_foamKit.export_snappyHexMeshDict					
					
					# Start OpenFOAM if not started yet. This requires a user reponse to proceed
					state = M_foamKit.OF_running?
					if !state
						result = UI.messagebox('OpenFOAM is not running yet, run it now?', MB_YESNO)
						if result == IDYES
							M_foamKit.start_OF_container
						end						
					end										
					
					# Run blockMesh, surfaceExtractFeature and snappyHexMesh
					if $domain['n_processors'] > 1
						pid = M_foamKit.exec_command(["blockMesh", "surfaceFeatureExtract", "decomposePar", 
						"mpirun -np #{$domain['n_processors']} snappyHexMesh -overwrite -parallel", "reconstructParMesh -constant"])
						Process.wait(pid)
						M_foamKit.delete_processor_folders($domain['n_processors'])
					else
						pid = M_foamKit.exec_command(["blockMesh", "surfaceFeatureExtract", "snappyHexMesh -overwrite"])
						Process.wait(pid)
					end
					
					# Plot mesh using Sketchup built in function Geom::fill_in_mesh
					M_foamKit.erase_mesh_entity
					M_foamKit.plot_mesh				
					
				end
				
				M_foamKit.update_milestones("mesh_created")
				if M_foamKit.milestone_accomplished?("pre")
					M_foamKit.enable_tool_command("solve")
				end
				
				if M_foamKit.milestone_accomplished?("results_available")
					M_foamKit.update_milestones("results_available", false)
					M_foamKit.disable_tool_command("view")
					M_foamKit.disable_tool_command("result")
				end				
				
				M_foamKit.update_progress
			}
			
			$dlg_m.set_on_close{ 
			
				# Clear locationInMesh sphere if still exists
				@model.entities.each { |ent|
					if ent.is_a?(Sketchup::ComponentInstance)
						if ent.definition.name[0..5]=="sphere"
							ent.erase!
							patch_names.each { |patch_name|
								patch = M_foamKit.get_entity(patch_name, "Group")
								patch.material.alpha = 1
							}
							break
						end
					end					
				}		
				
				# Check if mesh already exists. If yes, then hide it and show the faces of the geometry
				mesh_group = M_foamKit.get_entity("mesh", "Group")
				if mesh_group
					mesh_group.hidden = true
					@model.entities.each { |entity|
						if entity.is_a?(Sketchup::Group)
							if entity.name!="mesh" && entity.name[0..10]!="vector_plot"
								entity.hidden = false
							end
						end
					}
				end

				stored_mesh_settings = $domain['mesh_settings']
				patch_names = stored_mesh_settings[:patch_names]
				M_foamKit.change_patches_color("White")				
			}
			
			#####################################################################################
			# This call back function is meant to construct a sphere in the domain whose center is
			# at the locationInMesh assigned earlier. It is very important for the user to make
			# sure that the assigned locationInMesh is exactly in the domain
			$dlg_m.add_action_callback("call_showPoint") { |dialog, params|

				# Attach the observer.
				stored_mesh_settings = $domain['mesh_settings']
				patch_names = stored_mesh_settings[:patch_names]	

				params = params.split(',') rescue []
				state = M_foamKit.to_boolean(params[0])
				if state
					@model.entities.each { |ent|
						if ent.is_a?(Sketchup::ComponentInstance)
							if ent.definition.name[0..5]=="sphere"
								ent.erase!
							end
						end						
					}
					
					# Retrieve the locationInMesh values in order to set them as the center of the sphere
					x_loc = params[1]
					y_loc = params[2]
					z_loc = params[3]
					
					# Set an arbitrary radius for the sphere, which is to be 5% of the length scale
					# of the domain. Length scale is the average of geometry bounding box sides dimensions
					radius = M_foamKit::M_calculations.get_length_scale * 0.05
					if x_loc!="" && y_loc!="" && z_loc!=""
						# Draw the sphere
						M_foamKit.draw_sphere([x_loc.to_f, y_loc.to_f, z_loc.to_f], radius)
						
						# Make the geometry surfaces transparent in order to observe the sphere inside the domain
						patch_names.each { |patch_name|
							patch = M_foamKit.get_entity(patch_name, "Group")
							patch.material.alpha = 0.3
						}
					end
				else
					# Clear sphere
					@model.entities.each { |ent|
						if ent.is_a?(Sketchup::ComponentInstance)
							if ent.definition.name[0..5]=="sphere"
								ent.erase!
							end
						end
						
					}
					
					# Bring surfaces white again
					patch_names.each { |patch_name|
						patch = M_foamKit.get_entity(patch_name, "Group")
						patch.material.alpha = 1
					}				
				end
			}

			#####################################################################################
			# This call back functions allows the user to observe the current patch selection by turning
			# the corresponding faces into green
			$dlg_m.add_action_callback("call_displayPatch") {|dialog, params|					
						
				state = dialog.get_element_value("displayPatch")
				if state=="1"
					# Loop over groups, then loop over their faces, and turn them all white
					stored_mesh_settings = $domain['mesh_settings']
					patch_names = stored_mesh_settings[:patch_names]
					M_foamKit.change_patches_color("White")	
					
					# Turn the selected group faces into green
					selected_patch_names = params.split(',') rescue []
					selected_patch_names.each { |selected_patch_name|
						patch = M_foamKit.get_entity(selected_patch_name, "Group")
						patch.material = "Green"
					}

					# Check if mesh already exists. If yes, then hide it and show the faces of the geometry
					if M_foamKit.milestone_accomplished?("mesh_created")
						mesh_group = M_foamKit.get_entity("mesh", "Group")
						mesh_group.hidden = true
						@model.entities.each { |entity|
							if entity.is_a?(Sketchup::Group)
								if entity.name!="mesh"
									entity.hidden = false
								end
							end
						}
					end						
					
				else
					# Loop over groups, then loop over their faces, and turn them all white. This is done
					# when the user unchecks the relevant box
					stored_mesh_settings = $domain['mesh_settings']
					patch_names = stored_mesh_settings[:patch_names]
					M_foamKit.change_patches_color("White") 
					
					# Check if mesh already exists. If yes, then hide it and show the faces of the geometry
					if M_foamKit.milestone_accomplished?("mesh_created")
						mesh_group = M_foamKit.get_entity("mesh", "Group")
						mesh_group.hidden = false
						@model.entities.each { |entity|
							if entity.is_a?(Sketchup::Group)
								if entity.name!="mesh"
									entity.hidden = true
								end
							end
						}
					end					
					
				end				
			}			
			
			#####################################################################################			
			# Call back function to edit the patches again. Any editing interface will open same as the
			# adding interface except that all the patches including the unassigned ones
			$dlg_m.add_action_callback("call_editPatches") { |dialog, params|
				$dlg_m.set_position(3000, 3000)
				M_foamKit.edit_named_patches
			}

			#####################################################################################			
			# If the user checks the display patch box, and then selects any of the patches or multiple
			# of them, the corresponding faces will trurn green
			$dlg_m.add_action_callback("call_selectPatches") { |dialog, params|
				state = dialog.get_element_value("displayPatch")
				if state=="1"
					stored_mesh_settings = $domain['mesh_settings']
					patch_names = stored_mesh_settings[:patch_names]
					M_foamKit.change_patches_color("White")
					
					selected_patch_names = params.split(',') rescue []
					selected_patch_names.each { |selected_patch_name|
						patch = M_foamKit.get_entity(selected_patch_name, "Group")
						patch.material = "Green"
					} 	
				end
			}			
			
			$dlg_m.set_size(570, 680)
			$dlg_m.set_position(50, 10)
			$dlg_m.show
			
		end		
	
	end # module M_dialog
	
end # module M_foamKit	