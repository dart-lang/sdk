# Copyright (c) 2023 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines the sdk builders.
"""

load("//lib/dart.star", "dart")
load(
    "//lib/defaults.star",
    "arm64",
    "jammy",
    "mac",
    "no_android",
    "windows",
)
load("//lib/paths.star", "paths")
load("//lib/priority.star", "priority")

def sdk_builder_category():
    """Put the SDK category first on the consoles"""
    for channel, console in [
        ["main", "be"],
        ["main", "alt"],
        ["beta", "beta"],
        ["dev", "dev"],
        ["stable", "stable"],
    ]:
        for builder_type, short_name in [
            ["linux", "l"],
            ["linux-arm64", "la"],
            ["linux-riscv64", "lv"],
            ["mac", "m"],
            ["mac-arm64", "ma"],
            ["win", "w"],
            ["win-arm64", "wa"],
        ]:
            luci.console_view_entry(
                builder = "dart-internal:ci/dart-sdk-%s-%s" %
                          (builder_type, channel),
                short_name = short_name,
                category = "sdk",
                console_view = console,
            )
        luci.console_view_entry(
            builder = "dart-internal:ci/debian-x64-%s" % channel,
            short_name = "dp",
            category = "sdk",
            console_view = console,
        )

sdk_builder_category()

dart.try_builder(
    "dart-sdk-linux",
    properties = {
        "$dart/build": {
            "timeout": 100 * 60,  # 100 minutes,
        },
        "archs": ["ia32", "x64"],
        "dartdoc_arch": "x64",
        "disable_bcid": True,
        "upload_version": True,
    },
    location_filters = paths.to_location_filters(paths.release),
    recipe = "release/sdk",
)

dart.try_builder(
    "dart-sdk-linux-arm64",
    dimensions = [jammy, arm64],
    properties = {
        "archs": ["arm", "arm64"],
        "disable_bcid": True,
    },
    location_filters = paths.to_location_filters(paths.release),
    recipe = "release/sdk",
)

dart.try_builder(
    "dart-sdk-linux-riscv64",
    properties = {
        "$dart/build": {
            "timeout": 120 * 60,  # 120 minutes,
        },
        "archs": ["riscv64"],
        "disable_bcid": True,
    },
    recipe = "release/sdk",
    rbe = False,  # RBE gcc cross-compilation isn't supported yet
)

dart.try_builder(
    "dart-sdk-mac",
    dimensions = [mac, arm64],
    properties = [{"archs": ["x64"], "disable_bcid": True}],
    location_filters = paths.to_location_filters(paths.release),
    recipe = "release/sdk",
)

dart.try_builder(
    "dart-sdk-mac-arm64",
    dimensions = [mac, arm64],
    properties = [
        no_android,
        {"archs": ["arm64"], "disable_bcid": True},
    ],
    location_filters = paths.to_location_filters(paths.release),
    recipe = "release/sdk",
)

dart.try_builder(
    "dart-sdk-win",
    dimensions = windows,
    properties = {"archs": ["ia32", "x64"], "disable_bcid": True},
    recipe = "release/sdk",
)

dart.try_builder(
    "dart-sdk-win-arm64",
    dimensions = windows,
    properties = {"archs": ["arm64"], "disable_bcid": True},
    location_filters = paths.to_location_filters(paths.release),
    recipe = "release/sdk",
)

dart.ci_sandbox_builder(
    "google",
    recipe = "dart/external",
    category = "sdk|g3",
    channels = [],
    execution_timeout = 5 * time.minute,
    notifies = None,
    priority = priority.highest,
    triggered_by = None,
)

# Include a tryjob from dart-internal
luci.cq_tryjob_verifier(
    builder = "dart-internal:g3.dart-internal.try/g3-cbuild-try",
    cq_group = "sdk-main",
)
