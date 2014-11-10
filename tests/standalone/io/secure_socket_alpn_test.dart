// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

const String MAX_LEN_ERROR =
    'Length of protocol must be between 1 and 255';

const String MAX_MSG_LEN_ERROR =
    'The maximum message length supported is 2^15-1';

void InitializeSSL() {
  var testPkcertDatabase = Platform.script.resolve('pkcert').toFilePath();
  SecureSocket.initialize(database: testPkcertDatabase,
                          password: 'dartdart');
}

// Tests that client/server with same protocol can securly establish a
// connection, negogiate the protocol and can send data to each other.
void testSuccessfulAlpnNegogiationConnection(List<String> clientProtocols,
                                             List<String> serverProtocols,
                                             String selectedProtocol) {
  asyncStart();
  SecureServerSocket.bind('localhost', 0, 'localhost_cert',
     supportedProtocols: serverProtocols).then((SecureServerSocket server) {

    asyncStart();
    server.first.then((SecureSocket socket) {
      Expect.equals(selectedProtocol, socket.selectedProtocol);
      socket..write('server message')..close();
      socket.transform(ASCII.decoder).join('').then((String s) {
        Expect.equals('client message', s);
        asyncEnd();
      });
    });

    asyncStart();
    SecureSocket.connect('localhost', server.port,
        supportedProtocols: clientProtocols).then((socket) {
      Expect.equals(selectedProtocol, socket.selectedProtocol);
      socket..write('client message')..close();
      socket.transform(ASCII.decoder).join('').then((String s) {
        Expect.equals('server message', s);
        server.close();
        asyncEnd();
      });
    });

    asyncEnd();
  });
}

void testFailedAlpnNegogiationConnection(List<String> clientProtocols,
                                         List<String> serverProtocols) {
  asyncStart();
  SecureServerSocket.bind('localhost', 0, 'localhost_cert',
     supportedProtocols: serverProtocols).then((SecureServerSocket server) {

    asyncStart();
    server.first.catchError((error, stack) {
      Expect.isTrue(error is HandshakeException);
      asyncEnd();
    });

    asyncStart();
    SecureSocket.connect('localhost',
                         server.port,
                         supportedProtocols: clientProtocols)
        .catchError((error, stack) {
      Expect.isTrue(error is HandshakeException);
      asyncEnd();
    });

    asyncEnd();
  });
}

void testInvalidArgumentsLongName(List<String> protocols,
                                  bool isLenError,
                                  bool isMsgLenError) {
  asyncStart();
  SecureServerSocket.bind('localhost', 0, 'localhost_cert',
     supportedProtocols: protocols).then((SecureServerSocket server) {

    asyncStart();
    server.first.catchError((error, stack) {
      String errorString = '${(error as ArgumentError)}';
      if (isLenError) {
        Expect.isTrue(errorString.contains(MAX_LEN_ERROR));
      } else if (isMsgLenError) {
        Expect.isTrue(errorString.contains(MAX_MSG_LEN_ERROR));
      } else {
        throw 'unreachable';
      }
      asyncEnd();
    });

    asyncStart();
    SecureSocket.connect('localhost',
                         server.port,
                         supportedProtocols: protocols)
        .catchError((error, stack) {
      String errorString = '${(error as ArgumentError)}';
      if (isLenError) {
        Expect.isTrue(errorString.contains(MAX_LEN_ERROR));
      } else if (isMsgLenError) {
        Expect.isTrue(errorString.contains(MAX_MSG_LEN_ERROR));
      } else {
        throw 'unreachable';
      }
      asyncEnd();
    });

    asyncEnd();
  });
}

main() {
  InitializeSSL();
  final longname256 = 'p' * 256;
  final String longname255 = 'p' * 255;
  final String strangelongname255 = 'ø' + 'p' * 253;
  final String strangelongname256 = 'ø' + 'p' * 254;

  // This produces a message of (1 << 15)-2 bytes (1 length and 1 ascii byte).
  final List<String> allProtocols = new Iterable.generate(
      (1 << 14) - 1, (i) => '0').toList();

  // This produces a message of (1 << 15) bytes (1 length and 1 ascii byte).
  final List<String> allProtocolsPlusOne = new Iterable.generate(
      (1 << 14), (i) => '0').toList();

  // Protocols are in order of decreasing priority. First matching protocol
  // will be taken.

  // Test successfull negotiation, including priority.
  testSuccessfulAlpnNegogiationConnection(['a'],
                                          ['a'],
                                          'a');

  testSuccessfulAlpnNegogiationConnection([longname255],
                                          [longname255],
                                          longname255);

  testSuccessfulAlpnNegogiationConnection([strangelongname255],
                                          [strangelongname255],
                                          strangelongname255);

  testSuccessfulAlpnNegogiationConnection(allProtocols,
                                          allProtocols,
                                          '0');

  testSuccessfulAlpnNegogiationConnection(['a', 'b', 'c'],
                                          ['a', 'b', 'c'],
                                          'a');

  testSuccessfulAlpnNegogiationConnection(['a', 'b', 'c'],
                                          ['c'],
                                          'c');

  // Server precedence.
  testSuccessfulAlpnNegogiationConnection(['a', 'b', 'c'],
                                          ['c', 'b', 'a'],
                                          'a');

  testSuccessfulAlpnNegogiationConnection(['c'],
                                          ['a', 'b', 'c'],
                                          'c');

  testSuccessfulAlpnNegogiationConnection(['s1', 'b', 'e1'],
                                          ['s2', 'b', 'e2'],
                                          'b');

  // Test no protocol negotiation support
  testSuccessfulAlpnNegogiationConnection(null,
                                          null,
                                          null);

  testSuccessfulAlpnNegogiationConnection(['a', 'b', 'c'],
                                          null,
                                          null);

  testSuccessfulAlpnNegogiationConnection(null,
                                          ['a', 'b', 'c'],
                                          null);

  testSuccessfulAlpnNegogiationConnection([],
                                          [],
                                          null);

  testSuccessfulAlpnNegogiationConnection(['a', 'b', 'c'],
                                          [],
                                          null);

  testSuccessfulAlpnNegogiationConnection([],
                                          ['a', 'b', 'c'],
                                          null);

  // Test non-overlapping protocols.
  testFailedAlpnNegogiationConnection(['a'], ['b']);


  // Test too short / too long protocol names.
  testInvalidArgumentsLongName([longname256], true, false);
  testInvalidArgumentsLongName([strangelongname256], true, false);
  testInvalidArgumentsLongName([''], true, false);
  testInvalidArgumentsLongName(allProtocolsPlusOne, false, true);
  testInvalidArgumentsLongName(allProtocolsPlusOne, false, true);
}
