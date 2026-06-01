function proj_out = replace_proj_field(proj_out, proj_in, field_name)

dims = size(proj_out);

for i1 = 1:dims(1)
    for i2 = 1:dims(2)
        for i3 = 1:dims(3)
            for i4 = 1:dims(4)

                proj_out{i1,i2,i3,i4}.(field_name) = ...
                    proj_in{i1,i2,i3,i4}.(field_name);

            end
        end
    end
end

end