# Copyright (c) 2022 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines the Dart VM builders.
"""

load("//lib/cron.star", "cron")
load("//lib/dart.star", "dart")
load(
    "//lib/defaults.star",
    "arm64",
    "focal",
    "mac",
    "no_android",
    "slow_shards",
    "windows",
)
load("//lib/paths.star", "paths")
load("//lib/priority.star", "priority")

_postponed_alt_console_entries = []

dart.poller("dart-vm-gitiles-trigger", branches = ["main"], paths = paths.vm)
luci.notifier(
    name = "dart-vm-team",
    on_new_failure = True,
    notify_emails = ["dart-vm-team-breakages@google.com"],
)

def _builder(name, category = None, **kwargs):
    dart.ci_sandbox_builder(name, category = category, **kwargs)
    _postponed_alt_console_entry(name, category)

def _extra_builder(name, on_cq = False, location_filters = None, **kwargs):
    """
    Creates a Dart builder that is only triggered by VM commits.

    Args:
        name: The builder name.
        on_cq: Whether the build is added to the default set of CQ tryjobs.
        location_filters: Locations that trigger this builder.
        **kwargs: Extra arguments are passed on to dart_ci_sandbox_builder.
    """
    triggered_by = ["dart-vm-gitiles-trigger-%s"]
    if on_cq and not location_filters:
        # Don't add extra builders to the default CQ, trigger only on VM paths.
        location_filters = paths.to_location_filters(paths.vm)
        on_cq = False
    _builder(
        name,
        triggered_by = triggered_by,
        on_cq = on_cq,
        location_filters = location_filters,
        **kwargs
    )

def _low_priority_builder(name, **kwargs):
    _extra_builder(
        name,
        channels = ["try"],
        priority = priority.low,
        expiration_timeout = time.day,
        **kwargs
    )

def _nightly_builder(name, category, **kwargs):
    cron.nightly_builder(name, category = category, notifies = "dart-vm-team", **kwargs)
    _postponed_alt_console_entry(name, category)

def _postponed_alt_console_entry(name, category):
    if category:
        console_category, _, short_name = category.rpartition("|")
        _postponed_alt_console_entries.append({
            "builder": name,
            "category": console_category,
            "short_name": short_name,
        })

def add_postponed_alt_console_entries():
    for entry in _postponed_alt_console_entries:
        luci.console_view_entry(console_view = "alt", **entry)

# vm|nnbd|jit
_extra_builder(
    "vm-kernel-nnbd-linux-debug-x64",
    category = "vm|nnbd|jit|d",
    on_cq = True,
)
_extra_builder(
    "vm-kernel-nnbd-linux-release-x64",
    category = "vm|nnbd|jit|r",
    on_cq = True,
)
_nightly_builder(
    "vm-kernel-nnbd-linux-debug-ia32",
    category = "vm|nnbd|jit|d3",
    channels = ["try"],
    properties = slow_shards,
)
_nightly_builder(
    "vm-kernel-nnbd-linux-release-ia32",
    category = "vm|nnbd|jit|r3",
    channels = ["try"],
)
_extra_builder(
    "vm-kernel-nnbd-linux-release-simarm",
    category = "vm|nnbd|jit|ra",
)
_extra_builder(
    "vm-kernel-nnbd-linux-release-simarm64",
    category = "vm|nnbd|jit|ra6",
)
_nightly_builder(
    "vm-kernel-nnbd-mac-debug-arm64",
    category = "vm|nnbd|jit|m1d",
    channels = ["try"],
    dimensions = [mac, arm64],
    properties = [no_android, slow_shards],
)
_builder(
    "vm-kernel-nnbd-mac-debug-x64",
    category = "vm|nnbd|jit|md",
    dimensions = mac,
    properties = slow_shards,
)
_builder(
    "vm-kernel-nnbd-mac-release-arm64",
    category = "vm|nnbd|jit|m1r",
    dimensions = [mac, arm64],
    properties = no_android,
)
_builder(
    "vm-kernel-nnbd-mac-release-x64",
    category = "vm|nnbd|jit|mr",
    dimensions = mac,
)
_nightly_builder(
    "vm-kernel-nnbd-win-release-ia32",
    category = "vm|nnbd|jit|wr3",
    channels = ["try"],
    dimensions = windows,
)
_builder(
    "vm-kernel-nnbd-win-debug-x64",
    category = "vm|nnbd|jit|wd",
    properties = slow_shards,
    dimensions = windows,
)
_builder(
    "vm-kernel-nnbd-win-release-x64",
    category = "vm|nnbd|jit|wr",
    dimensions = windows,
)

# vm|nnbd|aot
_extra_builder(
    "vm-kernel-precomp-nnbd-linux-release-x64",
    category = "vm|nnbd|aot|r",
)
_extra_builder(
    "vm-kernel-precomp-nnbd-linux-debug-simarm_x64",
    category = "vm|nnbd|aot|da",
)
_extra_builder(
    "vm-kernel-precomp-nnbd-linux-release-simarm_x64",
    category = "vm|nnbd|aot|ra",
)
_nightly_builder(
    "vm-kernel-precomp-nnbd-linux-debug-x64",
    category = "vm|nnbd|aot|d",
    channels = ["try"],
    properties = slow_shards,
)
_extra_builder(
    "vm-kernel-precomp-nnbd-linux-release-simarm64",
    category = "vm|nnbd|aot|ra6",
)
_extra_builder(
    "vm-kernel-precomp-nnbd-mac-release-arm64",
    category = "vm|nnbd|aot|m1",
    channels = ["try"],
    dimensions = [mac, arm64],
    properties = [no_android, slow_shards],
)
_extra_builder(
    "vm-kernel-precomp-nnbd-mac-release-simarm64",
    category = "vm|nnbd|aot|ma6",
    dimensions = mac,
    properties = slow_shards,
)
_extra_builder(
    "vm-kernel-precomp-nnbd-win-release-x64",
    category = "vm|nnbd|aot|wr",
    dimensions = windows,
)

# vm|appjit
_extra_builder(
    "vm-appjit-linux-debug-x64",
    category = "vm|appjit|d",
    properties = slow_shards,
)
_extra_builder(
    "vm-appjit-linux-release-x64",
    category = "vm|appjit|r",
)
_nightly_builder(
    "vm-appjit-linux-product-x64",
    category = "vm|appjit|p",
    channels = ["try"],
)

#vm|kernel
_builder("vm-kernel-linux-debug-x64", category = "vm|kernel|d")
_builder(
    "vm-kernel-linux-release-x64",
    category = "vm|kernel|r",
    on_cq = True,
)
_extra_builder(
    "vm-kernel-checked-linux-release-x64",
    category = "vm|kernel|rc",
    experiments = {"dart.use_update_script": 100},
)
_nightly_builder(
    "vm-kernel-win-debug-ia32",
    category = "vm|kernel|wd3",
    channels = ["try"],
    dimensions = windows,
    properties = [slow_shards],
)
_extra_builder(
    "cross-vm-linux-release-arm64",
    category = "vm|kernel|cra",
    channels = [],
    execution_timeout = 4 * time.hour,
    properties = {"shard_timeout": (120 * time.minute) // time.second},
)

# vm|kernel-precomp
_extra_builder(
    "vm-kernel-precomp-linux-debug-x64",
    category = "vm|kernel-precomp|d",
)
_extra_builder(
    "vm-kernel-precomp-linux-release-simarm",
    category = "vm|kernel-precomp|a32",
)
_extra_builder(
    "vm-kernel-precomp-linux-release-x64",
    category = "vm|kernel-precomp|r",
)
_extra_builder(
    "vm-kernel-precomp-obfuscate-linux-release-x64",
    category = "vm|kernel-precomp|o",
)
_nightly_builder(
    "cross-vm-precomp-linux-release-arm64",
    category = "vm|kernel-precomp|cra",
    channels = [],
    properties = slow_shards,
)
_nightly_builder(
    "vm-kernel-precomp-dwarf-linux-product-x64",
    category = "vm|kernel-precomp|dw",
    channels = ["try"],
)

# vm|android
_extra_builder(
    "vm-aot-android-release-arm_x64",
    category = "vm|android|a32",
    properties = slow_shards,
)
_extra_builder(
    "vm-aot-android-release-arm64c",
    category = "vm|android|a64",
    properties = slow_shards,
)

# vm|product
_nightly_builder(
    "vm-aot-linux-product-x64",
    category = "vm|product|l",
    channels = ["try"],
)
_nightly_builder(
    "vm-aot-mac-product-x64",
    category = "vm|product|m",
    channels = ["try"],
    dimensions = mac,
)
_nightly_builder(
    "vm-aot-win-product-x64",
    category = "vm|product|w",
    channels = ["try"],
    dimensions = windows,
)

# vm|misc
_nightly_builder(
    "vm-eager-optimization-linux-release-ia32",
    category = "vm|misc|o32",
    channels = ["try"],
)
_low_priority_builder(
    "vm-eager-optimization-linux-release-x64",
    category = "vm|misc|o64",
)

def dart_vm_sanitizer_builder(name, **kwargs):
    _nightly_builder(
        name,
        channels = ["try"],
        properties = {"bisection_enabled": True},
        **kwargs
    )

dart_vm_sanitizer_builder(
    "vm-asan-linux-release-x64",
    category = "vm|misc|sanitizer|a",
)
dart_vm_sanitizer_builder(
    "vm-msan-linux-release-x64",
    category = "vm|misc|sanitizer|m",
)
dart_vm_sanitizer_builder(
    "vm-tsan-linux-release-x64",
    category = "vm|misc|sanitizer|t",
)
dart_vm_sanitizer_builder(
    "vm-ubsan-linux-release-x64",
    category = "vm|misc|sanitizer|u",
    goma = False,
)  # ubsan is not compatible with our sysroot.
dart_vm_sanitizer_builder(
    "vm-aot-asan-linux-release-x64",
    category = "vm|misc|sanitizer|a",
)
dart_vm_sanitizer_builder(
    "vm-aot-msan-linux-release-x64",
    category = "vm|misc|sanitizer|m",
)
dart_vm_sanitizer_builder(
    "vm-aot-tsan-linux-release-x64",
    category = "vm|misc|sanitizer|t",
)
dart_vm_sanitizer_builder(
    "vm-aot-ubsan-linux-release-x64",
    category = "vm|misc|sanitizer|u",
    goma = False,
)  # ubsan is not compatible with our sysroot.
_nightly_builder(
    "vm-reload-linux-debug-x64",
    category = "vm|misc|reload|d",
    channels = ["try"],
)
_nightly_builder(
    "vm-reload-linux-release-x64",
    category = "vm|misc|reload|r",
    channels = ["try"],
)
_nightly_builder(
    "vm-reload-rollback-linux-debug-x64",
    category = "vm|misc|reload|drb",
    channels = ["try"],
)
_nightly_builder(
    "vm-reload-rollback-linux-release-x64",
    category = "vm|misc|reload|rrb",
    channels = ["try"],
)
_nightly_builder(
    "vm-linux-debug-x64c",
    category = "vm|misc|compressed|jl",
    channels = ["try"],
)
_nightly_builder(
    "vm-aot-linux-debug-x64c",
    category = "vm|misc|compressed|al",
    channels = ["try"],
)
_nightly_builder(
    "vm-win-debug-x64c",
    category = "vm|misc|compressed|jw",
    channels = ["try"],
    dimensions = windows,
)
_nightly_builder(
    "vm-aot-win-debug-x64c",
    category = "vm|misc|compressed|aw",
    channels = ["try"],
    dimensions = windows,
)
_low_priority_builder("vm-fuchsia-release-x64", category = "vm|misc|f")

# Our sysroot does not support gcc, we can't use goma on RBE for this builder
_nightly_builder(
    "vm-kernel-gcc-linux",
    category = "vm|misc|g",
    channels = ["try"],
    execution_timeout = 5 * time.hour,
    goma = False,
    properties = {
        "$dart/build": {
            "timeout": 75 * 60,  # 100 minutes,
        },
    },
)

_nightly_builder(
    "vm-kernel-msvc-windows",
    category = "vm|misc|m",
    channels = ["try"],
    dimensions = windows,
    goma = False,
)

_nightly_builder(
    "vm-kernel-nnbd-linux-debug-simriscv64",
    category = "vm|misc|rv64",
    channels = ["try"],
)
_nightly_builder(
    "vm-kernel-precomp-nnbd-linux-debug-simriscv64",
    category = "vm|misc|rv64",
    channels = ["try"],
    properties = [slow_shards],
)

# vm|ffi
_extra_builder("vm-ffi-android-debug-arm", category = "vm|ffi|d32")
_extra_builder("vm-ffi-android-release-arm", category = "vm|ffi|r32")
_extra_builder("vm-ffi-android-product-arm", category = "vm|ffi|p32")
_extra_builder("vm-ffi-android-debug-arm64c", category = "vm|ffi|d64")
_extra_builder("vm-ffi-android-release-arm64c", category = "vm|ffi|r64")
_extra_builder("vm-ffi-android-product-arm64c", category = "vm|ffi|p64")
_extra_builder(
    "vm-precomp-ffi-qemu-linux-release-arm",
    category = "vm|ffi|qa",
    dimensions = focal,
)
_extra_builder(
    "vm-precomp-ffi-qemu-linux-release-riscv64",
    category = "vm|ffi|qr",
    dimensions = focal,
)

# Isolate stress test builder
_extra_builder(
    "iso-stress-linux",
    channels = [],
    notifies = "dart-vm-team",
    properties = slow_shards,
)
