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
    "os": "Ubuntu-20",
    "pool": "luci.dart.try",
}
_CACHES = {
    "Mac": [swarming.cache("osx_sdk", name = "osx_sdk", wait_for_warm_cache = time.minute)],
}

# Swarming has an implicit cache named builder and defining it explicitly makes
# the wait_for_warm_cache field default to zero.
_NO_CACHES = [swarming.cache("builder")]
_NO_ANDROID = {"custom_vars": {"download_android_deps": False}}
_CHROME = {"custom_vars": {"download_chrome": True}}
_EMSCRIPTEN = {"custom_vars": {"download_emscripten": True}}
_FIREFOX = {"custom_vars": {"download_firefox": True}}
_JS_ENGINES = {"custom_vars": {"checkout_javascript_engines": True}}
_SLOW_SHARDS = {"shard_timeout": (90 * time.minute) // time.second}

_ARM64 = {"cpu": "arm64"}
_MAC = {"os": "Mac"}
_FOCAL = {"os": "Ubuntu-20"}
_WINDOWS10 = {"os": "Windows-10"}
_WINDOWS11 = {"os": "Windows-11"}

_EXPERIMENTAL = {"host_class": "experimental"}

def _union(x, overrides):
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

defaults = struct(
    caches = lambda os: _CACHES.get(os),
    dimensions = lambda overrides: _union(_DIMENSIONS, overrides),
    properties = lambda overrides: _union(_PROPERTIES, overrides),
)

# Dimensions

arm64 = _ARM64
experimental = _EXPERIMENTAL
focal = _FOCAL
linux = _FOCAL
mac = _MAC
windows = _WINDOWS10
windows10 = _WINDOWS10
windows11 = _WINDOWS11

# Properties

chrome = _CHROME
emscripten = _EMSCRIPTEN
firefox = _FIREFOX
js_engines = _JS_ENGINES
no_android = _NO_ANDROID
slow_shards = _SLOW_SHARDS
no_caches = _NO_CACHES
