# Copyright (c) 2023 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines the dart2js builders.
"""

load("//lib/cron.star", "cron")
load("//lib/dart.star", "dart")
load(
    "//lib/defaults.star",
    "arm64",
    "chrome",
    "firefox",
    "jammy",
    "mac",
    "safari_17_6",
    "windows",
)
load("//lib/paths.star", "paths")

dart.poller("dart2js-gitiles-trigger", paths = paths.dart2js)

def _dart2js_builder(
        name,
        enable_cq = False,
        **kwargs):
    location_filters = []
    if enable_cq:
        location_filters = paths.to_location_filters(paths.dart2js)
    dart.ci_sandbox_builder(
        name,
        triggered_by = ["dart2js-gitiles-trigger-%s"],
        location_filters = location_filters,
        **kwargs
    )

_dart2js_builder(
    "dart2js-canary-linux",
    category = "dart2js|c",
    channels = ["try"],
    dimensions = [jammy],  # TODO(https://github.com/dart-lang/sdk/issues/63603): Unpin.
    properties = [chrome],
)
_dart2js_builder(
    "dart2js-hostasserts-linux-d8",
    category = "dart2js|d8|ha",
    channels = ["try"],
    enable_cq = True,
)
_dart2js_builder(
    "dart2js-minified-linux-d8",
    category = "dart2js|d8|mi",
    enable_cq = True,
)
_dart2js_builder(
    "dart2js-unit-linux-x64-release",
    category = "dart2js|d8|u",
    enable_cq = True,
)
_dart2js_builder(
    "dart2js-linux-chrome",
    category = "dart2js|chrome|l",
    dimensions = [jammy],  # TODO(https://github.com/dart-lang/sdk/issues/63603): Unpin.
    enable_cq = True,
    properties = [chrome],
)
_dart2js_builder(
    "dart2js-minified-csp-linux-chrome",
    category = "dart2js|chrome|csp",
    dimensions = [jammy],  # TODO(https://github.com/dart-lang/sdk/issues/63603): Unpin.
    properties = [chrome],
)
cron.nightly_builder(
    "dart2js-mac-chrome",
    category = "dart2js|chrome|m",
    dimensions = [arm64, mac],
    properties = [chrome],
)
_dart2js_builder(
    "dart2js-win-chrome",
    category = "dart2js|chrome|w",
    dimensions = windows,
    properties = [chrome],
)
_dart2js_builder(
    "dart2js-linux-firefox",
    category = "dart2js|firefox|l",
    properties = [firefox],
)
_dart2js_builder(
    "dart2js-win-firefox",
    dimensions = windows,
    enabled = False,
    properties = [firefox],
)
_dart2js_builder(
    "dart2js-mac-safari",
    category = "dart2js|safari|m",
    dimensions = [arm64, mac, safari_17_6],
)
