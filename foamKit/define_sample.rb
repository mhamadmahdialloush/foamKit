require 'sketchup'

module M_foamKit

	@model = Sketchup.active_model
	
	def self.define_sample(field, point, normal, surface_name)
	
		x = point[0]
		y = point[1]
		z = point[2]
		i = normal[0]
		j = normal[1]
		k = normal[2]
	
		return text_body = 
"/*--------------------------------*- C++ -*----------------------------------*\
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
    class       dictionary;
    location    #{'"'}system#{'"'};
    object      sample;
}
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

type surfaces;
libs            (#{'"'}libsampling.so#{'"'});

interpolationScheme cellPoint;
surfaceFormat       raw;

surfaces
(
	#{surface_name}
	{
		type	cuttingPlane;
		planeType pointAndNormal;
		
        pointAndNormalDict
        {
            basePoint (#{x} #{y} #{z});
            normalVector (#{i} #{j} #{k});
        }		
		interpolate   true;
	}
);

fields          (#{field});


// ************************************************************************* //"

	end
	
	
	
end
