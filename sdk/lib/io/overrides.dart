// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

final _ioOverridesToken = new Object();

const _asyncRunZoned = runZoned;

/// Facilities for overriding various APIs of `dart:io` with mock
/// implementations.
///
/// This abstract base class should be extended with overrides for the
/// operations needed to construct mocks. The implementations in this base class
/// default to the actual `dart:io` implementation. For example:
///
/// ```dart
/// class MyDirectory implements Directory {
///   ...
///   // An implementation of the Directory interface
///   ...
/// }
///
/// void main() {
///   IOOverrides.runZoned(() {
///     ...
///     // Operations will use MyDirectory instead of dart:io's Directory
///     // implementation whenever Directory is used.
///     ...
///   }, createDirectory: (String path) => new MyDirectory(path));
/// }
/// ```
abstract class IOOverrides {
  static IOOverrides? _global;

  static IOOverrides? get current {
    return Zone.current[_ioOverridesToken] ?? _global;
  }

  /// The [IOOverrides] to use in the root [Zone].
  ///
  /// These are the [IOOverrides] that will be used in the root [Zone], and in
  /// [Zone]'s that do not set [IOOverrides] and whose ancestors up to the root
  /// [Zone] also do not set [IOOverrides].
  static set global(IOOverrides? overrides) {
    _global = overrides;
  }

  /// Runs [body] in a fresh [Zone] using the provided overrides.
  ///
  /// See the documentation on the corresponding methods of [IOOverrides] for
  /// information about what the optional arguments do.
  static R runZoned<R>(R body(),
      {
      // Directory
      Directory Function(String)? createDirectory,
      Directory Function()? getCurrentDirectory,
      void Function(String)? setCurrentDirectory,
      Directory Function()? getSystemTempDirectory,

      // File
      File Function(String)? createFile,

      // FileStat
      Future<FileStat> Function(String)? stat,
      FileStat Function(String)? statSync,

      // FileSystemEntity
      Future<bool> Function(String, String)? fseIdentical,
      bool Function(String, String)? fseIdenticalSync,
      Future<FileSystemEntityType> Function(String, bool)? fseGetType,
      FileSystemEntityType Function(String, bool)? fseGetTypeSync,

      // _FileSystemWatcher
      Stream<FileSystemEvent> Function(String, int, bool)? fsWatch,
      bool Function()? fsWatchIsSupported,

      // Link
      Link Function(String)? createLink,

      // Socket
      Future<Socket> Function(dynamic, int,
              {dynamic sourceAddress, int sourcePort, Duration? timeout})?
          socketConnect,
      Future<ConnectionTask<Socket>> Function(dynamic, int,
              {dynamic sourceAddress, int sourcePort})?
          socketStartConnect,

      // ServerSocket
      Future<ServerSocket> Function(dynamic, int,
              {int backlog, bool v6Only, bool shared})?
          serverSocketBind,

      // Standard Streams
      Stdin Function()? stdin,
      Stdout Function()? stdout,
      Stdout Function()? stderr}) {
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

      // Socket
      socketConnect,
      socketStartConnect,

      // ServerSocket
      serverSocketBind,

      // Standard streams
      stdin,
      stdout,
      stderr,
    );
    return _asyncRunZoned<R>(body, zoneValues: {_ioOverridesToken: overrides});
  }

  /// Runs [body] in a fresh [Zone] using the overrides found in [overrides].
  ///
  /// Note that [overrides] should be an instance of a class that extends
  /// [IOOverrides].
  static R runWithIOOverrides<R>(R body(), IOOverrides overrides) {
    return _asyncRunZoned<R>(body, zoneValues: {_ioOverridesToken: overrides});
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
    return FileSystemEntity._getTypeRequest(
        utf8.encoder.convert(path), followLinks);
  }

  /// Returns the [FileSystemEntityType] for [path].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `FileSystemEntity.typeSync`.
  FileSystemEntityType fseGetTypeSync(String path, bool followLinks) {
    return FileSystemEntity._getTypeSyncHelper(
        utf8.encoder.convert(path), followLinks);
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
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `new Link()` and `new Link.fromUri()`.
  Link createLink(String path) => new _Link(path);

  // Socket

  /// Asynchronously returns a [Socket] connected to the given host and port.
  ///
  /// When this override is installed, this functions overrides the behavior of
  /// `Socket.connect(...)`.
  Future<Socket> socketConnect(host, int port,
      {sourceAddress, int sourcePort = 0, Duration? timeout}) {
    return Socket._connect(host, port,
        sourceAddress: sourceAddress, sourcePort: sourcePort, timeout: timeout);
  }

  /// Asynchronously returns a [ConnectionTask] that connects to the given host
  /// and port when successful.
  ///
  /// When this override is installed, this functions overrides the behavior of
  /// `Socket.startConnect(...)`.
  Future<ConnectionTask<Socket>> socketStartConnect(host, int port,
      {sourceAddress, int sourcePort = 0}) {
    return Socket._startConnect(host, port,
        sourceAddress: sourceAddress, sourcePort: sourcePort);
  }

  // ServerSocket

  /// Asynchronously returns a [ServerSocket] that connects to the given address
  /// and port when successful.
  ///
  /// When this override is installed, this functions overrides the behavior of
  /// `ServerSocket.bind(...)`.
  Future<ServerSocket> serverSocketBind(address, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false}) {
    return ServerSocket._bind(address, port,
        backlog: backlog, v6Only: v6Only, shared: shared);
  }

  // Standard streams

  /// The standard input stream of data read by this program.
  ///
  /// When this override is installed, this getter overrides the behavior of
  /// the top-level `stdin` getter.
  Stdin get stdin {
    return _stdin;
  }

  /// The standard output stream of data written by this program.
  ///
  /// When this override is installed, this getter overrides the behavior of
  /// the top-level `stdout` getter.
  Stdout get stdout {
    return _stdout;
  }

  /// The standard output stream of errors written by this program.
  ///
  /// When this override is installed, this getter overrides the behavior of
  /// the top-level `stderr` getter.
  Stdout get stderr {
    return _stderr;
  }
}

