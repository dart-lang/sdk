// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data' show Uint8List;

import 'package:analyzer/file_system/file_system.dart';
// ignore: implementation_imports
import 'package:front_end/src/api_prototype/file_system.dart' as fe;

fe.FileSystem resourceProviderAsFileSystem(ResourceProvider rp) =>
    _ResourceProviderFileSystem(rp);

final class _ResourceProviderFileSystem implements fe.FileSystem {
  final ResourceProvider _rp;

  _ResourceProviderFileSystem(this._rp);

  @override
  fe.FileSystemEntity entityForUri(Uri uri) {
    final path = _rp.pathContext.canonicalize(_rp.pathContext.fromUri(uri));
    return _FileSystemEntity(_rp.pathContext.toUri(path), path, this);
  }
}

final class _FileSystemEntity implements fe.FileSystemEntity {
  final _ResourceProviderFileSystem _fs;
  final String _path;

  @override
  final Uri uri;

  _FileSystemEntity(this.uri, this._path, this._fs);

  @override
  bool operator ==(Object other) =>
      other is _FileSystemEntity &&
      other.uri == uri &&
      identical(other._fs, _fs);

  @override
  int get hashCode => uri.hashCode;

  @override
  Future<bool> exists() async => _fs._rp.getResource(_path).exists;

  @override
  Future<bool> existsAsyncIfPossible() async =>
      _fs._rp.getResource(_path).exists;

  @override
  Future<Uint8List> readAsBytes() async {
    try {
      return _fs._rp.getFile(_path).readAsBytesSync();
    } on FileSystemException catch (e) {
      throw fe.FileSystemException(uri, e.message);
    }
  }

  @override
  Future<Uint8List> readAsBytesAsyncIfPossible() async {
    try {
      return _fs._rp.getFile(_path).readAsBytesSync();
    } on FileSystemException catch (e) {
      throw fe.FileSystemException(uri, e.message);
    }
  }

  @override
  Future<String> readAsString() async {
    try {
      return _fs._rp.getFile(_path).readAsStringSync();
    } on FormatException catch (e) {
      throw fe.FileSystemException(uri, e.message);
    } on FileSystemException catch (e) {
      throw fe.FileSystemException(uri, e.message);
    }
  }
}
