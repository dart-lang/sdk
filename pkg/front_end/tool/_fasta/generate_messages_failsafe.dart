// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../../test/utils/io_utils.dart' show computeRepoDirUri;
import 'generate_messages_lib.dart';

void main(List<String> arguments) {
  print("Running the fail-safe version.");
  final Uri repoDir = computeRepoDirUri();
  Messages message = generateMessagesFilesRaw(repoDir, (s) => s);
  if (message.sharedMessages.trim().isEmpty ||
      message.cfeMessages.trim().isEmpty) {
    print("Bailing because of errors: "
        "Refusing to overwrite with empty file!");
  } else {
    new File.fromUri(computeSharedGeneratedFile(repoDir))
        .writeAsStringSync(message.sharedMessages, flush: true);
    new File.fromUri(computeCfeGeneratedFile(repoDir))
        .writeAsStringSync(message.cfeMessages, flush: true);
  }

  if (exitCode != 0) {
    print("Something went wrong.");
    return;
  }

  print("Now executing the non-failsafe version.");

  ProcessResult run = Process.runSync(Platform.resolvedExecutable,
      [Platform.script.resolve("generate_messages.dart").toFilePath()]);
  stderr.writeln(run.stderr);
  stdout.writeln(run.stdout);
  if (run.exitCode != 0) exitCode = 1;
  print("Done with exit code $exitCode");
}
