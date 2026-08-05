#!/usr/bin/env python3
# Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# build_test_fast.py
#
# A smart wrapper around tools/build.py and tools/test.py that uses a
# minimal, hardcoded mapping to determine exactly what needs to be built.
# This avoids building the entire SDK (like CI does) just to run a single test.

import sys
import os
import subprocess
import platform


def get_host_os():
    if sys.platform == 'win32':
        return 'win'
    elif sys.platform == 'darwin':
        return 'mac'
    return 'linux'


def get_host_arch():
    machine = platform.machine().lower()
    if machine in ['arm64', 'aarch64']:
        return 'arm64'
    return 'x64'


def get_minimal_build_targets(compiler, test_paths):
    targets = set()

    # 1. Base compiler targets (Minimal!)
    if compiler == 'dart2wasm':
        targets.update([
            'dartaotruntime', 'dart2wasm_platform.dill', 'dart2wasm',
            'create_common_sdk', 'wasm-opt'
        ])
    elif compiler == 'dart2js':
        # Often dart2js_bot or dart2js_platform.dill is enough, rather than create_sdk
        targets.update(
            ['dartaotruntime', 'dart2js_platform.dill', 'create_common_sdk'])
    elif compiler == 'ddc':
        targets.update(['ddc_stable_test_local', 'create_common_sdk'])
    elif compiler in ['analyzer', 'dart2analyzer']:
        pass  # Often no build needed, or just dartanalyzer
    elif compiler == 'dartkp':
        targets.update(['runtime', 'runtime_precompiled'])
    elif compiler in ['vm', 'dartk', 'app_jitk', 'none']:
        targets.update(['runtime'])
    else:
        targets.update(['runtime'])

    # 2. Path-specific add-ons
    for path in test_paths:
        if 'tests/ffi' in path:
            targets.update(['ffi_test_functions', 'ffi_test_dynamic_library'])

    return list(targets)


def guess_compiler_from_paths(test_paths):
    # Try to guess the best compiler based on the test paths
    for path in test_paths:
        # Wasm tests
        if 'tests/web/wasm' in path or 'pkg/dart2wasm' in path:
            return 'dart2wasm'
        # DDC specific tests
        elif 'tests/dartdevc' in path or 'pkg/dev_compiler' in path:
            return 'ddc'
        # General web / dart2js tests
        elif 'tests/web' in path or 'pkg/compiler' in path:
            return 'dart2js'
        # Analyzer / language server tests
        elif 'pkg/analyzer' in path or 'pkg/analysis_server' in path:
            return 'dart2analyzer'

    # Default to the VM's JIT compiler
    return 'dartk'


def main():
    args = sys.argv[1:]

    compiler = None
    runtime = None
    test_paths = []

    # test.py defaults to release mode, while build.py defaults to debug.
    # We MUST pass the mode and arch explicitly to build.py to match.
    mode = 'release'
    arch = get_host_arch()
    system = get_host_os()

    # Parse out compiler, mode, arch and test paths
    skip_next = False
    for i, arg in enumerate(args):
        if skip_next:
            skip_next = False
            continue

        if arg == '-c' or arg == '--compiler':
            compiler = args[i + 1]
            skip_next = True
        elif arg.startswith('--compiler='):
            compiler = arg.split('=', 1)[1]
        elif arg == '-m' or arg == '--mode':
            mode = args[i + 1]
            skip_next = True
        elif arg.startswith('--mode='):
            mode = arg.split('=', 1)[1]
        elif arg == '-a' or arg == '--arch':
            arch = args[i + 1]
            skip_next = True
        elif arg.startswith('--arch='):
            arch = arg.split('=', 1)[1]
        elif arg == '-r' or arg == '--runtime':
            runtime = args[i + 1]
            skip_next = True
        elif arg.startswith('--runtime='):
            runtime = arg.split('=', 1)[1]
        elif not arg.startswith('-'):
            test_paths.append(arg)

    # Infer the compiler if not explicitly provided
    inferred = False
    if compiler is None:
        compiler = guess_compiler_from_paths(test_paths)
        inferred = True

    if inferred:
        print(
            f"🔮 Inferred compiler '\033[1m{compiler}\033[0m' from test paths.")

    # Default to d8 for web tests to reduce noise, if no runtime specified
    inferred_runtime = False
    if runtime is None and compiler in ['dart2js', 'dart2wasm', 'ddc']:
        runtime = 'd8'
        inferred_runtime = True
        print(
            f"🔮 Inferred runtime '\033[1m{runtime}\033[0m' for web compiler to reduce noise."
        )

    build_args = get_minimal_build_targets(compiler, test_paths)

    targets_str = ' '.join(build_args) if build_args else '(none)'
    print(
        f"🎯 Determined minimal build targets for compiler '\033[1m{compiler}\033[0m': \033[1m{targets_str}\033[0m"
    )

    stars_line = "🔹 " * 35

    if build_args:
        # 3. Build Dart using the minimal targets, matching test.py's mode and arch defaults
        build_script = os.path.join(os.path.dirname(__file__), 'build.py')
        build_cmd = [sys.executable, build_script, '-m', mode, '-a', arch
                    ] + build_args
        print(f"🚀 Building: python3 tools/build.py {' '.join(build_cmd[2:])}")
        print(stars_line)

        build_result = subprocess.run(build_cmd)
        print(stars_line)

        if build_result.returncode != 0:
            print("❌ Build failed! Aborting test run.")
            sys.exit(build_result.returncode)

        print("⭐⭐⭐ Build succeeded! ⭐⭐⭐\n")
    else:
        print("❓ No build targets required!\n")

    # 4. Run the tests
    test_script = os.path.join(os.path.dirname(__file__), 'test.py')

    if inferred:
        args = ['-c', compiler] + args

    if inferred_runtime:
        args = ['-r', runtime] + args

    test_cmd = [sys.executable, test_script] + args
    print(f"🧪 Running tests: python3 tools/test.py {' '.join(args)}")
    print(stars_line)
    test_result = subprocess.run(test_cmd)
    print(stars_line)

    if test_result.returncode != 0:
        print("\n" + "⚠️ " * 35)
        print("  TEST FAILED!")
        print(
            "If this failure looks like a missing file, missing snapshot, or compilation error,"
        )
        print(
            "it's possible that `build_test_fast.py` didn't build all the required dependencies."
        )
        print(
            "💡 You may need to update the `get_minimal_build_targets()` mapping in this script."
        )
        print(
            "   (Check tools/bots/test_matrix.json to see what CI builds for this test suite!)"
        )
        print("⚠️ " * 35 + "\n")
    else:
        print("⭐⭐⭐ Tests succeeded! ⭐⭐⭐")

    sys.exit(test_result.returncode)


if __name__ == '__main__':
    main()
