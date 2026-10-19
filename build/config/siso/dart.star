# -*- bazel-starlark -*-
# Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Siso configuration for remote Dart actions."""

# Updates here likely require matching updates in //build/rbe/rewrapper_dart.py

load("@builtin//encoding.star", "json")
load("@builtin//lib/gn.star", "gn")
load("@builtin//path.star", "path")
load("@builtin//runtime.star", "runtime")
load("@builtin//struct.star", "module")

def __enabled(ctx):
    # Dart actions execute host binaries (prebuilt Dart SDK, dartvm,
    # dartaotruntime, gen_snapshot), which can only run on Linux x64 RBE
    # workers when the host is also Linux x64 and RBE is enabled.
    if runtime.os != "linux" or runtime.arch != "amd64":
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
        pkg_dir = path.join(root_uri, pkg_uri).rstrip("/")
        if name and pkg_dir:
            pkg_map[name] = pkg_dir
    return pkg_map

def __resolve_uri(uri, pkg_map, whole_dir = False):
    if uri.startswith("package:"):
        rest = uri[len("package:"):]
        slash = rest.find("/")
        if slash == -1:
            return None
        pkg_name = rest[:slash]
        relative = rest[slash + 1:]
        base = pkg_map.get(pkg_name)
        if not base:
            fail("Unknown package in URI: %s" % uri)
        if whole_dir:
            return base
        return path.join(base, relative)
    return uri

def __list_imports(ctx, uri, pkg_map):
    if uri.startswith("dart:"):
        return []
    file_path = __resolve_uri(uri, pkg_map, whole_dir = False)
    if not file_path or not ctx.fs.exists(file_path):
        return []
    imports = {}
    content = str(ctx.fs.read(file_path))
    for line in content.splitlines():
        tokens = [t for t in line.replace("\t", " ").replace("\r", " ").split(" ") if t]
        if not tokens or tokens[0] in ["//", "///", "/*", "*/", "#!", "library", "show"]:
            continue
        if tokens[0] in ["const", "class", "enum", "final"]:
            break
        if len(tokens) >= 2 and tokens[0] == "if" and tokens[1] == "(dart.library.io)":
            tokens = ["import"] + tokens[2:]
        if tokens[0] not in ["import", "export", "part"]:
            continue
        if len(tokens) < 2:
            fail("Bad import statement: %s: %s" % (file_path, line))
        if tokens[0] == "part" and tokens[1] == "of":
            continue
        token = tokens[1].replace('"', "").replace("'", "").replace(";", "")
        if token.startswith("dart:"):
            continue
        if ":" not in token:
            dirname = path.dir(uri)
            for _ in range(16):
                if not token.startswith(".."):
                    break
                token = token[3:]
                dirname = path.dir(dirname)
            token = dirname + "/" + token
        imports[token] = True
    return imports.keys()

def __find_inputs(ctx, uris, pkg_map):
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
    for scheme in [
        "org-dartlang-gnroot:///",
        "org-dartlang-gnroot://",
        "org-dartlang-kernel-service:///",
        "org-dartlang-kernel-service://",
    ]:
        if p.startswith(scheme):
            return p[len(scheme):].lstrip("/")
    if p.startswith("file:////"):
        p = p[len("file:///"):]
    elif p.startswith("file://"):
        p = p[len("file://"):]
    return ctx.fs.canonpath(p)

def __match_option(args, idx, options):
    arg = args[idx]
    for opt in options:
        if arg == opt:
            if idx + 1 >= len(args):
                fail("Missing argument for option %s" % opt)
            return True, args[idx + 1], idx + 2
        elif opt.startswith("--") and arg.startswith(opt + "="):
            return True, arg[len(opt) + 1:], idx + 1
        elif len(opt) >= 2 and opt[0] == "-" and opt[1] != "-" and arg.startswith(opt):
            return True, arg[len(opt):], idx + 1
    return False, None, idx + 1

