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
    "mac",
    "no_android",
    "pinned_xcode",
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

def _extra_builder(name, on_cq = False, location_regexp = None, **kwargs):
    """
    Creates a Dart builder that is only triggered by VM commits.

    Args:
        name: The builder name.
        on_cq: Whether the build is added to the default set of CQ tryjobs.
        location_regexp: Locations that trigger this builder.
        **kwargs: Extra arguments are passed on to dart_ci_sandbox_builder.
    """
    triggered_by = ["dart-vm-gitiles-trigger-%s"]
    if on_cq and not location_regexp:
        # Don't add extra builders to the default CQ, trigger only on VM paths.
        location_regexp = paths.to_location_regexp(paths.vm)
        on_cq = False
    _builder(
        name,
        triggered_by = triggered_by,
        on_cq = on_cq,
        location_regexp = location_regexp,
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
_nightly_builder(
    "vm-kernel-nnbd-linux-release-simarm",
    category = "vm|nnbd|jit|ra",
    channels = ["try"],
)
_nightly_builder(
    "vm-kernel-nnbd-linux-release-simarm64",
    category = "vm|nnbd|jit|ra6",
    channels = ["try"],
)
_nightly_builder(
    "vm-kernel-nnbd-mac-debug-arm64",
    category = "vm|nnbd|jit|m1d",
    channels = ["try"],
    dimensions = [mac, arm64],
    properties = [no_android, pinned_xcode, slow_shards],
)
_nightly_builder(
    "vm-kernel-nnbd-mac-debug-x64",
    category = "vm|nnbd|jit|md",
    channels = ["try"],
    dimensions = mac,
    properties = [pinned_xcode, slow_shards],
)
_extra_builder(
    "vm-kernel-nnbd-mac-release-arm64",
    category = "vm|nnbd|jit|m1r",
    channels = ["try"],
    dimensions = [mac, arm64],
    properties = [no_android, pinned_xcode],
)
_nightly_builder(
    "vm-kernel-nnbd-mac-release-x64",
    category = "vm|nnbd|jit|mr",
    channels = ["try"],
    dimensions = mac,
    properties = pinned_xcode,
)
_nightly_builder(
    "vm-kernel-nnbd-win-release-ia32",
    category = "vm|nnbd|jit|wr3",
    channels = ["try"],
    dimensions = windows,
)
_nightly_builder(
    "vm-kernel-nnbd-win-debug-x64",
    category = "vm|nnbd|jit|wd",
    channels = ["try"],
    properties = slow_shards,
    dimensions = windows,
)
_nightly_builder(
    "vm-kernel-nnbd-win-release-x64",
    category = "vm|nnbd|jit|wr",
    channels = ["try"],
    dimensions = windows,
)

# vm|nnbd|aot
_extra_builder(
    "vm-kernel-precomp-nnbd-linux-release-x64",
    category = "vm|nnbd|aot|r",
)
_nightly_builder(
    "vm-kernel-precomp-nnbd-linux-debug-simarm_x64",
    category = "vm|nnbd|aot|da",
    channels = ["try"],
)
_nightly_builder(
    "vm-kernel-precomp-nnbd-linux-release-simarm_x64",
    category = "vm|nnbd|aot|ra",
    channels = ["try"],
)
_nightly_builder(
    "vm-kernel-precomp-nnbd-linux-debug-x64",
    category = "vm|nnbd|aot|d",
    channels = ["try"],
    properties = slow_shards,
)
_nightly_builder(
    "vm-kernel-precomp-nnbd-linux-release-simarm64",
    category = "vm|nnbd|aot|ra6",
    channels = ["try"],
)
_extra_builder(
    "vm-kernel-precomp-nnbd-mac-release-arm64",
    category = "vm|nnbd|aot|m1",
    channels = ["try"],
    dimensions = [mac, arm64],
    properties = [no_android, pinned_xcode, slow_shards],
)
_nightly_builder(
    "vm-kernel-precomp-nnbd-mac-release-simarm64",
    category = "vm|nnbd|aot|ma6",
    channels = ["try"],
    dimensions = mac,
    properties = [pinned_xcode, slow_shards],
)
_nightly_builder(
    "vm-kernel-precomp-nnbd-win-release-x64",
    category = "vm|nnbd|aot|wr",
    channels = ["try"],
    dimensions = windows,
)

# vm|app-kernel
_extra_builder(
    "app-kernel-linux-debug-x64",
    category = "vm|app-kernel|d64",
    properties = slow_shards,
)
_nightly_builder(
    "app-kernel-linux-product-x64",
    category = "vm|app-kernel|p64",
    channels = ["try"],
)
_extra_builder(
    "app-kernel-linux-release-x64",
    category = "vm|app-kernel|r64",
)

#vm|kernel
_extra_builder(
    "vm-canary-linux-debug",
    category = "vm|kernel|c",
    on_cq = True,
)
_builder("vm-kernel-linux-debug-x64", category = "vm|kernel|d")
_extra_builder(
    "vm-kernel-linux-release-simarm",
    category = "vm|kernel|a32",
)
_extra_builder(
    "vm-kernel-linux-release-simarm64",
    category = "vm|kernel|a64",
)
_nightly_builder(
    "vm-kernel-linux-release-ia32",
    category = "vm|kernel|r32",
    channels = ["try"],
)
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
    "vm-kernel-linux-debug-ia32",
    category = "vm|kernel|d32",
    channels = ["try"],
)
_builder(
    "vm-kernel-mac-debug-x64",
    category = "vm|kernel|md",
    dimensions = mac,
    properties = pinned_xcode,
)
_builder(
    "vm-kernel-mac-release-x64",
    category = "vm|kernel|mr",
    dimensions = mac,
    on_cq = True,
    experiment_percentage = 5,
    properties = pinned_xcode,
)
_builder(
    "vm-kernel-mac-release-arm64",
    category = "vm|kernel|m1r",
    channels = ["try", "dev"],
    dimensions = [mac, arm64],
    properties = [no_android, pinned_xcode],
)
_nightly_builder(
    "vm-kernel-win-debug-ia32",
    category = "vm|kernel|wd3",
    channels = ["try"],
    dimensions = windows,
)
_builder(
    "vm-kernel-win-debug-x64",
    category = "vm|kernel|wd",
    dimensions = windows,
)
_nightly_builder(
    "vm-kernel-win-release-ia32",
    category = "vm|kernel|wr3",
    channels = ["try"],
    dimensions = windows,
)
_builder(
    "vm-kernel-win-release-x64",
    category = "vm|kernel|wr",
    dimensions = windows,
)
_extra_builder(
    "cross-vm-linux-release-arm64",
    category = "vm|kernel|cra",
    channels = [],
    properties = {"shard_timeout": (120 * time.minute) // time.second},
)

# vm|kernel-precomp
_extra_builder(
    "vm-kernel-precomp-linux-debug-x64",
    category = "vm|kernel-precomp|d",
)
_extra_builder(
    "vm-kernel-precomp-linux-product-x64",
    category = "vm|kernel-precomp|p",
)
_extra_builder(
    "vm-kernel-precomp-linux-release-simarm",
    category = "vm|kernel-precomp|a32",
)
_extra_builder(
    "vm-kernel-precomp-linux-release-simarm64",
    category = "vm|kernel-precomp|a64",
)
_extra_builder(
    "vm-kernel-precomp-linux-release-x64",
    category = "vm|kernel-precomp|r",
)
_extra_builder(
    "vm-kernel-precomp-obfuscate-linux-release-x64",
    category = "vm|kernel-precomp|o",
)
_extra_builder(
    "vm-kernel-precomp-linux-debug-simarm_x64",
    category = "vm|kernel-precomp|adx",
    properties = slow_shards,
)
_extra_builder(
    "vm-kernel-precomp-linux-release-simarm_x64",
    category = "vm|kernel-precomp|arx",
)
_extra_builder(
    "vm-kernel-precomp-mac-release-simarm64",
    category = "vm|kernel-precomp|ma",
    dimensions = mac,
    properties = pinned_xcode,
)
_extra_builder(
    "vm-kernel-precomp-win-release-x64",
    category = "vm|kernel-precomp|wr",
    dimensions = windows,
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

# vm|kernel-precomp|android
_extra_builder(
    "vm-kernel-precomp-android-release-arm_x64",
    category = "vm|kernel-precomp|android|a32",
    properties = slow_shards,
)
_extra_builder(
    "vm-kernel-precomp-android-release-arm64c",
    category = "vm|kernel-precomp|android|a64",
    properties = slow_shards,
)

# vm|product
_nightly_builder(
    "vm-kernel-linux-product-x64",
    category = "vm|product|l",
    channels = ["try"],
)
_nightly_builder(
    "vm-kernel-mac-product-x64",
    category = "vm|product|m",
    channels = ["try"],
    dimensions = mac,
    properties = pinned_xcode,
)
_nightly_builder(
    "vm-kernel-win-product-x64",
    category = "vm|product|w",
    channels = ["try"],
    dimensions = windows,
)

# vm|misc
_nightly_builder(
    "vm-kernel-optcounter-threshold-linux-release-ia32",
    category = "vm|misc|o32",
    channels = ["try"],
)
_low_priority_builder(
    "vm-kernel-optcounter-threshold-linux-release-x64",
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
    "vm-kernel-asan-linux-release-x64",
    category = "vm|misc|a",
)
dart_vm_sanitizer_builder(
    "vm-kernel-msan-linux-release-x64",
    category = "vm|misc|m",
)
dart_vm_sanitizer_builder(
    "vm-kernel-tsan-linux-release-x64",
    category = "vm|misc|t",
)
dart_vm_sanitizer_builder(
    "vm-kernel-ubsan-linux-release-x64",
    category = "vm|misc|u",
    goma = False,
)  # ubsan is not compatible with our sysroot.
dart_vm_sanitizer_builder(
    "vm-kernel-precomp-asan-linux-release-x64",
    category = "vm|misc|aot|a",
)
dart_vm_sanitizer_builder(
    "vm-kernel-precomp-msan-linux-release-x64",
    category = "vm|misc|aot|m",
)
dart_vm_sanitizer_builder(
    "vm-kernel-precomp-tsan-linux-release-x64",
    category = "vm|misc|aot|t",
)
dart_vm_sanitizer_builder(
    "vm-kernel-precomp-ubsan-linux-release-x64",
    category = "vm|misc|aot|u",
    goma = False,
)  # ubsan is not compatible with our sysroot.
_nightly_builder(
    "vm-kernel-reload-linux-debug-x64",
    category = "vm|misc|reload|d",
    channels = ["try"],
)
_nightly_builder(
    "vm-kernel-reload-linux-release-x64",
    category = "vm|misc|reload|r",
    channels = ["try"],
)
_nightly_builder(
    "vm-kernel-reload-rollback-linux-debug-x64",
    category = "vm|misc|reload|drb",
    channels = ["try"],
)
_nightly_builder(
    "vm-kernel-reload-rollback-linux-release-x64",
    category = "vm|misc|reload|rrb",
    channels = ["try"],
)
_nightly_builder(
    "vm-kernel-linux-debug-x64c",
    category = "vm|misc|compressed|jl",
    channels = ["try"],
)
_nightly_builder(
    "vm-kernel-precomp-linux-debug-x64c",
    category = "vm|misc|compressed|al",
    channels = ["try"],
)
_nightly_builder(
    "vm-kernel-win-debug-x64c",
    category = "vm|misc|compressed|jw",
    channels = ["try"],
    dimensions = windows,
)
_nightly_builder(
    "vm-kernel-precomp-win-debug-x64c",
    category = "vm|misc|compressed|aw",
    channels = ["try"],
    dimensions = windows,
)
_low_priority_builder("vm-fuchsia-release-x64", category = "vm|misc|f")

# Our sysroot does not support gcc, we can't use goma on RBE for this builder
_nightly_builder("vm-kernel-gcc-linux", category = "vm|misc|g", goma = False)

_nightly_builder(
    "vm-kernel-linux-debug-simriscv64",
    category = "vm|misc|rv64",
    channels = ["try"],
)
_nightly_builder(
    "vm-kernel-precomp-linux-debug-simriscv64",
    category = "vm|misc|rv64",
    channels = ["try"],
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
)
_extra_builder(
    "vm-precomp-ffi-qemu-linux-release-riscv64",
    category = "vm|ffi|qr",
)

# Isolate stress test builder
_extra_builder(
    "iso-stress-linux",
    channels = [],
    notifies = "dart-vm-team",
)
