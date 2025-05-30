#!/usr/bin/env python3
#
# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import argparse
import io
import json
import os
import subprocess
import sys
import time
import utils

import gn as gn_py

HOST_OS = utils.GuessOS()
HOST_CPUS = utils.GuessCpus()
SCRIPT_DIR = os.path.dirname(sys.argv[0])
DART_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))
AVAILABLE_ARCHS = utils.ARCH_FAMILY.keys()

usage = """\
usage: %%prog [options] [targets]

This script invokes ninja to build Dart.
"""

def BuildOptions():
    parser = argparse.ArgumentParser(
        description='Runs GN (if necessary) followed by ninja',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    config_group = parser.add_argument_group('Configuration Related Arguments')
    gn_py.AddCommonConfigurationArgs(config_group)

    gn_group = parser.add_argument_group('GN Related Arguments')
    gn_py.AddCommonGnOptionArgs(gn_group)

    other_group = parser.add_argument_group('Other Arguments')
    gn_py.AddOtherArgs(other_group)

    other_group.add_argument("-j",
                             type=int,
                             help='Ninja -j option for RBE builds.',
                             default=200 if sys.platform == 'win32' else 500)
    other_group.add_argument("-l",
                             type=int,
                             help='Ninja -l option for RBE builds.',
                             default=64)
    other_group.add_argument("--no-start-rbe",
                             help="Don't try to start rbe",
                             default=False,
                             action='store_true')
    other_group.add_argument(
        "--check-clean",
        help="Check that a second invocation of Ninja has nothing to do",
        default=False,
        action='store_true')

    parser.add_argument('build_targets', nargs='*')

    return parser


def NotifyBuildDone(build_config, success, start):
    if not success:
        print("BUILD FAILED")

    sys.stdout.flush()

    # Display a notification if build time exceeded DART_BUILD_NOTIFICATION_DELAY.
    notification_delay = float(
        os.getenv('DART_BUILD_NOTIFICATION_DELAY', sys.float_info.max))
    if (time.time() - start) < notification_delay:
        return

    if success:
        message = 'Build succeeded.'
    else:
        message = 'Build failed.'
    title = build_config

    command = None
    if HOST_OS == 'macos':
        # Use AppleScript to display a UI non-modal notification.
        script = 'display notification  "%s" with title "%s" sound name "Glass"' % (
            message, title)
        command = "osascript -e '%s' &" % script
    elif HOST_OS == 'linux':
        if success:
            icon = 'dialog-information'
        else:
            icon = 'dialog-error'
        command = "notify-send -i '%s' '%s' '%s' &" % (icon, message, title)
    elif HOST_OS == 'win32':
        if success:
            icon = 'info'
        else:
            icon = 'error'
        command = (
            "powershell -command \""
            "[reflection.assembly]::loadwithpartialname('System.Windows.Forms')"
            "| Out-Null;"
            "[reflection.assembly]::loadwithpartialname('System.Drawing')"
            "| Out-Null;"
            "$n = new-object system.windows.forms.notifyicon;"
            "$n.icon = [system.drawing.systemicons]::information;"
            "$n.visible = $true;"
            "$n.showballoontip(%d, '%s', '%s', "
            "[system.windows.forms.tooltipicon]::%s);\"") % (
                5000,  # Notification stays on for this many milliseconds
                message,
                title,
                icon)

    if command:
        # Ignore return code, if this command fails, it doesn't matter.
        os.system(command)


def UseRBE(out_dir):
    args_gn = os.path.join(out_dir, 'args.gn')
    return 'use_rbe = true' in open(args_gn, 'r').read()


# Try to start RBE, but don't bail out if we can't. Instead print an error
# message, and let the build fail with its own error messages as well.
rbe_started = False
bootstrap_path = None


def StartRBE(out_dir, env):
    global rbe_started, bootstrap_path
    if not rbe_started:
        if HOST_OS == 'win32':
            rbe_dir = 'buildtools/reclient-win'
        elif HOST_OS == 'linux':
            rbe_dir = 'buildtools/reclient-linux'
        else:
            rbe_dir = 'buildtools/reclient'
        with open(os.path.join(out_dir, 'args.gn'), 'r') as fp:
            for line in fp:
                if 'rbe_dir' in line:
                    words = line.split()
                    rbe_dir = words[2][1:-1]  # rbe_dir = "/path/to/rbe"
        bootstrap_path = os.path.join(rbe_dir, 'bootstrap')
        bootstrap_command = [bootstrap_path]
        process = subprocess.Popen(bootstrap_command, env=env)
        process.wait()
        if process.returncode != 0:
            print('Failed to start RBE')
            return False
        rbe_started = True
    return True


def StopRBE(env):
    global rbe_started, bootstrap_path
    if rbe_started:
        bootstrap_command = [bootstrap_path, '--shutdown']
        process = subprocess.Popen(bootstrap_command, env=env)
        process.wait()
        rbe_started = False


# Returns a tuple (build_config, command to run, whether rbe is used)
def BuildOneConfig(options, targets, target_os, mode, arch, sanitizer, env):
    build_config = utils.GetBuildConf(mode, arch, target_os, sanitizer)
    out_dir = utils.GetBuildRoot(HOST_OS, mode, arch, target_os, sanitizer)
    using_rbe = False
    command = ['buildtools/ninja/ninja', '-C', out_dir]
    if options.verbose:
        command += ['-v']
    if UseRBE(out_dir):
        if options.no_start_rbe or StartRBE(out_dir, env):
            using_rbe = True
            command += [('-j%s' % str(options.j))]
            command += [('-l%s' % str(options.l))]
        else:
            exit(1)
    command += targets
    return (build_config, command, using_rbe)


def RunOneBuildCommand(build_config, args, env):
    start_time = time.time()
    print(' '.join(args))
    process = subprocess.Popen(args, env=env, stdin=None)
    process.wait()
    if process.returncode != 0:
        NotifyBuildDone(build_config, success=False, start=start_time)
        return 1
    else:
        NotifyBuildDone(build_config, success=True, start=start_time)

    return 0


def CheckCleanBuild(build_config, args, env):
    args = args + ['-n', '-d', 'explain']
    print(' '.join(args))
    process = subprocess.Popen(args,
                               env=env,
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE,
                               stdin=None)
    out, err = process.communicate()
    process.wait()
    if process.returncode != 0:
        return 1
    if 'ninja: no work to do' not in out.decode('utf-8'):
        print(err.decode('utf-8'))
        return 1

    return 0


def SanitizerEnvironmentVariables():
    with io.open('tools/bots/test_matrix.json', encoding='utf-8') as fd:
        config = json.loads(fd.read())
        env = dict()
        for k, v in config['sanitizer_options'].items():
            env[str(k)] = str(v)
        symbolizer_path = config['sanitizer_symbolizer'].get(HOST_OS, None)
        if symbolizer_path:
            symbolizer_path = str(os.path.join(DART_ROOT, symbolizer_path))
            env['ASAN_SYMBOLIZER_PATH'] = symbolizer_path
            env['LSAN_SYMBOLIZER_PATH'] = symbolizer_path
            env['MSAN_SYMBOLIZER_PATH'] = symbolizer_path
            env['TSAN_SYMBOLIZER_PATH'] = symbolizer_path
            env['UBSAN_SYMBOLIZER_PATH'] = symbolizer_path
        return env


def Build(configs, env, options):
    # Build regular configs.
    rbe_builds = []
    for (build_config, args, rbe) in configs:
        if args is None:
            return 1
        if rbe:
            rbe_builds.append([env, args])
        elif RunOneBuildCommand(build_config, args, env=env) != 0:
            return 1

    # Run RBE builds in parallel.
    active_rbe_builds = []
    for (env, args) in rbe_builds:
        print(' '.join(args))
        process = subprocess.Popen(args, env=env)
        active_rbe_builds.append([args, process])
    while active_rbe_builds:
        time.sleep(0.1)
        for rbe_build in active_rbe_builds:
            (args, process) = rbe_build
            if process.poll() is not None:
                print(' '.join(args) + " done.")
                active_rbe_builds.remove(rbe_build)
                if process.returncode != 0:
                    for (_, to_kill) in active_rbe_builds:
                        to_kill.terminate()
                    return 1

    if options.check_clean:
        for (build_config, args, rbe) in configs:
            if CheckCleanBuild(build_config, args, env=env) != 0:
                return 1

    return 0


def Main():
    starttime = time.time()
    # Parse the options.
    parser = BuildOptions()
    options = parser.parse_args()

    targets = options.build_targets

    if not gn_py.ProcessOptions(options):
        parser.print_help()
        return 1

    # If binaries are built with sanitizers we should use those flags.
    # If the binaries are not built with sanitizers the flag should have no
    # effect.
    env = dict(os.environ)
    env.update(SanitizerEnvironmentVariables())

    # macOS's python sets CPATH, LIBRARY_PATH, SDKROOT implicitly.
    #
    # See:
    #
    #   * https://openradar.appspot.com/radar?id=5608755232243712
    #   * https://github.com/dart-lang/sdk/issues/52411
    #
    # Remove these environment variables to avoid affecting clang's behaviors.
    if sys.platform == 'darwin':
        env.pop('CPATH', None)
        env.pop('LIBRARY_PATH', None)
        env.pop('SDKROOT', None)

    # Help QEMU binfmt work for executables that include dynamic links, such as
    # reclient's scandeps_server.
    if sys.platform == 'linux':
        env['QEMU_LD_PREFIX'] = "/usr/x86_64-linux-gnu/"

    # Always run GN before building.
    gn_py.RunGnOnConfiguredConfigurations(options, env)

    # Build all targets for each requested configuration.
    configs = []
    for target_os in options.os:
        for mode in options.mode:
            for arch in options.arch:
                for sanitizer in options.sanitizer:
                    configs.append(
                        BuildOneConfig(options, targets, target_os, mode, arch,
                                       sanitizer, env))

    exit_code = Build(configs, env, options)

    endtime = time.time()

    StopRBE(env)

    if exit_code == 0:
        print("The build took %.3f seconds" % (endtime - starttime))
    return exit_code


if __name__ == '__main__':
    sys.exit(Main())
