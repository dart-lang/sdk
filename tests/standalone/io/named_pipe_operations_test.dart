// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Testing file input stream, VM-only, standalone test.

import "dart:convert";
import "dart:io";

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";
import "package:path/path.dart";

final String stdinPipePath = '/dev/fd/0';

startProcess(Directory dir, String fname, String script, String result) async {
  File file = new File(join(dir.path, fname));
  file.writeAsStringSync(script);
  StringBuffer output = new StringBuffer();
  Process process = await Process.start(
    Platform.executable,
    []
      ..addAll(Platform.executableArguments)
      ..add('--sound-null-safety')
      ..add('--verbosity=warning')
      ..add(file.path),
  );
  process.stdout.transform(utf8.decoder).listen(output.write);
  process.stderr.transform(utf8.decoder).listen((data) {
    // No stderr data expected (the subprocess will catch exceptions and print
    // them to stdout).
    Expect.fail(data);
  });
  await process.stdin.close();

  int status = await process.exitCode;
  Expect.equals(0, status);
  Expect.contains(result, output.toString());
}

main() async {
  asyncStart();
  // Operations on a named pipe is only supported on Linux and MacOS.
  if (!Platform.isLinux && !Platform.isMacOS) {
    print("This test is only supported on Linux and MacOS.");
    asyncEnd();
    return;
  }

  Directory directory = Directory.systemTemp.createTempSync('named_pipe');

  final String delScript =
      '''
    import "dart:io";
    main() {
      try {
        final file = File("$stdinPipePath");
        if (file.existsSync()) print("Pipe Exists");
        file.deleteSync();
        if (!file.existsSync()) print("Pipe Deleted");
      } catch (e) {
        print(e);
      }
    }
  ''';

  final String renameScript =
      '''
    import "dart:io";
    main() {
      try {
        final file = File("$stdinPipePath");
        if (file.existsSync()) print("Pipe Exists");
        file.renameSync("junk");
        if (!file.existsSync()) print("Pipe Renamed");
      } catch (e) {
        print(e);
      }
    }
  ''';

  final String copyScript =
      '''
    import "dart:io";
    main() {
      try {
        final file = File("$stdinPipePath");
        if (file.existsSync()) print("Pipe Exists");
        file.copySync("junk");
      } catch (e) {
        print(e);
      }
    }
  ''';

  // If there's no file system access to the pipe, then we can't do a meaningful
  // test.
  if (!await (new File(stdinPipePath).exists())) {
    print("Couldn't find $stdinPipePath.");
    directory.deleteSync(recursive: true);
    asyncEnd();
    return;
  }

  await startProcess(directory, 'delscript', delScript, "Cannot delete file");
  await startProcess(
    directory,
    'renamescript',
    renameScript,
    "Cannot rename file",
  );
  await startProcess(directory, 'copyscript', copyScript, "Cannot copy file");

  directory.deleteSync(recursive: true);
  asyncEnd();
}
