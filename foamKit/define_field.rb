require 'sketchup'

module M_foamKit

	@model = Sketchup.active_model
	
	def self.define_field(field_name, field_boundary_conditions)
		
		field_dimensions, field_class = M_foamKit.get_field_dimensions_and_class(field_name)
		field_initial_condition = M_foamKit.get_field_initial_condition(field_name)	
		
		bc_block = ""
		field_boundary_conditions.each { |patch_name, patch_attributes|		
			
			# Get the standard boundary type entries of the current field
			boundary_attributes = ""
			patch_attributes.each_with_index { |(key, value), index|
			
				# Process to set the convenient number of tabs (spaces between entry and value) for the sake of organization
				tbs = M_foamKit.get_entries_tbs(key.to_s)
				
				# Concatenate the string array with the convenient entries and values
				if index==0				
					boundary_attributes = boundary_attributes + "#{key.to_s}#{tbs}#{value};"				
				else
					boundary_attributes = boundary_attributes + "\n		#{key.to_s}#{tbs}#{value};"
				end
			}
			
			# Create the boundary conditions block
			bc_block = bc_block +			
"	#{patch_name}
	{
		#{boundary_attributes}
	}\n"					
		}
	
	return text_body = 
"/*--------------------------------*- C++ -*----------------------------------*\\
| =========                 |                                                 |
| \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox           |
|  \\    /   O peration     | Version:  plus                                  |
|   \\  /    A nd           | Web:      www.OpenFOAM.com                      |
|    \\/     M anipulation  |                                                 |
\*---------------------------------------------------------------------------*/
FoamFile
{
	version     2.0;
	format      ascii;
	class       #{field_class};
	object      #{field_name};
}
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

dimensions      [#{field_dimensions[0]} #{field_dimensions[1]} #{field_dimensions[2]} #{field_dimensions[3]} #{field_dimensions[4]} #{field_dimensions[5]} #{field_dimensions[6]}];

internalField   #{field_initial_condition};

boundaryField
{
#{bc_block}
}

// ************************************************************************* //"

	end
	
	
	def self.get_entries_tbs(entry)
		# Process to print the entries and values with standard OpenFOAM tabs
		entry_string_length = entry.length
		tbs = ""
		if entry_string_length < 4
			tbs = "\t\t\t\t"
		elsif entry_string_length < 8
			tbs = "\t\t\t"
		elsif entry_string_length < 12
			tbs = "\t\t"
		elsif entry_string_length < 32
			tbs = "\t"			
		end		
	end
	
	
end
