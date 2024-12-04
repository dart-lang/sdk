// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:front_end/src/api_prototype/file_system.dart';

import 'retry_timeout_client.dart';

/// A wrapper around asset server that redirects file read requests
/// to http get requests to the asset server.
class AssetFileSystem implements FileSystem {
  final FileSystem original;
  final String server;
  final String port;
  final RetryTimeoutClient client;

  /// Wraps [original] to intercept request for asset entities and forward those
  /// to an http client at [server] and [port].
  ///
  /// Requests for `file:` entities continue to be resolved by [original].
  AssetFileSystem(FileSystem original, String server, String port)
      : this._(original, server, port);

  /// Constructor used for unit tests.
  ///
  /// Changes the default the http client behavior to have no delay on retries,
  /// and allow specifying fewer total retries.
  AssetFileSystem.forTesting(FileSystem original, String server, String port,
      {required int retries})
      : this._(original, server, port,
            retries: retries, delay: (_) => const Duration(seconds: 0));

  AssetFileSystem._(this.original, this.server, this.port,
      {int? retries, Duration Function(int retryCount)? delay})
      : client = RetryTimeoutClient(
            HttpClient()
              ..maxConnectionsPerHost = 200
              ..connectionTimeout = const Duration(seconds: 30)
              ..idleTimeout = const Duration(seconds: 30),
            retries: retries ?? 4,
            delay: delay);

  /// Convert the uri to a server uri.
  Uri _resourceUri(Uri uri) => Uri.parse('http://$server:$port/${uri.path}');

  @override
  FileSystemEntity entityForUri(Uri uri) {
    if (uri.isScheme('file')) {
      return original.entityForUri(uri);
    }

    // Pass the uri to the asset server in the debugger.
    return AssetFileSystemEntity(this, _resourceUri(uri));
  }

  void close() {
    client.close(force: true);
  }
}

class AssetFileSystemEntity implements FileSystemEntity {
  AssetFileSystem fileSystem;

  @override
  Uri uri;

  AssetFileSystemEntity(this.fileSystem, this.uri);

  @override
  Future<bool> exists() async {
    return _runWithClient((httpClient) async {
      var response = await httpClient.headUrl(uri);
      unawaited(_ignore(response));
      return response.statusCode == HttpStatus.ok;
    });
  }

  @override
  Future<bool> existsAsyncIfPossible() => exists();

  @override
  Future<Uint8List> readAsBytes() async {
    return _runWithClient((httpClient) async {
      var response = await httpClient.getUrl(uri);
      if (response.statusCode != HttpStatus.ok) {
        unawaited(_ignore(response));
        throw FileSystemException(
            uri, 'Asset server returned ${response.statusCode}');
      }
      return await collectBytes(response);
    });
  }

  @override
  Future<Uint8List> readAsBytesAsyncIfPossible() => readAsBytes();

  @override
  Future<String> readAsString() async {
    return _runWithClient((httpClient) async {
      var response = await httpClient.getUrl(uri);
      if (response.statusCode != HttpStatus.ok) {
        unawaited(_ignore(response));
        throw FileSystemException(
            uri, 'Asset server returned ${response.statusCode}');
      }
      return await response.transform(utf8.decoder).join();
    });
  }

  /// Execute the [body] with the http client created in [fileSystem].
  ///
  /// Throws a [FileSystemException] on failure,
  /// and cleans up the client on return or error.
  Future<T> _runWithClient<T>(
      Future<T> Function(RetryTimeoutClient httpClient) body) async {
    try {
      return await body(fileSystem.client);
    } on Exception catch (e, s) {
      throw FileSystemException(uri, '$e:$s');
    }
  }

  /// Make sure the response stream is listened to so that we don't leave
  /// dangling connections, suppress errors.
  Future<void> _ignore(HttpClientResponse response) {
    return response
        .listen((_) {}, cancelOnError: true)
        .cancel()
        .catchError((_) {});
  }
}
