// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, File, GZipCodec;

Uri saveAsGzip(List<int> data, String filename) {
  // TODO(jensj): This should be done via the FileSystem instead, but it
  // currently doesn't support writing.
  GZipCodec gZipCodec = new GZipCodec();
  List<int> gzippedInitializedFromData = gZipCodec.encode(data);
  Directory tempDir = Directory.systemTemp.createTempSync("$filename");
  File file = new File("${tempDir.path}/${filename}.gz");
  file.writeAsBytesSync(gzippedInitializedFromData);
  return file.uri;
}
