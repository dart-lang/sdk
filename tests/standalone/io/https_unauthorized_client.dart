// Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Client that makes HttpClient secure gets from a server that replies with
// a certificate that can't be authenticated.  This checks that all the
// futures returned from these connection attempts complete (with errors).

import "dart:async";
import "dart:io";

class ExpectException implements Exception {
  ExpectException(this.message);
  String toString() => "ExpectException: $message";
  String message;
}

void expect(condition, message) {
  if (!condition) {
    throw new ExpectException(message);
  }
}

const HOST_NAME = "localhost";

Future runClients(int port) {
  HttpClient client = new HttpClient();

  var testFutures = [];
  for (int i = 0; i < 20; ++i) {
    testFutures.add(client.getUrl(Uri.parse('https://$HOST_NAME:$port/')).then(
        (HttpClientRequest request) {
      expect(false, "Request succeeded");
    }, onError: (e) {
      // Remove ArgumentError once null default context is supported.
      expect(
          e is HandshakeException || e is SocketException || e is ArgumentError,
          "Error is wrong type: $e");
    }));
  }
  return Future.wait(testFutures);
}

void main(List<String> args) {
  runClients(int.parse(args[0])).then((_) => print('SUCCESS'));
}
