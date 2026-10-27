# -*- bazel-starlark -*-
# Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Siso configuration for remote Dart actions."""

load("@builtin//encoding.star", "json")
load("@builtin//lib/gn.star", "gn")
load("@builtin//runtime.star", "runtime")
load("@builtin//struct.star", "module")

def __enabled(ctx):
    # Dart actions execute host binaries (prebuilt Dart SDK, dartvm,
    # dartaotruntime, gen_snapshot), which can only run on Linux and Windows
    # x64 RBE workers when the host is also Linux or Windows x64 and RBE is
    # enabled.
    if (runtime.os != "linux" and runtime.os != "windows") or runtime.arch != "amd64":
        return False
    # Even if the machine is x64, the root toolchain may produce ia32 binaries.
    if gn.args(ctx).get("host_cpu") != '"x64"':
        return False
    if gn.args(ctx).get("use_rbe") != "true":
        return False
    return True

def __load_package_map(ctx):
    if not ctx.fs.exists(".dart_tool/package_config.json"):
        return {}
    cfg = json.decode(str(ctx.fs.read(".dart_tool/package_config.json")))
    pkg_map = {}
    for pkg in cfg.get("packages", []):
        name = pkg.get("name")
        root_uri = pkg.get("rootUri", "")
        pkg_uri = pkg.get("packageUri", "")
        if root_uri.startswith("../"):
            root_uri = root_uri[3:]
        pkg_dir = (root_uri + "/" + pkg_uri).rstrip("/")
        if name and pkg_dir:
            pkg_map[name] = pkg_dir
    return pkg_map

def __resolve_uri(uri, pkg_map):
    if uri.startswith("package:"):
        rest = uri[len("package:"):]
        slash = rest.find("/")
        if slash == -1:
            fail("Malformed package URI: %s" % uri)
        pkg_name = rest[:slash]
        relative = rest[slash + 1:]
        base = pkg_map.get(pkg_name)
        if not base:
            fail("Unknown package in URI: %s" % uri)
        return base + "/" + relative
    return uri

# Unlike path.dir, behaves the same on Linux and Windows
def __dirname(path):
    index = path.rfind("/")
    return path[0:index]

def __list_imports(ctx, uri, pkg_map):
    file_path = __resolve_uri(uri, pkg_map)
    if not file_path or not ctx.fs.exists(file_path):
        fail("Does not exist: %s resolved to %s" % (uri, file_path))

    imports = {}
    def add_import(token):
        token = token.replace('"', "").replace("'", "").replace(";", "")
        if token.startswith("dart:"):
            return
        if ":" not in token:
            dirname = __dirname(uri)
            for _ in range(16):
                if not token.startswith(".."):
                    break
                token = token[3:]
                dirname = __dirname(dirname)
            token = dirname + "/" + token
        imports[token] = True

    content = str(ctx.fs.read(file_path))
    for line in content.splitlines():
        tokens = [t for t in line.replace("\t", " ").replace("\r", " ").split(" ") if t]
        if not tokens or tokens[0] in ["//", "///", "/*", "*/"]:
            continue
        # Imports cannot appear after a declaration
        if tokens[0] in ["const", "class", "enum", "final"]:
            break
        # import "foo.dart";
        if len(tokens) >= 2 and tokens[0] in ["import", "export", "part"] and tokens[1] != "of":
            add_import(tokens[1])
        # if (dart.library.io) "foo.dart";
        if len(tokens) >= 2 and tokens[0] == "if" and tokens[1].startswith("(dart.library."):
            add_import(tokens[2])
        # "foo.dart" if (dart.library.io) "bar.dart";
        if len(tokens) >= 3 and tokens[1] == "if" and tokens[2].startswith("(dart.library."):
            add_import(tokens[3])
        # import "foo.dart" if (dart.library.io) "bar.dart";
        if len(tokens) >= 4 and tokens[2] == "if" and tokens[3].startswith("(dart.library."):
            add_import(tokens[4])
    return imports.keys()

def __trace_imports(ctx, uris, pkg_map):
    inputs = {}
    frontier = []
    for u in uris:
        if u not in inputs:
            inputs[u] = True
            frontier.append(u)
    for _ in range(256):
        if not frontier:
            break
        next_frontier = []
        for uri in frontier:
            for imp in __list_imports(ctx, uri, pkg_map):
                if imp not in inputs:
                    inputs[imp] = True
                    next_frontier.append(imp)
        frontier = next_frontier
    return inputs.keys()

def __rebase(ctx, p):
    if p.startswith("package:"):
        return p
    if p.startswith("org-dartlang-gnroot:///"):
        return p[len("org-dartlang-gnroot:///"):]
    return ctx.fs.canonpath(p)

