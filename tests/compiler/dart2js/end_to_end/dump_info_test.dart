// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that dump-info has no effect on the compiler output.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:expect/expect.dart';

import 'launch_helper.dart' show dart2JsCommand;

copyDirectory(Directory sourceDir, Directory destinationDir) {
  for (var element in sourceDir.listSync()) {
    if (element.path.endsWith('.git')) continue;
    String newPath =
        path.join(destinationDir.path, path.basename(element.path));
    if (element is File) {
      element.copySync(newPath);
    } else if (element is Directory) {
      Directory newDestinationDir = new Directory(newPath);
      newDestinationDir.createSync();
      copyDirectory(element, newDestinationDir);
    }
  }
}

void main() {
  Directory tmpDir = Directory.systemTemp.createTempSync('dump_info_test_');
  Directory out1 = new Directory.fromUri(tmpDir.uri.resolve('without'));
  out1.createSync();
  Directory out2 = new Directory.fromUri(tmpDir.uri.resolve('json'));
  out2.createSync();
  Directory out3 = new Directory.fromUri(tmpDir.uri.resolve('binary'));
  out3.createSync();
  Directory appDir =
      new Directory.fromUri(Uri.base.resolve('samples-dev/swarm'));

  print("Copying '${appDir.path}' to '${tmpDir.path}'.");
  copyDirectory(appDir, tmpDir);
  try {
    var command = dart2JsCommand(['--out=without/out.js', 'swarm.dart']);
    print('Run $command');
    var result = Process.runSync(Platform.resolvedExecutable, command,
        workingDirectory: tmpDir.path);
    print('exit code: ${result.exitCode}');
    print('stdout:');
    print(result.stdout);
    print('stderr:');
    print(result.stderr);
    Expect.equals(0, result.exitCode);
    String output1 = new File.fromUri(tmpDir.uri.resolve('without/out.js'))
        .readAsStringSync();

    command =
        dart2JsCommand(['--out=json/out.js', 'swarm.dart', '--dump-info']);
    print('Run $command');
    result = Process.runSync(Platform.resolvedExecutable, command,
        workingDirectory: tmpDir.path);
    print('exit code: ${result.exitCode}');
    print('stdout:');
    print(result.stdout);
    print('stderr:');
    print(result.stderr);
    Expect.equals(0, result.exitCode);
    String output2 =
        new File.fromUri(tmpDir.uri.resolve('json/out.js')).readAsStringSync();

    print('Compare outputs...');
    Expect.equals(output1, output2);

    command = dart2JsCommand(
        ['--out=binary/out.js', 'swarm.dart', '--dump-info=binary']);
    print('Run $command');
    result = Process.runSync(Platform.resolvedExecutable, command,
        workingDirectory: tmpDir.path);
    print('exit code: ${result.exitCode}');
    print('stdout:');
    print(result.stdout);
    print('stderr:');
    print(result.stderr);
    Expect.equals(0, result.exitCode);
    String output3 = new File.fromUri(tmpDir.uri.resolve('binary/out.js'))
        .readAsStringSync();

    print('Compare outputs...');
    Expect.equals(output1, output3);

    print('Done');
  } finally {
    print("Deleting '${tmpDir.path}'.");
    tmpDir.deleteSync(recursive: true);
  }
}
