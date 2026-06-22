# Copyright (c) 2023 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines the analyzer builders.
"""

load("//lib/dart.star", "dart")
load(
    "//lib/defaults.star",
    "mac",
    "windows",
)
load("//lib/paths.star", "paths")

dart.poller("analyzer-gitiles-trigger", paths = paths.analyzer)

def _analyzer_builder(
        name,
        enable_cq = False,
        **kwargs):
    location_filters = []
    if enable_cq:
        location_filters = paths.to_location_filters(paths.analyzer)
    dart.ci_sandbox_builder(
        name,
        triggered_by = ["analyzer-gitiles-trigger-%s"],
        location_filters = location_filters,
        **kwargs
    )

dart.ci_sandbox_builder(
    "flutter-analyze",
    category = "analyzer|fa",
    channels = ["try"],
    location_filters = paths.to_location_filters(paths.analyzer_end_user),
)
_analyzer_builder(
    "analyzer-analysis-server-linux",
    category = "analyzer|as",
    channels = dart.channels,
    enable_cq = True,
)
_analyzer_builder(
    "analyzer-linux-release",
    category = "analyzer|l",
    channels = dart.channels,
    enable_cq = True,
)
_analyzer_builder(
    "analyzer-mac-release",
    category = "analyzer|m",
    channels = dart.channels,
    dimensions = mac,
)
_analyzer_builder(
    "analyzer-win-release",
    category = "analyzer|w",
    channels = dart.channels,
    dimensions = windows,
)
