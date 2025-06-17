# Copyright (c) 2022 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines rules that can be used to define dart builders.
"""

load("//lib/accounts.star", "accounts")
load(
    "//lib/defaults.star",
    "defaults",
    "jammy",
    "linux",
    "mac",
    "noble",
    "windows",
)
load("//lib/paths.star", "paths")
load("//lib/priority.star", "priority")

_RELEASE_CHANNELS = ["beta", "dev", "stable"]
_CHANNELS = ["beta", "stable", "try"]
_BRANCHES = ["main"] + _RELEASE_CHANNELS

_DART_GIT = "https://dart.googlesource.com/sdk"

def _poller(name, bucket = "ci", branches = _BRANCHES, paths = None):
    for branch in branches:
        luci.gitiles_poller(
            name = "%s-%s" % (name, branch),
            bucket = bucket,
            path_regexps = paths,
            repo = _DART_GIT,
            refs = ["refs/heads/%s" % branch],
        )

def _recipe(name):
    return luci.recipe(
        name = name,
        cipd_package = "dart/recipe_bundles/dart.googlesource.com/recipes",
        cipd_version = "refs/heads/main",
        use_bbagent = True,
    )

def _flutter_recipe(name):
    return luci.recipe(
        name = name,
        cipd_package = "flutter/recipe_bundles/flutter.googlesource.com/recipes",
        cipd_version = "refs/heads/main",
        use_bbagent = True,
    )

def _with_rbe(rbe, properties):
    """Decorates the properties to setup RBE.

       Enables/disables RBE via the $dart/build property.

    Args:
        rbe: Opt-in (True), opt-out (False) or default (None).
        properties: The properties object to set $build/goma on (if opted-in).

    Returns:
        A copy of the properties with RBE related properties set if applicable.
    """
    updated_properties = dict(properties)
    if rbe == False:
        updated_properties = dict(properties)
        updated_properties.setdefault("$dart/build", {})
        updated_properties["$dart/build"].setdefault("disable_rbe", True)
    return updated_properties

def _try_builder(
        name,
        recipe = "dart/neo",
        bucket = "try",
        caches = None,
        cq_branches = _BRANCHES,
        dimensions = None,
        executable = None,
        execution_timeout = None,
        experiment_percentage = None,
        experiments = None,
        rbe = None,
        location_filters = None,
        properties = None,
        on_cq = False):
    """Creates a Dart tryjob.

    Args:
        name: The builder name.
        recipe: The recipe to use (defaults to "dart/neo").
        bucket: The bucket to use (defaults to "try").
        caches: A list of swarming caches.
        cq_branches: Make try builder on these branches (defaults to _BRANCHES).
        dimensions: Extra swarming dimensions required by this builder.
        executable: The Luci executable to use.
        execution_timeout: Time to allow for the build to run.
        experiment_percentage: What experiment percentage to use.
        experiments: Experiments to run on this builder, with percentages.
        rbe: Whether to use RBE.
        location_filters: Locations that trigger this tryjob.
        properties: Extra properties to set for builds.
        on_cq: Whether the build is added to the default set of CQ tryjobs.
    """
    if on_cq and location_filters:
        fail("Can't be on the default CQ and conditionally on the CQ")
    dimensions = defaults.dimensions(dimensions)

    # TODO(https://github.com/flutter/flutter/issues/127691): Remove filtering
    # of host_class.
    if dimensions["pool"] in ["luci.flutter.prod", "luci.flutter.staging"]:
        dimensions.pop("host_class")
    properties = defaults.properties(properties)
    builder_properties = _with_rbe(rbe, properties)
    builder = name + "-try"
    caches = caches if caches != None else defaults.caches(dimensions["os"])
    luci.builder(
        name = builder,
        build_numbers = True,
        bucket = bucket,
        caches = caches,
        dimensions = dimensions,
        executable = executable or _recipe(recipe),
        execution_timeout = execution_timeout,
        experiments = experiments,
        priority = priority.high,
        properties = builder_properties,
        service_account = accounts.try_builder,
    )
    includable_only = (not on_cq and not experiment_percentage and
                       not location_filters)
    for branch in cq_branches:
        luci.cq_tryjob_verifier(
            builder = builder,
            cq_group = "sdk-%s" % branch,
            experiment_percentage = experiment_percentage,
            location_filters = location_filters,
            includable_only = includable_only,
        )
    luci.list_view_entry(list_view = "cq", builder = builder)

def _builder(
        name,
        bucket,
        recipe = "dart/neo",
        enabled = True,
        category = None,
        channels = [],
        dimensions = None,
        executable = None,
        execution_timeout = None,
        experimental = None,
        experiments = None,
        expiration_timeout = None,
        rbe = None,
        notifies = "dart",
        priority = priority.normal,
        properties = None,
        schedule = "triggered",
        service_account = accounts.try_builder,
        triggered_by = ["dart-gitiles-trigger-%s"],
        triggering_policy = None,
        on_cq = False,
        experiment_percentage = None,
        location_filters = None):
    """
    Creates a Dart builder on all the specified channels.

    Args:
        name: The builder name.
        bucket: The bucket to use (defaults to "try").
        recipe: The recipe to use (defaults to "dart/neo").
        enabled: Whether this builder is currently running or not.
        category: Where to show the builder on the console.
        channels: Which other channels the builder should be added to.
        dimensions: Extra swarming dimensions required by this builder.
        executable: The Luci executable to use.
        execution_timeout: Time to allow for the build to run.
        experimental: Whether the build is experimental or not.
        experiments: Experiments to run on this builder, with percentages.
        expiration_timeout: How long builds should wait for a bot to run on.
        rbe: Whether to use RBE or not.
        notifies: Which luci notifier group to notify (default: "dart").
        priority: What swarming priority this builder gets (default: NORMAL).
        properties: Extra properties to set for builds.
        schedule: What schedule to use (default: "triggered").
        service_account: The task service account to use (default: accounts.try_builder).
        triggered_by: What triggers this builder (defaults to standard trigger).
        triggering_policy: The triggering policy used by this builder.
        on_cq: Whether the build is added to the default set of CQ tryjobs.
        experiment_percentage: What experiment percentage to use.
        location_filters: Locations that trigger this builder.
    """
    dimensions = defaults.dimensions(dimensions)

    # TODO(https://github.com/flutter/flutter/issues/127691): Remove filtering
    # of host_class.
    if dimensions["pool"] in ["luci.flutter.prod", "luci.flutter.staging"]:
        dimensions.pop("host_class")
    properties = defaults.properties(properties)

    os = dimensions["os"]

    def expect_os(os_pattern, expected_os):
        if os_pattern in name and os not in expected_os:
            fail("builder %s should be a %s builder but was %s" % (name, expected_os, os))

    expect_os("-win", windows["os"])
    expect_os("-linux", [linux["os"], jammy["os"], noble["os"]])
    expect_os("-mac", mac["os"])

    cq_branches = ["main"] + [branch for branch in channels if branch != "try"]

    def builder(channel, notifies, triggered_by):
        if channel == "try":
            _try_builder(
                name,
                recipe = recipe,
                cq_branches = cq_branches,
                dimensions = dimensions,
                properties = properties,
                on_cq = on_cq,
                executable = executable,
                execution_timeout = execution_timeout,
                experiment_percentage = experiment_percentage,
                experiments = experiments,
                rbe = rbe,
                location_filters = location_filters,
            )
        else:
            builder_properties = _with_rbe(
                rbe if service_account == accounts.try_builder else False,
                properties,
            )
            builder = name + "-" + channel if channel else name
            branch = channel if channel else "main"
            if schedule == "triggered" and triggered_by:
                triggered_by = [
                    trigger.replace("%s", branch) if type(trigger) == type("") else trigger
                    for trigger in triggered_by
                ]
                if channel in _RELEASE_CHANNELS:
                    # Always run vm builders on release channels.
                    triggered_by = [
                        trigger.replace("dart-vm-", "dart-") if type(trigger) == type("") else trigger
                        for trigger in triggered_by
                    ]

            notifies = [notifies] if type(notifies) == type("") else notifies
            adjusted_priority = priority + 10 if channel else priority
            luci.builder(
                name = builder,
                build_numbers = True,
                bucket = bucket,
                caches = defaults.caches(dimensions["os"]),
                dimensions = dimensions,
                executable = executable or _recipe(recipe),
                execution_timeout = execution_timeout,
                experimental = experimental,
                experiments = experiments,
                expiration_timeout = expiration_timeout,
                priority = adjusted_priority,
                properties = builder_properties,
                notifies = notifies if enabled else None,
                schedule = schedule if enabled else None,
                service_account = service_account,
                triggered_by = triggered_by if enabled else None,
                triggering_policy = triggering_policy,
            )
            if category:
                console_category, _, short_name = category.rpartition("|")
                toplevel_category, _, _ = console_category.partition("|")
                console = channel or "be"
                luci.console_view_entry(
                    builder = builder,
                    short_name = short_name,
                    category = console_category,
                    console_view = console,
                )
                if console == "be":
                    if toplevel_category != "vm":
                        luci.console_view_entry(
                            builder = builder,
                            short_name = short_name,
                            category = console_category,
                            console_view = "alt",
                        )

    builder(None, notifies = notifies, triggered_by = triggered_by)
    for _channel in channels:
        if enabled:
            builder(_channel, notifies = None, triggered_by = triggered_by)

def _ci_builder(name, bucket = "ci", dimensions = None, **kwargs):
    if type(dimensions) == type({}):
        dimensions = [dimensions]
    dimensions = list(dimensions or [])
    dimensions.append({"pool": "luci.dart.ci"})
    _builder(
        name,
        bucket = bucket,
        dimensions = dimensions,
        service_account = accounts.ci_builder,
        **kwargs
    )

def _ci_sandbox_builder(name, channels = _CHANNELS, **kwargs):
    _builder(
        name,
        bucket = "ci.sandbox",
        channels = channels,
        service_account = accounts.try_builder,
        **kwargs
    )

dart = struct(
    ci_builder = _ci_builder,
    ci_sandbox_builder = _ci_sandbox_builder,
    try_builder = _try_builder,
    flutter_recipe = _flutter_recipe,
    poller = _poller,
    channels = _CHANNELS,
    release_channels = _RELEASE_CHANNELS,
    branches = _BRANCHES,
    git = _DART_GIT,
)
