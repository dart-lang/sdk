// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:path/path.dart' as pathos;

/// A resource-provider operation measured by [TimingResourceProvider].
///
/// Values of this enum are the keys of [TimingResourceProvider.timings].
/// [label] is the operation name shown on the File I/O timing page.
enum ResourceProviderOperation {
  fileCopyTo('File.copyTo'),
  fileDelete('File.delete'),
  fileExists('File.exists'),
  fileLengthSync('File.lengthSync'),
  fileModificationStamp('File.modificationStamp'),
  fileReadAsBytesSync('File.readAsBytesSync'),
  fileReadAsStringSync('File.readAsStringSync'),
  fileRenameSync('File.renameSync'),
  fileResolveSymbolicLinksSync('File.resolveSymbolicLinksSync'),
  fileWatch('File.watch'),
  fileWriteAsBytesSync('File.writeAsBytesSync'),
  fileWriteAsStringSync('File.writeAsStringSync'),
  folderCopyTo('Folder.copyTo'),
  folderCreate('Folder.create'),
  folderDelete('Folder.delete'),
  folderExists('Folder.exists'),
  folderGetChild('Folder.getChild'),
  folderGetChildren('Folder.getChildren'),
  folderResolveSymbolicLinksSync('Folder.resolveSymbolicLinksSync'),
  folderWatch('Folder.watch'),
  linkCreate('Link.create'),
  linkExists('Link.exists'),
  resourceGetResource('ResourceProvider.getResource'),
  resourceGetStateLocation('ResourceProvider.getStateLocation');

  /// The operation name, such as `File.readAsBytesSync`.
  final String label;

  const ResourceProviderOperation(this.label);
}

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

  final Map<ResourceProviderOperation, ResourceProviderTiming> _timings = {};

  /// The number of active [withoutMeasuring] calls; nested calls are allowed.
  int _suspendedDepth = 0;

  TimingResourceProvider(this.baseProvider);

  @override
  pathos.Context get pathContext => baseProvider.pathContext;

  /// Measurements for each [ResourceProviderOperation], accumulated since this
  /// provider was created.
  Map<ResourceProviderOperation, ResourceProviderTiming> get timings =>
      Map.unmodifiable(_timings);

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
      ResourceProviderOperation.resourceGetResource,
      () => baseProvider.getResource(path),
    ),
  );

  @override
  Folder? getStateLocation(String pluginId) {
    var folder = _record(
      ResourceProviderOperation.resourceGetStateLocation,
      () => baseProvider.getStateLocation(pluginId),
    );
    return folder != null ? _TimingFolder(this, folder) : null;
  }

  /// Runs [operation] without measuring the resource operations it performs.
  ///
  /// This is intended for diagnostics that would otherwise distort the
  /// measurements they display.
  ///
  /// The [operation] must be synchronous. While it runs, no other code in this
  /// isolate can use this provider, so only operations performed by
  /// [operation] itself are excluded. Suspending measurements across an
  /// asynchronous gap would also hide unrelated operations.
  T withoutMeasuring<T>(T Function() operation) {
    _suspendedDepth++;
    try {
      var result = operation();
      assert(
        result is! Future,
        'The operation passed to withoutMeasuring must be synchronous.',
      );
      return result;
    } finally {
      _suspendedDepth--;
    }
  }

  /// Runs [action], recording it as a call to [operation].
  ///
  /// If [bytesRead] is provided, it computes the number of bytes returned by a
  /// successful [action].
  T _record<T>(
    ResourceProviderOperation operation,
    T Function() action, {
    int Function(T result)? bytesRead,
  }) {
    if (_suspendedDepth > 0) {
      return action();
    }

    var timing = _timings.putIfAbsent(operation, ResourceProviderTiming.new);
    var stopwatch = Stopwatch()..start();
    try {
      var result = action();
      if (bytesRead != null) {
        timing.bytesRead += bytesRead(result);
      }
      return result;
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
  int get lengthSync => provider._record(
    ResourceProviderOperation.fileLengthSync,
    () => _file.lengthSync,
  );

  @override
  int get modificationStamp => provider._record(
    ResourceProviderOperation.fileModificationStamp,
    () => _file.modificationStamp,
  );

  File get _file => _resource as File;

  @override
  File copyTo(Folder parentFolder) => _TimingFile(
    provider,
    provider._record(
      ResourceProviderOperation.fileCopyTo,
      () => _file.copyTo(_unwrap(parentFolder)),
    ),
  );

  @override
  Uint8List readAsBytesSync() => provider._record(
    ResourceProviderOperation.fileReadAsBytesSync,
    _file.readAsBytesSync,
    bytesRead: (bytes) => bytes.length,
  );

  @override
  String readAsStringSync() => provider._record(
    ResourceProviderOperation.fileReadAsStringSync,
    _file.readAsStringSync,
  );

  @override
  File renameSync(String newPath) => _TimingFile(
    provider,
    provider._record(
      ResourceProviderOperation.fileRenameSync,
      () => _file.renameSync(newPath),
    ),
  );

  @override
  void writeAsBytesSync(List<int> bytes) => provider._record(
    ResourceProviderOperation.fileWriteAsBytesSync,
    () => _file.writeAsBytesSync(bytes),
  );

  @override
  void writeAsStringSync(String content) => provider._record(
    ResourceProviderOperation.fileWriteAsStringSync,
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
      ResourceProviderOperation.folderCopyTo,
      () => _folder.copyTo(_unwrap(parentFolder)),
    ),
  );

  @override
  void create() =>
      provider._record(ResourceProviderOperation.folderCreate, _folder.create);

  @override
  Resource getChild(String relPath) => provider._wrap(
    provider._record(
      ResourceProviderOperation.folderGetChild,
      () => _folder.getChild(relPath),
    ),
  );

  @Deprecated('Use getFile instead.')
  @override
  File getChildAssumingFile(String relPath) => getFile(relPath);

  @Deprecated('Use getFolder instead.')
  @override
  Folder getChildAssumingFolder(String relPath) => getFolder(relPath);

  @override
  List<Resource> getChildren() => provider
      ._record(ResourceProviderOperation.folderGetChildren, _folder.getChildren)
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
  bool get exists => _provider._record(
    ResourceProviderOperation.linkExists,
    () => _link.exists,
  );

  @override
  void create(String target) => _provider._record(
    ResourceProviderOperation.linkCreate,
    () => _link.create(target),
  );
}

