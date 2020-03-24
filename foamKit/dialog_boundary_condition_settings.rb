require 'sketchup'
require 'fileutils'

module M_foamKit

	module M_dialog
		@dir = File.dirname(__FILE__)				
		@model = Sketchup.active_model
		
		def self.dialog_boundary_condition_settings(patch_name, boundary_type)
			$dlg_bc = UI::WebDialog.new("Set Boundary Conditions Settings", false, "foamKit", 400, 250, 0, 0, true)
			$dlg_bc.set_background_color("f3f0f0")	
			
			solver_name = $domain['application']['recommended OpenFOAM solver']
			turbulence_properties = $domain['turbulence_properties']
			
			dialog_name = "set"
			case solver_name
			when 'laplacianFoam'
				if boundary_type=="wall"
					dialog_name << "_wall_with_heat_solid"
					dialog_size = [240, 375]
				else
					UI.messagebox('Inlet boundary type is not applicable for the current application, only walls are permitted')
					return 0
				end				
			when 'simpleFoam', 'pisoFoam'
				if boundary_type=="inlet"
					if turbulence_properties[:turbulence]
						dialog_name << "_velocity_inlet_turb"
						dialog_size = [390, 565]
					else
						dialog_name << "_velocity_inlet"
						dialog_size = [390, 465]
					end				
				elsif boundary_type=="outlet"
					if turbulence_properties[:turbulence]
						dialog_name << "_turbulent_outlet"
						dialog_size = [370, 340]
					else
						dialog_name << "_laminar_outlet"
						dialog_size = [370, 220]
					end				
				elsif boundary_type=="wall"
					dialog_name << "_wall"
					dialog_size = [370, 220]			
				end
			when 'buoyantBoussinesqPimpleFoam', 'buoyantBoussinesqSimpleFoam'
				if boundary_type=="inlet"
					if turbulence_properties[:turbulence]
						dialog_name << "_velocity_inlet_temp_turb"
						dialog_size = [390, 620]
					else
						dialog_name << "_velocity_inlet_temp"
						dialog_size = [390, 515]
					end				
				elsif boundary_type=="outlet"
					if turbulence_properties[:turbulence]
						dialog_name << "_turbulent_outlet"
						dialog_size = [370, 335]
					else
						dialog_name << "_laminar_outlet"
						dialog_size = [370, 215]
					end				
				elsif boundary_type=="wall"
					dialog_name << "_wall_with_heat"
					dialog_size = [305, 565]		
				end	
			end
						
			dialog_name << "_bc"

			# Open the convenient boundary condition dialog
			html = File.read("#{@dir}/html/#{dialog_name}.html")
			
			$dlg_bc.set_size(dialog_size[0], dialog_size[1])
			$dlg_bc.set_position(150, 50)
			$dlg_bc.set_html(html)
			
			$dlg_bc.add_action_callback("switch_inlet_to_velocity") { |dialog, params|				
				dialog_name = "set"
				case solver_name
				when 'simpleFoam', 'pisoFoam'
					if turbulence_properties[:turbulence]
						dialog_name << "_velocity_inlet_turb"
						dialog_size = [390, 565]
					else
						dialog_name << "_velocity_inlet"
						dialog_size = [390, 465]
					end
				when 'buoyantBoussinesqPimpleFoam', 'buoyantBoussinesqSimpleFoam'
					if turbulence_properties[:turbulence]
						dialog_name << "_velocity_inlet_temp_turb"
						dialog_size = [390, 620]
					else
						dialog_name << "_velocity_inlet_temp"
						dialog_size = [390, 515]
					end	
				end			
				dialog_name << "_bc"
				
				$dlg_bc.set_size(dialog_size[0], dialog_size[1])			
				html = File.read("#{@dir}/html/#{dialog_name}.html")
				$dlg_bc.set_html(html)			
			}
			
			$dlg_bc.add_action_callback("switch_inlet_to_pressure") { |dialog, params|
				dialog_name = "set"
				case solver_name
				when 'simpleFoam', 'pisoFoam'
					if turbulence_properties[:turbulence]
						dialog_name << "_pressure_inlet_turb"
						dialog_size = [390, 425]
					else
						dialog_name << "_pressure_inlet"
						dialog_size = [390, 320]
					end	
				when 'buoyantBoussinesqPimpleFoam', 'buoyantBoussinesqSimpleFoam'
					if turbulence_properties[:turbulence]
						dialog_name << "_pressure_inlet_temp_turb"
						dialog_size = [390, 485]
					else
						dialog_name << "_pressure_inlet_temp"
						dialog_size = [390, 375]
					end	
				end	
				dialog_name << "_bc"
				
				$dlg_bc.set_size(dialog_size[0], dialog_size[1])
				html = File.read("#{@dir}/html/#{dialog_name}.html")
				$dlg_bc.set_html(html)
			}			
			
			# Retrieve and store data
			$dlg_bc.add_action_callback("call_applyChanges") { |dialog, params|
				case solver_name
				when 'laplacianFoam'				
					# Temperature
					isTemperature = dialog.get_element_value("isTemperature")
					isHeatFlux = dialog.get_element_value("isHeatFlux")
					isAdiabatic = dialog.get_element_value("isAdiabatic")
					value = dialog.get_element_value("TValue").to_f
					if isTemperature=="1"
						type = 'fixedValue'
					elsif isHeatFlux=="1"
						type = 'fixedValue'
					elsif isAdiabatic=="1"
						type = 'zeroGradient'
					end
					$domain['boundary_conditions']['T'][patch_name][:type] = "#{type}"
					$domain['boundary_conditions']['T'][patch_name][:value] = "#{value}"
		
				when 'simpleFoam', 'pisoFoam'
					if boundary_type=="inlet"
						if dialog_name.index("velocity")
							# Retrieve and store U settings for velocity inlet boundary condition
							insert_mode = dialog.get_element_value("insertVelMode")
							if insert_mode=="components"
								u = dialog.get_element_value("UxValue").to_f
								v = dialog.get_element_value("UyValue").to_f
								w = dialog.get_element_value("UzValue").to_f
							else
								mag = dialog.get_element_value("UmagValue").to_f
								
								# Get the normal direction vector of the patch and multiply it 
								# with the velocity magnitude
								group = M_foamKit.get_entity(patch_name, "Group")
								group.entities.each { |entity|
									if entity.is_a?(Sketchup::Face)
										e = entity.normal.transform!(group.transformation)
										if mag<0
											u = e[0] * mag
											v = e[1] * mag
											w = e[2] * mag
										else
											u = -e[0] * mag
											v = -e[1] * mag
											w = -e[2] * mag
										end
										
										# it is sufficient to get the normal from 1 face of 
										# the group assuming all the faces of this group have
										# the same normal
										break 
									end	
								}						
							end
							$domain['boundary_conditions']['U'][patch_name][:value] = "uniform (#{u} #{v} #{w})"							
						elsif dialog_name.index("pressure")
							# Retrieve and store U settings for pressure inlet boundary condition
							$domain['boundary_conditions']['U'][patch_name][:type] = "pressureInletVelocity"
							$domain['boundary_conditions']['U'][patch_name][:phi] = "phi"	
							$domain['boundary_conditions']['U'][patch_name][:rho] = "rho"								
							$domain['boundary_conditions']['U'][patch_name][:value] = "uniform (0 0 0)"
							
							p = dialog.get_element_value("pValue").to_f
							$domain['boundary_conditions']['p'][patch_name][:type] = "fixedValue"						
							$domain['boundary_conditions']['p'][patch_name][:value] = "uniform #{p}"								
						end						
						
						# Currently inactive #####################
						# if turbulence_properties[:turbulence]							
							# ti = dialog.get_element_value("IValue").to_f / 100
							# tls = dialog.get_element_value("LValue").to_f

							# Calculate turbulent energy "k" and dissipation rate "epsilon"
							# mag_U = M_foamKit::M_calculations.get_magnitude([u, v, w])
							# k = M_foamKit::M_calculations.calculate_k(mag_U, ti)
							
							# turbulence_model = turbulence_properties[:RASModel]
							# cmu = M_foamKit.get_turbulence_constants(turbulence_model, 'Cmu')	

							# epsilon = M_foamKit::M_calculations.calculate_epsilon(cmu, k, tls)					
							
							# $domain['boundary_conditions']['k'][patch_name][:value] = "uniform #{k}"						
							# $domain['boundary_conditions']['epsilon'][patch_name][:value] = "uniform #{epsilon}"
							
							# Update k and epsilon values at all the walls
							# patch_names = $domain['mesh_settings'][:patch_names]
							# boundary_types = $domain['boundary_types']
							# patch_names.each { |patch_name|
								# if boundary_types[patch_name]=="wall"
									# $domain['boundary_conditions']['k'][patch_name][:value] = "uniform #{k}"						
									# $domain['boundary_conditions']['epsilon'][patch_name][:value] = "uniform #{epsilon}"							
								# end
							# }
							
						# end		
						
					elsif boundary_type=="outlet"
						# Retrieve and store p settings
						p = dialog.get_element_value("pValue").to_f
						$domain['boundary_conditions']['p'][patch_name][:value] = "uniform #{p}"
						
					elsif boundary_type=="wall"
						isNoSlip = dialog.get_element_value("noSlip")
						if isNoSlip=="1"
							type = "noSlip"
						else
							type = "slip"
						end				
						$domain['boundary_conditions']['U'][patch_name][:type] = type
					
					end
				when 'buoyantBoussinesqPimpleFoam', 'buoyantBoussinesqSimpleFoam'
					if boundary_type=="inlet"
						if dialog_name.index("velocity")
							# Retrieve and store U settings for velocity inlet boundary condition
							insert_mode = dialog.get_element_value("insertVelMode")
							if insert_mode=="components"
								u = dialog.get_element_value("UxValue").to_f
								v = dialog.get_element_value("UyValue").to_f
								w = dialog.get_element_value("UzValue").to_f
							else
								mag = dialog.get_element_value("UmagValue").to_f
								
								# Get the normal direction vector of the patch and multiply it 
								# with the velocity magnitude
								group = M_foamKit.get_entity(patch_name, "Group")
								group.entities.each { |entity|
									if entity.is_a?(Sketchup::Face)
										e = entity.normal.transform!(group.transformation)
										if mag<0
											u = e[0] * mag
											v = e[1] * mag
											w = e[2] * mag
										else
											u = -e[0] * mag
											v = -e[1] * mag
											w = -e[2] * mag
										end
										
										# it is sufficient to get the normal from 1 face of 
										# the group assuming all the faces of this group have
										# the same normal
										break 
									end	
								}						
							end
							$domain['boundary_conditions']['U'][patch_name][:value] = "uniform (#{u} #{v} #{w})"							
						elsif dialog_name.index("pressure")
							# Retrieve and store U settings for pressure inlet boundary condition
							$domain['boundary_conditions']['U'][patch_name][:type] = "pressureInletVelocity"
							$domain['boundary_conditions']['U'][patch_name][:phi] = "phi"	
							$domain['boundary_conditions']['U'][patch_name][:rho] = "rho"								
							$domain['boundary_conditions']['U'][patch_name][:value] = "uniform (0 0 0)"
							
							p = dialog.get_element_value("pValue").to_f
							$domain['boundary_conditions']['p_rgh'][patch_name][:type] = "fixedValue"						
							$domain['boundary_conditions']['p_rgh'][patch_name][:value] = "uniform #{p}"								
						end	

						# Retrieve fixed value of temperature at the patch			
						temperature = dialog.get_element_value("TValue").to_f
						$domain['boundary_conditions']['T'][patch_name][:value] = "uniform #{temperature}"

						# Currently inactive #####################
						# if turbulence_properties[:turbulence]							
							# ti = dialog.get_element_value("IValue").to_f / 100
							# tls = dialog.get_element_value("LValue").to_f

							# Calculate turbulent energy "k" and dissipation rate "epsilon"
							# mag_U = M_foamKit::M_calculations.get_magnitude([u, v, w])
							# k = M_foamKit::M_calculations.calculate_k(mag_U, ti)
							
							# turbulence_model = turbulence_properties[:RASModel]
							# cmu = M_foamKit.get_turbulence_constants(turbulence_model, 'Cmu')	

							# epsilon = M_foamKit::M_calculations.calculate_epsilon(cmu, k, tls)					
							
							# $domain['boundary_conditions']['k'][patch_name][:value] = "uniform #{k}"						
							# $domain['boundary_conditions']['epsilon'][patch_name][:value] = "uniform #{epsilon}"
							
							# Update k and epsilon values at all the walls
							# patch_names = $domain['mesh_settings'][:patch_names]
							# boundary_types = $domain['boundary_types']
							# patch_names.each { |patch_name|
								# if boundary_types[patch_name]=="wall"
									# $domain['boundary_conditions']['k'][patch_name][:value] = "uniform #{k}"						
									# $domain['boundary_conditions']['epsilon'][patch_name][:value] = "uniform #{epsilon}"							
								# end
							# }	
							
						# end	
						
					elsif boundary_type=="outlet"
						# Retrieve and store p settings
						p = dialog.get_element_value("pValue").to_f
						$domain['boundary_conditions']['p_rgh'][patch_name][:value] = "uniform #{p}"
					
					elsif boundary_type=="wall"
						# Slip condition
						isNoSlip = dialog.get_element_value("noSlip")
						if isNoSlip=="1"
							type = "noSlip"
						else
							type = "slip"
						end				
						$domain['boundary_conditions']['U'][patch_name][:type] = type
					
						# Temperature
						isTemperature = dialog.get_element_value("isTemperature")
						isHeatFlux = dialog.get_element_value("isHeatFlux")
						isOutdoorTemperature = dialog.get_element_value("isOutdoorTemperature")
						isAdiabatic = dialog.get_element_value("isAdiabatic")
						isRadiation = dialog.get_element_value("isRadiation")	
						
						if isTemperature=="1"
							# Clear the hash first
							$domain['boundary_conditions']['T'][patch_name] = {}
							
							# Store inside the hash the corresponding info						
							type = 'fixedValue'
							value = dialog.get_element_value("TValue").to_f
							$domain['boundary_conditions']['T'][patch_name][:type] = "#{type}"
							$domain['boundary_conditions']['T'][patch_name][:value] = "#{value}"							
						elsif isHeatFlux=="1"
							# Clear the hash first
							$domain['boundary_conditions']['T'][patch_name] = {}
							
							# Store inside the hash the corresponding info
							type = 'codedMixed'
							$domain['boundary_conditions']['T'][patch_name][:type] = "#{type}"
							
							q_value = dialog.get_element_value("qValue").to_f
							$domain['boundary_conditions']['T'][patch_name][:refValue] = 'uniform 300'
							$domain['boundary_conditions']['T'][patch_name][:refGradient] = 'uniform 0'
							$domain['boundary_conditions']['T'][patch_name][:valueFraction] = 'uniform 0'
							$domain['boundary_conditions']['T'][patch_name][:name] = 'externalWallHeatFlux'
							$domain['boundary_conditions']['T'][patch_name][:code] = 
							"\n		#{'#'}{
			const scalar q = #{q_value}; // heat flux [w/m2] inwards if negative
			const scalar rho = 1.17;
			const scalar Cp = 1005;
			const fvPatch& boundaryPatch = patch();
			const volScalarField& alphaEff = db().lookupObject<volScalarField>(#{'"'}alphaEff#{'"'});
			forAll(boundaryPatch , faceI)
			{
				double kEff = rho * Cp * alphaEff.boundaryField()[boundaryPatch.index()][faceI];
				this->refGrad()[faceI] = - q / kEff;
			}						            
		#{'#'}}"							   					
						elsif isOutdoorTemperature=="1"
							# Clear the hash first
							$domain['boundary_conditions']['T'][patch_name] = {}
							
							# Store inside the hash the corresponding info						
							type = 'codedMixed'	
							$domain['boundary_conditions']['T'][patch_name][:type] = "#{type}"

							temp_out_value = dialog.get_element_value("ToutValue").to_f
							resis_value = dialog.get_element_value("RValue").to_f
							hinf = dialog.get_element_value("hinf").to_f							
							$domain['boundary_conditions']['T'][patch_name][:refValue] = 'uniform 300'
							$domain['boundary_conditions']['T'][patch_name][:refGradient] = 'uniform 0'
							$domain['boundary_conditions']['T'][patch_name][:valueFraction] = 'uniform 0'
							$domain['boundary_conditions']['T'][patch_name][:name] = 'externalWallHeatFlux'
							$domain['boundary_conditions']['T'][patch_name][:code] = 
							"\n		#{'#'}{
			// This code calculates the temperature gradient at the current patch using Fourier's law
			// of conduction:
			// gradT = q / k
			// The heat flux q from the wall outwards is calculated as follows:
			// q = (Tout - Tin)/(R + 1/hinf)
			// Where R is the thermal resistance of the wall and hinf is the
			// convective heat transfer coefficient
			// Note: the turbulent thermal conductivity (kEff) is used because the flow is
			// turbulent inside the room, and it is calculated from the turbulent 
			// thermal diffusivity field alphaEff:
			// kEff = rho * Cp * alphaEff
			//							
			const scalar Tout = 285.0; // Temperature outside wall
			const scalar R = 0.88; // Thermal resistance of wall
			const scalar hinf = 5.0; // Convective heat transfer coefficient
			const scalar rho = 1.17;
			const scalar Cp = 1005;
			const fvPatch& boundaryPatch = patch();
			const volScalarField& T = db().lookupObject<volScalarField>(#{'"'}T#{'"'});
			const volScalarField& alphaEff = db().lookupObject<volScalarField>(#{'"'}alphaEff#{'"'});
			forAll(boundaryPatch , faceI)
			{	
				double q = (T.boundaryField()[boundaryPatch.index()][faceI] - Tout) / (R + 1/hinf);
				double kEff = rho * Cp * alphaEff.boundaryField()[boundaryPatch.index()][faceI];
				this->refGrad()[faceI] = - q / kEff;
			}						            
		#{'#'}}"
						elsif isAdiabatic=="1"
							# Clear the hash first
							$domain['boundary_conditions']['T'][patch_name] = {}
							
							# Store inside the hash the corresponding info						
							type = 'zeroGradient'
							$domain['boundary_conditions']['T'][patch_name][:type] = "#{type}"							
						elsif isRadiation=="1"
							# Clear the hash first
							$domain['boundary_conditions']['T'][patch_name] = {}
							
							# Store inside the hash the corresponding info						
							type = 'fixedValue'
						end
					end	
				end
							
				$dlg_bc.close
			}

			$dlg_bc.add_action_callback("call_isTemperature") { |dialog, params|
				$dlg_bc.set_size(305, 575)
			}
			$dlg_bc.add_action_callback("call_isHeatFlux") { |dialog, params|
				$dlg_bc.set_size(305, 575)				
			}
			$dlg_bc.add_action_callback("call_isOutdoorTemperature") { |dialog, params|
				$dlg_bc.set_size(305, 625)						
			}
			$dlg_bc.add_action_callback("call_isAdiabatic") { |dialog, params|
				$dlg_bc.set_size(305, 565)						
			}	
			$dlg_bc.add_action_callback("call_isRadiation") { |dialog, params|
				$dlg_bc.set_size(305, 575)						
			}			
			
			$dlg_bc.show						
		end		
		
	end # module M_dialog
	
end # module M_foamKit