#!/usr/bin/env lucicfg

# Copyright (c) 2019 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Use ./main.star to regenerate the Luci configuration based on this file.
#
# Documentation for lucicfg is here:
# https://chromium.googlesource.com/infra/luci/luci-go/+/master/lucicfg/doc/

load("//defaults.star", "defaults")

lucicfg.check_version('1.15.0')

DART_GIT = "https://dart.googlesource.com/sdk"
DART_GERRIT = "https://dart-review.googlesource.com/"

GOMA_RBE = {
    "enable_ats": True,
    "server_host": "goma.chromium.org",
    "use_luci_auth": True
}

RELEASE_CHANNELS = ["beta", "dev", "stable"]
CHANNELS = RELEASE_CHANNELS + ["try"]
BRANCHES = ["master"] + RELEASE_CHANNELS

TEST_PY_PATHS = "pkg/(async_helper|expect|smith|status_file|test_runner)/.+"

STANDARD_PATHS = [
    "DEPS",  # DEPS catches most third_party changes.
    # build files
    "build/.+",
    "BUILD.gn",
    "sdk_args.gni",
    # core libraries
    "sdk(_nnbd)?/.+",
    # testing
    TEST_PY_PATHS,
    "tools/bots/test_matrix.json",
    # tests
    "tests/.+",
]

CFE_PATHS = STANDARD_PATHS + [
    "pkg/(front_end|kernel|testing|_fe_analyzer_shared)/.+",
]

VM_PATHS = CFE_PATHS + [
    # VM sources
    "pkg/vm/.+",
    "runtime/.+",
]

DART2JS_PATHS = CFE_PATHS + [
    # compiler sources
    "pkg/(compiler|dart2js_tools|js_ast)/.+",
    "utils/compiler/.+",
    # testing
    "pkg/(js|modular_test|sourcemap_testing)/.+",
]

DDC_PATHS = CFE_PATHS + [
    # compiler sources
    "pkg/(build_integration|dev_compiler|meta)/.+",
    "utils/dartdevc/.+",
    # testing
    "pkg/(js|modular_test|sourcemap_testing)/.+",
]

ANALYZER_NNBD_PATHS = STANDARD_PATHS + [
    # analyzer sources
    "pkg/(analyzer|analyzer_cli|_fe_analyzer_shared)/.+",
]

ANALYZER_PATHS = STANDARD_PATHS + [
    # "analyzer" bots analyze everything under pkg
    "pkg/.+",
]

# Priorities used by the swarming scheduler. The higher the number, the lower
# the priority.
LOW = 70  # Used for "FYI" post-submit builds.
NORMAL = 50  # Used for post-submit builds.
HIGH = 30  # Used for try-jobs.
HIGHEST = 25  # Used for shards in the recipes, included here for completeness.


def to_location_regexp(paths):
    return [".+/[+]/%s" % path for path in paths]


def mac():
    return {"os": "Mac"}


def windows():
    return {"os": "Windows"}


CI_ACCOUNT = "dart-luci-ci-builder@dart-ci.iam.gserviceaccount.com"
TRY_ACCOUNT = "dart-luci-try-builder@dart-ci.iam.gserviceaccount.com"
CI_TRIGGERERS = ["luci-scheduler@appspot.gserviceaccount.com", CI_ACCOUNT]
CI_SANDBOX_TRIGGERERS = CI_TRIGGERERS + [TRY_ACCOUNT]

lucicfg.config(
    config_dir=".",
    tracked_files=[
        "commit-queue.cfg",
        "cr-buildbucket.cfg",
        "luci-logdog.cfg",
        "luci-milo.cfg",
        "luci-notify.cfg",
        "luci-scheduler.cfg",
        "project.cfg",
    ],
)

luci.project(
    name="dart",
    buildbucket="cr-buildbucket.appspot.com",
    logdog="luci-logdog.appspot.com",
    milo="luci-milo.appspot.com",
    notify="luci-notify.appspot.com",
    scheduler="luci-scheduler.appspot.com",
    swarming="chromium-swarm.appspot.com",
    acls=[
        acl.entry(
            [
                acl.BUILDBUCKET_READER, acl.LOGDOG_READER,
                acl.PROJECT_CONFIGS_READER, acl.SCHEDULER_READER
            ],
            groups=["all"],
        ),
        acl.entry(acl.LOGDOG_WRITER, groups=["luci-logdog-chromium-writers"]),
        acl.entry([acl.SCHEDULER_OWNER, acl.BUILDBUCKET_TRIGGERER],
                  groups=["project-dart-admins"]),
        acl.entry(acl.CQ_COMMITTER, groups=["project-dart-committers"]),
        acl.entry(acl.CQ_DRY_RUNNER, groups=["project-dart-tryjob-access"]),
    ],
)