abstract class _TimingResource implements Resource {
  @override
  final TimingResourceProvider provider;

  final Resource _resource;

  _TimingResource(this.provider, this._resource);

  @override
  bool get exists => provider._record(
    _operation(
      ResourceProviderOperation.fileExists,
      ResourceProviderOperation.folderExists,
    ),
    () => _resource.exists,
  );

  @override
  int get hashCode => _resource.hashCode;

  @override
  Folder get parent => _TimingFolder(provider, _resource.parent);

  @override
  String get path => _resource.path;

  @override
  String get shortName => _resource.shortName;

  @override
  bool operator ==(Object other) =>
      other is _TimingResource && _resource == other._resource;

  @override
  void delete() => provider._record(
    _operation(
      ResourceProviderOperation.fileDelete,
      ResourceProviderOperation.folderDelete,
    ),
    _resource.delete,
  );

  @override
  bool isOrContains(String path) => _resource.isOrContains(path);

  @override
  Resource resolveSymbolicLinksSync() => provider._wrap(
    provider._record(
      _operation(
        ResourceProviderOperation.fileResolveSymbolicLinksSync,
        ResourceProviderOperation.folderResolveSymbolicLinksSync,
      ),
      _resource.resolveSymbolicLinksSync,
    ),
  );

  @override
  String toString() => _resource.toString();

  @override
  Uri toUri() => _resource.toUri();

  @override
  ResourceWatcher watch() => provider._record(
    _operation(
      ResourceProviderOperation.fileWatch,
      ResourceProviderOperation.folderWatch,
    ),
    _resource.watch,
  );

  ResourceProviderOperation _operation(
    ResourceProviderOperation fileOperation,
    ResourceProviderOperation folderOperation,
  ) => _resource is File ? fileOperation : folderOperation;

  Folder _unwrap(Folder folder) =>
      folder is _TimingFolder ? folder._folder : folder;
}
