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
    "android_deps",
    "arm64",
    "flutter_pool",
    "fuchsia_deps",
    "linux",
    "mac",
    "no_reclient",
    "resolute",
    "slow_build",
    "slow_shards",
    "windows",
)
load("//lib/helpers.star", "union")
load("//lib/paths.star", "paths")

_postponed_alt_console_entries = []

dart.poller("dart-vm-gitiles-trigger", branches = ["main"], paths = paths.vm)
luci.notifier(
    name = "dart-vm-team",
    on_new_failure = True,
    notify_emails = ["dart-vm-team-breakages@google.com"],
)

def _vm_builder(name, category = None, on_cq = False, location_filters = None, **kwargs):
    """
    Creates a Dart builder that is only triggered by VM commits.

    Args:
        name: The builder name.
        category: The column heading for the builder on a console.
        on_cq: Whether the build is added to the default set of CQ tryjobs.
        location_filters: Locations that trigger this builder.
        **kwargs: Extra arguments are passed on to dart_ci_sandbox_builder.
    """
    if on_cq and not location_filters:
        # Don't add VM builders to the default CQ, trigger only on VM paths.
        location_filters = paths.to_location_filters(paths.vm)
        on_cq = False
    dart.ci_sandbox_builder(
        name,
        category = category,
        triggered_by = ["dart-vm-gitiles-trigger-%s"],
        on_cq = on_cq,
        location_filters = location_filters,
        **kwargs
    )
    _postponed_alt_console_entry(name, category)

def _nightly_builder(name, category, channels = ["try"], properties = {}, **kwargs):
    properties = union({"bisection_enabled": True}, properties)
    cron.nightly_builder(name, category = category, channels = channels, properties = properties, notifies = "dart-vm-team", **kwargs)
    _postponed_alt_console_entry(name, category)

def _nightly_misc_builder(name, category, channels = ["try"], properties = {}, **kwargs):
    properties = union({"bisection_enabled": True}, properties)
    cron.nightly_builder(
        name,
        category = None,  # Don't add to main console.
        channels = channels,
        properties = properties,
        notifies = "dart-vm-team",
        **kwargs
    )
    console_category, _, short_name = category.rpartition("|")
    luci.console_view_entry(console_view = "misc", builder = name, category = console_category, short_name = short_name)

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

# vm|jit
_vm_builder(
    "vm-linux-debug-x64",
    category = "vm|jit|linux|d",
    on_cq = True,
)
_vm_builder(
    "vm-linux-release-x64",
    category = "vm|jit|linux|r",
)
_nightly_builder(
    "vm-linux-debug-ia32",
    category = "vm|jit|linux|d3",
)
_vm_builder(
    "vm-linux-release-ia32",
    category = "vm|jit|linux|r3",
)
_vm_builder(
    "vm-linux-release-simarm",
    category = "vm|jit|linux|ra",
)
_nightly_builder(
    "vm-linux-debug-simriscv32",
    category = "vm|jit|linux|rv",
)
_vm_builder(
    "vm-linux-debug-simriscv64",
    category = "vm|jit|linux|rv",
)
_nightly_builder(
    "vm-linux-debug-arm64",
    category = "vm|jit|linux|da",
    dimensions = [arm64],
)
_vm_builder(
    "vm-linux-release-arm64",
    category = "vm|jit|linux|ra",
    dimensions = [arm64],
)
_vm_builder(
    "vm-mac-debug-x64",
    category = "vm|jit|mac|d",
    dimensions = mac,
)
_vm_builder(
    "vm-mac-release-x64",
    category = "vm|jit|mac|r",
    dimensions = mac,
)
_nightly_builder(
    "vm-mac-debug-arm64",
    category = "vm|jit|mac|da",
    dimensions = [mac, arm64],
)
_vm_builder(
    "vm-mac-release-arm64",
    category = "vm|jit|mac|ra",
    dimensions = [mac, arm64],
)
_vm_builder(
    "vm-win-debug-x64",
    category = "vm|jit|windows|d",
    dimensions = windows,
)
_vm_builder(
    "vm-win-release-x64",
    category = "vm|jit|windows|r",
    dimensions = windows,
    on_cq = True,
)
_nightly_builder(
    "vm-win-debug-arm64",
    category = "vm|jit|windows|ad",
    dimensions = [windows, arm64, flutter_pool],
    properties = [no_reclient],
)
_vm_builder(
    "vm-win-release-arm64",
    category = "vm|jit|windows|ar",
    dimensions = [windows, arm64, flutter_pool],
    properties = [no_reclient],
)