luci.milo(
    logo="https://storage.googleapis.com/chrome-infra-public/logo/dartlang.png",
)

luci.console_view(
    name="be",
    repo="https://dart.googlesource.com/sdk",
    title="SDK Bleeding Edge Console",
    refs=["refs/heads/master"],
    header="console-header.textpb",
)

luci.console_view(
    name="alt",
    repo="https://dart.googlesource.com/sdk",
    title="SDK Bleeding Edge Console (alternative)",
    refs=["refs/heads/master"],
    header="console-header.textpb",
)

luci.console_view(
    name="dev",
    repo="https://dart.googlesource.com/sdk",
    title="SDK Dev Console",
    refs=["refs/heads/dev"],
    header="console-header.textpb",
)

luci.console_view(
    name="beta",
    repo="https://dart.googlesource.com/sdk",
    title="SDK Beta Console",
    refs=["refs/heads/beta"],
    header="console-header.textpb",
)

luci.console_view(
    name="stable",
    repo="https://dart.googlesource.com/sdk",
    title="SDK Stable Console",
    refs=["refs/heads/stable"],
    header="console-header.textpb",
)

luci.console_view(
    name="flutter",
    repo=DART_GIT,
    title="Dart/Flutter Console",
    refs=["refs/heads/master"],
)

luci.console_view(
    name="flutter-hhh",
    repo="https://dart.googlesource.com/linear_sdk_flutter_engine",
    title="Dart/Flutter Linear History Console",
    refs=["refs/heads/master"],
)

luci.console_view(
    name="fyi",
    repo=DART_GIT,
    title="SDK FYI Console",
    refs=["refs/heads/master"],
)

luci.list_view(
    name="cq",
    title="SDK CQ Console",
)

luci.list_view(
    name="infra",
    title="Infra Console",
)

luci.logdog(gs_bucket="chromium-luci-logdog")

luci.bucket(
    name="ci",
    acls=[
        acl.entry(acl.BUILDBUCKET_TRIGGERER, users=CI_TRIGGERERS),
    ],
)
luci.bucket(
    name="ci.sandbox",
    acls=[
        acl.entry(acl.BUILDBUCKET_TRIGGERER, users=CI_SANDBOX_TRIGGERERS),
    ],
)
TRY_ACLS=[
    acl.entry(
        acl.BUILDBUCKET_TRIGGERER,
        groups=["project-dart-tryjob-access", "service-account-cq"]),
]
luci.bucket(name="try", acls=TRY_ACLS) # Tryjobs specific to the Dart SDK repo.
luci.bucket(name="try.shared", acls=TRY_ACLS) # Tryjobs for all repos.

luci.gitiles_poller(
    name="dart-gitiles-trigger-flutter",
    bucket="ci",
    repo="https://dart.googlesource.com/linear_sdk_flutter_engine/",
    refs=["refs/heads/master"],
)


def dart_poller(name, bucket="ci", branches=BRANCHES, paths=None):
    for branch in branches:
        luci.gitiles_poller(
            name="%s-%s" % (name, branch),
            bucket=bucket,
            path_regexps=paths,
            repo=DART_GIT,
            refs=["refs/heads/%s" % branch],
        )


dart_poller("dart-gitiles-trigger", branches=BRANCHES)
dart_poller("dart-vm-gitiles-trigger", branches=["master"], paths=VM_PATHS)

luci.gitiles_poller(
    name="dart-flutter-engine-trigger",
    bucket="ci",
    repo="https://dart.googlesource.com/external/github.com/flutter/engine",
    refs=["refs/heads/master"],
)

luci.gitiles_poller(
    name="dart-flutter-flutter-trigger",
    bucket="ci",
    repo="https://dart.googlesource.com/external/github.com/flutter/flutter",
    refs=["refs/heads/master"],
)

luci.notifier(
    name="infra",
    on_new_failure=True,
    notify_emails=[
        "athom@google.com", "sortie@google.com", "whesse@google.com"
    ])

luci.notifier(
    name="dart",
    on_new_failure=True,
    notify_emails=["athom@google.com"],
    notify_blamelist=True)

luci.notifier(
    name="dart-fuzz-testing",
    on_success=True,
    on_failure=True,
    notify_emails=["ajcbik@google.com", "athom@google.com"])

luci.notifier(
    name="frontend-team", on_failure=True, notify_emails=["jensj@google.com"])

luci.cq(
    submit_max_burst=2,
    submit_burst_delay=8 * time.minute,
)

