module M_foamKit		
		
	def self.define_transportProperties
		transport_properties = $domain['transport_properties']
		
		properties_block = ""
		
		transport_properties.each { |key, value|
			dimensions = M_foamKit.convert_unit(value[:unit])
			properties_block = properties_block +

"// #{key}
#{value[:symbol]}				[#{dimensions[0]} #{dimensions[1]} #{dimensions[2]} #{dimensions[3]} #{dimensions[4]} #{dimensions[5]} #{dimensions[6]}] #{value[:value]};\n
"							
		}		
		
		
		return body_text =
"/*--------------------------------*- C++ -*----------------------------------*
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
    object      transportProperties;
}

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

transportModel Newtonian;

#{properties_block}

// ************************************************************************* //"
	end

end