def __dart_action(ctx, cmd):
    # Drop python3 gn_run_binary prefix. No python3 in the RBE container image.
    if len(cmd.args) < 3:
        fail("Not a Dart command? %s" % cmd.args)
    if runtime.os == "windows":
        new_args = ["cmd.exe", "/c", ".\\" + cmd.args[2].replace("/", "\\")] + list(cmd.args[3:])
    else:
        new_args = ["./" + cmd.args[2]] + list(cmd.args[3:])

    # Scandeps for Dart sources.
    dart_entry_points = []
    for arg in cmd.args:
        if arg.endswith(".dart"):
            dart_entry_points.append(__rebase(ctx, arg))
    pkg_map = __load_package_map(ctx)
    resolved_paths = {}
    for uri in __trace_imports(ctx, dart_entry_points, pkg_map):
        resolved_paths[__resolve_uri(uri, pkg_map)] = True
    new_inputs = cmd.inputs + sorted(resolved_paths.keys())

    ctx.actions.fix(args = new_args, inputs = new_inputs)

def __filegroups(ctx):
    if not __enabled(ctx):
        return {}
    return {
        "sdk:files":  {
            "type": "glob",
            "includes": ["*"],
        },
        "tools/sdks/dart-sdk:files":  {
            "type": "glob",
            "includes": ["*"],
        }
    }

__handlers = {
    "dart_action": __dart_action,
}

def __step_config(ctx, step_config):
    if not __enabled(ctx):
        return step_config

    rules = step_config["rules"]

    if runtime.os == "windows":
        platform = "default_windows"
        python_bin = "python3.exe"
    else:
        platform = "default"
        python_bin = "python3"

    # Local-only Dart actions:
    rules.extend([
        {
            "name": "dart/build_sdk_tar",
            "action": ".*_build_sdk_tar_.*",
            "remote": False,  # Just tars the built SDK directory locally.
        },
        {
            "name": "dart/bootstrap",
            "action": ".*_bootstrap_(compile_platform|gen_kernel)\\.(exe|dill)_.*",
            "remote": False,  # Bad depfile (https://dartbug.com/63495, https://dartbug.com/63546)
        },
        {
            "name": "dart/dartpad_worker",
            "action": ".*_dartpad_worker_.*",
            "remote": False,  # Bad depfile, slow
        },
        {
            "name": "dart/wasm_dev_rt",
            "action": ".*wasm_dev_rt.*",
            "remote": False,  # Bad depfile
        },
        {
            "name": "dart/analysis_server",
            "action": ".*analysis_server_.*",
            "remote": False,  # Slow
        },
    ])

    for prefix_label, subdir in [
        ("", ""),
        ("-clang_x64", "clang_x64/"),
    ]:
        rules.extend([
            {
                "name": "dart/gen_snapshot" + prefix_label,
                "command_prefix": python_bin + " ../../build/gn_run_binary.py " + subdir + "gen_snapshot",
                "handler": "dart_action",
                "remote": True,
                "platform_ref": platform,
                "timeout": "4m",
            },
            {
                "name": "dart/dartvm" + prefix_label,
                "command_prefix": python_bin + " ../../build/gn_run_binary.py " + subdir + "dartvm",
                "handler": "dart_action",
                "remote": True,
                "platform_ref": platform,
                "timeout": "4m",
            },
            {
                "name": "dart/dartaotruntime" + prefix_label,
                "command_prefix": python_bin + " ../../build/gn_run_binary.py " + subdir + "dartaotruntime",
                "handler": "dart_action",
                "remote": True,
                "platform_ref": platform,
                "timeout": "4m",
            },
            {
                "name": "dart/bootstrap_compile_platform" + prefix_label,
                "command_prefix": python_bin + " ../../build/gn_run_binary.py bootstrap_compile_platform.exe",
                "handler": "dart_action",
                "remote": True,
                "platform_ref": platform,
                "timeout": "4m",
                "inputs": ["sdk:files"],  # More properly this should just list what's in libraries.json.
                "input_root_absolute_path": True,  # https://dartbug.com/63495, https://dartbug.com/63546
            },
            {
                "name": "dart/bootstrap_gen_kernel" + prefix_label,
                "command_prefix": python_bin + " ../../build/gn_run_binary.py bootstrap_gen_kernel.exe",
                "handler": "dart_action",
                "remote": True,
                "platform_ref": platform,
                "timeout": "4m",
                "input_root_absolute_path": True,  # https://dartbug.com/63495, https://dartbug.com/63546
            },
        ])

    rules.append({
        "name": "dart/prebuilt_dart",
        "command_prefix": python_bin + " ../../build/gn_run_binary.py ../../tools/sdks/dart-sdk/bin/dart",
        "handler": "dart_action",
        "remote": True,
        "platform_ref": platform,
        "timeout": "4m",
        "inputs": ["tools/sdks/dart-sdk:files"],
    })

    return step_config

dart = module(
    "dart",
    step_config = __step_config,
    filegroups = __filegroups,
    handlers = __handlers,
)