luci.cq_group(
    name="sdk",
    watch=cq.refset(
        DART_GERRIT + "sdk", refs=["refs/heads/%s" % branch for branch in BRANCHES]),
    allow_submit_with_open_deps=True,
    tree_status_host="dart-status.appspot.com",
    retry_config=cq.RETRY_NONE,
    verifiers=None,
)

luci.cq_group(
    name="sdk-infra-config",
    watch=cq.refset(DART_GERRIT + "sdk", refs=["refs/heads/infra/config"]),
    allow_submit_with_open_deps=True,
    tree_status_host="dart-status.appspot.com",
    retry_config=cq.RETRY_NONE,
    verifiers=None,
)

luci.cq_group(
    name="recipes",
    watch=cq.refset(
        DART_GERRIT + "recipes", refs=["refs/heads/master"]),
    allow_submit_with_open_deps=True,
    tree_status_host="dart-status.appspot.com",
    retry_config=cq.RETRY_NONE,
    verifiers=None,
)

luci.cq_group(
    name="dart_ci",
    watch=cq.refset(
        DART_GERRIT + "dart_ci", refs=["refs/heads/master"]),
    allow_submit_with_open_deps=True,
    tree_status_host="dart-status.appspot.com",
    retry_config=cq.RETRY_NONE,
    verifiers=None,
)


def dart_recipe(name):
    return luci.recipe(
        name=name,
        cipd_package="dart/recipe_bundles/dart.googlesource.com/recipes",
    )


def use_goma_rbe(goma_rbe, dimensions):
    if goma_rbe == None:
        return dimensions["os"] == "Linux"
    return goma_rbe


def dart_try_builder(name,
                     recipe="dart/neo",
                     bucket="try",
                     dimensions=None,
                     execution_timeout=None,
                     experiment_percentage=None,
                     goma_rbe=None,
                     location_regexp=None,
                     properties=None,
                     on_cq=False):
    if on_cq and location_regexp:
        fail("Can't be on the default CQ and conditionally on the CQ")
    dimensions = defaults.dimensions(dimensions)
    dimensions["pool"] = "luci.dart.try"
    properties = defaults.properties(properties)
    if use_goma_rbe(goma_rbe, dimensions):
        properties.setdefault("$build/goma", GOMA_RBE)
    builder = name + "-try"

    luci.builder(
        name=builder,
        build_numbers=True,
        bucket=bucket,
        caches=[swarming.cache("browsers")],
        dimensions=dimensions,
        executable=dart_recipe(recipe),
        execution_timeout=execution_timeout,
        priority=HIGH,
        properties=properties,
        service_account=TRY_ACCOUNT,
        swarming_tags=["vpython:native-python-wrapper"],
    )
    includable_only = (not on_cq and not experiment_percentage and
                       not location_regexp)
    luci.cq_tryjob_verifier(
        builder=builder,
        cq_group="sdk",
        experiment_percentage=experiment_percentage,
        location_regexp=location_regexp,
        includable_only=includable_only)
    luci.list_view_entry(list_view="cq", builder=builder)


postponed_alt_console_entries = []

# Global builder defaults
luci.builder.defaults.properties.set({
    "$recipe_engine/isolated": {
        "server": "https://isolateserver.appspot.com"
    },
    "$recipe_engine/swarming": {
        "server": "https://chromium-swarm.appspot.com"
    },
})


