// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing native extensions.

#import("dart:io");
#import("dart:isolate");

// The following source statements, hidden in a string, fool the test script
// tools/testing/dart/multitest.dart
// into copying the files into the generated_tests directory.
// TODO(3919): Rewrite this test, not as a multitest, to copy them manually.
const dummyString = '''
#source('test_extension_tester.dart');
#source('test_extension.dart');
''';

void main() {
  Options options = new Options();

  // Make this a multitest so that the test scripts run a copy of it in
  // [build directory]/generated_tests.  This way, we can copy the shared
  // library for test_extension.dart to the test directory.
  // The "none" case of the multitest, without the following
  // line, is the one that runs the test of the extension.
  foo foo foo foo foo; /// 01: compile-time error

  Path testDirectory = new Path.fromNative(options.script).directoryPath;
  Path buildDirectory = new Path.fromNative(options.executable).directoryPath;

  // Copy test_extension shared library from the build directory to the
  // test directory.
  Future sharedLibraryCopied;
  // Use the platforms' copy file commands, to preserve executable privilege.
  switch (Platform.operatingSystem) {
    case 'linux':
      var source = buildDirectory.append('lib.target/libtest_extension.so');
      sharedLibraryCopied = Process.run('cp',
                               [source.toNativePath(),
                                testDirectory.toNativePath()]);
      break;
    case 'macos':
      var source = buildDirectory.append('libtest_extension.dylib');
      sharedLibraryCopied = Process.run('cp',
                               [source.toNativePath(),
                                testDirectory.toNativePath()]);
      break;
    case 'windows':
      var source = buildDirectory.append('test_extension.dll');
      sharedLibraryCopied = Process.run('cmd.exe',
          ['/C',
           'copy ${source.toNativePath()} ${testDirectory.toNativePath()}']);
      break;
    default:
      Expect.fail("Unknown operating system ${Platform.operatingSystem}");
  }

  sharedLibraryCopied.handleException((e) {
    print('Copying of shared library test_extension failed.');
    throw e;
  });
  sharedLibraryCopied.then((ignore) {
    print('Shared library copied to test directory.');
    Path copiedTest = testDirectory.append("test_extension_tester.dart");
    var result = Process.run(options.executable,
                             [copiedTest.toNativePath()]);
    result.then((processResult) {
      print('Output of test_extension_tester.dart:');
      print('  stdout:');
      print(processResult.stdout);
      print('  stderr:');
      print(processResult.stderr);
      stdout.flush();
      exit(processResult.exitCode);
    });
  });
}
