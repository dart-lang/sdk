import 'dart:async';
import 'dart:io' as io;

import 'package:front_end/src/api_unstable/vm.dart';

class HttpAwareFileSystem implements FileSystem {
  FileSystem original;

  HttpAwareFileSystem(this.original);

  @override
  FileSystemEntity entityForUri(Uri uri) {
    if (uri.scheme == 'http' || uri.scheme == 'https') {
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
      return response.statusCode == io.HttpStatus.ok;
    });
  }

  @override
  Future<List<int>> readAsBytes() async {
    return connectAndRun((io.HttpClient httpClient) async {
      io.HttpClientRequest request = await httpClient.getUrl(uri);
      io.HttpClientResponse response = await request.close();
      if (response.statusCode != io.HttpStatus.ok) {
        throw new FileSystemException(uri, response.toString());
      }
      List<List<int>> list = await response.toList();
      return list.expand((list) => list).toList();
    });
  }

  @override
  Future<String> readAsString() async {
    return String.fromCharCodes(await readAsBytes());
  }

  T connectAndRun<T>(T body(io.HttpClient httpClient)) {
    io.HttpClient httpClient;
    try {
      httpClient = new io.HttpClient();
      // Set timeout to be shorter than anticipated OS default
      httpClient.connectionTimeout = const Duration(seconds: 5);
      return body(httpClient);
    } on Exception catch (e) {
      throw new FileSystemException(uri, e.toString());
    } finally {
      httpClient?.close(force: true);
    }
  }
}