def dart_builder(name,
                 bucket,
                 recipe="dart/neo",
                 enabled=True,
                 category=None,
                 channels=[],
                 dimensions=None,
                 executable=None,
                 execution_timeout=None,
                 expiration_timeout=None,
                 goma_rbe=None,
                 fyi=False,
                 notifies="dart",
                 priority=NORMAL,
                 properties=None,
                 schedule="triggered",
                 service_account=TRY_ACCOUNT,
                 triggered_by=["dart-gitiles-trigger-%s"],
                 triggering_policy=None,
                 on_cq=False,
                 experiment_percentage=None,
                 location_regexp=None):
    dimensions = defaults.dimensions(dimensions)
    properties = defaults.properties(properties)
    if use_goma_rbe(goma_rbe, dimensions):
        properties.setdefault("$build/goma", GOMA_RBE)

    def builder(channel, triggered_by):
        if channel == "try":
            dart_try_builder(
                name,
                recipe=recipe,
                dimensions=dimensions,
                properties=properties,
                on_cq=on_cq,
                execution_timeout=execution_timeout,
                experiment_percentage=experiment_percentage,
                goma_rbe=goma_rbe,
                location_regexp=location_regexp)
        else:
            builder = name + "-" + channel if channel else name
            branch = channel if channel else "master"
            if schedule == "triggered" and triggered_by:
                triggered_by = [
                    trigger.replace("%s", branch) for trigger in triggered_by
                ]
                if channel in RELEASE_CHANNELS:
                    # Always run vm builders on release channels.
                    triggered_by = [
                        trigger.replace("dart-vm-", "dart-")
                        for trigger in triggered_by
                    ]
            luci.builder(
                name=builder,
                build_numbers=True,
                bucket=bucket,
                caches=[swarming.cache("browsers")],
                dimensions=dimensions,
                executable=executable or dart_recipe(recipe),
                execution_timeout=execution_timeout,
                expiration_timeout=expiration_timeout,
                priority=priority,
                properties=properties,
                notifies=[notifies]
                if notifies and not channel and enabled else None,
                schedule=schedule if enabled else None,
                service_account=service_account,
                swarming_tags=["vpython:native-python-wrapper"],
                triggered_by=triggered_by if enabled else None,
                triggering_policy=triggering_policy)
            if category:
                console_category, _, short_name = category.rpartition("|")
                toplevel_category, _, _ = console_category.partition("|")
                console = channel or "be" if not fyi else "fyi"
                luci.console_view_entry(
                    builder=builder,
                    short_name=short_name,
                    category=console_category,
                    console_view=console,
                )
                if console == "be":
                    if toplevel_category == "vm":
                        postponed_alt_console_entries.append({
                            "builder": builder,
                            "short_name": short_name,
                            "category": console_category,
                        })
                    else:
                        luci.console_view_entry(
                            builder=builder,
                            short_name=short_name,
                            category=console_category,
                            console_view="alt",
                        )

    builder(None, triggered_by=triggered_by)
    for channel in channels:
        if enabled:
            builder(channel, triggered_by=triggered_by)


def dart_ci_builder(name, dimensions={}, **kwargs):
    dimensions.setdefault("pool", "luci.dart.ci")
    dart_builder(
        name,
        bucket="ci",
        dimensions=dimensions,
        service_account=CI_ACCOUNT,
        **kwargs)


def dart_ci_sandbox_builder(name, channels=CHANNELS, **kwargs):
    dart_builder(
        name,
        bucket="ci.sandbox",
        channels=channels,
        service_account=TRY_ACCOUNT,
        **kwargs)


def dart_infra_builder(name, notifies="infra", triggered_by=None, **kwargs):
    dart_ci_builder(
        name, notifies=notifies, triggered_by=triggered_by, **kwargs)
    luci.list_view_entry(list_view="infra", builder=name)


def dart_vm_extra_builder(name, on_cq=False, location_regexp=None, **kwargs):
    triggered_by = ["dart-vm-gitiles-trigger-%s"]
    if on_cq and not location_regexp:
        location_regexp = to_location_regexp(VM_PATHS)
        on_cq = False
    dart_ci_sandbox_builder(
        name,
        triggered_by=triggered_by,
        on_cq=on_cq,
        location_regexp=location_regexp,
        **kwargs)


def dart_vm_low_priority_builder(name, **kwargs):
    dart_vm_extra_builder(
        name, channels=["try"], priority=LOW, expiration_timeout=time.day, **kwargs)


nightly_builders = []


def dart_vm_nightly_builder(name, **kwargs):
    dart_ci_sandbox_builder(
        name,
        notifies=None,
        on_cq=False,
        priority=LOW,
        schedule="triggered",  # triggered by nightly cron builder
        triggered_by=None,
        **kwargs)
    nightly_builders.append(name)


# cfe
dart_ci_sandbox_builder(
    "front-end-linux-release-x64", category="cfe|l", on_cq=True)
dart_ci_sandbox_builder(
    "front-end-mac-release-x64", category="cfe|m", dimensions=mac())
dart_ci_sandbox_builder(
    "front-end-win-release-x64", category="cfe|w", dimensions=windows())
dart_ci_sandbox_builder(
    "front-end-nnbd-linux-release-x64",
    category="cfe|nn",
    location_regexp=to_location_regexp(CFE_PATHS))
dart_ci_sandbox_builder(
    "flutter-frontend",
    category="cfe|fl",
    channels=["try"],
    notifies="frontend-team")

# flutter
dart_ci_sandbox_builder(
    "flutter-engine-linux",
    recipe="dart/flutter_engine",
    category="flutter|3H",
    channels=["try"],
    execution_timeout=8 * time.hour,
    triggered_by=["dart-gitiles-trigger-flutter"],
)

# vm|nnbd
dart_vm_extra_builder(
    "vm-kernel-nnbd-linux-debug-x64", category="vm|nnbd|d", on_cq=True)
