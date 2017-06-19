// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'launch_helper.dart' show dart2JsCommand;

var tmpDir;

copyDirectory(Directory sourceDir, Directory destinationDir) {
  sourceDir.listSync().forEach((FileSystemEntity element) {
    String newPath =
        path.join(destinationDir.path, path.basename(element.path));
    if (element is File) {
      element.copySync(newPath);
    } else if (element is Directory) {
      Directory newDestinationDir = new Directory(newPath);
      newDestinationDir.createSync();
      copyDirectory(element, newDestinationDir);
    }
  });
}

Future<Directory> createTempDir() {
  return Directory.systemTemp
      .createTemp('dart2js_batch_test-')
      .then((Directory dir) {
    return dir;
  });
}

Future setup() {
  return createTempDir().then((Directory directory) {
    tmpDir = directory;
    Directory sunflowerDir = new Directory.fromUri(
        Platform.script.resolve('../../../third_party/sunflower'));

    print("Copying '${sunflowerDir.path}' to '${tmpDir.path}'.");
    copyDirectory(sunflowerDir, tmpDir);
  });
}

void cleanUp() {
  print("Deleting '${tmpDir.path}'.");
  tmpDir.deleteSync(recursive: true);
}

Future launchDart2Js(_) {
  return Process.start(
      // Use an absolute path because we are changing the cwd below.
      path.fromUri(Uri.base.resolve(Platform.executable)),
      dart2JsCommand(['--batch']),
      workingDirectory: tmpDir.path);
}

Future runTests(Process process) {
  String inFile = path.join(tmpDir.path, 'web/sunflower.dart');
  String outFile = path.join(tmpDir.path, 'out.js');
  String outFile2 = path.join(tmpDir.path, 'out2.js');

  process.stdin.writeln('--out="$outFile" "$inFile"');
  process.stdin.writeln('--out="$outFile2" "$inFile"');
  process.stdin.writeln('too many arguments');
  process.stdin.writeln(r'"non existing file.dart"');
  process.stdin.close();
  Future<String> output = process.stdout.transform(UTF8.decoder).join();
  Future<String> errorOut = process.stderr.transform(UTF8.decoder).join();
  return Future.wait([output, errorOut]).then((result) {
    String stdoutOutput = result[0];
    String stderrOutput = result[1];

    Expect.equals(4, ">>> EOF STDERR".allMatches(stderrOutput).length);
    Expect.equals(4, ">>>".allMatches(stderrOutput).length);

    Expect.equals(2, ">>> TEST OK".allMatches(stdoutOutput).length);
    Expect.equals(2, ">>> TEST FAIL".allMatches(stdoutOutput).length);
    Expect.equals(4, ">>>".allMatches(stdoutOutput).length);
  });
}

void main() {
  asyncTest(() {
    return setup().then(launchDart2Js).then(runTests).whenComplete(cleanUp);
  });
}
