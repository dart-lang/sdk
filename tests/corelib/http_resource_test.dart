// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

const sampleText = "Sample text file.";

main() async {
  var server = await startServer();
  var uriText = "http://localhost:${server.port}/sample.txt?query#fragment";
  var resource = new Resource(uriText);

  if (resource.uri != Uri.parse(uriText)) {
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

  await server.close();
}

/// Checks that [bytes] and [expectedBytes] have the same contents.
bool compareBytes(bytes, expectedBytes) {
  if (bytes.length != expectedBytes.length) return false;
  for (int i = 0; i < expectedBytes.length; i++) {
    if (bytes[i] != expectedBytes[i]) return false;
  }
  return true;
}

startServer() async {
  var server = await HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 0);
  var expectedUri = new Uri(path: "/sample.txt", query: "query");
  server.forEach((request) async {
    await request.drain();
    var response = request.response;
    if (request.uri == expectedUri) {
      response.write(sampleText);
    } else {
      response.write("INCORRECT PATH!: ${request.uri}");
    }
    response.close();
  });
  return server;
}