class _IOOverridesScope extends IOOverrides {
  final IOOverrides? _previous = IOOverrides.current;

  // Directory
  Directory Function(String)? _createDirectory;
  Directory Function()? _getCurrentDirectory;
  void Function(String)? _setCurrentDirectory;
  Directory Function()? _getSystemTempDirectory;

  // File
  File Function(String)? _createFile;

  // FileStat
  Future<FileStat> Function(String)? _stat;
  FileStat Function(String)? _statSync;

  // FileSystemEntity
  Future<bool> Function(String, String)? _fseIdentical;
  bool Function(String, String)? _fseIdenticalSync;
  Future<FileSystemEntityType> Function(String, bool)? _fseGetType;
  FileSystemEntityType Function(String, bool)? _fseGetTypeSync;

  // _FileSystemWatcher
  Stream<FileSystemEvent> Function(String, int, bool)? _fsWatch;
  bool Function()? _fsWatchIsSupported;

  // Link
  Link Function(String)? _createLink;

  // Socket
  Future<Socket> Function(dynamic, int,
      {dynamic sourceAddress,
      int sourcePort,
      Duration? timeout})? _socketConnect;
  Future<ConnectionTask<Socket>> Function(dynamic, int,
      {dynamic sourceAddress, int sourcePort})? _socketStartConnect;

  // ServerSocket
  Future<ServerSocket> Function(dynamic, int,
      {int backlog, bool v6Only, bool shared})? _serverSocketBind;

  // Standard streams
  Stdin Function()? _stdin;
  Stdout Function()? _stdout;
  Stdout Function()? _stderr;

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

    // Socket
    this._socketConnect,
    this._socketStartConnect,

    // ServerSocket
    this._serverSocketBind,

