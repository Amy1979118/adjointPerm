function LS = ...
   setupMixedBO(resSol, wellSol, G, rock, S, fluid, p0, dt, LS)

%if LS.solved==false, return; end 

[B, LS.P, f, g, h, LS.mobt] = ...
   hybLinSys(resSol, G, S, rock, fluid, p0, dt, LS.bc, LS.src);
[Bw, fw, gw, hw] = ...
   hybLinWellSys(resSol, wellSol, G, LS.wells, fluid);

%--------------------------------------------------------------------------
LS.B = blkdiag(B, Bw);
hN  = [h(LS.fluxFacesR); hw(LS.fluxFacesW)];
f = [f; fw];
g = g + gw;

%------ unpack solution ---------------------------------------------------
cellFlux = [resSol.cellFlux; vertcat( wellSol.flux )];
p = resSol.cellPressure;
lam = [resSol.facePressure; vertcat( wellSol.pressure )];
lamN = lam( [LS.fluxFacesR; LS.fluxFacesW] );

%------ iterate on residual -----------------------------------------------
f  = f - LS.B*cellFlux + LS.C*p - LS.DN*lamN;
%!!!!!!!! Note that this residual only makes sense in a mixed setting!!!!!
% project f (average over inner faces)
LS.f = LS.Do * ( (LS.Do'*LS.Do)\(LS.Do'*f) );
LS.g  = g - LS.C'*cellFlux + LS.P*p;
LS.hN = hN - LS.DN'*cellFlux;
LS.solved = false;