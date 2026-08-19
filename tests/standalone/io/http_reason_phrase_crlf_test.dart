// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test: HTTP response splitting via reasonPhrase CRLF injection.
//
// Before the fix, setting reasonPhrase to a string containing \r\n would
// inject arbitrary headers and body content into the HTTP response stream.
// The fix validates reasonPhrase with _isValidValueString, rejecting
// control characters (bytes <= 31 except HT).

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";
import "dart:async";
import "dart:io";

// Verify that setting reasonPhrase to [phrase] throws a FormatException.
Future<void> testReasonPhraseRejected(String phrase, String label) async {
  var server = await HttpServer.bind("127.0.0.1", 0);
  try {
    server.listen((request) {
      Expect.throwsFormatException(
        () => request.response.reasonPhrase = phrase,
        "reasonPhrase with $label must throw",
      );
      var response = request.response;
      response.statusCode = 200;
      response.close();
    });

    var client = HttpClient();
    var request = await client.get("127.0.0.1", server.port, "/");
    var response = await request.close();
    Expect.equals(200, response.statusCode);
    await response.drain();
    client.close();
  } finally {
    await server.close();
  }
}

// Verify that a valid reasonPhrase is accepted and round-trips correctly.
Future<void> testReasonPhraseAccepted(String phrase) async {
  var server = await HttpServer.bind("127.0.0.1", 0);
  try {
    server.listen((request) {
      var response = request.response;
      response.statusCode = 200;
      response.reasonPhrase = phrase;
      response.close();
    });

    var client = HttpClient();
    var request = await client.get("127.0.0.1", server.port, "/");
    var response = await request.close();
    Expect.equals(200, response.statusCode);
    Expect.equals(phrase, response.reasonPhrase);
    await response.drain();
    client.close();
  } finally {
    await server.close();
  }
}

// End-to-end: read the raw wire bytes to prove no response splitting occurs.
// This is the real attack scenario.
Future<void> testNoResponseSplittingOnWire() async {
  var server = await HttpServer.bind("127.0.0.1", 0);
  try {
    server.listen((request) {
      var response = request.response;
      // The CRLF injection attempt must throw.
      Expect.throwsFormatException(
        () => response.reasonPhrase = "OK\r\nX-Injected: evil\r\n\r\nSMUGGLED",
      );
      response.statusCode = 200;
      response.reasonPhrase = "OK";
      response.headers.contentType = ContentType.text;
      response.write("legitimate body");
      response.close();
    });

    var socket = await Socket.connect("127.0.0.1", server.port);
    socket.write(
      "GET / HTTP/1.1\r\n"
      "Host: 127.0.0.1:${server.port}\r\n"
      "Connection: close\r\n\r\n",
    );
    var body = StringBuffer();
    var completer = Completer<String>();
    socket.listen(
      (data) => body.write(String.fromCharCodes(data)),
      onDone: () => completer.complete(body.toString()),
    );
    var rawResponse = await completer.future;
    await socket.close();

    // No injected content in the raw response.
    Expect.isFalse(rawResponse.contains("X-Injected"));
    Expect.isFalse(rawResponse.contains("SMUGGLED"));
    // Legitimate response present.
    Expect.isTrue(rawResponse.contains("200"));
    Expect.isTrue(rawResponse.contains("legitimate body"));
  } finally {
    await server.close();
  }
}

void main() async {
  asyncStart();

  // --- Control characters that MUST be rejected ---

  // CRLF injection — the actual attack vector.
  await testReasonPhraseRejected(
    "OK\r\nX-Injected: evil\r\n\r\nbody",
    "CRLF injection payload",
  );

  // Individual CR and LF.
  await testReasonPhraseRejected("OK\rEvil", "lone CR (0x0D)");
  await testReasonPhraseRejected("OK\nEvil", "lone LF (0x0A)");

  // NUL byte.
  await testReasonPhraseRejected("OK\x00Evil", "NUL (0x00)");

  // Other control characters in 0x01-0x1F (except 0x09 HT).
  await testReasonPhraseRejected("OK\x01", "SOH (0x01)");
  await testReasonPhraseRejected("OK\x08", "BS (0x08)");
  await testReasonPhraseRejected("OK\x0B", "VT (0x0B)");
  await testReasonPhraseRejected("OK\x0C", "FF (0x0C)");
  await testReasonPhraseRejected("OK\x0E", "SO (0x0E)");
  await testReasonPhraseRejected("OK\x1F", "US (0x1F)");

  // High bytes (>= 0x80) fall outside _isValueChar's 32-127 range and are
  // rejected. NOTE: DEL (0x7F) IS accepted by _isValueChar (`byte < 128`),
  // matching how dart:io validates header values; it does not enable response
  // splitting, so it is intentionally not asserted as rejected here.
  await testReasonPhraseRejected("OK\x80", "0x80");
  await testReasonPhraseRejected("OK\xFF", "0xFF");

  // --- Valid reason phrases that MUST be accepted ---

  await testReasonPhraseAccepted("OK");
  await testReasonPhraseAccepted("Not Found");
  await testReasonPhraseAccepted("Internal Server Error");

  // Tab (0x09) is explicitly allowed by _isValueChar.
  await testReasonPhraseAccepted("OK\tDetails");

  // Printable ASCII boundaries.
  await testReasonPhraseAccepted("Space: "); // 0x20
  await testReasonPhraseAccepted("Tilde: ~"); // 0x7E

  // --- End-to-end wire-level verification ---

  await testNoResponseSplittingOnWire();

  asyncEnd();
}