dart_vm_extra_builder(
    "vm-kernel-nnbd-linux-release-x64", category="vm|nnbd|r", on_cq=True)
dart_vm_extra_builder(
    "vm-kernel-precomp-nnbd-linux-release-x64", category="vm|nnbd|pr")

# vm|app-kernel
dart_vm_extra_builder(
    "app-kernel-linux-debug-x64", category="vm|app-kernel|d64")
dart_vm_extra_builder(
    "app-kernel-linux-product-x64", category="vm|app-kernel|p64")
dart_vm_extra_builder(
    "app-kernel-linux-release-x64", category="vm|app-kernel|r64")

# vm|dartkb
dart_vm_extra_builder(
    "vm-dartkb-linux-release-simarm64", category="vm|dartkb|sr")
dart_vm_extra_builder("vm-dartkb-linux-release-x64", category="vm|dartkb|r")
dart_vm_extra_builder(
    "vm-dartkb-linux-release-x64-abi", category="vm|dartkb|abi")

#vm|kernel
dart_vm_extra_builder(
    "vm-canary-linux-debug", category="vm|kernel|c", on_cq=True)
dart_ci_sandbox_builder("vm-kernel-linux-debug-x64", category="vm|kernel|d")
dart_vm_extra_builder(
    "vm-kernel-linux-release-simarm", category="vm|kernel|a32")
dart_vm_extra_builder(
    "vm-kernel-linux-release-simarm64", category="vm|kernel|a64")
dart_vm_extra_builder("vm-kernel-linux-release-ia32", category="vm|kernel|r32")
dart_ci_sandbox_builder(
    "vm-kernel-linux-release-x64", category="vm|kernel|r", on_cq=True)
dart_vm_extra_builder(
    "vm-kernel-checked-linux-release-x64", category="vm|kernel|rc")
dart_vm_extra_builder("vm-kernel-linux-debug-ia32", category="vm|kernel|d32")
dart_ci_sandbox_builder(
    "vm-kernel-mac-debug-x64", category="vm|kernel|md", dimensions=mac())
dart_ci_sandbox_builder(
    "vm-kernel-mac-release-x64",
    category="vm|kernel|mr",
    dimensions=mac(),
    on_cq=True,
    experiment_percentage=5)
dart_vm_extra_builder(
    "vm-kernel-win-debug-ia32", category="vm|kernel|wd3", dimensions=windows())
dart_ci_sandbox_builder(
    "vm-kernel-win-debug-x64", category="vm|kernel|wd", dimensions=windows())
dart_vm_extra_builder(
    "vm-kernel-win-release-ia32",
    category="vm|kernel|wr3",
    dimensions=windows())
dart_ci_sandbox_builder(
    "vm-kernel-win-release-x64", category="vm|kernel|wr", dimensions=windows())
dart_vm_extra_builder(
    "cross-vm-linux-release-arm64",
    category="vm|kernel|cra",
    channels=RELEASE_CHANNELS,
    properties={"shard_timeout": (90 * time.minute) / time.second})

# vm|kernel-precomp
dart_vm_extra_builder(
    "vm-kernel-precomp-linux-debug-x64", category="vm|kernel-precomp|d")
dart_vm_extra_builder(
    "vm-kernel-precomp-linux-product-x64", category="vm|kernel-precomp|p")
dart_vm_extra_builder(
    "vm-kernel-precomp-linux-release-simarm", category="vm|kernel-precomp|a32")
dart_vm_extra_builder(
    "vm-kernel-precomp-linux-release-simarm64",
    category="vm|kernel-precomp|a64")
dart_vm_extra_builder(
    "vm-kernel-precomp-linux-release-x64", category="vm|kernel-precomp|r")
dart_vm_extra_builder(
    "vm-kernel-precomp-obfuscate-linux-release-x64",
    category="vm|kernel-precomp|o")
dart_vm_extra_builder(
    "vm-kernel-precomp-linux-debug-simarm_x64",
    category="vm|kernel-precomp|adx",
    properties={"shard_timeout": (90 * time.minute) / time.second})
dart_vm_extra_builder(
    "vm-kernel-precomp-linux-release-simarm_x64",
    category="vm|kernel-precomp|arx")
dart_vm_extra_builder(
    "vm-kernel-precomp-mac-release-simarm64",
    category="vm|kernel-precomp|ma",
    dimensions=mac())
dart_vm_extra_builder(
    "vm-kernel-precomp-win-release-x64",
    category="vm|kernel-precomp|wr",
    dimensions=windows())
dart_vm_nightly_builder(
    "cross-vm-precomp-linux-release-arm64",
    category="vm|kernel-precomp|cra",
    channels=[],
    properties={"shard_timeout": (90 * time.minute) / time.second})

