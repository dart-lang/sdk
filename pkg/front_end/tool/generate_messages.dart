// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File;

import 'package:analyzer_utilities/tools.dart';

import '../test/utils/io_utils.dart' show computeRepoDirUri;
import 'generate_messages_lib.dart';

export 'generate_messages_lib.dart';

void main(List<String> arguments) {
  final Uri repoDir = computeRepoDirUri();
  Messages message = generateMessagesFiles(repoDir);
  if (message.sharedMessages.trim().isEmpty ||
      message.cfeMessages.trim().isEmpty) {
    print(
      "Bailing because of errors: "
      "Refusing to overwrite with empty file!",
    );
  } else {
    _writeAndFormat(
      new File.fromUri(computeSharedGeneratedFile(repoDir)),
      message.sharedMessages,
    );
    _writeAndFormat(
      new File.fromUri(computeCfeGeneratedFile(repoDir)),
      message.cfeMessages,
    );
  }
}

void _writeAndFormat(File file, String contents) {
  file.writeAsStringSync(contents, flush: true);
  DartFormat.formatFile(file);
}

Messages generateMessagesFiles(Uri repoDir) {
  return generateMessagesFilesRaw(repoDir);
}
