% optimization_driver for Five water-spot case
%
% Synopsis
%   just type optimization_driver
%
% Description
%   Second order adjoint optimization using oil reservoir model
%   Newton conjugate method, will be explored other methods
%   such as: Lancos, Truncated Newton, preferable methods that utilize
%   distributed/parallel computing
% 
% Inputs ([]s are optional)
%   none
%  
%
% Outputs ([]s are optional)
%   none
%   
%
% Examples
%   type : optimization_driver
%
% See also
%   computeNumericalGradient (to check 1st gradient)
%
% Requirements
%   SINTEF Oil reservoir toolbox
%   can be downloaded from
%   http://www.sintef.no/Projectweb/GeoScale/Simulators/MRST/
%
% References
%   based on Matthias Heinkenschloss code
%   http://www.caam.rice.edu/~heinken/software/matlab_impl_constr/
%
% Authors
%   Eka Suwartadi (suwartad@itk.ntnu.no)
%
% License
%   The program is free for non-commercial academic use. Please 
%   contact the authors if you are interested in using the software
%   for commercial purposes. The software must not modified or
%   re-distributed without prior permission of the authors.
%
% Changes
%   03.05.2009  First development
%   ...      

clear all

set(0, 'defaultaxesfontsize',18,'defaultaxeslinewidth',1.2,...
       'defaultlinelinewidth',0.8,'defaultpatchlinewidth',0.8,...
       'defaulttextfontsize',18);
   
addpath ../optimsecond

 
initSimpleModel

% % perform derivative checks
% usr_par = {G, S, W, rock, fluid, resSolInit, schedule, controls, objectiveFunction};
% Uinit = [controls.well.values]';
% Uinit = Uinit(:);
% deriv_check( Uinit, 1, usr_par);


% Solve the optimal control problem using Newton's method
fprintf(1,'\n\n Solve the optimal control problem using')

% set initial iterate
% u = zeros((nx+1)*(nt+1),1);
usr_par = {G, S, W, rock, fluid, resSolInit, schedule, controls, objectiveFunction};
Uinit = [controls.well.values]';
U     = Uinit(:);

optimizer = 1;

if( optimizer == 1)
    fprintf(1,' Newton''s method\n')
    % set options for Newton CG method
    options.iprint = 1; % print level, default = 0
    options.maxit  = 20; %  maximum number of iterations, default = 100
    options.gtol   = 1.e-8; % gradient stopping tolerance, default = 1.e-8
    options.stol   = 1.e-8; % stepsize stopping tolerance, default = 1.e-8
    
    tic;
    [ U, iter, iflag ]  = newton_cg( U, options, usr_par);
    t = toc; fprintf(1,' CPU time = %9.3f sec,   \n', t);
    fprintf(1,' Newton''s method returned after %d iterations with flag %d \n', iter,iflag )

elseif( optimizer == 2)
    fprintf(1,' limited memory BFGS method\n')
    % set options for limited memory BFGS method
    options.iprint = 1; % print level, default = 0
    options.gtol   = 1.e-8; % gradient stopping tolerance, default = 1.e-8
    options.stol   = 1.e-8; % stepsize stopping tolerance, default = 1.e-8
    options.maxit  = 50; % Maximum number of iterations, default 100
    options.L      = 20;  % LBFGS storage limit, default 20
    
    tic;
    [ U, iter, iflag ]  = lbfgs( U, options, usr_par);
    t = toc; fprintf(1,' CPU time = %9.3f sec,   \n', t);
    fprintf(1,' LBFGS returned after %d iterations with flag %d \n', iter,iflag )

else
    fprintf(1,' optimizer is %d; must be 1, 2 \n', optimizer)
end 





