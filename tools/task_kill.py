#!/usr/bin/env python3
#
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

# A script to kill hanging process. The tool will return non-zero if any
# process was actually found.
#

import optparse
import os
import signal
import subprocess
import sys

import utils

os_name = utils.GuessOS()

POSIX_INFO = 'ps -p %s -o args'

EXECUTABLE_NAMES = {
    'win32': {
        'chrome': 'chrome.exe',
        'crashpad_handler': 'crashpad_handler.exe',
        'dart': 'dart.exe',\
        'dart_product': 'dart_product.exe',
        'dartaotruntime': 'dartaotruntime.exe',
        'dartaotruntime_product': 'dartaotruntime_product.exe',
        'firefox': 'firefox.exe',
        'gen_snapshot': 'gen_snapshot.exe',
        'git': 'git.exe',
        'iexplore': 'iexplore.exe',
        'vctip': 'vctip.exe',
        'mspdbsrv': 'mspdbsrv.exe',
    },
    'linux': {
        'chrome': 'chrome',
        'dart': 'dart',
        'dart_product': 'dart_product',
        'dartaotruntime': 'dartaotruntime',
        'dartaotruntime_product': 'dartaotruntime_product',
        'firefox': 'firefox',
        'gen_snapshot': 'gen_snapshot',
        'flutter_tester': 'flutter_tester',
        'git': 'git',
    },
    'macos': {
        'chrome': 'Chrome',
        'chrome_helper': 'Chrome Helper',
        'dart': 'dart',
        'dart_product': 'dart_product',
        'dartaotruntime': 'dartaotruntime',
        'dartaotruntime_product': 'dartaotruntime_product',
        'firefox': 'firefox',
        'gen_snapshot': 'gen_snapshot',
        'git': 'git',
        'safari': 'Safari',
    }
}

INFO_COMMAND = {
    'win32': 'wmic process where Processid=%s get CommandLine',
    'macos': POSIX_INFO,
    'linux': POSIX_INFO,
}

STACK_INFO_COMMAND = {
    'win32': None,
    'macos': '/usr/bin/sample %s 1 4000 -mayDie',
    'linux': '/usr/bin/eu-stack -p %s',
}


def GetOptions():
    parser = optparse.OptionParser('usage: %prog [options]')
    true_or_false = ['True', 'False']
    parser.add_option(
        "--kill_dart",
        default='True',
        type='choice',
        choices=true_or_false,
        help="Kill all dart processes")
    parser.add_option(
        "--kill_vc",
        default='True',
        type='choice',
        choices=true_or_false,
        help="Kill all git processes")
    parser.add_option(
        "--kill_vsbuild",
        default='False',
        type='choice',
        choices=true_or_false,
        help="Kill all visual studio build related processes")
    parser.add_option(
        "--kill_browsers",
        default='False',
        type='choice',
        choices=true_or_false,
        help="Kill all browser processes")
    (options, args) = parser.parse_args()
    return options


def GetPidsPosix(process_name):
    # This is to have only one posix command, on linux we could just do:
    # pidof process_name
    cmd = 'ps -e -o pid= -o comm='
    # Sample output:
    # 1 /sbin/launchd
    # 80943 /Applications/Safari.app/Contents/MacOS/Safari
    p = subprocess.Popen(cmd,
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE,
                         shell=True,
                         universal_newlines=True)
    output, stderr = p.communicate()
    results = []
    lines = output.splitlines()
    for line in lines:
        split = line.split()
        # On mac this ps commands actually gives us the full path to non
        # system binaries.
        if len(split) >= 2 and " ".join(split[1:]).endswith(process_name):
            results.append(split[0])
    return results


def GetPidsWindows(process_name):
    cmd = 'tasklist /fo list /FI "IMAGENAME eq %s"' % process_name
    # Sample output:
    #   Image Name:   dart.exe
    #   PID:          26568
    #   Session Name: Console
    #   Session#:     1
    #   Mem Usage:    130,236 K
    #
    #   Image Name:   dart.exe
    #   PID:          22424
    #   Session Name: Console
    #   Session#:     1
    #   Mem Usage:    280,776 K

    p = subprocess.Popen(cmd,
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE,
                         shell=True,
                         universal_newlines=True)
    output, stderr = p.communicate()
    results = []
    lines = output.splitlines()

    for line in lines:
        split = line.split(':')
        if (len(split) == 2) and (split[0].strip() == 'PID'):
            results.append(split[1].strip())
    return results


