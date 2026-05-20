#!/usr/bin/env python3
# Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import argparse
import os
import shutil
import subprocess
import sys

tools_dir = os.path.dirname(os.path.realpath(__file__))
sys.path.append(tools_dir)
import utils


def main():
    parser = argparse.ArgumentParser(description='Builds the DevTools app.')
    parser.add_argument('--output', help='Output directory')
    args = parser.parse_args()

    if args.output:
        args.output = os.path.abspath(args.output)

    # Set up paths relative to the SDK root.
    sdk_root = utils.DART_DIR
    devtools_src_dir = os.path.join(sdk_root, 'third_party', 'devtools_src')
    devtools_app_dir = os.path.join(devtools_src_dir, 'packages',
                                    'devtools_app')

    if not os.path.isdir(devtools_src_dir):
        print(
            f'Missing devtools dir in devtools sources "{devtools_src_dir}"; '
            'make sure that "../.client" has a `custom_vars` section with '
            '"`"build_devtools_from_sources": True,` and then run `gclient sync`'
            '\n')
        return 1

    if not os.path.isdir(devtools_app_dir):
        print(
            f'Error: DevTools app directory not found at {devtools_app_dir}\n')
        return 1

    flutter_bin = os.path.normpath(
        os.path.join(sdk_root, 'third_party', 'flutter', 'bin', 'flutter'))
    if utils.GuessOS() == 'win32':
        flutter_bin += '.bat'
    if not os.path.isfile(flutter_bin):
        print(
            f'Missing Flutter SDK at "{flutter_bin}"; '
            'make sure that "../.client" has a `custom_vars` section with '
            '"`"build_devtools_from_sources": True,` and then run `gclient sync`'
            '\n')
        return 1

    try:
        os.chdir(devtools_app_dir)

        print(f'Running {flutter_bin} pub get...')
        subprocess.run([flutter_bin, 'pub', 'get'], check=True)

        print(f'Changing directory to {devtools_src_dir}')
        os.chdir(devtools_src_dir)

        # We use the 'dart' binary found in the same directory as the 'flutter' binary.
        dart_bin = os.path.join(os.path.dirname(flutter_bin), 'dart')
        if utils.GuessOS() == 'win32':
            dart_bin += '.exe'
        dt_path = os.path.join('tool', 'bin', 'dt.dart')

        print(f'Building DevTools web app using dt tool...')
        build_command = [
            dart_bin, dt_path, f'--flutter-sdk-path={flutter_bin}', 'build'
        ]
        subprocess.run(build_command, check=True)

        build_dir = os.path.join(devtools_app_dir, 'build', 'web')
        main_js = os.path.join(build_dir, 'main.dart.js')
        main_wasm = os.path.join(build_dir, 'main.dart.wasm')

        if not os.path.isfile(main_js):
            print(f'Missing expected built JS app at "{main_js}"\n')
            return 1

        if not os.path.isfile(main_wasm):
            print(f'Missing expected built WASM app at "{main_wasm}"\n')
            return 1

        if args.output:
            print(f'Copying build results to {args.output}...')
            if os.path.isdir(args.output):
                shutil.rmtree(args.output)
            elif os.path.exists(args.output):
                os.remove(args.output)
            shutil.copytree(build_dir, args.output)
            shutil.rmtree(build_dir)

        print('DevTools build successful.')
        return 0
    except subprocess.CalledProcessError as e:
        print(f'Error: Command failed with exit code {e.returncode}')
        return e.returncode
    except Exception as e:
        print(f'An unexpected error occurred: {e}')
        return 1


if __name__ == '__main__':
    sys.exit(main())
