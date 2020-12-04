#!/usr/bin/env python
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
        description='Runs GN (if ncecessary) followed by ninja',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    config_group = parser.add_argument_group('Configuration Related Arguments')
    gn_py.AddCommonConfigurationArgs(config_group)

    gn_group = parser.add_argument_group('GN Related Arguments')
    gn_py.AddCommonGnOptionArgs(gn_group)

    other_group = parser.add_argument_group('Other Arguments')
    gn_py.AddOtherArgs(other_group)

    other_group.add_argument("-j",
                             type=int,
                             help='Ninja -j option for Goma builds.',
                             default=1000)
    other_group.add_argument("-l",
                             type=int,
                             help='Ninja -l option for Goma builds.',
                             default=64)
    other_group.add_argument("--no-start-goma",
                             help="Don't try to start goma",
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

def UseGoma(out_dir):
    args_gn = os.path.join(out_dir, 'args.gn')
    return 'use_goma = true' in open(args_gn, 'r').read()


# Try to start goma, but don't bail out if we can't. Instead print an error
# message, and let the build fail with its own error messages as well.
goma_started = False


def EnsureGomaStarted(out_dir):
    global goma_started
    if goma_started:
        return True
    args_gn_path = os.path.join(out_dir, 'args.gn')
    goma_dir = None
    with open(args_gn_path, 'r') as fp:
        for line in fp:
            if 'goma_dir' in line:
                words = line.split()
                goma_dir = words[2][1:-1]  # goma_dir = "/path/to/goma"
    if not goma_dir:
        print('Could not find goma for ' + out_dir)
        return False
    if not os.path.exists(goma_dir) or not os.path.isdir(goma_dir):
        print('Could not find goma at ' + goma_dir)
        return False
    goma_ctl = os.path.join(goma_dir, 'goma_ctl.py')
    goma_ctl_command = [
        'python',
        goma_ctl,
        'ensure_start',
    ]
    process = subprocess.Popen(goma_ctl_command)
    process.wait()
    if process.returncode != 0:
        print(
            "Tried to run goma_ctl.py, but it failed. Try running it manually: "
            + "\n\t" + ' '.join(goma_ctl_command))
        return False
    goma_started = True
    return True

# Returns a tuple (build_config, command to run, whether goma is used)
def BuildOneConfig(options, targets, target_os, mode, arch, sanitizer):
    build_config = utils.GetBuildConf(mode, arch, target_os, sanitizer)
    out_dir = utils.GetBuildRoot(HOST_OS, mode, arch, target_os, sanitizer)
    using_goma = False
    command = ['ninja', '-C', out_dir]
    if options.verbose:
        command += ['-v']
    if UseGoma(out_dir):
        if options.no_start_goma or EnsureGomaStarted(out_dir):
            using_goma = True
            command += [('-j%s' % str(options.j))]
            command += [('-l%s' % str(options.l))]
        else:
            # If we couldn't ensure that goma is started, let the build start, but
            # slowly so we can see any helpful error messages that pop out.
            command += ['-j1']
    command += targets
    return (build_config, command, using_goma)


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


def Main():
    starttime = time.time()
    # Parse the options.
    parser = BuildOptions()
    options = parser.parse_args()

    targets = options.build_targets
    if len(targets) == 0:
        targets = ['all']

    if not gn_py.ProcessOptions(options):
        parser.print_help()
        return 1

    # If binaries are built with sanitizers we should use those flags.
    # If the binaries are not built with sanitizers the flag should have no
    # effect.
    env = dict(os.environ)
    env.update(SanitizerEnvironmentVariables())

    # Always run GN before building.
    gn_py.RunGnOnConfiguredConfigurations(options)

    # Build all targets for each requested configuration.
    configs = []
    for target_os in options.os:
        for mode in options.mode:
            for arch in options.arch:
                for sanitizer in options.sanitizer:
                    configs.append(
                        BuildOneConfig(options, targets, target_os, mode, arch,
                                       sanitizer))

    # Build regular configs.
    goma_builds = []
    for (build_config, args, goma) in configs:
        if args is None:
            return 1
        if goma:
            goma_builds.append([env, args])
        elif RunOneBuildCommand(build_config, args, env=env) != 0:
            return 1

    # Run goma builds in parallel.
    active_goma_builds = []
    for (env, args) in goma_builds:
        print(' '.join(args))
        process = subprocess.Popen(args, env=env)
        active_goma_builds.append([args, process])
    while active_goma_builds:
        time.sleep(0.1)
        for goma_build in active_goma_builds:
            (args, process) = goma_build
            if process.poll() is not None:
                print(' '.join(args) + " done.")
                active_goma_builds.remove(goma_build)
                if process.returncode != 0:
                    for (_, to_kill) in active_goma_builds:
                        to_kill.terminate()
                    return 1

    endtime = time.time()
    print("The build took %.3f seconds" % (endtime - starttime))
    return 0


if __name__ == '__main__':
    sys.exit(Main())
