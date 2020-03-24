module M_foamKit

	module M_exportSurfaces
		
		class << self
		
			def exportSUGroupsAsSTLSurfaces(exportDir = "C:/Users/Mahdi/OpenFOAM")		  
				model = Sketchup.active_model

				patch_names = $domain['mesh_settings'][:patch_names]				
				patch_names.each_with_index { |patch_name, index|
					path = "#{exportDir}/Sketchup/#{$domain['project_name']}/constant/triSurface/#{patch_name}.stl"
					filemode = 'w:ASCII-8BIT'      
					file = File.new(path, filemode)      

					scale = scale_factor('Model Units')
					write_header(file, patch_name)
					facet_count = find_faces(file, M_foamKit.get_entity(patch_name, "Group"), 0, scale, Geom::Transformation.new)      
					write_footer(file, facet_count, patch_name)									
				}				
			end
	
			def find_faces(file, group, facet_count, scale, tform)
				group.entities.each do |entity|
					if entity.is_a?(Sketchup::Face)
						facet_count += write_face(file, entity, scale, tform * group.transformation)
					end
				end
				return facet_count
			end
	
			def write_face(file, face, scale, tform)
			  normal = face.normal
			  normal.transform!(tform)
			  normal.normalize!
			  mesh = face.mesh(0)
			  mesh.transform!(tform)
			  facets_written = write_face_ascii(file, scale, mesh, normal)
			  return(facets_written)
			end
	
			def write_face_ascii(file, scale, mesh, normal)
			  vertex_order = get_vertex_order(mesh.points, normal)
			  facets_written = 0
			  polygons = mesh.polygons
			  polygons.each do |polygon|
				if (polygon.length == 3)
				  file.write("facet normal #{normal.x} #{normal.y} #{normal.z}\n")
				  file.write("  outer loop\n")
				  for j in vertex_order do
					pt = mesh.point_at(polygon[j].abs)
					pt = pt.to_a.map{|e| e * scale}
					file.write("    vertex #{M_foamKit.from_model_units_to_meter(pt.x)} #{M_foamKit.from_model_units_to_meter(pt.y)} #{M_foamKit.from_model_units_to_meter(pt.z)}\n")
				  end
				  file.write("  endloop\nendfacet\n")
				  facets_written += 1
				end
			  end
			  return(facets_written)
			end
	
			def write_header(file, patchName)
			  file.write("solid #{patchName}\n")
			end
	
			def write_footer(file, facet_count, patchName)
			  file.write("endsolid #{patchName}\n")
			  file.close
			end
	
			def defin(instance)
			  if instance.respond_to?(:definition)
				return instance.definition
			  elsif instance.is_a?(Sketchup::Group)
				if instance.entities.parent.instances.include?(instance)
				  return instance.entities.parent
				else
				  Sketchup.active_model.definitions.each { |definition|
					return definition if definition.instances.include?(instance)
				  }
				end
			  elsif instance.is_a?(Sketchup::Image)
				Sketchup.active_model.definitions.each { |definition|
				  if definition.image? && definition.instances.include?(instance)
					return definition
				  end
				}
			  end
			  return nil
			end
	
			def get_vertex_order(positions, face_normal)
				calculated_normal = (positions[1] - positions[0]).cross( (positions[2] - positions[0]) )
				order = [0, 1, 2]
				order.reverse! if calculated_normal.dot(face_normal) < 0
				order
			end
	
			def scale_factor(unit_key)
				if unit_key == 'Model Units'
					selected_key = M_foamKit.model_units
				else
					selected_key = unit_key
				end
				case selected_key
				when 'Meters'
					factor = 0.0254
				when 'Centimeters'
					factor = 2.54
				when 'Millimeters'
					factor = 25.4
				when 'Feet'
					factor = 0.0833333333333333
				when 'Inches'
					factor = 1.0
				end
				factor
			end

		end
	
	end # end ExportSUGroupsAsSTLSurfaces
	
end # end M_foamKit