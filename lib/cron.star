# Copyright (c) 2022 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Defines rules that can be used to define nightly and weekly builders.
"""

load("//lib/dart.star", "dart")
load("//lib/priority.star", "priority")

def _image_builder(name, notifies = None, **kwargs):
    dart.ci_sandbox_builder(
        name,
        notifies = notifies or [luci.notifier(
            name = "nightly",
            on_new_failure = True,
        )],
        on_cq = False,
        priority = priority.low,
        triggered_by = [luci.gitiles_poller(
            name = "dart-image-trigger",
            bucket = "ci",
            repo = dart.git,
            refs = ["refs/heads/main"],
            # Finish before the image roller runs at Mon-Fri 08:00 UTC.
            schedule = "45 6 * * 1-5",  # Mon-Fri at 06:45 UTC
        )],
        **kwargs
    )

def _nightly_builder(name, notifies = None, **kwargs):
    # Stagger the scheduled times so they don't all try to run at once. Note
    # that MSAN and TSAN are particularlly expensive.
    if name.find("-tsan-") > 0:
        hour = 6
        minute = 40
    elif name.find("-msan-") > 0:
        hour = 6
        minute = 20
    elif name.find("-asan-") > 0 or name.find("-lsan-") > 0 or name.find("-ubsan-") > 0:
        hour = 6
        minute = 0
    elif name.find("-aot-") > 0:
        hour = 5
        minute = 30
    else:
        hour = 5
        minute = 0
    dart.ci_sandbox_builder(
        name,
        notifies = notifies or [luci.notifier(
            name = "nightly",
            on_new_failure = True,
        )],
        on_cq = False,
        priority = priority.low,
        triggered_by = [luci.gitiles_poller(
            name = "dart-nightly-trigger-{}-{}".format(hour, minute),
            bucket = "ci",
            repo = dart.git,
            refs = ["refs/heads/main"],
            schedule = "{} {} * * *".format(minute, hour),  # daily, at hh:mm UTC
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
    image_builder = _image_builder,
    nightly_builder = _nightly_builder,
    weekly_builder = _weekly_builder,
)
