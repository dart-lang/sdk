#!/usr/bin/env python3
# Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import shutil
import subprocess
import sys

tools_dir = os.path.dirname(os.path.realpath(__file__))
sys.path.append(tools_dir)
import utils


def run_command(command, cwd, env=None):
    print(f"Running: {' '.join(command)} in {cwd}")
    if env:
        print(f"With environment: {env}")

    # TODO(srawlins): Check how to run bash scripts on Windows, or convert the
    # devtools scripts to Dart or batch scripts...
    # On Windows, if we're running a '.sh' script, we need bash.
    # if utils.GuessOS() == 'win32' and command[0].endswith('.sh'):
    #     # Assume bash is in PATH (standard for Git for Windows).
    #     command = ['bash'] + command

    subprocess.run(command, cwd=cwd, env=env, check=True)


def find_chrome_executable(sdk_root, platform):
    browsers_chrome_dir = os.path.join(sdk_root, 'third_party', 'browsers',
                                       'chrome')
    candidates = []
    if platform == 'macos':
        candidates = [
            os.path.join(browsers_chrome_dir, 'Google Chrome.app', 'Contents',
                         'MacOS', 'Google Chrome'),
            '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
        ]
    elif platform == 'linux':
        candidates = [
            os.path.join(browsers_chrome_dir, 'chrome', 'google-chrome'),
            '/usr/bin/google-chrome',
        ]

    for candidate in candidates:
        if os.path.isfile(candidate):
            return os.path.abspath(candidate)

    # Fallback to system PATH for local development machines.
    for name in ['google-chrome', 'chrome']:
        path = shutil.which(name)
        if path:
            return os.path.abspath(path)

    return None


