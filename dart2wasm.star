# Copyright (c) 2022 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines the dart2wasm builders.
"""

load("//lib/dart.star", "dart")
load(
    "//lib/defaults.star",
    "chrome",
    "emscripten",
    "firefox",
    "flute",
    "js_engines",
)
load("//lib/helpers.star", "union")
load("//lib/paths.star", "paths")

def _dart2wasm_builder(name, category = None, properties = [], **kwargs):
    default_properties = union({}, [emscripten, flute])
    dart.ci_sandbox_builder(
        name,
        category = category,
        properties = union(default_properties, properties),
        triggered_by = ["dart2wasm-gitiles-trigger-%s"],
        **kwargs
    )

dart.poller(
    "dart2wasm-gitiles-trigger",
    paths = paths.dart2wasm,
)

_dart2wasm_builder(
    "dart2wasm-linux-d8",
    category = "d2w|d",
    location_filters = paths.to_location_filters(paths.dart2wasm),
)

_dart2wasm_builder(
    "dart2wasm-asserts-minified-linux-d8",
    category = "d2w|d|m",
)

_dart2wasm_builder(
    "dart2wasm-linux-optimized-jsc",
    category = "d2w|j",
    properties = [js_engines],
)

_dart2wasm_builder(
    "dart2wasm-asserts-linux-chrome",
    category = "d2w|ca",
    properties = [chrome],
    location_filters = paths.to_location_filters(paths.dart2wasm),
)

_dart2wasm_builder(
    "dart2wasm-linux-chrome",
    category = "d2w|c",
    properties = [chrome],
    location_filters = paths.to_location_filters(paths.dart2wasm),
)

_dart2wasm_builder(
    "dart2wasm-linux-jscm-chrome",
    category = "d2w|cm",
    properties = [chrome],
    location_filters = paths.to_location_filters(paths.dart2wasm),
)

_dart2wasm_builder(
    "dart2wasm-linux-firefox",
    category = "d2w|f",
    properties = [firefox],
)
