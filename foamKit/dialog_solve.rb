require 'sketchup'
require 'fileutils'

module M_foamKit

	module M_dialog
		@dir = File.dirname(__FILE__)					
		@model = Sketchup.active_model	
	
		def self.dialog_solver	
			dlg = UI::WebDialog.new("Set Solver", false, "foamKit", 400, 250, 0, 0, true);
			dlg.set_background_color("f3f0f0")			
			
			application = $domain['application']['name']
			solver_name = $domain['application']['recommended OpenFOAM solver']	
			solver_time = M_foamKit.get_solver_time(solver_name)
			
			html0 = File.read("#{@dir}/html/run_manager.html")
			html1 = M_foamKit.update_html(html0, ["--endTime--", "--deltaT--", "--writeInterval--", "--solver_time--"], 
			[$domain['control_settings'][:endTime].to_s, $domain['control_settings'][:deltaT].to_s, $domain['control_settings'][:writeInterval].to_s, solver_time], "in_place")
			dlg.set_html(html1)	
									
			dlg.add_action_callback("call_initialize") { |dialog, params|
				M_foamKit::M_dialog.initialize_fields
			}
			
			dlg.add_action_callback("call_steady") { |dialog, params|								

				# If the OpenFOAM solver is steady by default, and a transient simulation
				# is requested, another solver of the same class is selected								
				solver_name = $domain['application']['recommended OpenFOAM solver']					
				
				# Retrieve the time option
				solver_time = M_foamKit.get_solver_time(solver_name)								
				alias_solver = M_foamKit.get_alias_solver(solver_name)
				unless alias_solver.nil?
					if solver_time=='transient'
						alias_solver = M_foamKit.get_alias_solver(solver_name)
						$domain['application']['recommended OpenFOAM solver'] = alias_solver
						$domain['schemes_settings'] = M_foamKit.get_schemes_settings(application)
						$domain['solution_settings'] = M_foamKit.get_solution_settings(application)
						$domain['control_settings'] = M_foamKit.get_control_settings(application)					
					end				
					
					js_command = "document.getElementById('endTime').value = #{$domain['control_settings'][:endTime]};
								  document.getElementById('deltaT').value = #{$domain['control_settings'][:deltaT]};
								  document.getElementById('writeInterval').value = #{$domain['control_settings'][:writeInterval]};"				
					dlg.execute_script(js_command)
				else
					$domain['schemes_settings'][:ddtSchemes] = "steadyState"
				end
			}
			
			dlg.add_action_callback("call_transient") { |dialog, params|						
				
				# If the OpenFOAM solver is steady by default, and a transient simulation
				# is requested, another solver of the same class is selected								
				solver_name = $domain['application']['recommended OpenFOAM solver']					
				
				# Retrieve the time option
				solver_time = M_foamKit.get_solver_time(solver_name)								
				
				if solver_time=='steady'
					alias_solver = M_foamKit.get_alias_solver(solver_name)
					$domain['application']['recommended OpenFOAM solver'] = alias_solver
					$domain['schemes_settings'] = M_foamKit.get_schemes_settings("#{application}_transient")
					$domain['solution_settings'] = M_foamKit.get_solution_settings("#{application}_transient")
					$domain['control_settings'] = M_foamKit.get_control_settings("#{application}_transient")

				end				
				
				js_command = "document.getElementById('endTime').value = #{$domain['control_settings'][:endTime]};
							  document.getElementById('deltaT').value = #{$domain['control_settings'][:deltaT]};
							  document.getElementById('writeInterval').value = #{$domain['control_settings'][:writeInterval]};"				
				dlg.execute_script(js_command)							
			}			
									
			dlg.add_action_callback("call_run") { |dialog, params|	
				Sketchup::set_status_text("Calculating Solution ...")
				
				dlg.close					

				$domain['control_settings'][:startFrom] = dialog.get_element_value("startFrom")
				$domain['control_settings'][:startTime] = dialog.get_element_value("startTime")
				$domain['control_settings'][:endTime] = dialog.get_element_value("endTime")
				$domain['control_settings'][:deltaT] = dialog.get_element_value("deltaT")
				$domain['control_settings'][:writeControl] = dialog.get_element_value("writeControl")
				$domain['control_settings'][:writeInterval] = dialog.get_element_value("writeInterval")
				
				$domain['n_processors'] = dialog.get_element_value("nProcessors").to_i
				
				M_foamKit.export_fvSchemes
				M_foamKit.export_fvSolution					
				M_foamKit.export_controlDict
				
				# Clear residuals file
				M_foamKit.clear_residuals_file
				
				# Export residuals dictionary
				M_foamKit.export_residuals
				
				# Check if previous run has left unwanted changes
				M_foamKit.restore_previous_run_changes
				
				# Check if OpenFOAM is running
				unless M_foamKit.OF_running?
					M_foamKit.start_OF_container
				end								
				
				# Run simulation
				if $domain['n_processors'] > 1
					M_foamKit.export_decomposeParDict
					process_pid = M_foamKit.exec_command(["decomposePar", "mpirun -n #{$domain['n_processors']} renumberMesh -overwrite -parallel", 
					"mpirun -np #{$domain['n_processors']} #{$domain['application']['recommended OpenFOAM solver']} -parallel", 
					"reconstructPar", "postProcess -func writeCellCentres -latestTime"])				
				else
					process_pid = M_foamKit.exec_command([$domain['application']['recommended OpenFOAM solver'], 
					"postProcess -func writeCellCentres -latestTime"])
				end
				
				# Store openfoam running process pid
				# $domain['process'] = pipe.pid
				
				# Wait until residuals file is created
				M_foamKit.wait_until_res_file_created
				
				# Display terminate button
				# M_foamKit.display_terminate_button
				
				# Run gnuplot to plot residuals
				gnuplot_process_pid = M_foamKit.run_gnuplot
				
				Process.wait(process_pid)
				M_foamKit.delete_processor_folders($domain['n_processors']) if $domain['n_processors'] > 1
				if gnuplot_process_pid
					begin
						Process.kill("KILL", gnuplot_process_pid)
					rescue
						nil
					end				
				end
				M_foamKit.correct_fields_files				
				
				# Update milestones
				M_foamKit.update_milestones("simulation_run")
				M_foamKit.update_milestones("results_available")				
				
				# Enable results tool
				M_foamKit.enable_tool_command("result")
				M_foamKit.enable_tool_command("view")
				
				M_foamKit.update_progress
				
				M_foamKit.dialog_vel_vectors if M_foamKit.get_required_fields.include?("U")				
			}
			
			dlg.set_size(340, 585)
			dlg.set_position(150, 50)
			dlg.show			
		end

	end # module M_dialog
	
end # module M_foamKit	