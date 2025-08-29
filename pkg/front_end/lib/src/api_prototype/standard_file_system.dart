// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library front_end.standard_file_system;

import 'dart:io' as io;
import 'dart:typed_data';

import '../base/file_system_dependency_tracker.dart';
import 'file_system.dart';

/// Concrete implementation of [FileSystem] handling standard URI schemes.
///
/// file: URIs are handled using file I/O.
/// data: URIs return their data contents.
///
/// Not intended to be implemented or extended by clients.
class StandardFileSystem implements FileSystem {
  /// This instance is without file tracking. If file tracking is wanted use
  /// [instanceWithTracking] instead.
  static final StandardFileSystem instance = new StandardFileSystem._(null);

  // Coverage-ignore(suite): Not run.
  static StandardFileSystem instanceWithTracking(
    FileSystemDependencyTracker tracker,
  ) => new StandardFileSystem._(tracker);

  final FileSystemDependencyTracker? tracker;

  StandardFileSystem._(this.tracker);

  @override
  FileSystemEntity entityForUri(Uri uri) {
    if (uri.isScheme('file')) {
      return new _IoFileSystemEntity(tracker, uri);
    }
    // Coverage-ignore(suite): Not run.
    else if (!uri.hasScheme) {
      // TODO(askesc): Empty schemes should have been handled elsewhere.
      return new _IoFileSystemEntity(tracker, Uri.base.resolveUri(uri));
    } else if (uri.isScheme('data')) {
      return new DataFileSystemEntity(Uri.base.resolveUri(uri));
    } else {
      throw new FileSystemException(
        uri,
        'StandardFileSystem only supports file:* and data:* URIs',
      );
    }
  }
}

/// Concrete implementation of [FileSystemEntity] for file: URIs.
class _IoFileSystemEntity implements FileSystemEntity {
  FileSystemDependencyTracker? tracker;

  @override
  final Uri uri;

  _IoFileSystemEntity(this.tracker, this.uri);

  @override
  int get hashCode => uri.hashCode;

  @override
  bool operator ==(Object other) =>
      other is _IoFileSystemEntity && other.uri == uri;

  @override
  Future<bool> exists() {
    if (new io.File.fromUri(uri).existsSync()) {
      return new Future.value(true);
    }
    if (io.FileSystemEntity.isDirectorySync(uri.toFilePath())) {
      // Coverage-ignore-block(suite): Not run.
      return new Future.value(true);
    }
    // TODO(CFE-team): What about [Link]s?
    return new Future.value(false);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Future<bool> existsAsyncIfPossible() async {
    if (await new io.File.fromUri(uri).exists()) {
      return true;
    }
    if (await io.FileSystemEntity.isDirectory(uri.toFilePath())) {
      return true;
    }
    // TODO(CFE-team): What about [Link]s?
    return false;
  }

  @override
  Future<Uint8List> readAsBytes() {
    try {
      FileSystemDependencyTracker.recordDependency(tracker, uri);
      return new Future.value(new io.File.fromUri(uri).readAsBytesSync());
    } on io.FileSystemException catch (exception) {
      return new Future.error(
        _toFileSystemException(exception),
        StackTrace.current,
      );
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  Future<Uint8List> readAsBytesAsyncIfPossible() async {
    try {
      FileSystemDependencyTracker.recordDependency(tracker, uri);
      return await new io.File.fromUri(uri).readAsBytes();
    } on io.FileSystemException catch (exception) {
      throw _toFileSystemException(exception);
    }
  }

  @override
  Future<String> readAsString() async {
    try {
      FileSystemDependencyTracker.recordDependency(tracker, uri);
      return await new io.File.fromUri(uri).readAsString();
    }
    // Coverage-ignore(suite): Not run.
    on io.FileSystemException catch (exception) {
      throw _toFileSystemException(exception);
    }
  }

  /**
   * Return the [FileSystemException] for the given I/O exception.
   */
  FileSystemException _toFileSystemException(io.FileSystemException exception) {
    String message = exception.message;
    String? osMessage = exception.osError?.message;
    if (osMessage != null && osMessage.isNotEmpty) {
      message = osMessage;
    }
    return new FileSystemException(uri, message);
  }
}

// Coverage-ignore(suite): Not run.
/// Concrete implementation of [FileSystemEntity] for data: URIs.
class DataFileSystemEntity implements FileSystemEntity {
  @override
  final Uri uri;

  DataFileSystemEntity(this.uri)
    : assert(uri.isScheme('data')),
      assert(uri.data != null);

  @override
  int get hashCode => uri.hashCode;

  @override
  bool operator ==(Object other) =>
      other is DataFileSystemEntity && other.uri == uri;

  @override
  Future<bool> exists() {
    return new Future.value(true);
  }

  @override
  Future<Uint8List> readAsBytes() {
    return new Future.value(uri.data!.contentAsBytes());
  }

  @override
  Future<bool> existsAsyncIfPossible() => exists();

  @override
  Future<Uint8List> readAsBytesAsyncIfPossible() => readAsBytes();

  @override
  Future<String> readAsString() {
    return new Future.value(uri.data!.contentAsString());
  }
}
