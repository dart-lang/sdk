// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const sampleText = "Sample text file.";

main() async {
  const uriText = "package:package_test_data/resources/sample.txt";
  const resource = const Resource(uriText);

  if (resource.uri != Uri.parse(uriText)) {
    throw "Incorrect URI: ${resource.uri}";
  }

  var text = await resource.readAsString();
  if (!text.startsWith("Sample text file.")) {
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

  if (!compareBytes(streamBytes, bytes)) {
    throw "Inconsistent reading of bytes: $bytes / $streamBytes";
  }
}

/// Checks that [bytes] starts with [expectedBytes].
///
/// The bytes may be longer (because the test file is a text file and its
/// terminating line ending may be mangled on some platforms).
bool compareBytes(bytes, expectedBytes) {
  if (bytes.length < expectedBytes.length) return false;
  for (int i = 0; i < expectedBytes.length; i++) {
    if (bytes[i] != expectedBytes[i]) return false;
  }
  return true;
}
