// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import "package:expect/expect.dart";

// See also http_headers_test.dart.

Future<void> testContentDoesNotMatchContentLength() async {
  final server = await HttpServer.bind("127.0.0.1", 0);
  final client = HttpClient();
  try {
    final request = await client.get("127.0.0.1", server.port, "/");
    final headers = request.headers;
    headers.contentLength = 100;
    headers.set('Content-Length', 100);
    Expect.equals('100', headers['Content-Length']?[0]);
    try {
      await request.close();
    } catch (e) {
      request.abort();
      // Expected: body length does not match specified content length.
    }

    final req = await client.get("127.0.0.1", server.port, "/");
    req.headers.contentLength = 100;
    req.add(List.filled(100, 0));
    final resFuture = req.close();
    final serverReq = await server.first;
    Expect.equals(
      "100",
      serverReq.headers.value(HttpHeaders.contentLengthHeader),
    );
    Expect.isNull(serverReq.headers.value(HttpHeaders.transferEncodingHeader));
    Expect.equals(100, serverReq.contentLength);
    Expect.isFalse(serverReq.headers.chunkedTransferEncoding);
    await serverReq.drain();
    await serverReq.response.close();
    await (await resFuture).drain();
  } finally {
    client.close();
    await server.close();
  }
}

Future<void> testRequestDefaults() async {
  final client = HttpClient();

  // GET
  {
    final server = await HttpServer.bind("127.0.0.1", 0);
    final req = await client.openUrl(
      "GET",
      Uri.parse("http://127.0.0.1:${server.port}/"),
    );
    Expect.equals(0, req.contentLength);
    Expect.isFalse(req.headers.chunkedTransferEncoding);
    Expect.equals("0", req.headers.value("content-length"));
    Expect.isNull(req.headers.value("transfer-encoding"));

    final resFuture = req.close();
    final serverReq = await server.first;
    Expect.isNull(serverReq.headers.value(HttpHeaders.contentLengthHeader));
    Expect.isNull(serverReq.headers.value(HttpHeaders.transferEncodingHeader));
    Expect.equals(-1, serverReq.contentLength);
    Expect.isFalse(serverReq.headers.chunkedTransferEncoding);
    await serverReq.response.close();
    await (await resFuture).drain();
    await server.close();
  }

  // HEAD
  {
    final server = await HttpServer.bind("127.0.0.1", 0);
    final req = await client.openUrl(
      "HEAD",
      Uri.parse("http://127.0.0.1:${server.port}/"),
    );
    Expect.equals(0, req.contentLength);
    Expect.isFalse(req.headers.chunkedTransferEncoding);
    Expect.equals("0", req.headers.value("content-length"));
    Expect.isNull(req.headers.value("transfer-encoding"));

    final resFuture = req.close();
    final serverReq = await server.first;
    Expect.isNull(serverReq.headers.value(HttpHeaders.contentLengthHeader));
    Expect.isNull(serverReq.headers.value(HttpHeaders.transferEncodingHeader));
    Expect.equals(-1, serverReq.contentLength);
    Expect.isFalse(serverReq.headers.chunkedTransferEncoding);
    await serverReq.response.close();
    await (await resFuture).drain();
    await server.close();
  }

  // POST
  {
    final server = await HttpServer.bind("127.0.0.1", 0);
    final req = await client.openUrl(
      "POST",
      Uri.parse("http://127.0.0.1:${server.port}/"),
    );
    Expect.equals(-1, req.contentLength);
    Expect.isTrue(req.headers.chunkedTransferEncoding);
    Expect.isNull(req.headers.value("content-length"));
    Expect.equals("chunked", req.headers.value("transfer-encoding"));

    req.write("hello");
    final resFuture = req.close();
    final serverReq = await server.first;
    Expect.isNull(serverReq.headers.value(HttpHeaders.contentLengthHeader));
    Expect.equals(
      "chunked",
      serverReq.headers.value(HttpHeaders.transferEncodingHeader),
    );
    Expect.equals(-1, serverReq.contentLength);
    Expect.isTrue(serverReq.headers.chunkedTransferEncoding);
    await serverReq.drain();
    await serverReq.response.close();
    await (await resFuture).drain();
    await server.close();
  }

  client.close();
}

