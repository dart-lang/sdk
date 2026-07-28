// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart';

import 'utilities.dart';

/// A utility to list the names of existing lint rules. This list is used to
/// populate the Github issues titled
/// "[featureName] Analysis Server - Existing lint rules" that are created to
/// track the implementation of new language features.
void main(List<String> args) {
  listLintRules(sink: stdout, serverPath: serverPath);
}

// List the files implementing the lint rules.
void listLintRules({required StringSink sink, required String serverPath}) {
  var rulesDirPath = context.join(
    context.dirname(serverPath),
    'linter',
    'lib',
    'src',
    'rules',
  );

  var fileNames = filesInDirectory(rulesDirPath, []);
  for (var fileName in fileNames) {
    sink.writeln('- [ ] $fileName');
  }
}
