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
   * If [linkRelative] is true, the target argument should be a relative path,
   * and the link will interpret the target as a path relative to the link's
   * directory.
   *
   * On the Windows platform, this will only work with directories, and the
   * target directory must exist. The link will be created as a Junction.
   */
  Future<Link> create(String target, {bool linkRelative: false });

  /**
   * Synchronously create the link. Calling [createSync] on an existing link
   * will throw an exception.
   *
   * If [linkRelative] is true, the target argument should be a relative path,
   * and the link will interpret the target as a path relative to the link's
   * directory.
   *
   * If [linkRelative] is false, the target argument will be turned into an
   * absolute path, and the target will be that absolute path.
   *
   * On the Windows platform, this will only work with directories, and the
   * target directory must exist. The link will be created as a Junction.
   */
  void createSync(String target, {bool linkRelative: false });

   /**
   * Updates a link to point to a different target.
   * Returns a [:Future<Link>:] that completes with
   * the link when it has been created.  If the link does not exist,
   * the future completes with an exception.
   *
   * If [linkRelative] is true, the target argument should be a relative path,
   * and the link will interpret the target as a path relative to the link's
   * directory.
   *
   * On the Windows platform, this will only work with directories, and the
   * target directory must exist.
   */
  Future<Link> update(String target, {bool linkRelative: false });

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

  /**
   * Get a [Directory] object for the directory containing this
   * link. This is the directory containing the link, not the directory
   * containing the target of the link. Returns a [:Future<Directory>:]
   * that completes with the directory.
   */
  Future<Directory> directory();

  /**
   * Synchronously get a [Directory] object for the directory containing
   * this link. This is the directory containing the link, not the directory
   * containing the target of the link.
   */
  Directory directorySync();

  /**
   * Get the target of the link. Returns a future that completes with
   * the path to the target.
   *
   * If [linkRelative] is true and the link target is a path relative to
   * the link's directory, the future will complete with that relative path.
   * Otherwise, the future completes with an error.
   *
   * If [linkRelative] is false, the future completes with an absolute path
   * to the target.
   */
  Future<String> target({bool linkRelative: false });

  /**
   * Synchronously get the target of the link. Returns the path to the target.
   *
   * If [linkRelative] is true and the link target is a path relative to
   * the link's directory, that relative path will be returned.  Otherwise,
   * an exception is thrown.
   */
  String targetSync({bool linkRelative: false });

  /**
   * Get the canonical full path corresponding to the link path.
   * Returns a [:Future<String>:] that completes with the path.
   */
  Future<String> fullPath();

  /**
   * Synchronously get the canonical full path corresponding to the link path.
   */
  String fullPathSync();
}


class _Link extends FileSystemEntity {
  final String path;

  _Link(String this.path);

  _Link.fromPath(Path inputPath) : path = inputPath.toNativePath();

  Future<bool> exists() {
    // TODO(whesse): Replace with asynchronous version.
    return new Future.immediate(existsSync());
  }

  bool existsSync() => FileSystemEntity.isLinkSync(path);

  Future<Link> create(String target, {bool linkRelative: false }) {
    // TODO(whesse): Replace with asynchronous version.
    return new Future.of(() {
      createSync(target, linkRelative: linkRelative);
      return this;
    });
  }

  void createSync(String target, {bool linkRelative: false }) {
    if (!new Path(target).isAbsolute && !linkRelative) {
      throw new UnimplementedError(
          "Link.create with relative path must be linkRelative");
    }
    var result = _File._createLink(path, target);
    if (result is OSError) {
      throw new LinkIOException("Error in Link.createSync", result);
    }
  }

  Future<Link> update(String target, {bool linkRelative: false }) {
    throw new UnimplementedError(
        'Asynchronous, atomic Link.update not yet implemented');
  }

  void updateSync(String target, {bool linkRelative: false }) {
    deleteSync();
    createSync(target, linkRelative: linkRelative);
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
