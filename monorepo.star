# Copyright (c) 2022 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines the monorepo builders.
"""

load("//lib/dart.star", "dart")
load("//lib/priority.star", "priority")

luci.gitiles_poller(
    name = "dart-gitiles-trigger-monorepo",
    bucket = "ci",
    repo = "https://dart.googlesource.com/monorepo/",
    refs = ["refs/heads/main"],
)

luci.console_view(
    name = "monorepo",
    repo = "https://dart.googlesource.com/monorepo",
    title = "Monorepo Console",
    refs = ["refs/heads/main"],
    header = "console-header.textpb",
)

luci.console_view(
    name = "flutter-engine",
    repo = "https://dart.googlesource.com/monorepo",
    title = "Dart/Flutter Engine Console",
    refs = ["refs/heads/main"],
    header = "console-header.textpb",
)

luci.console_view(
    name = "flutter-web",
    repo = "https://dart.googlesource.com/monorepo",
    title = "Dart/Flutter Web Console",
    refs = ["refs/heads/main"],
    header = "console-header.textpb",
)

dart.ci_sandbox_builder(
    name = "flutter-linux",
    channels = [],
    executable = dart.flutter_recipe("engine_v2/engine_v2"),
    execution_timeout = 120 * time.minute,
    notifies = None,
    priority = priority.normal,
    properties = {
        "$flutter/goma": {"server": "goma.chromium.org"},
        "config_name": "host_linux",
        "environment": "unused",
        "goma_jobs": "200",
    },
    triggered_by = ["dart-gitiles-trigger-monorepo"],
    schedule = "triggered",
)
luci.console_view_entry(
    builder = "flutter-linux",
    short_name = "engine",
    category = "coordinator",
    console_view = "monorepo",
)
dart.try_builder(
    "flutter-linux",
    executable = dart.flutter_recipe("engine_v2/engine_v2"),
    execution_timeout = 120 * time.minute,
    properties = {
        "$flutter/goma": {"server": "goma.chromium.org"},
        "builder_name_suffix": "-try",
        "config_name": "host_linux",
        "environment": "unused",
        "goma_jobs": "200",
    },
    on_cq = False,
    cq_branches = ["main"],
)

def monorepo_builder(name, short_name, category):
    dart.ci_sandbox_builder(
        name = name,
        channels = [],
        dimensions = {"pool": "dart.tests"},
        executable = dart.flutter_recipe("engine_v2/builder"),
        execution_timeout = 60 * time.minute,
        notifies = None,
        priority = priority.normal,
        triggered_by = [],
        schedule = None,
    )
    luci.console_view_entry(
        builder = name,
        short_name = short_name,
        category = category,
        console_view = "monorepo",
    )
    luci.console_view_entry(
        builder = name,
        short_name = short_name,
        console_view = "flutter-engine",
    )
    dart.try_builder(
        name,
        bucket = "try.monorepo",
        executable = dart.flutter_recipe("engine_v2/builder"),
        execution_timeout = 60 * time.minute,
        pool = "dart.tests",
        on_cq = False,
        cq_branches = [],
    )

monorepo_builder("flutter-android-debug", "android-debug", "build")
monorepo_builder("flutter-android-profile", "android-profile", "build")
monorepo_builder("flutter-linux-debug", "debug", "build")
monorepo_builder("flutter-linux-debug-unopt", "debug-unopt", "build")
monorepo_builder("flutter-linux-profile", "profile", "build")
monorepo_builder("flutter-linux-release", "release", "build")
monorepo_builder("flutter-wasm-release", "wasm", "build")

def monorepo_tester(name, short_name, category):
    dart.ci_sandbox_builder(
        name = name,
        channels = [],
        dimensions = {"pool": "dart.tests"},
        executable = dart.flutter_recipe("engine_v2/tester"),
        execution_timeout = 90 * time.minute,
        notifies = None,
        priority = priority.normal,
        triggered_by = [],
        schedule = None,
    )
    luci.console_view_entry(
        builder = name,
        short_name = short_name,
        category = category,
        console_view = "monorepo",
    )
    luci.console_view_entry(
        builder = name,
        short_name = short_name,
        console_view = "flutter-web",
    )
    dart.try_builder(
        name,
        bucket = "try.monorepo",
        executable = dart.flutter_recipe("engine_v2/tester"),
        execution_timeout = 90 * time.minute,
        pool = "dart.tests",
        on_cq = False,
        cq_branches = [],
    )

monorepo_tester("flutter-linux-web-tests-0", "wt0", "web_test")
monorepo_tester("flutter-linux-web-tests-1", "wt1", "web_test")
monorepo_tester("flutter-linux-web-tests-2", "wt2", "web_test")
monorepo_tester("flutter-linux-web-tests-3", "wt3", "web_test")
monorepo_tester("flutter-linux-web-tests-4", "wt4", "web_test")
monorepo_tester("flutter-linux-web-tests-5", "wt5", "web_test")
monorepo_tester("flutter-linux-web-tests-6", "wt6", "web_test")
monorepo_tester("flutter-linux-web-tests-7-last", "wt7", "web_test")
monorepo_tester("flutter-linux-web-tool-tests", "wtool", "web_test")
