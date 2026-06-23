// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:file/file.dart' as f;
import 'package:path/path.dart' as p;

f.FileSystem resourceProviderAsFileFileSystem(ResourceProvider rp) =>
    _ResourceProviderFileFileSystem(rp);

final class _ResourceProviderFileFileSystem extends f.FileSystem {
  final ResourceProvider _rp;

  _ResourceProviderFileFileSystem(this._rp);

  @override
  f.Directory directory(dynamic path) =>
      _ResourceProviderDirectory(this, getPath(path));

  @override
  f.File file(dynamic path) => _ResourceProviderFile(this, getPath(path));

  @override
  f.Link link(dynamic path) => _ResourceProviderLink(this, getPath(path));

  @override
  p.Context get path => _rp.pathContext;

  @override
  f.Directory get systemTempDirectory {
    final temp = _rp.getFolder('/tmp');
    if (!temp.exists) temp.create();
    return _ResourceProviderDirectory(this, temp.path);
  }

  @override
  f.Directory get currentDirectory =>
      _ResourceProviderDirectory(this, _rp.pathContext.current);

  @override
  set currentDirectory(dynamic path) =>
      throw UnsupportedError('setCurrentDirectory not supported');

  @override
  Future<io.FileStat> stat(String path) async => statSync(path);

  @override
  io.FileStat statSync(String path) {
    final absPath = _resolve(path);
    final resource = _rp.getResource(absPath);
    if (!resource.exists) {
      final link = _rp.getLink(absPath);
      if (link.exists) {
        return _FileStat(
          io.FileSystemEntityType.link,
          DateTime.now(),
          DateTime.now(),
          DateTime.now(),
          0777,
          0,
        );
      }
      return _FileStat.notFound;
    }

    var size = 0;
    var modified = 0;
    var type = io.FileSystemEntityType.notFound;

    if (resource is File) {
      type = io.FileSystemEntityType.file;
      try {
        size = resource.lengthSync;
        modified = resource.modificationStamp;
      } catch (_) {}
    } else if (resource is Folder) {
      type = io.FileSystemEntityType.directory;
    }

    final modifiedTime = DateTime.fromMillisecondsSinceEpoch(modified);

    return _FileStat(
      type,
      modifiedTime,
      modifiedTime,
      modifiedTime,
      0777,
      size,
    );
  }

  @override
  Future<bool> identical(String path1, String path2) async =>
      identicalSync(path1, path2);

  @override
  bool identicalSync(String path1, String path2) =>
      _resolve(path1) == _resolve(path2);

  @override
  bool get isWatchSupported => false;

  @override
  Future<io.FileSystemEntityType> type(
    String path, {
    bool followLinks = true,
  }) async => typeSync(path, followLinks: followLinks);

  @override
  io.FileSystemEntityType typeSync(String path, {bool followLinks = true}) {
    final absPath = _resolve(path);
    try {
      if (!followLinks) {
        if (_rp.getLink(absPath).exists) {
          return io.FileSystemEntityType.link;
        }
      }
      if (_rp.getFolder(absPath).exists) {
        return io.FileSystemEntityType.directory;
      }
      if (_rp.getFile(absPath).exists) {
        return io.FileSystemEntityType.file;
      }
      if (_rp.getLink(absPath).exists) {
        return io.FileSystemEntityType.link;
      }
    } catch (_) {}
    return io.FileSystemEntityType.notFound;
  }

  String _resolve(String path) {
    return _rp.pathContext.normalize(_rp.pathContext.absolute(path));
  }
}

class _FileStat implements io.FileStat {
  @override
  final DateTime accessed;
  @override
  final DateTime changed;
  @override
  final int mode;
  @override
  final DateTime modified;
  @override
  final int size;
  @override
  final io.FileSystemEntityType type;

  _FileStat(
    this.type,
    this.changed,
    this.modified,
    this.accessed,
    this.mode,
    this.size,
  );

  static final _FileStat notFound = _FileStat(
    io.FileSystemEntityType.notFound,
    DateTime.fromMillisecondsSinceEpoch(0),
    DateTime.fromMillisecondsSinceEpoch(0),
    DateTime.fromMillisecondsSinceEpoch(0),
    0,
    -1,
  );

