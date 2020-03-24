require 'sketchup'
require 'fileutils'

module M_foamKit

	module M_calculations
			
		def self.get_average(arr)
			avg = arr.inject{ |sum, el| sum + el }.to_f / arr.size
		end	
		
		def self.get_length_scale(direction = "none")
			bounds = M_foamKit.get_bounds
			arr_x = []
			arr_y = []
			arr_z = []
			bounds.each_with_index { |(key, value), index|
				x = value[0]
				y = value[1]
				z = value[2]
				
				arr_x[index] = x
				arr_y[index] = y
				arr_z[index] = z
			}
			min_x = arr_x.min
			min_y = arr_y.min
			min_z = arr_z.min
			
			max_x = arr_x.max
			max_y = arr_y.max
			max_z = arr_z.max

			x_range = max_x - min_x
			y_range = max_y - min_y
			z_range = max_z - min_z		
			
			if direction=="none"
				length_scale = get_average([x_range, y_range, z_range])		
			elsif  direction=="x"
				length_scale = x_range
			elsif  direction=="y"
				length_scale = y_range
			elsif  direction=="z"
				length_scale = z_range
			end
		end
		
		def self.get_domain_center_point(bounds = M_foamKit.get_bounds)
			arr_x = []
			arr_y = []
			arr_z = []
			bounds.each_with_index { |(key, value), index|
				x = value[0]
				y = value[1]
				z = value[2]
				
				arr_x[index] = x
				arr_y[index] = y
				arr_z[index] = z
			}
			min_x = arr_x.min
			min_y = arr_y.min
			min_z = arr_z.min
			
			max_x = arr_x.max
			max_y = arr_y.max
			max_z = arr_z.max

			center_point = [get_average([min_x, max_x]), get_average([min_y, max_y]), get_average([min_z, max_z])]
		end
		
		def	self.get_magnitude(arr)
			unless arr.is_a?(Array)
				arr = [arr]
			end
			sum = 0.0
			arr.each { |el|
				sum = sum + el**2
			}
			mag = sum**0.5
		end
	
		# Calculate turbulent energy "k"
		def self.calculate_k(u, i)
			k = 1.5 * (u * i)**2
			if k < 0.0001
				k = 0.0
			end
		end
		
		# Calculate dissipation rate "epsilon"
		def self.calculate_epsilon(cmu, k, l)			
			epsilon = cmu**0.75 * k**1.5 / l
			if epsilon < 0.0001
				epsilon = 0.0
			end
		end	

		def self.round_bounds(bounds)
			directions = [[-1,-1,-1], [1,-1,-1], [1,1,-1], [-1,1,-1], [-1,-1,1], [1,-1,1], [1,1,1], [-1,1,1]]
			bounds1 = Hash.new
			bounds.each_with_index { |(key, value), index|
				bounds1[key] = M_foamKit::M_calculations.shift_numeric(value, 10, directions[index])
			}
			return bounds1
		end	
		
		def self.shift_numeric(num, percentage, direction)
			if num.is_a?(Array)
				num1 = []
				num.each_with_index { |el, index|
					el = el.to_f
					unless el==0.0
						el = el + direction[index] * percentage * el / 100
					end
					num1.push(el)
				}
				return num1
			else
				num = num.to_f
				unless num==0.0
					el = el + direction[index] * percentage * el / 100
				else
					return num
				end
			end
		end
		
		def self.match(r, arr)
			levels = []
			
			if r[0]==r.max
				levels.push("high")
			elsif r[0]==r.min
				levels.push("low")
			else
				levels.push("medium")
			end
			
			if r[1]==r.max
				levels.push("high")
			elsif r[1]==r.min
				levels.push("low")
			else
				levels.push("medium")
			end
			
			if r[2]==r.max
				levels.push("high")
			elsif r[2]==r.min
				levels.push("low")
			else
				levels.push("medium")
			end			
			
			arr.each { |el|
				weights = []
				if el[0]==el.max
					weights.push("high")
				elsif el[0]==el.min
					weights.push("low")
				else
					weights.push("medium")
				end
				
				if el[1]==el.max
					weights.push("high")
				elsif el[1]==el.min
					weights.push("low")
				else
					weights.push("medium")
				end
				
				if el[2]==el.max
					weights.push("high")
				elsif el[2]==el.min
					weights.push("low")
				else
					weights.push("medium")
				end	
				
				if levels==weights
					return el
				end
			}	
			return nil
		end
		
	end # end of module M_calculations
end # end of module M_foamKit