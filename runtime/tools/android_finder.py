#!/usr/bin/env python

# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""
Find an Android device with a given ABI.

The name of the Android device is printed to stdout.

Optionally configure and launch an emulator if there's no existing device for a
given ABI. Will download and install Android SDK components as needed.
"""

import optparse
import os
import re
import sys
import traceback
import utils

DEBUG = False
VERBOSE = False


def BuildOptions():
    result = optparse.OptionParser()
    result.add_option(
        "-a",
        "--abi",
        action="store",
        type="string",
        help="Desired ABI. armeabi-v7a or x86.")
    result.add_option(
        "-b",
        "--bootstrap",
        help=
        'Bootstrap - create an emulator, installing SDK packages if needed.',
        default=False,
        action="store_true")
    result.add_option(
        "-d",
        "--debug",
        help='Turn on debugging diagnostics.',
        default=False,
        action="store_true")
    result.add_option(
        "-v",
        "--verbose",
        help='Verbose output.',
        default=False,
        action="store_true")
    return result


def ProcessOptions(options):
    global DEBUG
    DEBUG = options.debug
    global VERBOSE
    VERBOSE = options.verbose
    if options.abi is None:
        sys.stderr.write('--abi not specified.\n')
        return False
    return True


def ParseAndroidListSdkResult(text):
    """
  Parse the output of an 'android list sdk' command.

  Return list of (id-num, id-key, type, description).
  """
    header_regex = re.compile(
        r'Packages available for installation or update: \d+\n')
    packages = re.split(header_regex, text)
    if len(packages) != 2:
        raise utils.Error("Could not get a list of packages to install")
    entry_regex = re.compile(
        r'^id\: (\d+) or "([^"]*)"\n\s*Type\: ([^\n]*)\n\s*Desc\: (.*)')
    entries = []
    for entry in packages[1].split('----------\n'):
        match = entry_regex.match(entry)
        if match == None:
            continue
        entries.append((int(match.group(1)), match.group(2), match.group(3),
                        match.group(4)))
    return entries


def AndroidListSdk():
    return ParseAndroidListSdkResult(
        utils.RunCommand(["android", "list", "sdk", "-a", "-e"]))


def AndroidSdkFindPackage(packages, key):
    """
  Args:
    packages: list of (id-num, id-key, type, description).
    key: (id-key, type, description-prefix).
  """
    (key_id, key_type, key_description_prefix) = key
    for package in packages:
        (package_num, package_id, package_type, package_description) = package
        if (package_id == key_id and package_type == key_type and
                package_description.startswith(key_description_prefix)):
            return package
    return None


def EnsureSdkPackageInstalled(packages, key):
    """
  Makes sure the package with a given key is installed.

  key is (id-key, type, description-prefix)

  Returns True if the package was not already installed.
  """
    entry = AndroidSdkFindPackage(packages, key)
    if entry is None:
        raise utils.Error("Could not find a package for key %s" % key)
    packageId = entry[0]
    if VERBOSE:
        sys.stderr.write('Checking Android SDK package %s...\n' % str(entry))
    out = utils.RunCommand(
        ["android", "update", "sdk", "-a", "-u", "--filter",
         str(packageId)])
    return '\nInstalling Archives:\n' in out


def SdkPackagesForAbi(abi):
    packagesForAbi = {
        'armeabi-v7a': [
            # The platform needed to install the armeabi ABI system image:
            ('android-15', 'Platform', 'Android SDK Platform 4.0.3'),
            # The armeabi-v7a ABI system image:
            ('sysimg-15', 'SystemImage', 'Android SDK Platform 4.0.3')
        ],
        'x86': [
            # The platform needed to install the x86 ABI system image:
            ('android-15', 'Platform', 'Android SDK Platform 4.0.3'),
            # The x86 ABI system image:
            ('sysimg-15', 'SystemImage', 'Android SDK Platform 4.0.4')
        ]
    }

    if abi not in packagesForAbi:
        raise utils.Error('Unsupported abi %s' % abi)
    return packagesForAbi[abi]


def TargetForAbi(abi):
    for package in SdkPackagesForAbi(abi):
        if package[1] == 'Platform':
            return package[0]


def EnsureAndroidSdkPackagesInstalled(abi):
    """Return true if at least one package was not already installed."""
    abiPackageList = SdkPackagesForAbi(abi)
    installedSomething = False
    packages = AndroidListSdk()
    for package in abiPackageList:
        installedSomething |= EnsureSdkPackageInstalled(packages, package)
    return installedSomething


def ParseAndroidListAvdResult(text):
    """
  Parse the output of an 'android list avd' command.
  Return List of {Name: Path: Target: ABI: Skin: Sdcard:}
  """
    text = text.split('Available Android Virtual Devices:\n')[-1]
    text = text.split(
        'The following Android Virtual Devices could not be loaded:\n')[0]
    result = []
    line_re = re.compile(r'^\s*([^\:]+)\:\s*(.*)$')
    for chunk in text.split('\n---------\n'):
        entry = {}
        for line in chunk.split('\n'):
            line = line.strip()
            if len(line) == 0:
                continue
            match = line_re.match(line)
            if match is None:
                sys.stderr.write('Match fail %s\n' % str(line))
                continue
                #raise utils.Error('Match failed')
            entry[match.group(1)] = match.group(2)
        if len(entry) > 0:
            result.append(entry)
    return result


def AndroidListAvd():
    """Returns a list of available Android Virtual Devices."""
    return ParseAndroidListAvdResult(
        utils.RunCommand(["android", "list", "avd"]))


def FindAvd(avds, key):
    for avd in avds:
        if avd['Name'] == key:
            return avd
    return None


def CreateAvd(avdName, abi):
    out = utils.RunCommand([
        "android", "create", "avd", "--name", avdName, "--target",
        TargetForAbi(abi), '--abi', abi
    ],
                           input="no\n")
    if out.find('Created AVD ') < 0:
        if VERBOSE:
            sys.stderr.write('Could not create AVD:\n%s\n' % out)
        raise utils.Error('Could not create AVD')


def AvdExists(avdName):
    avdList = AndroidListAvd()
    return FindAvd(avdList, avdName) is not None


def EnsureAvdExists(avdName, abi):
    if AvdExists(avdName):
        return
    if VERBOSE:
        sys.stderr.write('Checking SDK packages...\n')
    if EnsureAndroidSdkPackagesInstalled(abi):
        # Installing a new package could have made a previously invalid AVD valid
        if AvdExists(avdName):
            return
    CreateAvd(avdName, abi)


def StartEmulator(abi, avdName, pollFn):
    """
  Start an emulator for a given abi and svdName.

  Echo the emulator's stderr and stdout output to our stderr.

  Call pollFn repeatedly until it returns False. Leave the emulator running
  when we return.

  Implementation note: Normally we would call the 'emulator' binary, which
  is a wrapper that launches the appropriate abi-specific emulator. But there
  is a bug that causes the emulator to exit immediately with a result code of
  -11 if run from a ssh shell or a No Machine shell. (And only if called from
  three levels of nested python scripts.) Calling the ABI-specific versions
  of the emulator directly works around this bug.
  """
    emulatorName = {'x86': 'emulator-x86', 'armeabi-v7a': 'emulator-arm'}[abi]
    command = [emulatorName, '-avd', avdName, '-no-boot-anim', '-no-window']
    utils.RunCommand(
        command,
        pollFn=pollFn,
        killOnEarlyReturn=False,
        outStream=sys.stderr,
        errStream=sys.stderr)


def ParseAndroidDevices(text):
    """Return Dictionary [name] -> status"""
    text = text.split('List of devices attached')[-1]
    lines = [line.strip() for line in text.split('\n')]
    lines = [line for line in lines if len(line) > 0]
    devices = {}
    for line in lines:
        lineItems = line.split('\t')
        devices[lineItems[0]] = lineItems[1]
    return devices


def GetAndroidDevices():
    return ParseAndroidDevices(utils.RunCommand(["adb", "devices"]))


def FilterOfflineDevices(devices):
    online = {}
    for device in devices.keys():
        status = devices[device]
        if status != 'offline':
            online[device] = status
    return online


def GetOnlineAndroidDevices():
    return FilterOfflineDevices(GetAndroidDevices())


def GetAndroidDeviceProperty(device, property):
    return utils.RunCommand(["adb", "-s", device, "shell", "getprop",
                             property]).strip()


def GetAndroidDeviceAbis(device):
    abis = []
    for property in ['ro.product.cpu.abi', 'ro.product.cpu.abi2']:
        out = GetAndroidDeviceProperty(device, property)
        if len(out) > 0:
            abis.append(out)
    return abis


def FindAndroidRunning(abi):
    for device in GetOnlineAndroidDevices().keys():
        if abi in GetAndroidDeviceAbis(device):
            return device
    return None


def AddSdkToolsToPath():
    script_dir = os.path.dirname(sys.argv[0])
    dart_root = os.path.realpath(os.path.join(script_dir, '..', '..'))
    third_party_root = os.path.join(dart_root, 'third_party')
    android_tools = os.path.join(third_party_root, 'android_tools')
    android_sdk_root = os.path.join(android_tools, 'sdk')
    android_sdk_tools = os.path.join(android_sdk_root, 'tools')
    android_sdk_platform_tools = os.path.join(android_sdk_root,
                                              'platform-tools')
    os.environ['PATH'] = ':'.join(
        [os.environ['PATH'], android_sdk_tools, android_sdk_platform_tools])
    # Remove any environment variables that would affect our build.
    for i in [
            'ANDROID_NDK_ROOT', 'ANDROID_SDK_ROOT', 'ANDROID_TOOLCHAIN', 'AR',
            'BUILDTYPE', 'CC', 'CXX', 'GYP_DEFINES', 'LD_LIBRARY_PATH', 'LINK',
            'MAKEFLAGS', 'MAKELEVEL', 'MAKEOVERRIDES', 'MFLAGS', 'NM'
    ]:
        if i in os.environ:
            del os.environ[i]


def FindAndroid(abi, bootstrap):
    if VERBOSE:
        sys.stderr.write(
            'Looking for an Android device running abi %s...\n' % abi)
    AddSdkToolsToPath()
    device = FindAndroidRunning(abi)
    if not device:
        if bootstrap:
            if VERBOSE:
                sys.stderr.write("No emulator found, try to create one.\n")
            avdName = 'dart-build-%s' % abi
            EnsureAvdExists(avdName, abi)

            # It takes a while to start up an emulator.
            # Provide feedback while we wait.
            pollResult = [None]

            def pollFunction():
                if VERBOSE:
                    sys.stderr.write('.')
                pollResult[0] = FindAndroidRunning(abi)
                # Stop polling once we have our result.
                return pollResult[0] != None

            StartEmulator(abi, avdName, pollFunction)
            device = pollResult[0]
    return device


def Main():
    # Parse options.
    parser = BuildOptions()
    (options, args) = parser.parse_args()
    if not ProcessOptions(options):
        parser.print_help()
        return 1

    # If there are additional arguments, report error and exit.
    if args:
        parser.print_help()
        return 1

    try:
        device = FindAndroid(options.abi, options.bootstrap)
        if device != None:
            sys.stdout.write("%s\n" % device)
            return 0
        else:
            if VERBOSE:
                sys.stderr.write('Could not find device\n')
            return 2
    except utils.Error as e:
        sys.stderr.write("error: %s\n" % e)
        if DEBUG:
            traceback.print_exc(file=sys.stderr)
        return -1


if __name__ == '__main__':
    sys.exit(Main())
