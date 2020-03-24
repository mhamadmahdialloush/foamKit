module M_foamKit

	def self.define_blockMeshDict(bounds)
		
		to_m = M_foamKit.get_meter_conversion_ratio
		
		return body_text =
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
	object      blockMeshDict;
}
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

convertToMeters #{to_m};

vertices
(
	(#{bounds[:pt0][0]} #{bounds[:pt0][1]} #{bounds[:pt0][2]})
	(#{bounds[:pt1][0]} #{bounds[:pt1][1]} #{bounds[:pt1][2]})
	(#{bounds[:pt2][0]} #{bounds[:pt2][1]} #{bounds[:pt2][2]})
	(#{bounds[:pt3][0]} #{bounds[:pt3][1]} #{bounds[:pt3][2]})
	(#{bounds[:pt4][0]} #{bounds[:pt4][1]} #{bounds[:pt4][2]})
	(#{bounds[:pt5][0]} #{bounds[:pt5][1]} #{bounds[:pt5][2]})
	(#{bounds[:pt6][0]} #{bounds[:pt6][1]} #{bounds[:pt6][2]})
	(#{bounds[:pt7][0]} #{bounds[:pt7][1]} #{bounds[:pt7][2]})
);

blocks
(
	hex (0 1 2 3 4 5 6 7) (5 5 5) simpleGrading (1 1 1)
);

edges
(
);

boundary
(  
   boundingbox
   {
	   type patch;
	   faces
	   (       
			(0 3 2 1)
			(4 5 6 7)
			(1 2 6 5)
			(3 0 4 7)
			(0 1 5 4)
			(2 3 7 6)
	   );
   }
);"
	end

end
