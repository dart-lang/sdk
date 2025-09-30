# Copyright (c) 2023 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines the dart2js builders.
"""

load("//lib/dart.star", "dart")
load(
    "//lib/defaults.star",
    "arm64",
    "chrome",
    "firefox",
    "mac",
    "windows",
)
load("//lib/paths.star", "paths")

dart.poller("dart2js-gitiles-trigger", branches = ["main"], paths = paths.dart2js)

dart.ci_sandbox_builder(
    "dart2js-canary-linux",
    category = "dart2js|c",
    channels = ["try"],
    properties = [chrome],
    triggered_by = ["dart2js-gitiles-trigger-%s"],
)
dart.ci_sandbox_builder(
    "dart2js-hostasserts-linux-d8",
    category = "dart2js|d8|ha",
    channels = ["try"],
    location_filters = paths.to_location_filters(paths.dart2js),
    triggered_by = ["dart2js-gitiles-trigger-%s"],
)
dart.ci_sandbox_builder(
    "dart2js-minified-linux-d8",
    category = "dart2js|d8|mi",
    location_filters = paths.to_location_filters(paths.dart2js),
)
dart.ci_sandbox_builder(
    "dart2js-unit-linux-x64-release",
    category = "dart2js|d8|u",
    location_filters = paths.to_location_filters(paths.dart2js),
)
dart.ci_sandbox_builder(
    "dart2js-linux-chrome",
    category = "dart2js|chrome|l",
    location_filters = paths.to_location_filters(paths.dart2js),
    properties = [chrome],
)
dart.ci_sandbox_builder(
    "dart2js-minified-csp-linux-chrome",
    category = "dart2js|chrome|csp",
    properties = [chrome],
)
dart.ci_sandbox_builder(
    "dart2js-mac-chrome",
    category = "dart2js|chrome|m",
    dimensions = [arm64, mac],
    properties = [chrome],
)
dart.ci_sandbox_builder(
    "dart2js-win-chrome",
    category = "dart2js|chrome|w",
    dimensions = windows,
    properties = [chrome],
)
dart.ci_sandbox_builder(
    "dart2js-linux-firefox",
    category = "dart2js|firefox|l",
    properties = [firefox],
)
dart.ci_sandbox_builder(
    "dart2js-win-firefox",
    dimensions = windows,
    enabled = False,
    properties = [firefox],
)
dart.ci_sandbox_builder(
    "dart2js-mac-safari",
    category = "dart2js|safari|m",
    dimensions = [arm64, mac],
)
