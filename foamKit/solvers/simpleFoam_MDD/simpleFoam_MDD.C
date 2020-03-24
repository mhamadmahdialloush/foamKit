/*---------------------------------------------------------------------------*\
  =========                 |
  \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox
   \\    /   O peration     |
    \\  /    A nd           | Copyright held by original author
     \\/     M anipulation  |
-------------------------------------------------------------------------------
License
    This file uses OpenFOAM and is provided as free software without any warranty

    OpenFOAM is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the
    Free Software Foundation; either version 2 of the License, or (at your
    option) any later version.

    OpenFOAM is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
    FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
    for more details.

    You should have received a copy of the GNU General Public License
    along with OpenFOAM; if not, write to the Free Software Foundation,
    Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

Application
    simpleFoam_MDD

Description
    Steady-state solver for incompressible laminar flow

Authors
    Luca Mangani   HSLU email: luca.mangani@hslu.ch
    Marwan Darwish AUB  email: darwish@aub.edu.lb
    Fadl Moukalled AUB  email: moukalled@aub.edu.lb

\*---------------------------------------------------------------------------*/

#include "fvCFD.H"
#include "singlePhaseTransportModel.H"
#include "turbulenceModel.H"
#include "RASModel.H"
#include "simpleControl.H"
#include "orthogonalSnGrad.H"

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

int main(int argc, char *argv[])
{

#   include "setRootCase.H"
#   include "createTime.H"
#   include "createMesh.H"
#   include "createFields.H"

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

    Info<< "\nStarting time loop\n" << endl;

    //- Main SIMPLE loop

    while (runTime.loop())
    {
        Info<< "Time = " << runTime.timeName() << nl << endl;

        //- storing variable of the previous iteration for implicit and explicit relaxation
        U.storePrevIter();
        mdotf.storePrevIter();

        // Pressure-velocity SIMPLE corrector        
	#include "UEqn.H"

        OFstream os ("ac");
	os << UEqn.A();

	#include "ppEqn.H"

        runTime.write();

        Info<< "ExecutionTime = " << runTime.elapsedCpuTime() << " s"
            << "  ClockTime = " << runTime.elapsedClockTime() << " s"
            << nl << endl;
    }

    Info<< "End\n" << endl;

    return(0);
}


// ************************************************************************* //
