# Copyright (c) 2022 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines the monorepo builders.
"""

load("//lib/dart.star", "dart")
load("//lib/priority.star", "priority")

dart.ci_sandbox_builder(
    name = "monorepo-engine-v2",
    channels = [],
    executable = dart.flutter_recipe("engine_v2/engine_v2"),
    execution_timeout = 60 * time.minute,
    notifies = None,
    priority = priority.high,
    properties = {
        "$fuchsia/goma": {"server": "goma.chromium.org"},
        "config_name": "host_linux",
        "environment": "unused",
        "goma_jobs": "200",
    },
    triggered_by = ["dart-gitiles-trigger-monorepo"],
    schedule = "triggered",
)

dart.ci_sandbox_builder(
    name = "monorepo-builder-v2",
    channels = [],
    dimensions = {"pool": "dart.tests"},
    executable = dart.flutter_recipe("engine_v2/builder"),
    execution_timeout = 60 * time.minute,
    notifies = None,
    priority = priority.high,
    triggered_by = [],
    schedule = None,
)
