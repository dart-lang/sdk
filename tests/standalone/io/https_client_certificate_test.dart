// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "dart:uri";
import "dart:isolate";

const SERVER_ADDRESS = "127.0.0.1";
const HOST_NAME = "localhost";

int numClientCertificatesReceived = 0;

Function test(Map options) {
  Future runTest([var unused]) {
    var completer = new Completer();
    HttpsServer server = new HttpsServer();
    Expect.throws(() => server.port);

    server.defaultRequestHandler =
        (HttpRequest request, HttpResponse response) {
      if (request.path == '/true') {
        // Client certificate sent
        numClientCertificatesReceived++;
        Expect.isNotNull(request.certificate);
        Expect.equals('CN=localhost', request.certificate.subject);
      } else {
        Expect.equals('/false', request.path);
        Expect.isNull(request.certificate);
      }

      request.inputStream.onClosed = () {
        response.outputStream.close();
      };
    };

    server.listen(SERVER_ADDRESS,
                  0,
                  backlog: 5,
                  certificate_name: 'CN=$HOST_NAME',
                  requestClientCertificate: true);

    HttpClient client = new HttpClient();
    Future testConnect(bool sendCertificate) {
      client.sendClientCertificate = sendCertificate;
      client.clientCertificate = options['certificateName'];
      var completer = new Completer();
      HttpClientConnection conn =
          client.getUrl(Uri.parse(
              "https://$HOST_NAME:${server.port}/$sendCertificate"));
      conn.onRequest = (HttpClientRequest request) {
        request.outputStream.close();
      };
      conn.onResponse = (HttpClientResponse response) {
        Expect.isNotNull(response.certificate);
        Expect.equals('CN=myauthority', response.certificate.issuer);
        response.inputStream.onClosed = () {
          completer.complete(false);  // Chained call will not send cert.
        };
      };
      conn.onError = (Exception e) {
        Expect.fail("Unexpected error in Https Client: $e");
      };
      return completer.future;
    }

    testConnect(true).then(testConnect).then((_) {
        client.shutdown();
        server.close();
        Expect.throws(() => server.port);
        // Run second test with a certificate name.
        completer.complete(null);
      });
    return completer.future;
  }
  return runTest;
}

void InitializeSSL() {
  var testPkcertDatabase =
      new Path(new Options().script).directoryPath.append('pkcert/');
  SecureSocket.initialize(database: testPkcertDatabase.toNativePath(),
                          password: 'dartdart');
}

void main() {
  var keepAlive = new ReceivePort();
  InitializeSSL();
  // Test two connections in sequence.
  test({'certificateName': null})()
      .then((_) => test({'certificateName': 'localhost_cert'})())
      .then((_) {
    Expect.equals(2, numClientCertificatesReceived);
    keepAlive.close();
  });
}
