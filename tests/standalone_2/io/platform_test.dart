// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

import "dart:async";
import "dart:io";
import "dart:isolate";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

test() {
  Expect.isTrue(Platform.numberOfProcessors > 0);
  var os = Platform.operatingSystem;
  Expect.isTrue(
      os == "android" || os == "linux" || os == "macos" || os == "windows");
  Expect.equals(Platform.isLinux, Platform.operatingSystem == "linux");
  Expect.equals(Platform.isMacOS, Platform.operatingSystem == "macos");
  Expect.equals(Platform.isWindows, Platform.operatingSystem == "windows");
  Expect.equals(Platform.isAndroid, Platform.operatingSystem == "android");
  var sep = Platform.pathSeparator;
  Expect.isTrue(sep == '/' || (os == 'windows' && sep == '\\'));
  var hostname = Platform.localHostname;
  Expect.isTrue(hostname is String && hostname != "");
  var environment = Platform.environment;
  Expect.isTrue(environment is Map<String, String>);
  if (!Platform.isWindows) {
    Expect.isTrue(Platform.executable.endsWith('dart'));
    Expect.isTrue(Platform.resolvedExecutable.endsWith('dart'));
  } else {
    Expect.isTrue(Platform.executable.endsWith('dart.exe'));
    Expect.isTrue(Platform.resolvedExecutable.endsWith('dart.exe'));
  }
  if (!Platform.isWindows) {
    Expect.isTrue(Platform.resolvedExecutable.startsWith('/'));
  } else {
    // This assumes that tests (both locally and on the bots) are
    // running off a location referred to by a drive letter. If a UNC
    // location is used or long names ("\\?\" prefix) is used this
    // needs to be fixed.
    Expect.equals(Platform.resolvedExecutable.substring(1, 3), ':\\');
  }
  // Move directory to be sure script is correct.
  var oldDir = Directory.current;
  Directory.current = Directory.current.parent;
  Expect.isTrue(Platform.script.path
      .endsWith('tests/standalone_2/io/platform_test.dart'));
  Expect.isTrue(Platform.script.toFilePath().startsWith(oldDir.path));
}

void f(reply) {
  reply.send({
    "Platform.executable": Platform.executable,
    "Platform.script": Platform.script,
    "Platform.executableArguments": Platform.executableArguments
  });
}

testIsolate() {
  asyncStart();
  ReceivePort port = new ReceivePort();
  var remote = Isolate.spawn(f, port.sendPort);
  port.first.then((results) {
    Expect.equals(Platform.executable, results["Platform.executable"]);

    Uri uri = results["Platform.script"];
    // SpawnFunction retains the script url of the parent which in this
    // case was a relative path.
    Expect.equals("file", uri.scheme);
    Expect.isTrue(
        uri.path.endsWith('tests/standalone_2/io/platform_test.dart'));
    Expect.listEquals(
        Platform.executableArguments, results["Platform.executableArguments"]);
    asyncEnd();
  });
}

testVersion() {
  checkValidVersion(String version) {
    RegExp re = new RegExp(r'(\d+)\.(\d+)\.(\d+)(-dev\.([^\.]*)\.([^\.]*))?');
    var match = re.firstMatch(version);
    Expect.isNotNull(match, version);
    var major = int.parse(match.group(1));
    // Major version.
    Expect.isTrue(major == 1 || major == 2);
    // Minor version.
    Expect.isTrue(int.parse(match.group(2)) >= 0);
    // Patch version.
    Expect.isTrue(int.parse(match.group(3)) >= 0);
    // Dev
    if (match.group(4) != null) {
      // Dev prerelease minor version
      Expect.isTrue(int.parse(match.group(5)) >= 0);
      // Dev prerelease patch version
      Expect.isTrue(int.parse(match.group(6)) >= 0);
    }
  }

  checkInvalidVersion(String version) {
    try {
      checkValidVersion(version);
    } on FormatException {
      return;
    } on ExpectException {
      return;
    }
    Expect.testError("checkValidVersion accepts invalid version: $version");
  }

  String stripAdditionalInfo(String version) {
    var index = version.indexOf(' ');
    if (index == -1) return version;
    return version.substring(0, index);
  }

  // Sanity-checks for `checkValidVersion`.
  // Ensure we can match valid versions.
  checkValidVersion('1.9.0');
  checkValidVersion('2.0.0');
  checkValidVersion('1.9.0-dev.0.0');
  checkValidVersion('1.9.0-edge');
  checkValidVersion('1.9.0-edge.r41234');
  // Check stripping of additional information.
  checkValidVersion(stripAdditionalInfo(
      '1.9.0-dev.1.2 (Wed Feb 25 02:22:19 2015) on "linux_ia32"'));
  // Reject some invalid versions.
  checkInvalidVersion('1.9');
  checkInvalidVersion('..');
  checkInvalidVersion('1..');
  checkInvalidVersion('1.9.');
  checkInvalidVersion('1.9.0-dev..');
  checkInvalidVersion('1.9.0-dev..0');
  checkInvalidVersion('1.9.0-dev.0.');
  checkInvalidVersion('1.9.0-dev.x.y');
  checkInvalidVersion('x');
  checkInvalidVersion('x.y.z');

  // Test current version.
  checkValidVersion(stripAdditionalInfo(Platform.version));
}

main() {
  // This tests assumes paths relative to dart main directory
  Directory.current = Platform.script.resolve('../../..').toFilePath();
  test();
  testIsolate();
  testVersion();
}
