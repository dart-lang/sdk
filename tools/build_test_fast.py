#!/usr/bin/env python3
# Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""build_test_fast.py

A smart wrapper around tools/build.py and tools/test.py that uses a minimal,
declarative mapping to determine exactly what needs to be built for a given test.
This avoids building the entire SDK (like CI does) during local iteration.
"""

import argparse
import os
import subprocess
import sys
import utils

# Declarative mapping: (Path substring, Default compiler, Default build targets)
SUITE_RULES = [
    ('tests/web/wasm', 'dart2wasm', ['dart2wasm_bot']),
    ('pkg/dart2wasm', 'dart2wasm', ['dart2wasm_bot']),
    ('tests/dartdevc', 'ddc', ['ddc_stable_test_local']),
    ('pkg/dev_compiler', 'ddc', ['ddc_stable_test_local']),
    ('tests/web', 'dart2js', ['dart2js_bot']),
    ('pkg/compiler', 'dart2js', ['dart2js_bot']),
    ('pkg/analyzer', 'dart2analyzer', ['analyzer_bot']),
    ('pkg/analysis_server', 'dart2analyzer', ['analyzer_bot']),
    ('pkg/front_end', 'fasta', ['front-end_bot']),
]

COMPILER_TARGETS = {
    'dart2wasm': ['dart2wasm_bot'],
    'dart2js': ['dart2js_bot'],
    'ddc': ['ddc_stable_test_local'],
    'fasta': ['front-end_bot'],
    'dartkp': ['runtime', 'runtime_precompiled'],
    'dartk': ['runtime'],
    'vm': ['runtime'],
    'dart2analyzer': ['analyzer_bot'],
    'analyzer': ['analyzer_bot'],
}


def main():
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        '-c',
        '--compiler',
        dest='compiler',
        default=None,
        help='Compiler to use (e.g. dartk, dartkp, dart2js, dart2wasm, ddc, dart2analyzer). Inferred if omitted.',
    )
    parser.add_argument(
        '-m',
        '--mode',
        dest='mode',
        default='release',
        help='Build and test mode (release, debug, product). Default: release.',
    )
    parser.add_argument(
        '-a',
        '--arch',
        dest='arch',
        default=utils.GuessArchitecture(),
        help='Build and test architecture (x64, arm64, etc.). Default: host arch.',
    )
    parser.add_argument(
        '-r',
        '--runtime',
        dest='runtime',
        default=None,
        help='Target runtime (vm, d8, chrome, etc.). Inferred as d8 for web compilers if omitted.',
    )

    known, remaining = parser.parse_known_args()

    if not remaining and known.compiler is None:
        parser.print_help(file=sys.stderr)
        print(
            "\n⚠️ Please provide at least one test path or selector (e.g. corelib/uri_test, pkg/analyzer).",
            file=sys.stderr,
        )
        return 1

    # Discover compiler and targets from paths if compiler not explicitly passed
    compiler = known.compiler
    build_targets = set()

    for path in remaining:
        if path.startswith('-'):
            continue
        for pattern, default_compiler, targets in SUITE_RULES:
            if pattern in path:
                if compiler is None:
                    compiler = default_compiler
                build_targets.update(targets)
        if 'tests/ffi' in path:
            build_targets.update(
                ['ffi_test_functions', 'ffi_test_dynamic_library'])

    if compiler is None:
        compiler = 'dartk'

    # If targets weren't filled by path rules, resolve from compiler
    if not build_targets:
        build_targets.update(COMPILER_TARGETS.get(compiler, ['runtime']))

    # Default web tests to d8 to avoid browser popup spam
    runtime = known.runtime
    if runtime is None and compiler in ['dart2js', 'dart2wasm', 'ddc']:
        runtime = 'd8'

    tools_dir = os.path.dirname(os.path.abspath(__file__))
    separator = "🔹 " * 35

    # 1. Build Phase
    if build_targets:
        build_cmd = [
            sys.executable,
            os.path.join(tools_dir, 'build.py'),
            '-m',
            known.mode,
            '-a',
            known.arch,
            *sorted(build_targets),
        ]
        print(f"🚀 Building: python3 tools/build.py {' '.join(build_cmd[2:])}")
        print(separator)
        res = subprocess.run(build_cmd)
        print(separator)
        if res.returncode != 0:
            print("❌ Build failed! Aborting test run.", file=sys.stderr)
            return res.returncode
        print("⭐⭐⭐ Build succeeded! ⭐⭐⭐\n")
    else:
        print("❓ No build targets required!\n")

    # 2. Test Phase
    test_args = [
        '-c',
        compiler,
        '-m',
        known.mode,
        '-a',
        known.arch,
    ]
    if runtime:
        test_args.extend(['-r', runtime])
    test_args.extend(remaining)

    test_cmd = [sys.executable, os.path.join(tools_dir, 'test.py'), *test_args]
    print(f"🧪 Running tests: python3 tools/test.py {' '.join(test_args)}")
    print(separator)
    test_res = subprocess.run(test_cmd)
    print(separator)

    if test_res.returncode != 0:
        print("\n" + "⚠️ " * 35, file=sys.stderr)
        print("  TEST FAILED!", file=sys.stderr)
        print(
            "  If this failure looks like a missing build dependency,",
            file=sys.stderr,
        )
        print(
            "  update COMPILER_TARGETS or SUITE_RULES in tools/build_test_fast.py.",
            file=sys.stderr,
        )
        print("⚠️ " * 35 + "\n", file=sys.stderr)

    return test_res.returncode


if __name__ == '__main__':
    sys.exit(main())
