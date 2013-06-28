// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import "package:unittest/unittest.dart";
import "package:http_server/http_server.dart";

import 'utils.dart';


void main() {
  group('serve-root', () {
    test('dir-exists', () {
      expect(HttpServer.bind('localhost', 0).then((server) {
        var dir = new Directory('').createTempSync();
        var virDir = new VirtualDirectory(dir.path);

        virDir.serve(server);

        return getStatusCode(server.port, '/')
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

        return getStatusCode(server.port, '/')
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

          return getStatusCode(server.port, '/file')
              .whenComplete(() {
                server.close();
                dir.deleteSync(recursive: true);
              });
        }), completion(equals(HttpStatus.OK)));
      });

      test('file-not-exists', () {
        expect(HttpServer.bind('localhost', 0).then((server) {
          var dir = new Directory('').createTempSync();
          var virDir = new VirtualDirectory(dir.path);

          virDir.serve(server);

          return getStatusCode(server.port, '/file')
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

          return getStatusCode(server.port, '/dir/file')
              .whenComplete(() {
                server.close();
                dir.deleteSync(recursive: true);
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

          return getStatusCode(server.port, '/dir/file')
              .whenComplete(() {
                server.close();
                dir.deleteSync(recursive: true);
              });
        }), completion(equals(HttpStatus.NOT_FOUND)));
      });
    });
  });

  group('serve-dir', () {
    group('top-level', () {
      test('simple', () {
        expect(HttpServer.bind('localhost', 0).then((server) {
          var dir = new Directory('').createTempSync();
          var virDir = new VirtualDirectory(dir.path);
          virDir.allowDirectoryListing = true;

          virDir.serve(server);

          return getAsString(server.port, '/')
          .whenComplete(() {
            server.close();
            dir.deleteSync();
          });
        }), completion(contains('Index of /')));
      });

      test('files', () {
        expect(HttpServer.bind('localhost', 0).then((server) {
          var dir = new Directory('').createTempSync();
          var virDir = new VirtualDirectory(dir.path);
          for (int i = 0; i < 10; i++) {
            new File('${dir.path}/$i').createSync();
          }
          virDir.allowDirectoryListing = true;

          virDir.serve(server);

          return getAsString(server.port, '/')
          .whenComplete(() {
            server.close();
            dir.deleteSync(recursive: true);
          });
        }), completion(contains('Index of /')));
      });

      test('dirs', () {
        expect(HttpServer.bind('localhost', 0).then((server) {
          var dir = new Directory('').createTempSync();
          var virDir = new VirtualDirectory(dir.path);
          for (int i = 0; i < 10; i++) {
            new Directory('${dir.path}/$i').createSync();
          }
          virDir.allowDirectoryListing = true;

          virDir.serve(server);

          return getAsString(server.port, '/')
          .whenComplete(() {
            server.close();
            dir.deleteSync(recursive: true);
          });
        }), completion(contains('Index of /')));
      });

      test('recursive-link', () {
        expect(HttpServer.bind('localhost', 0).then((server) {
          var dir = new Directory('').createTempSync();
          var link = new Link('${dir.path}/recursive')..createSync('.');
          var virDir = new VirtualDirectory(dir.path);
          virDir.allowDirectoryListing = true;

          virDir.serve(server);

          return Future.wait([
              getAsString(server.port, '/').then(
                  (s) => s.contains('recursive/')),
              getAsString(server.port, '/').then(
                  (s) => !s.contains('../')),
              getAsString(server.port, '/').then(
                  (s) => s.contains('Index of /')),
              getAsString(server.port, '/recursive').then(
                  (s) => s.contains('recursive/')),
              getAsString(server.port, '/recursive').then(
                  (s) => s.contains('../')),
              getAsString(server.port, '/recursive').then(
                  (s) => s.contains('Index of /recursive'))])
              .whenComplete(() {
                server.close();
                dir.deleteSync(recursive: true);
              });
        }), completion(equals([true, true, true, true, true, true])));
      });
    });

    group('custom', () {
      test('simple', () {
        expect(HttpServer.bind('localhost', 0).then((server) {
          var dir = new Directory('').createTempSync();
          var virDir = new VirtualDirectory(dir.path);
          virDir.allowDirectoryListing = true;
          virDir.setDirectoryHandler((dir2, request) {
            expect(dir2, isNotNull);
            expect(FileSystemEntity.identicalSync(dir.path, dir2.path), isTrue);
            request.response.write('My handler ${request.uri.path}');
            request.response.close();
          });

          virDir.serve(server);

          return getAsString(server.port, '/')
          .whenComplete(() {
            server.close();
            dir.deleteSync();
          });
        }), completion(contains('My handler /')));
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

            return getStatusCode(server.port, '/dir3/file')
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

            return getStatusCode(server.port, '/dir3/file')
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

            return getStatusCode(server.port, '/dir3/file')
                .whenComplete(() {
                  server.close();
                  dir.deleteSync(recursive: true);
                });
          }), completion(equals(HttpStatus.NOT_FOUND)));
        });
      });
    }
  });

  group('last-modified', () {
    group('file', () {
      test('file-exists', () {
        expect(HttpServer.bind('localhost', 0).then((server) {
          var dir = new Directory('').createTempSync();
          var file = new File('${dir.path}/file')..createSync();
          var virDir = new VirtualDirectory(dir.path);

          virDir.serve(server);

          return getHeaders(server.port, '/file')
              .then((headers) {
                expect(headers.value(HttpHeaders.LAST_MODIFIED), isNotNull);
                return HttpDate.parse(
                    headers.value(HttpHeaders.LAST_MODIFIED));
              })
              .then((lastModified) {
                return getStatusCode(
                    server.port, '/file', ifModifiedSince: lastModified);
              })
              .whenComplete(() {
                server.close();
                dir.deleteSync(recursive: true);
              });
        }), completion(equals(HttpStatus.NOT_MODIFIED)));
      });

      test('file-changes', () {
        expect(HttpServer.bind('localhost', 0).then((server) {
          var dir = new Directory('').createTempSync();
          var file = new File('${dir.path}/file')..createSync();
          var virDir = new VirtualDirectory(dir.path);

          virDir.serve(server);

          return getHeaders(server.port, '/file')
              .then((headers) {
                expect(headers.value(HttpHeaders.LAST_MODIFIED), isNotNull);
                return HttpDate.parse(
                    headers.value(HttpHeaders.LAST_MODIFIED));
              })
              .then((lastModified) {
                // Fake file changed by moving date back in time.
                lastModified = lastModified.subtract(
                  const Duration(seconds: 10));
                return getStatusCode(
                    server.port, '/file', ifModifiedSince: lastModified);
              })
              .whenComplete(() {
                server.close();
                dir.deleteSync(recursive: true);
              });
        }), completion(equals(HttpStatus.OK)));
      });
    });
  });

  group('content-type', () {
    group('mime-type', () {
      test('from-path', () {
        expect(HttpServer.bind('localhost', 0).then((server) {
          var dir = new Directory('').createTempSync();
          var file = new File('${dir.path}/file.jpg')..createSync();
          var virDir = new VirtualDirectory(dir.path);

          virDir.serve(server);

          return getHeaders(server.port, '/file.jpg')
              .then((headers) => headers.contentType.toString())
              .whenComplete(() {
                server.close();
                dir.deleteSync(recursive: true);
              });
        }), completion(equals('image/jpeg')));
      });

      test('from-magic-number', () {
        expect(HttpServer.bind('localhost', 0).then((server) {
          var dir = new Directory('').createTempSync();
          var file = new File('${dir.path}/file.jpg')..createSync();
          file.writeAsBytesSync(
              [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
          var virDir = new VirtualDirectory(dir.path);

          virDir.serve(server);

          return getHeaders(server.port, '/file.jpg')
              .then((headers) => headers.contentType.toString())
              .whenComplete(() {
                server.close();
                dir.deleteSync(recursive: true);
              });
        }), completion(equals('image/png')));
      });
    });
  });

  group('error-page', () {
    test('default', () {
      expect(HttpServer.bind('localhost', 0).then((server) {
        var dir = new Directory('').createTempSync();
        var virDir = new VirtualDirectory(dir.path);
        dir.deleteSync();

        virDir.serve(server);

        return getAsString(server.port, '/')
            .whenComplete(() {
              server.close();
            });
      }), completion(matches(new RegExp('404.*Not Found'))));
    });

    test('custom', () {
      expect(HttpServer.bind('localhost', 0).then((server) {
        var dir = new Directory('').createTempSync();
        var virDir = new VirtualDirectory(dir.path);
        dir.deleteSync();

        virDir.setErrorPageHandler((request) {
          request.response.write('my-page ');
          request.response.write(request.response.statusCode);
          request.response.close();
        });
        virDir.serve(server);

        return getAsString(server.port, '/')
            .whenComplete(() {
              server.close();
            });
      }), completion(equals('my-page 404')));
    });
  });
}

