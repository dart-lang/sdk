# Copyright (c) 2019 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Utility functions.
"""

def union(x, overrides):
    """ Creates a new dict with the values from all passed dictionaries

    If dicts contain the same keys, their values are merged if the values are
    dicts. This merging only happens at the top level, not recursively into
    dicts containing dicts.
    Otherwise, the earlier value is overwritten by the value from the
    later override.

    Args:
        x (dict): A dict.
        overrides (list): dicts to merge with x.

    Returns:
        dict: The merged dict.
    """
    z = {}
    z.update(x)
    if type(overrides) == type({}):
        overrides = [overrides]
    for y in overrides or []:
        for k in y.keys():
            v = z.get(k)
            if v and type(v) == type({}):
                v = dict(v, **y[k])
                z[k] = v
            else:
                z[k] = y[k]
    return z
