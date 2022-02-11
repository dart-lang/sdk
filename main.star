#!/usr/bin/env lucicfg

# Copyright (c) 2019 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Use ./main.star to regenerate the Luci configuration based on this file.
#
# Documentation for lucicfg is here:
# https://chromium.googlesource.com/infra/luci/luci-go/+/main/lucicfg/doc/
"""
Generates the Luci configuration for the Dart project.
"""

load("//lib/cron.star", "cron")
load("//lib/dart.star", "dart")
load(
    "//lib/defaults.star",
    "arm64",
    "chrome",
    "firefox",
    "js_engines",
    "mac",
    "no_android",
    "pinned_xcode",
    "windows",
)
load("//lib/paths.star", "paths")
load("//lib/priority.star", "priority")

lucicfg.check_version("1.30.9")

# Use LUCI Scheduler BBv2 names and add Scheduler realms configs.
lucicfg.enable_experiment("crbug.com/1182002")

# Global builder defaults
# These need to be set at the top level to affect all uses of luci.builder.
luci.builder.defaults.experiments.set({
    "luci.recipes.use_python3": 100,
})
luci.builder.defaults.properties.set({
    "$recipe_engine/isolated": {
        "server": "https://isolateserver.appspot.com",
    },
    "$recipe_engine/swarming": {
        "server": "https://chromium-swarm.appspot.com",
    },
})

exec("//project.star")
exec("//cq.star")

luci.console_view(
    name = "be",
    repo = "https://dart.googlesource.com/sdk",
    title = "SDK Bleeding Edge Console",
    refs = ["refs/heads/main"],
    header = "console-header.textpb",
)

luci.console_view(
    name = "alt",
    repo = "https://dart.googlesource.com/sdk",
    title = "SDK Bleeding Edge Console (alternative)",
    refs = ["refs/heads/main"],
    header = "console-header.textpb",
)

luci.console_view(
    name = "dev",
    repo = "https://dart.googlesource.com/sdk",
    title = "SDK Dev Console",
    refs = ["refs/heads/dev"],
    header = "console-header.textpb",
)

luci.console_view(
    name = "beta",
    repo = "https://dart.googlesource.com/sdk",
    title = "SDK Beta Console",
    refs = ["refs/heads/beta"],
    header = "console-header.textpb",
)

luci.console_view(
    name = "stable",
    repo = "https://dart.googlesource.com/sdk",
    title = "SDK Stable Console",
    refs = ["refs/heads/stable"],
    header = "console-header.textpb",
)

luci.list_view(
    name = "dart-fuzz",
    title = "Dart Fuzzer Console",
)

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

luci.list_view(
    name = "iso-stress",
    title = "VM Isolate Stress Test Console",
)

luci.console_view(
    name = "fyi",
    repo = dart.git,
    title = "SDK FYI Console",
    refs = ["refs/heads/main"],
)