# vm|appjit
_nightly_builder(
    "vm-appjit-linux-debug-x64",
    category = "vm|appjit|d",
)
_vm_builder(
    "vm-appjit-linux-release-x64",
    category = "vm|appjit|r",
)
_nightly_builder(
    "vm-appjit-linux-product-x64",
    category = "vm|appjit|p",
)

# vm|aot
_nightly_builder(
    "vm-aot-linux-debug-x64",
    category = "vm|aot|linux|d",
)
_vm_builder(
    "vm-aot-linux-release-x64",
    category = "vm|aot|linux|r",
    on_cq = True,
)
_vm_builder(
    "vm-aot-linux-debug-simarm_x64",
    category = "vm|aot|linux|da",
)
_vm_builder(
    "vm-aot-linux-release-simarm_x64",
    category = "vm|aot|linux|ra",
)
_nightly_builder(
    "vm-aot-linux-debug-simriscv32",
    category = "vm|aot|linux|rv",
)
_nightly_builder(
    "vm-aot-linux-debug-simriscv64",
    category = "vm|aot|linux|rv",
)
_nightly_builder(
    "vm-aot-linux-debug-arm64",
    category = "vm|aot|linux|da",
    dimensions = [arm64],
)
_vm_builder(
    "vm-aot-linux-release-arm64",
    category = "vm|aot|linux|ra",
    dimensions = [arm64],
)
_nightly_builder(
    "vm-aot-mac-debug-x64",
    category = "vm|aot|mac|d",
    dimensions = mac,
)
_vm_builder(
    "vm-aot-mac-release-x64",
    category = "vm|aot|mac|r",
    dimensions = mac,
)
_nightly_builder(
    "vm-aot-mac-debug-arm64",
    category = "vm|aot|mac|da",
    dimensions = [mac, arm64],
)
_vm_builder(
    "vm-aot-mac-release-arm64",
    category = "vm|aot|mac|ra",
    dimensions = [mac, arm64],
)
_nightly_builder(
    "vm-aot-win-debug-x64",
    category = "vm|aot|windows|d",
    dimensions = windows,
)
_vm_builder(
    "vm-aot-win-release-x64",
    category = "vm|aot|windows|r",
    dimensions = windows,
)
_nightly_builder(
    "vm-aot-win-debug-arm64",
    category = "vm|aot|windows|ad",
    dimensions = [windows, arm64, flutter_pool],
    properties = [no_reclient],
)
_vm_builder(
    "vm-aot-win-release-arm64",
    category = "vm|aot|windows|ar",
    dimensions = [windows, arm64, flutter_pool],
    properties = [no_reclient],
)

# vm|aot|android
_nightly_builder(
    "vm-aot-android-debug-arm_x64",
    category = "vm|aot|android|d3",
    properties = [android_deps, slow_shards],
)
_vm_builder(
    "vm-aot-android-release-arm_x64",
    category = "vm|aot|android|r3",
    properties = [android_deps, slow_shards],
    location_filters = paths.to_location_filters(paths.android),
)
_nightly_builder(
    "vm-aot-android-debug-arm64c",
    category = "vm|aot|android|d6",
    properties = [android_deps, slow_shards],
)
_vm_builder(
    "vm-aot-android-release-arm64c",
    category = "vm|aot|android|r6",
    properties = [android_deps, slow_shards],
    location_filters = paths.to_location_filters(paths.android),
)
_nightly_builder(
    "vm-aot-android-debug-x64c",
    category = "vm|aot|android|d",
    dimensions = [linux, {"host_class": "virtualization"}],
    properties = [android_deps],
)
_vm_builder(
    "vm-aot-android-release-x64c",
    category = "vm|aot|android|r",
    dimensions = [linux, {"host_class": "virtualization"}],
    properties = [android_deps],
)

# vm|aot|product
_nightly_builder(
    "vm-aot-linux-product-x64",
    category = "vm|aot|product|l",
)
_nightly_builder(
    "vm-aot-mac-product-arm64",
    category = "vm|aot|product|m",
    dimensions = [mac, arm64],
)
_nightly_builder(
    "vm-aot-win-product-x64",
    category = "vm|aot|product|w",
    dimensions = windows,
)

# vm|aot
_nightly_builder(
    "vm-modaot-mac-debug-arm64",
    category = "vm|aot|mod",
    dimensions = [mac, arm64],
    location_filters = paths.to_location_filters(paths.modular_aot),
)