def main():
    host_os = utils.GuessOS()
    if host_os == 'win32':
        platform = 'windows'
    elif host_os == 'macos':
        platform = 'macos'
    elif host_os == 'linux':
        platform = 'linux'
    else:
        print(f'Unsupported platform: "{host_os}"\n')
        return 1

    # TODO(srawlins): Enable Windows testing.
    if platform == 'windows':
        print('DevTools tests are currently skipped on Windows.')
        return 0

    # Set up paths relative to the SDK root.
    sdk_root = utils.DART_DIR
    devtools_src_dir = os.path.join(sdk_root, 'third_party', 'devtools_src')

    if not os.path.isdir(devtools_src_dir):
        print(
            f'Missing devtools dir in devtools sources "{devtools_src_dir}"; '
            'make sure that "../.client" has a `custom_vars` section with '
            '"`"build_devtools_from_source": True,` and then run `gclient sync`'
            '\n')
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

    env = os.environ.copy()
    env['FLUTTER_GIT_URL'] = (
        'https://dart.googlesource.com/external/github.com/flutter/flutter.git')
    env['DEVTOOLS_TOOL_FLUTTER_FROM_PATH'] = 'true'

    if 'RUNNER_OS' not in env:
        if platform == 'windows':
            env['RUNNER_OS'] = 'Windows'
        elif platform == 'macos':
            env['RUNNER_OS'] = 'macOS'
        else:
            env['RUNNER_OS'] = 'Linux'

    path_sep = ';' if utils.GuessOS() == 'win32' else ':'

    flutter_bin_dir = os.path.join(flutter_dir, 'bin')
    env['PATH'] = f"{flutter_bin_dir}{path_sep}{env.get('PATH', '')}"

    chromedriver_dir = os.path.join(sdk_root, 'third_party', 'webdriver',
                                    'chrome')
    if os.path.isdir(chromedriver_dir):
        env['PATH'] = f"{chromedriver_dir}{path_sep}{env.get('PATH', '')}"

    chrome_bin = find_chrome_executable(sdk_root, platform)
    if chrome_bin:
        print(f'Using Chrome executable: {chrome_bin}')
        env['CHROME_EXECUTABLE'] = chrome_bin
        env['CHROME_PATH'] = chrome_bin
        chrome_dir = os.path.dirname(chrome_bin)
        env['PATH'] = f"{chrome_dir}{path_sep}{env.get('PATH', '')}"
    else:
        print('Warning: Chrome executable not found; web tests may fail.')

    jobs = []

    if platform in ['linux', 'windows']:
        jobs.append({'script': 'tool/ci/bots.sh', 'env': {'BOT': 'main'}})

        for pkg in [
                'devtools_app_shared',
                # TODO(srawlins): Enable devtools_extensions tests.
                # 'devtools_extensions',
                'devtools_shared',
        ]:
            jobs.append({
                'script': 'tool/ci/package_tests.sh',
                'env': {
                    'PACKAGE': pkg
                }
            })

        jobs.append({'script': 'tool/ci/tool_tests.sh', 'env': {}})

        for bot in ['build_ddc', 'build_dart2js', 'test_ddc', 'test_dart2js']:
            jobs.append({
                'script': 'tool/ci/bots.sh',
                'env': {
                    'BOT': bot,
                    'PLATFORM': 'vm'
                }
            })

        # TODO(srawlins): Enable devtools_extensions integration tests.
        # for bot in ['integration_dart2js', 'integration_dart2wasm']:
        #     jobs.append({
        #         'script': 'tool/ci/bots.sh',
        #         'env': {
        #             'BOT': bot,
        #             'DEVTOOLS_PACKAGE': 'devtools_extensions'
        #         }
        #     })

        jobs.append({
            'script': 'tool/ci/bots.sh',
            'env': {
                'BOT': 'test_webdriver',
                'PLATFORM': 'vm'
            }
        })

        # TODO(srawlins): Enable benchmark_size tests.
        # if platform == 'linux':
        #     jobs.append({'script': 'tool/ci/benchmark_size.sh', 'env': {}})

    if platform == 'macos':
        jobs.append({
            'script': 'tool/ci/bots.sh',
            'env': {
                'BOT': 'test_dart2js',
                'PLATFORM': 'vm',
                'ONLY_GOLDEN': 'true'
            }
        })

        # TODO(srawlins): Enable devtools_app integration tests.
        # for bot in ['integration_dart2js', 'integration_dart2wasm']:
        #     jobs.append({
        #         'script': 'tool/ci/bots.sh',
        #         'env': {
        #             'BOT': bot,
        #             'DEVICE': 'flutter',
        #             'DEVTOOLS_PACKAGE': 'devtools_app'
        #         }
        #     })
        #     jobs.append({
        #         'script': 'tool/ci/bots.sh',
        #         'env': {
        #             'BOT': bot,
        #             'DEVICE': 'flutter-web',
        #             'DEVTOOLS_PACKAGE': 'devtools_app'
        #         }
        #     })
        #     jobs.append({
        #         'script': 'tool/ci/bots.sh',
        #         'env': {
        #             'BOT': bot,
        #             'DEVICE': 'dart-cli',
        #             'DEVTOOLS_PACKAGE': 'devtools_app'
        #         }
        #     })

        # TODO(srawlins): Enable benchmark_performance tests.
        # jobs.append({'script': 'tool/ci/benchmark_performance.sh', 'env': {}})

    for i, job in enumerate(jobs):
        print(
            f"\nJob {i+1}/{len(jobs)}: {job['env'] if job['env'] else job['script']}"
        )
        try:
            job_env = env.copy()
            if job.get('env'):
                job_env.update(job['env'])
            run_command(['./' + job['script']],
                        cwd=devtools_src_dir,
                        env=job_env)
        except subprocess.CalledProcessError as e:
            print(f'Error: Job failed with exit code {e.returncode}')
            return e.returncode
        except Exception as e:
            print(f'An unexpected error occurred: {e}')
            return 1

    print(f"\nAll DevTools tests for {platform} completed successfully.")
    return 0


if __name__ == '__main__':
    sys.exit(main())
