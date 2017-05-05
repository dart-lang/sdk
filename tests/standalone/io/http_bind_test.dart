// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

testBindShared(String host, bool v6Only) async {
  asyncStart();

  // Sent a single request using a new HttpClient to ensure a new TCP
  // connection is used.
  Future singleRequest(host, port, statusCode) async {
    var client = new HttpClient();
    var request = await client.open('GET', host, port, '/');
    var response = await request.close();
    await response.drain();
    Expect.equals(statusCode, response.statusCode);
    client.close(force: true);
  }

  Completer server1Request = new Completer();
  Completer server2Request = new Completer();

  var server1 = await HttpServer.bind(host, 0, v6Only: v6Only, shared: true);
  var port = server1.port;
  Expect.isTrue(port > 0);

  var server2 = await HttpServer.bind(host, port, v6Only: v6Only, shared: true);
  Expect.equals(server1.address.address, server2.address.address);
  Expect.equals(port, server2.port);

  server1.listen((request) {
    server1Request.complete();
    request.response.statusCode = 501;
    request.response.close();
  });

  await singleRequest(host, port, 501);
  await server1.close();

  server2.listen((request) {
    server2Request.complete();
    request.response.statusCode = 502;
    request.response.close();
  });

  await singleRequest(host, port, 502);
  await server2.close();

  await server1Request.future;
  await server2Request.future;

  asyncEnd();
}

void main() {
  // Please don't change this to use await/async.
  asyncStart();
  supportsIPV6().then((ok) {
    var addresses = ['127.0.0.1'];
    if (ok) {
      addresses.add('::1');
    }
    var futures = [];
    for (var host in addresses) {
      futures.add(testBindShared(host, false));
      futures.add(testBindShared(host, true));
    }
    Future.wait(futures).then((_) => asyncEnd());
  });
}

Future<bool> supportsIPV6() async {
  try {
    var socket = await ServerSocket.bind('::1', 0);
    await socket.close();
    return true;
  } catch (e) {
    print(e);
    return false;
  }
}
