# Copyright (c) 2023 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines the pkg builders.
"""

load("//lib/dart.star", "dart")
load(
    "//lib/defaults.star",
    "arm64",
    "chrome",
    "flute",
    "flutter_pool",
    "mac",
    "no_reclient",
    "windows",
)
load("//lib/helpers.star", "union")
load("//lib/paths.star", "paths")

def _pkg_builder(name, category = None, properties = [], **kwargs):
    # Some pkg unittests need flute sources.
    default_properties = union({}, [flute])
    dart.ci_sandbox_builder(
        name,
        category = category,
        properties = union(default_properties, properties),
        **kwargs
    )

_pkg_builder(
    "pkg-linux-release",
    category = "pkg|l",
    location_filters = paths.to_location_filters(paths.pkg),
    properties = chrome,
)
_pkg_builder(
    "pkg-linux-release-arm64",
    category = "pkg|la",
    dimensions = [arm64],
)
_pkg_builder(
    "pkg-mac-release",
    category = "pkg|m",
    dimensions = mac,
    properties = chrome,
)
_pkg_builder(
    "pkg-mac-release-arm64",
    category = "pkg|ma",
    dimensions = [mac, arm64],
    properties = [chrome],
)
_pkg_builder(
    "pkg-win-release",
    category = "pkg|w",
    dimensions = windows,
    properties = chrome,
)
_pkg_builder(
    "pkg-win-release-arm64",
    category = "pkg|wa",
    dimensions = [windows, arm64, flutter_pool],
    properties = [no_reclient],
)
_pkg_builder(
    "pkg-linux-debug",
    category = "pkg|ld",
    channels = ["try"],
    properties = chrome,
)
