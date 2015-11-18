// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const sampleText = "Sample text file.";

main() async {
  var uriEncoded = sampleText.replaceAll(' ', '%20');
  await testUri("data:application/dart;charset=utf-8,$uriEncoded");
  // TODO: Support other data: URI formats too.
  // See: https://github.com/dart-lang/sdk/issues/24030
  // await testUri("data:text/plain;charset=utf-8,$uriEncoded");
  var base64Encoded = "U2FtcGxlIHRleHQgZmlsZS4=";
  // await testUri("data:application/dart;charset=utf-8;base64,$base64Encoded");
  // await testUri("data:text/plain;charset=utf-8;base64,$base64Encoded");
}

testUri(uriText) async {
  var resource = new Resource(uriText);

  if (resource.uri != Uri.parse(uriText)) {
    throw "uriText: Incorrect URI: ${resource.uri}";
  }

  var text = await resource.readAsString();
  if (text != sampleText) {
    throw "uriText: Incorrect reading of text file: $text";
  }

  var bytes = await resource.readAsBytes();
  if (!compareBytes(bytes, sampleText.codeUnits)) {
    throw "uriText: Incorrect reading of bytes: $bytes";
  }

  var streamBytes = [];
  await for (var byteSlice in resource.openRead()) {
    streamBytes.addAll(byteSlice);
  }
  if (!compareBytes(streamBytes, sampleText.codeUnits)) {
    throw "uriText: Incorrect reading of bytes: $bytes";
  }
}

/// Checks that [bytes] and [expectedBytes] have the same contents.
bool compareBytes(bytes, expectedBytes) {
  if (bytes.length != expectedBytes.length) return false;
  for (int i = 0; i < expectedBytes.length; i++) {
    if (bytes[i] != expectedBytes[i]) return false;
  }
  return true;
}
