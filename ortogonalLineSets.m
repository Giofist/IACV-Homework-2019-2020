function pairs = ortogonalLineSets(l1,l2)

pairs = [];
for ii = 1:size(l1,2)
    for jj = 1:size(l2,2)
        pairs = [pairs l1(:,ii) l2(:,jj)];    
    end
end
