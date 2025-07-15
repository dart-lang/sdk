# Copyright (c) 2023 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines the CFE builders.
"""

load("//lib/cron.star", "cron")
load("//lib/dart.star", "dart")
load(
    "//lib/defaults.star",
    "mac",
    "windows",
)
load("//lib/paths.star", "paths")

luci.notifier(
    name = "frontend-team",
    on_failure = True,
    notify_emails = ["jensj@google.com"],
)

dart.ci_sandbox_builder(
    "front-end-linux-release-x64",
    category = "cfe|l",
    on_cq = True,
    properties = {"clobber": True},  # https://github.com/dart-lang/sdk/issues/61120
)
dart.ci_sandbox_builder(
    "front-end-nnbd-linux-release-x64",
    category = "cfe|nnbd|l",
    location_filters = paths.to_location_filters(paths.cfe),
    properties = {"clobber": True},  # https://github.com/dart-lang/sdk/issues/61120
)
cron.nightly_builder(
    "front-end-nnbd-mac-release-x64",
    category = "cfe|nnbd|m",
    channels = ["try"],
    dimensions = mac,
    properties = {"clobber": True},  # https://github.com/dart-lang/sdk/issues/61120
)
cron.nightly_builder(
    "front-end-nnbd-win-release-x64",
    category = "cfe|nnbd|w",
    channels = ["try"],
    dimensions = windows,
    properties = {"clobber": True},  # https://github.com/dart-lang/sdk/issues/61120
)
dart.ci_sandbox_builder(
    "flutter-frontend",
    category = "cfe|fl",
    channels = ["try"],
    notifies = "frontend-team",
    location_filters = paths.to_location_filters(paths.cfe_only),
    properties = {"clobber": True},  # https://github.com/dart-lang/sdk/issues/61120
)
cron.weekly_builder(
    "frontend-weekly",
    notifies = "frontend-team",
    channels = [],
    execution_timeout = 12 * time.hour,
    properties = {"clobber": True},  # https://github.com/dart-lang/sdk/issues/61120
)
