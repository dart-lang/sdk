// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dwds/src/readers/asset_reader.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_proxy/shelf_proxy.dart';

/// A reader for resources provided by a proxy server.
class ProxyServerAssetReader implements AssetReader {
  final _logger = Logger('ProxyServerAssetReader');

  final Handler _handler;
  final http.Client? _client;

  ProxyServerAssetReader._(this._handler, this._client);

  factory ProxyServerAssetReader(
    int assetServerPort, {
    String root = '',
    String host = 'localhost',
    bool isHttps = false,
  }) {
    final scheme = isHttps ? 'https://' : 'http://';
    final inner = HttpClient()
      ..maxConnectionsPerHost = 200
      ..idleTimeout = const Duration(seconds: 30)
      ..connectionTimeout = const Duration(seconds: 30);
    final client = isHttps
        ? IOClient(inner..badCertificateCallback = (cert, host, port) => true)
        : IOClient(inner);
    var url = '$scheme$host:$assetServerPort/';
    if (root.isNotEmpty) url += '$root/';
    final handler = proxyHandler(url, client: client);
    return ProxyServerAssetReader._(handler, client);
  }

  ProxyServerAssetReader.fromHandler(this._handler) : _client = null;

  @override
  String get basePath => '';

  @override
  Future<String?> dartSourceContents(String serverPath) =>
      _readResource(serverPath);

  @override
  Future<String?> sourceMapContents(String serverPath) =>
      _readResource(serverPath);

  Future<String?> _readResource(String path) async {
    // Handlers expect a fully formed HTML URI. The actual hostname and port
    // does not matter.
    final request = Request(
      'GET',
      Uri.parse('http://foo:0000/$path'),
    ).change(headers: {'requested-by': 'DWDS'});
    final response = await _handler(request);

    if (response.statusCode != HttpStatus.ok) {
      _logger.warning('''
      Failed to load asset at path: $path.

      Status code: ${response.statusCode}

      Headers:
      ${const JsonEncoder.withIndent('  ').convert(response.headers)}
      ''');
      return null;
    } else {
      return await response.readAsString();
    }
  }

  @override
  Future<String?> metadataContents(String serverPath) =>
      _readResource(serverPath);

  @override
  Future<void> close() async => _client?.close();
}
