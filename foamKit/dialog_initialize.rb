require 'sketchup'
require 'fileutils'

module M_foamKit

	module M_dialog
		@dir = File.dirname(__FILE__)					
		@model = Sketchup.active_model
		
		def self.initialize_fields
			dlg = UI::WebDialog.new("Initialize Fields", false, "foamKit", 400, 250, 0, 0, true);
			dlg.set_background_color("f3f0f0")
			
			solver_name = $domain['application']['recommended OpenFOAM solver']	
			
			case solver_name
			when 'laplacianFoam'
				html = File.read("#{@dir}/html/initialize_T.html")
				dialog_size = [315, 245]
			when 'simpleFoam', 'pisoFoam'
				html = File.read("#{@dir}/html/initialize_U_p.html")	
				dialog_size = [315, 400]
			when 'buoyantBoussinesqPimpleFoam', 'buoyantBoussinesqSimpleFoam'
				html = File.read("#{@dir}/html/initialize_U_p_T.html")	
				dialog_size = [315, 490]				
			end
			
			dlg.set_html(html)
						
			dlg.add_action_callback("call_applyChanges") { |dialog, params|	
				dlg.close
				
				case solver_name
				when 'laplacianFoam'
					temp = dialog.get_element_value("T")
					$domain['initial_conditions']['T'] = "uniform #{temp}"
				when 'simpleFoam', 'pisoFoam'
					u = dialog.get_element_value("Ux") 
					v = dialog.get_element_value("Uy") 
					w = dialog.get_element_value("Uz")														  
					$domain['initial_conditions']['U'] = "uniform (#{u} #{v} #{w})"
					
					p = dialog.get_element_value("p")
					$domain['initial_conditions']['p'] = "uniform #{p}"
				when 'buoyantBoussinesqPimpleFoam', 'buoyantBoussinesqSimpleFoam'
					u = dialog.get_element_value("Ux") 
					v = dialog.get_element_value("Uy") 
					w = dialog.get_element_value("Uz")														  
					$domain['initial_conditions']['U'] = "uniform (#{u} #{v} #{w})"
					
					p = dialog.get_element_value("p")
					$domain['initial_conditions']['p'] = "uniform #{p}"
					
					temp = dialog.get_element_value("T")
					$domain['initial_conditions']['T'] = "uniform #{temp}"									
				end
				
				
				# Export again the fields to the 0 directory. The internal fields are updated, that's
				# why these files are to be exported again									
				required_fields = M_foamKit.get_required_fields
				required_fields.each { |field|
					M_foamKit.export_field(field, $domain['boundary_conditions'][field])
				}			
				
			}
			
			dlg.set_size(dialog_size[0], dialog_size[1])
			dlg.set_position(150, 120)
			dlg.show
		
		end
		
		
		
	end
	
end