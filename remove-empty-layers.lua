label = "Remove empty layers"

about = [[ An Ipelet to remove all empty layers from the current page. ]]

function run(model)
    local t = {
        label = "remove empty layers",
        model = model
    }
    -- store some information about the current situation to be able to undo the removal
    t.views, t.layers, t.visibility = collect_data(model:page())
    t.page = model.pno
    t.redo = function(t, doc)
        redo(t.model, t.views, t.layers)
    end
    t.undo = function(t, doc)
        undo(t.model, t.views, t.layers, t.visibility, t.page)
    end
    model:register(t)
end

-- Collect data needed to undo the removal
function collect_data(p)
    local views = {}
    local layers = {}
    local visibility = {}
    -- For each view, what is the active layer?
    for v = 1, p:countViews() do
        views[v] = p:active(v)
    end
    -- Store the correct order of layers and on which views the layers are visible
    for i, l in pairs(p:layers()) do
        layers[i] = l
        visibility[l] = {}
        for v = 1, p:countViews() do
            visibility[l][v] = p:visible(v, l)
        end
    end
    return views, layers, visibility
end

function redo(model, views, layers)
    local p = model:page()

    -- 1. Remove all layers that are not locked, empty and not the only layer
    local empty = true
    local previous = nil
    for i, l in pairs(layers) do
        -- Abort if only one layer left
        if p:countLayers() == 1 then
            break
        end
        -- Ignore locked layers
        if p:isLocked(l) then
            previous = l
        else
            -- Check if there is an object on this layer
            empty = true
            for _, _, _, layer in p:objects() do
                if layer == l then
                    empty = false
                    break
                end
            end
            -- Ignore non-empty layers
            if not empty then
                previous = l
            else
                -- Actually remove the layer
                p:removeLayer(l)
                -- If the layer was the active one in a view set it to the previous layer
                if previous ~= nil then
                    for v, active in pairs(views) do
                        if active == l then
                            p:setActive(v, previous)
                        end
                    end
                end
            end
        end
    end

    -- 2. Set active layer of all views which had their active layer removed without replacement to the first remaining layer
    local first = p:layers()[1]
    local found = false
    for v = 1, p:countViews() do
        found = false
        -- Go through all remaining layers and check if the active layer of the view is still present
        for i, l in pairs(p:layers()) do
            if p:active(v) == l then
                found = true
                break
            end
        end
        if not found then
            p:setActive(v, first)
        end
    end
end

function undo(model, views, layers, visiblity, page)
    local p = model.doc[page]
    local found = false

    -- 1. Create all layers that were deleted and bring into correct order
    for i, l in pairs(layers) do
        found = false
        for _, pl in pairs(p:layers()) do
            if pl == l then
                found = true
                break
            end
        end
        -- Add, if it does not exist
        if not found then
            p:addLayer(l)
        end
        -- Bring to correct position
        p:moveLayer(l, i)

        -- TODO: Add additional information
        -- - locked: not necessary as we don't delete locked layers
        -- - layerData
        -- - snapping: whatever this is?!
        -- - layer matrices?
    end

    -- 2. Make the layer active on the views that had them active
    for v, l in pairs(views) do
        p:setActive(v, l)
    end

    -- 3. Make layer visible on the correct views
    for l, t in pairs(visiblity) do
        for v, visible in ipairs(t) do
            p:setVisible(v, l, visible)
        end
    end
end
