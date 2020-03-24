module M_foamKit
	@model = Sketchup.active_model

	def self.define_snappyHexMeshDict(patch_list)

		min_refLevel = $domain['mesh_settings'][:min_refLevel]
		max_refLevel = $domain['mesh_settings'][:max_refLevel]	
		addLayers = $domain['mesh_settings'][:addLayers]
		nSurfaceLayers = $domain['mesh_settings'][:nSurfaceLayers]	
		thickness = M_foamKit.from_model_units_to_meter($domain['mesh_settings'][:thickness])
		expansionRatio = $domain['mesh_settings'][:expansionRatio]
		locationInMesh = M_foamKit.from_model_units_to_meter($domain['mesh_settings'][:locationInMesh])
		
		geo_block = ""
		features_block = ""
		ref_block = ""
		layers_block = ""	
		
		patch_list.each_with_index { |name, index|			
		
			geo_block = geo_block +
	"
	#{name}.stl
	{
		type triSurfaceMesh;
		name #{name};
	}\n"
			
			featureFile = '"'+"#{name}.eMesh"+'"'
			features_block = features_block +
		"
		{
			file #{featureFile};
			level 3;
		}\n"	

			ref_block = ref_block +
		"
		#{name}
		{
			level (#{min_refLevel[index]} #{max_refLevel[index]});
		}\n"
					
			if addLayers[index]
				layers_block = layers_block +
			"
		#{name}
		{
			nSurfaceLayers #{nSurfaceLayers[index]};
		}\n"				
			end			
						
		
        }		
		
		return body_text = "
		
/*--------------------------------*- C++ -*----------------------------------*\\
| =========                 |                                                 |
| \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox           |
|  \\    /   O peration     | Version:  plus                                  |
|   \\  /    A nd           | Web:      www.OpenFOAM.org                      |
|    \\/     M anipulation  |                                                 |
\*---------------------------------------------------------------------------*/
FoamFile
{
	version     2.0;
	format      ascii;
	class       dictionary;
	object      snappyHexMeshDict;
}
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

castellatedMesh true;
snap            true;
addLayers       #{addLayers.include?(true)};


geometry
{
	#{geo_block}
};

castellatedMeshControls
{
	maxLocalCells 1000000;
	maxGlobalCells 2000000;
	minRefinementCells 10;
	maxLoadUnbalance 0.10;
	nCellsBetweenLevels 1;

	features
	(
		#{features_block}
	);

	refinementSurfaces
	{
		#{ref_block}
	}  

	resolveFeatureAngle 80;
	refinementRegions
	{	
		volume 
		{
			mode distance; 
			levels ((1e15 3));
		}
	}
	locationInMesh (#{locationInMesh[0]} #{locationInMesh[1]} #{locationInMesh[2]});
	allowFreeStandingZoneFaces true;
}

snapControls
{
	nSmoothPatch 3;
	tolerance 4.0;
	nSolveIter 30;
	nRelaxIter 5;
	nFeatureSnapIter 15;		

	implicitFeatureSnap false;
	explicitFeatureSnap true;
	multiRegionFeatureSnap false;

}

addLayersControls
{
	relativeSizes false;
	layers
	{
		#{layers_block}
	}

	expansionRatio #{expansionRatio};
	thickness #{thickness};
	
	minThickness 0.0008;
	nGrow 0;
	featureAngle 80;
	nRelaxIter 3;
	nSmoothSurfaceNormals 1;
	nSmoothNormals 3;
	nSmoothThickness 10;
	maxFaceThicknessRatio 0.5;
	maxThicknessToMedialRatio 0.3;
	minMedianAxisAngle 130;
	nBufferCellsNoExtrude 0;
	nLayerIter 50;
}

meshQualityControls
{
	maxNonOrtho 65;
	maxBoundarySkewness 20;
	maxInternalSkewness 4;
	maxConcave 80;
	minFlatness 0.5;
	minVol 1e-13;
	minTetQuality 1e-9;
	minArea -1;
	minTwist 0.02;
	minDeterminant 0.001;
	minFaceWeight 0.02;
	minVolRatio 0.01;
	minTriangleTwist -1;

	// Advanced

	nSmoothScale 4;
	errorReduction 0.75;
}

debug 0;
mergeTolerance 1E-6;


// ************************************************************************* //"
	
	end
	
end