// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart';

import 'utilities.dart';

/// A utility to list the names of the files implementing existing correction
/// producers. This list is used to populate the Github issues titled
/// "[featureName] Analysis Server - Existing correction producers" that are
/// created to track the implementation of new language features.
void main(List<String> args) {
  listCorrectionProducers(sink: stdout, serverPath: serverPath);
}

// List the files implementing the correction producers.
void listCorrectionProducers({
  required StringSink sink,
  required String serverPath,
}) {
  var producersDirPath = context.join(
    serverPath,
    'lib',
    'src',
    'services',
    'correction',
    'dart',
  );

  var fileNames = filesInDirectory(producersDirPath, [
    'abstract_producer.dart',
  ]);
  for (var fileName in fileNames) {
    sink.writeln('- [ ] $fileName');
  }
}
