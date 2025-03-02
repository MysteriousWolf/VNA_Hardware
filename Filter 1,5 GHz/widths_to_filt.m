function [filter, pcb, lengths, widths, L_tot, W_tot] = widths_to_filt(lengths, section_widths, metal, substrate)
    %GEN_FILT_POLY Generates a filter based on parameters
    %   No further explanation

    % In m
    widths = zeros(size(lengths), 'like', lengths);
    
    for i = 1:length(lengths)
        if i == 1 || i == length(lengths)
            widths(i) = section_widths(1);
        elseif mod(i, 2) == 0 % starts first - capacitive
            widths(i) = section_widths(2);
        else
            widths(i) = section_widths(3);
        end
    end
    
    L_tot = sum(lengths);
    W_tot = max(section_widths) + 10e-3; % 5 mm on each side 
    
    current_center = 0;
    for i = 1:length(lengths)
        current_center = current_center + lengths(i)/2;
        if i == 1
            filter = traceRectangular(Length = lengths(i), Width = widths(i), Center = [current_center 0]);
        else
            filter = filter + traceRectangular(Length = lengths(i), Width = widths(i), Center = [current_center 0]);
        end
        current_center = current_center + lengths(i)/2;
    end

    gnd = traceRectangular(Length = L_tot, Width = W_tot, Center = [L_tot/2,0]);
    
    pcb = pcbComponent(Conductor=metal);
    pcb.BoardShape = gnd;
    pcb.BoardThickness = 0.76e-3;
    pcb.Layers ={filter,substrate,gnd};
    pcb.FeedDiameter = section_widths(1)/2;
    pcb.FeedLocations = [0 0 1 3;L_tot 0 1 3];
end

