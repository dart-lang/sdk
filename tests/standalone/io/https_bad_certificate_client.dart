// Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Client for https_bad_certificate_test, that runs in a subprocess.
// It verifies that the client bad certificate callback works in HttpClient.

import "dart:async";
import "dart:io";

class ExpectException implements Exception {
  ExpectException(this.message);
  String toString() => "ExpectException: $message";
  String message;
}

void expect(condition) {
  if (!condition) {
    throw new ExpectException('');
  }
}

const HOST_NAME = "localhost";

Future runHttpClient(int port, result) {
  bool badCertificateCallback(X509Certificate certificate,
                              String host,
                              int callbackPort) {
    expect(HOST_NAME == host);
    expect(callbackPort == port);
    expect('CN=localhost' == certificate.subject);
    expect('CN=myauthority' == certificate.issuer);
    expect(result != 'exception');  // Throw exception if one is requested.
    if (result == 'true') return true;
    if (result == 'false') return false;
    return result;
  }

  HttpClient client = new HttpClient();

  var testFutures = [];  // The three async getUrl calls run simultaneously.
  testFutures.add(client.getUrl(Uri.parse('https://$HOST_NAME:$port/$result'))
    .then((HttpClientRequest request) {
      expect(result == 'true');  // The session cache may keep the session.
      return request.close();
    }, onError: (e) {
      expect(e is HandshakeException || e is SocketException);
    }));

  client.badCertificateCallback = badCertificateCallback;
  testFutures.add(client.getUrl(Uri.parse('https://$HOST_NAME:$port/$result'))
    .then((HttpClientRequest request) {
      expect(result == 'true');
      return request.close();
    }, onError: (e) {
      if (result == 'false') expect (e is HandshakeException ||
                                     e is SocketException);
      else if (result == 'exception') expect (e is ExpectException ||
                                              e is SocketException);
      else expect (e is ArgumentError || e is SocketException);
    }));

  client.badCertificateCallback = null;
  testFutures.add(client.getUrl(Uri.parse('https://$HOST_NAME:$port/$result'))
    .then((HttpClientRequest request) {
      expect(result == 'true');  // The session cache may keep the session.
      return request.close();
    }, onError: (e) {
      expect(e is HandshakeException || e is SocketException);
    }));

  return Future.wait(testFutures).then((_) => client.close());
}

void main(List<String> args) {
  SecureSocket.initialize();
  int port = int.parse(args[0]);
  runHttpClient(port, args[1])
    .then((_) => print('SUCCESS'));
}
