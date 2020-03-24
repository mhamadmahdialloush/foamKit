module M_foamKit

	def self.define_controlDict
		
		control_settings = $domain['control_settings']	
		
		control_block = ""
		control_settings.each { |key, value|
			tbs = M_foamKit.get_entry_tbs(key)
			control_block = control_block + "\n#{key}#{tbs}#{value};\n"		
		}	
		
		if M_foamKit.get_required_fields.include?("U")
			streamlines = "#includeFunc  streamlines"
		else
			streamlines = ""
		end
		
		return body_text = 
"/*--------------------------------*- C++ -*----------------------------------*\\
| =========                 |                                                 |
| \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox           |
|  \\    /   O peration     | Version:  2.0.1                                 |
|   \\  /    A nd           | Web:      www.OpenFOAM.com                      |
|    \\/     M anipulation  |                                                 |
\*---------------------------------------------------------------------------*/
FoamFile
{
    version     2.0;
    format      ascii;
    class       dictionary;
    location    #{'"'}system#{'"'};
    object      controlDict;
}
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //
#{control_block}


functions 
{ 
	#includeFunc  residuals
	#{streamlines}
}

// ************************************************************************* //"
		
	end
	
	def self.get_entry_tbs(entry)
		# Process to print the entries and values with standard OpenFOAM tabs
		entry_string_length = entry.length
		e_tbs = ""
		if entry_string_length < 4
			tbs = "\t\t\t\t"
		elsif entry_string_length < 8
			e_tbs = "\t\t\t"
		elsif entry_string_length < 12
			e_tbs = "\t\t"
		elsif entry_string_length < 32
			e_tbs = "\t"			
		end		
	end	
		
end # module M_foamKit