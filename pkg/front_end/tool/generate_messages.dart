// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File;

import 'package:dart_style/dart_style.dart' show DartFormatter;

import '../test/utils/io_utils.dart' show computeRepoDirUri;
import 'generate_messages_lib.dart';

export 'generate_messages_lib.dart';

void main(List<String> arguments) {
  final Uri repoDir = computeRepoDirUri();
  Messages message = generateMessagesFiles(repoDir);
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
}

Messages generateMessagesFiles(Uri repoDir) {
  return generateMessagesFilesRaw(
      repoDir,
      (s) => new DartFormatter(
              languageVersion: DartFormatter.latestShortStyleLanguageVersion)
          .format(s));
}
