# Copyright (c) 2022 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
CQs for the dart Gerrit host.
"""

load("//lib/dart.star", "dart")

luci.cq(
    submit_max_burst = 2,
    submit_burst_delay = 8 * time.minute,
    status_host = "chromium-cq-status.appspot.com",
)

def default_verifiers():
    return [
        luci.cq_tryjob_verifier(
            builder = "presubmit-try",
            disable_reuse = True,
        ),
    ]

DART_GERRIT = "https://dart-review.googlesource.com/"

luci.cq_group(
    name = "sdk",
    watch = cq.refset(
        DART_GERRIT + "sdk",
        refs = ["refs/heads/%s" % branch for branch in dart.branches],
    ),
    allow_submit_with_open_deps = True,
    tree_status_host = "dart-status.appspot.com",
    retry_config = cq.RETRY_NONE,
    verifiers = None,
)

luci.cq_group(
    name = "sdk-infra-config",
    watch = cq.refset(DART_GERRIT + "sdk", refs = ["refs/heads/infra/config"]),
    allow_submit_with_open_deps = True,
    tree_status_host = "dart-status.appspot.com",
    retry_config = cq.RETRY_NONE,
    verifiers = default_verifiers(),
)

luci.cq_group(
    name = "recipes",
    watch = cq.refset(DART_GERRIT + "recipes", refs = ["refs/heads/main"]),
    allow_submit_with_open_deps = True,
    tree_status_host = "dart-status.appspot.com",
    retry_config = cq.RETRY_NONE,
    verifiers = default_verifiers(),
)

luci.cq_group(
    name = "dart_ci",
    watch = cq.refset(DART_GERRIT + "dart_ci", refs = ["refs/heads/main"]),
    allow_submit_with_open_deps = True,
    tree_status_host = "dart-status.appspot.com",
    retry_config = cq.RETRY_NONE,
    verifiers = None,
)

luci.list_view(
    name = "cq",
    title = "SDK CQ Console",
)