# vm|kernel-precomp|android
dart_vm_extra_builder(
    "vm-kernel-precomp-android-release-arm_x64",
    category="vm|kernel-precomp|android|a32",
    goma_rbe=False,
    properties={"shard_timeout": (90 * time.minute) / time.second})
dart_vm_extra_builder(
    "vm-kernel-precomp-android-release-arm64",
    category="vm|kernel-precomp|android|a64",
    goma_rbe=False,
    properties={"shard_timeout": (90 * time.minute) / time.second})

# vm|product
dart_vm_extra_builder(
    "vm-kernel-linux-product-x64", category="vm|product|l", on_cq=True)
dart_ci_sandbox_builder(
    "vm-kernel-mac-product-x64", category="vm|product|m", dimensions=mac())
dart_ci_sandbox_builder(
    "vm-kernel-win-product-x64", category="vm|product|w", dimensions=windows())

# vm|misc
dart_vm_low_priority_builder(
    "vm-kernel-optcounter-threshold-linux-release-ia32", category="vm|misc|o32")
dart_vm_low_priority_builder(
    "vm-kernel-optcounter-threshold-linux-release-x64", category="vm|misc|o64")
dart_vm_low_priority_builder(
    "vm-kernel-asan-linux-release-x64", category="vm|misc|a")
dart_vm_low_priority_builder(
    "vm-kernel-msan-linux-release-x64", category="vm|misc|m")
dart_vm_low_priority_builder(
    "vm-kernel-tsan-linux-release-x64", category="vm|misc|t")
dart_vm_low_priority_builder(
    "vm-kernel-ubsan-linux-release-x64", category="vm|misc|u",
    goma_rbe=False) # ubsan is not compatible with our sysroot.
dart_vm_low_priority_builder(
    "vm-kernel-precomp-asan-linux-release-x64", category="vm|misc|aot|a")
dart_vm_low_priority_builder(
    "vm-kernel-precomp-msan-linux-release-x64", category="vm|misc|aot|m")
dart_vm_low_priority_builder(
    "vm-kernel-precomp-tsan-linux-release-x64", category="vm|misc|aot|t")
dart_vm_low_priority_builder(
    "vm-kernel-precomp-ubsan-linux-release-x64", category="vm|misc|aot|u",
    goma_rbe=False) # ubsan is not compatible with our sysroot.
dart_vm_low_priority_builder(
    "vm-kernel-reload-linux-debug-x64", category="vm|misc|reload|d")
dart_vm_low_priority_builder(
    "vm-kernel-reload-linux-release-x64", category="vm|misc|reload|r")
dart_vm_low_priority_builder(
    "vm-kernel-reload-rollback-linux-debug-x64", category="vm|misc|reload|drb")
dart_vm_low_priority_builder(
    "vm-kernel-reload-rollback-linux-release-x64",
    category="vm|misc|reload|rrb")

# vm|ffi
dart_vm_extra_builder(
    "vm-ffi-android-debug-arm", category="vm|ffi|d32", goma_rbe=False)
dart_vm_extra_builder(
    "vm-ffi-android-release-arm", category="vm|ffi|r32", goma_rbe=False)
dart_vm_extra_builder(
    "vm-ffi-android-product-arm", category="vm|ffi|p32", goma_rbe=False)
dart_vm_extra_builder(
    "vm-ffi-android-debug-arm64", category="vm|ffi|d64", goma_rbe=False)
dart_vm_extra_builder(
    "vm-ffi-android-release-arm64", category="vm|ffi|r64", goma_rbe=False)
dart_vm_extra_builder(
    "vm-ffi-android-product-arm64", category="vm|ffi|p64", goma_rbe=False)
dart_vm_extra_builder(
    "vm-precomp-ffi-qemu-linux-release-arm", category="vm|ffi|qe")

# pkg
dart_ci_sandbox_builder("pkg-linux-release", category="pkg|l", on_cq=True)
dart_ci_sandbox_builder("pkg-mac-release", category="pkg|m", dimensions=mac())
dart_ci_sandbox_builder(
    "pkg-win-release", category="pkg|w", dimensions=windows())
dart_ci_sandbox_builder("pkg-linux-debug", category="pkg|ld", channels=["try"])

# dart2js
dart_ci_sandbox_builder(
    "dart2js-strong-hostasserts-linux-ia32-d8",
    category="dart2js|d8|ha",
    location_regexp=to_location_regexp(DART2JS_PATHS))
dart_ci_sandbox_builder("dart2js-rti-linux-x64-d8", category="dart2js|d8|rti")
dart_ci_sandbox_builder(
    "dart2js-minified-strong-linux-x64-d8",
    category="dart2js|d8|mi",
    location_regexp=to_location_regexp(DART2JS_PATHS))