  @override
  String modeString() {
    final permissions = mode & 0xFFF;
    const codes = ['---', '--x', '-w-', '-wx', 'r--', 'r-x', 'rw-', 'rwx'];
    final result = <String>[];
    if ((mode & 0x800) != 0) result.add('d');
    result.add(codes[(permissions >> 6) & 0x7]);
    result.add(codes[(permissions >> 3) & 0x7]);
    result.add(codes[permissions & 0x7]);
    return result.join();
  }
}

abstract class _ResourceProviderEntity implements f.FileSystemEntity {
  @override
  final _ResourceProviderFileFileSystem fileSystem;
  final String _path;

  _ResourceProviderEntity(this.fileSystem, this._path);

  Resource get _resource => fileSystem._rp.getResource(_path);

  @override
  String get path => _path;

  @override
  Uri get uri => _resource.toUri();

  @override
  bool get isAbsolute => fileSystem.path.isAbsolute(_path);

  @override
  f.Directory get parent =>
      fileSystem.directory(fileSystem.path.dirname(_path));

  @override
  String get dirname => fileSystem.path.dirname(_path);

  @override
  String get basename => fileSystem.path.basename(_path);

  @override
  Future<f.FileSystemEntity> delete({bool recursive = false}) async {
    deleteSync(recursive: recursive);
    return this;
  }

  @override
  void deleteSync({bool recursive = false}) {
    try {
      _resource.delete();
    } catch (e) {
      throw io.FileSystemException(e.toString(), _path);
    }
  }

  @override
  Future<bool> exists() async => existsSync();

  @override
  Future<io.FileStat> stat() => fileSystem.stat(_path);

  @override
  io.FileStat statSync() => fileSystem.statSync(_path);

  @override
  Future<String> resolveSymbolicLinks() async => resolveSymbolicLinksSync();

  @override
  String resolveSymbolicLinksSync() {
    return _resource.resolveSymbolicLinksSync().path;
  }

  @override
  Stream<io.FileSystemEvent> watch({
    int events = io.FileSystemEvent.all,
    bool recursive = false,
  }) {
    return const Stream.empty();
  }
}

class _ResourceProviderFile extends _ResourceProviderEntity implements f.File {
  _ResourceProviderFile(super.fileSystem, super.path);

  File get _file => fileSystem._rp.getFile(_path);

  @override
  bool existsSync() =>
      fileSystem.typeSync(path) == io.FileSystemEntityType.file;

  @override
  f.File get absolute => fileSystem.file(fileSystem.path.absolute(_path));

  @override
  Future<f.File> copy(String newPath) async => copySync(newPath);

  @override
  f.File copySync(String newPath) {
    final dest = fileSystem._rp.getFile(fileSystem._resolve(newPath));
    try {
      dest.writeAsBytesSync(_file.readAsBytesSync());
      return _ResourceProviderFile(fileSystem, dest.path);
    } catch (e) {
      throw io.FileSystemException(e.toString(), path);
    }
  }

  @override
  Future<f.File> create({
    bool recursive = false,
    bool exclusive = false,
  }) async {
    createSync(recursive: recursive, exclusive: exclusive);
    return this;
  }

  @override
  void createSync({bool recursive = false, bool exclusive = false}) {
    if (exclusive && _file.exists) {
      throw io.FileSystemException('File already exists', path);
    }
    if (recursive) {
      _file.parent.create();
    }
    if (!_file.exists) {
      _file.writeAsBytesSync([]);
    }
  }

  @override
  Future<int> length() async => lengthSync();

  @override
  int lengthSync() {
    try {
      return _file.lengthSync;
    } catch (e) {
      throw io.FileSystemException(e.toString(), path);
    }
  }

  @override
  Future<DateTime> lastAccessed() async => lastAccessedSync();

  @override
  DateTime lastAccessedSync() => lastModifiedSync();

  @override
  Future<DateTime> lastModified() async => lastModifiedSync();

  @override
  DateTime lastModifiedSync() {
    try {
      return DateTime.fromMillisecondsSinceEpoch(_file.modificationStamp);
    } catch (e) {
      throw io.FileSystemException(e.toString(), path);
    }
  }

  @override
  Future<io.RandomAccessFile> open({
    io.FileMode mode = io.FileMode.read,
  }) async => openSync(mode: mode);