def __parse_dart2js(ctx, args, idx, entry_points, extra_paths):
    for _ in range(len(args)):
        if idx >= len(args):
            break
        arg = args[idx]
        matched, optarg, next_idx = __match_option(args, idx, ["-o", "--output"])
        if matched:
            idx = next_idx
            continue
        matched, optarg, next_idx = __match_option(args, idx, ["--platform-binaries"])
        if matched:
            extra_paths[__rebase(ctx, path.join(optarg, "dart2js_platform.dill"))] = True
            idx = next_idx
            continue
        matched, _, next_idx = __match_option(args, idx, [
            "--invoker",
            "--packages",
            "--libraries-spec",
            "--snapshot-kind",
            "--depfile_output_filename",
            "--coverage",
            "--ignore-unrecognized-flags",
        ])
        if matched:
            idx = next_idx
            continue
        if arg in ["--canary", "--enable-asserts", "-m", "--minify", "--no-source-maps"]:
            idx += 1
        elif not arg.startswith("-"):
            entry_points[__rebase(ctx, arg)] = True
            idx += 1
        else:
            fail("Unsupported dart2js operand: %s" % arg)

def __parse_dartdevc(ctx, args, idx, entry_points, extra_paths):
    for _ in range(len(args)):
        if idx >= len(args):
            break
        arg = args[idx]
        matched, _, next_idx = __match_option(args, idx, ["-o", "--output"])
        if matched:
            idx = next_idx
            continue
        matched, optarg, next_idx = __match_option(args, idx, ["--dart-sdk-summary", "--packages"])
        if matched:
            extra_paths[__rebase(ctx, optarg)] = True
            idx = next_idx
            continue
        matched, _, next_idx = __match_option(args, idx, [
            "--multi-root-scheme",
            "--multi-root-output-path",
            "--modules",
        ])
        if matched:
            idx = next_idx
            continue
        if arg in ["--canary", "--no-summarize", "--sound-null-safety", "--no-sound-null-safety"]:
            idx += 1
        elif not arg.startswith("-"):
            if arg.endswith(".dart"):
                entry_points[__rebase(ctx, arg)] = True
            else:
                extra_paths[__rebase(ctx, arg)] = True
            idx += 1
        else:
            fail("Unsupported dartdevc operand: %s" % arg)

def __parse_analysis_server(ctx, args, idx, entry_points, extra_paths):
    for _ in range(len(args)):
        if idx >= len(args):
            break
        arg = args[idx]
        matched, optarg, next_idx = __match_option(args, idx, ["--sdk"])
        if matched:
            extra_paths[__rebase(ctx, optarg)] = True
            idx = next_idx
            continue
        matched, optarg, next_idx = __match_option(args, idx, ["--train-using"])
        if matched:
            extra_paths[__rebase(ctx, optarg)] = True
            entry_points[__rebase(ctx, path.join(optarg, "compiler_api.dart"))] = True
            entry_points[__rebase(ctx, path.join(optarg, "src/io/mapped_file.dart"))] = True
            entry_points["package:shell_arg_splitter/shell_arg_splitter.dart"] = True
            idx = next_idx
            continue
        fail("Unsupported analysis_server operand: %s" % arg)

def __parse_kernel_worker(ctx, args, idx, entry_points, extra_paths):
    for _ in range(len(args)):
        if idx >= len(args):
            break
        arg = args[idx]
        if arg in ["--help", "--sound-null-safety", "--no-sound-null-safety", "--summary-only"]:
            idx += 1
            continue
        matched, _, next_idx = __match_option(args, idx, ["-o", "--output", "--target"])
        if matched:
            idx = next_idx
            continue
        matched, optarg, next_idx = __match_option(args, idx, ["--packages-file", "--dart-sdk-summary"])
        if matched:
            extra_paths[__rebase(ctx, optarg)] = True
            idx = next_idx
            continue
        matched, optarg, next_idx = __match_option(args, idx, ["--source"])
        if matched:
            entry_points[__rebase(ctx, optarg)] = True
            idx = next_idx
            continue
        fail("Unsupported kernel_worker operand: %s" % arg)

def __parse_modular_aot_compiler(ctx, args, idx, entry_points, extra_paths):
    for _ in range(len(args)):
        if idx >= len(args):
            break
        arg = args[idx]
        matched, _, next_idx = __match_option(args, idx, [
            "-o",
            "--output",
            "--packages",
            "-D",
            "--filesystem-root",
            "--filesystem-scheme",
            "--depfile",
        ])
        if matched:
            idx = next_idx
            continue
        matched, optarg, next_idx = __match_option(args, idx, ["--platform"])
        if matched:
            extra_paths[__rebase(ctx, optarg)] = True
            idx = next_idx
            continue
        if arg in ["--compile-platform", "--enable-asserts"]:
            idx += 1
        elif not arg.startswith("-"):
            entry_points[__rebase(ctx, arg)] = True
            idx += 1
        else:
            fail("Unsupported modular_aot_compiler operand: %s" % arg)

