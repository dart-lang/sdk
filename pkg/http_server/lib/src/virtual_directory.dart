// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of http_server;

/**
 * A [VirtualDirectory] can serve files and directory-listing from a root path,
 * to [HttpRequest]s.
 *
 * The [VirtualDirectory] providing secure handling of request uris and
 * file-system links, correct mime-types and custom error pages.
 */
abstract class VirtualDirectory {
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

  /*
   * Create a new [VirtualDirectory] for serving static file content of
   * the path [root].
   *
   * The [root] is not required to exist. If the [root] doesn't exist at time of
   * a request, a 404 is generated.
   */
  factory VirtualDirectory(String root) => new _VirtualDirectory(root);

  /**
   * Serve a [Stream] of [HttpRequest]s, in this [VirtualDirectory].
   */
  void serve(Stream<HttpRequest> requests);

  /**
   * Serve a single [HttpRequest], in this [VirtualDirectory].
   */
  void serveRequest(HttpRequest request);

  /**
   * Set the [callback] to override the error page handler. When [callback] is
   * invoked, the `statusCode` property of the response is set.
   */
  void setErrorPageHandler(void callback(HttpResponse response));
}

class _VirtualDirectory implements VirtualDirectory {
  final String root;

  bool allowDirectoryListing = false;
  bool followLinks = true;

  _VirtualDirectory(this.root);

  void serve(Stream<HttpRequest> requests) {
    requests.listen(serveRequest);
  }

  void serveRequest(HttpRequest request) {
    var path = new Path(request.uri.path).canonicalize();

    if (!path.isAbsolute) {
      return _serveErrorPage(HttpStatus.NOT_FOUND, request);
    }

    _locateResource(new Path('.'), path.segments())
        .then((entity) {
          if (entity == null) {
            _serveErrorPage(HttpStatus.NOT_FOUND, request);
            return;
          }
          if (entity is File) {
            entity.openRead().pipe(request.response).catchError((_) {});
          } else {
            _serveErrorPage(HttpStatus.NOT_FOUND, request);
          }
        });
  }

  Future<FileSystemEntity> _locateResource(Path path,
                                           Iterable<String> segments) {
    Path fullPath() => new Path(root).join(path);
    return FileSystemEntity.type(fullPath().toNativePath(), followLinks: false)
        .then((type) {
          switch (type) {
            case FileSystemEntityType.FILE:
              if (segments.isEmpty) return new File.fromPath(fullPath());
              break;

            case FileSystemEntityType.DIRECTORY:
              if (segments.isEmpty) {
                if (allowDirectoryListing) {
                  return new Directory.fromPath(fullPath());
                }
              } else {
                return _locateResource(path.append(segments.first),
                                       segments.skip(1));
              }
              break;

            case FileSystemEntityType.LINK:
              if (followLinks) {
                return new Link.fromPath(fullPath()).target()
                    .then((target) {
                      var targetPath = new Path(target).canonicalize();
                      if (targetPath.isAbsolute) return null;
                      targetPath = path.directoryPath.join(targetPath)
                          .canonicalize();
                      if (targetPath.segments().isEmpty ||
                          targetPath.segments().first == '..') return null;
                      return _locateResource(targetPath.append(segments.first),
                                             segments.skip(1));
                    });
              }
              break;
          }
          // Return `null` on fall-through, to indicate NOT_FOUND.
          return null;
        });
  }

  void _serveErrorPage(int error, HttpRequest request) {
    request.response.statusCode = error;
    request.response.close();
  }
}
