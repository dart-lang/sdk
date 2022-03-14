// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:front_end/src/api_unstable/vm.dart';

class HttpAwareFileSystem implements FileSystem {
  FileSystem original;

  HttpAwareFileSystem(this.original);

  @override
  FileSystemEntity entityForUri(Uri uri) {
    if (uri.isScheme('http') || uri.isScheme('https')) {
      return new HttpFileSystemEntity(this, uri);
    } else {
      return original.entityForUri(uri);
    }
  }
}

class HttpFileSystemEntity implements FileSystemEntity {
  HttpAwareFileSystem fileSystem;
  Uri uri;

  HttpFileSystemEntity(this.fileSystem, this.uri);

  @override
  Future<bool> exists() async {
    return connectAndRun((io.HttpClient httpClient) async {
      io.HttpClientRequest request = await httpClient.headUrl(uri);
      io.HttpClientResponse response = await request.close();
      await response.drain();
      return response.statusCode == io.HttpStatus.ok;
    });
  }

  @override
  Future<bool> existsAsyncIfPossible() => exists();

  @override
  Future<List<int>> readAsBytes() async {
    return connectAndRun((io.HttpClient httpClient) async {
      io.HttpClientRequest request = await httpClient.getUrl(uri);
      io.HttpClientResponse response = await request.close();
      if (response.statusCode != io.HttpStatus.ok) {
        await response.drain();
        throw new FileSystemException(uri, response.toString());
      }
      List<List<int>> list = await response.toList();
      return list.expand((list) => list).toList();
    });
  }

  @override
  Future<List<int>> readAsBytesAsyncIfPossible() => readAsBytes();

  @override
  Future<String> readAsString() async {
    return String.fromCharCodes(await readAsBytes());
  }

  Future<T> connectAndRun<T>(Future<T> body(io.HttpClient httpClient)) async {
    io.HttpClient? httpClient;
    try {
      httpClient = new io.HttpClient();
      // Set timeout to be shorter than anticipated OS default
      httpClient.connectionTimeout = const Duration(seconds: 5);
      return await body(httpClient);
    } on Exception catch (e) {
      throw new FileSystemException(uri, e.toString());
    } finally {
      httpClient?.close(force: true);
    }
  }
}
