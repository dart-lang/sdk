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
    "experimental",
    "focal",
    "js_engines",
    "no_caches",
)

lucicfg.check_version("1.43.13")

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
    title = "Main Console",
    refs = ["refs/heads/main"],
    header = "console-header.textpb",
)

luci.console_view(
    name = "alt",
    repo = "https://dart.googlesource.com/sdk",
    title = "Main Console (VM last)",
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

luci.list_view(
    name = "iso-stress",
    title = "VM Isolate Stress Test Console",
)

luci.gitiles_poller(
    name = "dart-ci-test-data-trigger",
    bucket = "ci",
    path_regexps = ["tools/bots/ci_test_data_trigger"],
    repo = dart.git,
    refs = ["refs/heads/ci-test-data"],
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
    ],
)

luci.notifier(
    name = "dart-fuzz-testing",
    on_success = False,
    on_failure = True,
    notify_emails = ["bkonyi@google.com"],
)

luci.notifier(
    name = "ci-test-data",
    on_success = True,
    on_failure = True,
)

exec("//sdk.star")
exec("//cfe.star")
exec("//dart2wasm.star")
vm = exec("//vm.star")
exec("//pkg.star")
exec("//dart2js.star")
exec("//ddc.star")
exec("//analyzer.star")

# misc
dart.ci_sandbox_builder("gclient", recipe = "dart/gclient", category = "misc|g")

# Builders that test the dev Linux images. When the image autoroller detects
# successful builds of these builders with a dev images, that dev image becomes
# the new prod image. Newly created bots will than use the updated image.
cron.image_builder(
    "vm-ffi-qemu-linux-release-arm-experimental",
    channels = [],
    dimensions = [experimental, focal],
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
dart.try_builder(
    "benchmark-linux",
    cq_branches = ["main"],
    on_cq = True,
    properties = js_engines,
)

dart.try_builder(
    "presubmit",
    bucket = "try.shared",
    caches = no_caches,
    execution_timeout = 10 * time.minute,
    on_cq = True,
    properties = {
        "$depot_tools/presubmit": {
            "runhooks": True,
        },
    },
    recipe = "presubmit/presubmit",
)

vm.add_postponed_alt_console_entries()

# Dart Fuzz console
luci.list_view_entry(
    builder = "fuzz-linux",
    list_view = "dart-fuzz",
)

# VM isolate stress test console
luci.list_view_entry(
    builder = "iso-stress-linux",
    list_view = "iso-stress",
)

dart.try_builder(
    "dev",
    recipe = "release/merge",
    execution_timeout = 15 * time.minute,
    properties = {"from_ref": "refs/heads/lkgr", "to_ref": "refs/heads/dev"},
)

dart.try_builder(
    "beta",
    recipe = "release/merge",
    execution_timeout = 15 * time.minute,
    properties = {"from_ref": "refs/heads/dev", "to_ref": "refs/heads/beta"},
)

dart.try_builder(
    "stable",
    recipe = "release/merge",
    execution_timeout = 15 * time.minute,
    properties = {"from_ref": "refs/heads/beta", "to_ref": "refs/heads/stable"},
)

dart.try_builder(
    "docker",
    recipe = "release/docker",
    # Use a fake stable version since it's only used to detect the channel.
    properties = {"version": "1.2.3"},
    cq_branches = [],
)

dart.try_builder(
    "homebrew",
    recipe = "release/homebrew",
    cq_branches = [],
)

exec("//monorepo.star")
