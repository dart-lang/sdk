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
    gerrit_listener_type = cq.GERRIT_LISTENER_TYPE_LEGACY_POLLER,
)

def default_verifiers():
    return [
        luci.cq_tryjob_verifier(
            builder = "presubmit-try",
            disable_reuse = True,
        ),
    ]

DART_GERRIT = "https://dart-review.googlesource.com/"

def sdk_cq_groups():
    for branch in dart.branches:
        luci.cq_group(
            name = "sdk-%s" % branch,
            watch = cq.refset(
                DART_GERRIT + "sdk",
                refs = ["refs/heads/%s" % branch],
            ),
            allow_submit_with_open_deps = True,
            tree_status_name = "dart",
            retry_config = cq.RETRY_NONE,
            verifiers = None,
        )

sdk_cq_groups()

luci.cq_group(
    name = "sdk-infra-config",
    watch = cq.refset(DART_GERRIT + "sdk", refs = ["refs/heads/infra/config"]),
    allow_submit_with_open_deps = True,
    tree_status_name = "dart",
    retry_config = cq.RETRY_NONE,
    verifiers = default_verifiers(),
)

def basic_cq(repository, extra_verifies = [], include_default_verifiers = True):
    luci.cq_group(
        name = repository,
        watch = cq.refset(DART_GERRIT + repository, refs = ["refs/heads/main"]),
        allow_submit_with_open_deps = True,
        tree_status_name = "dart",
        retry_config = cq.RETRY_NONE,
        verifiers = (default_verifiers() if include_default_verifiers else []) + extra_verifies,
    )

basic_cq(
    "dart_ci",
    # The PRESUBMIT.py in this repo assumes `dart` is available on PATH, which is only true locally.
    include_default_verifiers = False,
)
basic_cq("dart-docker", [
    luci.cq_tryjob_verifier(
        builder = "docker-try",
    ),
])
basic_cq("deps")
basic_cq("flute")
basic_cq("homebrew-dart", [
    luci.cq_tryjob_verifier(
        builder = "homebrew-try",
    ),
])
basic_cq("recipes")

def empty_cq(repository):
    luci.cq_group(
        name = repository,
        watch = cq.refset(DART_GERRIT + repository, refs = ["refs/heads/main"]),
        allow_submit_with_open_deps = True,
        tree_status_name = "dart",
        retry_config = cq.RETRY_NONE,
        verifiers = None,
    )

empty_cq("monorepo")

luci.list_view(
    name = "cq",
    title = "SDK CQ Console",
)
