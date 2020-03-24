require 'sketchup'
require 'fileutils'

module M_foamKit

	module M_dialog
		@dir = File.dirname(__FILE__)				
		@title = 'foamKit UI'	
		@model = Sketchup.active_model	
		
		def self.dialog_constant_properties		
			
			####################################################################################
			# The dialog variable dlg_cp is global because it is to be updated at some point out of the scope
			# of this function
			$dlg_cp = UI::WebDialog.new("Set Constant Properties", false, "foamKit", 400, 250, 0, 0, true);
			$dlg_cp.set_background_color("f3f0f0")											
			
			turbulence_properties = $domain['turbulence_properties']
			g_properties = $domain['g_properties']
			
			# Retrieve fluid properties
			working_fluid = $domain['working_fluid']		
			suggested_fluids = M_foamKit.get_suggested_fluids								
			
			# Read appropriate html file
			if g_properties[:gravity].nil? && turbulence_properties[:turbulence].nil? 
				html0 = File.read("#{@dir}/html/constant_properties_fluids.html")
				
				# Update html by populating the fluid list with the available fluids
				fluidList_block = ""
				suggested_fluids.each { |suggested_fluid|							
					if suggested_fluid==working_fluid
						fluidList_block = fluidList_block +
						"<option selected=#{'"'}selected#{'"'} value=#{'"'}#{suggested_fluid}#{'"'}>#{suggested_fluid}</option>\n"
					else
						fluidList_block = fluidList_block +
						"<option value=#{'"'}#{suggested_fluid}#{'"'}>#{suggested_fluid}</option>\n"
					end								
				}						
				html1 = M_foamKit.update_html(html0, "--fluidList--", fluidList_block)

				# Set html
				$dlg_cp.set_html(html1)		
				$dlg_cp.set_size(330, 240)	
				
			##########################################################################################
			elsif g_properties[:gravity].nil? && !turbulence_properties[:turbulence].nil? 
				html0 = File.read("#{@dir}/html/constant_properties_fluids_turbulence.html")
				
				# Update html by populating the fluid list with the available fluids
				fluidList_block = ""
				suggested_fluids.each { |suggested_fluid|							
					if suggested_fluid==working_fluid
						fluidList_block = fluidList_block +
						"<option selected=#{'"'}selected#{'"'} value=#{'"'}#{suggested_fluid}#{'"'}>#{suggested_fluid}</option>\n"
					else
						fluidList_block = fluidList_block +
						"<option value=#{'"'}#{suggested_fluid}#{'"'}>#{suggested_fluid}</option>\n"
					end								
				}						
				html1 = M_foamKit.update_html(html0, "--fluidList--", fluidList_block)													
				
				# Retrieve turbulence properties
				turbulence = turbulence_properties[:turbulence]
				recommended_turbulence_model = turbulence_properties[:RASModel]				
				suggested_turbulence_models = M_foamKit.get_suggested_turbulence_models	
				
				# Update the turbulence checkbox with the stored/default value
				if turbulence
					state = 'checked="checked"'
				else
					state = ''
				end
				html2 = M_foamKit.update_html(html1, "--turbulenceDisabled--", state, "in_place")
				
				# Update html by populating the turbulence models list with the suggested ones				
				turbulenceModel_block = ""
				suggested_turbulence_models.each { |suggested_turbulence_model|							
					if suggested_turbulence_model==recommended_turbulence_model
						turbulenceModel_block = turbulenceModel_block +
						"<option selected=#{'"'}selected#{'"'} value=#{'"'}#{suggested_turbulence_model}#{'"'}>#{suggested_turbulence_model}</option>\n"
					else
						turbulenceModel_block = turbulenceModel_block +
						"<option value=#{'"'}#{suggested_turbulence_model}#{'"'}>#{suggested_turbulence_model}</option>\n"
					end								
				}						
				html3 = M_foamKit.update_html(html2, "--modelList--", turbulenceModel_block)
				
				# Set html
				$dlg_cp.set_html(html3)	
				$dlg_cp.set_size(330, 340)				
				
			##########################################################################################	
			elsif !g_properties[:gravity].nil? && turbulence_properties[:turbulence].nil? 
				html0 = File.read("#{@dir}/html/constant_properties_gravity_fluids.html")

				# Update the gravity checkbox with the stored/default value
				gravity = g_properties[:gravity]
				gravity_value = g_properties[:value]
				if gravity
					state = 'checked="checked"'
				else
					state = ''
				end
				html1 = M_foamKit.update_html(html0, ["--gravityDisabled--", "--xGravity--", "--yGravity--", "--zGravity--"], 
				[state, "value=#{'"'}#{gravity_value[0]}#{'"'}", "value=#{'"'}#{gravity_value[1]}#{'"'}", "value=#{'"'}#{gravity_value[2]}#{'"'}"], "in_place")				
				
				# Update html by populating the fluid list with the available fluids
				fluidList_block = ""
				suggested_fluids.each { |suggested_fluid|							
					if suggested_fluid==working_fluid
						fluidList_block = fluidList_block +
						"<option selected=#{'"'}selected#{'"'} value=#{'"'}#{suggested_fluid}#{'"'}>#{suggested_fluid}</option>\n"
					else
						fluidList_block = fluidList_block +
						"<option value=#{'"'}#{suggested_fluid}#{'"'}>#{suggested_fluid}</option>\n"
					end								
				}						
				html2 = M_foamKit.update_html(html1, "--fluidList--", fluidList_block)				
								
				# Set html
				$dlg_cp.set_html(html2)	
				$dlg_cp.set_size(330, 420)	
				
			##########################################################################################
			elsif !g_properties[:gravity].nil? && !turbulence_properties[:turbulence].nil?
				html0 = File.read("#{@dir}/html/constant_properties.html")
				
				# Update the gravity checkbox with the stored/default value
				gravity = g_properties[:gravity]
				gravity_value = g_properties[:value]
				if gravity
					state = 'checked="checked"'
				else
					state = ''
				end
				html1 = M_foamKit.update_html(html0, ["--gravityDisabled--", "--xGravity--", "--yGravity--", "--zGravity--"], 
				[state, "value=#{'"'}#{gravity_value[0]}#{'"'}", "value=#{'"'}#{gravity_value[1]}#{'"'}", "value=#{'"'}#{gravity_value[2]}#{'"'}"], "in_place")			
				
				# Update html by populating the fluid list with the available fluids
				fluidList_block = ""
				suggested_fluids.each { |suggested_fluid|							
					if suggested_fluid==working_fluid
						fluidList_block = fluidList_block +
						"<option selected=#{'"'}selected#{'"'} value=#{'"'}#{suggested_fluid}#{'"'}>#{suggested_fluid}</option>\n"
					else
						fluidList_block = fluidList_block +
						"<option value=#{'"'}#{suggested_fluid}#{'"'}>#{suggested_fluid}</option>\n"
					end								
				}						
				html2 = M_foamKit.update_html(html1, "--fluidList--", fluidList_block)													
				
				# Retrieve turbulence properties
				turbulence = turbulence_properties[:turbulence]
				recommended_turbulence_model = turbulence_properties[:RASModel]				
				suggested_turbulence_models = M_foamKit.get_suggested_turbulence_models	
				
				# Update the turbulence checkbox with the stored/default value
				if turbulence
					state = 'checked="checked"'
				else
					state = ''
				end
				html3 = M_foamKit.update_html(html2, "--turbulenceDisabled--", state, "in_place")					
								
				# Update html by populating the turbulence models list with the suggested ones				
				turbulenceModel_block = ""
				suggested_turbulence_models.each { |suggested_turbulence_model|							
					if suggested_turbulence_model==recommended_turbulence_model
						turbulenceModel_block = turbulenceModel_block +
						"<option selected=#{'"'}selected#{'"'} value=#{'"'}#{suggested_turbulence_model}#{'"'}>#{suggested_turbulence_model}</option>\n"
					else
						turbulenceModel_block = turbulenceModel_block +
						"<option value=#{'"'}#{suggested_turbulence_model}#{'"'}>#{suggested_turbulence_model}</option>\n"
					end								
				}						
				html4 = M_foamKit.update_html(html3, "--modelList--", turbulenceModel_block)
				
				# Set html
				$dlg_cp.set_html(html4)
				$dlg_cp.set_size(330, 510)
				
			end
			
			$dlg_cp.set_position(150, 120)
			$dlg_cp.show

			####################################################################################
			# This call back function is processed whenever the user wants to edit an existing fluid in 
			# the list of available fluids, whether standard or user-defined
			$dlg_cp.add_action_callback("call_editFluid") { |dialog, params|
				M_foamKit::M_dialog.dialog_fluid_properties
			}		
			
			####################################################################################
			# This call back function is processed whenever the user wants to apply the changes in gravity, fluid properties, 
			# and turbulence properties
			$dlg_cp.add_action_callback("call_applyChanges") { |dialog, params|
				$dlg_cp.close
				constant_properties = params.split(',') rescue []
				
				if g_properties[:gravity].nil? && turbulence_properties[:turbulence].nil? 
					####
				elsif g_properties[:gravity].nil? && !turbulence_properties[:turbulence].nil?
					turbulence_properties[:turbulence] = M_foamKit.to_boolean(constant_properties[0])
					turbulence_properties[:RASModel] = constant_properties[1]
					$domain['turbulence_properties'] = turbulence_properties
					
				elsif !g_properties[:gravity].nil? && turbulence_properties[:turbulence].nil? 
					g_properties[:gravity] = M_foamKit.to_boolean(constant_properties[0])
					g_properties[:value] = [constant_properties[1], constant_properties[2], constant_properties[3]]
					$domain['g_properties'] = g_properties	
					
				elsif !g_properties[:gravity].nil? && !turbulence_properties[:turbulence].nil?
					g_properties[:gravity] = M_foamKit.to_boolean(constant_properties[0])
					g_properties[:value] = [constant_properties[1], constant_properties[2], constant_properties[3]]
					$domain['g_properties'] = g_properties	
					
					turbulence_properties[:turbulence] = M_foamKit.to_boolean(constant_properties[4])
					turbulence_properties[:RASModel] = constant_properties[5]
					$domain['turbulence_properties'] = turbulence_properties					
				end				
				
				################################################################################
				# Write the OpenFOAM constant properties files
				unless $domain['g_properties'][:gravity].nil?
					M_foamKit.export_g_properties
				end
				M_foamKit.export_transport_properties
				unless $domain['turbulence_properties'][:turbulence].nil?
					M_foamKit.export_turbulence_properties
				end	
				
				
				################################################################################
				
				M_foamKit.update_milestones("properties_assigned")
				if M_foamKit.milestone_accomplished?("pre")
					M_foamKit.enable_tool_command("solve")
				end	

				# Update icon
				M_foamKit.adjust_icon("properties", "done")	
				
				M_foamKit.update_progress
			}			
			
		end
	
	end # module M_dialog
	
end # module M_foamKit	