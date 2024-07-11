# Copyright (c) 2022 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines the dart2wasm builders.
"""

load("//lib/dart.star", "dart")
load("//lib/defaults.star", "chrome", "emscripten", "firefox", "no_android")
load("//lib/paths.star", "paths")

dart.poller(
    "dart2wasm-gitiles-trigger",
    paths = paths.dart2wasm,
)

dart.ci_sandbox_builder(
    "dart2wasm-linux-d8",
    category = "d2w|d",
    properties = [emscripten, no_android],
    location_filters = paths.to_location_filters(paths.dart2wasm),
    triggered_by = ["dart2wasm-gitiles-trigger-%s"],
)

dart.ci_sandbox_builder(
    "dart2wasm-asserts-linux-chrome",
    category = "d2w|ca",
    properties = [chrome, emscripten, no_android],
    location_filters = paths.to_location_filters(paths.dart2wasm),
    triggered_by = ["dart2wasm-gitiles-trigger-%s"],
)

dart.ci_sandbox_builder(
    "dart2wasm-linux-chrome",
    category = "d2w|c",
    properties = [chrome, emscripten, no_android],
    location_filters = paths.to_location_filters(paths.dart2wasm),
    triggered_by = ["dart2wasm-gitiles-trigger-%s"],
)

dart.ci_sandbox_builder(
    "dart2wasm-linux-jscm-chrome",
    category = "d2w|cm",
    properties = [chrome, emscripten, no_android],
    location_filters = paths.to_location_filters(paths.dart2wasm),
    triggered_by = ["dart2wasm-gitiles-trigger-%s"],
)

dart.ci_sandbox_builder(
    "dart2wasm-linux-firefox",
    category = "d2w|f",
    properties = [firefox, emscripten, no_android],
    triggered_by = ["dart2wasm-gitiles-trigger-%s"],
)
