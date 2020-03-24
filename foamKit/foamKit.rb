require 'sketchup'
require 'fileutils'
require 'etc'

dir = File.dirname(__FILE__)
require File.join(dir, 'dialog_start.rb')
require File.join(dir, 'dialog_mesh.rb')
require File.join(dir, 'dialog_solve.rb')
require File.join(dir, 'dialog_constant_properties.rb')
require File.join(dir, 'dialog_fluid_properties.rb')
require File.join(dir, 'dialog_boundary_conditions.rb')
require File.join(dir, 'dialog_boundary_condition_settings.rb')
require File.join(dir, 'dialog_initialize.rb')
require File.join(dir, 'dialog_preferences.rb')
require File.join(dir, 'runmanager.rb')
require File.join(dir, 'add_named_selections.rb')
require File.join(dir, 'edit_named_selections.rb')
require File.join(dir, 'export_surfaces.rb')
require File.join(dir, 'define_blockMeshDict.rb')
require File.join(dir, 'define_surfaceFeatureExtractDict.rb')
require File.join(dir, 'define_snappyHexMeshDict.rb')
require File.join(dir, 'define_decomposeParDict.rb')
require File.join(dir, 'define_mesh.rb')
require File.join(dir, 'define_g.rb')
require File.join(dir, 'define_transportProperties.rb')
require File.join(dir, 'define_turbulenceProperties.rb')
require File.join(dir, 'define_controlDict.rb')
require File.join(dir, 'define_fvSchemes.rb')
require File.join(dir, 'define_fvSolution.rb')
require File.join(dir, 'define_field.rb')
require File.join(dir, 'define_residuals.rb')
require File.join(dir, 'define_sample.rb')
# require File.join(dir, 'define_streamlines.rb')
require File.join(dir, 'calculations.rb')
require File.join(dir, 'graphics.rb')
require File.join(dir, 'lookup_data.rb')
require File.join(dir, 'line_tool.rb')

