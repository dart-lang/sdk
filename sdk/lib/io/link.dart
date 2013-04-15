// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * [Link] objects are references to filesystem links.
 *
 */
abstract class Link extends FileSystemEntity {
  /**
   * Creates a Link object.
   */
  factory Link(String path) => new _Link(path);

  /**
   * Creates a Link object from a Path object.
   */
  factory Link.fromPath(Path path) => new _Link.fromPath(path);

  /**
   * Checks if the link exists. The link may exist, even if its target
   * is missing or deleted.
   * Returns a [:Future<bool>:] that completes when the answer is known.
   */
  Future<bool> exists();

  /**
   * Synchronously checks if the link exists. The link may exist, even if
   * its target is missing or deleted.
   */
  bool existsSync();

  /**
   * Creates a symbolic link. Returns a [:Future<Link>:] that completes with
   * the link when it has been created. If the link exists,
   * the future will complete with an error.
   *
   * On the Windows platform, this will only work with directories, and the
   * target directory must exist. The link will be created as a Junction.
   * Only absolute links will be created, and relative paths to the target
   * will be converted to absolute paths.
   *
   * On other platforms, the posix symlink() call is used to make a symbolic
   * link containing the string [target].  If [target] is a relative path,
   * it will be interpreted relative to the directory containing the link.
   */
  Future<Link> create(String target);

  /**
   * Synchronously create the link. Calling [createSync] on an existing link
   * will throw an exception.
   *
   * On the Windows platform, this will only work with directories, and the
   * target directory must exist. The link will be created as a Junction.
   * Only absolute links will be created, and relative paths to the target
   * will be converted to absolute paths.
   *
   * On other platforms, the posix symlink() call is used to make a symbolic
   * link containing the string [target].  If [target] is a relative path,
   * it will be interpreted relative to the directory containing the link.
   */
  void createSync(String target);

  /**
   * Synchronously updates the link. Calling [updateSync] on a non-existing link
   * will throw an exception.
   *
   * If [linkRelative] is true, the target argument should be a relative path,
   * and the link will interpret the target as a path relative to the link's
   * directory.
   *
   * On the Windows platform, this will only work with directories, and the
   * target directory must exist.
   */
  void updateSync(String target, {bool linkRelative: false });

  /**
   * Deletes the link. Returns a [:Future<Link>:] that completes with
   * the link when it has been deleted. This does not delete, or otherwise
   * affect, the target of the link. It also works on broken links, but if
   * the link does not exist or is not actually a link, it completes the
   * future with a LinkIOException.
   */
  Future<Link> delete();

  /**
   * Synchronously deletes the link. This does not delete, or otherwise
   * affect, the target of the link.  It also works on broken links, but if
   * the link does not exist or is not actually a link, it throws a
   * LinkIOException.
   */
  void deleteSync();

  /**
   * Gets the target of the link. Returns a future that completes with
   * the path to the target.
   *
   * If the returned target is a relative path, it is relative to the
   * directory containing the link.
   *
   * If the link does not exist, or is not a link, the future completes with
   * a LinkIOException.
   */
  Future<String> target();

  /**
   * Synchronously gets the target of the link. Returns the path to the target.
   *
   * If the returned target is a relative path, it is relative to the
   * directory containing the link.
   *
   * If the link does not exist, or is not a link, throws a LinkIOException.
   */
  String targetSync();
}


class _Link extends FileSystemEntity implements Link {
  final String path;

  SendPort _fileService;

  _Link(String this.path);

  _Link.fromPath(Path inputPath) : path = inputPath.toNativePath();

  String toString() => "Link: '$path'";

  Future<bool> exists() {
    // TODO(whesse): Replace with asynchronous version.
    return new Future.value(existsSync());
  }

  bool existsSync() => FileSystemEntity.isLinkSync(path);

  Future<Link> create(String target) {
    _ensureFileService();
    if (Platform.operatingSystem == 'windows') {
      target = _makeWindowsLinkTarget(target);
    }
    List request = new List(3);
    request[0] = _CREATE_LINK_REQUEST;
    request[1] = path;
    request[2] = target;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
            "Cannot create link '$path' to target '$target'");
      }
      return this;
    });
  }

  void createSync(String target) {
    if (Platform.operatingSystem == 'windows') {
      target = _makeWindowsLinkTarget(target);
    }
    var result = _File._createLink(path, target);
    throwIfError(result, "Cannot create link '$path'");
  }

  // Put target into the form "\??\C:\my\target\dir".
  String _makeWindowsLinkTarget(String target) {
    if (target.startsWith('\\??\\')) {
      return target;
    }
    if (!(target.length > 3 && target[1] == ':' && target[2] == '\\')) {
      target = new File(target).fullPathSync();
    }
    if (target.length > 3 && target[1] == ':' && target[2] == '\\') {
      target = '\\??\\$target';
    } else {
      throw new ArgumentError(
          'Target $target of Link.create on Windows cannot be converted' +
          ' to start with a drive letter.  Unexpected error.');
    }
    return target;
  }

  void updateSync(String target, {bool linkRelative: false }) {
    // TODO(whesse): Replace with atomic update, where supported by platform.
    deleteSync();
    createSync(target);
  }

  Future<Link> delete() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _DELETE_LINK_REQUEST;
    request[1] = path;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Cannot delete link '$path'");
      }
      return this;
    });
  }

  void deleteSync() {
    var result = _File._deleteLink(path);
    throwIfError(result, "Cannot delete link '$path'");
  }

  Future<String> target() {
    // TODO(whesse): Replace with asynchronous version.
    return new Future.sync(targetSync);
  }

  String targetSync() {
    var result = _File._linkTarget(path);
    throwIfError(result, "Cannot read link '$path'");
    return result;
  }

  static throwIfError(Object result, String msg) {
    if (result is OSError) {
      throw new LinkIOException(msg, result);
    }
  }

  bool _isErrorResponse(response) {
    return response is List && response[0] != _SUCCESS_RESPONSE;
  }

  void _ensureFileService() {
    if (_fileService == null) {
      _fileService = _FileUtils._newServicePort();
    }
  }

  _exceptionFromResponse(response, String message) {
    assert(_isErrorResponse(response));
    switch (response[_ERROR_RESPONSE_ERROR_TYPE]) {
      case _ILLEGAL_ARGUMENT_RESPONSE:
        return new ArgumentError();
      case _OSERROR_RESPONSE:
        var err = new OSError(response[_OSERROR_RESPONSE_MESSAGE],
                              response[_OSERROR_RESPONSE_ERROR_CODE]);
        return new LinkIOException(message, err);
      default:
        return new Exception("Unknown error");
    }
  }
}


class LinkIOException implements Exception {
  const LinkIOException([String this.message = "",
                         String this.path = "",
                         OSError this.osError = null]);
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("LinkIOException");
    if (!message.isEmpty) {
      sb.write(": $message");
      if (path != null) {
        sb.write(", path = $path");
      }
      if (osError != null) {
        sb.write(" ($osError)");
      }
    } else if (osError != null) {
      sb.write(": $osError");
      if (path != null) {
        sb.write(", path = $path");
      }
    }
    return sb.toString();
  }
  final String message;
  final String path;
  final OSError osError;
}
