function [flux, press, lam, varargout] = schurComplementSymm(BI, C, D, ...
                                                              f, g, h, ...
                                                             varargin)
%Solve symmetric system of linear eqns using Schur Complement analysis.
%
% SYNOPSIS:
%   [flux, press, lam]    = schurComplementSymm(BI, C, D, f, g, h)
%   [flux, press, lam]    = schurComplementSymm(BI, C, D, f, g, h, ...
%                                               'pn', pv, ...)
%   [flux, press, lam, S] = schurComplementSymm(...)
%
% DESCRIPTION:
%   Solves the symmetric, hybrid (block) system of linear equations
%
%       [  B   C   D  ] [  v ]     [ f ]
%       [  C'  0   0  ] [ -p ]  =  [ g ]
%       [  D'  0   0  ] [ cp ]     [ h ]
%
%   with respect to the half-face (half-contact) flux 'v', the cell
%   pressure 'p', and the face (contact) pressure 'cp'.  The system is
%   solved using a Schur complement reduction to a symmetric system of
%   linear equations
%
%        S cp = R          (*)
%
%   from which the contact pressure 'cp' is recovered.  Then, using back
%   substitution, the cell pressure and half-contact fluxes are
%   recovered.
%
%   Note, however, that the function assumes that any faces having
%   prescribed pressure values (such as Dirichlet boundary condtions or
%   wells constrained by BHP targets) have already been eliminated from
%   the blocks 'D' and 'h'.
%
% PARAMETERS:
%   BI      - Inverse of the matrix B in the block system.  Assumed SPD.
%   C       - Block 'C' of the block system.
%   D       - Block 'D' of the block system.
%   f       - Block 'f' of the block system right hand side.
%   g       - Block 'g' of the block system right hand side.
%   h       - Block 'h' of the block system right hand side.
%   'pn'/pv - List of 'key'/value pairs defining optional parameters.  The
%             supported options are:
%               Regularize -- Whether or not to enforce p(1)==0 (i.e., set
%                             pressure zero level) which may be useful when
%                             solving pure Neumann problems.
%                             Logicial.  Default value = FALSE.
%               LinSolve   -- Function handle to a solver for the system
%                             (*) above.  Assumed to support the syntax
%
%                                    x = LinSolve(A, b)
%
%                             to solve a system Ax=b of linear equations.
%                             Default value: LinSolve = @mldivide
%                             (backslash).
%
% RETURNS:
%   flux  - The half-contact fluxes 'v'.
%   press - The cell pressure 'p'.
%   lam   - The contact pressure 'cp'.
%   S     - Schur complement reduced system matrix used in recovering
%           contact pressures.
%           OPTIONAL.  Only returned if specifically requested.
%
% SEE ALSO:
%   tpfSymm, mixedSymm, solveIncompFlow, solveIncompFlowMS.

%{
#COPYRIGHT#
%}

% $Id: schurComplementSymm.m 2101 2009-04-29 09:41:22Z bska $

opt = struct('Regularize', false, 'LinSolve', @mldivide);
opt = merge_options(opt, varargin{:});

regularize = opt.Regularize;

%--------------------------------------------------------------------------
% Schur complement analysis to reduce to SPD system for contact pressure --
%
ncell = numel(g);               % Number of cells in model

BIDf   = BI * [D, f];
CtBIDf = C' * BIDf;
DtBIDf = D' * BIDf;

M = CtBIDf(:, 1:end-1);         % == C' * inv(B) * D
S = DtBIDf(:, 1:end-1);         % == D' * inv(B) * D

g = g - CtBIDf(:, end);         % == g - C'*inv(B)*f
h = h - DtBIDf(:, end);         % == h - D'*inv(B)*f

L = diag(C.' * BI * C);
if regularize, L(1) = 2 * L(1); end

L      = spdiags(L, 0, ncell, ncell);
LIMg   = L  \ [M, g];           % use MLDIVIDE for improved accuracy
MtLIMg = M' * LIMg;

S = S - MtLIMg(:, 1:end-1);     % == S - M.'*inv(L)*M
h = MtLIMg(:,end) - h;          % == M.'*inv(L)*g - h

%--------------------------------------------------------------------------
% Solve Schur system to recover unknown contact pressures -----------------
%   (D.'*BI*D - M.'*inv(L)*M) cp = right hand side
%
lam   = opt.LinSolve(S, h);

%--------------------------------------------------------------------------
% Recover cell pressure from reduced (diagonal) system --------------------
%   L p = g + M*lam
%
press = LIMg(:, end) + LIMg(:, 1:end-1)*lam;

if issparse(press),
   % This happens whenever NUMEL(lam)==1
   press = full(press);
end

%--------------------------------------------------------------------------
% Recover half-contact fluxes from reduced system -------------------------
%   B v = f + C*p - D*lam
%
flux  = BIDf(:, end) - BIDf(:, 1:end-1)*lam + BI*C*press;

if nargout > 3, varargout{1} = S; end
