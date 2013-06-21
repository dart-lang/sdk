// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:unittest/unittest.dart";
import "package:http_server/http_server.dart";


void main() {
  group('serve-root', () {
    test('dir-exists', () {
      expect(HttpServer.bind('localhost', 0).then((server) {
        var dir = new Directory('').createTempSync();
        var virDir = new VirtualDirectory(dir.path);

        virDir.serve(server);

        return new HttpClient().get('localhost', server.port, '/')
            .then((request) => request.close())
            .then((response) => response.drain().then(
                (_) => response.statusCode))
            .whenComplete(() {
              server.close();
              dir.deleteSync();
            });
      }), completion(equals(HttpStatus.NOT_FOUND)));
    });

    test('dir-not-exists', () {
      expect(HttpServer.bind('localhost', 0).then((server) {
        var dir = new Directory('').createTempSync();
        dir.deleteSync();
        var virDir = new VirtualDirectory(dir.path);

        virDir.serve(server);

        return new HttpClient().get('localhost', server.port, '/')
            .then((request) => request.close())
            .then((response) => response.drain().then(
                (_) => response.statusCode))
            .whenComplete(() {
              server.close();
            });
      }), completion(equals(HttpStatus.NOT_FOUND)));
    });
  });

  group('serve-file', () {
    group('top-level', () {
      test('file-exists', () {
        expect(HttpServer.bind('localhost', 0).then((server) {
          var dir = new Directory('').createTempSync();
          var file = new File('${dir.path}/file')..createSync();
          var virDir = new VirtualDirectory(dir.path);

          virDir.serve(server);

          return new HttpClient().get('localhost', server.port, '/file')
              .then((request) => request.close())
              .then((response) => response.drain().then(
                  (_) => response.statusCode))
              .whenComplete(() {
                server.close();
                file.deleteSync();
                dir.deleteSync();
              });
        }), completion(equals(HttpStatus.OK)));
      });

      test('file-not-exists', () {
        expect(HttpServer.bind('localhost', 0).then((server) {
          var dir = new Directory('').createTempSync();
          var virDir = new VirtualDirectory(dir.path);

          virDir.serve(server);

          return new HttpClient().get('localhost', server.port, '/file')
              .then((request) => request.close())
              .then((response) => response.drain().then(
                  (_) => response.statusCode))
              .whenComplete(() {
                server.close();
                dir.deleteSync();
              });
        }), completion(equals(HttpStatus.NOT_FOUND)));
      });
    });

    group('in-dir', () {
      test('file-exists', () {
        expect(HttpServer.bind('localhost', 0).then((server) {
          var dir = new Directory('').createTempSync();
          var dir2 = new Directory('${dir.path}/dir')..createSync();
          var file = new File('${dir2.path}/file')..createSync();
          var virDir = new VirtualDirectory(dir.path);

          virDir.serve(server);

          return new HttpClient().get('localhost', server.port, '/dir/file')
              .then((request) => request.close())
              .then((response) => response.drain().then(
                  (_) => response.statusCode))
              .whenComplete(() {
                server.close();
                file.deleteSync();
                dir2.deleteSync();
                dir.deleteSync();
              });
        }), completion(equals(HttpStatus.OK)));
      });

      test('file-not-exists', () {
        expect(HttpServer.bind('localhost', 0).then((server) {
          var dir = new Directory('').createTempSync();
          var dir2 = new Directory('${dir.path}/dir')..createSync();
          var file = new File('${dir.path}/file')..createSync();
          var virDir = new VirtualDirectory(dir.path);

          virDir.serve(server);

          return new HttpClient().get('localhost', server.port, '/dir/file')
              .then((request) => request.close())
              .then((response) => response.drain().then(
                  (_) => response.statusCode))
              .whenComplete(() {
                server.close();
                file.deleteSync();
                dir2.deleteSync();
                dir.deleteSync();
              });
        }), completion(equals(HttpStatus.NOT_FOUND)));
      });
    });
  });
}

