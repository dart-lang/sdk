// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

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
    String newPath = path.join(directory.path, "dart2js_batch2_run.dart");
    File source = new File.fromUri(
        Platform.script.resolve("data/dart2js_batch2_run.dart"));
    source.copySync(newPath);
  });
}

void cleanUp() {
  print("Deleting '${tmpDir.path}'.");
  tmpDir.deleteSync(recursive: true);
}

Future<Process> launchDart2Js(_) {
  String ext = Platform.isWindows ? '.bat' : '';
  String command = path.normalize(path.join(
      path.fromUri(Platform.script), '../../../../sdk/bin/dart2js${ext}'));
  print("Running '$command --batch' from '${tmpDir}'.");
  return Process.start(command, ['--batch'], workingDirectory: tmpDir.path);
}

Future runTests(Process process) {
  String inFile = path.join(tmpDir.path, 'dart2js_batch2_run.dart');
  String outFile = path.join(tmpDir.path, 'out.js');

  process.stdin.writeln('--out="$outFile" "$inFile"');
  process.stdin.close();
  Future<String> output = process.stdout.transform(utf8.decoder).join();
  Future<String> errorOut = process.stderr.transform(utf8.decoder).join();
  return Future.wait([output, errorOut]).then((result) {
    String stdoutOutput = result[0];
    Expect.isFalse(stdoutOutput.contains("crashed"));
  });
}

void main() {
  asyncTest(() {
    return setup().then(launchDart2Js).then(runTests).whenComplete(cleanUp);
  });
}
