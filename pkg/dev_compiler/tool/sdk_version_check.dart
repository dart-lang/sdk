#!/usr/bin/env dart
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Checks that the Dart VM is at least the requested version
import 'dart:io' show Platform, exit;
import 'package:pub_semver/pub_semver.dart' show Version;

void main(List<String> argv) {
  if (argv.length == 0 || argv[0] == '--help') {
    print('usage: sdk_version_check.dart <minimum-version>');
    print('for example: sdk_version_check.dart 1.9.0-dev.4.0');
    exit(2);
  }
  var minVersion = Version.parse(argv[0]);

  var vmStr = Platform.version;
  vmStr = vmStr.substring(0, vmStr.indexOf(' '));
  var vmVersion = Version.parse(vmStr);
  if (vmVersion < minVersion) {
    print('Requires VM $minVersion but actual version $vmVersion');
    exit(1);
  }
}
