function [obj] = PermMatch(param, G, S, W, rock, fluid, simRes, schedule, controls, varargin)
% simpleNPV - simple net-present-value function - no discount factor
%
% SYNOPSIS:
%   obj = (G, S, W, rock, fluid, simRes, schedule, controls, varargin)
%
% DESCRIPTION:
%   Computes value of objective function for given simulation, and partial
%   derivatives of variables if varargin > 6
% PARAMETERS:
%   simRes      -
%
% RETURNS:
%   obj         - structure with fields
%        val    - value of objective function
%        
%   
%
%
% SEE ALSO:
%  
%-----------------------------------------------

computePartials  = (nargin > 7);
numSteps = numel(simRes);
val      = 0;
partials = repmat( struct('v', [], 'p', [], 'pi', [], 's', [], 'u', []), [numSteps 1] );

% load data from reference model, simRes_ref
load simResSmallRef;
load Kmodel;

m = param.m;

for step = 2 : numSteps
    % model
    resSol  = simRes(step).resSol;
    wellSol = simRes(step).wellSol;
    
    % measurement/reference
    resSolref  = simRes_refSmall(step).resSol;
    wellSolref = simRes_refSmall(step).wellSol;
    
    % model
    [wellRates, rateSigns] = getRates(W, wellSol);
    wellCells = vertcat( W.cells );
    wellSats  = resSol.s( wellCells ); 

    % measurement/reference
    [wellRates_ref, rateSigns_ref] = getRates(W, wellSolref);

    % model
    f_w_all   = fluid.fw(resSol);
    f_w       = f_w_all(wellCells);
    f_o       = 1 - f_w;
    injInx    = (rateSigns > 0);
    prodInx   = (rateSigns < 0);
    
    % measurement/reference
    f_w_all_ref   = fluid.fw(resSolref);
    f_w_ref       = f_w_all_ref(wellCells);
    f_o_ref       = 1 - f_w_ref;
    injInx_ref    = (rateSigns_ref > 0);
    prodInx_ref   = (rateSigns_ref < 0);
    
    % model - liquid rate at producer wells
%     g_m     = [ f_w( injInx ); f_w( prodInx )];
    g_m     = f_w( prodInx );
    
    % measurement - liquid rate at producer wells
%     d_obs   = [ f_w( injInx_ref ); f_w_ref( prodInx_ref ) ];
    d_obs   = f_w_ref( prodInx_ref );
   
    misMatch= g_m - d_obs;
    numDiff = size(misMatch,1);
    covD    = eye(numDiff,numDiff);
    mismatchTerm = misMatch'*covD*misMatch;
    
    % Objective value:
    wm  = 0;
    val = val + wm*mismatchTerm;
    
    % regularization term added only at final time
    if step == numSteps
        % regularization term
        curPerm  = ( param.K ./ m );
        K        = K(:);
        regTerm  = K - curPerm ;
        numReg   = size(regTerm,1);
        covM     = eye(numReg,numReg);
        regularTerm  = regTerm'*covM*regTerm;
        
        wr  = 1;
        val = val + wr*regularTerm;
    end
    
    if computePartials        
        numC  = G.cells.num;
        numCF = size(G.cellFaces, 1);
        numF  = G.faces.num;
        numW  = numel(W);
        
        qw_d               = zeros(1,numW);
        partials(step).q_w = qw_d;
        
        
        partials(step).v   = zeros(1, numCF);
        dp                 = zeros(1, numC);
        partials(step).p   = dp;
        partials(step).pi  = zeros(1, numF);
        
        if step == numSteps
            partials(step).u   = (2*wr*regTerm ./ (m.^2))';
        else
            partials(step).u   = zeros(1, numC);
        end
        
        Dfw_all                    = fluid.dfw(resSol);
        Df_w                       = Dfw_all(wellCells(prodInx));
        ds                         = zeros(1, numC);
        ds( wellCells(prodInx) )   = -2*wm*Df_w .* misMatch ;
%         discrepancy                = -2*wm*misMatch .* Df_w;
%         ds( wellCells(injInx) )    = discrepancy(1);
%         ds( wellCells(prodInx) )   = discrepancy(end);
        partials(step).s           = ds;
        
    end
end

obj.val = val;
if computePartials, obj.partials = partials; end

