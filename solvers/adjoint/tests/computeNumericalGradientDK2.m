function numGrad = computeNumericalGradientDK2(simRes, G, S, W, rock, fluid, schedule, controls, objectiveFunction)
% compute numerical gradient

epsilon = 1e-8;
numSteps  = numel( schedule);
obj       = objectiveFunction(G, S, W, rock, fluid, simRes);
valInit   = obj.val;

nx = G.cartDims(1); 
ny = G.cartDims(2); 
nz = G.cartDims(3);
gd = nx * ny* nz;

m        = ones(nx,ny);
m        = reshape(m, [1,G.cells.num]);
uInit    = repmat(m,numSteps,1);
uInit    = uInit(:);
dimU     = length( uInit );


uInit = reshape(uInit,gd,numSteps);

for k = 1:dimU
    e_k     = zeros(dimU, 1); e_k(k) = 1;
    
    
   % update permeability -> update well & assemblemimetic !
    j         = ceil(k/gd);
    Un        = uInit(:,j);
    e_k       = reshape(e_k,gd,numSteps);
    e_k       = e_k(:,j);
    uCur      = Un + epsilon*e_k;
    m         = uCur;
    load Kreal;
    Kreal     = reshape(Kreal, [G.cells.num,1]);
    rock.perm = (Kreal ./ m)*100*milli*darcy;  
    modelHMSmall2
    
    % forward run
    simRes = runSchedule(resSolInit, G, S, W, rock, fluid, schedule, 'VerboseLevel', 0);
    
    % evaluate OBJ. FUNCTION
    obj       = objectiveFunction(G, S, W, rock, fluid, simRes);
    values(k) = obj.val;
end


numGrad = reshape((values' - valInit)/epsilon, 1, numSteps*gd);

  