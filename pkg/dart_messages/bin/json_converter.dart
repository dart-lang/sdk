// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import '../lib/shared_messages.dart' as shared_messages;

/// Translates the shared messages in `../lib/shared_messages` to JSON and
/// emits it into `../lib/shared_messages.json`.
void main() {
  var input = shared_messages.MESSAGES;
  var outPath =
      Platform.script.resolve('../lib/shared_messages.json').toFilePath();
  print("Input: ${input.length} entries");
  print("Output: $outPath");
  new File(outPath).writeAsStringSync(JSON.encode(shared_messages.MESSAGES));
  print("Done");
}
