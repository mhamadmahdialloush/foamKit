require 'sketchup'
require 'fileutils'

module M_foamKit
	
	module M_graphics
		
		@model = Sketchup.active_model
		@dir = File.dirname(__FILE__)

		class << self		
			
			def quiver(scale, skip, min, max, location, name)							
				velocity_data, centroid_data = get_velocity_field_and_centroids(location)
				
				unless velocity_data.nil?

					u = []
					v = []
					w = []
					x = []
					y = []
					z = []				
					if velocity_data.length==1
						fixed_value = velocity_data[0]
						centroid_data.each { |centroid|
							x.push(centroid[0])
							y.push(centroid[1])
							z.push(centroid[2])
							u.push(fixed_value[0])
							v.push(fixed_value[1])
							w.push(fixed_value[2])
						}	
						vel_magnitudes = Array.new(centroid_data.length, M_foamKit::M_calculations.get_magnitude(fixed_value))												
					else
						centroid_data.each_with_index { |centroid, index|
							x.push(centroid[0])
							y.push(centroid[1])
							z.push(centroid[2])
							u.push(velocity_data[index][0])
							v.push(velocity_data[index][1])
							w.push(velocity_data[index][2])
						}
						if location.index("new_surface")
							vel_magnitudes = get_field_magnitudes("U", location, "post")
						else
							vel_magnitudes = get_field_magnitudes("U", location)
						end						
					end
					
					num_vcts = x.length
					length_scale = M_foamKit::M_calculations.get_length_scale
					velocity_scale = get_velocity_scale

					mult = 0.2 * scale * length_scale / velocity_scale
					
					if skip==0
						i_vcts = Array(0..num_vcts-1)
					elsif skip>=num_vcts
						return nil
					else
						i_vcts = []
						i_vct = 0
						while i_vct<num_vcts
							i_vcts.push(i_vct)
							i_vct += skip
						end
					end

					mesh = Geom::PolygonMesh.new
					
					arrow_head_to_body_ratio = 0.4				
					i_vcts.each { |i_vct|
						vel_mag = vel_magnitudes[i_vct]
						
						position = Geom::Point3d.new(x[i_vct].m, y[i_vct].m, z[i_vct].m)
						
						if vel_mag<min || vel_mag>max || vel_mag<min+0.01*(max-min)
							# @model.entities.add_cpoint(position)
							next 
						end
																		
						z_axis = Geom::Vector3d.new(u[i_vct] / vel_mag, v[i_vct] / vel_mag, w[i_vct] / vel_mag)
						tr = Geom::Transformation.new(position, z_axis)
						
						cylinder_height = vel_mag * (1.0 - arrow_head_to_body_ratio) * mult
						cone_height = vel_mag * arrow_head_to_body_ratio * mult
						
						cylinder_radius = vel_mag * mult * 0.03										
						
						if location=="internalField"
							mesh = get_arrow_points_simple(mesh, tr, M_foamKit.from_model_units_to_inch(cylinder_radius), 
							M_foamKit.from_model_units_to_inch(cylinder_height), M_foamKit.from_model_units_to_inch(cone_height)) 					
						else
							mesh = get_arrow_points_simple(mesh, tr, M_foamKit.from_model_units_to_inch(cylinder_radius), 
							M_foamKit.from_model_units_to_inch(cylinder_height), M_foamKit.from_model_units_to_inch(cone_height))					
						end					
					}
					
					material = Sketchup.active_model.materials.add('red')
					smooth_flags = Geom::PolygonMesh::SMOOTH_SOFT_EDGES
					group = Sketchup.active_model.entities.add_group
					group.name = name
					group.entities.fill_from_mesh(mesh, true, smooth_flags, material)
				end
				
			end
			
			def get_velocity_scale
				min, max = get_velocity_bounds
				vel_scale = max - min
				return vel_scale if vel_scale>0.0001
				return max if vel_scale<=0.0001
			end			
			
			def get_velocity_bounds(location = "internalField")
				vel_magnitudes = get_field_magnitudes("U", location)	
				min = vel_magnitudes.min
				max = vel_magnitudes.max
				return min, max
			end			
			
			def get_field_magnitudes(field, location, filetype="result")
				latest_time_step = M_foamKit.get_latest_field_timestep
				if filetype=="post"
					field_data, centroid_data = read_field_data(field, latest_time_step, location, filetype)				
				else
					field_data = read_field_data(field, latest_time_step, location)
				end
				num_pts = field_data.length
				
				field_dim, field_class = M_foamKit.get_field_dimensions_and_class(field)
				field_magnitudes = []
				if field_class=="volVectorField"					
					num_pts.times do |i_pt|
						magnitude = M_foamKit::M_calculations.get_magnitude(field_data[i_pt])
						field_magnitudes.push(magnitude)
					end									
				else
					num_pts.times do |i_pt|
						field_magnitudes.push(field_data[i_pt])
					end				
				end				
				return field_magnitudes									
			end						
			
			def map_scalar_to_color(scalar, min, max)
				rgb_colors = M_foamKit::Data.get_rgb
				num_color = rgb_colors.length
				mapped_scalar = (scalar - min) / (max - min) * (num_color - 1)
				color_index = mapped_scalar.to_i
				keys = rgb_colors.keys
				color = rgb_colors[keys[color_index]]
				return Sketchup::Color.new(color[0], color[1], color[2])
			end
			
			def get_velocity_field_and_centroids(location)
				latest_time_step = M_foamKit.get_latest_field_timestep
				if location.index("new_surface")
					velocity_data, centroid_data = read_field_data("U", latest_time_step, location, "post")
				else
					velocity_data = read_field_data("U", latest_time_step, location)
					centroid_data = read_field_data("C", latest_time_step, location)			
				end
				return velocity_data, centroid_data
			end
			
			def read_field_data(field, timestep, location, filetype="result")
				export_dir = M_foamKit.get_export_dir
				if filetype=="result"
					content = File.read(export_dir+"/Sketchup/#{$domain['project_name']}/#{timestep}/#{field}") 
					lines = convert_text_to_array(content)
					
					field_data = []
					if location=="internalField"
						field_start_line_index = 22
						field_class = lines[19][lines[19].index("<")+1..lines[19].index(">")-1]
						numpts = lines[20].to_i					
					else
						start_check_for_nonuniform_list = false				
						lines.each_with_index { |line, index|					
							if line.index(location)
								start_check_for_nonuniform_list = true
							end
							
							if start_check_for_nonuniform_list
								if line.index("}")
									return nil
								end						
								line_strings = line.split
								if line_strings[0] == "value"
									if line_strings[1] == "nonuniform"
										field_start_line_index = index+3 
										field_class = line[line.index("<")+1..line.index(">")-1]
										numpts = lines[index+1].to_i
										break
									elsif line_strings[1] = "uniform"
										field_data = [line[line.index("(")+1..line.index(")")-1].split(" ").map {|el| el.to_f}]
										break
									end
								end
							end
						}	
					end
					
					if field_data.empty?
						lines[field_start_line_index..field_start_line_index+numpts-1].each { |line|
							if field_class=="vector"
								vector = line[line.index("(")+1..line.index(")")-1].split(" ").map {|el| el.to_f}
								field_data.push(vector)
							else
								scalar = line.to_f
								field_data.push(scalar)				
							end			
						}
					end
					return field_data
				else
					content = File.read(export_dir+"/Sketchup/#{$domain['project_name']}/postProcessing/sample/#{timestep}/#{field}_#{location}.raw") 
					lines = convert_text_to_array(content)
					field_data = []
					centroid_data = []
					lines.each_with_index { |line, index|
						if index > 1
							array = line.split(" ")
							centroid_data.push([array[0].to_f, array[1].to_f, array[2].to_f])
							field_data.push([array[3].to_f, array[4].to_f, array[5].to_f])
						end
					}
					return field_data, centroid_data
				end									
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
			
			def get_arrow_points(mesh, tr, radius, cylinder_height, cone_height)

				alpha = radius / 4
				beta = alpha * 3**0.5
				
				# cylinder base				
				pt1 = Geom::Point3d.new([0, -2*alpha, 0])
				pt2 = Geom::Point3d.new([-beta, -alpha, 0])
				pt3 = Geom::Point3d.new([-beta, alpha, 0])
				pt4 = Geom::Point3d.new([0, 2*alpha, 0])
				pt5 = Geom::Point3d.new([beta, alpha, 0])
				pt6 = Geom::Point3d.new([beta, -alpha, 0])
				mesh.add_polygon([pt1.transform!(tr), pt2.transform!(tr), pt3.transform!(tr), pt4.transform!(tr), pt5.transform!(tr), pt6.transform!(tr)])

				# face1
				pt1 = Geom::Point3d.new([0, -2*alpha, 0])
				pt2 = Geom::Point3d.new([-beta, -alpha, 0])
				pt4 = Geom::Point3d.new([0, -2*alpha, cylinder_height])
				pt3 = Geom::Point3d.new([-beta, -alpha, cylinder_height])
				mesh.add_polygon([pt1.transform!(tr), pt2.transform!(tr), pt3.transform!(tr), pt4.transform!(tr)])

				# face2
				pt1 = Geom::Point3d.new([-beta, -alpha, 0])
				pt2 = Geom::Point3d.new([-beta, alpha, 0])
				pt4 = Geom::Point3d.new([-beta, -alpha, cylinder_height])
				pt3 = Geom::Point3d.new([-beta, alpha, cylinder_height])
				mesh.add_polygon([pt1.transform!(tr), pt2.transform!(tr), pt3.transform!(tr), pt4.transform!(tr)])
				
				# face3
				pt1 = Geom::Point3d.new([-beta, alpha, 0])
				pt2 = Geom::Point3d.new([0, 2*alpha, 0])
				pt4 = Geom::Point3d.new([-beta, alpha, cylinder_height])
				pt3 = Geom::Point3d.new([0, 2*alpha, cylinder_height])
				mesh.add_polygon([pt1.transform!(tr), pt2.transform!(tr), pt3.transform!(tr), pt4.transform!(tr)])

				# face4
				pt1 = Geom::Point3d.new([0, 2*alpha, 0])
				pt2 = Geom::Point3d.new([beta, alpha, 0])
				pt4 = Geom::Point3d.new([0, 2*alpha, cylinder_height])
				pt3 = Geom::Point3d.new([beta, alpha, cylinder_height])
				mesh.add_polygon([pt1.transform!(tr), pt2.transform!(tr), pt3.transform!(tr), pt4.transform!(tr)])

				# face5
				pt1 = Geom::Point3d.new([beta, alpha, 0])
				pt2 = Geom::Point3d.new([beta, -alpha, 0])
				pt4 = Geom::Point3d.new([beta, alpha, cylinder_height])
				pt3 = Geom::Point3d.new([beta, -alpha, cylinder_height])
				mesh.add_polygon([pt1.transform!(tr), pt2.transform!(tr), pt3.transform!(tr), pt4.transform!(tr)])

				# face6
				pt1 = Geom::Point3d.new([beta, -alpha, 0])
				pt2 = Geom::Point3d.new([0, -2*alpha, 0])
				pt4 = Geom::Point3d.new([beta, -alpha, cylinder_height])
				pt3 = Geom::Point3d.new([0, -2*alpha, cylinder_height])
				mesh.add_polygon([pt1.transform!(tr), pt2.transform!(tr), pt3.transform!(tr), pt4.transform!(tr)])
				
				# cone base
				pt1 = Geom::Point3d.new([0, -2*alpha, cylinder_height])
				pt2 = Geom::Point3d.new([-beta, -alpha, cylinder_height])
				pt3 = Geom::Point3d.new([-beta, alpha, cylinder_height])
				pt4 = Geom::Point3d.new([0, 2*alpha, cylinder_height])
				pt5 = Geom::Point3d.new([beta, alpha, cylinder_height])
				pt6 = Geom::Point3d.new([beta, -alpha, cylinder_height])
				pt7 = Geom::Point3d.new([0, -2*alpha*2, cylinder_height])
				pt8 = Geom::Point3d.new([-beta*2, -alpha*2, cylinder_height])
				pt9 = Geom::Point3d.new([-beta*2, alpha*2, cylinder_height])
				pt10 = Geom::Point3d.new([0, 2*alpha*2, cylinder_height])
				pt11 = Geom::Point3d.new([beta*2, alpha*2, cylinder_height])
				pt12 = Geom::Point3d.new([beta*2, -alpha*2, cylinder_height])			
				mesh.add_polygon([pt1.transform!(tr), pt2.transform!(tr), pt3.transform!(tr), pt4.transform!(tr), pt5.transform!(tr), pt6.transform!(tr), pt7.transform!(tr), pt8.transform!(tr), pt9.transform!(tr), pt10.transform!(tr), pt11.transform!(tr), pt12.transform!(tr)])

				# cone face1
				pt1 = Geom::Point3d.new([0, -2*alpha*2, cylinder_height])
				pt2 = Geom::Point3d.new([-beta*2, -alpha*2, cylinder_height])
				pt3 = Geom::Point3d.new([0, 0, cylinder_height+cone_height])
				mesh.add_polygon([pt1.transform!(tr), pt2.transform!(tr), pt3.transform!(tr)])	

				# cone face2
				pt1 = Geom::Point3d.new([-beta*2, -alpha*2, cylinder_height])
				pt2 = Geom::Point3d.new([-beta*2, alpha*2, cylinder_height])
				pt3 = Geom::Point3d.new([0, 0, cylinder_height+cone_height])
				mesh.add_polygon([pt1.transform!(tr), pt2.transform!(tr), pt3.transform!(tr)])

				# cone face3
				pt1 = Geom::Point3d.new([-beta*2, alpha*2, cylinder_height])
				pt2 = Geom::Point3d.new([0, 2*alpha*2, cylinder_height])
				pt3 = Geom::Point3d.new([0, 0, cylinder_height+cone_height])
				mesh.add_polygon([pt1.transform!(tr), pt2.transform!(tr), pt3.transform!(tr)])

				# cone face4
				pt1 = Geom::Point3d.new([0, 2*alpha*2, cylinder_height])
				pt2 = Geom::Point3d.new([beta*2, alpha*2, cylinder_height])
				pt3 = Geom::Point3d.new([0, 0, cylinder_height+cone_height])
				mesh.add_polygon([pt1.transform!(tr), pt2.transform!(tr), pt3.transform!(tr)])

				# cone face5
				pt1 = Geom::Point3d.new([beta*2, alpha*2, cylinder_height])
				pt2 = Geom::Point3d.new([beta*2, -alpha*2, cylinder_height])
				pt3 = Geom::Point3d.new([0, 0, cylinder_height+cone_height])
				mesh.add_polygon([pt1.transform!(tr), pt2.transform!(tr), pt3.transform!(tr)])

				# cone face6
				pt1 = Geom::Point3d.new([beta*2, -alpha*2, cylinder_height])
				pt2 = Geom::Point3d.new([0, -2*alpha*2, cylinder_height])
				pt3 = Geom::Point3d.new([0, 0, cylinder_height+cone_height])
				mesh.add_polygon([pt1.transform!(tr), pt2.transform!(tr), pt3.transform!(tr)])								
						
				return mesh
			end
			
			def get_arrow_points_simple(mesh, tr, radius, cylinder_height, cone_height)

				s = 3.0 * radius / (3.0**0.5)
				alpha = s / 2.0
				beta = s * (3.0**0.5) / 6.0
				
				# cylinder base				
				pt1 = Geom::Point3d.new([alpha, -beta, 0])
				pt2 = Geom::Point3d.new([-alpha, -beta, 0])
				pt3 = Geom::Point3d.new([0, 2*beta, 0])
				mesh.add_polygon([pt1.transform!(tr), pt2.transform!(tr), pt3.transform!(tr)])

				# face1
				pt1 = Geom::Point3d.new([alpha, -beta, 0])
				pt2 = Geom::Point3d.new([-alpha, -beta, 0])
				pt3 = Geom::Point3d.new([-alpha, -beta, cylinder_height])
				pt4 = Geom::Point3d.new([alpha, -beta, cylinder_height])
				mesh.add_polygon([pt1.transform!(tr), pt2.transform!(tr), pt3.transform!(tr), pt4.transform!(tr)])

				# face2
				pt1 = Geom::Point3d.new([-alpha, -beta, 0])
				pt2 = Geom::Point3d.new([0, 2*beta, 0])
				pt3 = Geom::Point3d.new([0, 2*beta, cylinder_height])
				pt4 = Geom::Point3d.new([-alpha, -beta, cylinder_height])
				mesh.add_polygon([pt1.transform!(tr), pt2.transform!(tr), pt3.transform!(tr), pt4.transform!(tr)])
				
				# face3
				pt1 = Geom::Point3d.new([0, 2*beta, 0])
				pt2 = Geom::Point3d.new([alpha, -beta, 0])
				pt3 = Geom::Point3d.new([alpha, -beta, cylinder_height])
				pt4 = Geom::Point3d.new([0, 2*beta, cylinder_height])
				mesh.add_polygon([pt1.transform!(tr), pt2.transform!(tr), pt3.transform!(tr), pt4.transform!(tr)])
				
				# cone base
				pt1 = Geom::Point3d.new([alpha, -beta, cylinder_height])
				pt2 = Geom::Point3d.new([-alpha, -beta, cylinder_height])
				pt3 = Geom::Point3d.new([0, 2*beta, cylinder_height])
				pt4 = Geom::Point3d.new([3*alpha, -3*beta, cylinder_height])
				pt5 = Geom::Point3d.new([-3*alpha, -3*beta, cylinder_height])
				pt6 = Geom::Point3d.new([0, 6*beta, cylinder_height])		
				mesh.add_polygon([pt1.transform!(tr), pt2.transform!(tr), pt3.transform!(tr), pt4.transform!(tr), pt5.transform!(tr), pt6.transform!(tr)])

				# cone face1
				pt1 = Geom::Point3d.new([3*alpha, -3*beta, cylinder_height])
				pt2 = Geom::Point3d.new([-3*alpha, -3*beta, cylinder_height])
				pt3 = Geom::Point3d.new([0, 0, cylinder_height+cone_height])
				mesh.add_polygon([pt1.transform!(tr), pt2.transform!(tr), pt3.transform!(tr)])	

				# cone face2
				pt1 = Geom::Point3d.new([-3*alpha, -3*beta, cylinder_height])
				pt2 = Geom::Point3d.new([0, 6*beta, cylinder_height])
				pt3 = Geom::Point3d.new([0, 0, cylinder_height+cone_height])
				mesh.add_polygon([pt1.transform!(tr), pt2.transform!(tr), pt3.transform!(tr)])

				# cone face3
				pt1 = Geom::Point3d.new([0, 6*beta, cylinder_height])
				pt2 = Geom::Point3d.new([3*alpha, -3*beta, cylinder_height])
				pt3 = Geom::Point3d.new([0, 0, cylinder_height+cone_height])
				mesh.add_polygon([pt1.transform!(tr), pt2.transform!(tr), pt3.transform!(tr)])							
						
				return mesh
			end	

			def dialog_vel_vectors				
				$dlg_vv = UI::WebDialog.new("Plot Vectors", false, "foamKit", 400, 250, 0, 0, true)
				$dlg_vv.set_background_color("f3f0f0")
				$dlg_vv.set_size(265, 485)
				$dlg_vv.set_position(0, 0)
				html0 = File.read("#{@dir}/html/plot_vectors.html")		
				
				new_surfaces = @model.get_attribute("project_attributes", "new_surfaces")
				surface_index = @model.get_attribute("counters", "new_surface_index")				
				
				# adjust min
				min, max = get_velocity_bounds						
				min = min + 0.01 * (max - min)
				
				html1 = M_foamKit.update_html(html0, ["--min--", "--max--"], [min.to_s, max.to_s], "in_place")

				mesh_settings = $domain['mesh_settings']			
				patch_names = mesh_settings[:patch_names]

				patchList_block = ""	
				patch_names.each_with_index { |patch_name, index|			
					if index == 0
						patchList_block = patchList_block +
						"<option selected=#{'"'}selected#{'"'} value=#{'"'}#{patch_name}#{'"'}>#{patch_name}</option>\n"
					else
						patchList_block = patchList_block +
						"<option value=#{'"'}#{patch_name}#{'"'}>#{patch_name}</option>\n"
					end				
				}
				
				patchList_block = patchList_block +
				"<option value=#{'"'}internalField#{'"'}>internalField</option>\n"					
				
				if new_surfaces
					new_surfaces.each { |surface|
						patchList_block = patchList_block +
						"<option value=#{'"'}#{surface}#{'"'}>#{surface}</option>\n"					
					}
				end			
				
				html2 = M_foamKit.update_html(html1, "--locations--", patchList_block)
							
				$dlg_vv.set_html(html2)
				$dlg_vv.show
				
				$dlg_vv.add_action_callback("call_new") { |dialog1, params1|
					$dlg_vv.set_position(3000, 3000)										

					@model.entities.grep(Sketchup::Group).each { |group|
						if group.name[0..10]=="vector_plot"
							group.hidden = true
						end
					}
					
					stored_mesh_settings = $domain['mesh_settings']
					patch_names = stored_mesh_settings[:patch_names]				
					patch_names.each { |patch_name|
						patch = M_foamKit.get_entity(patch_name, "Group")
						patch.material.alpha = 1
					}					
					
					available_locations = params1.split(',') rescue []
					
					$dlg_cs = UI::WebDialog.new("Create New Surface", false, "foamKit", 400, 250, 0, 0, true)
					$dlg_cs.set_background_color("f3f0f0")
					$dlg_cs.set_size(310, 420)
					$dlg_cs.set_position(0, 0)
					
					html = File.read("#{@dir}/html/surface.html")
					$dlg_cs.set_html(html)
					
					$dlg_cs.show
					
					$dlg_cs.add_action_callback("call_select_method") { |dialog2, params2|	
						insert_method = dialog2.get_element_value("insert_method")
						if insert_method=="three_points"
							html = File.read("#{@dir}/html/section.html")
							$dlg_cs.set_html(html)	
							$dlg_cs.set_size(310, 530)							
						elsif insert_method=="point_normal"
							html = File.read("#{@dir}/html/surface.html")
							$dlg_cs.set_html(html)
							$dlg_cs.set_size(310, 420)
						end
					}
					
					$dlg_cs.add_action_callback("call_3pcut") { |dialog2, params2|
						M_foamKit.linetool	
						$dlg_cs.set_position(3000, 3000)
					}					
										
					$dlg_cs.add_action_callback("call_create") { |dialog2, params2|												
						$dlg_vv.set_position(0, 0)
						
						if surface_index.nil?
							surface_index = 0
						else
							surface_index += 1
						end
						new_surfaces = [] if new_surfaces.nil?
						
						insert_method = dialog2.get_element_value("insert_method")
						if insert_method=="point_normal"
							x = dialog2.get_element_value("x").to_f
							y = dialog2.get_element_value("y").to_f
							z = dialog2.get_element_value("z").to_f
							i = dialog2.get_element_value("xdir").to_f
							j = dialog2.get_element_value("ydir").to_f
							k = dialog2.get_element_value("zdir").to_f							
							M_foamKit.export_sample("U", [x, y, z], [i, j, k], "new_surface#{surface_index}")
							
							# Check if OpenFOAM is running
							unless M_foamKit.OF_running?
								M_foamKit.start_OF_container
							end							
							process_pid = M_foamKit.exec_command(["postProcess -func sample -latestTime"])
						elsif insert_method=="three_points"
							points_array = @model.get_attribute("project_attributes", "section_points")
							section = @model.entities.add_face(points_array)
							n = section.normal
							i = n[0]
							j = n[1]
							k = n[2]
							
							# Erase face and edges of the section
							edges = section.edges
							section.erase!
							edges.each {|edge| edge.erase!}
							
							x = points_array[0][0].to_m
							y = points_array[0][1].to_m
							z = points_array[0][2].to_m
							
							M_foamKit.export_sample("U", [x, y, z], [i, j, k], "new_surface#{surface_index}")
							
							# Check if OpenFOAM is running
							unless M_foamKit.OF_running?
								M_foamKit.start_OF_container
							end							
							process_pid = M_foamKit.exec_command(["postProcess -func sample -latestTime"])							
						end
												
						@model.set_attribute("project_attributes", "new_surfaces", new_surfaces.push("new_surface#{surface_index}"))
						@model.set_attribute("counters", "new_surface_index", surface_index)
						
						html0 = File.read("#{@dir}/html/plot_vectors.html")		
						
						# adjust min
						min, max = get_velocity_bounds						
						min = min + 0.01 * (max - min)
						
						html1 = M_foamKit.update_html(html0, ["--min--", "--max--"], [min.to_s, max.to_s], "in_place")

						mesh_settings = $domain['mesh_settings']			
						patch_names = mesh_settings[:patch_names]

						list_block = ""	
						patch_names.each_with_index { |patch_name, index|			
							list_block = list_block +
							"<option value=#{'"'}#{patch_name}#{'"'}>#{patch_name}</option>\n"				
						}
						
						list_block = list_block +
						"<option value=#{'"'}internalField#{'"'}>internalField</option>\n"					
						
						if new_surfaces
							new_surfaces.each_with_index { |surface, index|
								if surface=="new_surface#{surface_index}"
									list_block = list_block +
									"<option selected=#{'"'}selected#{'"'} value=#{'"'}#{surface}#{'"'}>#{surface}</option>\n"									
								else
									list_block = list_block +
									"<option value=#{'"'}#{surface}#{'"'}>#{surface}</option>\n"																	
								end				
							}
						end								
						
						html2 = M_foamKit.update_html(html1, "--locations--", list_block)
									
						$dlg_vv.set_html(html2)
						$dlg_cs.close
					}
				}	

				$dlg_vv.add_action_callback("call_show_mesh") { |dialog, params|
					state = dialog.get_element_value("showMesh") 
					if state=="1"
						mesh = M_foamKit.get_entity("mesh", "Group")
						mesh.hidden = false if mesh
						stored_mesh_settings = $domain['mesh_settings']
						patch_names = stored_mesh_settings[:patch_names]				
						patch_names.each { |patch_name|
							patch = M_foamKit.get_entity(patch_name, "Group")
							patch.material.alpha = 0
						}
					else
						mesh = M_foamKit.get_entity("mesh", "Group")
						mesh.hidden = true if mesh
						stored_mesh_settings = $domain['mesh_settings']
						patch_names = stored_mesh_settings[:patch_names]				
						patch_names.each { |patch_name|
							patch = M_foamKit.get_entity(patch_name, "Group")
							patch.material.alpha = 0.3
						}					
					end
				}					
				
				$dlg_vv.add_action_callback("call_plot") { |dialog, params|										
					
					# Delete vectors if exist
					vector_plot = M_foamKit.get_entity("vector_plot", "Group")
					unless vector_plot.nil?
						vector_plot.erase!
					end	

					stored_mesh_settings = $domain['mesh_settings']
					patch_names = stored_mesh_settings[:patch_names]				
					patch_names.each { |patch_name|
						patch = M_foamKit.get_entity(patch_name, "Group")
						patch.material.alpha = 0.3
					}					
					
					scale = dialog.get_element_value("scale").to_f
					skip = dialog.get_element_value("skip").to_i
					min = dialog.get_element_value("min").to_f
					max = dialog.get_element_value("max").to_f	
					
					selected_locations = params.split(',') rescue []
					selected_locations.each_with_index { |selected_location, index|
						plot_name = "vector_plot#{index}"
						quiver(scale, skip, min, max, selected_location, plot_name)
					}					
				}
				$dlg_vv.add_action_callback("call_done") { |dialog, params|
					@model.entities.grep(Sketchup::Group).each { |group|
						if group.name[0..10]=="vector_plot"
							group.hidden = true
						end
					}
					
					stored_mesh_settings = $domain['mesh_settings']
					patch_names = stored_mesh_settings[:patch_names]				
					patch_names.each { |patch_name|
						patch = M_foamKit.get_entity(patch_name, "Group")
						patch.material.alpha = 1
					}
					$dlg_vv.close
				}	

				vector_plot = M_foamKit.get_entity("vector_plot", "Group")
				unless vector_plot.nil?
					vector_plot.hidden = false 
					stored_mesh_settings = $domain['mesh_settings']
					patch_names = stored_mesh_settings[:patch_names]				
					patch_names.each { |patch_name|
						patch = M_foamKit.get_entity(patch_name, "Group")
						patch.material.alpha = 0.3
					}				
				end
			end			
			
		end
		
	end # end of module M_graphics
end # end of module M_foamKit