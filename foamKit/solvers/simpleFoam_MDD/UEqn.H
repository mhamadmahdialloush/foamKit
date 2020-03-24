//- Solve the Momentum equation

//- Assembling
fvVectorMatrix UEqn
(
        fvm::ddt(U)
      + fvm::div(mdotf, U)
      + turbulence->divDevReff(U)
      + fvm::SuSp(-fvc::div(mdotf),U)
);

//- Implicit relaxation
UEqn.relax();

//- Solution of the linear solver adding the pressure gradient as source term
solve
(
    UEqn == -fvc::grad(p)
);



