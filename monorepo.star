# Copyright (c) 2022 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines the monorepo builders.
Currently only triggered manually, while prototyping.
"""

load("//lib/dart.star", "dart")
load("//lib/defaults.star", "defaults", "linux")
load("//lib/priority.star", "priority")

luci.builder(
    name = "monorepo-engine-v2",
    build_numbers = False,
    bucket = "try",
    dimensions = defaults.dimensions(linux),
    executable = dart.flutter_recipe("engine_v2/engine_v2"),
    execution_timeout = 60 * time.minute,
    experiments = {"luci.non_production": 100},
    priority = priority.high,
)

luci.builder(
    name = "monorepo-builder-v2",
    build_numbers = False,
    bucket = "try",
    dimensions = defaults.dimensions([linux, {"pool": "dart.tests"}]),
    executable = dart.flutter_recipe("engine_v2/builder_v2"),
    execution_timeout = 60 * time.minute,
    experiments = {"luci.non_production": 100},
    priority = priority.high,
)
