// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of http_server;


// Used for signal a directory redirecting, where a tailing slash is missing.
class _DirectoryRedirect {
  const _DirectoryRedirect();
}

typedef dynamic _DirCallback(Directory dir, HttpRequest request);
typedef dynamic _ErrorCallback(HttpRequest request);

/**
 * A [VirtualDirectory] can serve files and directory-listing from a root path,
 * to [HttpRequest]s.
 *
 * The [VirtualDirectory] providing secure handling of request uris and
 * file-system links, correct mime-types and custom error pages.
 */
class VirtualDirectory {
  final String root;

  /**
   * Set or get if the [VirtualDirectory] should list the content of
   * directories.
   */
  bool allowDirectoryListing = false;

  /**
   * Set or get if the [VirtualDirectory] should follow links, that point
   * to other resources within the [root] directory.
   */
  bool followLinks = true;

  /**
   * Set or get if the [VirtualDirectory] should jail the root. When the root is
   * not jailed, links can be followed to outside the [root] directory.
   */
  bool jailRoot = true;

  final RegExp _invalidPathRegExp = new RegExp("[\\\/\x00]");

  _ErrorCallback _errorCallback;
  _DirCallback _dirCallback;

  /*
   * Create a new [VirtualDirectory] for serving static file content of
   * the path [root].
   *
   * The [root] is not required to exist. If the [root] doesn't exist at time of
   * a request, a 404 is generated.
   */
  VirtualDirectory(this.root);

  /**
   * Serve a [Stream] of [HttpRequest]s, in this [VirtualDirectory].
   */
  StreamSubscription<HttpRequest> serve(Stream<HttpRequest> requests) =>
      requests.listen(serveRequest);

  /**
   * Serve a single [HttpRequest], in this [VirtualDirectory].
   */
  Future serveRequest(HttpRequest request) {
    return _locateResource('.', request.uri.pathSegments.iterator..moveNext())
        .then((entity) {
          if (entity is File) {
            serveFile(entity, request);
          } else if (entity is Directory) {
            if (allowDirectoryListing) {
              _serveDirectory(entity, request);
            } else {
              _serveErrorPage(HttpStatus.NOT_FOUND, request);
            }
          } else if (entity is _DirectoryRedirect) {
            // TODO(ajohnsen): Use HttpRequest.requestedUri once 1.2 is out.
            request.response.redirect(Uri.parse('${request.uri}/'),
                                      status: HttpStatus.MOVED_PERMANENTLY);
          } else {
            assert(entity == null);
            _serveErrorPage(HttpStatus.NOT_FOUND, request);
          }
          return request.response.done;
        });
  }

  /**
   * Set the [callback] to override the default directory listing. The
   * [callback] will be called with the [Directory] to be listed and the
   * [HttpRequest].
   */
  void set directoryHandler(void callback(Directory dir, HttpRequest request)) {
    _dirCallback = callback;
  }

  /**
   * Set the [callback] to override the error page handler. When [callback] is
   * invoked, the `statusCode` property of the response is set.
   */
  void set errorPageHandler(void callback(HttpRequest request)) {
    _errorCallback = callback;
  }

  Future _locateResource(String path, Iterator<String> segments) {
    // Don't allow navigating up paths.
    if (segments.current == "..") return new Future.value(null);
    path = normalize(path);
    // If we jail to root, the relative path can never go up.
    if (jailRoot && split(path).first == "..") return new Future.value(null);
    String fullPath() => join(root, path);
    return FileSystemEntity.type(fullPath(), followLinks: false)
        .then((type) {
          switch (type) {
            case FileSystemEntityType.FILE:
              if (segments.current == null) {
                return new File(fullPath());
              }
              break;

            case FileSystemEntityType.DIRECTORY:
              String dirFullPath() => '${fullPath()}$separator';
              var current = segments.current;
              if (current == null) {
                if (path == '.') return new Directory(dirFullPath());
                return const _DirectoryRedirect();
              }
              bool hasNext = segments.moveNext();
              if (!hasNext && current == "") {
                return new Directory(dirFullPath());
              } else {
                if (_invalidPathRegExp.hasMatch(current)) break;
                return _locateResource(join(path, current), segments);
              }
              break;

            case FileSystemEntityType.LINK:
              if (followLinks) {
                return new Link(fullPath()).target()
                    .then((target) {
                      String targetPath = normalize(target);
                      if (isAbsolute(targetPath)) {
                        // If we jail to root, the path can never be absolute.
                        if (jailRoot) return null;
                        return _locateResource(targetPath, segments);
                      } else {
                        targetPath = join(dirname(path), targetPath);
                        return _locateResource(targetPath, segments);
                      }
                    });
              }
              break;
          }
          // Return `null` on fall-through, to indicate NOT_FOUND.
          return null;
        });
  }

