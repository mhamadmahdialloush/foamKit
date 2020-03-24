require 'sketchup'
require 'fileutils'

module M_foamKit

	@model = Sketchup.active_model
	@dir = File.dirname(__FILE__)
	
	class Return_Selected_Faces			
		def initialize			
			@model = Sketchup.active_model
			@selection = @model.selection
			@selection.clear
			
			@dir = File.dirname(__FILE__)
			
			@cursor_pos = [0, 0]
			
			@cursor_select			= cursor('Select.png', 3, 8)
			@cursor_select_add		= cursor('Select_Add.png', 3, 8)
			@cursor_select_remove	= cursor('Select_Remove.png', 3, 8)
			@cursor_select_toggle	= cursor('Select_Toggle.png', 3, 8)
			
			@ctrl = nil
			@shift = nil							
		end
		
		def activate
			@ip = Sketchup::InputPoint.new
			@ctrl = false
			@shift = false
			
			tools = Sketchup.active_model.tools
			tool = tools.pop_tool				
		end  
		
		def onCancel(reason, view)
		end
		
		def deactivate(view)
		end  
	
		def onLButtonDown(flags, x, y, view)
			@ip.pick view, x, y
			f = @ip.face
			unless f.nil?
				if flags==0
					@selection.add(f)
				else
					if @selection.include?(f)
						@selection.remove(f)
					end
				end
			end
		end													
		
		def cursor(file, x = 0, y = 0)
		  cursor_path = File.join(@dir, 'cursor')
		  return (cursor_path) ? UI.create_cursor(cursor_path, x, y) : 0
		end
		
		def onKeyDown(key, repeat, flags, view)
		  @ctrl  = true if key == VK_CONTROL
		  @shift = true if key == VK_SHIFT
		  onSetCursor
		end
		
		def onKeyUp(key, repeat, flags, view)
		  @ctrl  = false if key == VK_CONTROL
		  @shift = false if key == VK_SHIFT
		  onSetCursor
		end			
		
		def onSetCursor		
		  if @ctrl && @shift
			UI.set_cursor(@cursor_select_remove)
		  elsif @ctrl
			UI.set_cursor(@cursor_select_add)
		  elsif @shift
			UI.set_cursor(@cursor_select_toggle)
		  else
			UI.set_cursor(@cursor_select)
		  end
		end			
		
	end  # end of class Return_Selected_Faces
				
		
	class << self		
		def edit_named_patches
			dir = File.dirname(__FILE__)			
								
			M_foamKit.change_patches_color("White") 				
			
			$dlg_enp = UI::WebDialog.new("Add Patches", false, "foamKit", 400, 250, 0, 0, true)
			$dlg_enp.set_background_color("f3f0f0")										
			
			patch_names = $domain['mesh_settings'][:patch_names]
			patchOptionList_block = ""
			patch_names.each { |name|
				patchOptionList_block = patchOptionList_block +
				"<option value=#{'"'}#{name}#{'"'}>#{name}</option>\n"								
			}								
			
			patchOptionList_block = patchOptionList_block + "<option></option>"
			
			html0 = File.read("#{dir}/html/edit_patch.html")
			html1 = M_foamKit.update_html(html0, "--patchList--", patchOptionList_block)											
			$dlg_enp.set_html(html1)
			
			$dlg_enp.add_action_callback("set_addPatch") { |dialog, params|
			
				$dlg_enp.set_position(3000, 3000)
			
				# Check if there are unassigned faces, if no, the user can't add groups because there will be overlapping
				# groups
				unassigned_face_entities = M_foamKit.get_unassigned_face_entities
				if unassigned_face_entities.empty?
					UI.messagebox('There are no unassigned faces, you can not add groups. Delete existing groups and try again!')				
				else				
					selection_tool = Return_Selected_Faces.new
					@model.select_tool(selection_tool)
					
					# Create an auxiliary dialog box to enter the name of the patch
					dlg_np = UI::WebDialog.new("Name Patches", false, "foamKit", 400, 250, 0, 0, true)
					dlg_np.set_background_color("f3f0f0")
					
					html2 = File.read("#{dir}/html/set_patch_name.html")				
					dlg_np.set_html(html2)
					
					# Once the faces are selected and a name was given, pressing the apply
					# button on the auxiliary dialog will create a group in Sketchup that includes the selected
					# faces.
					dlg_np.add_action_callback("set_patchName") { |dialog2, params2|
						patch_name = dlg_np.get_element_value("patchName")
						patch_name = M_foamKit.convert_name(patch_name)
						
						# Get the selected entities
						@model = Sketchup.active_model
						selection = @model.selection
						
						selected_faces = selection.grep(Sketchup::Face)
						selected_groups = selection.grep(Sketchup::Group)
						
						unless selected_groups.empty?
							result = UI.messagebox('You have selected an exisiting patch, you are not allowed to create overlapping patches, press Yes if you want to delete the existing patch and create a new one, otherwise, press No to select again', MB_YESNO)
							if result == IDYES
								exploded_faces = []
								selected_groups.each { |selected_group|
									# Remove patch name from project attributes database and update the number of patches
									patch_names = $domain['mesh_settings'][:patch_names]	
									index_in_list = patch_names.index(selected_group.name)
									patch_names.delete(selected_group.name)
									
									group_entities = selected_group.explode

									$domain['mesh_settings'][:patch_names] = patch_names
									$domain['mesh_settings'][:number_of_patches] = patch_names.length					
									
									# Update the list in the dialog by executing the following javascript code
									js_command = "patchList = document.getElementById('patchList');
												  patchList.remove(#{index_in_list});
												  patchList.options[0].selected = true;"
									$dlg_enp.execute_script(js_command)
									
									group_entities.each { |ent|
										exploded_faces.push(ent) if ent.is_a?(Sketchup::Face)
									}																		
								}								
								faces = exploded_faces + selected_faces
								
								# Put the selected entities (faces particularly) in a separate new group
								patch = @model.entities.add_group(faces)
								patch.material = "Green"
								patch_names = $domain['mesh_settings'][:patch_names] # get the existing patch names, initially empty
								
								# If the creation of the patch succeeds, store the new patch name
								# in the project attributes database
								unless patch.nil?												
									
									# Check if the new name exists. If yes, add an index to its end
									str_length = patch_name.length
									while patch_names.include?(patch_name)
										index = patch_name.gsub(/[^\d]/, '').to_i
										patch_name = "#{patch_name[0..str_length-1]}#{index+1}"
									end	
									patch_names.push(patch_name)
									patch_names = patch_names.sort_by{|m| m.downcase} # sort according to alphabetical order
									
									patch.name = patch_name	# name the group as assigned by the user
									
									# Store in project attributes both the new patch names array and the new number of patches
									$domain['mesh_settings'][:patch_names] = patch_names
									$domain['mesh_settings'][:number_of_patches] = patch_names.length						
									
									# Update the dlg_enp dialog with the newly added patch by executing the following
									# javascript code which is basicall adding a new option to the patch list in the html
									index_in_list = patch_names.index(patch_name)
									js_command = "var patchList = document.getElementById('patchList');
												  var option = document.createElement('option');
												  option.text = '#{patch_name}';
												  option.value = '#{patch_name}';
												  patchList.add(option, #{index_in_list});
												  patchList.options[#{index_in_list}].selected = true;"
									
									$dlg_enp.execute_script(js_command)													
									
									# The selection tool is now deactivated
									selection_tool.deactivate(Sketchup::View)
									
									# The selections are cleared in order, perhaps, to start new selection process
									selection.clear 
									
									unless faces.length > 50
										patch_duplicate = patch.copy
										array = patch_duplicate.explode

										# Put all the exploded entities in a single array
										array.grep(Sketchup::Face).each { |ex_ent| ex_ent.hidden = true}
									end							
									
								end					
								dlg_np.close									
							else
								selection.clear
							end
						else
						
							# Put the selected entities (faces particularly) in a separate new group
							patch = @model.entities.add_group(selected_faces)
							patch.material = "Green"
							
							patch_names = $domain['mesh_settings'][:patch_names] # get the existing patch names, initially empty
							
							# If the creation of the patch succeeds, store the new patch name
							# in the project attributes database
							unless patch.nil?												
								
								# Check if the new name exists. If yes, add an index to its end
								str_length = patch_name.length
								while patch_names.include?(patch_name)
									index = patch_name.gsub(/[^\d]/, '').to_i
									patch_name = "#{patch_name[0..str_length-1]}#{index+1}"
								end	
								patch_names.push(patch_name)
								patch_names = patch_names.sort_by{|m| m.downcase} # sort according to alphabetical order
								
								patch.name = patch_name	# name the group as assigned by the user
								
								# Store in project attributes both the new patch names array and the new number of patches
								$domain['mesh_settings'][:patch_names] = patch_names
								$domain['mesh_settings'][:number_of_patches] = patch_names.length						
								
								# Update the dlg_enp dialog with the newly added patch by executing the following
								# javascript code which is basicall adding a new option to the patch list in the html
								index_in_list = patch_names.index(patch_name)
								js_command = "var patchList = document.getElementById('patchList');
											  var option = document.createElement('option');
											  option.text = '#{patch_name}';
											  option.value = '#{patch_name}';
											  patchList.add(option, #{index_in_list});
											  patchList.options[#{index_in_list}].selected = true;"
								
								$dlg_enp.execute_script(js_command)													
								
								# The selection tool is now deactivated
								selection_tool.deactivate(Sketchup::View)
								
								# The selections are cleared in order, perhaps, to start new selection process
								selection.clear 
								
								unless selected_faces.length > 50
									patch_duplicate = patch.copy
									array = patch_duplicate.explode

									# Put all the exploded entities in a single array
									array.grep(Sketchup::Face).each { |ex_ent| ex_ent.hidden = true}
								end						
								
							end					
							dlg_np.close
						end
						$dlg_enp.set_position(50, 50)
					}
					dlg_np.set_size(310, 180)
					dlg_np.set_position(50, 50)   				
					dlg_np.show	
				end				
			}
			
			##########################################################################################
			# This call back function  deletes an exisiting patch (selected in the list within the dialog)			
			$dlg_enp.add_action_callback("set_deletePatch") { |dialog3, params3|
				# Retrieve the selected patch names, loop over them and explode the corresponding Sketchup group.
				# Other processes are also done
				selected_patches = params3.split(',') rescue []
				selected_patches.each { |selected_patch|
					group = M_foamKit.get_entity(selected_patch, "Group")
					group.material = "White"
					group_entities = group.explode

					# Remove patch name from project attributes database and update the number of patches
					patch_names = $domain['mesh_settings'][:patch_names]	
					index_in_list = patch_names.index(selected_patch)
					patch_names.delete(selected_patch)

					$domain['mesh_settings'][:patch_names] = patch_names
					$domain['mesh_settings'][:number_of_patches] = patch_names.length					
					
					# Update the list in the dialog by executing the following javascript code
					js_command = "patchList = document.getElementById('patchList');
								  patchList.remove(#{index_in_list});
								  patchList.options[0].selected = true;"
					$dlg_enp.execute_script(js_command)													
				}							
			}			
			
			
			##########################################################################################
			# This call back function is processed if the user wants to save the changes of patch addition
			$dlg_enp.add_action_callback("set_applyChanges") { |dialog3, params3|
				$dlg_enp.close	
				
				# This step is extremely nescessary. In what follows, the groups that are created must be duplicated.
				# The new duplicate is then exploded so as to have all the faces in the group as independant entities.
				# This is done because overlapping faces may cause a problem. If the user selected a face, which is
				# coplanar to another face, and the selected faces also lies within the outer loop of the other face 
				# like a window in a wall where the window and the wall are coplanar and in addition the window
				# is within the outer loop of the wall, then the selected face is then put in a group, what happens to 
				# the other face?
				# What happens is that the selected face is no more a face, it is a group. So it is now separated from
				# the wall. Selecting the wall, will disregard the presence of the window face, which is no more a face,
				# and we'll be having two overlapping groups. Thus, it is a good practice to make duplicates of the groups
				# in order for the other faces to maintain their edges/borders ...
				
				# 1) Remove hidden faces that are redundant
				@model.entities.each { |ent|
					if ent.is_a?(Sketchup::Face) && ent.hidden?
						@model.entities.erase_entities(ent)
					end
				}
				
				# 2) create unassigned
				patch_names = $domain['mesh_settings'][:patch_names]
				
				unassigned_faces = M_foamKit.get_unassigned_face_entities
				unless unassigned_faces.empty?	
					if unassigned_faces.length < 50
						unassigned_faces.each_with_index { |face, index|
							unless face.hidden?
								patch = @model.entities.add_group(face)
								patch_name = "unassigned_wall#{index+1}"
								patch.name = patch_name
								
								# Add the new group to the array of patch names in the
								# database after sorting according to alphabetical order
								patch_names.push(patch_name)
								patch_names = patch_names.sort_by{|m| m.downcase}
								$domain['mesh_settings'][:patch_names] = patch_names
								$domain['mesh_settings'][:number_of_patches] = patch_names.length	

								patch_duplicate = patch.copy
								array = patch_duplicate.explode	

								# Put all the exploded entities in a single array
								array.each_with_index { |ex_ent, index|
									if ex_ent.is_a?(Sketchup::Face)
										ex_ent.hidden = true
									end
								}
							end
							
						}
					else
						patch = @model.entities.add_group(unassigned_faces)
						patch_name = "unassigned_walls"
						patch.name = patch_name
						
						# Add the new group to the array of patch names in the
						# database after sorting according to alphabetical order
						patch_names.push(patch_name)
						patch_names = patch_names.sort_by{|m| m.downcase}
						$domain['mesh_settings'][:patch_names] = patch_names
						$domain['mesh_settings'][:number_of_patches] = patch_names.length						
					end
					
					# After creating all the groups, the recently exploded entities are now erased
					# as they are redundant to the model
					@model.entities.each { |ent|
						if ent.is_a?(Sketchup::Face) && ent.hidden?
							@model.entities.erase_entities(ent)
						end
					}
				
				end
				
				# Turn all patches' faces white
				M_foamKit.change_patches_color("White")
				
				###############################################################################
				# Loop over stored patches, predict their boundary types, and fill in the recommended mesh settings
				# based on the type							
				mesh_settings = $domain['mesh_settings']
				mesh_settings[:min_refLevel] = []
				mesh_settings[:max_refLevel] = []
				mesh_settings[:addLayers] = []
				mesh_settings[:nSurfaceLayers] = []
				
				standard_mesh_settings = M_foamKit.get_standard_mesh_settings							
				patch_names.each { |patch_name|
					boundary_type = M_foamKit.get_predicted_boundary_type(patch_name)
					patch_settings = standard_mesh_settings[boundary_type]
					
					mesh_settings[:min_refLevel].push(patch_settings[:min_refLevel])
					mesh_settings[:max_refLevel].push(patch_settings[:max_refLevel])
					mesh_settings[:addLayers].push(patch_settings[:addLayers])
					mesh_settings[:nSurfaceLayers].push(patch_settings[:nSurfaceLayers])				
				}
				$domain['mesh_settings'] = mesh_settings
								
				# Export default system dictionaries. These files may invoked rather at a later
				# step. They are exported currently because they must be available once we want to call the
				# snappyHexMesh utility
				M_foamKit.export_controlDict
				M_foamKit.export_fvSchemes
				M_foamKit.export_fvSolution	


				# Export default gravity, transport and turbulence properties. They may be invoked later on
				unless $domain['g_properties'][:gravity].nil?
					M_foamKit.export_g_properties
				end
				M_foamKit.export_transport_properties
				unless $domain['turbulence_properties'][:turbulence].nil?
					M_foamKit.export_turbulence_properties
				end	

				# Get standard boundary conditions
				standard_bcs = M_foamKit.get_standard_bcs($domain['application']['name'])
				
				# Get required fields by the solver and the turbulence model
				required_fields = M_foamKit.get_required_fields
				
				# Loop over fields and store data
				required_fields.each { |field|
					# create a secondary hash structure to include bcs for every required field
					$domain['boundary_conditions'][field] = Hash.new
					
					# Store patch attributes based on the predicted boundary type
					patch_names.each { |patch_name|							
						boundary_type = M_foamKit.get_predicted_boundary_type(patch_name)
						$domain['boundary_conditions'][field][patch_name] = Hash.new
						standard_bcs[field][boundary_type].each { |key, value|
							$domain['boundary_conditions'][field][patch_name][key] = value						
						}
						$domain['boundary_types'][patch_name] = boundary_type
					}
					M_foamKit.export_field(field, $domain['boundary_conditions'][field])						
				}

				# Enable meshing, constant settings, boundary conditions settings comomands in foamKit toolbar					
				M_foamKit.enable_tool_command("pre")
												
				######################################################################################
				# Update the mesh settings dialog

				mesh_settings = $domain['mesh_settings']
				patch_list_length = mesh_settings[:number_of_patches]
				
				patchList_block = ""
				patchOptionList_block = ""				
				patch_names.each_with_index { |patch_name, index|
					if index < patch_list_length-1
						patchList_block = patchList_block +
						"{
							name: #{'"'}#{patch_name}#{'"'},
							min_refLevel: #{'"'}#{mesh_settings[:min_refLevel][index]}#{'"'},
							max_refLevel: #{'"'}#{mesh_settings[:max_refLevel][index]}#{'"'},
							addLayers: #{mesh_settings[:addLayers][index]},
							numberOfLayers: #{'"'}#{mesh_settings[:nSurfaceLayers][index]}#{'"'}
						},\n"
					else
						patchList_block = patchList_block +
						"{
							name: #{'"'}#{patch_name}#{'"'},
							min_refLevel: #{'"'}#{mesh_settings[:min_refLevel][index]}#{'"'},
							max_refLevel: #{'"'}#{mesh_settings[:max_refLevel][index]}#{'"'},
							addLayers: #{mesh_settings[:addLayers][index]},
							numberOfLayers: #{'"'}#{mesh_settings[:nSurfaceLayers][index]}#{'"'}
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
				
				thickness = mesh_settings[:thickness]
				expansionRatio = mesh_settings[:expansionRatio]
				locationInMesh = mesh_settings[:locationInMesh]				
				
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
				$dlg_m.set_position(50, 50)
			}
			
			# Upon selecting any of the patches in the list in the dialog, the corresponding faces in the geometry
			# will be turned green
			$dlg_enp.add_action_callback("call_selectPatches") { |dialog, params|
				M_foamKit.change_patches_color("White")
				
				selected_patch_names = params.split(',') rescue []
				selected_patch_names.each { |selected_patch_name|
					patch = M_foamKit.get_entity(selected_patch_name, "Group")
					patch.material = "Green"
				} 				
			}

			# This call back function renames an exisiting patch/patches
			# This call back function renames an exisiting patch/patches
			$dlg_enp.add_action_callback("set_changeName") { |dialog, params|
				# Retrieve selected patches from the dialog
				selected_patch_names = params.split(',') rescue []
				
				# Call patch names array from project attributes database					
				patch_names = $domain['mesh_settings'][:patch_names]												
				
				# Create an auxiliary dialog and set the corresponding html
				dlg_cn = UI::WebDialog.new("Change Name", false, "foamKit", 400, 250, 0, 0, true)
				dlg_cn.set_background_color("f3f0f0")
				
				html = File.read("#{dir}/html/edit_patch_name.html")
				dlg_cn.set_html(html)	
				
				# Set the new name of the patch/patches
				dlg_cn.add_action_callback("set_patchName") { |dialog, params|
					patch_name = dialog.get_element_value("patchName")
					patch_name = M_foamKit.convert_name(patch_name)
					
					# Turn all patches white (faster way - different than other spots of the code)
					M_foamKit.change_patches_color("White")
					
					# Loop over selected patches and rename them. If muli=tiple patches are
					# selected, then rename them all with the same name except that add an index
					# at the end
					selected_patch_names.each_with_index { |selected_patch, index|
						patch = M_foamKit.get_entity(selected_patch, "Group")
						if selected_patch_names.length>1
							new_patch_name = "#{patch_name}#{index+1}"
							patch.name = new_patch_name
						else
							if patch_name==selected_patch
								next
							else								
								# Check if the new name exists. If yes, add an index to its end
								str_length = patch_name.length
								while patch_names.include?(patch_name)
									index = patch_name.gsub(/[^\d]/, '').to_i
									patch_name = "#{patch_name[0..str_length-1]}#{index+1}"
								end
								new_patch_name = patch_name
								patch.name = new_patch_name
							end
						end
						
						index_of_patch = patch_names.index(selected_patch)
						patch_names[index_of_patch] = new_patch_name
						patch_names = patch_names.sort_by{|m| m.downcase}
						
						# Update the main dialog with the new patch names
						index_in_list = patch_names.index(new_patch_name)
						js_command = "var patchList = document.getElementById('patchList');
									  patchList.remove(#{index_of_patch});
									  var option = document.createElement('option');
									  option.text = '#{new_patch_name}';
									  option.value = '#{new_patch_name}';
									  patchList.add(option, #{index_in_list});
									  patchList.options[#{index_in_list}].selected = true;"
						
						$dlg_enp.execute_script(js_command)
						
						# Turn the current patch green
						patch.material = "Green"
					}
					$domain['mesh_settings'][:patch_names] = patch_names
					$domain['mesh_settings'][:number_of_patches] = patch_names.length					
					
					dlg_cn.close															
				}
				dlg_cn.set_size(310, 180)
				dlg_cn.set_position(50, 50)  
				dlg_cn.show
			}
			
			$dlg_enp.set_size(373, 295)
			$dlg_enp.set_position(50, 50)
			$dlg_enp.show			
						
		end	
		
	end	# end of class << self

end # end of module M_foamKit