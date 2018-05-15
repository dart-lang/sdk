// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "common_patch.dart";

@patch
class FileStat {
  @patch
  static _statSync(_Namespace namespace, String path) native "File_Stat";
}

@patch
class FileSystemEntity {
  @patch
  static _getTypeNative(_Namespace namespace, Uint8List rawPath,
      bool followLinks) native "File_GetType";
  @patch
  static _identicalNative(_Namespace namespace, String path1, String path2)
      native "File_AreIdentical";
  @patch
  static _resolveSymbolicLinks(_Namespace namespace, _Path path)
      native "File_ResolveSymbolicLinks";
}

@patch
class _Path {
  @patch
  factory _Path(String path) => new _PathImpl(path);
  @patch
  factory _Path.fromRawPath(Uint8List rawPath) =>
      new _PathImpl.fromRawPath(rawPath);

  Uint8List get _rawPath;
}

class _PathImpl extends NativeFieldWrapperClass1 implements _Path {
  _setRawPathNative(Uint8List rawPath) native "Path_SetRawPath";
  _getRawPathNative() native "Path_GetRawPath";

  _PathImpl.fromRawPath(Uint8List rawPath) {
    if (rawPath is! Uint8List) {
      throw new ArgumentError('rawPath must be a Uint8List but was '
          '${rawPath.runtimeType}');
    }
    final tmp = rawPath.toList();
    // Since we're just setting _cachedRawPath here instead of in native land,
    // we need to make sure this raw path is null terminated.
    if (tmp.isEmpty || (tmp.last != 0)) {
      tmp.add(0);
    }
    _cachedRawPath = new Uint8List.fromList(tmp);
    _setRawPathNative(rawPath);
  }

  factory _PathImpl(String path) =>
      new _PathImpl.fromRawPath(new Uint8List.fromList(utf8.encode(path)))
        .._cachedPath = path;

  UnmodifiableUint8ListView get rawPath {
    // We added a null terminator in native land to ensure that the raw path
    // is a properly terminated string, which we need to remove here.
    final tmp = _rawPath.buffer.asUint8List(0, _rawPath.length - 1);
    return new UnmodifiableUint8ListView(tmp);
  }

  // allowMalformed replaces invalid UTF-8 characters with '�'.
  String get path {
    _cachedPath ??= utf8.decode(rawPath, allowMalformed: true);
    return _cachedPath;
  }

  Uint8List get _rawPath {
    // We don't remove the null terminator from our private raw path getter
    // since it is passed to native code directly and should be null
    // terminated.
    _cachedRawPath ??= _getRawPathNative();
    return _cachedRawPath;
  }

  Uint8List _cachedRawPath;
  String _cachedPath;
}
