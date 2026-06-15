// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:path/path.dart' as p;

ResourceProvider resourceProviderWithCurrentWorkingDirectory(
  ResourceProvider rp,
  String cwd,
) => _OverridePathContextResourceProvider(
  rp,
  p.Context(style: rp.pathContext.style, current: cwd),
);

final class _OverridePathContextResourceProvider implements ResourceProvider {
  final ResourceProvider _rp;

  _OverridePathContextResourceProvider(this._rp, this.pathContext);

  @override
  File getFile(String path) => _File(
    _rp.getFile(pathContext.normalize(pathContext.absolute(path))),
    this,
  );

  @override
  Folder getFolder(String path) => _Folder(
    _rp.getFolder(pathContext.normalize(pathContext.absolute(path))),
    this,
  );

  @override
  Resource getResource(String path) =>
      _wrap(_rp.getResource(pathContext.normalize(pathContext.absolute(path))));

  @override
  Folder? getStateLocation(String pluginId) {
    final r = _rp.getStateLocation(pluginId);
    if (r == null) {
      return null;
    }
    return _Folder(r, this);
  }

  @override
  final p.Context pathContext;

  @override
  String toString() => _rp.toString();

  Resource _wrap(Resource r) {
    if (r is File) {
      return _File(r, this);
    }
    if (r is Folder) {
      return _Folder(r, this);
    }
    throw AssertionError('Resource must be File or Folder');
  }

  @override
  Link getLink(String path) {
    return _rp.getLink(pathContext.normalize(pathContext.absolute(path)));
  }
}

final class _File implements File {
  final File _r;
  final _OverridePathContextResourceProvider _rp;

  _File(this._r, this._rp);

  @override
  File copyTo(Folder parentFolder) => _File(_r.copyTo(parentFolder), _rp);

  @override
  void delete() => _r.delete();

  @override
  bool get exists => _r.exists;

  @override
  bool isOrContains(String path) => _r.isOrContains(path);

  @override
  int get lengthSync => _r.lengthSync;

  @override
  int get modificationStamp => _r.modificationStamp;

  @override
  Folder get parent => _Folder(_r.parent, _rp);

  @override
  String get path => _r.path;

  @override
  ResourceProvider get provider => _rp;

  @override
  Uint8List readAsBytesSync() => _r.readAsBytesSync();

  @override
  String readAsStringSync() => _r.readAsStringSync();

  @override
  File renameSync(String newPath) => _File(_r.renameSync(newPath), _rp);

  @override
  Resource resolveSymbolicLinksSync() =>
      _rp._wrap(_r.resolveSymbolicLinksSync());

  @override
  String get shortName => _r.shortName;

  @override
  Uri toUri() => _r.toUri();

  @override
  ResourceWatcher watch() => _r.watch();

  @override
  void writeAsBytesSync(List<int> bytes) => _r.writeAsBytesSync(bytes);

  @override
  void writeAsStringSync(String content) => _r.writeAsStringSync(content);

  @override
  String toString() => _r.toString();
}

final class _Folder implements Folder {
  final Folder _r;
  final _OverridePathContextResourceProvider _rp;

  _Folder(this._r, this._rp);

  @override
  String canonicalizePath(String path) => _r.canonicalizePath(path);

  @override
  bool contains(String path) => _r.contains(path);

  @override
  Folder copyTo(Folder parentFolder) => _Folder(_r.copyTo(parentFolder), _rp);

  @override
  void create() => _r.create();

  @override
  void delete() => _r.delete();

  @override
  bool get exists => _r.exists;

  @override
  Resource getChild(String relPath) => _rp._wrap(_r.getChild(relPath));

  @override
  File getFile(String relPath) => _File(_r.getFile(relPath), _rp);

  @Deprecated('Use getFile instead.')
  @override
  File getChildAssumingFile(String relPath) {
    return getFile(relPath);
  }

  @override
  Folder getFolder(String relPath) => _Folder(_r.getFolder(relPath), _rp);

  @Deprecated('Use getFolder instead.')
  @override
  Folder getChildAssumingFolder(String relPath) {
    return getFolder(relPath);
  }

  @override
  List<Resource> getChildren() => _r.getChildren().map(_rp._wrap).toList();

  @override
  bool isOrContains(String path) => _r.isOrContains(path);

  @override
  bool get isRoot => _r.isRoot;

  @override
  Folder get parent => _Folder(_r.parent, _rp);

  @override
  String get path => _r.path;

  @override
  ResourceProvider get provider => _rp;

  @override
  Resource resolveSymbolicLinksSync() =>
      _rp._wrap(_r.resolveSymbolicLinksSync());

  @override
  String get shortName => _r.shortName;

  @override
  Uri toUri() => _r.toUri();

  @override
  ResourceWatcher watch() => _r.watch();

  @override
  String toString() => _r.toString();
}
