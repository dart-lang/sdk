// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

Map lookupServiceObject(String path) {
  var io = currentMirrorSystem().findLibrary(const Symbol('dart.io'));
  var m = MirrorSystem.getSymbol('_serviceObjectHandler', io);
  var paths = Uri.parse(path).pathSegments;
  Expect.equals('io', paths.first);
  return JSON.decode(
      io.invoke(m, [paths.sublist(1), [], []]).reflectee);
}


String getServicePath(obj) {
  var io = currentMirrorSystem().findLibrary(const Symbol('dart.io'));
  var m = MirrorSystem.getSymbol('_getServicePath', io);
  return io.invoke(m, [obj]).reflectee;
}


Future testHttpServer1() {
  return HttpServer.bind('localhost', 0).then((server) {
    var path = getServicePath(server);
    var map = lookupServiceObject(path);
    Expect.equals(map['type'], 'HttpServer');
    Expect.equals(map['id'], path);
    Expect.equals(map['address'], 'localhost');
    Expect.equals(map['port'], server.port);
    Expect.equals(map['closed'], false);
    Expect.listEquals(map['idle'], []);
    Expect.listEquals(map['active'], []);
    var socket = map['socket'];
    Expect.equals(socket['type'], '@Socket');
    Expect.equals(socket['kind'], 'Listening');
    // Validate owner back-ref.
    socket = lookupServiceObject(socket['id']);
    Expect.equals(socket['owner']['id'], path);
    return server.close();
  });
}


Future testHttpServerConnection1() {
  return HttpServer.bind('localhost', 0).then((server) {
    server.listen((request) {
      var map = lookupServiceObject(getServicePath(server));
      Expect.listEquals(map['idle'], []);
      Expect.equals(map['active'].length, 1);
      var active = map['active'].first;
      Expect.equals(active['type'], '@HttpServerConnection');
      var path = active['id'];
      map = lookupServiceObject(path);
      Expect.equals(map['type'], 'HttpServerConnection');
      var socket = map['socket'];
      Expect.equals(socket['type'], '@Socket');
      Expect.equals(socket['kind'], 'Normal');
      // Validate owner back-ref.
      socket = lookupServiceObject(socket['id']);
      Expect.equals(socket['owner']['id'], path);
      request.response.close();
    });
    var client = new HttpClient();
    return client.get('localhost', server.port, '/')
        .then((request) => request.close())
        .then((response) => response.drain())
        .then((_) {
          // The connection should be idle now.
          var map = lookupServiceObject(getServicePath(server));
          Expect.equals(map['idle'].length, 1);
          Expect.listEquals(map['active'], []);
          return server.close();
        });

  });
}


void main() {
  final tests = [
    testHttpServer1(),
    testHttpServerConnection1(),
  ];

  asyncStart();
  // Run one test at a time.
  Future.forEach(tests, (f) => f)
      .then((_) {
        asyncEnd();
      });
}
