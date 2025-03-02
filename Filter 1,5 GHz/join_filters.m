function [filter_sum, pcb_sum, L_tot, W_tot] = join_filters(filt1, len1, wid1, filt2, len2, wid2, wdt, met, sub)
%JOIN_FILTERS Adds two filters together
%   Appends filt1 to filt2 (trace not PCB) with offset of len2. Takes the
%   max width and the sum of lengths as the total filter size and makes a
%   PCB out of it. Met and Sub are metal/conductor and substrate materials.
%   Wdt is the array of filter widths (system, low_imp, high_imp)

ignored = translate(filt2, [len1 0 0]); % needs to write to something to 
                                        % avoid plotting
filter_sum = filt1 + filt2;
ignored = translate(filt2, [-len1 0 0]);

L_tot = len1 + len2;
W_tot = max(wid1, wid2);

gnd = traceRectangular(Length = L_tot, Width = W_tot, Center = [L_tot/2,0]);

pcb = pcbComponent(Conductor=met);
pcb.BoardShape = gnd;
pcb.BoardThickness = 0.76e-3;
pcb.Layers ={filter_sum,sub,gnd};
pcb.FeedDiameter = wdt(1)/2;
pcb.FeedLocations = [0 0 1 3;L_tot 0 1 3];

pcb_sum = pcb;
end

