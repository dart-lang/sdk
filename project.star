# Copyright (c) 2022 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Global definitions and ACLs for the project.
"""

load("//lib/accounts.star", "accounts")

# https://chrome-infra-auth.appspot.com/auth/groups/project-dart-ci-task-accounts
CI_ACCOUNTS_GROUP = "project-dart-ci-task-accounts"

# https://chrome-infra-auth.appspot.com/auth/groups/project-dart-try-task-accounts
TRY_ACCOUNTS_GROUP = "project-dart-try-task-accounts"

ROLL_TRIGGERERS = {
    "groups": ["project-dart-roller-owners"],
    "users": [
        accounts.ci_builder,
    ],
}
CI_SANDBOX_TRIGGERERS = [
    accounts.ci_builder,
    accounts.try_builder,
    "dart-internal-cbuild@dart-ci-internal.iam.gserviceaccount.com",
]

lucicfg.config(
    tracked_files = ["*"],
    lint_checks = ["all"],
)

luci.project(
    name = "dart",
    buildbucket = "cr-buildbucket.appspot.com",
    logdog = "luci-logdog.appspot.com",
    milo = "luci-milo.appspot.com",
    notify = "luci-notify.appspot.com",
    scheduler = "luci-scheduler.appspot.com",
    swarming = "chromium-swarm.appspot.com",
    acls = [
        acl.entry(
            [
                acl.BUILDBUCKET_READER,
                acl.LOGDOG_READER,
                acl.PROJECT_CONFIGS_READER,
                acl.SCHEDULER_READER,
            ],
            groups = ["all"],
        ),
        acl.entry(acl.LOGDOG_WRITER, groups = ["luci-logdog-chromium-writers"]),
        acl.entry(
            [acl.SCHEDULER_OWNER, acl.BUILDBUCKET_TRIGGERER],
            groups = ["project-dart-admins"],
        ),
        acl.entry(acl.CQ_COMMITTER, groups = ["project-dart-committers"]),
        acl.entry(acl.CQ_DRY_RUNNER, groups = ["project-dart-tryjob-access"]),
    ],
    bindings = [
        luci.binding(
            roles = "role/configs.validator",
            users = accounts.try_builder,
        ),
        luci.binding(
            roles = "role/swarming.poolOwner",
            groups = "project-dart-admins",
        ),
        luci.binding(
            roles = "role/swarming.poolViewer",
            groups = "project-dart-committers",
        ),
    ],
)

luci.logdog(gs_bucket = "chromium-luci-logdog")

luci.bucket(
    name = "ci",
    acls = [
        acl.entry(acl.BUILDBUCKET_TRIGGERER, users = [accounts.ci_builder]),
    ],
)
luci.bucket(
    name = "ci.roll",
    acls = [
        acl.entry(acl.BUILDBUCKET_TRIGGERER, **ROLL_TRIGGERERS),
    ],
)
luci.bucket(
    name = "ci.sandbox",
    acls = [
        acl.entry(acl.BUILDBUCKET_TRIGGERER, users = CI_SANDBOX_TRIGGERERS),
    ],
)
TRY_ACLS = [
    acl.entry(
        acl.BUILDBUCKET_TRIGGERER,
        groups = ["project-dart-tryjob-access", "service-account-cq"],
    ),
]

# Tryjobs specific to the Dart SDK repo.
luci.bucket(
    name = "try",
    acls = TRY_ACLS + [
        # For workflows that need to be authorized by Google-internal
        # approval mechanisms, see b/231131625
        acl.entry(
            acl.BUILDBUCKET_TRIGGERER,
            users = ["dart-eng-tool-proxy@system.gserviceaccount.com"],
        ),
    ],
)

# Tryjobs for all repos.
luci.bucket(name = "try.shared", acls = TRY_ACLS)

# Swarming permissions in realms.cfg.

luci.realm(name = "pools/ci")
luci.realm(name = "pools/try")
luci.realm(
    name = "pools/tests",
    bindings = [
        luci.binding(
            roles = "role/swarming.poolUser",
            groups = [CI_ACCOUNTS_GROUP, TRY_ACCOUNTS_GROUP],
        ),
    ],
)

def led_users(*, pool_realms, builder_realm, groups):
    for realm in pool_realms:
        luci.binding(
            realm = realm,
            roles = "role/swarming.poolUser",
            groups = groups,
        )
    luci.binding(
        realm = builder_realm,
        roles = "role/swarming.taskTriggerer",
        groups = groups,
    )

# Allow admins to use LED and "Debug" button on every Dart builder and bot.
led_users(
    pool_realms = ["@root"],
    builder_realm = "@root",
    groups = ["project-dart-admins"],
)

# Allow mdb/dart-build-access to use LED and "Debug" button on try builders and
# try and test bots.
led_users(
    pool_realms = ["pools/try", "pools/tests"],
    builder_realm = "try",
    groups = ["mdb/dart-build-access"],
)

luci.milo(
    logo = "https://storage.googleapis.com/chrome-infra-public/logo/dartlang.png",
)
