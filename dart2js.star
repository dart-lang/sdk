# Copyright (c) 2023 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines the dart2js builders.
"""

load("//lib/dart.star", "dart")
load(
    "//lib/defaults.star",
    "chrome",
    "firefox",
    "mac",
    "no_android",
    "windows",
)
load("//lib/paths.star", "paths")

dart.ci_sandbox_builder(
    "dart2js-canary-x64",
    category = "dart2js|c",
    properties = [chrome, no_android],
)
dart.ci_sandbox_builder(
    "dart2js-strong-hostasserts-linux-ia32-d8",
    category = "dart2js|d8|ha",
    location_filters = paths.to_location_filters(paths.dart2js),
    properties = no_android,
)
dart.ci_sandbox_builder(
    "dart2js-minified-strong-linux-x64-d8",
    category = "dart2js|d8|mi",
    location_filters = paths.to_location_filters(paths.dart2js),
    properties = no_android,
)
dart.ci_sandbox_builder(
    "dart2js-unit-linux-x64-release",
    category = "dart2js|d8|u",
    location_filters = paths.to_location_filters(paths.dart2js),
    properties = no_android,
)
dart.ci_sandbox_builder(
    "dart2js-strong-linux-x64-chrome",
    category = "dart2js|chrome|l",
    location_filters = paths.to_location_filters(paths.dart2js),
    properties = [chrome, no_android],
)
dart.ci_sandbox_builder(
    "dart2js-csp-minified-linux-x64-chrome",
    category = "dart2js|chrome|csp",
    properties = [chrome, no_android],
)
dart.ci_sandbox_builder(
    "dart2js-strong-mac-x64-chrome",
    category = "dart2js|chrome|m",
    dimensions = mac,
    properties = [chrome, no_android],
)
dart.ci_sandbox_builder(
    "dart2js-strong-win-x64-chrome",
    category = "dart2js|chrome|w",
    dimensions = windows,
    properties = [chrome, no_android],
)
dart.ci_sandbox_builder(
    "dart2js-nnbd-linux-x64-chrome",
    category = "dart2js|chrome|nn",
    location_filters = paths.to_location_filters(paths.dart2js),
    properties = [chrome, no_android],
)
dart.ci_sandbox_builder(
    "dart2js-strong-linux-x64-firefox",
    category = "dart2js|firefox|l",
    properties = [firefox, no_android],
)
dart.ci_sandbox_builder(
    "dart2js-strong-win-x64-firefox",
    dimensions = windows,
    enabled = False,
    properties = [firefox, no_android],
)
dart.ci_sandbox_builder(
    "dart2js-strong-mac-x64-safari",
    category = "dart2js|safari|m",
    dimensions = mac,
    properties = no_android,
)