    // Standard streams
    this._stdin,
    this._stdout,
    this._stderr,
  );

  // Directory
  @override
  Directory createDirectory(String path) {
    if (_createDirectory != null) return _createDirectory!(path);
    if (_previous != null) return _previous!.createDirectory(path);
    return super.createDirectory(path);
  }

  @override
  Directory getCurrentDirectory() {
    if (_getCurrentDirectory != null) return _getCurrentDirectory!();
    if (_previous != null) return _previous!.getCurrentDirectory();
    return super.getCurrentDirectory();
  }

  @override
  void setCurrentDirectory(String path) {
    if (_setCurrentDirectory != null)
      _setCurrentDirectory!(path);
    else if (_previous != null)
      _previous!.setCurrentDirectory(path);
    else
      super.setCurrentDirectory(path);
  }

  @override
  Directory getSystemTempDirectory() {
    if (_getSystemTempDirectory != null) return _getSystemTempDirectory!();
    if (_previous != null) return _previous!.getSystemTempDirectory();
    return super.getSystemTempDirectory();
  }

  // File
  @override
  File createFile(String path) {
    if (_createFile != null) return _createFile!(path);
    if (_previous != null) return _previous!.createFile(path);
    return super.createFile(path);
  }

  // FileStat
  @override
  Future<FileStat> stat(String path) {
    if (_stat != null) return _stat!(path);
    if (_previous != null) return _previous!.stat(path);
    return super.stat(path);
  }

  @override
  FileStat statSync(String path) {
    if (_stat != null) return _statSync!(path);
    if (_previous != null) return _previous!.statSync(path);
    return super.statSync(path);
  }

  // FileSystemEntity
  @override
  Future<bool> fseIdentical(String path1, String path2) {
    if (_fseIdentical != null) return _fseIdentical!(path1, path2);
    if (_previous != null) return _previous!.fseIdentical(path1, path2);
    return super.fseIdentical(path1, path2);
  }

  @override
  bool fseIdenticalSync(String path1, String path2) {
    if (_fseIdenticalSync != null) return _fseIdenticalSync!(path1, path2);
    if (_previous != null) return _previous!.fseIdenticalSync(path1, path2);
    return super.fseIdenticalSync(path1, path2);
  }

  @override
  Future<FileSystemEntityType> fseGetType(String path, bool followLinks) {
    if (_fseGetType != null) return _fseGetType!(path, followLinks);
    if (_previous != null) return _previous!.fseGetType(path, followLinks);
    return super.fseGetType(path, followLinks);
  }

  @override
  FileSystemEntityType fseGetTypeSync(String path, bool followLinks) {
    if (_fseGetTypeSync != null) return _fseGetTypeSync!(path, followLinks);
    if (_previous != null) return _previous!.fseGetTypeSync(path, followLinks);
    return super.fseGetTypeSync(path, followLinks);
  }

  // _FileSystemWatcher
  @override
  Stream<FileSystemEvent> fsWatch(String path, int events, bool recursive) {
    if (_fsWatch != null) return _fsWatch!(path, events, recursive);
    if (_previous != null) return _previous!.fsWatch(path, events, recursive);
    return super.fsWatch(path, events, recursive);
  }

  @override
  bool fsWatchIsSupported() {
    if (_fsWatchIsSupported != null) return _fsWatchIsSupported!();
    if (_previous != null) return _previous!.fsWatchIsSupported();
    return super.fsWatchIsSupported();
  }

  // Link
  @override
  Link createLink(String path) {
    if (_createLink != null) return _createLink!(path);
    if (_previous != null) return _previous!.createLink(path);
    return super.createLink(path);
  }

  // Socket
  @override
  Future<Socket> socketConnect(host, int port,
      {sourceAddress, int sourcePort = 0, Duration? timeout}) {
    if (_socketConnect != null) {
      return _socketConnect!(host, port,
          sourceAddress: sourceAddress, timeout: timeout);
    }
    if (_previous != null) {
      return _previous!.socketConnect(host, port,
          sourceAddress: sourceAddress,
          sourcePort: sourcePort,
          timeout: timeout);
    }
    return super.socketConnect(host, port,
        sourceAddress: sourceAddress, sourcePort: sourcePort, timeout: timeout);
  }

  @override
  Future<ConnectionTask<Socket>> socketStartConnect(host, int port,
      {sourceAddress, int sourcePort = 0}) {
    if (_socketStartConnect != null) {
      return _socketStartConnect!(host, port,
          sourceAddress: sourceAddress, sourcePort: sourcePort);
    }
    if (_previous != null) {
      return _previous!.socketStartConnect(host, port,
          sourceAddress: sourceAddress, sourcePort: sourcePort);
    }
    return super.socketStartConnect(host, port,
        sourceAddress: sourceAddress, sourcePort: sourcePort);
  }

  // ServerSocket

  @override
  Future<ServerSocket> serverSocketBind(address, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false}) {
    if (_serverSocketBind != null) {
      return _serverSocketBind!(address, port,
          backlog: backlog, v6Only: v6Only, shared: shared);
    }
    if (_previous != null) {
      return _previous!.serverSocketBind(address, port,
          backlog: backlog, v6Only: v6Only, shared: shared);
    }
    return super.serverSocketBind(address, port,
        backlog: backlog, v6Only: v6Only, shared: shared);
  }

  // Standard streams

  @override
  Stdin get stdin {
    return _stdin?.call() ?? _previous?.stdin ?? super.stdin;
  }

  @override
  Stdout get stdout {
    return _stdout?.call() ?? _previous?.stdout ?? super.stdout;
  }

  @override
  Stdout get stderr {
    return _stderr?.call() ?? _previous?.stderr ?? super.stderr;
  }
}
