// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.scanner.main;

import 'io.dart' show readBytesFromFileSync;

import '../scanner.dart' show scan;

scanAll(Map<Uri, List<int>> files) {
  Stopwatch sw = new Stopwatch()..start();
  int byteCount = 0;
  files.forEach((Uri uri, List<int> bytes) {
    scan(bytes);
    byteCount += bytes.length - 1;
  });
  sw.stop();
  print("Scanning files took: ${sw.elapsed}");
  print("Bytes/ms: ${byteCount/sw.elapsedMilliseconds}");
}

mainEntryPoint(List<String> arguments) {
  Map<Uri, List<int>> files = <Uri, List<int>>{};
  Stopwatch sw = new Stopwatch()..start();
  for (String name in arguments) {
    Uri uri = Uri.base.resolve(name);
    List<int> bytes = readBytesFromFileSync(uri);
    files[uri] = bytes;
  }
  sw.stop();
  print("Reading files took: ${sw.elapsed}");
  scanAll(files);
}
