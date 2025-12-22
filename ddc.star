# Copyright (c) 2023 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines the DDC builders.
"""

load("//lib/cron.star", "cron")
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

dart.poller("ddc-gitiles-trigger", branches = ["main"], paths = paths.ddc)

dart.ci_sandbox_builder(
    "ddc-linux-chrome",
    category = "ddc|chrome|l",
    properties = [chrome],
    location_filters = paths.to_location_filters(paths.ddc),
)

dart.ci_sandbox_builder(
    "ddc-mac-chrome",
    category = "ddc|chrome|m",
    dimensions = [arm64, mac],
    # TODO(2026-01-07): remove clobber when caches are cleared.
    properties = [chrome, {"clobber": True}],
)

dart.ci_sandbox_builder(
    "ddc-win-chrome",
    category = "ddc|chrome|w",
    dimensions = windows,
    properties = [chrome],
)

dart.ci_sandbox_builder(
    "ddc-linux-firefox",
    category = "ddc|f",
    channels = ["try"],
    properties = [firefox],
    triggered_by = ["ddc-gitiles-trigger-%s"],
)

dart.ci_sandbox_builder(
    "ddc-mac-safari",
    category = "ddc|s",
    channels = ["try"],
    dimensions = [arm64, mac],
    properties = [chrome],
)

cron.nightly_builder(
    "ddc-canary-linux-chrome",
    category = "ddc|c",
    channels = ["try"],
    properties = [chrome],
)

cron.nightly_builder(
    "ddc-hostasserts-linux-d8",
    category = "ddc|h",
    channels = ["try"],
)