def __parse_frontend_server(ctx, args, idx, entry_points, extra_paths):
    for _ in range(len(args)):
        if idx >= len(args):
            break
        arg = args[idx]
        matched, optarg, next_idx = __match_option(args, idx, ["--platform"])
        if matched:
            extra_paths[__rebase(ctx, optarg)] = True
            idx = next_idx
            continue
        matched, _, next_idx = __match_option(args, idx, ["--sdk-root"])
        if matched:
            idx = next_idx
            continue
        if arg == "--train":
            idx += 1
        elif not arg.startswith("-"):
            entry_points[__rebase(ctx, arg)] = True
            idx += 1
        else:
            fail("Unsupported frontend_server operand: %s" % arg)

def __parse_kernel_service_snapshot(ctx, args, idx, entry_points):
    for _ in range(len(args)):
        if idx >= len(args):
            break
        arg = args[idx]
        matched, optarg, next_idx = __match_option(args, idx, ["--train"])
        if matched:
            entry_points[__rebase(ctx, optarg)] = True
            idx = next_idx
        else:
            fail("Unsupported kernel_service_snapshot operand: %s" % arg)

def __parse_simple_flags(args, idx, allowed_flags, state_name):
    for _ in range(len(args)):
        if idx >= len(args):
            break
        arg = args[idx]
        if arg in allowed_flags:
            idx += 1
        else:
            fail("Unsupported %s operand: %s" % (state_name, arg))

def __parse_dart(ctx, dart_subdir, args, idx, entry_points, extra_paths):
    extra_paths[__rebase(ctx, path.join(dart_subdir, "dartvm"))] = True
    extra_paths[__rebase(ctx, path.join(dart_subdir, "snapshots/kernel-service.dart.snapshot"))] = True

    for _ in range(len(args)):
        if idx >= len(args):
            break
        arg = args[idx]
        matched, optarg, next_idx = __match_option(args, idx, ["--dfe"])
        if matched:
            extra_paths[__rebase(ctx, optarg)] = True
            idx = next_idx
            continue
        matched, _, next_idx = __match_option(args, idx, [
            "--snapshot",
            "--depfile",
            "--snapshot-depfile",
            "--packages",
            "-D",
            "--snapshot-kind",
            "--depfile_output_filename",
            "--coverage",
            "--ignore-unrecognized-flags",
            "--enable-asserts",
        ])
        if matched:
            idx = next_idx
            continue
        if arg in ["--deterministic", "--sound-null-safety", "--disable-experimental-vm-service"]:
            idx += 1
            continue
        if arg == "../../pkg/compiler/lib/src/dart2js.dart":
            entry_points[__rebase(ctx, arg)] = True
            __parse_dart2js(ctx, args, idx + 1, entry_points, extra_paths)
            return
        if arg.endswith("obj/utils/compiler/dart2js.jit.dill"):
            extra_paths[__rebase(ctx, arg)] = True
            __parse_dart2js(ctx, args, idx + 1, entry_points, extra_paths)
            return
        if arg == "../../pkg/dev_compiler/bin/dartdevc.dart":
            entry_points[__rebase(ctx, arg)] = True
            __parse_dartdevc(ctx, args, idx + 1, entry_points, extra_paths)
            return
        if arg.endswith("obj/utils/ddc/dartdevc.jit.dill"):
            extra_paths[__rebase(ctx, arg)] = True
            __parse_dartdevc(ctx, args, idx + 1, entry_points, extra_paths)
            return
        if arg.endswith("obj/utils/dartanalyzer/dartanalyzer.jit.dill"):
            extra_paths[__rebase(ctx, arg)] = True
            __parse_simple_flags(args, idx + 1, ["--help"], "dartanalyzer")
            return
        if arg.endswith("obj/utils/analysis_server/analysis_server.jit.dill"):
            extra_paths[__rebase(ctx, arg)] = True
            __parse_analysis_server(ctx, args, idx + 1, entry_points, extra_paths)
            return
        if arg == "../../utils/bazel/kernel_worker.dart":
            entry_points[__rebase(ctx, arg)] = True
            __parse_kernel_worker(ctx, args, idx + 1, entry_points, extra_paths)
            return
        if arg == "../../pkg/native_compiler/bin/modular_aot_compiler.dart":
            entry_points[__rebase(ctx, arg)] = True
            __parse_modular_aot_compiler(ctx, args, idx + 1, entry_points, extra_paths)
            return
        if arg.endswith("obj/utils/kernel-service/frontend_server.jit.dill"):
            extra_paths[__rebase(ctx, arg)] = True
            __parse_frontend_server(ctx, args, idx + 1, entry_points, extra_paths)
            return
        if arg.endswith("obj/utils/dtd/generate_dtd_snapshot.jit.dill"):
            extra_paths[__rebase(ctx, arg)] = True
            __parse_simple_flags(args, idx + 1, ["--train"], "generate_dtd_snapshot")
            return
        if arg.endswith("obj/utils/dds/generate_dds_snapshot.jit.dill"):
            extra_paths[__rebase(ctx, arg)] = True
            __parse_simple_flags(args, idx + 1, ["--help"], "generate_dds_snapshot")
            return
        if arg.endswith("obj/utils/bazel/kernel_worker.jit.dill"):
            extra_paths[__rebase(ctx, arg)] = True
            __parse_kernel_worker(ctx, args, idx + 1, entry_points, extra_paths)
            return
        if arg.endswith("obj/utils/dart_runtime_service_vm/generate_dart_runtime_service_vm_snapshot.jit.dill"):
            extra_paths[__rebase(ctx, arg)] = True
            __parse_simple_flags(args, idx + 1, ["--help"], "generate_dart_runtime_service_vm_snapshot")
            return
        if arg.endswith("obj/utils/dartdev/generate_dartdev_snapshot.jit.dill"):
            extra_paths[__rebase(ctx, arg)] = True
            __parse_simple_flags(args, idx + 1, ["--help"], "generate_dartdev_snapshot")
            return
        if arg.endswith("obj/utils/kernel-service/kernel-service_snapshot.jit.dill"):
            extra_paths[__rebase(ctx, arg)] = True
            extra_paths[__rebase(ctx, path.join(dart_subdir, "vm_platform.dill"))] = True
            __parse_kernel_service_snapshot(ctx, args, idx + 1, entry_points)
            return
        fail("Unsupported dart operand: %s" % arg)

