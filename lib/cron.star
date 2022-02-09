# Copyright (c) 2022 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines rules that can be used to define nightly and weekly builders.
"""

load("//lib/dart.star", "dart")
load("//lib/priority.star", "priority")

def _nightly_builder(name, notifies = None, **kwargs):
    dart.ci_sandbox_builder(
        name,
        notifies = notifies or [luci.notifier(
            name = "nightly",
            on_new_failure = True,
        )],
        on_cq = False,
        priority = priority.low,
        triggered_by = [luci.gitiles_poller(
            name = "dart-nightly-trigger",
            bucket = "ci",
            repo = dart.git,
            refs = ["refs/heads/main"],
            schedule = "0 5 * * *",  # daily, at 05:00 UTC
        )],
        **kwargs
    )

def _weekly_builder(name, notifies = None, **kwargs):
    dart.ci_sandbox_builder(
        name,
        notifies = notifies,
        on_cq = False,
        priority = priority.low,
        triggered_by = [luci.gitiles_poller(
            name = "dart-weekly-trigger",
            bucket = "ci",
            repo = dart.git,
            refs = ["refs/heads/main"],
            schedule = "0 0 * * SUN",  # weekly, midnight Saturday to Sunday
        )],
        **kwargs
    )

cron = struct(
    nightly_builder = _nightly_builder,
    weekly_builder = _weekly_builder,
)
