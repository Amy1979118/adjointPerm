function xr = reorder_incompressible_twophase(xr, xw, G, tf, rock, ...
                                             fluid, varargin)
   opt = struct(...
      'src',   [], ...
      'bc',    [], ...
      'wells', [], ...
      'verbose', false);
   opt = merge_options(opt, varargin{:});
   fn = tempname('.');
   f  = fopen (fn, 'w');
   fprintf(f, [...
   '<?xml version = ''1.0'' encoding = ''ISO-8859-1''?>\n', ...
   '<!-- -->\n', ...
   '<ParameterGroup name="root">\n', ...
   ' <ParameterGroup name="fluid">\n', ...
   '  <ParameterGroup name="Phase0">\n', ...
   '   <Parameter name="Density"   type="double" value="1.0"/>\n', ...
   '   <Parameter name="Viscosity" type="double" value="%f" />\n',...
   '  </ParameterGroup>\n', ...
   '  <ParameterGroup name="Phase1">\n', ...
   '   <Parameter name="Density"   type="double" value="1.0"/>\n', ...
   '   <Parameter name="Viscosity" type="double" value="%f" />\n',...
   '  </ParameterGroup>\n', ...
   ' </ParameterGroup>\n', ...
   ' <ParameterGroup name="transport">\n', ...
   '  <Parameter name="solver_library"               type="string" value="umfpack"/>\n', ...
   '  <Parameter name="number_of_reorder_time_steps" type="int"    value="1"/>      \n', ...
   '  <Parameter name="tolerance"                    type="double" value="1e-6"/>   \n', ...
   '  <Parameter name="max_iterations"               type="int"    value="100"/>    \n', ...
   '  <Parameter name="relaxation"                   type="double" value="0.95"/>   \n', ...
   '  <Parameter name="newton_saturation_guess"      type="double" value="0.15"/>   \n', ...
   ' </ParameterGroup>\n', ...
   '</ParameterGroup>'], fluid.mu);
   fclose(f);
   
   q = computeTransportSourceTerm(xr, xw, G, opt.wells, opt.src, opt.bc);
   pv = poreVolume(G, rock);

   v = xr.faceFlux;
   n = double(G.faces.neighbors);
   i = all(n~=0, 2);
   j = v>0 & i;
   F = sparse(n(j, 2), n(j,1), v(j), G.cells.num, G.cells.num);
   xr.s = matlab_reorder_incompressible(xr.s, tf, full(q), pv, F, fn);
   delete(fn);


end