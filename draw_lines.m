function draw_lines(lines,img)
%PLOT_LINES Plot lines over the image
%   lines is a vector of structs made of point1, point2

% plot lines
figure, imshow(img), hold on
    for k = 1:length(lines)
       xy = [lines(k).point1; lines(k).point2];
       plot(xy(:,1),xy(:,2),'LineWidth',1.5,'Color','green');
       text(xy(1,1),xy(1,2), num2str(k), 'Color', 'red')
    end
end

