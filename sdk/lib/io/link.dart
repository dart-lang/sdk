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
   * Create a Link object.
   */
  factory Link(String path) => new _Link(path);

  /**
   * Create a Link object from a Path object.
   */
  factory Link.fromPath(Path path) => new _Link.fromPath(path);

  /**
   * Check if the link exists. The link may exist, even if its target
   * is missing or deleted.
   * Returns a [:Future<bool>:] that completes when the answer is known.
   */
  Future<bool> exists();

  /**
   * Synchronously check if the link exists. The link may exist, even if
   * its target is missing or deleted.
   */
  bool existsSync();

  /**
   * Create a symbolic link. Returns a [:Future<Link>:] that completes with
   * the link when it has been created. If the link exists, the function
   * the future will complete with an error.
   *
   * On the Windows platform, this will only work with directories, and the
   * target directory must exist. The link will be created as a Junction.
   * Only absolute links will be created, and relative paths to the target
   * will be converted to absolute paths.
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
   */
  void createSync(String target);

  /**
   * Synchronously update the link. Calling [updateSync] on a non-existing link
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
   * Delete the link. Returns a [:Future<Link>:] that completes with
   * the link when it has been deleted.  This does not delete, or otherwise
   * affect, the target of the link.
   */
  Future<Link> delete();

  /**
   * Synchronously delete the link. This does not delete, or otherwise
   * affect, the target of the link.
   */
  void deleteSync();
}


class _Link extends FileSystemEntity implements Link {
  final String path;

  _Link(String this.path);

  _Link.fromPath(Path inputPath) : path = inputPath.toNativePath();

  Future<bool> exists() {
    // TODO(whesse): Replace with asynchronous version.
    return new Future.immediate(existsSync());
  }

  bool existsSync() => FileSystemEntity.isLinkSync(path);

  Future<Link> create(String target) {
    // TODO(whesse): Replace with asynchronous version.
    return new Future.of(() {
      createSync(target);
      return this;
    });
  }

  void createSync(String target) {
    if (Platform.operatingSystem == 'windows') {
      target = _makeWindowsLinkTarget(target);
    }
    var result = _File._createLink(path, target);
    if (result is Error) {
      throw new LinkIOException("Error in Link.createSync", result);
    }
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
    return new File(path).delete().then((_) => this);
  }

  void deleteSync() {
    new File(path).deleteSync();
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
