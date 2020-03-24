require 'sketchup'
require 'fileutils'

module M_foamKit

	module M_dialog
		@dir = File.dirname(__FILE__)					
		@model = Sketchup.active_model	
		
		def self.dialog_fluid_properties
			
			transport_properties = $domain['transport_properties']
			working_fluid = $domain['working_fluid'][:name]
			
			fluid_property_block = ""			
			transport_properties.each { |property_name, attributes|

				# Retrieve property name, unit, symbol and value for each required property
				property_unit = attributes[:unit]
				property_symbol = attributes[:symbol]
				property_value = attributes[:value]
				
				# Create the fluid property block which is to be set into the html																
				fluid_property_block = fluid_property_block +
"        <tr>
			<td class=#{'"'}auto-style88#{'"'}>
				&nbsp;</td>
			<td class=#{'"'}auto-style89#{'"'} colspan=#{'"'}2#{'"'}>
				&nbsp;</td>
			<td class=#{'"'}auto-style90#{'"'}>
				&nbsp;</td>
		</tr>
		<tr>
			<td class=#{'"'}auto-style88#{'"'}>
				&nbsp;</td>
			<td class=#{'"'}auto-style89#{'"'} colspan=#{'"'}2#{'"'}>
				#{property_name} [#{property_unit}]<br />
				<input id=#{'"'}#{property_symbol}#{'"'} class=#{'"'}auto-style97#{'"'} type=#{'"'}text#{'"'} value=#{'"'}#{property_value}#{'"'} /></td>
			<td class=#{'"'}auto-style90#{'"'}>
				&nbsp;</td>
		</tr>\n"
			}					
			
			####################################################################################
			$dlg_fp = UI::WebDialog.new("Set Fluid Properties", false, "foamKit", 400, 250, 0, 0, true);
			$dlg_fp.set_background_color("f3f0f0")				
			
			html0 = File.read("#{@dir}/html/fluid_properties.html")

			# Update html by displaying fluid name
			html1 = M_foamKit.update_html(html0, "--fluidName--", working_fluid, "in_place")
			
			# Update html by displaying fluid properties
			html2 = M_foamKit.update_html(html1, "--fluidProperties--", fluid_property_block)		
							
			$dlg_fp.set_html(html2)
			
			####################################################################################
			# This call back function is processed when the the user wants to apply the changes
			$dlg_fp.add_action_callback("call_applyChanges") { |dialog, params|																	
				transport_properties.each { |property_name, attributes|
					property_symbol = attributes[:symbol]
					$domain['transport_properties'][property_name][:value] = dialog.get_element_value(property_symbol)								
				}
				$dlg_fp.close
			}				
			
			####################################################################################
			number_of_properties = transport_properties.length
			
			$dlg_fp.set_size(370, 305 + 68*(number_of_properties-1))
			$dlg_fp.set_position(150, 100)
			$dlg_fp.show			
		end		

	end # module M_dialog
	
end # module M_foamKit	