  @override
  io.RandomAccessFile openSync({io.FileMode mode = io.FileMode.read}) {
    return _MemoryRandomAccessFile(_file, path, mode);
  }

  @override
  Stream<List<int>> openRead([int? start, int? end]) {
    try {
      var bytes = _file.readAsBytesSync();
      if (start != null) {
        end ??= bytes.length;
        bytes = bytes.sublist(start, end);
      }
      return Stream.value(bytes);
    } catch (e) {
      return Stream.error(io.FileSystemException(e.toString(), path));
    }
  }

  @override
  io.IOSink openWrite({
    io.FileMode mode = io.FileMode.write,
    Encoding encoding = utf8,
  }) {
    return _FileIOSink(this, mode: mode, encoding: encoding);
  }

  @override
  Future<Uint8List> readAsBytes() async => readAsBytesSync();

  @override
  Uint8List readAsBytesSync() {
    try {
      return _file.readAsBytesSync();
    } catch (e) {
      throw io.FileSystemException(e.toString(), path);
    }
  }

  @override
  Future<List<String>> readAsLines({Encoding encoding = utf8}) async =>
      readAsLinesSync(encoding: encoding);

  @override
  List<String> readAsLinesSync({Encoding encoding = utf8}) {
    return readAsStringSync(encoding: encoding).split('\n');
  }

  @override
  Future<String> readAsString({Encoding encoding = utf8}) async =>
      readAsStringSync(encoding: encoding);

  @override
  String readAsStringSync({Encoding encoding = utf8}) {
    try {
      if (encoding == utf8) {
        return _file.readAsStringSync();
      }
      return encoding.decode(_file.readAsBytesSync());
    } catch (e) {
      throw io.FileSystemException(e.toString(), path);
    }
  }

  @override
  Future<f.File> rename(String newPath) async => renameSync(newPath);

  @override
  f.File renameSync(String newPath) {
    try {
      final renamed = _file.renameSync(fileSystem._resolve(newPath));
      return _ResourceProviderFile(fileSystem, renamed.path);
    } catch (e) {
      throw io.FileSystemException(e.toString(), path);
    }
  }

  @override
  Future setLastAccessed(DateTime time) async {}

  @override
  void setLastAccessedSync(DateTime time) {}

  @override
  Future setLastModified(DateTime time) async {}

  @override
  void setLastModifiedSync(DateTime time) {}

  @override
  Future<f.File> writeAsBytes(
    List<int> bytes, {
    io.FileMode mode = io.FileMode.write,
    bool flush = false,
  }) async {
    writeAsBytesSync(bytes, mode: mode, flush: flush);
    return this;
  }

  @override
  void writeAsBytesSync(
    List<int> bytes, {
    io.FileMode mode = io.FileMode.write,
    bool flush = false,
  }) {
    try {
      if (mode == io.FileMode.writeOnly || mode == io.FileMode.write) {
        _file.writeAsBytesSync(bytes);
      } else if (mode == io.FileMode.append ||
          mode == io.FileMode.writeOnlyAppend) {
        final builder = BytesBuilder(copy: false);
        if (_file.exists) builder.add(_file.readAsBytesSync());
        builder.add(bytes);
        _file.writeAsBytesSync(builder.takeBytes());
      }
    } catch (e) {
      throw io.FileSystemException(e.toString(), path);
    }
  }

