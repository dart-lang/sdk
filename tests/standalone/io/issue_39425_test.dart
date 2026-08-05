// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=certificates/server_chain.pem
// OtherResources=certificates/server_key.pem
// OtherResources=certificates/untrusted_server_chain.pem
// OtherResources=certificates/untrusted_server_key.pem

// Regression test for https://github.com/dart-lang/sdk/issues/39425.
// Verifies that badCertificateCallback receives the server's leaf certificate
// rather than an intermediate or root CA certificate when chain verification fails.

import "dart:io";

import "package:expect/expect.dart";

const hostName = 'localhost';

String localFile(path) => Platform.script.resolve(path).toFilePath();

SecurityContext serverContext = SecurityContext()
  ..useCertificateChain(localFile('certificates/server_chain.pem'))
  ..usePrivateKey(
    localFile('certificates/server_key.pem'),
    password: 'dartdart',
  );

SecurityContext untrustedServerContext = SecurityContext()
  ..useCertificateChain(localFile('certificates/untrusted_server_chain.pem'))
  ..usePrivateKey(
    localFile('certificates/untrusted_server_key.pem'),
    password: 'dartdart',
  );

main() async {
  var host = (await InternetAddress.lookup(hostName)).first;
  var server = await HttpServer.bindSecure(host, 0, serverContext, backlog: 5);
  server.listen((request) {
    request.listen(
      (_) {},
      onDone: () {
        request.response.statusCode = 200;
        request.response.close();
      },
    );
  });

  var untrustedServer = await HttpServer.bindSecure(
    host,
    0,
    untrustedServerContext,
    backlog: 5,
  );
  untrustedServer.listen((request) {
    request.listen(
      (_) {},
      onDone: () {
        request.response.statusCode = 200;
        request.response.close();
      },
    );
  });

  // Empty security context that trusts no root certificates.
  SecurityContext untrustedContext = SecurityContext();
  HttpClient client = HttpClient(context: untrustedContext);

  // Test 1: Positive approval, Public Key Pinning inspection & strict invocation count.
  int callCount1 = 0;
  client.badCertificateCallback =
      (X509Certificate certificate, String host, int port) {
        callCount1++;
        Expect.isTrue(certificate.subject.contains('localhost'));
        Expect.isTrue(certificate.issuer.contains('intermediateauthority'));
        Expect.isTrue(certificate.pem.contains('BEGIN CERTIFICATE'));
        Expect.isTrue(certificate.der.isNotEmpty);
        Expect.equals(20, certificate.sha1.length);
        return true;
      };

  var request1 = await client.getUrl(
    Uri.parse('https://$hostName:${server.port}/'),
  );
  var response1 = await request1.close();
  await response1.drain();
  Expect.equals(200, response1.statusCode);
  Expect.equals(1, callCount1);
  client.close(force: true);

  // Test 2: Negative rejection (returning false aborts handshake).
  client = HttpClient(context: untrustedContext);
  bool test2Called = false;
  client.badCertificateCallback =
      (X509Certificate certificate, String host, int port) {
        test2Called = true;
        return false;
      };

  bool handshakeRejected = false;
  try {
    var request2 = await client.getUrl(
      Uri.parse('https://$hostName:${server.port}/'),
    );
    var response2 = await request2.close();
    await response2.drain();
  } catch (e) {
    handshakeRejected = true;
  }
  Expect.isTrue(test2Called);
  Expect.isTrue(handshakeRejected);
  client.close(force: true);

  // Test 3: Edge case (throwing exception inside callback safely aborts connection).
  client = HttpClient(context: untrustedContext);
  bool test3Called = false;
  client.badCertificateCallback =
      (X509Certificate certificate, String host, int port) {
        test3Called = true;
        throw StateError('Simulated pinning verification failure');
      };

  bool callbackThrew = false;
  try {
    var request3 = await client.getUrl(
      Uri.parse('https://$hostName:${server.port}/'),
    );
    var response3 = await request3.close();
    await response3.drain();
  } catch (e) {
    callbackThrew = true;
  }
  Expect.isTrue(test3Called);
  Expect.isTrue(callbackThrew);
  client.close(force: true);

  // Test 4: Alternative failure chain verification.
  client = HttpClient(context: untrustedContext);
  int callCount4 = 0;
  client.badCertificateCallback =
      (X509Certificate certificate, String host, int port) {
        callCount4++;
        Expect.isTrue(certificate.der.isNotEmpty);
        return true;
      };

  var request4 = await client.getUrl(
    Uri.parse('https://$hostName:${untrustedServer.port}/'),
  );
  var response4 = await request4.close();
  await response4.drain();
  Expect.equals(200, response4.statusCode);
  Expect.equals(1, callCount4);

  client.close();
  await server.close();
  await untrustedServer.close();
}
