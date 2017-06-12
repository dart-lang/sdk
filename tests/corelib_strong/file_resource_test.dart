// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

const sampleText = "Sample text file.";

main() async {
  var file = await createFile();
  var uri = new Uri.file(file.path);

  var resource = new Resource(uri.toString());

  if (resource.uri != uri) {
    throw "Incorrect URI: ${resource.uri}";
  }

  var text = await resource.readAsString();
  if (text != sampleText) {
    throw "Incorrect reading of text file: $text";
  }

  var bytes = await resource.readAsBytes();
  if (!compareBytes(bytes, sampleText.codeUnits)) {
    throw "Incorrect reading of bytes: $bytes";
  }

  var streamBytes = [];
  await for (var byteSlice in resource.openRead()) {
    streamBytes.addAll(byteSlice);
  }
  if (!compareBytes(streamBytes, sampleText.codeUnits)) {
    throw "Incorrect reading of bytes: $bytes";
  }

  await deleteFile(file);
}

/// Checks that [bytes] and [expectedBytes] have the same contents.
bool compareBytes(bytes, expectedBytes) {
  if (bytes.length != expectedBytes.length) return false;
  for (int i = 0; i < expectedBytes.length; i++) {
    if (bytes[i] != expectedBytes[i]) return false;
  }
  return true;
}

createFile() async {
  var tempDir = await Directory.systemTemp.createTemp("sample");
  var filePath = tempDir.path + Platform.pathSeparator + "sample.txt";
  var file = new File(filePath);
  await file.create();
  await file.writeAsString(sampleText);
  return file;
}

deleteFile(File file) async {
  // Removes the file and the temporary directory it's in.
  var parentDir = new Directory(
      file.path.substring(0, file.path.lastIndexOf(Platform.pathSeparator)));
  await parentDir.delete(recursive: true);
}
