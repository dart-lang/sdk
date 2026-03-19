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
        location_filters = paths.to_location_filters(paths.dart2wasm),
        **kwargs
    )

dart.poller(
    "dart2wasm-gitiles-trigger",
    paths = paths.dart2wasm,
)

_dart2wasm_builder(
    "dart2wasm-linux-d8",
    category = "dart2wasm|cmd|d",
)

_dart2wasm_builder(
    "dart2wasm-asserts-minified-linux-d8",
    category = "dart2wasm|cmd|dm",
)

_dart2wasm_builder(
    "dart2wasm-linux-optimized-jsc",
    category = "dart2wasm|cmd|j",
    properties = [js_engines],
)

_dart2wasm_builder(
    "dart2wasm-asserts-linux-chrome",
    category = "dart2wasm|browser|ca",
    properties = [chrome],
)

_dart2wasm_builder(
    "dart2wasm-linux-chrome",
    category = "dart2wasm|browser|c",
    properties = [chrome],
)

_dart2wasm_builder(
    "dart2wasm-linux-jscm-chrome",
    category = "dart2wasm|browser|cm",
    properties = [chrome],
)

_dart2wasm_builder(
    "dart2wasm-linux-firefox",
    category = "dart2wasm|browser|f",
    properties = [firefox],
)
_dart2wasm_builder(
    "dart2wasm-linux-standalone-chrome",
    category = "dart2wasm|sc",
    properties = [chrome],
)
