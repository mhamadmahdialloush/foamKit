module M_foamKit	
	
	def self.define_residuals
		
		# Retrieve required fields
		required_fields = M_foamKit.get_required_fields
		fields_set = ""
		required_fields.each { |field_name|
			fields_set << " #{field_name}"
		}
				
		return body_text =
"/*--------------------------------*- C++ -*----------------------------------*\
  =========                 |
  \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox
|  \\    /   O peration     | Version:  plus                                  |  
|   \\  /    A nd           | Web:      www.OpenFOAM.com                      |
     \\/     M anipulation  |
-------------------------------------------------------------------------------
Description
    For specified fields, writes out the initial residuals for the first
    solution of each time step; for non-scalar fields (e.g. vectors), writes
    the largest of the residuals for each component (e.g. x, y, z).

\*---------------------------------------------------------------------------*/

#includeEtc #{'"'}caseDicts/postProcessing/numerical/residuals.cfg#{'"'}

fields (#{fields_set});

// ************************************************************************* //"
	end
	
end	