module M_foamKit
	
	# Constant project settings
	# Constant project settings is the constant database of foamKit which includes
	# recipes of different application types. The user may proceed in their problem
	# with default problem settings. However, they might also try a custom recipe by
	# setting their own attributes (application type, solver, working fluid/solid medium)
	
	@USER_NAME = Etc.getlogin
	@EXPORT_DIR = "C:/Users/#{@USER_NAME}/OpenFOAM"
	
	@OF_VERSION = "1612"	
	@OF_DIR = nil
	
	@PARAVIEW_VERSION = nil	
	@PARAVIEW_DIR = "C:/Program Files/ParaView 5.3.0-RC2-Qt5-OpenGL2-Windows-64bit/bin"
	
	@PROJECT_NAME = "foamKit_project"
	
	@STANDARD_APPLICATIONS = {
		'Indoor'                      => {
			'description'                 => 'Air flow inside a room. This could be natural or forced ventilation (i.e. hot room)',
			'working fluid'               => 'air',
			'recommended OpenFOAM solver' => 'buoyantBoussinesqSimpleFoam'		
		},
		'Outdoor'                      => {
			'description'                 => 'Air flow outside buildings (i.e. wind around buildings)',
			'working fluid'               => 'air',
			'recommended OpenFOAM solver' => 'simpleFoam'		
		},		
		'Incompressible Aerodynamics' => {
			'description'                 => 'Air flow at low speeds (i.e. flow past car, motorbike, airfoil, etc)',
			'working fluid'               => 'air',
			'recommended OpenFOAM solver' => 'simpleFoam'		
		},
		'Internal Flow'               => {
			'description'                 => 'Fluid flow through a channel (i.e. water flow in an elbow, blood flow in artery)',
			'working fluid'               => 'water-liquid',
			'recommended OpenFOAM solver' => 'simpleFoam'		
		},	
		'Heat Transfer in Solid'      => {
			'description'                 => 'Diffusion of heat in a solid object (i.e. temperature distribution in a flange)',
			'working fluid'               => 'Aluminum',
			'recommended OpenFOAM solver' => 'laplacianFoam'	
		}		
	}

	@STANDARD_FLUIDS = {
		'air'          => {
			'Density'                       => 1.177,
			'Specific Heat'                 => 1004.9,
			'Thermal Conductivity'          => 2.624e-02,
			'Dynamic Viscosity'             => 1.846e-05,
			'Kinematic Viscosity'           => 1.568e-05,
			'Thermal Expansion Coefficient' => 3e-03,
			'Prandtl Number'                => 0.707,
			'Turbulent Prandtl Number'      => 0.85,
			'Reference Temperature'         => 300,
			'Schmidt Number'                => 0.7,
			'Turbulent Schmidt Number'      => 0.7	
		},
		
		'water-liquid' => {
			'Density'                       => 997.1,
			'Specific Heat'                 => 4180,
			'Thermal Conductivity'          => 59.84-02,
			'Dynamic Viscosity'             => 1.002e-03,
			'Kinematic Viscosity'           => 1.004e-06,
			'Thermal Expansion Coefficient' => 2.14e-04,
			'Prandtl Number'                => 7.01,
			'Reference Temperature'         => 300,
			'Schmidt Number'                => '',
			'Turbulent Schmidt Number'      => ''			
		},
		'Aluminum' => {
			'Diffusion Coefficient' => 0.1
		}		
	}		
	
	@STANDARD_PROPERTIES = {
		'Density'                       => {:unit => 'kg/m3',     :symbol => 'rho'},
		'Specific Heat'                 => {:unit => 'm2/s2-k',   :symbol => 'Cp'},
		'Thermal Conductivity'          => {:unit => 'kg-m/k-s3', :symbol => 'k'},
		'Dynamic Viscosity'             => {:unit => 'kg/m-s',    :symbol => 'mu'},
		'Kinematic Viscosity'           => {:unit => 'm2/s',      :symbol => 'nu'},
		'Thermal Expansion Coefficient' => {:unit => '1/k',       :symbol => 'beta'},
		'Prandtl Number'                => {:unit => '',          :symbol => 'Pr'},
		'Turbulent Prandtl Number'      => {:unit => '',          :symbol => 'Prt'},
		'Reference Temperature'         => {:unit => 'k',         :symbol => 'TRef'},
		'Schmidt Number'                => {:unit => '',          :symbol => 'Sc'},
		'Turbulent Schmidt Number'      => {:unit => '',          :symbol => 'Sct'},
		'Diffusion Coefficient'         => {:unit => 'm4/k-s3',   :symbol => 'DT'}		
	}
	
	@STANDARD_SOLVERS = {
		'laplacianFoam' => {
			:class => 'basic',
			:description => "Laplace equation solver for a scalar quantity",
			:time  => 'transient',
			:fields => [{:name => 'T', :unit => 'k', :class => 'volScalarField'}],
			:gravity => nil,
			:turbulence => nil,
			:transport_properties => ['Diffusion Coefficient'],
			:alias_solver => nil
		},
		'simpleFoam' => {
			:class => 'incompressible',
			:description => "Steady-state solver for incompressible flows with turbulence modelling",
			:time  => 'steady',
			:fields => [{:name => 'U', :unit => 'm/s',   :class => 'volVectorField'}, 
						{:name => 'p', :unit => 'm2/s2', :class => 'volScalarField'}],
			:gravity => nil,
			:turbulence => true,
			:transport_properties => ['Kinematic Viscosity'],
			:alias_solver => 'pisoFoam'
		},
		'pisoFoam' => {
			:class => 'incompressible',
			:description => "Transient solver for incompressible, turbulent flow, using the PISO algorithm",
			:time  => 'transient',
			:fields => [{:name => 'U', :unit => 'm/s',   :class => 'volVectorField'}, 
						{:name => 'p', :unit => 'm2/s2', :class => 'volScalarField'}],
			:gravity => nil,
			:turbulence => true,
			:transport_properties => ['Kinematic Viscosity'],
			:alias_solver => 'simpleFoam'			
		},
		'buoyantBoussinesqPimpleFoam' => {
			:class => 'heatTransfer',
			:description => "Transient solver for buoyant, turbulent flow of incompressible fluids",
			:time  => 'transient',
			:fields => [{:name => 'U',      :unit => 'm/s',   :class => 'volVectorField'}, 
						{:name => 'p',      :unit => 'm2/s2', :class => 'volScalarField'},
						{:name => 'T',      :unit => 'k',     :class => 'volScalarField'},
						{:name => 'p_rgh',  :unit => 'm2/s2', :class => 'volScalarField'},
						{:name => 'alphat', :unit => 'm2/s',  :class => 'volScalarField'}],
			:gravity => true,
			:turbulence => true,
			:transport_properties => ['Kinematic Viscosity', 'Thermal Expansion Coefficient',
									  'Reference Temperature', 'Prandtl Number', 'Turbulent Prandtl Number'],
			:alias_solver => 'buoyantBoussinesqSimpleFoam'									  
		},
		'buoyantBoussinesqSimpleFoam' => {
			:class => 'heatTransfer',
			:description => "Steady-state solver for buoyant, turbulent flow of incompressible fluids",
			:time  => 'steady',
			:fields => [{:name => 'U',      :unit => 'm/s',   :class => 'volVectorField'}, 
						{:name => 'p',      :unit => 'm2/s2', :class => 'volScalarField'},
						{:name => 'T',      :unit => 'k',     :class => 'volScalarField'},
						{:name => 'p_rgh',  :unit => 'm2/s2', :class => 'volScalarField'},
						{:name => 'alphat', :unit => 'm2/s',  :class => 'volScalarField'}],
			:gravity => true,
			:turbulence => true,
			:transport_properties => ['Kinematic Viscosity', 'Thermal Expansion Coefficient',
									  'Reference Temperature', 'Prandtl Number', 'Turbulent Prandtl Number'],
			:alias_solver => 'buoyantBoussinesqPimpleFoam'
		}
	}		

	@STANDARD_TURBULENCE_MODELS = {
		'SpalartAllmaras' => {
			:fields    => [{:name => 'nuTilda', :unit => 'm2/s', :class => 'volScalarField'}, 
						   {:name => 'nut',     :unit => 'm2/s', :class => 'volScalarField'}],
			:constants => {},
			:recommended_for => ['Incompressible Aerodynamics']
		},
		'kEpsilon' => {
			:fields    => [{:name => 'k',       :unit => 'm2/s2' , :class => 'volScalarField'}, 
						   {:name => 'epsilon', :unit => 'm2/s3',  :class => 'volScalarField'},
						   {:name => 'nut',     :unit => 'm2/s',   :class => 'volScalarField'}],			
			:constants => {:Cmu => 0.09, :kappa => 0.41, :E => 9.8},
			:recommended_for => ['Indoor', 'Outdoor', 'Incompressible Aerodynamics', 'Internal Flow']
		},
		'kOmega' => {
			:fields    => [{:name => 'k',       :unit => 'm2/s2', :class => 'volScalarField'}, 
						   {:name => 'omega',   :unit => '1/s',   :class => 'volScalarField'},
						   {:name => 'nut',     :unit => 'm2/s',  :class => 'volScalarField'}],
			:constants => {},
			:recommended_for => ['Incompressible Aerodynamics']		
		}	
	}
	
	# This is important because certain applications are designed to work with specific turbulence models.
	# If an application is designed to work with more than a turbulence model, it is added to the corresponding array.
	# In theory, an application can work with any turbulence model
	@APPLICABLE_TURBULENCE_MODELS = {
		'Indoor' => ['kEpsilon'],
		'Outdoor' => ['kEpsilon'],
		'Incompressible Aerodynamics' => ['kEpsilon'],
		'Internal Flow' => ['kEpsilon']
	}	

	@APPLICABLE_FLUIDS = {
		'Indoor' => ['air'],
		'Outdoor' => ['air'],
		'Incompressible Aerodynamics' => ['air'],
		'Internal Flow' => ['air', 'water-liquid']
	}
	
	@STANDARD_BOUNDARY_TYPES = ['inlet', 'outlet', 'wall', 'symmetry', 'empty']		
	
	@STANDARD_BCS = {
		'Indoor' => {
			'U' => {
				'inlet'    => {:type => 'fixedValue',  :value => 'uniform (0 0 0)'},
				
				# the inletOutlet boundary condition used here for the outlet means that if there's an inflow, then
				# the fixed value of the inlet is as specified by inletValue, otherwise, it is a zeroGradient
				# boundary condition. The entry "value" is dummy and not used
				'outlet'   => {:type => 'inletOutlet', :inletValue => 'uniform (0 0 0)', :value => 'uniform (0 0 0)'},
				'wall'     => {:type => 'noSlip'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			},
			'p' => {
				# In buoyantBoussinesqSimpleFoam the pressure field itself is not solved. However,
				# it is calculated from p_rgh, by:
				# p = p_rgh + rgh
				# Thus, the boundary conditions of p are calculated, so they are not driving
				'inlet'    => {:type => 'calculated', :value => 'uniform 0'},
				'outlet'   => {:type => 'calculated', :value => 'uniform 0'},
				'wall'     => {:type => 'calculated', :value => 'uniform 0'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			},	
			'T' => {
				'inlet'    => {:type => 'fixedValue',  :value => 'uniform 300'},
				
				# Using inletOutlet here for the same reason stated above for the outlet of U field.
				# The entry "value" is dummy and not used
				'outlet'   => {:type => 'inletOutlet', :inletValue => 'uniform 300', :value => 'uniform 300'},
				
				'wall'     => {:type => 'zeroGradient'},
				
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			},	
			# p_rgh is the pressure without the hydrostatic pressure. It is actually the quantity
			# that the solver solves for but not the pressure itself.
			'p_rgh' => {
				# For the inlet and wall boundaries in this application, the boundary condition is better be set to
				# fixedFluxPressure instead of zeroGradient because it enhances convergence. This boundary condition changes
				# the pressure gradient at each iteration based on the predicted flux (phiHbyA - phi)
				# as a result of solving the momemntum predictor equation
				'inlet'    => {:type => 'fixedFluxPressure', :gradient => 'uniform 0', :value => 'uniform 0'},
				'outlet'   => {:type => 'fixedValue',        :value => 'uniform 0'},
				'wall'     => {:type => 'fixedFluxPressure', :rho => 'rhok', :value => 'uniform 0'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			},
			'alphat' => {
				'inlet'    => {:type => 'calculated', :value => 'uniform 0'},
				'outlet'   => {:type => 'calculated', :value => 'uniform 0'},
				'wall'     => {:type => 'alphatJayatillekeWallFunction', :Prt => 0.85, :value => 'uniform 0'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			},

			# The values of k and epsilon at the inlet and wall are calculated using the velocity at inlet
			# by applying k-epsilon approximations that make use of turbulence intensity and turbulence length scale.
			'k' => {
				'inlet'    => {:type => 'fixedValue', :value => 'uniform 0.1'},
				'outlet'   => {:type => 'zeroGradient'},
				'wall'     => {:type => 'kqRWallFunction', :value => 'uniform 0'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			},
			'epsilon' => {
				'inlet'    => {:type => 'fixedValue', :value => 'uniform 0.01'},
				'outlet'   => {:type => 'zeroGradient'},
				'wall'     => {:type => 'epsilonWallFunction', :value => 'uniform 0'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			},	
			'nut' => {
				'inlet'    => {:type => 'calculated', :value => 'uniform 0'},
				'outlet'   => {:type => 'calculated', :value => 'uniform 0'},
				'wall'     => {:type => 'nutkWallFunction', :value => 'uniform 0'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			}	
		},
		'Outdoor' => {
			'U' => {
				'inlet'    => {:type => 'fixedValue', :value => 'uniform (0 0 0)'},
				
				# This velocity inlet/outlet boundary condition is applied to pressure boundaries where the 
				# pressure is specified. A zeroGradient condition is applied for outflow (as defined by the flux); 
				# for inflow, the velocity is obtained from the patch-face normal component of the internal-cell value.
				# the "value" entry is dummy and not used
				'outlet'   => {:type => 'pressureInletOutletVelocity', :value => 'uniform (0 0 0)'},
				'wall'     => {:type => 'noSlip'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			},
			'p' => {
				'inlet'    => {:type => 'zeroGradient'},
				
				# The totalPressure boundary condition is used here. The total pressure p0 = p + 1/2 * U^2
				# setting it to 0, means that the pressure p may change at the outlet based on the velocity
				# at the outlet. It enhances convergence.
				'outlet'   => {:type => 'totalPressure', :p0 => 'uniform 0'},
				'wall'     => {:type => 'zeroGradient'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			},			
			'k' => {
				# The value of turbulent energy k is calculated from the velocity at inlet by: k = 1.5*(I*U)^2
				# I is the turbulence intensity specified by the user
				'inlet'    => {:type => 'fixedValue', :value => 'uniform 0.1'},
				'outlet'   => {:type => 'zeroGradient'},
				'wall'     => {:type => 'kqRWallFunction', :value => 'uniform 0'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			},
			'epsilon' => {
				# The value of epsilon is calculated from by: Cmu^0.75 * k^1.5 / L where L
				# is the turbulence length scale specified by the user and Cmu is a constant		
				'inlet'    => {:type => 'fixedValue', :value => 'uniform 0.01'},
				'outlet'   => {:type => 'zeroGradient'},
				'wall'     => {:type => 'epsilonWallFunction', :value => 'uniform 0'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			},	
			'nut' => {
				'inlet'    => {:type => 'calculated', :value => 'uniform 0'},
				'outlet'   => {:type => 'calculated', :value => 'uniform 0'},
				'wall'     => {:type => 'nutkWallFunction', :value => 'uniform 0'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			}		
		},
		'Incompressible Aerodynamics' => {
			'U' => {
				'inlet'    => {:type => 'fixedValue', :value => 'uniform (0 0 0)'},
				'outlet'   => {:type => 'pressureInletOutletVelocity', :value => 'uniform (0 0 0)'},
				'wall'     => {:type => 'noSlip'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			},
			'p' => {
				'inlet'    => {:type => 'zeroGradient'},
				'outlet'   => {:type => 'fixedValue', :value => 'uniform 0'},
				'wall'     => {:type => 'zeroGradient'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			},		
			'k' => {
				'inlet'    => {:type => 'fixedValue', :value => 'uniform 0'},
				'outlet'   => {:type => 'zeroGradient'},
				'wall'     => {:type => 'kqRWallFunction', :value => 'uniform 0'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			},
			'epsilon' => {		
				'inlet'    => {:type => 'fixedValue', :value => 'uniform 0'},
				'outlet'   => {:type => 'zeroGradient'},
				'wall'     => {:type => 'epsilonWallFunction', :value => 'uniform 0'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			},				
			'nut' => {
				'inlet'    => {:type => 'calculated', :value => 'uniform 0'},
				'outlet'   => {:type => 'calculated', :value => 'uniform 0'},
				'wall'     => {:type => 'nutkWallFunction', :value => 'uniform 0'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			}		
		},
		'Internal Flow' => {
			'U' => {
				'inlet'    => {:type => 'fixedValue', :value => 'uniform (0 0 0)'},
				'outlet'   => {:type => 'zeroGradient'},
				'wall'     => {:type => 'noSlip'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			},
			'p' => {
				'inlet'    => {:type => 'zeroGradient'},
				'outlet'   => {:type => 'fixedValue', :value => 'uniform 0'},
				'wall'     => {:type => 'zeroGradient'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			},
			'k' => {
				'inlet'    => {:type => 'fixedValue', :value => 'uniform 1'},
				'outlet'   => {:type => 'inletOutlet', :inletValue => 'uniform 1'},
				'wall'     => {:type => 'kqRWallFunction', :value => 'uniform 0'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			},
			'epsilon' => {
				'inlet'    => {:type => 'fixedValue', :value => 'uniform 1'},
				'outlet'   => {:type => 'inletOutlet', :inletValue => 'uniform 1'},
				'wall'     => {:type => 'epsilonWallFunction', :value => 'uniform 0'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			},	
			'nut' => {
				'inlet'    => {:type => 'calculated', :value => 'uniform 0'},
				'outlet'   => {:type => 'calculated', :value => 'uniform 0'},
				'wall'     => {:type => 'nutkWallFunction', :value => 'uniform 0'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			},
			'nuTilda' => {
				'inlet'    => {:type => 'zeroGradient'},
				'outlet'   => {:type => 'zeroGradient'},
				'wall'     => {:type => 'zeroGradient'},
				'symmetry' => {:type => 'symmetryPlane'},
				'empty'    => {:type => 'empty'}		
			}			
		}
	}
	
	@STANDARD_REQUIRED_FIELDS = {
		'Indoor' => {
			'U'       => {:unit => 'm/s',    :class => 'volVectorField'},
			'p'       => {:unit => 'm2/s2',  :class => 'volScalarField'},	
			'T'       => {:unit => 'k',      :class => 'volScalarField'},
			'p_rgh'   => {:unit => 'm2/s2',  :class => 'volScalarField'},
			'alphat'  => {:unit => 'm2/s',   :class => 'volScalarField'},	
			'k'       => {:unit => 'm2/s2' , :class => 'volScalarField'},
			'epsilon' => {:unit => 'm2/s3',  :class => 'volScalarField'},	
			'nut'     => {:unit => 'm2/s',   :class => 'volScalarField'}		
		},
		'Outdoor' => {
			'U'       => {:unit => 'm/s',    :class => 'volVectorField'},
			'p'       => {:unit => 'm2/s2',  :class => 'volScalarField'},	
			'k'       => {:unit => 'm2/s2' , :class => 'volScalarField'},
			'epsilon' => {:unit => 'm2/s3',  :class => 'volScalarField'},	
			'nut'     => {:unit => 'm2/s',   :class => 'volScalarField'}
		},
		'Incompressible Aerodynamics' => {
			'U'       => {:unit => 'm/s',    :class => 'volVectorField'},
			'p'       => {:unit => 'm2/s2',  :class => 'volScalarField'},
			'k'       => {:unit => 'm2/s2' , :class => 'volScalarField'},
			'epsilon' => {:unit => 'm2/s3',  :class => 'volScalarField'},	
			'nut'     => {:unit => 'm2/s',   :class => 'volScalarField'}		
		},
		'Internal Flow' => {
			'U'       => {:unit => 'm/s',    :class => 'volVectorField'},
			'p'       => {:unit => 'm2/s2',  :class => 'volScalarField'},	
			'k'       => {:unit => 'm2/s2' , :class => 'volScalarField'},
			'epsilon' => {:unit => 'm2/s3',  :class => 'volScalarField'},	
			'nut'     => {:unit => 'm2/s',   :class => 'volScalarField'},
			'nuTilda' => {:unit => 'm2/s',   :class => 'volScalarField'}
		}	
	}	
	
	@STANDARD_INITIAL_CONDITIONS = {
		'Indoor' => {
			'U'       => 'uniform (0 0 0)',
			'p'       => 'uniform 0',	
			'T'       => 'uniform 300',
			'p_rgh'   => 'uniform 0',
			'alphat'  => 'uniform 0',	
			'k'       => 'uniform 0.1',
			'epsilon' => 'uniform 0.01',	
			'nut'     => 'uniform 0'		
		},
		'Outdoor' => {
			'U'       => 'uniform (0 0 0)',
			'p'       => 'uniform 0',		
			'k'       => 'uniform 1.5',
			'epsilon' => 'uniform 0.03',	
			'nut'     => 'uniform 0'
		},
		'Incompressible Aerodynamics' => {
			'U'       => 'uniform (0 0 0)',
			'p'       => 'uniform 0',		
			'k'       => 'uniform 0.375',
			'epsilon' => 'uniform 0.125',	
			'nut'     => 'uniform 0'		
		},
		'Internal Flow' => {
			'U'       => 'uniform (0 0 0)',
			'p'       => 'uniform 0',		
			'k'       => 'uniform 1',
			'epsilon' => 'uniform 1',	
			'nut'     => 'uniform 0',
			'nuTilda' => 'uniform 0'
		}	
	}
	
	@STANDARD_SOLUTION_ATTRIBUTES = {
		'Indoor' => {
			'solvers' => {
				'p_rgh'   => {:solver => 'PCG',       :preconditioner => 'DIC', :tolerance => 1e-08, :relTol => 0.01},
				'U'       => {:solver => 'PBiCGStab', :preconditioner => 'DILU', :tolerance => 1e-05, :relTol => 0.1},	
				'T'       => {:solver => 'PBiCGStab', :preconditioner => 'DILU', :tolerance => 1e-05, :relTol => 0.1},		
				'k'       => {:solver => 'PBiCGStab', :preconditioner => 'DILU', :tolerance => 1e-05, :relTol => 0.1},	
				'epsilon' => {:solver => 'PBiCGStab', :preconditioner => 'DILU', :tolerance => 1e-05, :relTol => 0.1},
				'R'       => {:solver => 'PBiCGStab', :preconditioner => 'DILU', :tolerance => 1e-05, :relTol => 0.1}
			},
			'SIMPLE' => {
				:nNonOrthogonalCorrectors => 0,
				:pRefCell                 => 0,
				:pRefValue                => 0,
				:residualControl          => {'p_rgh' => 1e-2, 'U' => 1e-4, 'T' => 1e-2, 'k' => 1e-3, 'epsilon' => 1e-3, 'omega' => 1e-3}
			},
			'relaxationFactors' => {
				:fields    => {'p_rgh' => 0.7},
				:equations => {'U' => 0.3, 'T' => 0.5, 'k' => 0.7, 'epsilon' => 0.7, 'R' => 0.7}				
			}
		},
		
		'Indoor_transient' => {
			'solvers' => {
				'p_rgh'      	  => {:solver => 'PCG',       :preconditioner => 'DIC', :tolerance => 1e-08, :relTol => 0.01},
				'p_rghFinal' 	  => {:$p_rgh => nil, :relTol => 0},
				'U'          	  => {:solver => 'PBiCGStab', :preconditioner => 'DILU', :tolerance => 1e-05, :relTol => 0.1},	
				'T'          	  => {:solver => 'PBiCGStab', :preconditioner => 'DILU', :tolerance => 1e-05, :relTol => 0.1},		
				'k'          	  => {:solver => 'PBiCGStab', :preconditioner => 'DILU', :tolerance => 1e-05, :relTol => 0.1},	
				'epsilon'   	  => {:solver => 'PBiCGStab', :preconditioner => 'DILU', :tolerance => 1e-05, :relTol => 0.1},
				'R'          	  => {:solver => 'PBiCGStab', :preconditioner => 'DILU', :tolerance => 1e-05, :relTol => 0.1},
				'UFinal'          => {:$U => nil, :relTol => 0},	
				'TFinal'          => {:$U => nil, :relTol => 0},		
				'kFinal'          => {:$U => nil, :relTol => 0},	
				'epsilonFinal'    => {:$U => nil, :relTol => 0},
				'RFinal'          => {:$U => nil, :relTol => 0}				
			},
			'PIMPLE' => {
				:momentumPredictor 		  => 'no',
				:nOuterCorrectors		  => 1,
				:nCorrectors	     	  => 2,
				:nNonOrthogonalCorrectors => 0,
				:pRefCell                 => 0,
				:pRefValue                => 0
			},
			'relaxationFactors' => {
				:equations => {
					'U'            => 1, 
					'T'            => 1, 
					'k'            => 1, 
					'epsilon'      => 1, 
					'R'            => 1,
					'UFinal'       => 1, 
					'TFinal'       => 1, 
					'kFinal'       => 1, 
					'epsilonFinal' => 1, 
					'RFinal'       => 1				
				}				
			}
		},		
		
		'Outdoor' => {
			'solvers' => {
				'p'       => {:solver => 'GAMG',         :smoother => 'GaussSeidel', :tolerance => 1e-06, :relTol => 0.1},
				'U'       => {:solver => 'smoothSolver', :smoother => 'symGaussSeidel', :tolerance => 1e-06, :relTol => 0.1},			
				'k'       => {:solver => 'smoothSolver', :smoother => 'symGaussSeidel', :tolerance => 1e-06, :relTol => 0.1},	
				'omega'   => {:solver => 'smoothSolver', :smoother => 'symGaussSeidel', :tolerance => 1e-06, :relTol => 0.1},				
				'epsilon' => {:solver => 'smoothSolver', :smoother => 'symGaussSeidel', :tolerance => 1e-06, :relTol => 0.1}
			},
			'SIMPLE' => {
				:nNonOrthogonalCorrectors => 0,
				:pRefCell                 => 0,
				:pRefValue                => 0,
				:residualControl          => {'p' => 1e-4, 'U' => 1e-4, 'k' => 1e-4, 'omega' => 1e-4, 'epsilon' => 1e-4}
			},
			'potentialFlow' => {:nNonOrthogonalCorrectors => 10},
			'relaxationFactors' => {
				:fields    => {'p' => 0.3},
				:equations => {'U' => 0.7, 'k' => 0.7, 'omega' => 0.7, 'epsilon' => 0.7}				
			}			
		},		
		
		'Incompressible Aerodynamics' => {
			'solvers' => {
				'p'       => {:solver => 'GAMG',         :smoother => 'GaussSeidel', :tolerance => 1e-07, :relTol => 0.01},
				'U'       => {:solver => 'smoothSolver', :smoother => 'GaussSeidel', :tolerance => 1e-08, :relTol => 0.1, :nSweeps => 1},			
				'k'       => {:solver => 'smoothSolver', :smoother => 'GaussSeidel', :tolerance => 1e-08, :relTol => 0.1, :nSweeps => 1},	
				'omega'   => {:solver => 'smoothSolver', :smoother => 'GaussSeidel', :tolerance => 1e-08, :relTol => 0.1, :nSweeps => 1}
			},
			'SIMPLE' => {
				:nNonOrthogonalCorrectors => 0,
				:consistent => 'yes'
			},
			'potentialFlow' => {:nNonOrthogonalCorrectors => 10},
			'relaxationFactors' => {
				:equations => {'U' => 0.9, 'k' => 0.7, 'omega' => 0.7}
			},
			'cache' => 'grad(U)'	
		},
		
		'Internal Flow' => {
			'solvers' => {
				'p'       => {:solver => 'GAMG',         :smoother => 'GaussSeidel', :tolerance => 1e-06, :relTol => 0.05},
				'pFinal'  => {:$p => nil, :tolerance => 1e-05, :relTol => 0},		
				'"(U|k|epsilon)"' => {:solver => 'smoothSolver', :smoother => 'symGaussSeidel', :tolerance => 1e-05, :relTol => 0.1},
				'"(U|k|epsilon)Final"'       => {:$U => nil, :tolerance => 1e-05, :relTol => 0}		
			},
			'SIMPLE'  => {
				:nNonOrthogonalCorrectors => 0,
				:residualControl          => {'p' => 1e-2, 'U' => 1e-3, 'k' => 1e-3, 'epsilon' => 1e-3}
			},
			'relaxationFactors' => {
				:fields    => {'p' => 0.3},
				:equations => {'U' => 0.7, 'k' => 0.7, '"epsilon.*"' => 0.7}				
			},
			'cache' => 'grad(U)'			
		},	
		
		'Heat Transfer in Solid' => {
			'p_rgh'   => {:solver => 'PCG',       :preconditioner => 'DIC',  :tolerance => 1e-08, :relTol => 0.01},
			'U'       => {:solver => 'PBiCGStab', :preconditioner => 'DILU', :tolerance => 1e-05, :relTol => 0.1},	
			'T'       => {:solver => 'PBiCGStab', :preconditioner => 'DILU', :tolerance => 1e-05, :relTol => 0.1},		
			'k'       => {:solver => 'PBiCGStab', :preconditioner => 'DILU', :tolerance => 1e-05, :relTol => 0.1},	
			'epsilon' => {:solver => 'PBiCGStab', :preconditioner => 'DILU', :tolerance => 1e-05, :relTol => 0.1},
			'R'       => {:solver => 'PBiCGStab', :preconditioner => 'DILU', :tolerance => 1e-05, :relTol => 0.1}		
		}		
	}
	
	@STANDARD_SCHEMES_ATTRIBUTES = {
		'Indoor' => {
			:ddtSchemes  => {'default' => 'steadyState'},
			:gradSchemes => {'default' => 'Gauss linear'},
			:divSchemes  => {
				'default'                       => 'none',
				'div(phi,U)'                    => 'bounded Gauss upwind',
				'div(phi,T)'                    => 'bounded Gauss upwind',
				'div(phi,k)'                    => 'bounded Gauss upwind',
				'div(phi,epsilon)'              => 'bounded Gauss upwind',
				'div((nuEff*dev2(T(grad(U)))))' => 'Gauss linear'
			},
			:laplacianSchemes     => {'default' => 'Gauss linear corrected'},
			:interpolationSchemes => {'default' => 'linear'},
			:snGradSchemes        => {'default' => 'corrected'}			
		},
		'Indoor_transient' => {
			:ddtSchemes  => {'default' => 'Euler'},
			:gradSchemes => {'default' => 'Gauss linear'},
			:divSchemes  => {
				'default'                       => 'none',
				'div(phi,U)'                    => 'Gauss upwind',
				'div(phi,T)'                    => 'Gauss upwind',
				'div(phi,k)'                    => 'Gauss upwind',
				'div(phi,epsilon)'              => 'Gauss upwind',
				'div(phi,R)'                    => 'Gauss upwind',
				'div(R)'                        => 'Gauss linear',
				'div((nuEff*dev2(T(grad(U)))))' => 'Gauss linear'
			},
			:laplacianSchemes     => {'default' => 'Gauss linear uncorrected'},
			:interpolationSchemes => {'default' => 'linear'},
			:snGradSchemes        => {'default' => 'uncorrected'}			
		},		
		
		'Outdoor' => {
			:ddtSchemes  => {'default' => 'steadyState'},
			:gradSchemes => {
				'default' => 'Gauss linear',
				'limited' => 'cellLimited Gauss linear 1',
				'grad(U)' => 'cellLimited Gauss linear 1',
				'grad(k)' => 'cellLimited Gauss linear 1',
				'grad(epsilon)' => 'cellLimited Gauss linear 1'				
			},
			:divSchemes  => {
				'default'                       => 'none',
				'div(phi,U)'                    => 'bounded Gauss linearUpwind limited',
				'turbulence'					=> 'bounded Gauss limitedLinear 1',
				'div(phi,k)'                    => 'bounded Gauss limitedLinear 1',
				'div(phi,epsilon)'              => 'bounded Gauss limitedLinear 1',
				'div((nuEff*dev2(T(grad(U)))))' => 'Gauss linear'
			},
			:laplacianSchemes     => {'default' => 'Gauss linear corrected'},
			:interpolationSchemes => {'default' => 'linear'},
			:snGradSchemes        => {'default' => 'corrected'},
			:wallDist             => {'method' => 'meshWave'}
		},
		
		'Incompressible Aerodynamics' => {
			:ddtSchemes  => {'default' => 'steadyState'},
			:gradSchemes => {
				'default' => 'Gauss linear', 
				'grad(U)' => 'cellLimited Gauss linear 1'
			},
			:divSchemes  => {
				'default'                       => 'none',
				'div(phi,U)'                    => 'bounded Gauss linearUpwindV grad(U)',
				'div(phi,k)'                    => 'bounded Gauss upwind',
				'div(phi,omega)'                => 'bounded Gauss upwind',
				'div((nuEff*dev2(T(grad(U)))))' => 'Gauss linear'
			},
			:laplacianSchemes     => {'default' => 'Gauss linear corrected'},
			:interpolationSchemes => {'default' => 'linear'},
			:snGradSchemes        => {'default' => 'corrected'},
			:wallDist             => {'method'  => 'meshWave'}	
		},
		
		'Internal Flow'               => {
			:ddtSchemes  => {'default' => 'steadyState'},
			:gradSchemes => {'default' => 'Gauss linear'},
			:divSchemes  => {
				'default'                       => 'none',
				'div(phi,U)'                    => 'bounded Gauss limitedLinearV 1',
				'div(phi,k)'                    => 'bounded Gauss limitedLinear 1',
				'div(phi,epsilon)'              => 'bounded Gauss limitedLinear 1',
				'div(phi,R)'                    => 'bounded Gauss limitedLinear 1',
				'div(R)'                        => 'Gauss linear',
				'div(phi,nuTilda)'              => 'bounded Gauss limitedLinear 1',
				'div((nuEff*dev2(T(grad(U)))))' => 'Gauss linear'
			},
			:laplacianSchemes => {'default' => 'Gauss linear corrected'},
			:interpolationSchemes => {'default' => 'linear'},
			:snGradSchemes => {'default' => 'corrected'}		
		},	
		
		'Heat Transfer in Solid'      => {
			:ddtSchemes  => {'default' => 'steadyState'},
			:gradSchemes => {'default' => 'Gauss linear'},
			:divSchemes  => {
				'default'                       => 'none',
				'div(phi,U)'                    => 'bounded Gauss upwind',
				'div(phi,T)'                    => 'bounded Gauss upwind',
				'div(phi,k)'                    => 'bounded Gauss upwind',
				'div(phi,epsilon)'              => 'bounded Gauss upwind',
				'div((nuEff*dev2(T(grad(U)))))' => 'Gauss linear'
			},
			:laplacianSchemes => {'default' => 'Gauss linear corrected'},
			:interpolationSchemes => {'default' => 'linear'},
			:snGradSchemes => {'default' => 'corrected'}	
		}			
	}
	
	@STANDARD_CONTROL_ATTRIBUTES = {	
		'Indoor' => {
			:application       => 'buoyantBoussinesqSimpleFoam',
			:startFrom         => 'startTime',
			:startTime         => 0,
			:stopAt            => 'endTime',
			:endTime           => 1000,
			:deltaT            => 1,
			:writeControl      => 'timeStep',
			:writeInterval     => 100,
			:purgeWrite        => 0,
			:writeFormat       => 'ascii',
			:writePrecision    => 7,
			:writeCompression  => 'off',
			:timeFormat        => 'general',
			:timePrecision     => 6,
			:runTimeModifiable => 'true'
		},
		
		'Indoor_transient' => {
			:application       => 'buoyantBoussinesqPimpleFoam',
			:startFrom         => 'startTime',
			:startTime         => 0,
			:stopAt            => 'endTime',
			:endTime           => 2000,
			:deltaT            => 2,
			:writeControl      => 'timeStep',
			:writeInterval     => 200,
			:purgeWrite        => 0,
			:writeFormat       => 'ascii',
			:writePrecision    => 7,
			:writeCompression  => 'off',
			:timeFormat        => 'general',
			:timePrecision     => 6,
			:runTimeModifiable => 'true',
			:adjustTimeStep	   => 'no',
			:maxCo			   => 0.5
		},		
		
		'Outdoor' => {
			:application       => 'simpleFoam',
			:startFrom         => 'latestTime',
			:startTime         => 0,
			:stopAt            => 'endTime',
			:endTime           => 400,
			:deltaT            => 1,
			:writeControl      => 'timeStep',
			:writeInterval     => 50,
			:purgeWrite        => 0,
			:writeFormat       => 'ascii',
			:writePrecision    => 7,
			:writeCompression  => 'off',
			:timeFormat        => 'general',
			:timePrecision     => 6,
			:runTimeModifiable => 'true'
		},
		
		'Incompressible Aerodynamics' => {
			:application       => 'simpleFoam',
			:startFrom         => 'latestTime',
			:startTime         => 0,
			:stopAt            => 'endTime',
			:endTime           => 500,
			:deltaT            => 1,
			:writeControl      => 'timeStep',
			:writeInterval     => 100,
			:purgeWrite        => 0,
			:writeFormat       => 'binary',
			:writePrecision    => 7,
			:writeCompression  => 'uncompressed',
			:timeFormat        => 'general',
			:timePrecision     => 6,
			:runTimeModifiable => 'true'	
		},
		
		'Incompressible Aerodynamics_transient' => {
			:application       => 'pisoFoam',
			:startFrom         => 'latestTime',
			:startTime         => 0,
			:stopAt            => 'endTime',
			:endTime           => 500,
			:deltaT            => 1,
			:writeControl      => 'timeStep',
			:writeInterval     => 100,
			:purgeWrite        => 0,
			:writeFormat       => 'binary',
			:writePrecision    => 7,
			:writeCompression  => 'uncompressed',
			:timeFormat        => 'general',
			:timePrecision     => 6,
			:runTimeModifiable => 'true'	
		},		
		
		'Internal Flow' => {
			:application       => 'simpleFoam',
			:startFrom         => 'startTime',
			:startTime         => 0,
			:stopAt            => 'endTime',
			:endTime           => 1000,
			:deltaT            => 1,
			:writeControl      => 'timeStep',
			:writeInterval     => 100,
			:purgeWrite        => 0,
			:writeFormat       => 'ascii',
			:writePrecision    => 7,
			:writeCompression  => 'uncompressed',
			:timeFormat        => 'general',
			:timePrecision     => 6,
			:runTimeModifiable => 'true'		
		},	
		
		'Heat Transfer in Solid' => {
			:application       => 'laplacianFoam',
			:startFrom         => 'latestTime',
			:startTime         => 0,
			:stopAt            => 'endTime',
			:endTime           => 3,
			:deltaT            => 0.005,
			:writeControl      => 'runTime',
			:writeInterval     => 0.1,
			:purgeWrite        => 0,
			:writeFormat       => 'ascii',
			:writePrecision    => 7,
			:writeCompression  => 'off',
			:timeFormat        => 'general',
			:timePrecision     => 6,
			:runTimeModifiable => 'true'	
		}
	}
	
	@STANDARD_MESH_SETTINGS = {
		'inlet' => {
			:min_refLevel   => 4,
			:max_refLevel   => 6,
			:addLayers      => false,
			:nSurfaceLayers => 0			
		},
		'outlet' => {
			:min_refLevel   => 4,
			:max_refLevel   => 6,
			:addLayers      => false,
			:nSurfaceLayers => 0			
		},
		'wall' => {
			:min_refLevel   => 3,
			:max_refLevel   => 6,
			:addLayers      => true,
			:nSurfaceLayers => 5			
		},
		'symmetry' => {
			:min_refLevel   => 2,
			:max_refLevel   => 4,
			:addLayers      => false,
			:nSurfaceLayers => 0			
		},
		'empty' => {
			:min_refLevel   => 2,
			:max_refLevel   => 4,
			:addLayers      => false,
			:nSurfaceLayers => 0			
		},		
	}		
	
	@model = Sketchup.active_model				
	
	class << self
	
		def store_default_project_attributes(application)	
			
			# Retrieve default model settings
			project_name = @PROJECT_NAME
			standard_applications = @STANDARD_APPLICATIONS
			standard_fluids = @STANDARD_FLUIDS
			standard_mesh_settings = @STANDARD_MESH_SETTINGS
			standard_solvers = @STANDARD_SOLVERS
			standard_turbulence_models = @STANDARD_TURBULENCE_MODELS
			standard_properties = @STANDARD_PROPERTIES
			standard_boundary_types = @STANDARD_BOUNDARY_TYPES
			standard_bcs = @STANDARD_BCS
			standard_solution_attributes = @STANDARD_SOLUTION_ATTRIBUTES
			standard_schemes_attributes = @STANDARD_SCHEMES_ATTRIBUTES
			standard_control_attributes = @STANDARD_CONTROL_ATTRIBUTES
						
			# Create a global variable domain in order to be used to store model data
			$domain = Hash.new
			$domain['active_plugin'] = "foamKit"
			$domain['paths'] = {
				:project_dir => @EXPORT_DIR,
				:paraview_dir => @PARAVIEW_DIR
			}
			
			$domain['versions'] = {
				:openfoam_version => @OF_VERSION,
				:paraview_version => @PARAVIEW_VERSION
			}			
			$domain['project_name'] = project_name + assign_project_index.to_s
			
			# This is to be used on when the project is launched later after the first time
			@model.set_attribute('project_attributes', 'project_name', $domain['project_name'])
			
			$domain['application'] = standard_applications[application]			
			$domain['application']['name'] = application				
			
			###############################################################################################
			# Create data structures cotaining default settings
			# The following settings are default settings of the project 
			# that are to be overwritten by the user's choices once they
			# proceed through their 
			
			# Get application attributes
			solver_name = $domain['application']['recommended OpenFOAM solver']
			fluid_name = $domain['application']['working fluid']			
			
			# Mesh settings. Still empty at this level because there are no defined patches yet
			mesh_settings = Hash.new
			mesh_settings[:number_of_patches] = 0
			mesh_settings[:patch_names] = []
			mesh_settings[:min_refLevel] = []
			mesh_settings[:max_refLevel] = []
			mesh_settings[:addLayers] = []
			mesh_settings[:nSurfaceLayers] = []
			mesh_settings[:thickness] = from_meter_to_model_units(0.01) # in model units
			mesh_settings[:expansionRatio] = 1.3
			mesh_settings[:locationInMesh] = M_foamKit::M_calculations.get_domain_center_point # in model units					
			$domain['mesh_settings'] = mesh_settings
			
			# Graviational properties
			gravity = standard_solvers[solver_name][:gravity]
			g_properties = {
				:gravity => gravity,
				:value   => [0, 0, -9.81]
			}			
			$domain['g_properties'] = g_properties
			
			# Working fluid as required by application
			working_fluid = {
				:name => fluid_name
			}			
			$domain['working_fluid'] = working_fluid
			
			# Transport properties of working fluid as required by the solver
			transport_properties = Hash.new
			required_properties_by_solver = standard_solvers[solver_name][:transport_properties]			
			required_properties_by_solver.each { |property_name|				
				transport_properties[property_name] = {
					:symbol => standard_properties[property_name][:symbol],
					:unit   => standard_properties[property_name][:unit],
					:value  => standard_fluids[fluid_name][property_name]
				}						
			}				
			$domain['transport_properties'] = transport_properties
			
			# Turbulence properties			
			turbulence_properties = {
				:turbulence  => standard_solvers[solver_name][:turbulence],
				:RASModel    => 'kEpsilon' # default model for all applications
			}			
			$domain['turbulence_properties'] = turbulence_properties

			# Control, solution and schemes settings
			$domain['control_settings'] = standard_control_attributes[application]
			$domain['schemes_settings'] = standard_schemes_attributes[application]
			$domain['solution_settings'] = standard_solution_attributes[application]

			# Boundary conditions
			$domain['boundary_types'] = Hash.new # this hash is empty at this level
												 # will be filled after patches are created
			$domain['boundary_conditions'] = Hash.new # this hash is empty at this level
													  # will be filled after patches are
													  # defined
			# Initial Conditions
			$domain['initial_conditions'] = @STANDARD_INITIAL_CONDITIONS[application]
				
			$domain['milestones'] = {
				:of_case_created => true,
				:mesh_created => false,
				:properties_assigned => false,
				:boundary_conditions_assigned => false,
				:simulation_run => false,
				:results_available => false
			}
					
		end
		
		def assign_project_index
			latest_index = get_latest_project
			if latest_index.nil?
				project_index = 0
			else
				project_index = latest_index + 1
			end
			return project_index
		end
		
		def get_latest_project
			export_dir = get_export_dir
			if File.directory?(export_dir+"/Sketchup")
				files_dirname = Dir[export_dir+"/Sketchup/*"]
				if files_dirname.empty?
					return nil
				else
					project_index = 0
					files_dirname.each { |dirname|
						if File.directory?(dirname)
							project_name = File.basename(dirname)
							if project_name[0..14] == "foamKit_project"
								index = project_name.gsub(/[^0-9]/, '')
								if project_index < index.to_i
									project_index = index.to_i
								end
							end
						end
					}
					return project_index
				end
			else
				return nil
			end
		end
		
		def get_export_dir
			if defined?($domain).nil? || $domain.nil?
				return @EXPORT_DIR
			else
				return $domain['paths'][:project_dir]
			end
		end
		
		def get_OF_version
			if defined?($domain).nil?
				return @OF_VERSION
			else
				return $domain['versions'][:openfoam_version]
			end
		end	

		def get_paraview_dir
			if defined?($domain).nil?
				return @PARAVIEW_DIR
			else
				return $domain['paths'][:paraview_dir]
			end
		end		
		
		def update_path(dirname, path)
			$domain['paths'][dirname.to_sym] = path
		end
		
		def update_version(software, version)
			$domain['versions'][software.to_sym] = version
		end		
		
		def get_standard_applications
			standard_application = @STANDARD_APPLICATIONS
		end
		
		def get_standard_mesh_settings
			standard_mesh_settings = @STANDARD_MESH_SETTINGS
		end			
			
		def get_schemes_settings(application)
			schemes_settings = @STANDARD_SCHEMES_ATTRIBUTES[application]		
		end
		
		def get_solution_settings(application)
			solution_settings = @STANDARD_SOLUTION_ATTRIBUTES[application]		
		end

		def get_control_settings(application)
			control_settings = @STANDARD_CONTROL_ATTRIBUTES[application]		
		end	

		def get_standard_bcs(application)
			standard_bcs = @STANDARD_BCS[application]		
		end			
			
		# Create OpenFoam Folders
		def create_folders		
			export_dir = get_export_dir
			
			if folders_exist?
				delete_folders
			end

			FileUtils.mkdir_p(export_dir+"/Sketchup/#{$domain['project_name']}/0")
			FileUtils.mkdir_p(export_dir+"/Sketchup/#{$domain['project_name']}/0.orig")
			FileUtils.mkdir_p(export_dir+"/Sketchup/#{$domain['project_name']}/constant/polyMesh")
			FileUtils.mkdir_p(export_dir+"/Sketchup/#{$domain['project_name']}/constant/triSurface")
			FileUtils.mkdir_p(export_dir+"/Sketchup/#{$domain['project_name']}/system")
			
			# Necessary for paraview
			M_foamKit.export_paraview_key
		end	
	
		# Delete OpenFoam Folders
		def delete_folders
			export_dir = get_export_dir
			FileUtils.rm_r(export_dir+"/Sketchup/#{$domain['project_name']}")
		end
		
		# Check if OpenFOAM folders exist
		def folders_exist?
			export_dir = get_export_dir		
			return File.directory?(export_dir+"/Sketchup/#{$domain['project_name']}")
		end
		
		# Checks if mesh exists by looking into the OpenFOAM durectory for one
		# of the files that are typically exported once the mesh is created
		def mesh_exists?
			export_dir = get_export_dir		
			return state = File.file?(export_dir+"/Sketchup/#{$domain['project_name']}/constant/polyMesh/boundary")
		end		
		
		# Erases mesh files from the OpenFOAM directory. It keeps the OpenFOAM folders
		def clear_mesh
			export_dir = get_export_dir
			if mesh_exists?
				FileUtils.rm_r(export_dir+"/Sketchup/#{$domain['project_name']}/constant")
				
				FileUtils.mkdir_p(export_dir+"/Sketchup/#{$domain['project_name']}/constant/triSurface")
				FileUtils.mkdir_p(export_dir+"/Sketchup/#{$domain['project_name']}/constant/polyMesh")			
			end	
		end
		
		def reset_project
			unless $domain.nil?
				delete_folders				
				@model.entities.grep(Sketchup::Group).each { |group| 
					if group.name=="mesh" || group.name=="vector_plot"
						group.erase!
					else
						group.explode
					end
				}
				$domain = nil
				$dlg_pr.close if $dlg_pr.respond_to?('close')
				$dlg_pr = nil
				$dlg_vv.close if $dlg_vv.respond_to?('close')
				$dlg_vv = nil
				disable_tool_command("init")
			end
		end
		
		# Checks if there's any group in the model
		def groups_exist?
			@model.entities.each { |entity|
				if entity.is_a?(Sketchup::Group)
					return true
				end
			}
			return false
		end
		
		# Checks if the solver is assigned
		def solver_assigned?
			solver_name = $domain['application']['recommended OpenFOAM solver']
			return true if solver_name
			return false if solver_name.nil?	
		end			
				
		def get_entity(entity_name, entity_type = "Group")
			if entity_type=="Group"
				@model.entities.each_with_index  { |entity, index|
					if entity.is_a?(Sketchup::Group) && entity.name == entity_name
						return @model.entities[index]
					end
				}			
			elsif entity_type=="Face"
				@model.entities.each_with_index  { |entity, index|
					if entity.is_a?(Sketchup::Face) && entity.name == entity_name
						return @model.entities[index]
					end
				}			
			else
				@model.entities.each_with_index  { |entity, index|
					if entity.typename == entity_type && entity.name == entity_name
						return @model.entities[index]
					end
				}
			end
			return nil
		end			
		
		def adjust_element_in_array(array, element, adjustment)
			array0 = array
			if array0.is_a?(String)				
				array = array.split("")
			end
			array.each_with_index { |el, index|
				if el==element
					array[index] = adjustment
				end
			}
			if array0.is_a?(String)
				array = array.join
			end			
			return array			
		end
		
		def correct_path(pathname)
			adjust_element_in_array(pathname, "\\", '/')
		end
		
		def get_nprocessors
			nprocessors = Etc.nprocessors
		end
		
		def model_units
			unit_m = 4
			unit_cm = 3
			unit_mm = 2
			unit_ft = 1
			unit_inch = 0
			
			case @model.options['UnitsOptions']['LengthUnit']			
			when unit_m
				'Meters'
			when unit_cm
				'Centimeters'
			when unit_mm
				'Millimeters'
			when unit_ft
				'Feet'
			when unit_inch
				'Inches'
			end					
		end
		
		def get_model_units_symbol
			units = model_units
			case units			
			when 'Meters'
				'm'
			when 'Centimeters'
				'cm'
			when 'Millimeters'
				'mm'
			when 'Feet'
				'ft'
			when 'Inches'
				'inch'
			end			
		end

		def from_model_units_to_inch(length)
			units = model_units
			if length.is_a?(Array)
				case units			
				when 'Meters'
					converted_length = []
					length.each { |el| converted_length.push(el.m)}
				when 'Centimeters'
					converted_length = []
					length.each { |el| converted_length.push(el.cm)}
				when 'Millimeters'
					converted_length = []
					length.each { |el| converted_length.push(el.mm)}
				when 'Feet'
					converted_length = []
					length.each { |el| converted_length.push(el.feet)}
				when 'Inches'
					converted_length = []
					length.each { |el| converted_length.push(el.inch)}
				end	
			else
				case units			
				when 'Meters'
					converted_length = length.m
				when 'Centimeters'
					converted_length = length.cm
				when 'Millimeters'
					converted_length = length.mm
				when 'Feet'
					converted_length = length.feet
				when 'Inches'
					converted_length = length.inch
				end		
			end	
			return converted_length
		end
		
		def from_inch_to_model_units(length)
			units = model_units
			if length.is_a?(Array)
				case units			
				when 'Meters'
					converted_length = []
					length.each { |el| converted_length.push(el.to_m)}
				when 'Centimeters'
					converted_length = []
					length.each { |el| converted_length.push(el.to_cm)}
				when 'Millimeters'
					converted_length = []
					length.each { |el| converted_length.push(el.to_mm)}
				when 'Feet'
					converted_length = []
					length.each { |el| converted_length.push(el.to_feet)}
				when 'Inches'
					converted_length = []
					length.each { |el| converted_length.push(el.to_inch)}
				end	
			else
				case units			
				when 'Meters'
					converted_length = length.to_m
				when 'Centimeters'
					converted_length = length.to_cm
				when 'Millimeters'
					converted_length = length.to_mm
				when 'Feet'
					converted_length = length.to_feet
				when 'Inches'
					converted_length = length.to_inch
				end		
			end	
			return converted_length
		end
		
		def from_model_units_to_meter(length)
			units = model_units
			if length.is_a?(Array)
				case units			
				when 'Meters'
					converted_length = []
					 converted_length = length
				when 'Centimeters'
					converted_length = []
					length.each { |el| converted_length.push(el * 0.01)}
				when 'Millimeters'
					converted_length = []
					length.each { |el| converted_length.push(el * 0.001)}
				when 'Feet'
					converted_length = []
					length.each { |el| converted_length.push(el * 0.3048)}
				when 'Inches'
					converted_length = []
					length.each { |el| converted_length.push(el * 0.0254)}
				end	
			else
				case units			
				when 'Meters'
					converted_length = length
				when 'Centimeters'
					converted_length = length * 0.01
				when 'Millimeters'
					converted_length = length * 0.001
				when 'Feet'
					converted_length = length * 0.3048
				when 'Inches'
					converted_length = length * 0.0254
				end			
			end
			return converted_length
		end

		def from_meter_to_model_units(length)
			units = model_units
			if length.is_a?(Array)
				case units			
				when 'Meters'
					converted_length = []
					length.each { |el| converted_length.push(el)}
				when 'Centimeters'
					converted_length = []
					length.each { |el| converted_length.push(el / 0.01)}
				when 'Millimeters'
					converted_length = []
					length.each { |el| converted_length.push(el / 0.001)}
				when 'Feet'
					converted_length = []
					length.each { |el| converted_length.push(el / 0.3048)}
				when 'Inches'
					converted_length = []
					length.each { |el| converted_length.push(el / 0.0254)}
				end	
			else
				case units			
				when 'Meters'
					converted_length = length
				when 'Centimeters'
					converted_length = length / 0.01
				when 'Millimeters'
					converted_length = length / 0.001
				when 'Feet'
					converted_length = length / 0.3048
				when 'Inches'
					converted_length = length / 0.0254
				end			
			end
			return converted_length
		end
		
		def get_meter_conversion_ratio
			units = model_units
			case units			
			when 'Meters'
				ratio = 1
			when 'Centimeters'
				ratio = 0.01
			when 'Millimeters'
				ratio = 0.001
			when 'Feet'
				ratio = 0.3048
			when 'Inches'
				ratio = 0.0254
			end
		end
		
		# This function is important for blockMeshDict where the bounds of the domain are necessary to blockMesh
		# The bounds are retrieved directly from Sketchup
		def get_bounds			
			bounds = @model.bounds
			model_bounds = {
				:pt0 => from_inch_to_model_units(bounds.corner(0).to_a),
				:pt1 => from_inch_to_model_units(bounds.corner(1).to_a),
				:pt2 => from_inch_to_model_units(bounds.corner(3).to_a),
				:pt3 => from_inch_to_model_units(bounds.corner(2).to_a),
				:pt4 => from_inch_to_model_units(bounds.corner(4).to_a),
				:pt5 => from_inch_to_model_units(bounds.corner(5).to_a),
				:pt6 => from_inch_to_model_units(bounds.corner(7).to_a),
				:pt7 => from_inch_to_model_units(bounds.corner(6).to_a)
			}
			return M_foamKit::M_calculations.round_bounds(model_bounds)
		end		
		
		def to_boolean(str)
			if str == "true"
				return true
			elsif str == "false"
				return false
			end
		end
		
		def draw_sphere(location, radius)
			compdef = @model.definitions.add("sphere")	
			circle = compdef.entities.add_circle(from_model_units_to_inch(location), [0, 0, 1], from_model_units_to_inch(radius))
			circle_face = compdef.entities.add_face(circle)
			
			circle_face.material = "Red"
			circle_face.back_material = "Red"
			
			path = compdef.entities.add_circle(from_model_units_to_inch(location), [0, 1, 0], from_model_units_to_inch(radius/1.2))

			circle_face.followme path		
			
			trans = Geom::Transformation.new
			@model.entities.add_instance(compdef, trans) 
		end
		
		def draw_rhombus(location, radius)
			compdef = @model.definitions.add("sphere")	
			circle = compdef.entities.add_circle(from_model_units_to_inch(location), [0, 0, 1], from_model_units_to_inch(radius))
			circle_face = compdef.entities.add_face circle
			
			circle_face.material = Sketchup::Color.new("Red")
			circle_face.back_material = Sketchup::Color.new("Red")
			
			path = compdef.entities.add_circle(from_model_units_to_inch(location), [0, 1, 0], from_model_units_to_inch(radius + 1))

			circle_face.followme path
			compdef.entities.erase_entities path		
			
			trans = Geom::Transformation.new
			@model.entities.add_instance(compdef, trans) 
		end		
		
		def get_unassigned_face_entities
			unassigned_faces = []
			index = 0
			@model.entities.each { |entity|
				if entity.is_a?(Sketchup::Face)
					if  !entity.hidden?
						unassigned_faces[index] = entity
						index += 1
					end
				end			
			}	
			return unassigned_faces
		end
		
		def update_html(html_text, statements, adjustments, shift = "backwards")
			if statements.is_a?(Array)
				statements.each_with_index { |statement, index|			
					loc_statement = html_text.index(statement)
					char_count = statement.length
					if shift=="backwards"
						html_text[loc_statement..loc_statement+char_count-1] = ""
						html_text[loc_statement-1] = adjustments[index]
					elsif shift=="in_place"
						html_text[loc_statement..loc_statement+char_count-1] = " "
						html_text[loc_statement] = adjustments[index]			
					end				
				}
			else
				loc_statement = html_text.index(statements)
				char_count = statements.length
				if shift=="backwards"
					html_text[loc_statement..loc_statement+char_count-1] = ""
					html_text[loc_statement-1] = adjustments
				elsif shift=="in_place"
					html_text[loc_statement..loc_statement+char_count-1] = " "
					html_text[loc_statement] = adjustments			
				end							
			end
			return html_text
		end

		def export_blockMeshDict
			export_dir = get_export_dir
			bounds = get_bounds										
			File.write(export_dir+"/Sketchup/#{$domain['project_name']}/system/blockMeshDict", M_foamKit.define_blockMeshDict(bounds))
		end
		
		def export_surfaceFeatureExtractDict
			export_dir = get_export_dir
			patch_names = $domain['mesh_settings'][:patch_names]
			File.write(export_dir+"/Sketchup/#{$domain['project_name']}/system/surfaceFeatureExtractDict", M_foamKit.define_surfaceFeatureExtractDict(patch_names))
		end
		
		def export_decomposeParDict
			export_dir = get_export_dir									
			File.write(export_dir+"/Sketchup/#{$domain['project_name']}/system/decomposeParDict", M_foamKit.define_decomposeParDict)
		end		

		def export_snappyHexMeshDict
			export_dir = get_export_dir
			patch_names = $domain['mesh_settings'][:patch_names]
			File.write(export_dir+"/Sketchup/#{$domain['project_name']}/system/snappyHexMeshDict", M_foamKit.define_snappyHexMeshDict(patch_names))
		end		
		
		def export_controlDict
			export_dir = get_export_dir
			File.write(export_dir+"/Sketchup/#{$domain['project_name']}/system/controlDict", M_foamKit.define_controlDict)
		end
		
		def export_fvSchemes
			export_dir = get_export_dir
			File.write(export_dir+"/Sketchup/#{$domain['project_name']}/system/fvSchemes", M_foamKit.define_fvSchemes)
		end
		
		def export_fvSolution
			export_dir = get_export_dir
			File.write(export_dir+"/Sketchup/#{$domain['project_name']}/system/fvSolution", M_foamKit.define_fvSolution)
		end			
		
		def export_g_properties
			export_dir = get_export_dir
			File.write(export_dir+"/Sketchup/#{$domain['project_name']}/constant/g", M_foamKit.define_g)
		end	
		
		def export_transport_properties
			export_dir = get_export_dir
			File.write(export_dir+"/Sketchup/#{$domain['project_name']}/constant/transportProperties", M_foamKit.define_transportProperties)
		end	

		def export_turbulence_properties
			export_dir = get_export_dir
			File.write(export_dir+"/Sketchup/#{$domain['project_name']}/constant/turbulenceProperties", M_foamKit.define_turbulenceProperties)
		end	

		def export_field(field_name, field_boundary_conditions)
			export_dir = get_export_dir
			File.write(export_dir+"/Sketchup/#{$domain['project_name']}/0/#{field_name}", M_foamKit.define_field(field_name, field_boundary_conditions))
		end
		
		def export_sample(field, point, normal, surface_name)
			export_dir = get_export_dir
			File.write(export_dir+"/Sketchup/#{$domain['project_name']}/system/sample", M_foamKit.define_sample(field, point, normal, surface_name))
		end		

		def faces_coplanar?(face1, face2)
			vertices = face1.vertices + face2.vertices
			plane = Geom.fit_plane_to_points( vertices.map{|v| v.position} )
			vertices.all? { |v| 
				v.position.on_plane?(plane) 
			}
		end
		
		def faces_overlapping?(face1, face2)
			return false if face1 == face2
			
			if faces_coplanar?(face1, face2)
				v1 = face1.outer_loop.vertices
				v2 = face2.outer_loop.vertices			
				# Check if any of face1 vertices lies inside face2
				v1.each_with_index { |vertex|
					result = face2.classify_point(vertex)
					return true if result == Sketchup::Face::PointInside			
				}			
				# Check if any of face2 vertices lies inside face1
				v2.each_with_index { |vertex|
					result = face1.classify_point(vertex)
					return true if result == Sketchup::Face::PointInside			
				}
			end	
			return false
		end

		def faces_strictly_overlapping?(face1, face2, transform1, transform2)
			return false if face1 == face2
					
			v1 = face1.outer_loop.vertices.map { |vertex|
				vertex.position.transform(transform1)
			}
			v2 = face2.outer_loop.vertices.map { |vertex|
				vertex.position.transform(transform2)
			}
			
			return true if v1 == v2
		end		
		
		def convert_name(name)
			while name.index(" ") do
				name[name.index(" ")] = "_"
			end
			return name
		end
		
		def get_latest_unassigned_wall_index
			patch_list = get_patch_list
			array_of_indecis = []
			patch_list.each { |patch_name|
				if patch_name.index("unassigned_wall")
					array_of_indecis << patch_name.gsub(/[^\d]/, '').to_i					
				end
			}
			
			(1..array_of_indecis.length-1).each do |i|
				if array_of_indecis[i]-array_of_indecis[i-1] > 1
					return array_of_indecis[i-1] 					
				end
			end
			
			return array_of_indecis[array_of_indecis.length-1]
		end				
		
		def get_frequency(array, element)
			freq = 0
			array.each { |el|
				if el==element
					freq += 1
				end
			}
			return freq
		end
		
		def convert_unit(unit)
			dimensionSet = [0, 0, 0, 0, 0, 0, 0]
			
			slash_loc = unit.index("/")
			dash_loc = unit.index("-")
			
			kg_loc = unit.index("kg")
			unless kg_loc.nil?
				kg_exp = unit[kg_loc+1].to_i
				if kg_exp !=0 
					if slash_loc
						if kg_loc<slash_loc
							dimensionSet[0] = kg_exp
						else	
							dimensionSet[0] = -kg_exp
						end	
					end
				else
					if slash_loc
						if kg_loc<slash_loc
							dimensionSet[0] = 1
						else	
							dimensionSet[0] = -1
						end
					else
					  dimensionSet[0] = 1
					end				
				end
				unit[kg_loc] = ""
			end
			
			m_loc = unit.index("m")
			unless m_loc.nil?
				m_exp = unit[m_loc+1].to_i
				if m_exp !=0 
					if slash_loc
						if m_loc<slash_loc
							dimensionSet[1] = m_exp
						else	
							dimensionSet[1] = -m_exp
						end	
					end
				else
					if slash_loc                
						if m_loc<slash_loc
							dimensionSet[1] = 1
						else	
							dimensionSet[1] = -1
						end
					else
					  dimensionSet[1] = 1
					end				
				end
			end			
			
			s_loc = unit.index("s")
			unless s_loc.nil?
				s_exp = unit[s_loc+1].to_i         
				if s_exp !=0       
					if slash_loc           
						if s_loc<slash_loc
							dimensionSet[2] = s_exp
						else	
							dimensionSet[2] = -s_exp
						end	
					end
				else
					if slash_loc
						if s_loc<slash_loc
							dimensionSet[2] = 1
						else	
							dimensionSet[2] = -1
						end
					else
					  dimensionSet[2] = 1
					end				
				end
			end			

			k_loc = unit.index("k")	
			unless k_loc.nil?
				k_exp = unit[k_loc+1].to_i
				if k_exp !=0 
					if slash_loc
						if k_loc<slash_loc
							dimensionSet[3] = k_exp
						else	
							dimensionSet[3] = -k_exp
						end	
					end
				else
					if slash_loc
						if k_loc<slash_loc
							dimensionSet[3] = 1
						else	
							dimensionSet[3] = -1
						end
					else
					  dimensionSet[3] = 1
					end					
				end
			end	

			return dimensionSet						
		end				
		
		def change_patches_color(color)
			patch_names = $domain['mesh_settings'][:patch_names]
			patch_names.each { |name|
				patch = M_foamKit.get_entity(name, "Group")
				patch.material = color
			} 		
		end
		
		def get_patch_area(patch_name)
			patch = get_entity(patch_name, "Group")
			area = 0;
			patch.entities.each { |ent|
				area += ent.area if ent.is_a?(Sketchup::Face)				
			}
		
		end
		
		def get_suggested_turbulence_models
			application = $domain['application']['name']
			suggested_turbulence_models = @APPLICABLE_TURBULENCE_MODELS[application]
		end
		
		def get_suggested_fluids
			application = $domain['application']['name']
			suggested_fluids = @APPLICABLE_FLUIDS[application]
		end
							
		def get_required_fields(vector = false)
			required_fields = []
			application = $domain['application']['name']
			@STANDARD_REQUIRED_FIELDS[application].each { |field, value|
				if value[:class] == "volVectorField" && vector
					required_fields.push("#{field}x")
					required_fields.push("#{field}y")
					required_fields.push("#{field}z")
				else
					required_fields.push(field)
				end
			}
			return required_fields
		end		
		
		def get_field_dimensions_and_class(field)
			required_fields = get_required_fields
			if required_fields.include?(field)
				attributes = @STANDARD_REQUIRED_FIELDS[$domain['application']['name']][field]
				field_unit = convert_unit(attributes[:unit])
				field_class = attributes[:class]
				return field_unit, field_class
			else
				return [0, 0, 0, 0, 0, 0, 0], 'volScalarField'
			end
		end		
		
		def get_field_initial_condition(field)
			value = $domain['initial_conditions'][field]		
		end
		
		def get_predicted_boundary_type(patch_name)
			return "inlet" if patch_name.index("inlet") || patch_name.index("Inlet") || patch_name.index("INLET")
			return "outlet" if patch_name.index("outlet") || patch_name.index("Outlet") || patch_name.index("OUTLET")
			return "wall" if patch_name.index("wall") || patch_name.index("Wall") || patch_name.index("WALL")
			return "symmetry" if patch_name.index("symmetry") || patch_name.index("Symmetry") || patch_name.index("SYMMETRY")
			return "empty" if patch_name.index("empty") || patch_name.index("Empty") || patch_name.index("EMPTY")
			return "wall"
		end		
		
		def get_solver_class
			solver_name = $domain['application']['recommended OpenFOAM solver']
			solver_class = @STANDARD_SOLVERS[solver_name][:class]
		end
		
		def get_turbulence_constants(turbulence_model, constant_name)
			constant_value = @STANDARD_TURBULENCE_MODELS[turbulence_model][:constants][constant_name.to_sym]
		end
		
		def get_alias_solver(solver_name)
			alias_solver = @STANDARD_SOLVERS[solver_name][:alias_solver]
			if alias_solver.nil?
				return solver_name
			else
				return alias_solver
			end
		end
		
		def get_solver_time(solver_name)
			solver_time = @STANDARD_SOLVERS[solver_name][:time]
		end	
		
		def update_milestones(flag, status = true)
			$domain['milestones'][flag.to_sym] = status			
		end
		
		def milestone_accomplished?(flag = "pre")
			unless flag=="pre"
				return true if $domain['milestones'][flag.to_sym]
				return false
			else
				if $domain['milestones'][:mesh_created] && $domain['milestones'][:properties_assigned] && $domain['milestones'][:boundary_conditions_assigned]
					return true
				else
					return false
				end
			end
		end
		
		def enable_tool_command(command_menu_text = "pre")			
			if command_menu_text=="pre"
				$fk_toolbar.each { |command|
					unless command.is_a?(String)
						if command.menu_text == "mesh" || command.menu_text == "properties" || command.menu_text == "boundary_conditions"
							command.set_validation_proc {
								MF_ENABLED
							}
						end
					end
				}
			elsif command_menu_text=="post"
				$fk_toolbar.each { |command|
					unless command.is_a?(String)
						if command.menu_text == "mesh" || command.menu_text == "properties" || command.menu_text == "boundary_conditions" || command.menu_text == "solve" || command.menu_text == "result" || command.menu_text == "view"
							command.set_validation_proc {
								MF_ENABLED
							}
						end
					end
				}
			else
				$fk_toolbar.each { |command|
					unless command.is_a?(String)
						if command.menu_text == command_menu_text
							command.set_validation_proc {
								MF_ENABLED
							}
						end
					end
				}				
			end			
		end
		
		def disable_tool_command(command_menu_text = "init")			
			if command_menu_text=="init"
				$fk_toolbar.each { |command|
					unless command.is_a?(String)
						if command.menu_text == "mesh" || command.menu_text == "properties" || command.menu_text == "boundary_conditions" || command.menu_text == "solve" || command.menu_text == "result" || command.menu_text == "view"
							command.set_validation_proc {
								MF_GRAYED
							}
						end
					end
				}
			else
				$fk_toolbar.each { |command|
					unless command.is_a?(String)
						if command.menu_text == command_menu_text
							command.set_validation_proc {
								MF_GRAYED
							}
						end
					end
				}				
			end			
		end	
		
		def get_tool_command(command_menu_text)
			$fk_toolbar.each { |command|
				unless command.is_a?(String)
					if command.menu_text == command_menu_text
						return command
					end
				end
			}
		end
		
		def adjust_icon(command_menu_text, style = "done")
			tool_command = get_tool_command(command_menu_text)
			case tool_command.menu_text			
			when "foamKit"
				unless style=="done"
					tool_command.large_icon = "img/fk_1_24.png"
				else
					tool_command.large_icon = "img/fk_1_24_done.png"
				end
			when "mesh"
				unless style=="done"
					tool_command.large_icon = "img/fk_2_24.png"
				else
					tool_command.large_icon = "img/fk_2_24_done.png"
				end
			when "properties"
				unless style=="done"
					tool_command.large_icon = "img/fk_4_24.png"
				else
					tool_command.large_icon = "img/fk_4_24_done.png"
				end
			when "boundary_conditions"
				unless style=="done"
					tool_command.large_icon = "img/fk_6_24.png"
				else
					tool_command.large_icon = "img/fk_6_24_done.png"
				end
			when "solve"
				unless style=="done"
					tool_command.large_icon = "img/fk_3_24.png"
				else
					tool_command.large_icon = "img/fk_3_24_done.png"
				end
			end				
		end				
		
		def export_residuals			
			export_dir = get_export_dir	
			File.write(export_dir+"/Sketchup/#{$domain['project_name']}/system/residuals", M_foamKit.define_residuals)
		end
		
		def export_gnuplot_script
			export_dir = get_export_dir	
			file = File.new("#{export_dir}/Sketchup/#{$domain['project_name']}/postProcessing/residuals/0/residuals.dat", "r")
			counter = 0
			while (line = file.gets)
				if line[0..5]=='# Time'
					vars = line.split(" ")
					vars.delete('#')
					vars.delete('Time')
					break
				end
				counter = counter + 1
			end
			file.close
			
			gnuplot_script = "set title #{'"'}Convergence process#{'"'}\nset xlabel #{'"'}Iterations#{'"'}\nset ylabel #{'"'}Residuals#{'"'}\nset logscale y"
			gnuplot_script << "\nplot "	
			vars.each_with_index { |var, index|
				gnuplot_script << "#{'"'}#{export_dir}/Sketchup/#{$domain['project_name']}/postProcessing/residuals/0/residuals.dat#{'"'} using 1:#{index+2} title #{'"'}#{var}#{'"'} w lines, "
			}
			gnuplot_script[gnuplot_script.length-2..gnuplot_script.length-1] = ""
			gnuplot_script << "\nreread"	
			
			File.write(export_dir+"/Sketchup/#{$domain['project_name']}/plot_res", gnuplot_script)
		end		
		
		def get_directories(category = "no data")
			export_dir = get_export_dir
			if category=="no data"
				directories = [
				export_dir+"/Sketchup/#{$domain['project_name']}/0.orig",			
				export_dir+"/Sketchup/#{$domain['project_name']}/constant",
				export_dir+"/Sketchup/#{$domain['project_name']}/dynamicCode",
				export_dir+"/Sketchup/#{$domain['project_name']}/postProcessing",
				export_dir+"/Sketchup/#{$domain['project_name']}/system"]
			elsif category=="fundamental"	
				directories = [
				export_dir+"/Sketchup/#{$domain['project_name']}/0",
				export_dir+"/Sketchup/#{$domain['project_name']}/0.orig",			
				export_dir+"/Sketchup/#{$domain['project_name']}/constant",
				export_dir+"/Sketchup/#{$domain['project_name']}/system"]			
			end
			return directories
		end
		
		def get_fields_timesteps
			no_data_directories = get_directories("no data")
			export_dir = get_export_dir	
			files_dirname = Dir[export_dir+"/Sketchup/#{$domain['project_name']}/*"]
			fields_timesteps = []
			files_dirname.each { |filename|
				if File.directory?(filename) && !no_data_directories.include?(filename)
					fields_timesteps.push(filename)
				end
			}
			return fields_timesteps
		end
		
		def get_latest_field_timestep
			fields_timesteps = get_fields_timesteps
			timesteps = []
			float_timesteps = []
			fields_timesteps.each { |directory|
				comps = directory.split("/")
				timesteps.push(comps[comps.length-1])
				float_timesteps.push(comps[comps.length-1].to_f)
			}
			index_of_latest_field_timestep = float_timesteps.index(float_timesteps.max)
			latest_field_timestep = timesteps[index_of_latest_field_timestep]
		end
		
		def correct_fields_files
			fields_timesteps = get_fields_timesteps
			required_fields = get_required_fields
			required_fields.each { |field|
				$domain['boundary_conditions'][field].each { |patch_name, attributes|
					if attributes[:type]=="codedMixed"
						fields_timesteps.each { |filename|
							boundary_field = File.read(filename + "/" + field)	
							boundary_field = boundary_field.gsub("name", '/*name')
							boundary_field = boundary_field.gsub('#};', '#};*/')
							File.write(filename + "/" + field, boundary_field)
						}
					end				
				}
			}		
		end
		
		def restore_previous_run_changes
			fields_timesteps = get_fields_timesteps
			required_fields = get_required_fields
			required_fields.each { |field|
				$domain['boundary_conditions'][field].each { |patch_name, attributes|
					if attributes[:type]=="codedMixed"
						fields_timesteps.each { |filename|
							boundary_field = File.read(filename + "/" + field)	
							boundary_field = boundary_field.gsub('/*name', "name")
							boundary_field = boundary_field.gsub('#};*/', '#};')
							File.write(filename + "/" + field, boundary_field)
						}
					end				
				}
			}			
		end
		
		def delete_processor_folders(n_processors)
			export_dir = get_export_dir
			n_processors.times do |index_processor|									
				dir = export_dir+"/Sketchup/#{$domain['project_name']}/processor#{index_processor}"
				FileUtils.rm_r(dir)
			end
		end
		
		# Clears OpenFOAM results while keeping fundamental folders
		def clear_results
			fundamental_directories = get_directories("fundamental")
			fundamental_directories.each { |dir|
				FileUtils.rm_r(dir)
			}
		end	

		def clear_residuals_file
			export_dir = M_foamKit.get_export_dir
			res_file_path = "#{export_dir}/Sketchup/#{$domain['project_name']}/postProcessing/residuals/0/residuals.dat"
			begin
				FileUtils.rm(res_file_path.to_s) if File.file?(res_file_path)
			rescue
				nil
			end			
		end
		
		def wait_until_res_file_created
			export_dir = M_foamKit.get_export_dir
			file_created = false
			until file_created
				sleep(1)
				res_file_path = "#{export_dir}/Sketchup/#{$domain['project_name']}/postProcessing/residuals/0/residuals.dat"
				file_created = File.file?(res_file_path.to_s)
			end
			fields_timesteps = []
			while fields_timesteps.empty?
				sleep(1)
				fields_timesteps = get_fields_timesteps
			end			
		end	

		def export_paraview_key
			export_dir = M_foamKit.get_export_dir
			File.write("#{export_dir}/Sketchup/#{$domain['project_name']}/a.foam", "")	
		end	

		def dialog_progress			
			$dlg_pr = UI::WebDialog.new("Progress", false, "foamKit", 400, 250, 0, 0, true)
			$dlg_pr.set_background_color("f3f0f0")
			$dlg_pr.set_size(212, 210)
			$dlg_pr.set_position(0, 480)
			$dlg_pr.show
			$dlg_pr.set_on_close{ 
				$dlg_pr = nil
			}
		end		
		
		def update_progress
			html = File.read("#{@dir}/html/progress.html")
			progress_milestones = get_progress_milestones
			progress_milestones.each { |progress_milestone|
				if milestone_accomplished?(progress_milestone)
					html = M_foamKit.update_html(html, "--#{progress_milestone}--", "&#9745;", "in_place")
				else
					html = M_foamKit.update_html(html, "--#{progress_milestone}--", "&#9744;", "in_place")
				end
			}	
			if defined?($dlg_pr).nil? || $dlg_pr.nil?
				dialog_progress
			end
			$dlg_pr.set_html(html)
		end
		
		def get_progress_milestones
			progress_milestones = ["of_case_created", "mesh_created", "properties_assigned", "boundary_conditions_assigned", "simulation_run"]
		end	

		def get_subdomains
			n_processors = $domain['n_processors']
			
			x_scale = M_foamKit::M_calculations.get_length_scale("x")
			y_scale = M_foamKit::M_calculations.get_length_scale("y")
			z_scale = M_foamKit::M_calculations.get_length_scale("z")
			
			arr = []
			for nx in 1..n_processors
				for ny in 1..n_processors
				   for nz in 1..n_processors
					  arr.push([nx, ny, nz]) if nx*ny*nz==n_processors
				   end			
				end
			end	

			rx = (x_scale * n_processors / (x_scale + y_scale + z_scale)).round
			ry = (y_scale * n_processors / (x_scale + y_scale + z_scale)).round
			rz = (z_scale * n_processors / (x_scale + y_scale + z_scale)).round
			
			r = [rx, ry, rz]
			domain_weights = M_foamKit::M_calculations.match(r, arr)
			unless domain_weights
				domain_weights = [n_processors, 1, 1]
			end		
			return domain_weights
		end
		
		class MyModelObserver < Sketchup::ModelObserver
			def onSaveModel(model)
				unless $domain.nil?
					export_dir = M_foamKit.get_export_dir
					File.write(export_dir+"/Sketchup/#{$domain['project_name']}/domain", $domain)
					
					# Check if file created
					status = File.file?(export_dir+"/Sketchup/#{$domain['project_name']}/domain")
					unless status
						UI.messagebox('An error has occurred, the case cannot be saved!')
					end					
				end
			end		
		end

		# Attach the observer
		Sketchup.active_model.add_observer(MyModelObserver.new)
		
		class MyAppObserver < Sketchup::AppObserver
			def onOpenModel(model)				
				project_name = Sketchup.active_model.get_attribute('project_attributes', 'project_name')								
				if project_name	
					$domain = nil unless $domain.nil?								
					$dlg_pr.close if $dlg_pr.respond_to?('close')
					
					export_dir = M_foamKit.get_export_dir
					data_exists = File.file?(export_dir+"/Sketchup/#{Sketchup.active_model.get_attribute('project_attributes', 'project_name')}/domain")
					if data_exists
						$domain = eval(File.read(export_dir+"/Sketchup/#{Sketchup.active_model.get_attribute('project_attributes', 'project_name')}/domain"))
						M_foamKit.update_progress
						if M_foamKit.milestone_accomplished?("simulation_run")
							M_foamKit.enable_tool_command("post")
						elsif M_foamKit.milestone_accomplished?("pre")
							M_foamKit.enable_tool_command("pre")
							M_foamKit.enable_tool_command("solve")
						else
							M_foamKit.enable_tool_command("pre")
						end
					end
				else
					unless $domain.nil?
						$dlg_pr.close if $dlg_pr.respond_to?('close')
						M_foamKit.disable_tool_command("init")
						export_dir = M_foamKit.get_export_dir				
						data_exists = File.file?(export_dir+"/Sketchup/#{$domain['project_name']}/domain")	
						if data_exists
							$dlg_pr = nil
							$dlg_vv = nil
							$domain = nil
						end
					end
				end
			end
			def onNewModel(model)
				unless $domain.nil?
					$dlg_pr.close if $dlg_pr.respond_to?('close')
					M_foamKit.disable_tool_command("init")
					export_dir = M_foamKit.get_export_dir				
					data_exists = File.file?(export_dir+"/Sketchup/#{$domain['project_name']}/domain")	
					if data_exists
						$dlg_pr = nil
						$dlg_vv = nil
						$domain = nil
					end
				end
			end	

			def onQuit()
			end
		end

		# Attach the observer
		Sketchup.add_observer(MyAppObserver.new)

		# Add an observer for move tool
		class MyToolsObserver < Sketchup::ToolsObserver
			def onToolStateChanged(tools, tool_name, tool_id, tool_state)
				if tool_name=="MoveTool" && defined?($dlg_m)
					if tool_state==0
						sel = Sketchup.active_model.selection
						unless sel.empty?
							bounds = sel[0].bounds
							
							sphere_bounds = {
								:pt0 => M_foamKit.from_inch_to_model_units(bounds.corner(0).to_a),
								:pt1 => M_foamKit.from_inch_to_model_units(bounds.corner(1).to_a),
								:pt2 => M_foamKit.from_inch_to_model_units(bounds.corner(3).to_a),
								:pt3 => M_foamKit.from_inch_to_model_units(bounds.corner(2).to_a),
								:pt4 => M_foamKit.from_inch_to_model_units(bounds.corner(4).to_a),
								:pt5 => M_foamKit.from_inch_to_model_units(bounds.corner(5).to_a),
								:pt6 => M_foamKit.from_inch_to_model_units(bounds.corner(7).to_a),
								:pt7 => M_foamKit.from_inch_to_model_units(bounds.corner(6).to_a)
							}							
														
							center = M_foamKit::M_calculations.get_domain_center_point(sphere_bounds)

							cx = center[0].to_f
							cy = center[1].to_f
							cz = center[2].to_f

							js_command = "document.getElementById('xLoc').value = #{cx};
										  document.getElementById('yLoc').value = #{cy};
										  document.getElementById('zLoc').value = #{cz};
										  general_mesh_settings.locationInMesh = [#{cx}, #{cy}, #{cz}];"
							
							$dlg_m.execute_script(js_command)
						end
					end
				end
			end
		end	

		Sketchup.active_model.tools.add_observer(MyToolsObserver.new)		
		
	end # end of class << self
	
end # end module M_foamKit

# Get file name of this file
file = File.basename(__FILE__)

# Check if information is stored from previous session. If yes, load them
if Sketchup.active_model.title==""
	data_exists = false
else
	if Sketchup.active_model.get_attribute('project_attributes', 'project_name')
		data_exists = true
		export_dir = M_foamKit.get_export_dir
		$domain = eval(File.read(export_dir+"/Sketchup/#{Sketchup.active_model.get_attribute('project_attributes', 'project_name')}/domain"))
		M_foamKit.update_progress
	else
		data_exists = false
	end
end

# Add menu items
unless file_loaded?(file)

	# Add toolbar
	$fk_toolbar = UI::Toolbar.new("foamKit")

	# Add start foamKit command
	fk_cmd = UI::Command.new("Start foamKit") { 
		M_foamKit::M_dialog.dialog_start
	}  
	fk_cmd.small_icon = "img/fk_1_16.png"
	fk_cmd.large_icon = "img/fk_1_24.png"
	fk_cmd.tooltip = "Start foamKit"
	fk_cmd.status_bar_text = "Create OpenFoam Case"
	fk_cmd.menu_text = "foamKit"
	$fk_toolbar.add_item(fk_cmd)

	# Add foamKit snappyHexMesh command
	fk_cmd = UI::Command.new("Create Mesh") { 
		M_foamKit::M_dialog.dialog_mesh
	}  
	fk_cmd.small_icon = "img/fk_2_16.png"
	fk_cmd.large_icon = "img/fk_2_24.png"
	fk_cmd.tooltip = "Create Mesh"
	fk_cmd.status_bar_text = "Set snappyHexMesh Dictionary"
	fk_cmd.menu_text = "mesh"
	fk_cmd.set_validation_proc {
		if data_exists
			state = M_foamKit.milestone_accomplished?("of_case_created")
			unless state
				MF_GRAYED
			end
		else
			MF_GRAYED
		end
	}  
	$fk_toolbar.add_item(fk_cmd)   
	
	# Add foamKit Constant Properties command
	fk_cmd = UI::Command.new("Set Constant Properties") { 
		M_foamKit::M_dialog.dialog_constant_properties
	}  
	fk_cmd.small_icon = "img/fk_4_16.png"
	fk_cmd.large_icon = "img/fk_4_24.png"
	fk_cmd.tooltip = "Set Constant Properties"
	fk_cmd.status_bar_text = "Set Gravity, Material Properties and Turbulence Properties"
	fk_cmd.menu_text = "properties"
	fk_cmd.set_validation_proc {
		if data_exists
			state = M_foamKit.milestone_accomplished?("of_case_created")
			unless state
				MF_GRAYED
			end
		else
			MF_GRAYED
		end
	}   	
	$fk_toolbar.add_item(fk_cmd)

	# Add foamKit Boundary Conditions command
	fk_cmd = UI::Command.new("Set Boundary Conditions") { 
		M_foamKit::M_dialog.dialog_boundary_conditions
	}  
	fk_cmd.small_icon = "img/fk_6_16.png"
	fk_cmd.large_icon = "img/fk_6_24.png"
	fk_cmd.tooltip = "Set Boundary Conditions"
	fk_cmd.status_bar_text = "Set Boundary Type and Relevant Attributes"
	fk_cmd.menu_text = "boundary_conditions" 	
	fk_cmd.set_validation_proc {
		if data_exists	
			unless M_foamKit.milestone_accomplished?("of_case_created")
				MF_GRAYED
			end
		else
			MF_GRAYED
		end
	} 		
	$fk_toolbar.add_item(fk_cmd)

	# Add foamKit System command
	fk_cmd = UI::Command.new("Run Manager") { 
		M_foamKit::M_dialog.dialog_solver
	}  
	fk_cmd.small_icon = "img/fk_3_16.png"
	fk_cmd.large_icon = "img/fk_3_24.png"
	fk_cmd.tooltip = "Run Manager"
	fk_cmd.status_bar_text = "Set Time Settings and Run Simulation"
	fk_cmd.menu_text = "solve"
	fk_cmd.set_validation_proc {
		if data_exists	
			unless M_foamKit.milestone_accomplished?("pre")
				MF_GRAYED
			end
		else
			MF_GRAYED
		end
	}    	
	$fk_toolbar.add_item(fk_cmd)	
	
	# Add foamKit Results command
	fk_cmd = UI::Command.new("Display Simulation Results 1") { 
		M_foamKit::M_graphics.dialog_vel_vectors
	}  
	fk_cmd.small_icon = "img/fk_7_16.png"
	fk_cmd.large_icon = "img/fk_7_24.png"
	fk_cmd.tooltip = "Plot Results"
	fk_cmd.status_bar_text = "Display Contours, Vectors and Streamlines"
	fk_cmd.menu_text = "result"
	fk_cmd.set_validation_proc {
		if data_exists	
			unless M_foamKit.milestone_accomplished?("simulation_run")
				MF_GRAYED
			end
		else
			MF_GRAYED
		end
	}  	
	$fk_toolbar.add_item(fk_cmd)	

	# Add foamKit Paraview command
	fk_cmd = UI::Command.new("Display Simulation Results 2") { 
		M_foamKit.run_paraview
	}  
	fk_cmd.small_icon = "img/fk_5_16.png"
	fk_cmd.large_icon = "img/fk_5_24.png"
	fk_cmd.tooltip = "Open ParaView"
	fk_cmd.status_bar_text = "Visualize Results by ParaView"
	fk_cmd.menu_text = "view"
	fk_cmd.set_validation_proc {
		if data_exists	
			unless M_foamKit.milestone_accomplished?("simulation_run")
				MF_GRAYED
			end
		else
			MF_GRAYED
		end
	}  	
	$fk_toolbar.add_item(fk_cmd)

	$fk_toolbar.add_separator
	
	# Add Reset button
	fk_cmd = UI::Command.new("Reset Project") { 
		M_foamKit.reset_project
	}  
	fk_cmd.small_icon = "img/fk_10_16.png"
	fk_cmd.large_icon = "img/fk_10_24.png"
	fk_cmd.tooltip = "Reset"
	fk_cmd.status_bar_text = "Clear Mesh and Results"
	fk_cmd.menu_text = "reset" 	
	$fk_toolbar.add_item(fk_cmd)	
	
	# Add foamKit Preferences
	fk_cmd = UI::Command.new("Set Preferences") { 
		M_foamKit::M_dialog.set_preferences
	}  
	fk_cmd.small_icon = "img/fk_8_16.png"
	fk_cmd.large_icon = "img/fk_8_24.png"
	fk_cmd.tooltip = "Preferences"
	fk_cmd.status_bar_text = "Set Paths for OpenFOAM, Paraview and GNUPLOT"
	fk_cmd.menu_text = "preferences" 	
	$fk_toolbar.add_item(fk_cmd)

	# Add foamKit About
	fk_cmd = UI::Command.new("Set Preferences") { 
		M_foamKit::M_dialog.display_about
	}  
	fk_cmd.small_icon = "img/fk_9_16.png"
	fk_cmd.large_icon = "img/fk_9_24.png"
	fk_cmd.tooltip = "About"
	fk_cmd.status_bar_text = "About foamKit"
	fk_cmd.menu_text = "about" 	
	$fk_toolbar.add_item(fk_cmd)	

	$fk_toolbar.show		

	# Tell SU that we loaded this file
	file_loaded file
end
