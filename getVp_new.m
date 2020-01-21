function VP = getVp_new(ls)

points = zeros(size(ls, 1), 3);
for i=1:size(ls,1)
    points(i,:) = [x(i) y(i) 1];
end

nr_couples = uint8(size(ls,1)/2);
vertical_lines = zeros(nr_couples, 3);
mean_pt = zeros(nr_couples,3);

for i=1:2:nr_couples*2
    indx_couple = uint8(i/2);
    mean_pt(indx_couple, :) = (points(i,:)+points(i+1,:))/2;
    line_coeff           = cross(points(i,:),points(i+1,:));
    line_coeff           = line_coeff/line_coeff(3);
    vertical_lines(indx_couple,:) = line_coeff;
end

% determine line intersection
vanishing_points = zeros(uint8(nr_couples*(nr_couples-1)/2),3);
count=1;
for i=1:nr_couples
    for j=i+1:nr_couples
        vanishing_point_i_j = cross(vertical_lines(i,:), vertical_lines(j,:));
        vanishing_point_i_j = vanishing_point_i_j/ vanishing_point_i_j(3);
        vanishing_points(count,:) = vanishing_point_i_j;
        count = count+1;
    end
end

vanishing_point_start = mean(vanishing_points);

fun = @(y)cumulate_cos_err(y, mean_pt, vertical_lines);
vanishing_point = lsqnonlin(fun,vanishing_point_start(1:2));
VP = [vanishing_point(1), vanishing_point(2), 1];

end
