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
            '"`"build_devtools_from_source": True,` and then run `gclient sync`'
            '\n')
        return 1

    if not os.path.isdir(devtools_app_dir):
        print(
            f'Error: DevTools app directory not found at {devtools_app_dir}\n')
        return 1

    flutter_dir = os.path.normpath(
        os.path.join(sdk_root, 'third_party', 'flutter'))
    flutter_shell = os.path.join(flutter_dir, 'bin', 'flutter')
    if utils.GuessOS() == 'win32':
        flutter_shell += '.bat'

    if not os.path.isfile(flutter_shell):
        print(
            f'Missing Flutter SDK at "{flutter_shell}"; '
            'make sure that "../.client" has a `custom_vars` section with '
            '"`"build_devtools_from_source": True,` and then run `gclient sync`'
            '\n')
        return 1


    # The flutter tool "figures out" it's version number in a very complex way. It
    # depends on some caching, and also the tags at the remote git repository, and
    # the URL of the remote git repository, which doesn't fit well with our
    # googlesource mirror. The simplest way to trick the flutter tool into using a
    # good version number is to create a tag of the form '#.#.#-#.#.pre' (or #.#.#,
    # I imagine). This can be obtained by running `./bin/flutter --version` in a
    # checkout of the flutter repository at the commit indicated by 'flutter_rev'
    # in `DEPS`.
    # TODO(https://github.com/dart-lang/sdk/issues/64027): Figure out someething better.
    FLUTTER_TAG = '3.48.0-1.0.pre'

    env = os.environ.copy()
    env['FLUTTER_GIT_URL'] = (
        'https://dart.googlesource.com/external/github.com/flutter/flutter.git')

    # Clear out the third_party/flutter/bin/cache directory.
    flutter_cache_dir = os.path.join(flutter_dir, 'bin', 'cache')
    print(f'Clearing flutter cache directory: {flutter_cache_dir}', flush=True)
    if os.path.isdir(flutter_cache_dir):
        try:
            shutil.rmtree(flutter_cache_dir)
        except Exception as e:
            print(f'Failed to clear flutter cache directory: {e}', flush=True)

    print(f'Creating local git tag {FLUTTER_TAG} in {flutter_dir}', flush=True)
    try:
        subprocess.run(['git', 'tag', '-f', FLUTTER_TAG], cwd=flutter_dir)
    except Exception as e:
        print(f'Failed to create git tag: {e}', flush=True)

    print('Running flutter --version', flush=True)
    try:
        subprocess.run([flutter_shell, '--version'], cwd=flutter_dir, env=env)
    except Exception as e:
        print(f'Failed to run flutter --version: {e}', flush=True)

    try:
        os.chdir(devtools_app_dir)

        print(f'Running {flutter_shell} pub get...')
        subprocess.run([flutter_shell, 'pub', 'get'], check=True, env=env)

        print(f'Changing directory to {devtools_src_dir}')
        os.chdir(devtools_src_dir)

        # We use the 'dart' script found in the same directory as the 'flutter' binary.
        dart_script = os.path.join(os.path.dirname(flutter_shell), 'dart')
        if utils.GuessOS() == 'win32':
            dart_script += '.bat'
        dt_path = os.path.join('tool', 'bin', 'dt.dart')

        print(f'Building DevTools web app using dt tool...')
        build_command = [
            dart_script, dt_path, f'--flutter-sdk-path={flutter_shell}', 'build'
        ]
        subprocess.run(build_command, check=True, env=env)

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

            print(f'Running {flutter_shell} clean...')
            subprocess.run([flutter_shell, 'clean'],
                           cwd=devtools_app_dir,
                           check=True,
                           env=env)

            print(f'Running git checkout pupspec.lock...')
            subprocess.run(['git', 'checkout', 'pubspec.lock'],
                           cwd=devtools_src_dir,
                           check=True)

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
