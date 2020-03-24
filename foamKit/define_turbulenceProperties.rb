module M_foamKit		
	
	def self.define_turbulenceProperties
		
		turbulence_properties = $domain['turbulence_properties']
		
		model = turbulence_properties[:RASModel]
		
		if turbulence_properties[:turbulence]
			turbulence = "on"
		else
			turbulence = "off"
		end	
		
		
		return body_text =
"/*--------------------------------*- C++ -*----------------------------------*
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
    class       dictionary;
    location    #{'"'}constant#{'"'};
    object      turbulenceProperties;
}
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

simulationType RAS;

RAS
{
    RASModel        #{model};

    turbulence      #{turbulence};

    printCoeffs     off;
}


// ************************************************************************* //"
	end
	
end