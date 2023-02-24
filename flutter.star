# Copyright (c) 2023 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines the flutter builders.
"""

load("//lib/dart.star", "dart")

luci.console_view(
    name = "flutter",
    repo = dart.git,
    title = "Dart/Flutter Console",
    refs = ["refs/heads/main"],
)

luci.console_view(
    name = "flutter-hhh",
    repo = "https://dart.googlesource.com/linear_sdk_flutter_engine",
    title = "Dart/Flutter Linear History Console",
    refs = ["refs/heads/master"],
)

luci.gitiles_poller(
    name = "dart-gitiles-trigger-flutter",
    bucket = "ci",
    repo = "https://dart.googlesource.com/linear_sdk_flutter_engine/",
    refs = ["refs/heads/master"],
)

luci.gitiles_poller(
    name = "dart-gitiles-trigger-flutter-daily",
    bucket = "ci",
    repo = "https://dart.googlesource.com/linear_sdk_flutter_engine/",
    refs = ["refs/heads/master"],
    schedule = "0 8 * * *",  # daily, at 08:00 UTC
)

dart.ci_sandbox_builder(
    "flutter-engine-linux",
    recipe = "dart/flutter_engine",
    category = "flutter|3H",
    channels = ["try"],
    execution_timeout = 8 * time.hour,
    triggered_by = ["dart-gitiles-trigger-flutter"],
    properties = [{
        "bisection_enabled": True,
        "flutter_test_suites": [
            "add_to_app_life_cycle_tests",
            "flutter_plugins",
            "framework_coverage",
            "framework_tests",
            "tool_tests",
        ],
    }],
)

dart.try_builder(
    "flutter-engine-linux-web_tests",
    recipe = "dart/flutter_engine",
    cq_branches = ["main"],
    execution_timeout = 8 * time.hour,
    properties = {
        "flutter_test_suites": [
            "web_tests",
            "web_tool_tests",
        ],
    },
)

dart.ci_builder(
    "flutter-engine-ios",
    recipe = "flutter/engine",
    category = "flutter|i",
    channels = [],
    execution_timeout = 2 * time.hour,
    triggered_by = ["dart-gitiles-trigger-flutter-daily"],
    notifies = None,
)

luci.console_view_entry(
    builder = "flutter-engine-linux",
    short_name = "3H",
    console_view = "flutter-hhh",
)

luci.console_view_entry(
    builder = "flutter-engine-ios",
    short_name = "ios",
    console_view = "flutter-hhh",
)
