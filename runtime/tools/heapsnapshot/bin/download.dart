// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File;
import 'dart:typed_data' show BytesBuilder;

import 'package:heapsnapshot/src/load.dart' show loadFromUri;

Future<void> main(List<String> args) async {
  String filename = "snapshot.heapsnapshot";
  String? uriString;
  for (String arg in args) {
    if (arg.startsWith("-o=")) {
      filename = arg.substring("-o=".length);
    } else {
      uriString = arg;
    }
  }
  if (uriString == null) {
    throw "Give uri as input.";
  }
  print("Will try to fetch snapshot from $uriString and dump to $filename");
  await download(uriString, filename);
  print("Done");
}

Future<void> download(String uriString, String filename) async {
  final chunks = await loadFromUri(Uri.parse(uriString));
  final bytesBuilder = BytesBuilder();
  for (final bd in chunks) {
    bytesBuilder.add(bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes));
    print("Got ${(bytesBuilder.length / 1024 / 1024).toStringAsFixed(1)} MB");
  }
  final bytes = bytesBuilder.toBytes();

  File(filename).writeAsBytesSync(bytes);
}
