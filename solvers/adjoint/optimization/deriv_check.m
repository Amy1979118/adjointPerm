%
% function [ ]  = deriv_check( x, hess, usr_par)
%
% Check derivatives using finite differences

function [ ]  = deriv_check( x, hess, usr_par)

[G, S, W, rock, fluid, resSolInit, schedule, controls, objectiveFunction, param, modelFunction] = deal(usr_par{:});

% FORWARD SOLVE
simRes    = runSchedulePerm(resSolInit, G, S, W, rock, fluid, schedule, param, modelFunction, 'VerboseLevel', 0);

% ADJOINT SOLVE
adjRes    = runAdjointPerm(simRes, G, S, W, rock, fluid, schedule, controls, objectiveFunction, param, modelFunction);

% COMPUTE GRADIENT
grad = computeGradientDK(simRes, adjRes, G, S, W, rock, fluid, schedule, controls, objectiveFunction, param);
du   = cell2mat( {grad{:}}');
% du   = du';
    
fprintf(1,' Derivative checks \n')

fprintf(1,' Gradient check using finite differences (FDs)\n')
fprintf(1,' FD step size    <grad,v>     FD approx.   absolute error \n')

load Kreal;
obj    = objectiveFunction(param, G, S, W, rock, fluid, simRes, schedule);
f      = obj.val;
g      = du;
dir    = rand(size(x));
dg     = xprod(g, dir, usr_par);
delta  = 1.e-6;

for d = 1:9
    delta     = delta/10;
    uCur      = x + delta*dir;
    m         = uCur;
    param.m   = m;
    simRes    = runSchedulePerm(resSolInit, G, S, W, rock, fluid, schedule, param, modelFunction, 'VerboseLevel', 0);
    obj       = objectiveFunction(param, G, S, W, rock, fluid, simRes, schedule);
    f1        = obj.val;

    fprintf(1,' %12.6e  %12.6e  %12.6e  %12.6e  \n', ...
        delta, dg, (f1-f)/delta, abs(dg - (f1-f)/delta) )
    
end


if( hess )
    % perform Hessian check
    fprintf(1,'\n Hessian check using finite differences (FDs)\n')
    fprintf(1,' FD step size   absolute error \n')
    g       = du;
    dir     = rand(size(x));
    delta   = 1.e-4;
    usr_par = {G, S, W, rock, fluid, resSolInit, schedule, controls, objectiveFunction, param, modelFunction};
    h       = Hessvec( dir, x, usr_par );
    for d = 1:9
        delta     = delta/10;
        uCur      = x + delta*dir;
        
        m         = uCur;
        param.m   = m;
        simRes    = runSchedulePerm(resSolInit, G, S, W, rock, fluid, schedule, param, modelFunction, 'VerboseLevel', 0);
        adjRes    = runAdjointPerm(simRes, G, S, W, rock, fluid, schedule, controls, objectiveFunction, param, modelFunction);
        grad      = computeGradientDK(simRes, adjRes, G, S, W, rock, fluid, schedule, controls, objectiveFunction, param);
        g1        = cell2mat( {grad{:}}');
        
        err     = xprod(h - (g1-g)/delta, h - (g1-g)/delta, usr_par);
        aaa     = (g1-g)/delta;
        fprintf(1,' %12.6e  %12.6e   \n', delta, err )
    end

    % check selfadjointness of Hessian
    fprintf(1,'\n Check if Hessian is selfadjoint \n')

    uCur      = x + delta*dir;
    m         = uCur;
    param.m   = m;
   
    usr_par = {G, S, W, rock, fluid, resSolInit, schedule, controls, objectiveFunction, param, modelFunction};
    v1      = rand(size(x));
    v2      = rand(size(x));
    h       = Hessvec( v1, x, usr_par );
    prod1   = xprod(h, v2, usr_par);
    h       = Hessvec( v2, x, usr_par );
    prod2   = xprod(h, v1, usr_par);
    fprintf(1,'<H*v1,v2> = %12.6e, <H*v2,v1> =  %12.6e   \n', prod1, prod2 )
    fprintf(1,'| <H*v1,v2> - <H*v2,v1> | =  %12.6e   \n', abs(prod1 - prod2) )

end
fprintf(1,' End of derivative checks \n\n')