def __parse_dartaotruntime(ctx, dart_subdir, args, idx, entry_points, extra_paths):
    for _ in range(len(args)):
        if idx >= len(args):
            break
        arg = args[idx]
        if arg.endswith("/dart2js_aot.dart.snapshot"):
            extra_paths[__rebase(ctx, path.join(dart_subdir, "snapshots/dart2js_aot.dart.snapshot"))] = True
            __parse_dart2js(ctx, args, idx + 1, entry_points, extra_paths)
            return
        if arg.endswith("/modular_aot_compiler.dart.snapshot"):
            extra_paths[__rebase(ctx, arg)] = True
            __parse_modular_aot_compiler(ctx, args, idx + 1, entry_points, extra_paths)
            return
        fail("Unsupported dartaotruntime operand: %s" % arg)

def __dart_action(ctx, cmd):
    if len(cmd.args) < 3:
        return
    binary = cmd.args[2]
    exec_binary = binary if "/" in binary else "./" + binary
    new_args = [exec_binary] + list(cmd.args[3:])

    if (binary == "gen_snapshot" or binary.endswith("/gen_snapshot") or
        binary == "gen_snapshot_product" or binary.endswith("/gen_snapshot_product")):
        ctx.actions.fix(args = new_args)
        return

    dart_subdir = path.dir(binary) if "/" in binary else "."
    entry_points = {}
    extra_paths = {}

    if binary == "dart" or binary.endswith("/dart") or binary == "dartvm" or binary.endswith("/dartvm"):
        __parse_dart(ctx, dart_subdir, cmd.args, 3, entry_points, extra_paths)
    elif binary == "dartaotruntime" or binary.endswith("/dartaotruntime"):
        __parse_dartaotruntime(ctx, dart_subdir, cmd.args, 3, entry_points, extra_paths)
    else:
        fail("Unsupported dart_action binary: %s" % binary)

    pkg_map = __load_package_map(ctx)
    uris = __find_inputs(ctx, entry_points.keys(), pkg_map)

    resolved_paths = {
        ".dart_tool/package_config.json": True,
    }
    for p in extra_paths.keys():
        resolved_paths[p] = True
    for uri in uris:
        p = __resolve_uri(uri, pkg_map, whole_dir = True)
        if p:
            resolved_paths[p] = True

    inputs = list(cmd.inputs)
    for p in sorted(resolved_paths.keys()):
        p = p.rstrip("/")
        if not ctx.fs.exists(p):
            continue
        if ctx.fs.is_dir(p):
            inputs.append(p + ":files")
        else:
            inputs.append(p)

    has_workdir_input = False
    for inp in inputs:
        if inp.startswith(cmd.dir + "/"):
            has_workdir_input = True
            break
    if not has_workdir_input:
        stamp = __rebase(ctx, "build.ninja.stamp")
        if ctx.fs.exists(stamp):
            inputs.append(stamp)

    ctx.actions.fix(
        args = new_args,
        inputs = inputs,
    )

