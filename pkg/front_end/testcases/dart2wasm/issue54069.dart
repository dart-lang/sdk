// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

Future<Uint8List> getBinaryTestProto() => readFileWeb("test.binary.pb");

Future<Uint8List> readFileWeb(String path) async {
  throw '';
}

void runBench([Uint8List? data]) async {
  data ??= await getBinaryTestProto();
  print(data);
}

void main() async {
  Uint8List data = await getBinaryTestProto();
  print("File successfully read, contents: $data");
  runBench(data);
}
