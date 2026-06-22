# Copyright (c) 2022 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines the dart2wasm builders.
"""

load("//lib/dart.star", "dart")
load(
    "//lib/defaults.star",
    "arm64",
    "chrome",
    "emscripten",
    "firefox",
    "flute",
    "jammy",
    "js_engines",
    "mac",
    "safari_26_5",
)
load("//lib/helpers.star", "union")
load("//lib/paths.star", "paths")

dart.poller("dart2wasm-gitiles-trigger", paths = paths.dart2wasm)

def _dart2wasm_builder(
        name,
        properties = [],
        enable_cq = True,
        **kwargs):
    default_properties = union({}, [emscripten, flute])
    location_filters = []
    if enable_cq:
        location_filters = paths.to_location_filters(paths.dart2wasm)
    dart.ci_sandbox_builder(
        name,
        properties = union(default_properties, properties),
        triggered_by = ["dart2wasm-gitiles-trigger-%s"],
        location_filters = location_filters,
        **kwargs
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
    dimensions = [jammy],  # TODO(https://github.com/dart-lang/sdk/issues/63603): Unpin.
    properties = [chrome],
)

_dart2wasm_builder(
    "dart2wasm-linux-chrome",
    category = "dart2wasm|browser|c",
    dimensions = [jammy],  # TODO(https://github.com/dart-lang/sdk/issues/63603): Unpin.
    properties = [chrome],
)

_dart2wasm_builder(
    "dart2wasm-linux-jscm-chrome",
    category = "dart2wasm|browser|cm",
    dimensions = [jammy],  # TODO(https://github.com/dart-lang/sdk/issues/63603): Unpin.
    properties = [chrome],
)

_dart2wasm_builder(
    "dart2wasm-linux-firefox",
    category = "dart2wasm|browser|f",
    properties = [firefox],
)

_dart2wasm_builder(
    "dart2wasm-mac-safari",
    category = "dart2wasm|browser|s",
    dimensions = [arm64, mac, safari_26_5],
    enable_cq = False,
    execution_timeout = 3 * time.hour,
    channels = ["try"],
)

_dart2wasm_builder(
    "dart2wasm-linux-standalone-chrome",
    category = "dart2wasm|sc",
    dimensions = [jammy],  # TODO(https://github.com/dart-lang/sdk/issues/63603): Unpin.
    properties = [chrome],
)
