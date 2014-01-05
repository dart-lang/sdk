// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import "package:http_server/http_server.dart";
import 'package:path/path.dart' as pathos;
import "package:unittest/unittest.dart";

import 'utils.dart';

void _testVirDir(String name, dynamic func(HttpServer server, Directory dir)) {
  test(name, () {
    HttpServer server;
    Directory dir;
    
    return HttpServer.bind('localhost', 0)
        .then((value) {
          server = value;
          dir = Directory.systemTemp.createTempSync('http_server_virtual_');
          return func(server, dir);          
        })
        .whenComplete(() {
          return Future.wait([server.close(), dir.delete(recursive: true)]);
        });
  });
}

void _testEncoding(name, expected, [bool create = true]) {
  _testVirDir('encode-$name', (server, dir) {
      if (create) new File('${dir.path}/$name').createSync();
      var virDir = new VirtualDirectory(dir.path);
      virDir.allowDirectoryListing = true;

      virDir.serve(server);

      return getStatusCode(server.port, '/$name')
        .then((result) {
          expect(result, expected);
        });
  });
}

void main() {
  group('serve-root', () {
    _testVirDir('dir-exists', (server, dir) {

      var virDir = new VirtualDirectory(dir.path);
      virDir.serve(server);

      return getStatusCode(server.port, '/')
        .then((result) {
          expect(result, HttpStatus.NOT_FOUND);
        });
    });

    _testVirDir('dir-not-exists', (server, dir) {
      var virDir = new VirtualDirectory(pathos.join(dir.path + 'foo'));

      virDir.serve(server);

      return getStatusCode(server.port, '/')
          .then((result) {
            expect(result, HttpStatus.NOT_FOUND);
          });
    });
  });

  group('serve-file', () {
    group('top-level', () {
      _testVirDir('file-exists', (server, dir) {
        var file = new File('${dir.path}/file')..createSync();
        var virDir = new VirtualDirectory(dir.path);
  
        virDir.serve(server);
  
        return getStatusCode(server.port, '/file')
            .then((result) {
              expect(result, HttpStatus.OK);
            });
      });

      _testVirDir('file-not-exists', (server, dir) {
        var virDir = new VirtualDirectory(dir.path);

        virDir.serve(server);

        return getStatusCode(server.port, '/file')
          .then((result) {
            expect(result, HttpStatus.NOT_FOUND);
          });
      });
    });

    group('in-dir', () {
      _testVirDir('file-exists', (server, dir) {
              var dir2 = new Directory('${dir.path}/dir')..createSync();
              var file = new File('${dir2.path}/file')..createSync();
              var virDir = new VirtualDirectory(dir.path);
    
              virDir.serve(server);
    
              return getStatusCode(server.port, '/dir/file')
            .then((result) {
              expect(result, HttpStatus.OK);
            });
      });

      _testVirDir('file-not-exists', (server, dir) {
              var dir2 = new Directory('${dir.path}/dir')..createSync();
              var file = new File('${dir.path}/file')..createSync();
              var virDir = new VirtualDirectory(dir.path);
    
              virDir.serve(server);
    
              return getStatusCode(server.port, '/dir/file')
                .then((result) {
                  expect(result, HttpStatus.NOT_FOUND);
                });
      });
    });
  });

  group('serve-dir', () {
    group('top-level', () {
      _testVirDir('simple', (server, dir) {
        var virDir = new VirtualDirectory(dir.path);
        virDir.allowDirectoryListing = true;
  
        virDir.serve(server);
  
        return getAsString(server.port, '/')
          .then((result) {
            expect(result, contains('Index of /'));
          });
      });

      _testVirDir('files', (server, dir) {
        var virDir = new VirtualDirectory(dir.path);
        for (int i = 0; i < 10; i++) {
          new File('${dir.path}/$i').createSync();
        }
        virDir.allowDirectoryListing = true;
  
        virDir.serve(server);
  
        return getAsString(server.port, '/')
          .then((result) {
            expect(result, contains('Index of /'));
          });
      });

      _testVirDir('dirs', (server, dir) {
        var virDir = new VirtualDirectory(dir.path);
        for (int i = 0; i < 10; i++) {
          new Directory('${dir.path}/$i').createSync();
        }
        virDir.allowDirectoryListing = true;

        virDir.serve(server);

        return getAsString(server.port, '/')
          .then((result) {
            expect(result, contains('Index of /'));
          });
      });

      if (!Platform.isWindows) {
        _testVirDir('recursive-link', (server, dir) {
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
            .then((result) {
              expect(result, equals([true, true, true, true, true, true]));
            });
        });
      }
    });

    group('custom', () {
      _testVirDir('simple', (server, dir) {
        var virDir = new VirtualDirectory(dir.path);
        virDir.allowDirectoryListing = true;
        virDir.directoryHandler = (dir2, request) {
          expect(dir2, isNotNull);
          expect(FileSystemEntity.identicalSync(dir.path, dir2.path), isTrue);
          request.response.write('My handler ${request.uri.path}');
          request.response.close();
        };
  
        virDir.serve(server);
  
        return getAsString(server.port, '/')
          .then((result) {
            expect(result, 'My handler /');
          });
      });
    });
  });

  group('links', () {
    if (!Platform.isWindows) {
      group('follow-links', () {
        _testVirDir('dir-link', (server, dir) {
          var dir2 = new Directory('${dir.path}/dir2')..createSync();
          var link = new Link('${dir.path}/dir3')..createSync('dir2');
          var file = new File('${dir2.path}/file')..createSync();
          var virDir = new VirtualDirectory(dir.path);
          virDir.followLinks = true;
  
          virDir.serve(server);
  
          return getStatusCode(server.port, '/dir3/file')
            .then((result) {
              expect(result, HttpStatus.OK);
            });
        });

        _testVirDir('root-link', (server, dir) {
          var link = new Link('${dir.path}/dir3')..createSync('.');
          var file = new File('${dir.path}/file')..createSync();
          var virDir = new VirtualDirectory(dir.path);
          virDir.followLinks = true;
  
          virDir.serve(server);
  
          return getStatusCode(server.port, '/dir3/file')
            .then((result) {
              expect(result, HttpStatus.OK);
            });
        });

        group('bad-links', () {
          _testVirDir('absolute-link', (server, dir) {
              var file = new File('${dir.path}/file')..createSync();
              var link = new Link('${dir.path}/file2')
                  ..createSync('${dir.path}/file');
              var virDir = new VirtualDirectory(dir.path);
              virDir.followLinks = true;
  
              virDir.serve(server);
  
              return new HttpClient().get('localhost',
                                          server.port,
                                          '/file2')
                  .then((request) => request.close())
                  .then((response) => response.drain().then(
                      (_) => response.statusCode))
                .then((result) {
                  expect(result, HttpStatus.NOT_FOUND);
                });
          });

          _testVirDir('relative-parent-link', (server, dir) {
              var dir2 = new Directory('${dir.path}/dir')..createSync();
              var file = new File('${dir.path}/file')..createSync();
              var link = new Link('${dir2.path}/file')
                  ..createSync('../file');
              var virDir = new VirtualDirectory(dir2.path);
              virDir.followLinks = true;

              virDir.serve(server);

              return new HttpClient().get('localhost',
                                          server.port,
                                          '/dir3/file')
                  .then((request) => request.close())
                  .then((response) => response.drain().then(
                      (_) => response.statusCode))
                  .then((result) {
                    expect(result, HttpStatus.NOT_FOUND);
                  });
          });
        });
      });

      group('not-follow-links', () {
        _testVirDir('dir-link', (server, dir) {
          return HttpServer.bind('localhost', 0).then((server) {
            var dir =
                Directory.systemTemp.createTempSync('http_server_virtual_');
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
          })
          .then((result) {
            expect(result, HttpStatus.NOT_FOUND);
          });
        });
      });

      group('follow-links', () {
        group('no-root-jail', () {
          _testVirDir('absolute-link', (server, dir) {
              var file = new File('${dir.path}/file')..createSync();
              var link = new Link('${dir.path}/file2')
                  ..createSync('${dir.path}/file');
              var virDir = new VirtualDirectory(dir.path);
              virDir.followLinks = true;
              virDir.jailRoot = false;

              virDir.serve(server);

              return new HttpClient().get('localhost',
                                          server.port,
                                          '/file2')
                  .then((request) => request.close())
                  .then((response) => response.drain().then(
                      (_) => response.statusCode))
                  .then((result) {
                    expect(result, HttpStatus.OK);
                  });
          });

          _testVirDir('relative-parent-link', (server, dir) {
              var dir2 = new Directory('${dir.path}/dir')..createSync();
              var file = new File('${dir.path}/file')..createSync();
              var link = new Link('${dir2.path}/file')
                  ..createSync('../file');
              var virDir = new VirtualDirectory(dir2.path);
              virDir.followLinks = true;
              virDir.jailRoot = false;

              virDir.serve(server);

              return new HttpClient().get('localhost',
                                          server.port,
                                          '/file')
                  .then((request) => request.close())
                  .then((response) => response.drain().then(
                      (_) => response.statusCode))
                  .then((result) {
                    expect(result, HttpStatus.OK);
                  });
          });
        });
      });
    }
  });

  group('last-modified', () {
    group('file', () {
      _testVirDir('file-exists', (server, dir) {
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
              .then((result) {
                expect(result, HttpStatus.NOT_MODIFIED);
              });
      });

      _testVirDir('file-changes', (server, dir) {
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
              .then((result) {
                expect(result, HttpStatus.OK);
              });
      });
    });
  });

  group('content-type', () {
    group('mime-type', () {
      _testVirDir('from-path', (server, dir) {
          var file = new File('${dir.path}/file.jpg')..createSync();
          var virDir = new VirtualDirectory(dir.path);

          virDir.serve(server);

          return getHeaders(server.port, '/file.jpg')
              .then((headers) => headers.contentType.toString())
              .then((result) {
                expect(result, 'image/jpeg');
              });
      });

      _testVirDir('from-magic-number', (server, dir) {
          var file = new File('${dir.path}/file.jpg')..createSync();
          file.writeAsBytesSync(
              [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
          var virDir = new VirtualDirectory(dir.path);

          virDir.serve(server);

          return getHeaders(server.port, '/file.jpg')
              .then((headers) => headers.contentType.toString())
              .then((result) {
                expect(result, 'image/png');
              });
      });
    });
  });

  group('error-page', () {
    _testVirDir('default', (server, dir) {
        var virDir = new VirtualDirectory(pathos.join(dir.path, 'foo'));

        virDir.serve(server);

        return getAsString(server.port, '/')
          .then((result) {
            expect(result, matches(new RegExp('404.*Not Found')));
          });
    });

    _testVirDir('custom', (server, dir) {
        var virDir = new VirtualDirectory(pathos.join(dir.path, 'foo'));

        virDir.errorPageHandler = (request) {
          request.response.write('my-page ');
          request.response.write(request.response.statusCode);
          request.response.close();
        };
        virDir.serve(server);

        return getAsString(server.port, '/')
          .then((result) {
            expect(result, 'my-page 404');
          });
    });
  });

  group('escape-root', () {
    _testVirDir('escape1', (server, dir) {
        var virDir = new VirtualDirectory(dir.path);
        virDir.allowDirectoryListing = true;

        virDir.serve(server);

        return getStatusCode(server.port, '/../')
          .then((result) {
            expect(result, HttpStatus.NOT_FOUND);
          });
    });

    _testVirDir('escape2', (server, dir) {
        new Directory('${dir.path}/dir').createSync();
        var virDir = new VirtualDirectory(dir.path);
        virDir.allowDirectoryListing = true;

        virDir.serve(server);

        return getStatusCode(server.port, '/dir/../../')
          .then((result) {
            expect(result, HttpStatus.NOT_FOUND);
          });
    });
  });

  group('url-decode', () {
    _testVirDir('with-space', (server, dir) {
        var file = new File('${dir.path}/my file')..createSync();
        var virDir = new VirtualDirectory(dir.path);

        virDir.serve(server);

        return getStatusCode(server.port, '/my file')
          .then((result) {
            expect(result, HttpStatus.OK);
          });
    });

    _testVirDir('encoded-space', (server, dir) {
        var file = new File('${dir.path}/my file')..createSync();
        var virDir = new VirtualDirectory(dir.path);

        virDir.serve(server);

        return getStatusCode(server.port, '/my%20file')
          .then((result) {
            expect(result, HttpStatus.NOT_FOUND);
          });
    });

    _testVirDir('encoded-path-separator', (server, dir) {
        new Directory('${dir.path}/a').createSync();
        new Directory('${dir.path}/a/b').createSync();
        new Directory('${dir.path}/a/b/c').createSync();
        var virDir = new VirtualDirectory(dir.path);
        virDir.allowDirectoryListing = true;

        virDir.serve(server);

        return getStatusCode(server.port, '/a%2fb/c', rawPath: true)
          .then((result) {
            expect(result, HttpStatus.NOT_FOUND);
          });
    });

    _testVirDir('encoded-null', (server, dir) {
        var virDir = new VirtualDirectory(dir.path);
        virDir.allowDirectoryListing = true;

        virDir.serve(server);

        return getStatusCode(server.port, '/%00', rawPath: true)
          .then((result) {
            expect(result, HttpStatus.NOT_FOUND);
          });
    });

    _testEncoding('..', HttpStatus.NOT_FOUND, false);
    _testEncoding('%2e%2e', HttpStatus.OK);
    _testEncoding('%252e%252e', HttpStatus.OK);
    _testEncoding('/', HttpStatus.OK, false);
    _testEncoding('%2f', HttpStatus.NOT_FOUND, false);
    _testEncoding('%2f', HttpStatus.OK, true);
  });

  group('serve-file', () {
    _testVirDir('from-dir-handler', (server, dir) {
        new File('${dir.path}/file')..writeAsStringSync('file contents');
        var virDir = new VirtualDirectory(dir.path);
        virDir.allowDirectoryListing = true;
        virDir.directoryHandler = (d, request) {
          expect(FileSystemEntity.identicalSync(dir.path, d.path), isTrue);
          virDir.serveFile(new File('${d.path}/file'), request);
        };

        virDir.serve(server);

        return getAsString(server.port, '/')
          .then((result) {
            expect(result, 'file contents');
          });
    });
  });
}
