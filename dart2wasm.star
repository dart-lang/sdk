# Copyright (c) 2022 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines the dart2wasm builders.
"""

load("//lib/dart.star", "dart")
load("//lib/defaults.star", "chrome", "emscripten")
load("//lib/paths.star", "paths")

dart.poller(
    "dart2wasm-gitiles-trigger",
    branches = ["main"],
    paths = paths.dart2wasm,
)

dart.ci_sandbox_builder(
    "dart2wasm-linux-d8",
    category = "d2w|d",
    channels = ["try"],
    properties = emscripten,
    location_filters = paths.to_location_filters(paths.dart2wasm),
    triggered_by = ["dart2wasm-gitiles-trigger-%s"],
)

dart.ci_sandbox_builder(
    "dart2wasm-linux-chrome",
    category = "d2w|c",
    channels = ["try"],
    properties = [chrome, emscripten],
    location_filters = paths.to_location_filters(paths.dart2wasm),
    triggered_by = ["dart2wasm-gitiles-trigger-%s"],
)
