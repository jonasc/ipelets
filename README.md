# Ipelets -- small scripts for the editor Ipe [1]

The available scripts are currently:

-   `remove-empty-layers.lua`:
    Remove all layers from the current page which do not have any objects on them.
    Locked layers are not removed.
    
    If a view had a removed layer as the active layer, the next layer above with objects on it is made the active layer.
    If no layer remains above, then the next layer below is made the active layer.
    The script will always leave at least one layer, even if all are empty.

    It is possible to undo the action:
    Deleted layers are created and the order of all layers is restored.
    The views which had a deleted layer as their active layer will have the new layer made active.
    It is restored on which views the layer was active.

[1] https://ipe.otfried.org/