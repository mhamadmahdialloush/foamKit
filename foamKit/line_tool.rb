require 'sketchup.rb'

module M_foamKit

	class LineTool

		# This is the standard Ruby initialize method that is called when you create
		# a new object.
		def initialize
			@dir = File.dirname(__FILE__)
			@model = Sketchup.active_model
			@cursor_slice = UI.create_cursor(@dir + "/cursor/Slice.png", 3, 8)			
			@ip1 = nil
			@ip2 = nil
			@ip3 = nil
			@line = nil
			@xdown = 0
			@ydown = 0
		end

		# The activate method is called by SketchUp when the tool is first selected.
		# it is a good place to put most of your initialization
		def activate
			# The Sketchup::InputPoint class is used to get 3D points from screen
			# positions.  It uses the SketchUp inferencing code.
			# In this tool, we will have two points for the endpoints of the line.
			@ip1 = Sketchup::InputPoint.new
			@ip2 = Sketchup::InputPoint.new
			@ip3 = Sketchup::InputPoint.new
			@ip = Sketchup::InputPoint.new
			@drawn = false
			onSetCursor
			self.reset(nil)
		end
		
		def onSetCursor
			UI.set_cursor(@cursor_slice)
		end		

		# deactivate is called when the tool is deactivated because
		# a different tool was selected
		def deactivate(view)
			view.invalidate if @drawn
		end		

		# The onMouseMove method is called whenever the user moves the mouse.
		# because it is called so often, it is important to try to make it efficient.
		# In a lot of tools, your main interaction will occur in this method.
		def onMouseMove(flags, x, y, view)			
			if( @state == 0 )
				# We are getting the first end of the line.  Call the pick method
				# on the InputPoint to get a 3D position from the 2D screen position
				# that is bassed as an argument to this method.
				@ip.pick view, x, y
				if( @ip != @ip1 )
					# if the point has changed from the last one we got, then
					# see if we need to display the point.  We need to display it
					# if it has a display representation or if the previous point
					# was displayed.  The invalidate method on the view is used
					# to tell the view that something has changed so that you need
					# to refresh the view.
					view.invalidate if( @ip.display? or @ip1.display? )
					@ip1.copy! @ip
					
					# set the tooltip that should be displayed to this point
					view.tooltip = @ip1.tooltip
				end
			elsif( @state == 1 )
				# Getting the second end of the line
				# If you pass in another InputPoint on the pick method of InputPoint
				# it uses that second point to do additional inferencing such as
				# parallel to an axis.
				@ip2.pick view, x, y, @ip1
				view.tooltip = @ip2.tooltip if( @ip2.valid? )
				view.invalidate
				
				# Update the length displayed in the VCB
				if( @ip2.valid? )
					length = @ip1.position.distance(@ip2.position)
					Sketchup::set_status_text("Select second point ...")
				end
				
				# Check to see if the mouse was moved far enough to create a line.
				# This is used so that you can create a line by either dragging
				# or doing click-move-click
				if( (x-@xdown).abs > 10 || (y-@ydown).abs > 10 )
					@dragging = true
				end
			else
				# Getting the second end of the line
				# If you pass in another InputPoint on the pick method of InputPoint
				# it uses that second point to do additional inferencing such as
				# parallel to an axis.
				@ip3.pick view, x, y, @ip2
				view.tooltip = @ip3.tooltip if( @ip3.valid? )
				view.invalidate
				
				# Update the length displayed in the VCB
				if( @ip3.valid? )
					length = @ip2.position.distance(@ip3.position)
					Sketchup::set_status_text("Select third point ...")
				end
				
				# Check to see if the mouse was moved far enough to create a line.
				# This is used so that you can create a line by either dragging
				# or doing click-move-click
				if( (x-@xdown).abs > 10 || (y-@ydown).abs > 10 )
					@dragging = true
				end
			end
		end

		# The onLButtonDOwn method is called when the user presses the left mouse button.
		def onLButtonDown(flags, x, y, view)
			# When the user clicks the first time, we switch to getting the
			# second point.  When they click a second time we create the line
			if( @state == 0 )
				@ip1.pick view, x, y
				if( @ip1.valid? )
					@state = 1
					Sketchup::set_status_text("Select second point ...")
					@xdown = x
					@ydown = y
					js_command = "document.getElementById('x').value = #{M_foamKit.from_inch_to_model_units(@ip1.position[0])};
								  document.getElementById('y').value = #{M_foamKit.from_inch_to_model_units(@ip1.position[1])};
								  document.getElementById('z').value = #{M_foamKit.from_inch_to_model_units(@ip1.position[2])};"
					$dlg_cs.execute_script(js_command)					
				end
			elsif( @state == 1 )
				@ip2.pick view, x, y
				if( @ip2.valid? )
					@line = self.create_geometry(@ip1.position, @ip2.position, view)
					@state = 2
					Sketchup::set_status_text("Select third point ...")
					@xdown = x
					@ydown = y
					js_command = "document.getElementById('x0').value = #{M_foamKit.from_inch_to_model_units(@ip2.position[0])};
								  document.getElementById('y0').value = #{M_foamKit.from_inch_to_model_units(@ip2.position[1])};
								  document.getElementById('z0').value = #{M_foamKit.from_inch_to_model_units(@ip2.position[2])};"
					$dlg_cs.execute_script(js_command)					
				end
			else
				# create the line on the third click
				if( @ip3.valid? )
					@model.set_attribute("project_attributes", "section_points", [@ip1.position, @ip2.position, @ip3.position])
					js_command = "document.getElementById('x1').value = #{M_foamKit.from_inch_to_model_units(@ip3.position[0])};
								  document.getElementById('y1').value = #{M_foamKit.from_inch_to_model_units(@ip3.position[1])};
								  document.getElementById('z1').value = #{M_foamKit.from_inch_to_model_units(@ip3.position[2])};"
					$dlg_cs.execute_script(js_command)
					$dlg_cs.set_position(0, 0)
					self.reset(view)					
					@line.erase!
					@model.select_tool(nil)
				end				
			end
			
			# Clear any inference lock
			view.lock_inference
		end

		def draw(view)
			if( @ip1.valid? )
				if( @ip1.display? )
					@ip1.draw(view)
					@drawn = true
				end
				
				if( @ip2.valid? )
					@ip2.draw(view) if( @ip2.display? )
					
					# The set_color_from_line method determines what color
					# to use to draw a line based on its direction.  For example
					# red, green or blue.
					view.set_color_from_line(@ip1, @ip2)
					self.draw_geometry(@ip1.position, @ip2.position, view)
					@drawn = true
				end
			end
			if( @ip2.valid? )
				if( @ip2.display? )
					@ip2.draw(view)
					@drawn = true
				end
				
				if( @ip3.valid? )
					@ip3.draw(view) if( @ip3.display? )
					
					# The set_color_from_line method determines what color
					# to use to draw a line based on its direction.  For example
					# red, green or blue.
					view.set_color_from_line(@ip2, @ip3)
					self.draw_geometry(@ip2.position, @ip3.position, view)
					@drawn = true
				end
			end			
		end
		
		def draw_geometry(pt1, pt2, view)
			view.draw_line(pt1, pt2)
		end		

		# onCancel is called when the user hits the escape key
		def onCancel(flag, view)
			@line.erase! unless @line.nil?
			self.reset(view)
		end

		# The following methods are not directly called from SketchUp.  They are
		# internal methods that are used to support the other methods in this class.

		# Reset the tool back to its initial state
		def reset(view)
					
			# Display a prompt on the status bar
			if @state == 2
				Sketchup::set_status_text("")
			else
				Sketchup::set_status_text("Select first point ...")
			end
			
			# This variable keeps track of which point we are currently getting
			@state = 0
			
			# clear the InputPoints
			@ip1.clear
			@ip2.clear
			@ip3.clear
			
			if( view )
				view.tooltip = nil
				view.invalidate if @drawn
			end
			
			@drawn = false
			@dragging = false
		end
		
		# Create new geometry when the user has selected two points.
		def create_geometry(p1, p2, view)
			cline = view.model.entities.add_cline(p1, p2)
			return cline
		end	

	end # class LineTool


	#-----------------------------------------------------------------------------
	# This functions is just a shortcut for selecting the new tool
	def self.linetool
		Sketchup.active_model.select_tool(M_foamKit::LineTool.new)
	end


end