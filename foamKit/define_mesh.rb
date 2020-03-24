require 'sketchup'
require 'fileutils'

module M_foamKit

	@model = Sketchup.active_model

	class Define_mesh		
		
		def initialize
			@model = Sketchup.active_model
			@export_dir = M_foamKit.get_export_dir
			@mesh = Geom::PolygonMesh.new		
		end			
		
		def import_OF_files(file_name)
			content = File.read("#{@export_dir}/Sketchup/#{$domain['project_name']}/constant/polyMesh/#{file_name}")      
		end
		
		def convert_text_to_array(txt)
		   txt_array = []
		   index = 0
		   txt.each_line { |line|
			  txt_array[index] = line
			  index += 1
		   }
		   return txt_array
		end	
		
		def create_mesh
		
			boundary = import_OF_files("boundary")
			boundingbox = boundary.index("boundingbox")
			
			if boundingbox
				UI.messagebox('Mesh generation is not complete because the chosen location of point is not within the domain! Change the locationInMesh parameter and try again')
				return nil
			else
				points_file = import_OF_files("points")
				
				# get number of points
				nPoints = convert_text_to_array(points_file)[18].to_i
				start_line = 20
				
				point_count = 0
				points = []
				
				block_started = false			
				line_index = 0
				points_file.each_line { |line|
					if line_index > start_line-1
						if block_started
							if line.index(")")
								end_line_index = line_index
								point_arr = []
								convert_text_to_array(points_file)[@start_line_index..end_line_index].each { |el| point_arr.push(el.split("\n")[0])}
								point_arr = point_arr[point_arr.index("(")+1..point_arr.index(")")-1]
								points.push(point_arr)
								block_started = false									
								point_count += 1
							end							
						else
							if line.index("(")
								block_started = true																											
								@start_line_index = line_index
								if line.index(")")
									points.push(line[line.index("(")+1..line.index(")")-1].split(" "))
									block_started = false
									point_count += 1
								end										
							end
						end
						if point_count==nPoints
							break
						end
					end
					line_index += 1
				}
				
				boundary = convert_text_to_array(boundary) 
				
				faces_file = import_OF_files("faces")			
				patch_length = $domain['mesh_settings'][:number_of_patches]		
						
				Array(1..patch_length).each_with_index { |patch, index| 		
					# get number of faces and start face of each patch
					nFaces = boundary[23 + index*7]
					unless nFaces.nil? == true
						nFaces[nFaces.index(";")] = ""
						nFaces = nFaces.split(" ")[1].to_i

						startFace = boundary[24 + index*7]           
						startFace[startFace.index(";")] = ""
						startFace = startFace.split(" ")[1].to_i

						start_line = 20 + startFace.to_i
						
						face_count = 0
						faces = []
						block_started = false
						
						line_index = 0
						faces_file.each_line { |line|
							if line_index > start_line-1
								if block_started
									if line.index(")")
										end_line_index = line_index
										face_arr = []
										convert_text_to_array(faces_file)[@start_line_index..end_line_index].each { |el| face_arr.push(el.split("\n")[0])}
										face_arr = face_arr[face_arr.index("(")+1..face_arr.index(")")-1]
										faces.push(face_arr)								
										block_started = false									
										face_count += 1
									end							
								else
									if line.index("(")
										block_started = true																											
										@start_line_index = line_index
										if line.index(")")
											faces.push(line[line.index("(")+1..line.index(")")-1].split(" "))										
											block_started = false
											face_count += 1
										end										
									end
								end
								if face_count==nFaces
									break
								end
							end
							line_index += 1
						}

						faces.each_with_index { |face, index|						
							points_indecis = face.map {|el| el.to_i}
							points_array = []
							points_indecis.each { |point_index|
								point = Geom::Point3d.new(points[point_index][0].to_f.m, points[point_index][1].to_f.m, points[point_index][2].to_f.m)														
								points_array.push(point)
							}
							@mesh.add_polygon(points_array)
						}					
					end
				}	
				return @mesh
			end
		end										
	end	# end of class Define_mesh
		
		
	class << self		
		
		def store_plot_mesh			
			new_mesh = Define_mesh.new
			mesh = new_mesh.create_mesh
			if mesh.nil?
				return nil
			end
			group = @model.entities.add_group
			group.name = "mesh"	
			
			material = @model.materials.add('White')
			material.color = "White" 
			smooth_flags = Geom::PolygonMesh::NO_SMOOTH_OR_HIDE
			group.entities.fill_from_mesh(mesh, true, smooth_flags, f_material = material, b_material = material)
			return 1
		end
		
		def plot_mesh			
			state = store_plot_mesh
			hide_geometry unless state.nil?
		end
		
		def get_mesh
			mesh = M_foamKit.get_entity("mesh", "Group")	
		end			
		
		def erase_mesh_entity		
			# Create a new group that we will include the mesh
			@model.entities.grep(Sketchup::Group).each { |group| group.erase! if group.name=="mesh" || group.name=="vector_plot"}		
		end

		def hide_geometry
			@model.entities.each { |entity|
				if entity.is_a?(Sketchup::Group) && entity.name !="mesh"
					entity.hidden = true
				end
			}      
		end
		
	end # end of class << self
	
end # end of module M_foamKit