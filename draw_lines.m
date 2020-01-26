function draw_lines(lines,img)
%PLOT_LINES Plot lines over the image
%   lines is a vector of structs made of point1, point2

% plot lines
figure, imshow(img), hold on
    for k = 1:length(lines)
        if (k ~= 108 && k ~= 132 && k ~= 11 && k ~= 52 && k ~= 109 && k ~= 126 && k ~= 111 && k ~= 22 && k ~= 58 && k ~= 88 && k ~= 40 && k ~= 68 && k ~= 73 && k ~= 130&& k ~=121 && k ~=7 && k ~=65 && k ~=117 && k ~= 95 && k ~= 124 && k ~= 100 && k ~= 123 && k ~= 127 && k ~= 125 && k ~= 110 && k ~= 119 && k ~= 92 && k ~= 35 && k ~= 31 && k ~= 87 && k ~= 57)
           xy = [lines(k).point1; lines(k).point2];
           plot(xy(:,1),xy(:,2),'LineWidth',1.5,'Color','green');
           text(xy(1,1),xy(1,2), num2str(k), 'Color', 'red')
        end 
    end
end

