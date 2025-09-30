# Copyright (c) 2019 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defaults for properties and dimensions used in main.star.
"""

load("//lib/helpers.star", "union")

_PROPERTIES = {"clobber": False}
_DIMENSIONS = {
    "cpu": "x86-64",
    "host_class": "default",
    "os": "Ubuntu-22",
    "pool": "luci.dart.try",
}
_CACHES = {
    "Mac": [swarming.cache("osx_sdk", name = "osx_sdk", wait_for_warm_cache = time.minute)],
}

# Swarming has an implicit cache named builder and defining it explicitly makes
# the wait_for_warm_cache field default to zero.
_NO_CACHES = [swarming.cache("builder")]
_NO_RECLIENT = {"custom_vars": {"download_reclient": False}}
_ANDROID_DEPS = {"custom_vars": {"download_android_deps": True}}
_CHROME = {"custom_vars": {"download_chrome": True}}
_EMSCRIPTEN = {"custom_vars": {"download_emscripten": True}}
_FIREFOX = {"custom_vars": {"download_firefox": True}}
_FUCHSIA_DEPS = {"custom_vars": {"download_fuchsia_deps": True}}
_JS_ENGINES = {"custom_vars": {"checkout_javascript_engines": True}}
_FLUTE = {"custom_vars": {"checkout_flute": True}}
_SLOW_SHARDS = {"shard_timeout": (90 * time.minute) // time.second}

_ARM64 = {"cpu": "arm64"}
_MAC = {"os": "Mac"}
_JAMMY = {"os": "Ubuntu-22"}
_NOBLE = {"os": "Ubuntu-24"}
_WINDOWS = {"os": "Windows"}

_FLUTTER_POOL = {"pool": "luci.flutter.prod"}
_EXPERIMENTAL = {"host_class": "experimental"}

defaults = struct(
    caches = lambda os: _CACHES.get(os),
    dimensions = lambda overrides: union(_DIMENSIONS, overrides),
    properties = lambda overrides: union(_PROPERTIES, overrides),
)

# Dimensions

arm64 = _ARM64
experimental = _EXPERIMENTAL
flutter_pool = _FLUTTER_POOL
jammy = _JAMMY
linux = _JAMMY
mac = _MAC
noble = _NOBLE
windows = _WINDOWS

# Properties

android_deps = _ANDROID_DEPS
chrome = _CHROME
emscripten = _EMSCRIPTEN
firefox = _FIREFOX
flute = _FLUTE
fuchsia_deps = _FUCHSIA_DEPS
js_engines = _JS_ENGINES
slow_shards = _SLOW_SHARDS
no_caches = _NO_CACHES
no_reclient = _NO_RECLIENT
