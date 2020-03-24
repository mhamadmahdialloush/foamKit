//SIMPLE correction 

volScalarField DU = 1.0/UEqn.A();
surfaceScalarField DUf("DUf",linearInterpolate(DU));


//- Grabbing necessary data for Rhie-Chow interplation

const surfaceVectorField ed = mesh.delta()()/mag(mesh.delta()());
Foam::fv::orthogonalSnGrad<scalar> faceGradient(mesh);

surfaceVectorField gradp_avg_f = linearInterpolate(fvc::grad(p));
surfaceVectorField gradp_f = gradp_avg_f - (gradp_avg_f & ed)*ed + (faceGradient.snGrad(p))*ed;

surfaceVectorField U_avg_f = linearInterpolate(U);

// Rhie-Chow interplation
mdotf = (U_avg_f & mesh.Sf()) - ((DUf*(gradp_f - gradp_avg_f)) & mesh.Sf());

//- resetting pressure correction
pp.internalField() = scalar(0.0);
pp.correctBoundaryConditions();

//- Assembling
fvScalarMatrix ppEqn
(
    - fvm::laplacian(DUf, pp, "laplacian(pDiff,pp)")
    + fvc::div(mdotf)
);

ppEqn.setReference(pRefCell, pRefValue);

//- Solution
ppEqn.solve();

//- update of the fluxes based on the flux correction
mdotf += ppEqn.flux();

//- update of the variable pressure and velocity based on the pressure correction solution and pressure correction relaxation factor
scalar URFPP = mesh.equationRelaxationFactor("pp");
p += URFPP*pp;
p.correctBoundaryConditions();

U -= fvc::grad(pp)*DU;
U.correctBoundaryConditions();


