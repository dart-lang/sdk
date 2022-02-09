# Copyright (c) 2022 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines rules that can be used to define nightly and weekly builders.
"""

load("//lib/accounts.star", "accounts")
load("//lib/defaults.star", "defaults")
load("//lib/paths.star", "paths")
load("//lib/priority.star", "priority")

_GOMA_RBE = {
    "server_host": "goma.chromium.org",
    "use_luci_auth": True,
}

_RELEASE_CHANNELS = ["beta", "dev", "stable"]
_CHANNELS = _RELEASE_CHANNELS + ["try"]
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

def _with_goma(goma, dimensions, properties):
    """Decorates the properties to setup goma.

       Adds the $build/goma property when goma is used and disables goma via
       the $dart/build property if not.

    Args:
        goma: Opt-in (True), opt-out (False) or default (None).
        dimensions: The dimensions of the builder.
        properties: The properties object to set $build/goma on (if opted-in).

    Returns:
        A copy of the properties with goma related properties set if applicable.
    """
    updated_properties = dict(properties)
    if goma in (None, True):
        goma_properties = {}
        goma_properties.update(_GOMA_RBE)

        enable_ats = dimensions["os"] == "Linux"

        goma_properties["enable_ats"] = enable_ats
        updated_properties.setdefault("$build/goma", goma_properties)
    else:
        updated_properties = dict(properties)
        updated_properties.setdefault("$dart/build", {})
        updated_properties["$dart/build"].setdefault("disable_goma", True)
    return updated_properties

def _try_builder(
        name,
        recipe = "dart/neo",
        bucket = "try",
        dimensions = None,
        execution_timeout = None,
        experiment_percentage = None,
        experiments = None,
        goma = None,
        location_regexp = None,
        properties = None,
        on_cq = False):
    """Creates a Dart tryjob.

    Args:
        name: The builder name.
        recipe: The recipe to use (defaults to "dart/neo").
        bucket: The bucket to use (defaults to "try").
        dimensions: Extra swarming dimensions required by this builder.
        execution_timeout: Time to allow for the build to run.
        experiment_percentage: What experiment percentage to use.
        experiments: Experiments to run on this builder, with percentages.
        goma: Whether to use goma or not.
        location_regexp: Locations that trigger this tryjob.
        properties: Extra properties to set for builds.
        on_cq: Whether the build is added to the default set of CQ tryjobs.
    """
    if on_cq and location_regexp:
        fail("Can't be on the default CQ and conditionally on the CQ")
    dimensions = defaults.dimensions(dimensions)
    dimensions["pool"] = "luci.dart.try"
    properties = defaults.properties(properties)
    builder_properties = _with_goma(goma, dimensions, properties)
    builder = name + "-try"
    luci.builder(
        name = builder,
        build_numbers = True,
        bucket = bucket,
        caches = defaults.caches(dimensions["os"]),
        dimensions = dimensions,
        executable = _recipe(recipe),
        execution_timeout = execution_timeout,
        experiments = experiments,
        priority = priority.high,
        properties = builder_properties,
        service_account = accounts.try_builder,
        swarming_tags = ["vpython:native-python-wrapper"],
    )
    includable_only = (not on_cq and not experiment_percentage and
                       not location_regexp)
    luci.cq_tryjob_verifier(
        builder = builder,
        cq_group = "sdk",
        experiment_percentage = experiment_percentage,
        location_regexp = location_regexp,
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
        goma = None,
        fyi = False,
        main_channel = True,
        notifies = "dart",
        priority = priority.normal,
        properties = None,
        schedule = "triggered",
        service_account = accounts.try_builder,
        triggered_by = ["dart-gitiles-trigger-%s"],
        triggering_policy = None,
        on_cq = False,
        experiment_percentage = None,
        location_regexp = None):
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
        goma: Whether to use goma or not.
        fyi: Whether this is an FYI builder or not.
        main_channel: Whether to add to the main channel (default: True).
        notifies: Which luci notifier group to notify (default: "dart").
        priority: What swarming priority this builder gets (default: NORMAL).
        properties: Extra properties to set for builds.
        schedule: What schedule to use (default: "triggered").
        service_account: The task service account to use (default: accounts.try_builder).
        triggered_by: What triggers this builder (defaults to standard trigger).
        triggering_policy: The triggering policy used by this builder.
        on_cq: Whether the build is added to the default set of CQ tryjobs.
        experiment_percentage: What experiment percentage to use.
        location_regexp: Locations that trigger this builder.
    """
    dimensions = defaults.dimensions(dimensions)
    properties = defaults.properties(properties)

    os = dimensions["os"]
    if "win" in name and os != "Windows":
        fail("builder %s should be a Windows builder" % name)
    if "mac" in name and os != "Mac":
        fail("builder %s should be a macOS builder" % name)
    if "linux" in name and os != "Linux":
        fail("builder %s should be a Linux builder" % name)

    def builder(channel, notifies, triggered_by):
        if channel == "try":
            _try_builder(
                name,
                recipe = recipe,
                dimensions = dimensions,
                properties = properties,
                on_cq = on_cq,
                execution_timeout = execution_timeout,
                experiment_percentage = experiment_percentage,
                experiments = experiments,
                goma = goma,
                location_regexp = location_regexp,
            )
        else:
            builder_properties = _with_goma(
                goma if service_account == accounts.try_builder else False,
                dimensions,
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
                priority = priority,
                properties = builder_properties,
                notifies = notifies if enabled else None,
                schedule = schedule if enabled else None,
                service_account = service_account,
                swarming_tags = ["vpython:native-python-wrapper"],
                triggered_by = triggered_by if enabled else None,
                triggering_policy = triggering_policy,
            )
            if category:
                console_category, _, short_name = category.rpartition("|")
                toplevel_category, _, _ = console_category.partition("|")
                console = channel or "be" if not fyi else "fyi"
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

    if main_channel:
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

def _infra_builder(name, notifies = "infra", triggered_by = None, **kwargs):
    _ci_builder(
        name,
        notifies = notifies,
        triggered_by = triggered_by,
        **kwargs
    )
    luci.list_view_entry(list_view = "infra", builder = name)

dart = struct(
    ci_builder = _ci_builder,
    ci_sandbox_builder = _ci_sandbox_builder,
    infra_builder = _infra_builder,
    try_builder = _try_builder,
    poller = _poller,
    channels = _CHANNELS,
    release_channels = _RELEASE_CHANNELS,
    branches = _BRANCHES,
    git = _DART_GIT,
)
