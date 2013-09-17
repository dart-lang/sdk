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
   * Creates a symbolic link. Returns a [:Future<Link>:] that completes with
   * the link when it has been created. If the link exists,
   * the future will complete with an error.
   *
   * On the Windows platform, this will only work with directories, and the
   * target directory must exist. The link will be created as a Junction.
   * Only absolute links will be created, and relative paths to the target
   * will be converted to absolute paths by joining them with the path of the
   * directory the link is contained in.
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
   * On the Windows platform, this will only work with directories, and the
   * target directory must exist.
   */
  void updateSync(String target);

  /**
   * Updates the link. Returns a [:Future<Link>:] that completes with the
   * link when it has been updated.  Calling [update] on a non-existing link
   * will complete its returned future with an exception.
   *
   * On the Windows platform, this will only work with directories, and the
   * target directory must exist.
   */
  Future<Link> update(String target);

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
   * Returns a [Link] instance whose path is the absolute path to [this].
   *
   * The absolute path is computed by prefixing
   * a relative path with the current working directory, and returning
   * an absolute path unchanged.
   */
  Link get absolute;

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

  _Link(String this.path) {
    if (path is! String) {
      throw new ArgumentError('${Error.safeToString(path)} '
                              'is not a String');
    }
  }


  String toString() => "Link: '$path'";

  Future<bool> exists() => FileSystemEntity.isLink(path);

  bool existsSync() => FileSystemEntity.isLinkSync(path);

  Link get absolute => new Link(_absolutePath);

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
    Uri base = new Uri.file('${Directory.current.path}\\');
    Uri link = new Uri.file(path);
    Uri destination = new Uri.file(target);
    String result = base.resolveUri(link).resolveUri(destination).toFilePath();
    if (result.length > 3 && result[1] == ':' && result[2] == '\\') {
      return '\\??\\$result';
    } else {
      throw new LinkException(
          'Target $result of Link.create on Windows cannot be converted' +
          ' to start with a drive letter.  Unexpected error.');
    }
  }

  void updateSync(String target) {
    // TODO(12414): Replace with atomic update, where supported by platform.
    // Atomically changing a link can be done by creating the new link, with
    // a different name, and using the rename() posix call to move it to
    // the old name atomically.
    deleteSync();
    createSync(target);
  }

  Future<Link> update(String target) {
    // TODO(12414): Replace with atomic update, where supported by platform.
    // Atomically changing a link can be done by creating the new link, with
    // a different name, and using the rename() posix call to move it to
    // the old name atomically.
    return delete().then((_) => create(target));
  }

  Future<Link> _delete({bool recursive: false}) {
    if (recursive) {
      return new Directory(path).delete(recursive: true).then((_) => this);
    }
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

  void _deleteSync({bool recursive: false}) {
    if (recursive) {
      return new Directory(path).deleteSync(recursive: true);
    }
    var result = _File._deleteLinkNative(path);
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
