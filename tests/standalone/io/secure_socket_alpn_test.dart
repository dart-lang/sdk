// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// OtherResources=certificates/server_chain.pem
// OtherResources=certificates/server_key.pem
// OtherResources=certificates/trusted_certs.pem

import 'dart:io';
import 'dart:convert';

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

const String NAME_LENGTH_ERROR = 'Length of protocol must be between 1 and 255';

const String MESSAGE_LENGTH_ERROR =
    'The maximum message length supported is 2^13-1';

String localFile(path) => Platform.script.resolve(path).toFilePath();

SecurityContext clientContext() => new SecurityContext()
  ..setTrustedCertificates(localFile('certificates/trusted_certs.pem'));

SecurityContext serverContext() => new SecurityContext()
  ..useCertificateChain(localFile('certificates/server_chain.pem'))
  ..usePrivateKey(localFile('certificates/server_key.pem'),
      password: 'dartdart');

// Tests that client/server with same protocol can securely establish a
// connection, negotiate the protocol and can send data to each other.
void testSuccessfulAlpnNegotiationConnection(List<String> clientProtocols,
    List<String> serverProtocols, String selectedProtocol) {
  asyncStart();
  var sContext = serverContext()..setAlpnProtocols(serverProtocols, true);
  SecureServerSocket
      .bind('localhost', 0, sContext)
      .then((SecureServerSocket server) {
    asyncStart();
    server.first.then((SecureSocket socket) {
      Expect.equals(selectedProtocol, socket.selectedProtocol);
      socket
        ..write('server message')
        ..close();
      socket.transform(ASCII.decoder).join('').then((String s) {
        Expect.equals('client message', s);
        asyncEnd();
      });
    });

    asyncStart();
    SecureSocket
        .connect('localhost', server.port,
            context: clientContext(), supportedProtocols: clientProtocols)
        .then((socket) {
      Expect.equals(selectedProtocol, socket.selectedProtocol);
      socket
        ..write('client message')
        ..close();
      socket.transform(ASCII.decoder).join('').then((String s) {
        Expect.equals('server message', s);
        server.close();
        asyncEnd();
      });
    });

    asyncEnd();
  });
}

void testInvalidArgument(List<String> protocols, String errorIncludes) {
  testInvalidArgumentServerContext(protocols, errorIncludes);
  testInvalidArgumentClientContext(protocols, errorIncludes);
  testInvalidArgumentClientConnect(protocols, errorIncludes);
}

void testInvalidArgumentServerContext(
    List<String> protocols, String errorIncludes) {
  Expect.throws(() => serverContext().setAlpnProtocols(protocols, true), (e) {
    Expect.isTrue(e is ArgumentError);
    Expect.isTrue(e.toString().contains(errorIncludes));
    return true;
  });
}

void testInvalidArgumentClientContext(
    List<String> protocols, String errorIncludes) {
  Expect.throws(() => clientContext().setAlpnProtocols(protocols, false), (e) {
    Expect.isTrue(e is ArgumentError);
    Expect.isTrue(e.toString().contains(errorIncludes));
    return true;
  });
}

void testInvalidArgumentClientConnect(
    List<String> protocols, String errorIncludes) {
  asyncStart();
  var sContext = serverContext()..setAlpnProtocols(['abc'], true);
  SecureServerSocket.bind('localhost', 0, sContext).then((server) async {
    asyncStart();
    server.listen((SecureSocket socket) {
      Expect.fail(
          "Unexpected connection made to server, with bad client argument");
    }, onError: (e) {
      Expect.fail("Unexpected error on server stream: $e");
    }, onDone: () {
      asyncEnd();
    });

    asyncStart();
    SecureSocket
        .connect('localhost', server.port,
            context: clientContext(), supportedProtocols: protocols)
        .then((socket) {
      Expect.fail(
          "Unexpected connection made from client, with bad client argument");
    }, onError: (e) {
      Expect.isTrue(e is ArgumentError);
      Expect.isTrue(e.toString().contains(errorIncludes));
      server.close();
      asyncEnd();
    });
    asyncEnd();
  });
}

main() {
  if (!SecurityContext.alpnSupported) {
    return 0;
  }
  final longname256 = 'p' * 256;
  final String longname255 = 'p' * 255;
  final String strangelongname255 = 'ø' + 'p' * 253;
  final String strangelongname256 = 'ø' + 'p' * 254;

  // This produces a message of (1 << 13) - 2 bytes. 2^12 -1 strings are each
  // encoded by 1 length byte and 1 ascii byte.
  final List<String> manyProtocols =
      new Iterable.generate((1 << 12) - 1, (i) => '0').toList();

  // This produces a message of (1 << 13) bytes. 2^12 strings are each
  // encoded by 1 length byte and 1 ascii byte.
  final List<String> tooManyProtocols =
      new Iterable.generate((1 << 12), (i) => '0').toList();

  // Protocols are in order of decreasing priority. The server will select
  // the first protocol from its list that has a match in the client list.
  // Test successful negotiation, including priority.
  testSuccessfulAlpnNegotiationConnection(['a'], ['a'], 'a');

  testSuccessfulAlpnNegotiationConnection(
      [longname255], [longname255], longname255);

  testSuccessfulAlpnNegotiationConnection(
      [strangelongname255], [strangelongname255], strangelongname255);
  testSuccessfulAlpnNegotiationConnection(manyProtocols, manyProtocols, '0');
  testSuccessfulAlpnNegotiationConnection(
      ['a', 'b', 'c'], ['a', 'b', 'c'], 'a');

  testSuccessfulAlpnNegotiationConnection(['a', 'b', 'c'], ['c'], 'c');

  // Server precedence.
  testSuccessfulAlpnNegotiationConnection(
      ['a', 'b', 'c'], ['c', 'b', 'a'], 'c');

  testSuccessfulAlpnNegotiationConnection(['c'], ['a', 'b', 'c'], 'c');

  testSuccessfulAlpnNegotiationConnection(
      ['s1', 'b', 'e1'], ['s2', 'b', 'e2'], 'b');
  // Test no protocol negotiation support
  testSuccessfulAlpnNegotiationConnection(null, null, null);

  testSuccessfulAlpnNegotiationConnection(['a', 'b', 'c'], null, null);

  testSuccessfulAlpnNegotiationConnection(null, ['a', 'b', 'c'], null);

  testSuccessfulAlpnNegotiationConnection([], [], null);

  testSuccessfulAlpnNegotiationConnection(['a', 'b', 'c'], [], null);

  testSuccessfulAlpnNegotiationConnection([], ['a', 'b', 'c'], null);

  // Test non-overlapping protocols.  The ALPN RFC says the connection
  // should be terminated, but OpenSSL continues as if no ALPN is present.
  // Issue  https://github.com/dart-lang/sdk/issues/23580
  // Chromium issue https://code.google.com/p/chromium/issues/detail?id=497770
  testSuccessfulAlpnNegotiationConnection(['a'], ['b'], null);

  // Test too short / too long protocol names.
  testInvalidArgument([longname256], NAME_LENGTH_ERROR);
  testInvalidArgument([strangelongname256], NAME_LENGTH_ERROR);
  testInvalidArgument([''], NAME_LENGTH_ERROR);
  testInvalidArgument(tooManyProtocols, MESSAGE_LENGTH_ERROR);
}
