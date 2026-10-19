# -*- bazel-starlark -*-
# Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Siso configuration main entry."""

load("@builtin//encoding.star", "json")
load("@builtin//lib/gn.star", "gn")
load("@builtin//struct.star", "module")
load("./clang.star", "clang")
load("./dart.star", "dart")
load("./simple.star", "simple")

def init(ctx):
    step_config = {
        "platforms": {
            "default": {
                "OSFamily": "Linux",
                "container-image": "docker://gcr.io/cloud-marketplace/google/debian11@sha256:69e2789c9f3d28c6a0f13b25062c240ee7772be1f5e6d41bb4680b63eae6b304",
            },
        },
        "input_deps": {},
        "rules": [],
        "executables": [],
    }
    filegroups = {}
    handlers = {}
    for m in [
        clang,
        dart,
        simple,
    ]:
        step_config = m.step_config(ctx, step_config)
        filegroups.update(m.filegroups(ctx))
        handlers.update(m.handlers)

    use_rbe = False
    if "args.gn" in ctx.metadata:
        use_rbe = gn.args(ctx).get("use_rbe") == "true"
    if not use_rbe:
        for rule in step_config["rules"]:
            rule["remote"] = False

    return module(
        "config",
        step_config = json.encode(step_config),
        filegroups = filegroups,
        handlers = handlers,
    )
