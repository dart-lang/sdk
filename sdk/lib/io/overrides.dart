// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

final _ioOverridesToken = new Object();

const _asyncRunZoned = runZoned;

/// This class facilitates overriding various APIs of dart:io with mock
/// implementations.
///
/// This abstract base class should be extended with overrides for the
/// operations needed to construct mocks. The implementations in this base class
/// default to the actual dart:io implementation. For example:
///
/// ```
/// class MyDirectory implements Directory {
///   ...
///   // An implementation of the Directory interface
///   ...
/// }
///
/// main() {
///   IOOverrides.runZoned(() {
///     ...
///     // Operations will use MyDirectory instead of dart:io's Directory
///     // implementation whenever Directory is used.
///     ...
///   }, createDirectory: (String path) => new MyDirectory(path));
/// }
/// ```
abstract class IOOverrides {
  static IOOverrides get current {
    return Zone.current[_ioOverridesToken];
  }

  /// Runs [body] in a fresh [Zone] using the provided overrides.
  ///
  /// See the documentation on the corresponding methods of IOOverrides for
  /// information about what the optional arguments do.
  static R runZoned<R>(R body(),
      {
      // Directory
      Directory Function(String) createDirectory,
      Directory Function() getCurrentDirectory,
      void Function(String) setCurrentDirectory,
      Directory Function() getSystemTempDirectory,

      // File
      File Function(String) createFile,

      // FileStat
      Future<FileStat> Function(String) stat,
      FileStat Function(String) statSync,

      // FileSystemEntity
      Future<bool> Function(String, String) fseIdentical,
      bool Function(String, String) fseIdenticalSync,
      Future<FileSystemEntityType> Function(String, bool) fseGetType,
      FileSystemEntityType Function(String, bool) fseGetTypeSync,

      // _FileSystemWatcher
      Stream<FileSystemEvent> Function(String, int, bool) fsWatch,
      bool Function() fsWatchIsSupported,

      // Link
      Link Function(String) createLink,

      // Optional Zone parameters
      ZoneSpecification zoneSpecification,
      Function onError}) {
    IOOverrides overrides = new _IOOverridesScope(
      // Directory
      createDirectory,
      getCurrentDirectory,
      setCurrentDirectory,
      getSystemTempDirectory,

      // File
      createFile,

      // FileStat
      stat,
      statSync,

      // FileSystemEntity
      fseIdentical,
      fseIdenticalSync,
      fseGetType,
      fseGetTypeSync,

      // _FileSystemWatcher
      fsWatch,
      fsWatchIsSupported,

      // Link
      createLink,
    );
    return _asyncRunZoned<R>(body,
        zoneValues: {_ioOverridesToken: overrides},
        zoneSpecification: zoneSpecification,
        onError: onError);
  }

  /// Runs [body] in a fresh [Zone] using the overrides found in [overrides].
  ///
  /// Note that [overrides] should be an instance of a class that extends
  /// [IOOverrides].
  static R runWithIOOverrides<R>(R body(), IOOverrides overrides,
      {ZoneSpecification zoneSpecification, Function onError}) {
    return _asyncRunZoned<R>(body,
        zoneValues: {_ioOverridesToken: overrides},
        zoneSpecification: zoneSpecification,
        onError: onError);
  }

  // Directory

  /// Creates a new [Directory] object for the given [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `new Directory()` and `new Directory.fromUri()`.
  Directory createDirectory(String path) => new _Directory(path);

  /// Returns the current working directory.
  ///
  /// When this override is installed, this function overrides the behavior of
  /// the static getter `Directory.current`
  Directory getCurrentDirectory() => _Directory.current;

  /// Sets the current working directory to be [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// the setter `Directory.current`.
  void setCurrentDirectory(String path) {
    _Directory.current = path;
  }

  /// Returns the system temporary directory.
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `Directory.systemTemp`.
  Directory getSystemTempDirectory() => _Directory.systemTemp;

  // File

  /// Creates a new [File] object for the given [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `new File()` and `new File.fromUri()`.
  File createFile(String path) => new _File(path);

  // FileStat

  /// Asynchronously returns [FileStat] information for [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileStat.stat()`.
  Future<FileStat> stat(String path) {
    return FileStat._stat(path);
  }

  /// Returns [FileStat] information for [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileStat.statSync()`.
  FileStat statSync(String path) {
    return FileStat._statSyncInternal(path);
  }

  // FileSystemEntity

  /// Asynchronously returns `true` if [path1] and [path2] are paths to the
  /// same file system object.
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileSystemEntity.identical`.
  Future<bool> fseIdentical(String path1, String path2) {
    return FileSystemEntity._identical(path1, path2);
  }

  /// Returns `true` if [path1] and [path2] are paths to the
  /// same file system object.
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileSystemEntity.identicalSync`.
  bool fseIdenticalSync(String path1, String path2) {
    return FileSystemEntity._identicalSync(path1, path2);
  }

  /// Asynchronously returns the [FileSystemEntityType] for [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileSystemEntity.type`.
  Future<FileSystemEntityType> fseGetType(String path, bool followLinks) {
    return FileSystemEntity._getTypeRequest(path, followLinks);
  }

  /// Returns the [FileSystemEntityType] for [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileSystemEntity.typeSync`.
  FileSystemEntityType fseGetTypeSync(String path, bool followLinks) {
    return FileSystemEntity._getTypeSyncHelper(path, followLinks);
  }

  // _FileSystemWatcher

