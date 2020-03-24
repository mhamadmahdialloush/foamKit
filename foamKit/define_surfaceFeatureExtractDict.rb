module M_foamKit
		
	def M_foamKit.define_surfaceFeatureExtractDict(stl_surfaces)		
		surf_block = ""		
		stl_surfaces.each { |name|					
			surf_block = surf_block +
			"
#{name}.stl
{
    extractionMethod    extractFromSurface;
    extractFromSurfaceCoeffs
    {
		includedAngle   150;
    }
    writeObj                yes;    // Write options
}\n"
		
		}
		
	
		body_text = 
"/*--------------------------------*- C++ -*----------------------------------*\
| =========                 |                                                 |
| \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox           |
|  \\    /   O peration     | Version:  2.3.0                                 |
|   \\  /    A nd           | Web:      www.OpenFOAM.org                      |
|    \\/     M anipulation  |                                                 |
\*---------------------------------------------------------------------------*/
FoamFile
{
    version     2.0;
    format      ascii;
    class       dictionary;
    object      surfaceFeatureExtractDict;
}
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

#{surf_block}

// ************************************************************************* //"
	
	end
	
end