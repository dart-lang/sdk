// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import "package:http_server/http_server.dart";
import 'package:path/path.dart' as pathos;
import "package:unittest/unittest.dart";

import 'utils.dart';

void _testEncoding(name, expected, [bool create = true]) {
  testVirtualDir('encode-$name', (dir) {
      if (create) new File('${dir.path}/$name').createSync();
      var virDir = new VirtualDirectory(dir.path);
      virDir.allowDirectoryListing = true;

      return getStatusCodeForVirtDir(virDir, '/$name')
        .then((result) {
          expect(result, expected);
        });
  });
}

void main() {
  group('serve-root', () {
    testVirtualDir('dir-exists', (dir) {

      var virDir = new VirtualDirectory(dir.path);

      return getStatusCodeForVirtDir(virDir, '/')
        .then((result) {
          expect(result, HttpStatus.NOT_FOUND);
        });
    });

    testVirtualDir('dir-not-exists', (dir) {
      var virDir = new VirtualDirectory(pathos.join(dir.path + 'foo'));

      return getStatusCodeForVirtDir(virDir, '/')
          .then((result) {
            expect(result, HttpStatus.NOT_FOUND);
          });
    });
  });

  group('serve-file', () {
    group('top-level', () {
      testVirtualDir('file-exists', (dir) {
        var file = new File('${dir.path}/file')..createSync();
        var virDir = new VirtualDirectory(dir.path);
        return getStatusCodeForVirtDir(virDir, '/file')
            .then((result) {
              expect(result, HttpStatus.OK);
            });
      });

      testVirtualDir('file-not-exists', (dir) {
        var virDir = new VirtualDirectory(dir.path);

        return getStatusCodeForVirtDir(virDir, '/file')
            .then((result) {
              expect(result, HttpStatus.NOT_FOUND);
            });
      });
    });

    group('in-dir', () {
      testVirtualDir('file-exists', (dir) {
              var dir2 = new Directory('${dir.path}/dir')..createSync();
              var file = new File('${dir2.path}/file')..createSync();
              var virDir = new VirtualDirectory(dir.path);
              return getStatusCodeForVirtDir(virDir, '/dir/file')
            .then((result) {
              expect(result, HttpStatus.OK);
            });
      });

      testVirtualDir('file-not-exists', (dir) {
              var dir2 = new Directory('${dir.path}/dir')..createSync();
              var file = new File('${dir.path}/file')..createSync();
              var virDir = new VirtualDirectory(dir.path);

              return getStatusCodeForVirtDir(virDir, '/dir/file')
                .then((result) {
                  expect(result, HttpStatus.NOT_FOUND);
                });
      });
    });
  });

  group('serve-dir', () {
    group('top-level', () {
      testVirtualDir('simple', (dir) {
        var virDir = new VirtualDirectory(dir.path);
        virDir.allowDirectoryListing = true;

        return getAsString(virDir, '/')
          .then((result) {
            expect(result, contains('Index of &#x2F'));
          });
      });

      testVirtualDir('files', (dir) {
        var virDir = new VirtualDirectory(dir.path);
        for (int i = 0; i < 10; i++) {
          new File('${dir.path}/$i').createSync();
        }
        virDir.allowDirectoryListing = true;

        return getAsString(virDir, '/')
          .then((result) {
            expect(result, contains('Index of &#x2F'));
          });
      });

      testVirtualDir('dirs', (dir) {
        var virDir = new VirtualDirectory(dir.path);
        for (int i = 0; i < 10; i++) {
          new Directory('${dir.path}/$i').createSync();
        }
        virDir.allowDirectoryListing = true;

        return getAsString(virDir, '/')
          .then((result) {
            expect(result, contains('Index of &#x2F'));
          });
      });

      testVirtualDir('encoded-dir', (dir) {
        var virDir = new VirtualDirectory(dir.path);
        new Directory('${dir.path}/alert(\'hacked!\');').createSync();
        virDir.allowDirectoryListing = true;

        return getAsString(virDir, '/alert(\'hacked!\');')
          .then((result) {
            expect(result, contains('&#x2F;alert(&#x27;hacked!&#x27;);&#x2F;'));
          });
      });

      testVirtualDir('non-ascii-dir', (dir) {
        var virDir = new VirtualDirectory(dir.path);
        new Directory('${dir.path}/æøå').createSync();
        virDir.allowDirectoryListing = true;

        return getAsString(virDir, '/')
          .then((result) {
            expect(result, contains('æøå'));
          });
      });

      testVirtualDir('content-type', (dir) {
        var virDir = new VirtualDirectory(dir.path);
        virDir.allowDirectoryListing = true;

        return getHeaders(virDir, '/')
          .then((headers) {
            var contentType = headers.contentType.toString();
            expect(contentType, 'text/html; charset=utf-8');
          });
      });

      if (!Platform.isWindows) {
        testVirtualDir('recursive-link', (dir) {
          var link = new Link('${dir.path}/recursive')..createSync('.');
          var virDir = new VirtualDirectory(dir.path);
          virDir.allowDirectoryListing = true;

          return Future.wait([
              getAsString(virDir, '/').then(
                  (s) => s.contains('recursive&#x2F;')),
              getAsString(virDir, '/').then(
                  (s) => !s.contains('../')),
              getAsString(virDir, '/').then(
                  (s) => s.contains('Index of &#x2F;')),
              getAsString(virDir, '/recursive').then(
                  (s) => s.contains('recursive&#x2F;')),
              getAsString(virDir, '/recursive').then(
                  (s) => s.contains('..&#x2F;')),
              getAsString(virDir, '/recursive').then(
                  (s) => s.contains('Index of &#x2F;recursive'))])
            .then((result) {
              expect(result, equals([true, true, true, true, true, true]));
            });
        });

        testVirtualDir('encoded-path', (dir) {
          var virDir = new VirtualDirectory(dir.path);
          new Directory('${dir.path}/javascript:alert(document);"')
              .createSync();
          virDir.allowDirectoryListing = true;

          return getAsString(virDir, '/')
            .then((result) {
              expect(result, contains('%2Fjavascript%3Aalert(document)%3B%22'));
            });
        });

        testVirtualDir('encoded-special', (dir) {
          var virDir = new VirtualDirectory(dir.path);
          new Directory('${dir.path}/<>&"').createSync();
          virDir.allowDirectoryListing = true;

          return getAsString(virDir, '/')
            .then((result) {
              expect(result, contains('&lt;&gt;&amp;&quot;&#x2F;'));
              expect(result, contains('href="%2F%3C%3E%26%22"'));
            });
        });
      }
    });

    group('custom', () {
      testVirtualDir('simple', (dir) {
        var virDir = new VirtualDirectory(dir.path);
        virDir.allowDirectoryListing = true;
        virDir.directoryHandler = (dir2, request) {
          expect(dir2, isNotNull);
          expect(FileSystemEntity.identicalSync(dir.path, dir2.path), isTrue);
          request.response.write('My handler ${request.uri.path}');
          request.response.close();
        };

        return getAsString(virDir, '/')
          .then((result) {
            expect(result, 'My handler /');
          });
      });

      testVirtualDir('index-1', (dir) {
        new File('${dir.path}/index.html').writeAsStringSync('index file');
        var virDir = new VirtualDirectory(dir.path);
        virDir.allowDirectoryListing = true;
        virDir.directoryHandler = (dir2, request) {
          // Redirect directory-requests to index.html files.
          var indexUri = new Uri.file(dir2.path).resolve('index.html');
          return virDir.serveFile(new File(indexUri.toFilePath()), request);
        };

        return getAsString(virDir, '/')
          .then((result) {
            expect(result, 'index file');
          });
      });

      testVirtualDir('index-2', (dir) {
        new Directory('${dir.path}/dir').createSync();
        var virDir = new VirtualDirectory(dir.path);
        virDir.allowDirectoryListing = true;

        virDir.directoryHandler = (dir2, request) {
          fail('not expected');
        };

        return getStatusCodeForVirtDir(virDir, '/dir', followRedirects: false)
          .then((result) {
            expect(result, 301);
          });
      });

      testVirtualDir('index-3', (dir) {
        new File('${dir.path}/dir/index.html')
            ..createSync(recursive: true)
            ..writeAsStringSync('index file');
        var virDir = new VirtualDirectory(dir.path);
        virDir.allowDirectoryListing = true;
        virDir.directoryHandler = (dir2, request) {
          // Redirect directory-requests to index.html files.
          var indexUri = new Uri.file(dir2.path).resolve('index.html');
          return virDir.serveFile(new File(indexUri.toFilePath()), request);
        };
        return getAsString(virDir, '/dir')
          .then((result) {
            expect(result, 'index file');
          });
      });

      testVirtualDir('index-4', (dir) {
        new File('${dir.path}/dir/index.html')
            ..createSync(recursive: true)
            ..writeAsStringSync('index file');
        var virDir = new VirtualDirectory(dir.path);
        virDir.allowDirectoryListing = true;
        virDir.directoryHandler = (dir2, request) {
          // Redirect directory-requests to index.html files.
          var indexUri = new Uri.file(dir2.path).resolve('index.html');
          virDir.serveFile(new File(indexUri.toFilePath()), request);
        };
        return getAsString(virDir, '/dir/')
          .then((result) {
            expect(result, 'index file');
          });
      });
    });
  });

  group('links', () {
    if (!Platform.isWindows) {
      group('follow-links', () {
        testVirtualDir('dir-link', (dir) {
          var dir2 = new Directory('${dir.path}/dir2')..createSync();
          var link = new Link('${dir.path}/dir3')..createSync('dir2');
          var file = new File('${dir2.path}/file')..createSync();
          var virDir = new VirtualDirectory(dir.path);
          virDir.followLinks = true;

          return getStatusCodeForVirtDir(virDir, '/dir3/file')
            .then((result) {
              expect(result, HttpStatus.OK);
            });
        });

        testVirtualDir('root-link', (dir) {
          var link = new Link('${dir.path}/dir3')..createSync('.');
          var file = new File('${dir.path}/file')..createSync();
          var virDir = new VirtualDirectory(dir.path);
          virDir.followLinks = true;

          return getStatusCodeForVirtDir(virDir, '/dir3/file')
            .then((result) {
              expect(result, HttpStatus.OK);
            });
        });

        group('bad-links', () {
          testVirtualDir('absolute-link', (dir) {
              var file = new File('${dir.path}/file')..createSync();
              var link = new Link('${dir.path}/file2')
                  ..createSync('${dir.path}/file');
              var virDir = new VirtualDirectory(dir.path);
              virDir.followLinks = true;

              return getStatusCodeForVirtDir(virDir, '/file2')
                .then((result) {
                  expect(result, HttpStatus.NOT_FOUND);
                });
          });

          testVirtualDir('relative-parent-link', (dir) {
              var dir2 = new Directory('${dir.path}/dir')..createSync();
              var file = new File('${dir.path}/file')..createSync();
              var link = new Link('${dir2.path}/file')
                  ..createSync('../file');
              var virDir = new VirtualDirectory(dir2.path);
              virDir.followLinks = true;

              return getStatusCodeForVirtDir(virDir, '/dir3/file')
                  .then((result) {
                    expect(result, HttpStatus.NOT_FOUND);
                  });
          });
        });
      });

      group('not-follow-links', () {
        testVirtualDir('dir-link', (dir) {
            var dir2 = new Directory('${dir.path}/dir2')..createSync();
            var link = new Link('${dir.path}/dir3')..createSync('dir2');
            var file = new File('${dir2.path}/file')..createSync();
            var virDir = new VirtualDirectory(dir.path);
            virDir.followLinks = false;

            return getStatusCodeForVirtDir(virDir, '/dir3/file')
                .then((result) {
                  expect(result, HttpStatus.NOT_FOUND);
                });
        });
      });

      group('follow-links', () {
        group('no-root-jail', () {
          testVirtualDir('absolute-link', (dir) {
              var file = new File('${dir.path}/file')..createSync();
              var link = new Link('${dir.path}/file2')
                  ..createSync('${dir.path}/file');
              var virDir = new VirtualDirectory(dir.path);
              virDir.followLinks = true;
              virDir.jailRoot = false;

              return getStatusCodeForVirtDir(virDir, '/file2')
                  .then((result) {
                    expect(result, HttpStatus.OK);
                  });
          });

          testVirtualDir('relative-parent-link', (dir) {
              var dir2 = new Directory('${dir.path}/dir')..createSync();
              var file = new File('${dir.path}/file')..createSync();
              var link = new Link('${dir2.path}/file')
                  ..createSync('../file');
              var virDir = new VirtualDirectory(dir2.path);
              virDir.followLinks = true;
              virDir.jailRoot = false;

              return getStatusCodeForVirtDir(virDir, '/file')
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
      testVirtualDir('file-exists', (dir) {
          var file = new File('${dir.path}/file')..createSync();
          var virDir = new VirtualDirectory(dir.path);

          return getHeaders(virDir, '/file')
              .then((headers) {
                expect(headers.value(HttpHeaders.LAST_MODIFIED), isNotNull);
                var lastModified = HttpDate.parse(
                    headers.value(HttpHeaders.LAST_MODIFIED));

                return getStatusCodeForVirtDir(
                    virDir, '/file', ifModifiedSince: lastModified);
              })
              .then((result) {
                expect(result, HttpStatus.NOT_MODIFIED);
              });
      });

      testVirtualDir('file-changes', (dir) {
          var file = new File('${dir.path}/file')..createSync();
          var virDir = new VirtualDirectory(dir.path);

          return getHeaders(virDir, '/file')
              .then((headers) {
                expect(headers.value(HttpHeaders.LAST_MODIFIED), isNotNull);
                var lastModified = HttpDate.parse(
                    headers.value(HttpHeaders.LAST_MODIFIED));

                // Fake file changed by moving date back in time.
                lastModified = lastModified.subtract(
                  const Duration(seconds: 10));

                return getStatusCodeForVirtDir(virDir, '/file',
                    ifModifiedSince: lastModified);
              })
              .then((result) {
                expect(result, HttpStatus.OK);
              });
      });
    });
  });

  group('content-type', () {
    group('mime-type', () {
      testVirtualDir('from-path', (dir) {
          var file = new File('${dir.path}/file.jpg')..createSync();
          var virDir = new VirtualDirectory(dir.path);

          return getHeaders(virDir, '/file.jpg')
              .then((headers) {
                var contentType = headers.contentType.toString();
                expect(contentType, 'image/jpeg');
              });
      });

      testVirtualDir('from-magic-number', (dir) {
          var file = new File('${dir.path}/file.jpg')..createSync();
          file.writeAsBytesSync(
              [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
          var virDir = new VirtualDirectory(dir.path);

          return getHeaders(virDir, '/file.jpg')
              .then((headers) {
                var contentType = headers.contentType.toString();
                expect(contentType, 'image/png');
              });
      });
    });
  });

  group('error-page', () {
    testVirtualDir('default', (dir) {
        var virDir = new VirtualDirectory(pathos.join(dir.path, 'foo'));

        return getAsString(virDir, '/')
          .then((result) {
            expect(result, matches(new RegExp('404.*Not Found')));
          });
    });

    testVirtualDir('custom', (dir) {
        var virDir = new VirtualDirectory(pathos.join(dir.path, 'foo'));

        virDir.errorPageHandler = (request) {
          request.response.write('my-page ');
          request.response.write(request.response.statusCode);
          request.response.close();
        };

        return getAsString(virDir, '/')
          .then((result) {
            expect(result, 'my-page 404');
          });
    });
  });

  group('escape-root', () {
    testVirtualDir('escape1', (dir) {
        var virDir = new VirtualDirectory(dir.path);
        virDir.allowDirectoryListing = true;

        return getStatusCodeForVirtDir(virDir, '/../')
          .then((result) {
            expect(result, HttpStatus.NOT_FOUND);
          });
    });

    testVirtualDir('escape2', (dir) {
        new Directory('${dir.path}/dir').createSync();
        var virDir = new VirtualDirectory(dir.path);
        virDir.allowDirectoryListing = true;

        return getStatusCodeForVirtDir(virDir, '/dir/../../')
          .then((result) {
            expect(result, HttpStatus.NOT_FOUND);
          });
    });
  });

  group('url-decode', () {
    testVirtualDir('with-space', (dir) {
        var file = new File('${dir.path}/my file')..createSync();
        var virDir = new VirtualDirectory(dir.path);

        return getStatusCodeForVirtDir(virDir, '/my file')
          .then((result) {
            expect(result, HttpStatus.OK);
          });
    });

    testVirtualDir('encoded-space', (dir) {
        var file = new File('${dir.path}/my file')..createSync();
        var virDir = new VirtualDirectory(dir.path);

        return getStatusCodeForVirtDir(virDir, '/my%20file')
          .then((result) {
            expect(result, HttpStatus.NOT_FOUND);
          });
    });

    testVirtualDir('encoded-path-separator', (dir) {
        new Directory('${dir.path}/a').createSync();
        new Directory('${dir.path}/a/b').createSync();
        new Directory('${dir.path}/a/b/c').createSync();
        var virDir = new VirtualDirectory(dir.path);
        virDir.allowDirectoryListing = true;

        return getStatusCodeForVirtDir(virDir, '/a%2fb/c', rawPath: true)
          .then((result) {
            expect(result, HttpStatus.NOT_FOUND);
          });
    });

    testVirtualDir('encoded-null', (dir) {
        var virDir = new VirtualDirectory(dir.path);
        virDir.allowDirectoryListing = true;

        return getStatusCodeForVirtDir(virDir, '/%00', rawPath: true)
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
    testVirtualDir('from-dir-handler', (dir) {
        new File('${dir.path}/file')..writeAsStringSync('file contents');
        var virDir = new VirtualDirectory(dir.path);
        virDir.allowDirectoryListing = true;
        virDir.directoryHandler = (d, request) {
          expect(FileSystemEntity.identicalSync(dir.path, d.path), isTrue);
          return virDir.serveFile(new File('${d.path}/file'), request);
        };

        return getAsString(virDir, '/')
          .then((result) {
            expect(result, 'file contents');
          });
    });
  });
}