  /**
   * Serve the content of [file] to [request].
   *
   * This is usefull when e.g. overriding [directoryHandler] to redirect to
   * some index file.
   *
   * In the request contains the [HttpStatus.IF_MODIFIED_SINCE] header,
   * [serveFile] will send a [HttpStatus.NOT_MODIFIED] response if the file
   * was not changed.
   *
   * Note that if it was unabled to read from [file], the [request]s response
   * is closed with error-code [HttpStatus.NOT_FOUND].
   */
  void serveFile(File file, HttpRequest request) {
    var response = request.response;
    // TODO(ajohnsen): Set up Zone support for these errors.
    file.lastModified().then((lastModified) {
      if (request.headers.ifModifiedSince != null &&
          !lastModified.isAfter(request.headers.ifModifiedSince)) {
        response.statusCode = HttpStatus.NOT_MODIFIED;
        response.close();
        return null;
      }

      response.headers.set(HttpHeaders.LAST_MODIFIED, lastModified);
      response.headers.set(HttpHeaders.ACCEPT_RANGES, "bytes");

      if (request.method == 'HEAD') {
        response.close();
        return null;
      }

      return file.length().then((length) {
        String range = request.headers.value("range");
        if (range != null) {
          // We only support one range, where the standard support several.
          Match matches = new RegExp(r"^bytes=(\d*)\-(\d*)$").firstMatch(range);
          // If the range header have the right format, handle it.
          if (matches != null) {
            // Serve sub-range.
            int start;
            int end;
            if (matches[1].isEmpty) {
              start = matches[2].isEmpty ?
                  length :
                  length - int.parse(matches[2]);
              end = length;
            } else {
              start = int.parse(matches[1]);
              end = matches[2].isEmpty ? length : int.parse(matches[2]) + 1;
            }

            // Override Content-Length with the actual bytes sent.
            response.headers.set(HttpHeaders.CONTENT_LENGTH, end - start);

            // Set 'Partial Content' status code.
            response.statusCode = HttpStatus.PARTIAL_CONTENT;
            response.headers.set(HttpHeaders.CONTENT_RANGE,
                                 "bytes $start-${end - 1}/$length");

            // Pipe the 'range' of the file.
            file.openRead(start, end)
                .pipe(new _VirtualDirectoryFileStream(response, file.path))
                .catchError((_) {
                  // TODO(kevmoo): log errors
                });
            return;
          }
        }

        file.openRead()
            .pipe(new _VirtualDirectoryFileStream(response, file.path))
            .catchError((_) {
              // TODO(kevmoo): log errors
            });
      });
    }).catchError((_) {
      response.statusCode = HttpStatus.NOT_FOUND;
      response.close();
    });
  }

