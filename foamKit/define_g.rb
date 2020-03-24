module M_foamKit	
	
	def self.define_g
		
		# Retrieve gravity settings from domain
		
		g_properties = $domain['g_properties']
		gravity = g_properties[:gravity]
		if gravity
			value = g_properties[:value]
		else
			value = [0, 0, 0]
		end
		
		return body_text =
"/*--------------------------------*- C++ -*----------------------------------*\\
| =========                 |                                                 |
| \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox           |
|  \\    /   O peration     | Version:  4.1                                   |
|   \\  /    A nd           | Web:      www.OpenFOAM.org                      |
|    \\/     M anipulation  |                                                 |
\*---------------------------------------------------------------------------*/
FoamFile
{
    version     2.0;
    format      ascii;
    class       uniformDimensionedVectorField;
    location    #{'"'}constant#{'"'};
    object      g;
}
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

dimensions      [0 1 -2 0 0 0 0];
value           (#{value[0]} #{value[1]} #{value[2]});


// ************************************************************************* //"
	end
	
end	