luci.list_view(
    name = "infra",
    title = "Infra Console",
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

luci.gitiles_poller(
    name = "dart-ci-test-data-trigger",
    bucket = "ci",
    path_regexps = ["tools/bots/ci_test_data_trigger"],
    repo = dart.git,
    refs = ["refs/heads/ci-test-data"],
)

luci.gitiles_poller(
    name = "dart-flutter-engine-trigger",
    bucket = "ci",
    repo = "https://dart.googlesource.com/external/github.com/flutter/engine",
    refs = ["refs/heads/master"],
)

luci.gitiles_poller(
    name = "dart-flutter-flutter-trigger",
    bucket = "ci",
    repo = "https://dart.googlesource.com/external/github.com/flutter/flutter",
    refs = ["refs/heads/master"],
)

dart.poller("dart-gitiles-trigger", branches = dart.branches)

luci.notifier(
    name = "dart",
    on_new_failure = True,
    notify_blamelist = True,
)

luci.notifier(
    name = "infra",
    on_new_failure = True,
    notify_emails = [
        "athom@google.com",
        "sortie@google.com",
        "whesse@google.com",
    ],
)

luci.notifier(
    name = "dart-fuzz-testing",
    on_success = False,
    on_failure = True,
    notify_emails = ["bkonyi@google.com"],
)

luci.notifier(
    name = "frontend-team",
    on_failure = True,
    notify_emails = ["jensj@google.com"],
)

luci.notifier(
    name = "ci-test-data",
    on_success = True,
    on_failure = True,
)

# cfe
dart.ci_sandbox_builder(
    "front-end-linux-release-x64",
    category = "cfe|l",
    on_cq = True,
)
dart.ci_sandbox_builder(
    "front-end-mac-release-x64",
    category = "cfe|m",
    dimensions = mac,
    properties = pinned_xcode,
)
dart.ci_sandbox_builder(
    "front-end-win-release-x64",
    category = "cfe|w",
    dimensions = windows,
)
dart.ci_sandbox_builder(
    "front-end-nnbd-linux-release-x64",
    category = "cfe|nnbd|l",
    location_regexp = paths.to_location_regexp(paths.cfe),
)
cron.nightly_builder(
    "front-end-nnbd-mac-release-x64",
    category = "cfe|nnbd|m",
    channels = ["try"],
    dimensions = mac,
    properties = pinned_xcode,
)
cron.nightly_builder(
    "front-end-nnbd-win-release-x64",
    category = "cfe|nnbd|w",
    channels = ["try"],
    dimensions = windows,
)
dart.ci_sandbox_builder(
    "flutter-frontend",
    category = "cfe|fl",
    channels = ["try"],
    notifies = "frontend-team",
    location_regexp = paths.to_location_regexp(paths.cfe_only),
)
cron.weekly_builder(
    "frontend-weekly",
    notifies = "frontend-team",
    channels = [],
    execution_timeout = 12 * time.hour,
)

# flutter
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

dart.ci_sandbox_builder(
    "flutter-engine-linux-web_tests",
    recipe = "dart/flutter_engine",
    category = "flutter|web",
    channels = ["try"],
    execution_timeout = 8 * time.hour,
    triggered_by = ["dart-gitiles-trigger-flutter"],
    properties = {
        "bisection_enabled": True,
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

vm = exec("//vm.star")

# pkg
dart.ci_sandbox_builder(
    "pkg-linux-release",
    category = "pkg|l",
    on_cq = True,
    properties = [chrome, pinned_xcode],
)
dart.ci_sandbox_builder(
    "pkg-mac-release",
    category = "pkg|m",
    dimensions = mac,
    properties = [chrome, pinned_xcode],
)
dart.ci_sandbox_builder(
    "pkg-mac-release-arm64",
    category = "pkg|m1",
    channels = ["try"],
    dimensions = [mac, arm64],
    properties = [chrome, no_android, pinned_xcode],
    experiments = {"dart.use_update_script": 100},
)
dart.ci_sandbox_builder(
    "pkg-win-release",
    category = "pkg|w",
    dimensions = windows,
    properties = chrome,
    experiments = {"dart.use_update_script": 100},
)
dart.ci_sandbox_builder(
    "pkg-linux-debug",
    category = "pkg|ld",
    channels = ["try"],
    properties = chrome,
)

# dart2js
dart.ci_sandbox_builder(
    "dart2js-canary-x64",
    category = "dart2js|c",
    properties = [chrome, no_android],
)
dart.ci_sandbox_builder(
    "dart2js-strong-hostasserts-linux-ia32-d8",
    category = "dart2js|d8|ha",
    location_regexp = paths.to_location_regexp(paths.dart2js),
    properties = no_android,
)
dart.ci_sandbox_builder(
    "dart2js-minified-strong-linux-x64-d8",
    category = "dart2js|d8|mi",
    location_regexp = paths.to_location_regexp(paths.dart2js),
    properties = no_android,
)
dart.ci_sandbox_builder(
    "dart2js-unit-linux-x64-release",
    category = "dart2js|d8|u",
    location_regexp = paths.to_location_regexp(paths.dart2js),
    properties = no_android,
)
dart.ci_sandbox_builder(
    "dart2js-strong-linux-x64-chrome",
    category = "dart2js|chrome|l",
    location_regexp = paths.to_location_regexp(paths.dart2js),
    properties = [chrome, no_android],
)
dart.ci_sandbox_builder(
    "dart2js-csp-minified-linux-x64-chrome",
    category = "dart2js|chrome|csp",
    properties = [chrome, no_android],
)
dart.ci_sandbox_builder(
    "dart2js-strong-mac-x64-chrome",
    category = "dart2js|chrome|m",
    dimensions = mac,
    properties = [chrome, pinned_xcode, no_android],
)
dart.ci_sandbox_builder(
    "dart2js-strong-win-x64-chrome",
    category = "dart2js|chrome|w",
    dimensions = windows,
    properties = [chrome, no_android],
)
dart.ci_sandbox_builder(
    "dart2js-nnbd-linux-x64-chrome",
    category = "dart2js|chrome|nn",
    location_regexp = paths.to_location_regexp(paths.dart2js),
    properties = [chrome, no_android],
)
dart.ci_sandbox_builder(
    "dart2js-strong-linux-x64-firefox",
    category = "dart2js|firefox|l",
    properties = [firefox, no_android],
)
dart.ci_sandbox_builder(
    "dart2js-strong-win-x64-firefox",
    category = "dart2js|firefox|w",
    dimensions = windows,
    enabled = False,
    properties = [firefox, no_android],
)
dart.ci_sandbox_builder(
    "dart2js-strong-mac-x64-safari",
    category = "dart2js|safari|m",
    dimensions = mac,
    properties = [pinned_xcode, no_android],
)

# analyzer
dart.ci_sandbox_builder(
    "flutter-analyze",
    category = "analyzer|fa",
    channels = ["try"],
    execution_timeout = 45 * time.minute,
    notifies = None,
)
dart.ci_sandbox_builder(
    "analyzer-analysis-server-linux",
    category = "analyzer|as",
    channels = dart.channels,
    location_regexp = paths.to_location_regexp(paths.analyzer),
)
dart.ci_sandbox_builder(
    "analyzer-linux-release",
    category = "analyzer|l",
    channels = dart.channels,
    location_regexp = paths.to_location_regexp(paths.analyzer),
)
dart.ci_sandbox_builder(
    "analyzer-mac-release",
    category = "analyzer|m",
    channels = dart.channels,
    dimensions = mac,
    properties = pinned_xcode,
)
dart.ci_sandbox_builder(
    "analyzer-win-release",
    category = "analyzer|w",
    channels = dart.channels,
    dimensions = windows,
    experiments = {"dart.use_update_script": 100},
)

# analyzer|nnbd
dart.ci_sandbox_builder(
    "analyzer-nnbd-linux-release",
    category = "analyzer|nnbd|l",
    location_regexp = paths.to_location_regexp(paths.analyzer_nnbd),
    channels = dart.channels,
)
cron.nightly_builder(
    "analyzer-nnbd-mac-release",
    category = "analyzer|nnbd|m",
    channels = ["try"],
    dimensions = mac,
    properties = pinned_xcode,
)
cron.nightly_builder(
    "analyzer-nnbd-win-release",
    category = "analyzer|nnbd|w",
    channels = ["try"],
    dimensions = windows,
)

# sdk
dart.ci_builder(
    "dart-sdk-linux",
    category = "sdk|l",
    channels = dart.channels,
    main_channel = False,
    properties = {
        "$dart/build": {
            "timeout": 100 * 60,  # 100 minutes,
        },
    },
)
dart.ci_builder(
    "dart-sdk-mac",
    category = "sdk|m",
    channels = dart.channels,
    dimensions = mac,
    main_channel = False,
    properties = pinned_xcode,
)
dart.ci_builder(
    "dart-sdk-mac-arm64",
    category = "sdk|m1",
    channels = dart.channels,
    dimensions = [mac, arm64],
    main_channel = False,
    properties = [no_android, pinned_xcode],
)

dart.ci_builder(
    "dart-sdk-win",
    category = "sdk|w",
    channels = dart.channels,
    dimensions = windows,
    main_channel = False,
    on_cq = True,
)

# ddc
dart.ci_sandbox_builder(
    "ddc-linux-release-chrome",
    category = "ddc|l",
    location_regexp = paths.to_location_regexp(paths.ddc),
    properties = chrome,
)
dart.ci_sandbox_builder(
    "ddc-nnbd-linux-release-chrome",
    category = "ddc|nn",
    channels = ["try"],
    location_regexp = paths.to_location_regexp(paths.ddc),
    properties = chrome,
)
dart.ci_sandbox_builder(
    "ddc-mac-release-chrome",
    category = "ddc|m",
    dimensions = mac,
    properties = [chrome, pinned_xcode],
)
dart.ci_sandbox_builder(
    "ddc-win-release-chrome",
    category = "ddc|w",
    dimensions = windows,
    properties = chrome,
)
dart.ci_sandbox_builder(
    "ddk-linux-release-firefox",
    category = "ddc|fl",
    properties = firefox,
)

# misc
dart.ci_sandbox_builder("gclient", recipe = "dart/gclient", category = "misc|g")
dart.ci_builder(
    "debianpackage-linux",
    category = "misc|dp",
    channels = dart.release_channels,
    notifies = "infra",
    properties = {
        "clobber": False,
    },
)

# external
dart.ci_sandbox_builder(
    "google",
    recipe = "dart/external",
    category = "flutter|g3",
    channels = [],
    execution_timeout = 5 * time.minute,
    notifies = None,
    priority = priority.high,
    triggered_by = None,
)

# infra
dart.infra_builder(
    "base",
    execution_timeout = 15 * time.minute,
    recipe = "dart/forward_branch",
    schedule = "with 15m interval",
    notifies = None,
)
dart.infra_builder(
    "cbuild",
    recipe = "dart/cbuild",
    schedule = "with 15m interval",
    execution_timeout = 10 * time.minute,
)
dart.infra_builder("chocolatey", recipe = "dart/chocolatey", dimensions = windows)
dart.infra_builder("co19-roller", recipe = "dart/package_co19")
dart.infra_builder(
    "dart-ci-scripts-linux",
    recipe = "dart/package_dart_ci",
)
dart.infra_builder(
    "dart-ci-scripts-win",
    recipe = "dart/package_dart_ci",
    dimensions = windows,
)
dart.infra_builder(
    "dart-ci-scripts-mac",
    recipe = "dart/package_dart_ci",
    dimensions = mac,
    properties = pinned_xcode,
)
dart.infra_builder(
    "dart-ci-scripts-mac-arm64",
    recipe = "dart/package_dart_ci",
    dimensions = [mac, arm64],
    properties = pinned_xcode,
)
dart.infra_builder(
    "linearize-flutter",
    recipe = "dart/linearize",
    properties = {
        "repo": "https://dart.googlesource.com/linear_sdk_flutter_engine.git",
    },
    notifies = "infra",
    triggered_by = [
        "dart-gitiles-trigger-main",
        "dart-flutter-engine-trigger",
        "dart-flutter-flutter-trigger",
    ],
    triggering_policy = scheduler.greedy_batching(max_batch_size = 1),
)
dart.infra_builder(
    "roll-to-dev",
    bucket = "ci.roll",
    execution_timeout = 15 * time.minute,
    notifies = "infra",
    properties = {"from_ref": "refs/heads/lkgr"},
    recipe = "roller/roll_to_dev",
    schedule = "with 4h interval",
)

# Builder that tests the dev Linux image. When the image autoroller detects
# successful builds of this builder with the dev image, it the current dev image
# becomes the new prod image. Newly created bots will than use the updated
# image. The `vm-precomp-ffi-qemu-linux-release-arm` is  used because qemu is
# the primary difference, it passes all tests, triggers no shards and runs a few
# different builds. See also https://crbug.com/1207358.
cron.nightly_builder(
    "vm-precomp-ffi-qemu-linux-release-arm-experimental",
    channels = [],
    dimensions = {"host_class": "experimental"},
    notifies = "infra",
)

dart.ci_sandbox_builder(
    "ci-test-data",
    channels = [],
    properties = {"bisection_enabled": True},
    notifies = "ci-test-data",
    triggered_by = ["dart-ci-test-data-trigger"],
)

# Fuzz testing builders
dart.ci_sandbox_builder(
    "fuzz-linux",
    channels = [],
    notifies = "dart-fuzz-testing",
    schedule = "0 3,4 * * *",
    triggered_by = None,
)

# Try only builders
dart.try_builder("benchmark-linux", on_cq = True, properties = js_engines)

dart.try_builder(
    "presubmit",
    bucket = "try.shared",
    execution_timeout = 10 * time.minute,
    recipe = "presubmit/presubmit",
)

vm.add_postponed_alt_console_entries()

# Dart Fuzz console
luci.list_view_entry(
    builder = "fuzz-linux",
    list_view = "dart-fuzz",
)

# Flutter consoles
luci.console_view_entry(
    builder = "flutter-analyze",
    short_name = "fa",
    category = "analyzer",
    console_view = "flutter",
)

luci.console_view_entry(
    builder = "flutter-frontend",
    short_name = "fl",
    category = "fasta",
    console_view = "flutter",
)

luci.console_view_entry(
    builder = "flutter-engine-linux",
    short_name = "3H",
    category = "flutter",
    console_view = "flutter-hhh",
)

luci.console_view_entry(
    builder = "flutter-engine-linux-web_tests",
    short_name = "web",
    category = "flutter",
    console_view = "flutter-hhh",
)

# VM isolate stress test console
luci.list_view_entry(
    builder = "iso-stress-linux",
    list_view = "iso-stress",
)

exec("//recipes.star")
