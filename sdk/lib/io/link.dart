// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * [Link] objects are references to filesystem links.
 *
 */
abstract class Link implements FileSystemEntity {
  /**
   * Creates a Link object.
   */
  factory Link(String path) => new _Link(path);

  /**
   * Creates a Link object from a Path object.
   */
  factory Link.fromPath(Path path) => new _Link.fromPath(path);

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
   * future with a LinkException.
   */
  Future<Link> delete();

  /**
   * Synchronously deletes the link. This does not delete, or otherwise
   * affect, the target of the link.  It also works on broken links, but if
   * the link does not exist or is not actually a link, it throws a
   * LinkException.
   */
  void deleteSync();

  /**
   * Renames this link. Returns a `Future<Link>` that completes
   * with a [Link] instance for the renamed link.
   *
   * If [newPath] identifies an existing link, that link is
   * replaced. If [newPath] identifies an existing file or directory,
   * the operation fails and the future completes with an exception.
   */
  Future<Link> rename(String newPath);

   /**
   * Synchronously renames this link. Returns a [Link]
   * instance for the renamed link.
   *
   * If [newPath] identifies an existing link, that link is
   * replaced. If [newPath] identifies an existing file or directory
   * the operation fails and an exception is thrown.
   */
  Link renameSync(String newPath);

  /**
   * Gets the target of the link. Returns a future that completes with
   * the path to the target.
   *
   * If the returned target is a relative path, it is relative to the
   * directory containing the link.
   *
   * If the link does not exist, or is not a link, the future completes with
   * a LinkException.
   */
  Future<String> target();

  /**
   * Synchronously gets the target of the link. Returns the path to the target.
   *
   * If the returned target is a relative path, it is relative to the
   * directory containing the link.
   *
   * If the link does not exist, or is not a link, throws a LinkException.
   */
  String targetSync();
}


class _Link extends FileSystemEntity implements Link {
  final String path;

  SendPort _fileService;

  _Link(String this.path);

  _Link.fromPath(Path inputPath) : path = inputPath.toNativePath();

  String toString() => "Link: '$path'";

  Future<bool> exists() => FileSystemEntity.isLink(path);

  bool existsSync() => FileSystemEntity.isLinkSync(path);

  Future<FileStat> stat() => FileStat.stat(path);

  FileStat statSync() => FileStat.statSync(path);

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
        throw _exceptionFromResponse(
            response, "Cannot create link to target '$target'", path);
      }
      return this;
    });
  }

  void createSync(String target) {
    if (Platform.operatingSystem == 'windows') {
      target = _makeWindowsLinkTarget(target);
    }
    var result = _File._createLink(path, target);
    throwIfError(result, "Cannot create link", path);
  }

  // Put target into the form "\??\C:\my\target\dir".
  String _makeWindowsLinkTarget(String target) {
    if (target.startsWith('\\??\\')) {
      return target;
    }
    if (!(target.length > 3 && target[1] == ':' && target[2] == '\\')) {
      try {
        target = new File(target).fullPathSync();
      } on FileException catch (e) {
        throw new LinkException('Could not locate target', target, e.osError);
      }
    }
    if (target.length > 3 && target[1] == ':' && target[2] == '\\') {
      target = '\\??\\$target';
    } else {
      throw new LinkException(
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
        throw _exceptionFromResponse(response, "Cannot delete link", path);
      }
      return this;
    });
  }

  void deleteSync() {
    var result = _File._deleteLink(path);
    throwIfError(result, "Cannot delete link", path);
  }

  Future<Link> rename(String newPath) {
    _ensureFileService();
    List request = new List(3);
    request[0] = _RENAME_LINK_REQUEST;
    request[1] = path;
    request[2] = newPath;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(
            response, "Cannot rename link to '$newPath'", path);
      }
      return new Link(newPath);
    });
  }

  Link renameSync(String newPath) {
    var result = _File._renameLink(path, newPath);
    throwIfError(result, "Cannot rename link '$path' to '$newPath'");
    return new Link(newPath);
  }

  Future<String> target() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _LINK_TARGET_REQUEST;
    request[1] = path;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(
            response, "Cannot get target of link", path);
      }
      return response;
    });
  }

  String targetSync() {
    var result = _File._linkTarget(path);
    throwIfError(result, "Cannot read link", path);
    return result;
  }

  static throwIfError(Object result, String msg, [String path = ""]) {
    if (result is OSError) {
      throw new LinkException(msg, path, result);
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

  _exceptionFromResponse(response, String message, String path) {
    assert(_isErrorResponse(response));
    switch (response[_ERROR_RESPONSE_ERROR_TYPE]) {
      case _ILLEGAL_ARGUMENT_RESPONSE:
        return new ArgumentError();
      case _OSERROR_RESPONSE:
        var err = new OSError(response[_OSERROR_RESPONSE_MESSAGE],
                              response[_OSERROR_RESPONSE_ERROR_CODE]);
        return new LinkException(message, path, err);
      default:
        return new Exception("Unknown error");
    }
  }
}


class LinkException implements IOException {
  const LinkException([String this.message = "",
                       String this.path = "",
                       OSError this.osError = null]);
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("LinkException");
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
