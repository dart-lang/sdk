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

dart.ci_sandbox_builder(
    "flutter-analyze",
    category = "analyzer|fa",
    channels = ["try"],
    location_filters = paths.to_location_filters(paths.analyzer_only),
)
dart.ci_sandbox_builder(
    "analyzer-analysis-server-linux",
    category = "analyzer|as",
    channels = dart.channels,
    location_filters = paths.to_location_filters(paths.analyzer),
)
dart.ci_sandbox_builder(
    "analyzer-linux-release",
    category = "analyzer|l",
    channels = dart.channels,
    location_filters = paths.to_location_filters(paths.analyzer),
)
dart.ci_sandbox_builder(
    "analyzer-mac-release",
    category = "analyzer|m",
    channels = dart.channels,
    dimensions = mac,
)
dart.ci_sandbox_builder(
    "analyzer-win-release",
    category = "analyzer|w",
    channels = dart.channels,
    dimensions = windows,
)