dart_ci_sandbox_builder(
    "dart2js-unit-linux-x64-release",
    category="dart2js|d8|u",
    location_regexp=to_location_regexp(DART2JS_PATHS))
dart_ci_sandbox_builder(
    "dart2js-strong-linux-x64-chrome",
    category="dart2js|chrome|l",
    location_regexp=to_location_regexp(DART2JS_PATHS))
dart_ci_sandbox_builder(
    "dart2js-csp-minified-linux-x64-chrome", category="dart2js|chrome|csp")
dart_ci_sandbox_builder(
    "dart2js-strong-mac-x64-chrome",
    category="dart2js|chrome|m",
    dimensions=mac())
dart_ci_sandbox_builder(
    "dart2js-strong-win-x64-chrome",
    category="dart2js|chrome|w",
    dimensions=windows())
dart_ci_sandbox_builder(
    "dart2js-nnbd-linux-x64-chrome",
    category="dart2js|chrome|nn",
    location_regexp=to_location_regexp(DART2JS_PATHS))
dart_ci_sandbox_builder(
    "dart2js-strong-linux-x64-firefox", category="dart2js|firefox|l")
dart_ci_sandbox_builder(
    "dart2js-strong-win-x64-firefox",
    category="dart2js|firefox|w",
    dimensions=windows(),
    enabled=False)
dart_ci_sandbox_builder(
    "dart2js-strong-mac-x64-safari",
    category="dart2js|safari|m",
    dimensions=mac())
dart_ci_sandbox_builder(
    "dart2js-strong-win-x64-ie11",
    category="dart2js|ms|ie",
    dimensions=windows())

# analyzer
dart_ci_sandbox_builder(
    "flutter-analyze",
    category="analyzer|fa",
    channels=["try"],
    notifies=None,
    location_regexp=[
        ".+/[+]/DEPS",
        ".+/[+]/pkg/analysis_server/.+",
        ".+/[+]/pkg/analysis_server_client/.+",
        ".+/[+]/pkg/analyzer/.+",
        ".+/[+]/pkg/analyzer_plugin/.+",
        ".+/[+]/pkg/front_end/.+",
        ".+/[+]/pkg/_fe_analyzer_shared/.+",
        ".+/[+]/pkg/meta/.+",
        ".+/[+]/pkg/telemetry/.+",
    ])
dart_ci_sandbox_builder(
    "analyzer-analysis-server-linux",
    category="analyzer|as",
    location_regexp=to_location_regexp(ANALYZER_PATHS),
    channels=CHANNELS)
dart_ci_sandbox_builder(
    "analyzer-linux-release",
    category="analyzer|l",
    location_regexp=to_location_regexp(ANALYZER_PATHS),
    channels=CHANNELS)
dart_ci_sandbox_builder(
    "analyzer-nnbd-linux-release",
    category="analyzer|nn",
    location_regexp=to_location_regexp(ANALYZER_NNBD_PATHS),
    channels=CHANNELS)
dart_ci_sandbox_builder(
    "analyzer-mac-release",
    category="analyzer|m",
    dimensions=mac(),
    channels=CHANNELS)
dart_ci_sandbox_builder(
    "analyzer-win-release",
    category="analyzer|w",
    dimensions=windows(),
    channels=CHANNELS)

# sdk
dart_ci_builder(
    "dart-sdk-linux", category="sdk|l", channels=CHANNELS)
dart_ci_builder(
    "dart-sdk-mac", category="sdk|m", channels=CHANNELS, dimensions=mac())
dart_ci_builder(
    "dart-sdk-win",
    category="sdk|w",
    channels=CHANNELS,
    dimensions=windows(),
    on_cq=True)

# ddc
dart_ci_sandbox_builder(
    "ddc-linux-release-chrome",
    category="ddc|l",
    location_regexp=to_location_regexp(DDC_PATHS))
dart_ci_sandbox_builder(
    "ddc-nnbd-linux-release-chrome",
    category="ddc|nn",
    channels=["try"],
    location_regexp=to_location_regexp(DDC_PATHS))
dart_ci_sandbox_builder(
    "ddc-mac-release-chrome", category="ddc|m", dimensions=mac())
dart_ci_sandbox_builder(
    "ddc-win-release-chrome", category="ddc|w", dimensions=windows())
dart_ci_sandbox_builder("ddk-linux-release-firefox", category="ddc|fl")

# misc
dart_ci_sandbox_builder(
    "gclient", recipe="dart/gclient", category="misc|g", on_cq=True)
