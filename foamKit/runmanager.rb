require 'sketchup'
require 'fileutils'

module M_foamKit              
    @model = Sketchup.active_model 
	@dir = File.dirname(__FILE__)	
    def self.start_OF_container
		of_version = M_foamKit.get_OF_version		
		
		cmd = '"' + "C:/Program Files (x86)/ESI/OpenFOAM/#{of_version}/Windows/Scripts/of_start_container.exe" + '"' + " -Arguments " + '"' + "C:/Program Files/Docker Toolbox/;C:/Program Files/Git/bin" + '"'
        
        pipe = IO.popen(cmd)
        Process.wait(pipe.pid)

		# Trying to autpmatically close the OpenFOAM console window, didn't succeed yet. The user
		# has to close it manually to proceed
		#pipe = IO.popen("Taskkill /PID #{pipe.pid}")
		#Process.wait(pipe.pid)
    end
    
    def self.OF_running?   
		export_dir = M_foamKit.get_export_dir
        cmd = "docker-machine env > #{export_dir}/Sketchup/#{$domain['project_name']}/log1"       
        
        pipe = IO.popen(cmd)
        Process.wait(pipe.pid)                
        
        output = File.read("#{export_dir}/Sketchup/#{$domain['project_name']}/log1")
        
        if output==""
            return false
        else 
            output = output.split()
            if output[0]=="Error"
                return false
            else
                return true 
            end
        end
    end
    
    def self.get_container_id
		export_dir = M_foamKit.get_export_dir	
        batch_file =
        "docker-machine env > #{export_dir}/Sketchup/#{$domain['project_name']}/log1
        for /F #{'"'}tokens=*#{'"'} %%A in (#{export_dir}/Sketchup/#{$domain['project_name']}/log1) do %%A
        del #{export_dir}/Sketchup/#{$domain['project_name']}/log1
        docker ps > #{export_dir}/Sketchup/#{$domain['project_name']}/log2"
       
        File.write("#{export_dir}/Sketchup/#{$domain['project_name']}/log.bat", batch_file)
        
        pipe = IO.popen("#{export_dir}/Sketchup/#{$domain['project_name']}/log.bat")
        Process.wait(pipe.pid)
        
        if !pipe
            UI.messagebox('Docker container could not be started!', MB_OK)
            return 0
        end            
        
        running_containers_list = File.read("#{export_dir}/Sketchup/#{$domain['project_name']}/log2")
        
        line_index = 0
        running_containers_list.each_line do |line|                    
            if line_index>0
                items = line.split(" ")
                items_length = items.length
                if items[items_length-1][0..6]=="of_plus"
                    container_id = items[0]
                    return container_id
                end
            end                    
            line_index += 1
        end                            
    end
    
    def self.exec_command(of_cmds)
		export_dir = M_foamKit.get_export_dir	
        cmds = "docker exec -i " + M_foamKit.get_container_id + " su - ofuser -c " + "#{'"'}cd /home/ofuser/workingDir/OpenFOAM/Sketchup/" + $domain['project_name']
        of_cmds.each { |of_cmd|
            cmds = cmds + "; #{of_cmd}"
        }
        cmds = cmds + "#{'"'}"
                
        batch_file =
        "@echo off\ndocker-machine env > #{export_dir}/Sketchup/#{$domain['project_name']}/log1\nfor /F #{'"'}tokens=*#{'"'} %%A in (#{export_dir}/Sketchup/#{$domain['project_name']}/log1) do %%A\n" +
        cmds
       
        File.write("#{export_dir}/Sketchup/#{$domain['project_name']}/log.bat", batch_file)
        
        pipe = IO.popen("#{export_dir}/Sketchup/#{$domain['project_name']}/log.bat")
        return pipe.pid                               
    end
		
	def self.run_paraview
		export_dir = M_foamKit.get_export_dir
		paraview_dir = M_foamKit.get_paraview_dir
		if File.directory?("#{paraview_dir}")
			pipe = IO.popen("#{'"'}#{paraview_dir}/paraview#{'"'} #{export_dir}/Sketchup/#{$domain['project_name']}/a.foam")
		else
			UI.messagebox('paraview is not found!')
		end		
	end
	
	def self.run_gnuplot	
		gnuplot_env_path = ENV['GNUPLOT_LIB']
		unless gnuplot_env_path.nil?
			M_foamKit.export_gnuplot_script
			
			export_dir = M_foamKit.get_export_dir
			path = Pathname("#{export_dir}/Sketchup/#{$domain['project_name']}/..").dirname + "plot_res"	
			pipe = IO.popen('"' + "gnuplot" + '"' + " -persist " + path.to_s)
			return pipe.pid
		else
			UI.messagebox('GNUPLOT is not found. The convergence process will not be shown!')
		end
		return nil
	end
	
	def self.terminate_simulation
		unless defined?($domain['process']).nil?
			process_pid = $domain['process']
			Process.kill("KILL", process_pid)
		end
	end
	
	def self.display_terminate_button
		dlg = UI::WebDialog.new("Terminate Process", false, "foamKit", 400, 250, 0, 0, true);
		dlg.set_background_color("f3f0f0")			
					
		html = File.read("#{@dir}/html/terminate.html")	
		dlg.set_html(html)
		
		dlg.add_action_callback("call_terminate") { |dialog, params|	
			M_foamKit.terminate_simulation
		}
		dlg.add_action_callback("call_reset") { |dialog, params|	
			M_foamKit.terminate_simulation
			M_foamKit.clear_results
			dlg.close
		}		
		dlg.show
		dlg.set_position(50, 500)
		dlg.set_size(235, 140)
	end
end