# vm|misc
_vm_builder(
    "vm-aot-dyn-linux-debug-x64",
    category = "vm|misc|dyn|d",
    channels = ["try"],
    location_filters = paths.to_location_filters(paths.dart2bytecode),
)
_vm_builder(
    "vm-aot-dyn-linux-product-x64",
    category = "vm|misc|dyn|p",
    channels = ["try"],
    location_filters = paths.to_location_filters(paths.vm + paths.dart2bytecode),
)
_vm_builder(
    "vm-dyn-linux-debug-x64",
    category = "vm|misc|dyn|j",
    channels = ["try"],
    location_filters = paths.to_location_filters(paths.dart2bytecode),
)
_nightly_builder(
    "vm-dyn-mac-debug-arm64",
    category = "vm|misc|dyn|ja",
    channels = ["try"],
    dimensions = [mac, arm64],
    location_filters = paths.to_location_filters(paths.dart2bytecode),
)

# vm|ffi
_vm_builder(
    "vm-fuchsia-release-arm64",
    category = "vm|ffi|f",
    channels = ["try"],
    properties = [fuchsia_deps],
    location_filters = paths.to_location_filters(paths.fuchsia),
)
_vm_builder(
    "vm-fuchsia-release-x64",
    category = "vm|ffi|f",
    channels = ["try"],
    dimensions = [linux, {"host_class": "virtualization"}],
    properties = [fuchsia_deps],
    location_filters = paths.to_location_filters(paths.fuchsia),
)
_vm_builder(
    "vm-ffi-android-debug-arm",
    category = "vm|ffi|d3",
    properties = [android_deps],
)
_vm_builder(
    "vm-ffi-android-release-arm",
    category = "vm|ffi|r3",
    properties = [android_deps],
)
_vm_builder(
    "vm-ffi-android-product-arm",
    category = "vm|ffi|p3",
    properties = [android_deps],
)
_vm_builder(
    "vm-ffi-android-debug-arm64c",
    category = "vm|ffi|d6",
    properties = [android_deps],
)
_vm_builder(
    "vm-ffi-android-release-arm64c",
    category = "vm|ffi|r6",
    properties = [android_deps],
)
_vm_builder(
    "vm-ffi-android-product-arm64c",
    category = "vm|ffi|p6",
    properties = [android_deps],
)
_vm_builder(
    "vm-ffi-qemu-linux-release-arm",
    category = "vm|ffi|qa",
    dimensions = resolute,
)
_vm_builder(
    "vm-ffi-qemu-linux-release-riscv64",
    category = "vm|ffi|qr",
    dimensions = resolute,
)
_nightly_builder(
    "vm-ffi-mac-debug-simarm64_arm64",
    category = "vm|ffi|ad",
    channels = ["try"],
    dimensions = [mac, arm64],
)
_nightly_builder(
    "vm-ffi-mac-release-simarm64_arm64",
    category = "vm|ffi|ar",
    channels = ["try"],
    dimensions = [mac, arm64],
)
_vm_builder(
    "vm-ffi-dyn-mac-debug-simarm64_arm64",
    category = "vm|ffi|dd",
    channels = ["try"],
    dimensions = [mac, arm64],
)
_nightly_builder(
    "vm-ffi-dyn-mac-release-simarm64_arm64",
    category = "vm|ffi|dr",
    channels = ["try"],
    dimensions = [mac, arm64],
)

# Misc console
_nightly_misc_builder(
    "vm-linux-debug-x64c",
    category = "compressed|jl",
)
_nightly_misc_builder(
    "vm-aot-linux-debug-x64c",
    category = "compressed|al",
)
_nightly_misc_builder(
    "vm-win-debug-x64c",
    category = "compressed|jw",
    dimensions = windows,
)
_nightly_misc_builder(
    "vm-aot-win-debug-x64c",
    category = "compressed|aw",
    dimensions = windows,
)

_nightly_misc_builder(
    "vm-eager-optimization-linux-release-x64",
    category = "misc|e",
)

_nightly_misc_builder(
    "vm-aot-obfuscate-linux-release-x64",
    category = "misc|o",
)
_nightly_misc_builder(
    "vm-aot-dwarf-linux-product-x64",
    category = "misc|dw",
)

_nightly_misc_builder(
    "vm-aot-optimization-level-linux-release-x64",
    category = "misc|a",
)

_nightly_misc_builder(
    "vm-reload-linux-debug-x64",
    category = "reload|d",
)
_nightly_misc_builder(
    "vm-reload-linux-release-x64",
    category = "reload|r",
)

# Isolate stress test builder
_nightly_misc_builder(
    "iso-stress-linux-x64",
    category = "iso-stress|x64",
)
_nightly_misc_builder(
    "iso-stress-linux-arm64",
    category = "iso-stress|arm64",
    dimensions = [arm64],
)

