function [outfname, rows, cols] = miffilegen6bit(infile, outfname, numrows, numcols)

img = imread(infile); % Reads as uint8, values 0-255

imgresized = imresize(img, [numrows numcols]); % Still uint8, 0-255

[rows, cols, ~] = size(imgresized);

% --- Displaying a representation of the 6-bit image ---
% To visualize what the 6-bit image will look like, we can create it first.
% Each channel (R, G, B) will be 2-bit (0-3).
img_6bit_display = zeros(rows, cols, 3, 'uint8'); % Prepare for display

for r_idx = 1:rows
    for c_idx = 1:cols
        % Quantize each 8-bit channel to 2-bit (0-3)
        r_2bit = floor(double(imgresized(r_idx,c_idx,1)) / 64);
        g_2bit = floor(double(imgresized(r_idx,c_idx,2)) / 64);
        b_2bit = floor(double(imgresized(r_idx,c_idx,3)) / 64);

        % Clamp values to be strictly 0-3 in case of any floating point inaccuracies
        % (though floor should handle this for positive inputs from imread)
        r_2bit = min(max(r_2bit, 0), 3);
        g_2bit = min(max(g_2bit, 0), 3);
        b_2bit = min(max(b_2bit, 0), 3);

        % For display, scale these 2-bit values back to an 8-bit range
        % to make them visible with imshow.
        % 0 -> 0, 1 -> 85, 2 -> 170, 3 -> 255 (approximately)
        img_6bit_display(r_idx,c_idx,1) = uint8(r_2bit * (255/3));
        img_6bit_display(r_idx,c_idx,2) = uint8(g_2bit * (255/3));
        img_6bit_display(r_idx,c_idx,3) = uint8(b_2bit * (255/3));
    end
end
imshow(img_6bit_display);
title('6-bit Color Representation (Scaled for Display)');
% --- End display section ---


fid = fopen(outfname,'w');

fprintf(fid,'-- %3ux%3u 6bit image color values\n\n',rows,cols); % Changed from 12bit
fprintf(fid,'WIDTH = 6;\n');                                   % Changed from 12
fprintf(fid,'DEPTH = %4u;\n\n',rows*cols);
fprintf(fid,'ADDRESS_RADIX = UNS;\n');
fprintf(fid,'DATA_RADIX = UNS;\n\n');
fprintf(fid,'CONTENT BEGIN\n');

count = 0;
for r = 1:rows
    for c = 1:cols
        % Quantize each 8-bit channel from imgresized (0-255) to 2-bit (0-3)
        % R_orig = double(imgresized(r,c,1)); % value 0-255
        % G_orig = double(imgresized(r,c,2)); % value 0-255
        % B_orig = double(imgresized(r,c,3)); % value 0-255

        % red_2bit will be 0, 1, 2, or 3
        red_2bit   = floor(double(imgresized(r,c,1)) / 64);
        green_2bit = floor(double(imgresized(r,c,2)) / 64);
        blue_2bit  = floor(double(imgresized(r,c,3)) / 64);

        % Ensure values are strictly within the 0-3 range if there's any doubt
        % (floor on positive numbers from 0-255 divided by 64 should be fine)
        red_2bit   = min(max(red_2bit, 0), 3);
        green_2bit = min(max(green_2bit, 0), 3);
        blue_2bit  = min(max(blue_2bit, 0), 3);

        % New 6-bit color packing (2 bits per component: RR GG BB)
        % R component: bits 5-4 (most significant 2 bits of the 6)
        % G component: bits 3-2
        % B component: bits 1-0 (least significant 2 bits of the 6)
        % Example: R=3 (11), G=2 (10), B=1 (01) -> 111001
        color = red_2bit*(2^4) + green_2bit*(2^2) + blue_2bit*(2^0);
        % color = red_2bit*16  + green_2bit*4   + blue_2bit*1;
        % Max value: 3*16 + 3*4 + 3*1 = 48 + 12 + 3 = 63 (which is 2^6 - 1)

        fprintf(fid,'%4u : %4u;\n',count, color);
        count = count + 1;
    end
end
fprintf(fid,'END;');
fclose(fid);

end