  @override
  Future<f.File> writeAsString(
    String contents, {
    io.FileMode mode = io.FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) async {
    writeAsStringSync(contents, mode: mode, encoding: encoding, flush: flush);
    return this;
  }

  @override
  void writeAsStringSync(
    String contents, {
    io.FileMode mode = io.FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) {
    try {
      if (mode == io.FileMode.writeOnly || mode == io.FileMode.write) {
        _file.writeAsStringSync(contents);
      } else if (mode == io.FileMode.append ||
          mode == io.FileMode.writeOnlyAppend) {
        final current = _file.exists ? _file.readAsStringSync() : '';
        _file.writeAsStringSync(current + contents);
      }
    } catch (e) {
      throw io.FileSystemException(e.toString(), path);
    }
  }
}

class _ResourceProviderDirectory extends _ResourceProviderEntity
    implements f.Directory {
  _ResourceProviderDirectory(super.fileSystem, super.path);

  Folder get _folder => fileSystem._rp.getFolder(_path);

  @override
  bool existsSync() =>
      fileSystem.typeSync(path) == io.FileSystemEntityType.directory;

  @override
  f.Directory get absolute =>
      fileSystem.directory(fileSystem.path.absolute(_path));

  @override
  Future<f.Directory> create({bool recursive = false}) async {
    createSync(recursive: recursive);
    return this;
  }

  @override
  void createSync({bool recursive = false}) {
    try {
      if (recursive) {
        var current = _folder;
        while (!current.exists && !current.isRoot) {
          current = current.parent;
        }
        var pathParts = fileSystem.path.split(_path);
        var currPath = pathParts[0];
        for (var i = 1; i < pathParts.length; i++) {
          currPath = fileSystem.path.join(currPath, pathParts[i]);
          fileSystem._rp.getFolder(currPath).create();
        }
      } else {
        _folder.create();
      }
    } catch (e) {
      throw io.FileSystemException(e.toString(), path);
    }
  }

  @override
  Future<f.Directory> createTemp([String? prefix]) async =>
      createTempSync(prefix);

  @override
  f.Directory createTempSync([String? prefix]) {
    var i = 0;
    while (true) {
      var name = "${prefix ?? 'temp'}_$i";
      var temp = _folder.getFolder(name);
      if (!temp.exists) {
        temp.create();
        return _ResourceProviderDirectory(fileSystem, temp.path);
      }
      i++;
    }
  }

  @override
  Stream<f.FileSystemEntity> list({
    bool recursive = false,
    bool followLinks = true,
  }) {
    var controller = StreamController<f.FileSystemEntity>();
    _listRecursive(controller, _folder, recursive, followLinks);
    controller.close();
    return controller.stream;
  }

  void _listRecursive(
    StreamController<f.FileSystemEntity> controller,
    Folder folder,
    bool recursive,
    bool followLinks,
  ) {
    try {
      for (var child in folder.getChildren()) {
        if (child is File) {
          controller.add(_ResourceProviderFile(fileSystem, child.path));
        } else if (child is Folder) {
          var dir = _ResourceProviderDirectory(fileSystem, child.path);
          controller.add(dir);
          if (recursive) {
            _listRecursive(controller, child, recursive, followLinks);
          }
        }
      }
    } catch (e) {
      controller.addError(io.FileSystemException(e.toString(), folder.path));
    }
  }

  @override
  List<f.FileSystemEntity> listSync({
    bool recursive = false,
    bool followLinks = true,
  }) {
    var result = <f.FileSystemEntity>[];
    _listRecursiveSync(result, _folder, recursive, followLinks);
    return result;
  }

  void _listRecursiveSync(
    List<f.FileSystemEntity> result,
    Folder folder,
    bool recursive,
    bool followLinks,
  ) {
    try {
      for (var child in folder.getChildren()) {
        if (child is File) {
          result.add(_ResourceProviderFile(fileSystem, child.path));
        } else if (child is Folder) {
          var dir = _ResourceProviderDirectory(fileSystem, child.path);
          result.add(dir);
          if (recursive) {
            _listRecursiveSync(result, child, recursive, followLinks);
          }
        }
      }
    } catch (e) {
      throw io.FileSystemException(e.toString(), folder.path);
    }
  }

  @override
  Future<f.Directory> rename(String newPath) async => renameSync(newPath);

  @override
  f.Directory renameSync(String newPath) {
    final destPath = fileSystem._resolve(newPath);
    final destFolder = fileSystem._rp.getFolder(destPath);

    _copyFolderSync(_folder, destFolder);
    try {
      _folder.delete();
    } catch (_) {}

    return _ResourceProviderDirectory(fileSystem, destFolder.path);
  }

  void _copyFolderSync(Folder source, Folder dest) {
    if (!dest.exists) {
      dest.create();
    }
    for (final child in source.getChildren()) {
      if (child is File) {
        final destFile = dest.getFile(child.shortName);
        destFile.writeAsBytesSync(child.readAsBytesSync());
      } else if (child is Folder) {
        final destChild = dest.getFolder(child.shortName);
        _copyFolderSync(child, destChild);
      }
    }
  }

  @override
  f.Directory childDirectory(String basename) =>
      fileSystem.directory(fileSystem.path.join(_path, basename));

  @override
  f.File childFile(String basename) =>
      fileSystem.file(fileSystem.path.join(_path, basename));

  @override
  f.Link childLink(String basename) =>
      fileSystem.link(fileSystem.path.join(_path, basename));
}

class _ResourceProviderLink extends _ResourceProviderEntity implements f.Link {
  _ResourceProviderLink(super.fileSystem, super.path);

  Link get _link => fileSystem._rp.getLink(_path);

  @override
  bool existsSync() =>
      fileSystem.typeSync(path, followLinks: false) ==
      io.FileSystemEntityType.link;

  @override
  f.Link get absolute => fileSystem.link(fileSystem.path.absolute(_path));

  @override
  Future<f.Link> create(String target, {bool recursive = false}) async {
    createSync(target, recursive: recursive);
    return this;
  }

  @override
  void createSync(String target, {bool recursive = false}) {
    if (recursive) {
      fileSystem._rp.getFolder(fileSystem.path.dirname(_path)).create();
    }
    _link.create(target);
  }

  @override
  Future<f.Link> rename(String newPath) async => renameSync(newPath);

  @override
  f.Link renameSync(String newPath) {
    throw io.FileSystemException('Rename not supported for links', _path);
  }

  @override
  Future<String> target() async => targetSync();

  @override
  String targetSync() {
    throw io.FileSystemException('Cannot read link target', _path);
  }

  @override
  Future<f.Link> update(String target) async {
    updateSync(target);
    return this;
  }

  @override
  void updateSync(String target) {
    createSync(target);
  }
}

class _FileIOSink implements io.IOSink {
  final _ResourceProviderFile _file;
  final io.FileMode _mode;
  final Encoding _encoding;
  final BytesBuilder _buffer = BytesBuilder();
  bool _closed = false;

  _FileIOSink(
    this._file, {
    required io.FileMode mode,
    required Encoding encoding,
  }) : _mode = mode,
       _encoding = encoding;

  @override
  Encoding get encoding => _encoding;

  @override
  set encoding(Encoding value) {
    throw UnsupportedError('Changing encoding not supported');
  }

  @override
  void add(List<int> data) {
    if (_closed) throw StateError('Sink closed');
    _buffer.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future addStream(Stream<List<int>> stream) async {
    await stream.forEach(add);
  }

  @override
  Future close() async {
    if (_closed) return;
    _closed = true;
    _flushSync();
  }

  @override
  Future get done => Future.value();

  @override
  Future flush() async {
    _flushSync();
  }

  void _flushSync() {
    if (_buffer.isEmpty) return;
    _file.writeAsBytesSync(_buffer.takeBytes(), mode: _mode);
  }

  @override
  void write(Object? object) {
    final string = '$object';
    add(_encoding.encode(string));
  }

  @override
  void writeAll(Iterable objects, [String separator = '']) {
    var iterator = objects.iterator;
    if (!iterator.moveNext()) return;
    if (separator.isEmpty) {
      do {
        write(iterator.current);
      } while (iterator.moveNext());
    } else {
      write(iterator.current);
      while (iterator.moveNext()) {
        write(separator);
        write(iterator.current);
      }
    }
  }

  @override
  void writeCharCode(int charCode) {
    write(String.fromCharCode(charCode));
  }

  @override
  void writeln([Object? object = '']) {
    write(object);
    write('\n');
  }

  String lineTerminator = '\n';
}

class _MemoryRandomAccessFile implements io.RandomAccessFile {
  final File _file;
  final String _path;
  final io.FileMode _mode;
  List<int> _data = [];
  int _position = 0;
  bool _closed = false;

  _MemoryRandomAccessFile(this._file, this._path, this._mode) {
    if (_file.exists) {
      _data = _file.readAsBytesSync().toList();
    }
    if (_mode == io.FileMode.write || _mode == io.FileMode.writeOnly) {
      _data = [];
      _position = 0;
    } else if (_mode == io.FileMode.append ||
        _mode == io.FileMode.writeOnlyAppend) {
      _position = _data.length;
    } else {
      _position = 0;
    }
  }

  void _checkOpen() {
    if (_closed) throw io.FileSystemException('File closed', _path);
  }

  @override
  Future<io.RandomAccessFile> close() async {
    closeSync();
    return this;
  }

  @override
  void closeSync() {
    _checkOpen();
    _closed = true;
    _flush();
  }

  void _flush() {
    if (_mode == io.FileMode.read) return;
    _file.writeAsBytesSync(_data);
  }

  @override
  Future<io.RandomAccessFile> flush() async {
    flushSync();
    return this;
  }

  @override
  void flushSync() {
    _checkOpen();
    _flush();
  }

  @override
  Future<int> length() async => lengthSync();

  @override
  int lengthSync() {
    _checkOpen();
    return _data.length;
  }

  @override
  Future<io.RandomAccessFile> lock([
    io.FileLock mode = io.FileLock.exclusive,
    int start = 0,
    int end = -1,
  ]) async => this;

  @override
  void lockSync([
    io.FileLock mode = io.FileLock.exclusive,
    int start = 0,
    int end = -1,
  ]) {}

  @override
  Future<io.RandomAccessFile> unlock([int start = 0, int end = -1]) async =>
      this;

  @override
  void unlockSync([int start = 0, int end = -1]) {}

  @override
  Future<int> position() async => positionSync();

  @override
  int positionSync() {
    _checkOpen();
    return _position;
  }

  @override
  Future<Uint8List> read(int bytes) async =>
      Uint8List.fromList(readSync(bytes));

  @override
  Uint8List readSync(int bytes) {
    _checkOpen();
    if (_position >= _data.length) return Uint8List(0);
    var end = _position + bytes;
    if (end > _data.length) end = _data.length;
    var result = Uint8List.fromList(_data.sublist(_position, end));
    _position = end;
    return result;
  }

  @override
  Future<int> readByte() async => readByteSync();

  @override
  int readByteSync() {
    _checkOpen();
    if (_position >= _data.length) return -1;
    return _data[_position++];
  }

  @override
  Future<io.RandomAccessFile> setPosition(int position) async {
    setPositionSync(position);
    return this;
  }

  @override
  void setPositionSync(int position) {
    _checkOpen();
    _position = position;
  }

  @override
  Future<io.RandomAccessFile> truncate(int length) async {
    truncateSync(length);
    return this;
  }

  @override
  void truncateSync(int length) {
    _checkOpen();
    if (length < _data.length) {
      _data = _data.sublist(0, length);
      if (_position > length) _position = length;
    } else if (length > _data.length) {
      _data.addAll(List.filled(length - _data.length, 0));
    }
    _flush();
  }

  @override
  Future<io.RandomAccessFile> writeByte(int value) async {
    writeByteSync(value);
    return this;
  }

  @override
  int writeByteSync(int value) {
    _checkOpen();
    if (_position < _data.length) {
      _data[_position] = value;
    } else {
      _data.add(value);
    }
    _position++;
    return 1;
  }

  @override
  Future<io.RandomAccessFile> writeFrom(
    List<int> buffer, [
    int start = 0,
    int? end,
  ]) async {
    writeFromSync(buffer, start, end);
    return this;
  }

  @override
  void writeFromSync(List<int> buffer, [int start = 0, int? end]) {
    _checkOpen();
    end ??= buffer.length;
    for (var i = start; i < end; i++) {
      writeByteSync(buffer[i]);
    }
  }

  @override
  Future<io.RandomAccessFile> writeString(
    String string, {
    Encoding encoding = utf8,
  }) async {
    writeStringSync(string, encoding: encoding);
    return this;
  }

  @override
  void writeStringSync(String string, {Encoding encoding = utf8}) {
    writeFromSync(encoding.encode(string));
  }

  @override
  String get path => _path;

  @override
  Future<int> readInto(List<int> buffer, [int start = 0, int? end]) async {
    return readIntoSync(buffer, start, end);
  }

  @override
  int readIntoSync(List<int> buffer, [int start = 0, int? end]) {
    _checkOpen();
    end ??= buffer.length;
    if (end > buffer.length) end = buffer.length;
    var count = end - start;
    if (count <= 0) return 0;

    var available = _data.length - _position;
    var toRead = count < available ? count : available;
    if (toRead <= 0) return 0;

    for (var i = 0; i < toRead; i++) {
      buffer[start + i] = _data[_position + i];
    }
    _position += toRead;
    return toRead;
  }
}
