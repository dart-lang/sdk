// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:dev_compiler/src/kernel/retry_timeout_client.dart';
import 'package:front_end/src/api_prototype/file_system.dart';
import 'package:pedantic/pedantic.dart';

/// A wrapper around asset server that redirects file read requests
/// to http get requests to the asset server.
class AssetFileSystem implements FileSystem {
  FileSystem original;
  final String server;
  final String port;

  AssetFileSystem(this.original, this.server, this.port);

  /// Convert the uri to a server uri.
  Uri _resourceUri(Uri uri) => Uri.parse('http://$server:$port/${uri.path}');

  @override
  FileSystemEntity entityForUri(Uri uri) {
    if (uri.scheme == 'file') {
      return original.entityForUri(uri);
    }

    // Pass the uri to the asset server in the debugger.
    return AssetFileSystemEntity(this, _resourceUri(uri));
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
  Future<List<int>> readAsBytes() async {
    return _runWithClient((httpClient) async {
      var response = await httpClient.getUrl(uri);
      if (response.statusCode != HttpStatus.ok) {
        unawaited(_ignore(response));
        throw FileSystemException(
            uri, 'Asset rerver returned ${response.statusCode}');
      }
      return await collectBytes(response);
    });
  }

  @override
  Future<List<int>> readAsBytesAsyncIfPossible() => readAsBytes();

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

  /// Execute the [body] with the new http client.
  ///
  /// Throws a [FileSystemException] on failure,
  /// and cleans up the client on return or error.
  Future<T> _runWithClient<T>(
      Future<T> Function(RetryTimeoutClient httpClient) body) async {
    RetryTimeoutClient httpClient;
    try {
      httpClient = RetryTimeoutClient(HttpClient(), retries: 4);
      return await body(httpClient);
    } on Exception catch (e, s) {
      throw FileSystemException(uri, '$e:$s');
    } finally {
      httpClient?.close(force: true);
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
