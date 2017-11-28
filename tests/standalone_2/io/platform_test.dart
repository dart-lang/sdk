// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  // Restore dir.
  Directory.current = oldDir;
  var pkgRootString = Platform.packageRoot;
  if (pkgRootString != null) {
    Directory packageRoot = new Directory.fromUri(Uri.parse(pkgRootString));
    Expect.isTrue(packageRoot.existsSync());
    Expect.isTrue(new Directory("${packageRoot.path}/expect").existsSync());
    Expect.isTrue(Platform.executableArguments.any((arg) {
      if (!arg.startsWith("--package-root=")) {
        return false;
      }
      // Cut out the '--package-root=' prefix.
      arg = arg.substring(15);
      return pkgRootString.contains(arg);
    }));
  }
}

void f(reply) {
  reply.send({
    "Platform.executable": Platform.executable,
    "Platform.script": Platform.script,
    "Platform.packageRoot": Platform.packageRoot,
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
    Expect
        .isTrue(uri.path.endsWith('tests/standalone_2/io/platform_test.dart'));
    Expect.equals(Platform.packageRoot, results["Platform.packageRoot"]);
    Expect.listEquals(
        Platform.executableArguments, results["Platform.executableArguments"]);
    asyncEnd();
  });
}

testVersion() {
  checkValidVersion(String version) {
    RegExp re = new RegExp(r'(\d+)\.(\d+)\.(\d+)(-dev\.([^\.]*)\.([^\.]*))?');
    var match = re.firstMatch(version);
    Expect.isNotNull(match);
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

  String stripAdditionalInfo(String version) {
    var index = version.indexOf(' ');
    if (index == -1) return version;
    return version.substring(0, index);
  }

  // Ensure we can match valid versions.
  checkValidVersion('1.9.0');
  checkValidVersion('2.0.0');
  checkValidVersion('1.9.0-dev.0.0');
  checkValidVersion('1.9.0-edge');
  checkValidVersion('1.9.0-edge.r41234');
  // Check stripping of additional information.
  checkValidVersion(stripAdditionalInfo(
      '1.9.0-dev.1.2 (Wed Feb 25 02:22:19 2015) on "linux_ia32"'));
  // Test current version.
  checkValidVersion(stripAdditionalInfo(Platform.version));
  // Test some invalid versions.
  Expect.throws(() => checkValidVersion('1.9'));
  Expect.throws(() => checkValidVersion('..'));
  Expect.throws(() => checkValidVersion('1..'));
  Expect.throws(() => checkValidVersion('1.9.'));
  Expect.throws(() => checkValidVersion('1.9.0-dev..'));
  Expect.throws(() => checkValidVersion('1.9.0-dev..0'));
  Expect.throws(() => checkValidVersion('1.9.0-dev.0.'));
  Expect.throws(() => checkValidVersion('1.9.0-dev.x.y'));
  Expect.throws(() => checkValidVersion('x'));
  Expect.throws(() => checkValidVersion('x.y.z'));
}

main() {
  // This tests assumes paths relative to dart main directory
  Directory.current = Platform.script.resolve('../../..').toFilePath();
  test();
  testIsolate();
  testVersion();
}
