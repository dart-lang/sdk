# Copyright (c) 2022 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines the monorepo builders.
"""

load("//lib/dart.star", "dart")
load("//lib/defaults.star", "defaults")
load("//lib/priority.star", "priority")

monorepo_properties = {
    "$flutter/goma": {"server": "goma.chromium.org"},
    "$flutter/rbe": {
        "instance": "projects/flutter-rbe-prod/instances/default",
        "platform": "container-image=docker://gcr.io/cloud-marketplace/google/debian11@sha256:69e2789c9f3d28c6a0f13b25062c240ee7772be1f5e6d41bb4680b63eae6b304",
    },
    "clobber": False,
    "environment": "unused",
    "goma_jobs": "200",
    "rbe_jobs": "200",
}

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
    execution_timeout = 180 * time.minute,
    priority = priority.normal,
    properties = defaults.properties([monorepo_properties, {"config_name": "host_linux"}]),
    triggered_by = ["dart-gitiles-trigger-monorepo"],
    schedule = "triggered",
)
luci.console_view_entry(
    builder = "flutter-linux",
    short_name = "engine",
    category = "coordinator",
    console_view = "monorepo",
)
luci.console_view_entry(
    builder = "flutter-linux",
    short_name = "engine",
    category = "coordinator",
    console_view = "flutter-engine",
)
dart.try_builder(
    "flutter-linux",
    executable = dart.flutter_recipe("engine_v2/engine_v2"),
    execution_timeout = 180 * time.minute,
    properties = defaults.properties([monorepo_properties, {
        "builder_name_suffix": "-try",
        "config_name": "host_linux",
    }]),
    on_cq = False,
    cq_branches = ["main"],
)

dart.ci_sandbox_builder(
    name = "flutter-web",
    channels = [],
    executable = dart.flutter_recipe("engine_v2/engine_v2"),
    execution_timeout = 180 * time.minute,
    priority = priority.normal,
    properties = defaults.properties([monorepo_properties, {"config_name": "web_linux"}]),
    triggered_by = ["dart-gitiles-trigger-monorepo"],
    schedule = "triggered",
)
luci.console_view_entry(
    builder = "flutter-web",
    short_name = "web",
    category = "coordinator",
    console_view = "monorepo",
)
luci.console_view_entry(
    builder = "flutter-web",
    short_name = "web",
    category = "coordinator",
    console_view = "flutter-web",
)
dart.try_builder(
    "flutter-web",
    executable = dart.flutter_recipe("engine_v2/engine_v2"),
    execution_timeout = 180 * time.minute,
    properties = defaults.properties([monorepo_properties, {
        "builder_name_suffix": "-try",
        "config_name": "web_linux",
    }]),
    on_cq = False,
    cq_branches = ["main"],
)

def _monorepo_builder(name, short_name, console):
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
    dart.try_builder(
        name,
        bucket = "try.monorepo",
        executable = dart.flutter_recipe("engine_v2/builder"),
        execution_timeout = 60 * time.minute,
        dimensions = {"pool": "dart.tests"},
        on_cq = False,
        cq_branches = [],
    )
    if console:
        luci.console_view_entry(
            builder = name,
            short_name = short_name,
            category = console,
            console_view = "monorepo",
        )
        luci.console_view_entry(
            builder = name,
            short_name = short_name,
            console_view = console,
        )

_monorepo_builder(
    "flutter-linux-android_debug",
    "android-debug",
    "flutter-engine",
)
_monorepo_builder(
    "flutter-linux-android_profile",
    "android-profile",
    "flutter-engine",
)
_monorepo_builder(
    "flutter-linux-android_release",
    "android-release",
    "flutter-engine",
)
_monorepo_builder(
    "flutter-linux-android_debug_arm64",
    "android-debug-arm64",
    "flutter-engine",
)
_monorepo_builder(
    "flutter-linux-android_profile_arm64",
    "android-profile-arm64",
    "flutter-engine",
)
_monorepo_builder(
    "flutter-linux-android_release_arm64",
    "android-release-arm64",
    "flutter-engine",
)
_monorepo_builder(
    "flutter-linux-android_debug_x64",
    "android-debug-x64",
    "flutter-engine",
)
_monorepo_builder(
    "flutter-linux-android_profile_x64",
    "android-profile-x64",
    "flutter-engine",
)
_monorepo_builder(
    "flutter-linux-android_release_x64",
    "android-release-x64",
    "flutter-engine",
)
_monorepo_builder(
    "flutter-linux-android_debug_x86",
    "android-debug-x86",
    "flutter-engine",
)
_monorepo_builder("flutter-linux-host_debug", "debug", "flutter-engine")
_monorepo_builder("flutter-linux-host_debug_unopt", "debug-unopt", "flutter-engine")
_monorepo_builder("flutter-linux-host_profile", "profile", "flutter-engine")
_monorepo_builder("flutter-linux-host_release", "release", "flutter-engine")
_monorepo_builder("flutter-linux-wasm_release", "wasm", "flutter-web")
_monorepo_builder("flutter-linux-web_tests-artifacts", "web-tests", None)
_monorepo_builder(
    "flutter-linux-web_tests-test_bundles-dart2wasm-skwasm-ui",
    "skwasm-ui-tests",
    None,
)

def _monorepo_tester(name, short_name, console, recipe = "engine_v2/tester"):
    dart.ci_sandbox_builder(
        name = name,
        channels = [],
        dimensions = {"pool": "dart.tests"},
        executable = dart.flutter_recipe(recipe),
        execution_timeout = 90 * time.minute,
        notifies = None,
        priority = priority.normal,
        triggered_by = [],
        schedule = None,
    )
    dart.try_builder(
        name,
        bucket = "try.monorepo",
        executable = dart.flutter_recipe(recipe),
        execution_timeout = 90 * time.minute,
        dimensions = {"pool": "dart.tests"},
        on_cq = False,
        cq_branches = [],
    )
    if console:
        luci.console_view_entry(
            builder = name,
            short_name = short_name,
            category = console,
            console_view = "monorepo",
        )
        luci.console_view_entry(
            builder = name,
            short_name = short_name,
            console_view = console,
        )

_monorepo_tester("flutter-linux-flutter-plugins", "plugins", "flutter-engine")
_monorepo_tester("flutter-linux-framework-coverage", "coverage", "flutter-engine")
_monorepo_tester("flutter-linux-framework-tests-libraries", "fl", "flutter-engine")
_monorepo_tester("flutter-linux-framework-tests-misc", "fm", "flutter-engine")
_monorepo_tester("flutter-linux-framework-tests-slow", "fs", "flutter-engine")
_monorepo_tester("flutter-linux-framework-tests-widgets", "fw", "flutter-engine")
_monorepo_tester("flutter-linux-tool-tests", "tool", "flutter-engine")
_monorepo_tester("flutter-linux-customer-testing", "customer_testing", "flutter-engine")
_monorepo_tester("flutter-linux-web-tests-0", "wt0", "flutter-web")
_monorepo_tester("flutter-linux-web-tests-1", "wt1", "flutter-web")
_monorepo_tester("flutter-linux-web-tests-2", "wt2", "flutter-web")
_monorepo_tester("flutter-linux-web-tests-3", "wt3", "flutter-web")
_monorepo_tester("flutter-linux-web-tests-4", "wt4", "flutter-web")
_monorepo_tester("flutter-linux-web-tests-5", "wt5", "flutter-web")
_monorepo_tester("flutter-linux-web-tests-6", "wt6", "flutter-web")
_monorepo_tester("flutter-linux-web-tests-7-last", "wt7", "flutter-web")
_monorepo_tester("flutter-linux-web-tool-tests", "wtool", "flutter-web")
_monorepo_tester(
    "flutter-linux-chrome-dart2wasm-skwasm-ui",
    "skwasm-ui",
    None,
    recipe = "engine_v2/tester_engine",
)