  void _serveDirectory(Directory dir, HttpRequest request) {
    if (_dirCallback != null) {
      _dirCallback(dir, request);
      return;
    }
    var response = request.response;
    dir.stat().then((stats) {
      if (request.headers.ifModifiedSince != null &&
          !stats.modified.isAfter(request.headers.ifModifiedSince)) {
        response.statusCode = HttpStatus.NOT_MODIFIED;
        response.close();
        return;
      }

      response.headers.contentType =
          new ContentType('text', 'html', parameters: {'charset': 'utf-8'});
      response.headers.set(HttpHeaders.LAST_MODIFIED, stats.modified);
      var path = Uri.decodeComponent(request.uri.path);
      var encodedPath = new HtmlEscape().convert(path);
      var header =
'''<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Index of $encodedPath</title>
</head>
<body>
<h1>Index of $encodedPath</h1>
<table>
  <tr>
    <td>Name</td>
    <td>Last modified</td>
    <td>Size</td>
  </tr>
''';
      var server = response.headers.value(HttpHeaders.SERVER);
      if (server == null) server = "";
      var footer =
'''</table>
$server
</body>
</html>
''';

      response.write(header);

      void add(String name, String modified, var size, bool folder) {
        if (size == null) size = "-";
        if (modified == null) modified = "";
        var encodedSize = new HtmlEscape().convert(size.toString());
        var encodedModified = new HtmlEscape().convert(modified);
        var encodedLink = new HtmlEscape(HtmlEscapeMode.ATTRIBUTE)
            .convert(Uri.encodeComponent(name));
        if (folder) {
          encodedLink += '/';
          name += '/';
        }
        var encodedName = new HtmlEscape().convert(name);

        var entry =
'''  <tr>
    <td><a href="$encodedLink">$encodedName</a></td>
    <td>$encodedModified</td>
    <td style="text-align: right">$encodedSize</td>
  </tr>''';
        response.write(entry);
      }

      if (path != '/') {
        add('..', null, null, true);
      }

      dir.list(followLinks: true).listen((entity) {
        var name = basename(entity.path);
        var stat = entity.statSync();
        if (entity is File) {
          add(name,
              stat.modified.toString(),
              stat.size,
              false);
        } else if (entity is Directory) {
          add(name,
              stat.modified.toString(),
              null,
              true);
        }
      }, onError: (e) {
        // TODO(kevmoo): log error
      }, onDone: () {
        response.write(footer);
        response.close();
      });
    }, onError: (e) {
      // TODO(kevmoo): log error
      response.close();
    });
  }

  void _serveErrorPage(int error, HttpRequest request) {
    var response = request.response;
    response.statusCode = error;
    if (_errorCallback != null) {
      _errorCallback(request);
      return;
    }
    response.headers.contentType =
        new ContentType('text', 'html', parameters: {'charset': 'utf-8'});
    // Default error page.
    var path = Uri.decodeComponent(request.uri.path);
    var encodedPath = new HtmlEscape().convert(path);
    var encodedReason = new HtmlEscape().convert(response.reasonPhrase);
    var encodedError = new HtmlEscape().convert(error.toString());

    var server = response.headers.value(HttpHeaders.SERVER);
    if (server == null) server = "";
    var page =
'''<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>$encodedReason: $encodedPath</title>
</head>
<body>
<h1>Error $encodedError at \'$encodedPath\': $encodedReason</h1>
$server
</body>
</html>''';
    response.write(page);
    response.close();
  }
}

class _VirtualDirectoryFileStream extends StreamConsumer<List<int>> {
  final HttpResponse response;
  final String path;
  List<int> buffer = [];

  _VirtualDirectoryFileStream(HttpResponse this.response, String this.path);

  Future addStream(Stream<List<int>> stream) {
    stream.listen(
        (data) {
          if (buffer == null) {
            response.add(data);
            return;
          }
          if (buffer.length == 0) {
            if (data.length >= defaultMagicNumbersMaxLength) {
              setMimeType(data);
              response.add(data);
              buffer = null;
            } else {
              buffer.addAll(data);
            }
          } else {
            buffer.addAll(data);
            if (buffer.length >= defaultMagicNumbersMaxLength) {
              setMimeType(buffer);
              response.add(buffer);
              buffer = null;
            }
          }
        },
        onDone: () {
          if (buffer != null) {
            if (buffer.length == 0) {
              setMimeType(null);
            } else {
              setMimeType(buffer);
              response.add(buffer);
            }
          }
          response.close();
        },
        onError: response.addError);
    return response.done;
  }

  Future close() => new Future.value();

  void setMimeType(List<int> bytes) {
    var mimeType = lookupMimeType(path, headerBytes: bytes);
    if (mimeType != null) {
      response.headers.contentType = ContentType.parse(mimeType);
    }
  }
}