_nightly_misc_builder(
    "vm-asan-linux-release-x64",
    category = "sanitizer|linux|a",
)
_nightly_misc_builder(
    "vm-msan-linux-release-x64",
    category = "sanitizer|linux|m",
)
_nightly_misc_builder(
    "vm-tsan-linux-release-x64",
    category = "sanitizer|linux|t",
)
_nightly_misc_builder(
    "vm-ubsan-linux-release-x64",
    category = "sanitizer|linux|u",
)
_nightly_misc_builder(
    "vm-asan-linux-release-arm64",
    category = "sanitizer|linux|a",
    dimensions = [arm64],
)
_nightly_misc_builder(
    "vm-msan-linux-release-arm64",
    category = "sanitizer|linux|m",
    dimensions = [arm64],
)
_nightly_misc_builder(
    "vm-tsan-linux-release-arm64",
    category = "sanitizer|linux|t",
    dimensions = [arm64],
    properties = [slow_shards],
)
_nightly_misc_builder(
    "vm-ubsan-linux-release-arm64",
    category = "sanitizer|linux|u",
    dimensions = [arm64],
)
_nightly_misc_builder(
    "vm-asan-mac-release-arm64",
    category = "sanitizer|mac|a",
    dimensions = [mac, arm64],
)
_nightly_misc_builder(
    "vm-tsan-mac-release-arm64",
    category = "sanitizer|mac|t",
    dimensions = [mac, arm64],
    properties = [slow_shards],
)
_nightly_misc_builder(
    "vm-ubsan-mac-release-arm64",
    category = "sanitizer|mac|u",
    dimensions = [mac, arm64],
)
_nightly_misc_builder(
    "vm-asan-win-release-x64",
    category = "sanitizer|win|a",
    dimensions = [windows],
)
_nightly_misc_builder(
    "vm-ubsan-win-release-x64",
    category = "sanitizer|win|u",
    dimensions = [windows],
)
_nightly_misc_builder(
    "vm-asan-fuchsia-release-x64",
    category = "sanitizer|fuchsia|a",
    dimensions = [linux, {"host_class": "virtualization"}],
    properties = [fuchsia_deps],
)
_nightly_misc_builder(
    "vm-ubsan-fuchsia-release-x64",
    category = "sanitizer|fuchsia|u",
    dimensions = [linux, {"host_class": "virtualization"}],
    properties = [fuchsia_deps],
)

# Our RBE setup doesn't work with GCC.
_nightly_misc_builder(
    "vm-gcc-linux-debug-x64",
    category = "toolchain|gcc|x64|d",
    dimensions = resolute,
    properties = slow_build,
    rbe = False,
)
_nightly_misc_builder(
    "vm-gcc-linux-release-x64",
    category = "toolchain|gcc|x64|r",
    dimensions = resolute,
    properties = slow_build,
    rbe = False,
)
_nightly_misc_builder(
    "vm-gcc-linux-debug-arm",
    category = "toolchain|gcc|arm|d",
    dimensions = resolute,
    properties = slow_build,
    rbe = False,
)
_nightly_misc_builder(
    "vm-gcc-linux-release-arm",
    category = "toolchain|gcc|arm|r",
    dimensions = resolute,
    properties = slow_build,
    rbe = False,
)
_nightly_misc_builder(
    "vm-gcc-linux-debug-arm64",
    category = "toolchain|gcc|arm64|d",
    dimensions = resolute,
    properties = slow_build,
    rbe = False,
)
_nightly_misc_builder(
    "vm-gcc-linux-release-arm64",
    category = "toolchain|gcc|arm64|r",
    dimensions = resolute,
    properties = slow_build,
    rbe = False,
)
_nightly_misc_builder(
    "vm-gcc-linux-debug-riscv64",
    category = "toolchain|gcc|riscv64|d",
    dimensions = resolute,
    properties = slow_build,
    rbe = False,
)
_nightly_misc_builder(
    "vm-gcc-linux-release-riscv64",
    category = "toolchain|gcc|riscv64|r",
    dimensions = resolute,
    properties = slow_build,
    rbe = False,
)

# Our RBE setup doesn't work with MSVC.
_nightly_misc_builder(
    "vm-msvc-win-debug-x64",
    category = "toolchain|msvc|x64|d",
    dimensions = windows,
    properties = slow_build,
    rbe = False,
)
_nightly_misc_builder(
    "vm-msvc-win-release-x64",
    category = "toolchain|msvc|x64|r",
    dimensions = windows,
    properties = slow_build,
    rbe = False,
)
_nightly_misc_builder(
    "vm-msvc-win-debug-arm64",
    category = "toolchain|msvc|arm64|d",
    dimensions = windows,
    properties = slow_build,
    rbe = False,
)
_nightly_misc_builder(
    "vm-msvc-win-release-arm64",
    category = "toolchain|msvc|arm64|r",
    dimensions = windows,
    properties = slow_build,
    rbe = False,
)
