
function _create_group(h5::H5DataStore, name)
    if haskey(h5, name)
        g = h5[name]
    else
        g = create_group(h5, name)
    end
    return g
end
