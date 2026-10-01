// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:path/path.dart' as pathos;

/// Cumulative measurements of calls to a resource provider operation.
class ResourceProviderTiming {
  int count = 0;
  Duration elapsed = Duration.zero;

  /// Bytes returned by successful `File.readAsBytesSync` calls.
  ///
  /// Text reads are delegated without additional I/O or re-encoding, so their
  /// byte counts are not available.
  int bytesRead = 0;
}

/// A provider that measures operations on resources from [baseProvider].
///
/// Measurements accumulate for the lifetime of this provider, including failed
/// calls. Place this below overlay or caching providers to exclude operations
/// satisfied in memory. Operations that only manipulate paths are not measured.
/// Watch timings cover synchronous watcher creation, not asynchronous watcher
/// initialization or background events. Composite operations such as copying
/// are measured as one call rather than counting their internal I/O again.
class TimingResourceProvider implements ResourceProvider {
  final ResourceProvider baseProvider;

  final Map<String, ResourceProviderTiming> _timings = {};

  TimingResourceProvider(this.baseProvider);

  @override
  pathos.Context get pathContext => baseProvider.pathContext;

  Map<String, ResourceProviderTiming> get timings => Map.unmodifiable(_timings);

  @override
  File getFile(String path) => _TimingFile(this, baseProvider.getFile(path));

  @override
  Folder getFolder(String path) =>
      _TimingFolder(this, baseProvider.getFolder(path));

  @override
  Link getLink(String path) => _TimingLink(this, baseProvider.getLink(path));

  @override
  Resource getResource(String path) => _wrap(
    _record(
      'ResourceProvider.getResource',
      () => baseProvider.getResource(path),
    ),
  );

  @override
  Folder? getStateLocation(String pluginId) {
    var folder = _record(
      'ResourceProvider.getStateLocation',
      () => baseProvider.getStateLocation(pluginId),
    );
    return folder != null ? _TimingFolder(this, folder) : null;
  }

  T _record<T>(String operation, T Function() action) {
    var timing = _timings.putIfAbsent(operation, ResourceProviderTiming.new);
    var stopwatch = Stopwatch()..start();
    try {
      return action();
    } finally {
      stopwatch.stop();
      timing.count++;
      timing.elapsed += stopwatch.elapsed;
    }
  }

  Resource _wrap(Resource resource) {
    if (resource is File) {
      return _TimingFile(this, resource);
    } else if (resource is Folder) {
      return _TimingFolder(this, resource);
    }
    throw ArgumentError('Unknown resource type: ${resource.runtimeType}');
  }
}

class _TimingFile extends _TimingResource implements File {
  _TimingFile(super.provider, File super.resource);

  @override
  int get lengthSync =>
      provider._record('File.lengthSync', () => _file.lengthSync);

  @override
  int get modificationStamp =>
      provider._record('File.modificationStamp', () => _file.modificationStamp);

  File get _file => _resource as File;

  @override
  File copyTo(Folder parentFolder) => _TimingFile(
    provider,
    provider._record('File.copyTo', () => _file.copyTo(_unwrap(parentFolder))),
  );

  @override
  Uint8List readAsBytesSync() {
    var bytes = provider._record('File.readAsBytesSync', _file.readAsBytesSync);
    provider._timings['File.readAsBytesSync']!.bytesRead += bytes.length;
    return bytes;
  }

  @override
  String readAsStringSync() =>
      provider._record('File.readAsStringSync', _file.readAsStringSync);

  @override
  File renameSync(String newPath) => _TimingFile(
    provider,
    provider._record('File.renameSync', () => _file.renameSync(newPath)),
  );

  @override
  void writeAsBytesSync(List<int> bytes) => provider._record(
    'File.writeAsBytesSync',
    () => _file.writeAsBytesSync(bytes),
  );

  @override
  void writeAsStringSync(String content) => provider._record(
    'File.writeAsStringSync',
    () => _file.writeAsStringSync(content),
  );
}

class _TimingFolder extends _TimingResource implements Folder {
  _TimingFolder(super.provider, Folder super.resource);

  @override
  bool get isRoot => _folder.isRoot;

  Folder get _folder => _resource as Folder;

  @override
  String canonicalizePath(String path) => _folder.canonicalizePath(path);

  @override
  bool contains(String path) => _folder.contains(path);

  @override
  Folder copyTo(Folder parentFolder) => _TimingFolder(
    provider,
    provider._record(
      'Folder.copyTo',
      () => _folder.copyTo(_unwrap(parentFolder)),
    ),
  );

  @override
  void create() => provider._record('Folder.create', _folder.create);

  @override
  Resource getChild(String relPath) => provider._wrap(
    provider._record('Folder.getChild', () => _folder.getChild(relPath)),
  );

  @Deprecated('Use getFile instead.')
  @override
  File getChildAssumingFile(String relPath) => getFile(relPath);

  @Deprecated('Use getFolder instead.')
  @override
  Folder getChildAssumingFolder(String relPath) => getFolder(relPath);

  @override
  List<Resource> getChildren() => provider
      ._record('Folder.getChildren', _folder.getChildren)
      .map(provider._wrap)
      .toList();

  @override
  File getFile(String relPath) =>
      _TimingFile(provider, _folder.getFile(relPath));

  @override
  Folder getFolder(String relPath) =>
      _TimingFolder(provider, _folder.getFolder(relPath));
}

class _TimingLink implements Link {
  final TimingResourceProvider _provider;
  final Link _link;

  _TimingLink(this._provider, this._link);

  @override
  bool get exists => _provider._record('Link.exists', () => _link.exists);

  @override
  void create(String target) =>
      _provider._record('Link.create', () => _link.create(target));
}

abstract class _TimingResource implements Resource {
  @override
  final TimingResourceProvider provider;

  final Resource _resource;

  _TimingResource(this.provider, this._resource);

  @override
  bool get exists => provider._record('$_kind.exists', () => _resource.exists);

  @override
  int get hashCode => _resource.hashCode;

  @override
  Folder get parent => _TimingFolder(provider, _resource.parent);

  @override
  String get path => _resource.path;

  @override
  String get shortName => _resource.shortName;

  String get _kind => _resource is File ? 'File' : 'Folder';

  @override
  bool operator ==(Object other) =>
      other is _TimingResource && _resource == other._resource;

  @override
  void delete() => provider._record('$_kind.delete', _resource.delete);

  @override
  bool isOrContains(String path) => _resource.isOrContains(path);

  @override
  Resource resolveSymbolicLinksSync() => provider._wrap(
    provider._record(
      '$_kind.resolveSymbolicLinksSync',
      _resource.resolveSymbolicLinksSync,
    ),
  );

  @override
  String toString() => _resource.toString();

  @override
  Uri toUri() => _resource.toUri();

  @override
  ResourceWatcher watch() => provider._record('$_kind.watch', _resource.watch);

  Folder _unwrap(Folder folder) =>
      folder is _TimingFolder ? folder._folder : folder;
}
