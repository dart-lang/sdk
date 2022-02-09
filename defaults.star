# Copyright (c) 2019 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defaults for properties and dimensions used in main.star.
"""

_PROPERTIES = {"clobber": True}
_DIMENSIONS = {
    "cpu": "x86-64",
    "host_class": "default",
    "os": "Linux",
    "pool": "luci.dart.try",
}
_CACHES = {
    "Mac": [swarming.cache("osx_sdk", name = "osx_sdk")],
}

def _default_dict(defaults, overrides):
    defaults = dict(defaults)
    if overrides:
        defaults.update(overrides)
    return defaults

defaults = struct(
    caches = lambda os: _CACHES.get(os),
    dimensions = lambda dimensions: _default_dict(_DIMENSIONS, dimensions),
    properties = lambda properties: _default_dict(_PROPERTIES, properties),
)