dart_ci_builder(
    "debianpackage-linux",
    category="misc|dp",
    channels=RELEASE_CHANNELS,
    notifies="infra")
dart_ci_builder(
    "versionchecker-linux", category="misc|vc", channels=RELEASE_CHANNELS)

# external
dart_infra_builder(
    "google", recipe="dart/external", category="external|g", enabled=False, fyi=True)

# infra
dart_infra_builder(
    "base",
    execution_timeout=15 * time.minute,
    recipe="dart/forward_branch",
    schedule="with 15m interval",
    notifies=None)
dart_infra_builder("chocolatey", recipe="dart/chocolatey", dimensions=windows())
dart_infra_builder("co19-roller", recipe="dart/package_co19")
dart_infra_builder("docker", recipe="dart/docker")
dart_infra_builder(
    "linearize-flutter",
    recipe="dart/linearize",
    properties={
        "repo": "https://dart.googlesource.com/linear_sdk_flutter_engine.git"
    },
    notifies="infra",
    triggered_by=[
        "dart-gitiles-trigger-master", "dart-flutter-engine-trigger",
        "dart-flutter-flutter-trigger"
    ],
    triggering_policy=scheduler.greedy_batching(max_batch_size=1),
)
dart_infra_builder(
    "nightly",
    notifies="infra",
    properties={"builders": nightly_builders},
    recipe="cron/cron",
    schedule="0 5 * * *",  # daily, at 05:00 UTC
)

# Fuzz testing builders
dart_ci_sandbox_builder(
    "fuzz-linux",
    channels=[],
    notifies="dart-fuzz-testing",
    schedule="0 3,4 * * *",
    triggered_by=None,
)

# Try only builders
dart_try_builder("benchmark-linux", on_cq=True)
dart_try_builder("vm-kernel-gcc-linux")
dart_try_builder(
    "presubmit",
    bucket="try.shared",
    execution_timeout=5 * time.minute,
    recipe="presubmit/presubmit",
)

def add_postponed_alt_console_entries():
    for entry in postponed_alt_console_entries:
        luci.console_view_entry(console_view="alt", **entry)


add_postponed_alt_console_entries()

# Flutter consoles
luci.console_view_entry(
    builder="flutter-analyze",
    short_name="fa",
    category="analyzer",
    console_view="flutter",
)

luci.console_view_entry(
    builder="flutter-frontend",
    short_name="fl",
    category="fasta",
    console_view="flutter",
)

luci.console_view_entry(
    builder="flutter-engine-linux",
    short_name="3H",
    category="flutter",
    console_view="flutter-hhh",
)

# Rolls dart recipe dependencies.
dart_infra_builder(
    name="recipe-deps-roller",
    executable=luci.recipe(
        name="recipe_autoroller",
        cipd_package=
        "infra/recipe_bundles/chromium.googlesource.com/infra/infra",
        cipd_version="git_revision:647d5e58ec508f13ccd054f1516e78d7ca3bd540"
    ),
    execution_timeout=20 * time.minute,
    expiration_timeout=time.day,
    priority=LOW,
    properties={
        "db_gcs_bucket": "dart-recipe-roller-db",
        "projects": {
            "dart": "https://dart.googlesource.com/recipes",
        }.items(), # recipe_autoroller expects a list of tuples.
    },
    schedule="with 4h interval",
)

dart_infra_builder(
    name="recipe-bundler",
    executable=luci.recipe(
        name="recipe_bundler",
        cipd_package=
        "infra/recipe_bundles/chromium.googlesource.com/infra/infra",
        cipd_version="git_revision:40621e908eb88bd10451ee9d013b7ef89ea91e37",
    ),
    execution_timeout=5 * time.minute,
    properties={
        # This property controls the version of the recipe_bundler go tool:
        #   https://chromium.googlesource.com/infra/infra/+/master/go/src/infra/tools/recipe_bundler
        "recipe_bundler_vers":
            "git_revision:2ed88b2c854578b512e1c0486824175fe0d7aab6",
        # These control the prefix of the CIPD package names that the tool
        # will create.
        "package_name_prefix":
            "dart/recipe_bundles",
        "package_name_internal_prefix":
            "dart_internal/recipe_bundles",
        # Where to grab the recipes to bundle.
        "repo_specs": [
            "dart.googlesource.com/recipes=FETCH_HEAD,refs/heads/master",
        ],
    },
    schedule="*/30 * * * *",
    triggered_by=[
        luci.gitiles_poller(
            name="recipes-dart",
            bucket="ci",
            repo="https://dart.googlesource.com/recipes",
            refs=["refs/heads/master"],
        ),
    ],
)
