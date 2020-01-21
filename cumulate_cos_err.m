function err=cumulate_cos_err(y,means_pts,line_coeff)
    y = [y(1), y(2), 1];
    err = zeros(size(means_pts,1),1);
    for i=1:size(means_pts,1)
        expected_line = cross(y,means_pts(i,:));
        expected_line = expected_line/expected_line(3)+0.1;
        cos_line_expected_vs_real = dot(expected_line, line_coeff(i,:));
        cos_line_expected_vs_real = cos_line_expected_vs_real/(dot(expected_line, expected_line)+0.1);
        cos_line_expected_vs_real = cos_line_expected_vs_real/(dot(line_coeff(i,:), line_coeff(i,:))+0.1);
        err(i) = cos_line_expected_vs_real;
    end
end


