// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test a dart sub-process handling stdio with different types of
// redirection.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "package:expect/expect.dart";
import "dart:io";
import "process_test_util.dart";

void checkFileEmpty(String fileName) {
  RandomAccessFile pipeOut = new File(fileName).openSync();
  Expect.equals(0, pipeOut.lengthSync());
  pipeOut.closeSync();
}

void checkFileContent(String fileName, String content) {
  RandomAccessFile pipeOut = new File(fileName).openSync();
  int length = pipeOut.lengthSync();
  List data = new List<int>(length);
  pipeOut.readIntoSync(data, 0, length);
  Expect.equals(content, new String.fromCharCodes(data));
  pipeOut.closeSync();
}

void test(String shellScript, String dartScript, String type, bool devNull) {
  Directory dir = Directory.systemTemp.createTempSync('dart_dart_std_io_pipe');

  // The shell script will run the dart executable passed with a
  // number of different redirections of stdio.
  String pipeOutFile = "${dir.path}/pipe";
  if (devNull) pipeOutFile = "/dev/null";
  String redirectOutFile = "${dir.path}/redirect";
  String executable = Platform.executable;
  List args = [
    executable,
    dartScript,
    type,
    pipeOutFile,
    redirectOutFile,
    devNull ? "terminal" : "file"
  ];
  var future = Process.start(shellScript, args);
  future.then((process) {
    process.exitCode.then((exitCode) {
      Expect.equals(0, exitCode);

      // Check the expected file contents.
      if (type == "0") {
        if (devNull) {
          checkFileEmpty("${redirectOutFile}.stdout");
        } else {
          checkFileContent("${pipeOutFile}", "Hello\n");
          checkFileContent("${redirectOutFile}.stdout", "Hello\nHello\n");
        }
        checkFileEmpty("${redirectOutFile}.stderr");
      }
      if (type == "1") {
        if (devNull) {
          checkFileEmpty("${redirectOutFile}.stderr");
        } else {
          checkFileContent("${pipeOutFile}", "Hello\n");
          checkFileContent("${redirectOutFile}.stderr", "Hello\nHello\n");
        }
        checkFileEmpty("${redirectOutFile}.stdout");
      }
      if (type == "2") {
        if (devNull) {
          checkFileEmpty("${redirectOutFile}.stdout");
          checkFileEmpty("${redirectOutFile}.stderr");
        } else {
          checkFileContent("${pipeOutFile}", "Hello\nHello\n");
          checkFileContent(
              "${redirectOutFile}.stdout", "Hello\nHello\nHello\nHello\n");
          checkFileContent(
              "${redirectOutFile}.stderr", "Hello\nHello\nHello\nHello\n");
        }
      }

      // Cleanup test directory.
      dir.deleteSync(recursive: true);
    });
    // Drain out and err streams so they close.
    process.stdout.listen((_) {});
    process.stderr.listen((_) {});
  });
  future.catchError((error) {
    dir.deleteSync(recursive: true);
    Expect.fail(error.toString());
  });
}

// This tests that the Dart standalone VM can handle piping to stdin
// and can pipe to stdout.
main() {
  // Don't try to run shell scripts on Windows.
  var os = Platform.operatingSystem;
  if (os == 'windows') return;

  // Get the shell script for testing the Standalone Dart VM with
  // piping and redirections of stdio.
  var shellScript = new File("tests/standalone/io/dart_std_io_pipe_test.sh");
  if (!shellScript.existsSync()) {
    shellScript = new File("../tests/standalone/io/dart_std_io_pipe_test.sh");
  }
  // Get the Dart script file which echoes stdin to stdout or stderr or both.
  var scriptFile = new File("tests/standalone/io/dart_std_io_pipe_script.dart");
  if (!scriptFile.existsSync()) {
    scriptFile =
        new File("../tests/standalone/io/dart_std_io_pipe_script.dart");
  }

  // Run the shell script.
  test(shellScript.path, scriptFile.path, "0", false);
  test(shellScript.path, scriptFile.path, "0", true);
  test(shellScript.path, scriptFile.path, "1", false);
  test(shellScript.path, scriptFile.path, "1", true);
  test(shellScript.path, scriptFile.path, "2", false);
  test(shellScript.path, scriptFile.path, "2", true);
}
