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
_NO_ANDROID = {"custom_vars": {"download_android_deps": False}}
_CHROME = {"custom_vars": {"download_chrome": True}}
_FIREFOX = {"custom_vars": {"download_firefox": True}}
_JS_ENGINES = {"custom_vars": {"checkout_javascript_engines": True}}
_SLOW_SHARDS = {"shard_timeout": (90 * time.minute) // time.second}
_PINNED_XCODE = {"$depot_tools/osx_sdk": {"sdk_version": "12d4e"}}

_ARM64 = {"cpu": "arm64"}
_MAC = {"os": "Mac"}
_LINUX = {"os": "Linux"}
_WINDOWS = {"os": "Windows"}

def _union(x, overrides):
    """ Creates a new dict with the values from all passed dictionaries

    If dicts contain the same keys, their values are assumed to be dicts
    and merged. Values in dicts later in overrides' sub-dicts will overwrite
    values in earlier sub-dicts.

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

defaults = struct(
    caches = lambda os: _CACHES.get(os),
    dimensions = lambda overrides: _union(_DIMENSIONS, overrides),
    properties = lambda overrides: _union(_PROPERTIES, overrides),
)

# Dimensions

arm64 = _ARM64
linux = _LINUX
mac = _MAC
windows = _WINDOWS

# Properties

chrome = _CHROME
firefox = _FIREFOX
js_engines = _JS_ENGINES
no_android = _NO_ANDROID
slow_shards = _SLOW_SHARDS
pinned_xcode = _PINNED_XCODE
