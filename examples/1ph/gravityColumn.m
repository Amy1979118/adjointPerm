%% My First Flow Solver: Gravity Column
% In this example, we introduce the mimetic pressure solver and use it to
% solve the single-phase pressure equation
%
% $$\nabla\cdot v = q, \qquad
%    v=\textbf{--}\frac{K}{\mu} \bigl[\nabla p+\rho g\nabla z\bigr],$$
%
% within the domain [0,1]x[0,1]x[0,30] using a Cartesian grid with
% homogeneous isotropic permeability of 100 mD. The fluid has density 1000
% kg/m^3 and viscosity 1 cP and the pressure is 100 bar at the top of the
% structure.
%
% The purpose of the example is to show the basic steps for setting up,
% solving, and visualizing a simple flow problem. More details on the grid
% structure, the structure used to hold the solutions, and so on, are given
% in the <simpleBC.html basic flow-solver tutorial>.

%% Define the model
gravity reset on
G          = cartGrid([2, 2, 30], [1, 1, 30]);
G          = computeGeometry(G);
rock.perm  = repmat(0.1*darcy(), [G.cells.num, 1]);
fluid      = initSingleFluid();
bc  = pside([], G, 'TOP', 1:G.cartDims(1), 1:G.cartDims(2), 100.*barsa());

%% Assemble and solve the linear system
S   = computeMimeticIP(G, rock);
sol = solveIncompFlow(initResSol(G , 0.0), initWellSol([], 0.0), ...
                      G, S, fluid,'bc', bc);

%% Plot the face pressures
newplot;
plotFaces(G, 1:G.faces.num, sol.facePressure ./ barsa());
set(gca, 'ZDir', 'reverse'), title('Pressure [bar]')
view(3), colorbar

%%
% #COPYRIGHT_EXAMPLE#

%%
% <html>
% <font size="-1">
%   Last time modified:
%   $Id: gravityColumn.m 2089 2009-04-23 10:43:52Z bska $
% </font>
% </html>
displayEndOfDemoMessage(mfilename)