def GetPids(process_name):
    if os_name == "win32":
        return GetPidsWindows(process_name)
    else:
        return GetPidsPosix(process_name)


def PrintPidStackInfo(pid):
    command_pattern = STACK_INFO_COMMAND.get(os_name, False)
    if command_pattern:
        p = subprocess.Popen(command_pattern % pid,
                             stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE,
                             shell=True,
                             universal_newlines=True)
        stdout, stderr = p.communicate()
        stdout = stdout.splitlines()
        stderr = stderr.splitlines()

        print("  Stack:")
        for line in stdout:
            print("    %s" % line)
        if stderr:
            print("  Stack (stderr):")
            for line in stderr:
                print("    %s" % line)


def PrintPidInfo(pid, dump_stacks):
    # We assume that the list command will return lines in the format:
    # EXECUTABLE_PATH ARGS
    # There may be blank strings in the output
    p = subprocess.Popen(INFO_COMMAND[os_name] % pid,
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE,
                         shell=True,
                         universal_newlines=True)
    output, stderr = p.communicate()
    lines = output.splitlines()

    # Pop the header
    lines.pop(0)

    print("Hanging process info:")
    print("  PID: %s" % pid)
    for line in lines:
        # wmic will output a bunch of empty strings, we ignore these
        if line: print("  Command line: %s" % line)

    if dump_stacks:
        PrintPidStackInfo(pid)


def KillPosix(pid):
    try:
        os.kill(int(pid), signal.SIGKILL)
    except:
        # Ignore this, the process is already dead from killing another process.
        pass


def KillWindows(pid):
    # os.kill is not available until python 2.7
    cmd = "taskkill /F /PID %s" % pid
    p = subprocess.Popen(cmd,
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE,
                         shell=True,
                         universal_newlines=True)
    p.communicate()


def Kill(name, dump_stacks=False):
    if name not in EXECUTABLE_NAMES[os_name]:
        return 0
    print("***************** Killing %s *****************" % name)
    platform_name = EXECUTABLE_NAMES[os_name][name]
    pids = GetPids(platform_name)
    for pid in pids:
        PrintPidInfo(pid, dump_stacks)
        if os_name == "win32":
            KillWindows(pid)
        else:
            KillPosix(pid)
        print("Killed pid: %s" % pid)
    if len(pids) == 0:
        print("  No %s processes found." % name)
    return len(pids)


def KillBrowsers():
    status = Kill('firefox')
    # We don't give error on killing chrome. It happens quite often that the
    # browser controller fails in killing chrome, so we silently do it here.
    Kill('chrome')
    status += Kill('chrome_helper')
    status += Kill('iexplore')
    status += Kill('safari')
    return status


def KillVCSystems():
    status = Kill('git')
    return status


def KillVSBuild():
    status = Kill('vctip')
    status += Kill('mspdbsrv')
    return status


def KillDart():
    status = Kill("dart", dump_stacks=True)
    status += Kill("gen_snapshot", dump_stacks=True)
    status += Kill("dartaotruntime", dump_stacks=True)
    status += Kill("dartaotruntime_product", dump_stacks=True)
    status += Kill("flutter_tester", dump_stacks=True)
    status += Kill("crashpad_handler", dump_stacks=True)
    return status


def Main():
    options = GetOptions()
    status = 0
    if options.kill_dart == 'True':
        if os_name == "win32":
            # TODO(24086): Add result of KillDart into status once pub hang is fixed.
            KillDart()
        else:
            status += KillDart()
    if options.kill_vc == 'True':
        status += KillVCSystems()
    if options.kill_vsbuild == 'True' and os_name == 'win32':
        status += KillVSBuild()
    if options.kill_browsers == 'True':
        status += KillBrowsers()
    return status


if __name__ == '__main__':
    sys.exit(Main())
