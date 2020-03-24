# foamKit
Sketchup Extension which connects your geomtery to OpenFOAM. You can run an OF simulation from Sketchup!

For example, you may draw a geometry on Sketchup (fluid in a pipe, air volume in room, air enclosure around an airfoil, etc.), mesh it with snappyHexMesh from the OpenFOAM library, and run it using any of the standard solvers in OpenFOAM. All of these steps are made within Sketchup, and no need to refer to text files to run the OpenFOAM simulation.

For making the extension available, the code has to be downloaded and placed in the Sketchup extensions directory:
"C:\Users\username\AppData\Roaming\SketchUp\SketchUp 2017\SketchUp\Plugins\*"

On the other hand, the user has to have already these package installed on his machine:

1) Download openfoam for windows (includes docker and oracle) from this link:

https://sourceforge.net/projects/openfoam/files/v1912/OpenCFD-OpenFOAM4WindowsInstaller-v1912.exe/download 


2) Download Sktechup Make 2017 (free) for windows from this link:

https://help.sketchup.com/en/downloading-older-versions 


3) Download gnuplot for plotting residuals:

https://sourceforge.net/projects/gnuplot/files/gnuplot/ 

Make sure when you install gnuplot to set the environemnt variable path to be available, such that when you are installing gnuplot, keep clicking next until you reach a page where you can find some options for the installation. One of the options asks if you want to set environment variables of gnuplot to your path ... something like that. Check its box and proceed. 


Final Note:
This extension is still in its early stage of development, and still requires lots of improvements. I encourage my fellow githubbers share it, and help improve it!
