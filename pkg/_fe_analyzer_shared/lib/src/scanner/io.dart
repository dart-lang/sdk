// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.scanner.io;

import 'dart:io' show File;

import 'dart:typed_data' show Uint8List;

Uint8List readBytesFromFileSync(Uri uri) {
  return new File.fromUri(uri).readAsBytesSync();
}

Future<Uint8List> readBytesFromFile(Uri uri) async {
  return await new File.fromUri(uri).readAsBytes();
}
