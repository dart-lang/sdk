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
  for (var messages in generateMessagesFiles(repoDir)) {
    _writeAndFormat(
      new File.fromUri(messages.oldUri(repoDir)),
      messages.oldContents,
    );
  }
}

void _writeAndFormat(File file, String contents) {
  file.writeAsStringSync(contents, flush: true);
  DartFormat.formatFile(file);
}

List<Messages> generateMessagesFiles(Uri repoDir) {
  return generateMessagesFilesRaw(repoDir);
}
