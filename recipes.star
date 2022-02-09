# Copyright (c) 2022 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Luci recipe framework infrastructure.

The recipe-deps-roller keeps recipe dependencies up-to-date and the recipe
bundler uploads recipes as CIPD packages.
"""

load("//lib/dart.star", "dart")
load("//lib/priority.star", "priority")

def chromium_infra_recipe(name):
    return luci.recipe(
        name = name,
        cipd_package =
            "infra/recipe_bundles/chromium.googlesource.com/infra/infra",
        cipd_version = "git_revision:21e1e6473db300eb5045e4483e8b53d1324cd0d8",
        use_bbagent = True,
    )

# Rolls dart recipe dependencies.
dart.infra_builder(
    name = "recipe-deps-roller",
    executable = chromium_infra_recipe("recipe_autoroller"),
    execution_timeout = 20 * time.minute,
    expiration_timeout = time.day,
    priority = priority.low,
    properties = {
        "db_gcs_bucket": "dart-recipe-roller-db",
        "projects": {
            "dart": "https://dart.googlesource.com/recipes",
        }.items(),  # recipe_autoroller expects a list of tuples.
    },
    schedule = "with 4h interval",
)

dart.infra_builder(
    name = "recipe-bundler",
    executable = chromium_infra_recipe("recipe_bundler"),
    execution_timeout = 5 * time.minute,
    properties = {
        # These control the prefix of the CIPD package names that the tool
        # will create.
        "package_name_internal_prefix": "dart_internal/recipe_bundles",
        "package_name_prefix": "dart/recipe_bundles",
        # This property controls the version of the recipe_bundler go tool:
        #   https://chromium.googlesource.com/infra/infra/+/main/go/src/infra/tools/recipe_bundler
        "recipe_bundler_vers": "git_revision:bc0c2fb9082bc82a2d972b5cca8fc17afa55d34e",
        # Where to grab the recipes to bundle.
        "repo_specs": [
            "dart.googlesource.com/recipes=FETCH_HEAD,refs/heads/main",
        ],
    },
    schedule = "*/30 * * * *",
    triggered_by = [
        luci.gitiles_poller(
            name = "recipes-dart",
            bucket = "ci",
            repo = "https://dart.googlesource.com/recipes",
            refs = ["refs/heads/main"],
        ),
    ],
)