  /// Returns a [Stream] of [FileSystemEvent]s.
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileSystemEntity.watch()`.
  Stream<FileSystemEvent> fsWatch(String path, int events, bool recursive) {
    return _FileSystemWatcher._watch(path, events, recursive);
  }

  /// Returns `true` when [FileSystemEntity.watch] is supported.
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileSystemEntity.isWatchSupported`.
  bool fsWatchIsSupported() => _FileSystemWatcher.isSupported;

  // Link

  /// Returns a new [Link] object for the given [path].
  /// When this override is installed, this function overrides the behavior of
  /// `new Link()` and `new Link.fromUri()`.
  Link createLink(String path) => new _Link(path);
}

class _IOOverridesScope extends IOOverrides {
  final IOOverrides _previous = IOOverrides.current;

  // Directory
  Directory Function(String) _createDirectory;
  Directory Function() _getCurrentDirectory;
  void Function(String) _setCurrentDirectory;
  Directory Function() _getSystemTempDirectory;

  // File
  File Function(String) _createFile;

  // FileStat
  Future<FileStat> Function(String) _stat;
  FileStat Function(String) _statSync;

  // FileSystemEntity
  Future<bool> Function(String, String) _fseIdentical;
  bool Function(String, String) _fseIdenticalSync;
  Future<FileSystemEntityType> Function(String, bool) _fseGetType;
  FileSystemEntityType Function(String, bool) _fseGetTypeSync;

  // _FileSystemWatcher
  Stream<FileSystemEvent> Function(String, int, bool) _fsWatch;
  bool Function() _fsWatchIsSupported;

  // Link
  Link Function(String) _createLink;

  _IOOverridesScope(
    // Directory
    this._createDirectory,
    this._getCurrentDirectory,
    this._setCurrentDirectory,
    this._getSystemTempDirectory,

    // File
    this._createFile,

    // FileStat
    this._stat,
    this._statSync,

    // FileSystemEntity
    this._fseIdentical,
    this._fseIdenticalSync,
    this._fseGetType,
    this._fseGetTypeSync,

    // _FileSystemWatcher
    this._fsWatch,
    this._fsWatchIsSupported,

    // Link
    this._createLink,
  );

  // Directory
  @override
  Directory createDirectory(String path) {
    if (_createDirectory != null) return _createDirectory(path);
    if (_previous != null) return _previous.createDirectory(path);
    return super.createDirectory(path);
  }

  @override
  Directory getCurrentDirectory() {
    if (_getCurrentDirectory != null) return _getCurrentDirectory();
    if (_previous != null) return _previous.getCurrentDirectory();
    return super.getCurrentDirectory();
  }

  @override
  void setCurrentDirectory(String path) {
    if (_setCurrentDirectory != null)
      _setCurrentDirectory(path);
    else if (_previous != null)
      _previous.setCurrentDirectory(path);
    else
      super.setCurrentDirectory(path);
  }

  @override
  Directory getSystemTempDirectory() {
    if (_getSystemTempDirectory != null) return _getSystemTempDirectory();
    if (_previous != null) return _previous.getSystemTempDirectory();
    return super.getSystemTempDirectory();
  }

  // File
  @override
  File createFile(String path) {
    if (_createFile != null) return _createFile(path);
    if (_previous != null) return _previous.createFile(path);
    return super.createFile(path);
  }

  // FileStat
  @override
  Future<FileStat> stat(String path) {
    if (_stat != null) return _stat(path);
    if (_previous != null) return _previous.stat(path);
    return super.stat(path);
  }

  @override
  FileStat statSync(String path) {
    if (_stat != null) return _statSync(path);
    if (_previous != null) return _previous.statSync(path);
    return super.statSync(path);
  }

  // FileSystemEntity
  @override
  Future<bool> fseIdentical(String path1, String path2) {
    if (_fseIdentical != null) return _fseIdentical(path1, path2);
    if (_previous != null) return _previous.fseIdentical(path1, path2);
    return super.fseIdentical(path1, path2);
  }

  @override
  bool fseIdenticalSync(String path1, String path2) {
    if (_fseIdenticalSync != null) return _fseIdenticalSync(path1, path2);
    if (_previous != null) return _previous.fseIdenticalSync(path1, path2);
    return super.fseIdenticalSync(path1, path2);
  }

  @override
  Future<FileSystemEntityType> fseGetType(String path, bool followLinks) {
    if (_fseGetType != null) return _fseGetType(path, followLinks);
    if (_previous != null) return _previous.fseGetType(path, followLinks);
    return super.fseGetType(path, followLinks);
  }

  @override
  FileSystemEntityType fseGetTypeSync(String path, bool followLinks) {
    if (_fseGetTypeSync != null) return _fseGetTypeSync(path, followLinks);
    if (_previous != null) return _previous.fseGetTypeSync(path, followLinks);
    return super.fseGetTypeSync(path, followLinks);
  }

  // _FileSystemWatcher
  @override
  Stream<FileSystemEvent> fsWatch(String path, int events, bool recursive) {
    if (_fsWatch != null) return _fsWatch(path, events, recursive);
    if (_previous != null) return _previous.fsWatch(path, events, recursive);
    return super.fsWatch(path, events, recursive);
  }

  bool fsWatchIsSupported() {
    if (_fsWatchIsSupported != null) return _fsWatchIsSupported();
    if (_previous != null) return _previous.fsWatchIsSupported();
    return super.fsWatchIsSupported();
  }

  // Link
  @override
  Link createLink(String path) {
    if (_createLink != null) return _createLink(path);
    if (_previous != null) return _previous.createLink(path);
    return super.createLink(path);
  }
}
