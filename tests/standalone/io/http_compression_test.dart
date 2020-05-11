// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import 'package:expect/expect.dart';
import 'dart:io';
import 'dart:typed_data';

Future<void> testServerCompress({bool clientAutoUncompress: true}) async {
  Future<void> test(List<int> data) async {
    final server = await HttpServer.bind("127.0.0.1", 0);
    server.autoCompress = true;
    server.listen((request) {
      request.response.add(data);
      request.response.close();
    });
    var client = new HttpClient();
    client.autoUncompress = clientAutoUncompress;
    final request = await client.get("127.0.0.1", server.port, "/");
    request.headers.set(HttpHeaders.acceptEncodingHeader, "gzip,deflate");
    final response = await request.close();
    Expect.equals(
        "gzip", response.headers.value(HttpHeaders.contentEncodingHeader));
    final list =
        await response.fold<List<int>>(<int>[], (list, b) => list..addAll(b));
    if (clientAutoUncompress) {
      Expect.listEquals(data, list);
    } else {
      Expect.listEquals(data, gzip.decode(list));
    }
    server.close();
    client.close();
  }

  await test("My raw server provided data".codeUnits);
  var longBuffer = new Uint8List(1024 * 1024);
  for (int i = 0; i < longBuffer.length; i++) {
    longBuffer[i] = i & 0xFF;
  }
  await test(longBuffer);
}

Future<void> testAcceptEncodingHeader() async {
  Future<void> test(String encoding, bool valid) async {
    final server = await HttpServer.bind("127.0.0.1", 0);
    server.autoCompress = true;
    server.listen((request) {
      request.response.write("data");
      request.response.close();
    });
    var client = new HttpClient();
    final request = await client.get("127.0.0.1", server.port, "/");
    request.headers.set(HttpHeaders.acceptEncodingHeader, encoding);
    final response = await request.close();
    Expect.equals(valid,
        ("gzip" == response.headers.value(HttpHeaders.contentEncodingHeader)));
    await response.listen((_) {}).asFuture();
    server.close();
    client.close();
  }

  await test('gzip', true);
  await test('deflate', false);
  await test('gzip, deflate', true);
  await test('gzip ,deflate', true);
  await test('gzip  ,  deflate', true);
  await test('deflate,gzip', true);
  await test('deflate, gzip', true);
  await test('deflate ,gzip', true);
  await test('deflate  ,  gzip', true);
  await test('abc,deflate  ,  gzip,def,,,ghi  ,jkl', true);
  await test('xgzip', false);
  await test('gzipx;', false);
}

Future<void> testDisableCompressTest() async {
  final server = await HttpServer.bind("127.0.0.1", 0);
  Expect.equals(false, server.autoCompress);
  server.listen((request) {
    Expect.equals(
        'gzip', request.headers.value(HttpHeaders.acceptEncodingHeader));
    request.response.write("data");
    request.response.close();
  });
  final client = new HttpClient();
  final request = await client.get("127.0.0.1", server.port, "/");
  final response = await request.close();
  Expect.equals(
      null, response.headers.value(HttpHeaders.contentEncodingHeader));
  await response.listen((_) {}).asFuture();
  server.close();
  client.close();
}

void main() async {
  await testServerCompress();
  await testServerCompress(clientAutoUncompress: false);
  await testAcceptEncodingHeader();
  await testDisableCompressTest();
}
