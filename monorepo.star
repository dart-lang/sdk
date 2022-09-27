# Copyright (c) 2022 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines the monorepo builders.
"""

load("//lib/dart.star", "dart")
load("//lib/priority.star", "priority")

luci.console_view(
    name = "monorepo",
    repo = "https://dart.googlesource.com/monorepo",
    title = "Monorepo Console",
    refs = ["refs/heads/main"],
    header = "console-header.textpb",
)

dart.ci_sandbox_builder(
    name = "monorepo-engine-v2",
    channels = [],
    executable = dart.flutter_recipe("engine_v2/engine_v2"),
    execution_timeout = 60 * time.minute,
    notifies = None,
    priority = priority.normal,
    properties = {
        "$fuchsia/goma": {"server": "goma.chromium.org"},
        "config_name": "host_linux",
        "environment": "unused",
        "goma_jobs": "200",
    },
    triggered_by = ["dart-gitiles-trigger-monorepo"],
    schedule = "triggered",
)
luci.console_view_entry(
    builder = "monorepo-engine-v2",
    short_name = "engine",
    category = "coordinator",
    console_view = "monorepo",
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

monorepo_builder("monorepo-android-debug", "android-debug", "build")
monorepo_builder("monorepo-android-profile", "android-profile", "build")
monorepo_builder("monorepo-host-debug", "debug", "build")
monorepo_builder("monorepo-host-debug-unopt", "debug-unopt", "build")
monorepo_builder("monorepo-host-profile", "profile", "build")
monorepo_builder("monorepo-host-release", "release", "build")

def monorepo_tester(name, short_name, category):
    dart.ci_sandbox_builder(
        name = name,
        channels = [],
        dimensions = {"pool": "dart.tests"},
        executable = dart.flutter_recipe("engine_v2/tester"),
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

monorepo_tester("monorepo-tester", "tester", "test")
