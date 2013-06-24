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

  group('links', () {
    if (!Platform.isWindows) {
      group('follow-links', () {
        test('dir-link', () {
          expect(HttpServer.bind('localhost', 0).then((server) {
            var dir = new Directory('').createTempSync();
            var dir2 = new Directory('${dir.path}/dir2')..createSync();
            var link = new Link('${dir.path}/dir3')..createSync('dir2');
            var file = new File('${dir2.path}/file')..createSync();
            var virDir = new VirtualDirectory(dir.path);
            virDir.followLinks = true;

            virDir.serve(server);

            return new HttpClient().get('localhost', server.port, '/dir3/file')
                .then((request) => request.close())
                .then((response) => response.drain().then(
                    (_) => response.statusCode))
                .whenComplete(() {
                  server.close();
                  dir.deleteSync(recursive: true);
                });
          }), completion(equals(HttpStatus.OK)));
        });

        test('root-link', () {
          expect(HttpServer.bind('localhost', 0).then((server) {
            var dir = new Directory('').createTempSync();
            var link = new Link('${dir.path}/dir3')..createSync('.');
            var file = new File('${dir.path}/file')..createSync();
            var virDir = new VirtualDirectory(dir.path);
            virDir.followLinks = true;

            virDir.serve(server);

            return new HttpClient().get('localhost', server.port, '/dir3/file')
                .then((request) => request.close())
                .then((response) => response.drain().then(
                    (_) => response.statusCode))
                .whenComplete(() {
                  server.close();
                  dir.deleteSync(recursive: true);
                });
          }), completion(equals(HttpStatus.OK)));
        });

        group('bad-links', () {
          test('absolute-link', () {
            expect(HttpServer.bind('localhost', 0).then((server) {
              var dir = new Directory('').createTempSync();
              var file = new File('${dir.path}/file')..createSync();
              var link = new Link('${dir.path}/dir3')
                  ..createSync('${dir.path}/file');
              var virDir = new VirtualDirectory(dir.path);
              virDir.followLinks = true;

              virDir.serve(server);

              return new HttpClient().get('localhost',
                                          server.port,
                                          '/dir3/file')
                  .then((request) => request.close())
                  .then((response) => response.drain().then(
                      (_) => response.statusCode))
                  .whenComplete(() {
                    server.close();
                    dir.deleteSync(recursive: true);
                  });
            }), completion(equals(HttpStatus.NOT_FOUND)));
          });

          test('relative-parent-link', () {
            expect(HttpServer.bind('localhost', 0).then((server) {
              var dir = new Directory('').createTempSync();
              var name = new Path(dir.path).filename;
              var file = new File('${dir.path}/file')..createSync();
              var link = new Link('${dir.path}/dir3')
                  ..createSync('../$name/file');
              var virDir = new VirtualDirectory(dir.path);
              virDir.followLinks = true;

              virDir.serve(server);

              return new HttpClient().get('localhost',
                                          server.port,
                                          '/dir3/file')
                  .then((request) => request.close())
                  .then((response) => response.drain().then(
                      (_) => response.statusCode))
                  .whenComplete(() {
                    server.close();
                    dir.deleteSync(recursive: true);
                  });
            }), completion(equals(HttpStatus.NOT_FOUND)));
          });
        });
      });

      group('not-follow-links', () {
        test('dir-link', () {
          expect(HttpServer.bind('localhost', 0).then((server) {
            var dir = new Directory('').createTempSync();
            var dir2 = new Directory('${dir.path}/dir2')..createSync();
            var link = new Link('${dir.path}/dir3')..createSync('dir2');
            var file = new File('${dir2.path}/file')..createSync();
            var virDir = new VirtualDirectory(dir.path);
            virDir.followLinks = false;

            virDir.serve(server);

            return new HttpClient().get('localhost', server.port, '/dir3/file')
                .then((request) => request.close())
                .then((response) => response.drain().then(
                    (_) => response.statusCode))
                .whenComplete(() {
                  server.close();
                  dir.deleteSync(recursive: true);
                });
          }), completion(equals(HttpStatus.NOT_FOUND)));
        });
      });
    }
  });
}