def __filegroups(ctx):
    if not __enabled(ctx):
        return {}
    fg = {}
    pkg_map = __load_package_map(ctx)
    for pkg_dir in pkg_map.values():
        if ctx.fs.exists(pkg_dir) and ctx.fs.is_dir(pkg_dir):
            fg[pkg_dir + ":files"] = {
                "type": "glob",
                "includes": ["*"],
            }
    for extra_dir in ["sdk", "tools/sdks/dart-sdk/lib"]:
        if ctx.fs.exists(extra_dir) and ctx.fs.is_dir(extra_dir):
            fg[extra_dir + ":files"] = {
                "type": "glob",
                "includes": ["*"],
            }
    return fg

__handlers = {
    "dart_action": __dart_action,
}

def __step_config(ctx, step_config):
    if not __enabled(ctx):
        return step_config

    rules = step_config["rules"]

    # Local-only Dart actions:
    # - create_snapshot_entry.dart invokes python3 tools/make_version.py, and
    #   python3 is not installed in the RBE container image.
    # - build_dart_sdk_tar.dart simply tars the built SDK directory locally.
    # - bootstrap_compile_platform/bootstrap_gen_kernel and dartpad_worker emit
    #   depfiles containing absolute paths (https://dartbug.com/63495,
    #   https://dartbug.com/63546).
    rules.extend([
        {
            "name": "dart/create_snapshot_entry",
            "action": ".*_create_snapshot_entry_.*",
            "remote": False,
        },
        {
            "name": "dart/build_sdk_tar",
            "action": ".*_build_sdk_tar_.*",
            "remote": False,
        },
        {
            "name": "dart/bootstrap",
            "action": ".*_bootstrap_(compile_platform|gen_kernel)\\.(exe|dill)_.*",
            "remote": False,
        },
        {
            "name": "dart/dartpad_worker",
            "action": ".*_dartpad_worker_.*",
            "remote": False,
        },
    ])



    for prefix_label, subdir in [
        ("", ""),
        ("-clang_x64", "clang_x64/"),
    ]:
        rules.extend([
            {
                "name": "dart/gen_snapshot" + prefix_label,
                "command_prefix": "python3 ../../build/gn_run_binary.py " + subdir + "gen_snapshot",
                "handler": "dart_action",
                "remote": True,
                "timeout": "4m",
            },
            {
                "name": "dart/dartvm" + prefix_label,
                "command_prefix": "python3 ../../build/gn_run_binary.py " + subdir + "dartvm",
                "handler": "dart_action",
                "remote": True,
                "timeout": "4m",
            },
            {
                "name": "dart/dartaotruntime" + prefix_label,
                "command_prefix": "python3 ../../build/gn_run_binary.py " + subdir + "dartaotruntime",
                "handler": "dart_action",
                "remote": True,
                "timeout": "4m",
            },
        ])

    rules.append({
        "name": "dart/prebuilt_dart",
        "command_prefix": "python3 ../../build/gn_run_binary.py ../../tools/sdks/dart-sdk/bin/dart",
        "handler": "dart_action",
        "remote": True,
        "timeout": "4m",
    })

    return step_config

dart = module(
    "dart",
    step_config = __step_config,
    filegroups = __filegroups,
    handlers = __handlers,
)