Future<void> testNegativeOneContentLengthHeaders() async {
  final client = HttpClient();

  for (final method in ["GET", "HEAD"]) {
    // contentLength = -1
    {
      final server = await HttpServer.bind("127.0.0.1", 0);
      final req = await client.openUrl(
        method,
        Uri.parse("http://127.0.0.1:${server.port}/"),
      );
      req.contentLength = -1;
      Expect.equals(-1, req.contentLength);
      Expect.isFalse(req.headers.chunkedTransferEncoding);
      Expect.isNull(req.headers.value("content-length"));
      Expect.isNull(req.headers.value("transfer-encoding"));

      req.contentLength = 10;
      Expect.equals(10, req.contentLength);
      Expect.isFalse(req.headers.chunkedTransferEncoding);
      Expect.equals("10", req.headers.value("content-length"));
      Expect.isNull(req.headers.value("transfer-encoding"));

      req.contentLength = -1;
      Expect.equals(-1, req.contentLength);
      Expect.isFalse(req.headers.chunkedTransferEncoding);
      Expect.isNull(req.headers.value("content-length"));
      Expect.isNull(req.headers.value("transfer-encoding"));

      final resFuture = req.close();
      final serverReq = await server.first;
      Expect.isNull(serverReq.headers.value(HttpHeaders.contentLengthHeader));
      Expect.isNull(
        serverReq.headers.value(HttpHeaders.transferEncodingHeader),
      );
      Expect.equals(-1, serverReq.contentLength);
      Expect.isFalse(serverReq.headers.chunkedTransferEncoding);
      await serverReq.response.close();
      await (await resFuture).drain();
      await server.close();
    }

    // We support non-empty bodies for GET/POST. We probably shouldn't but that
    // is the current behavior.
    // contentLength = 10
    {
      final server = await HttpServer.bind("127.0.0.1", 0);
      final req = await client.openUrl(
        method,
        Uri.parse("http://127.0.0.1:${server.port}/"),
      );
      req.contentLength = 10;
      Expect.equals(10, req.contentLength);
      Expect.isFalse(req.headers.chunkedTransferEncoding);
      Expect.equals("10", req.headers.value("content-length"));
      Expect.isNull(req.headers.value("transfer-encoding"));

      req.add(List.filled(10, 0));
      final resFuture = req.close();
      final serverReq = await server.first;
      Expect.equals(
        "10",
        serverReq.headers.value(HttpHeaders.contentLengthHeader),
      );
      Expect.isNull(
        serverReq.headers.value(HttpHeaders.transferEncodingHeader),
      );
      Expect.equals(10, serverReq.contentLength);
      Expect.isFalse(serverReq.headers.chunkedTransferEncoding);
      await serverReq.drain();
      await serverReq.response.close();
      await (await resFuture).drain();
      await server.close();
    }

    // We support setting chunkedTransferEncoding for GET/HEAD requests.
    {
      final server = await HttpServer.bind("127.0.0.1", 0);
      final req = await client.openUrl(
        method,
        Uri.parse("http://127.0.0.1:${server.port}/"),
      );
      req.headers.chunkedTransferEncoding = true;
      Expect.isTrue(req.headers.chunkedTransferEncoding);
      Expect.equals("chunked", req.headers.value("transfer-encoding"));

      req.write("hello");
      final resFuture = req.close();
      final serverReq = await server.first;
      Expect.isNull(serverReq.headers.value(HttpHeaders.contentLengthHeader));
      Expect.equals(
        "chunked",
        serverReq.headers.value(HttpHeaders.transferEncodingHeader),
      );
      Expect.equals(-1, serverReq.contentLength);
      Expect.isTrue(serverReq.headers.chunkedTransferEncoding);
      await serverReq.drain();
      await serverReq.response.close();
      await (await resFuture).drain();
      await server.close();
    }
  }

  // POST with contentLength = 10
  {
    final server = await HttpServer.bind("127.0.0.1", 0);
    final req = await client.openUrl(
      "POST",
      Uri.parse("http://127.0.0.1:${server.port}/"),
    );
    req.contentLength = 10;
    Expect.isFalse(req.headers.chunkedTransferEncoding);
    Expect.equals("10", req.headers.value("content-length"));
    Expect.isNull(req.headers.value("transfer-encoding"));

    req.add(List.filled(10, 0));
    final resFuture = req.close();
    final serverReq = await server.first;
    Expect.equals(
      "10",
      serverReq.headers.value(HttpHeaders.contentLengthHeader),
    );
    Expect.isNull(serverReq.headers.value(HttpHeaders.transferEncodingHeader));
    Expect.equals(10, serverReq.contentLength);
    Expect.isFalse(serverReq.headers.chunkedTransferEncoding);
    await serverReq.drain();
    await serverReq.response.close();
    await (await resFuture).drain();
    await server.close();
  }

  // POST with contentLength = -1
  {
    final server = await HttpServer.bind("127.0.0.1", 0);
    final req = await client.openUrl(
      "POST",
      Uri.parse("http://127.0.0.1:${server.port}/"),
    );
    req.contentLength = 10;
    Expect.isFalse(req.headers.chunkedTransferEncoding);
    Expect.equals("10", req.headers.value("content-length"));
    req.contentLength = -1;
    Expect.isTrue(req.headers.chunkedTransferEncoding);
    Expect.equals("chunked", req.headers.value("transfer-encoding"));

    req.write("hello");
    final resFuture = req.close();
    final serverReq = await server.first;
    Expect.isNull(serverReq.headers.value(HttpHeaders.contentLengthHeader));
    Expect.equals(
      "chunked",
      serverReq.headers.value(HttpHeaders.transferEncodingHeader),
    );
    Expect.equals(-1, serverReq.contentLength);
    Expect.isTrue(serverReq.headers.chunkedTransferEncoding);
    await serverReq.drain();
    await serverReq.response.close();
    await (await resFuture).drain();
    await server.close();
  }

  client.close();
}

Future<void> main() async {
  await testContentDoesNotMatchContentLength();
  await testRequestDefaults();
  await testNegativeOneContentLengthHeaders();
}
