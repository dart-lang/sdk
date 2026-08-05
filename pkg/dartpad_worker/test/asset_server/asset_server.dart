// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;
import 'dart:io' show HttpServer;

import 'package:collection/collection.dart';
import 'package:pub_semver/pub_semver.dart' show Version;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';

import 'package.dart';

final class AssetServer {
  static shelf.Response get _notFound => shelf.Response.notFound('404');

  late final HttpServer _server;
  final Uri _assetPath;
  final Uri? _flutterAssetPath;
  final _packages = <Package>[];

  final FutureOr<void> Function(String) _printOnFailure;

  AssetServer._({
    required FutureOr<void> Function(String) printOnFailure,
    required Uri assetPath,
    required Uri? flutterAssetPath,
  }) : _printOnFailure = printOnFailure,
       _assetPath = assetPath,
       _flutterAssetPath = flutterAssetPath;

  static Future<AssetServer> listen({
    required FutureOr<void> Function(String) printOnFailure,
    required Uri assetPath,
    required Uri? flutterAssetPath,
  }) async {
    final ts = AssetServer._(
      printOnFailure: printOnFailure,
      assetPath: assetPath,
      flutterAssetPath: flutterAssetPath,
    );
    ts._server = await io.serve(ts._handler, '127.0.0.1', 0);
    return ts;
  }

  late final _handler = const shelf.Pipeline()
      .addMiddleware(_logRequestsOnFailure)
      .addMiddleware(_addCorsHeaders)
      .addHandler(
        shelf.Cascade()
            .add((request) {
              if (request.url.path.startsWith('asset/flutter/') &&
                  _handleFlutterAsset != null) {
                final r = request.change(path: 'asset/flutter');
                return _handleFlutterAsset(r);
              }
              return _notFound;
            })
            .add((request) {
              if (request.url.path.startsWith('asset/')) {
                return _handleAsset(request.change(path: 'asset'));
              }
              return _notFound;
            })
            .add(_handleArchive)
            .add(_handleVersionListing)
            .handler,
      );

  late final _handleFlutterAsset = _flutterAssetPath != null
      ? createStaticHandler(_flutterAssetPath.toFilePath())
      : null;
  late final _handleAsset = createStaticHandler(_assetPath.toFilePath());

  /// Add [package] to this pub server.
  void addPackage(Package package) {
    _packages.add(package);
  }

  /// BaseUrl for this test server.
  Uri get baseUrl => Uri.http('${_server.address.host}:${_server.port}', '/');

  /// Stop the server.
  Future<void> close() async {
    try {
      await _server.close(force: false).timeout(const Duration(seconds: 5));
    } on TimeoutException {
      await _server.close(force: true);
    }
  }

  shelf.Handler _logRequestsOnFailure(shelf.Handler handler) {
    return (request) async {
      final response = await handler(request);
      await _printOnFailure(
        '${request.method} ${request.url} -> ${response.statusCode}',
      );
      return response;
    };
  }

  shelf.Handler _addCorsHeaders(shelf.Handler handler) {
    return (request) async {
      final response = await handler(request);
      return response.change(
        headers: {
          'access-control-allow-origin': '*',
          'access-control-expose-headers': 'ETag,x-goog-hash,Accept,User-Agent',
        },
      );
    };
  }

  /// Handle `GET /api/packages/<package>`
  Future<shelf.Response> _handleVersionListing(shelf.Request request) async {
    if (request.method != 'GET' ||
        !request.url.path.startsWith('api/packages/') ||
        request.url.pathSegments.length != 3) {
      return _notFound;
    }

    final packageName = request.url.pathSegments[2];

    final versions = _packages
        .where((p) => p.name == packageName)
        .sortedBy((p) => p.version);

    if (versions.isEmpty) {
      return shelf.Response.notFound(
        json.encode({
          'error': {'message': 'Package not found'},
        }),
      );
    }
    final latest = versions.last;

    Object? pkgToJson(Package p) {
      return {
        'version': p.version.toString(),
        'archive_url': baseUrl
            .resolve('/archive/${p.name}-${p.version}.tar.gz')
            .toString(),
        'pubspec': p.pubspec,
      };
    }

    return shelf.Response.ok(
      json.encode({
        'name': packageName,
        'latest': pkgToJson(latest),
        'versions': versions.map(pkgToJson).toList(),
      }),
      headers: {'content-type': 'application/vnd.pub.v2+json'},
    );
  }

  static final _archiveUrlPattern = RegExp(
    r'^archive/(?<package>[^-]+)-(?<version>.+)\.tar\.gz$',
  );

  /// Handle `GET /api/archive/<package>-<version>.tar.gz`
  Future<shelf.Response> _handleArchive(shelf.Request request) async {
    final m = _archiveUrlPattern.firstMatch(request.url.path);
    if (request.method != 'GET' || m == null) {
      return _notFound;
    }

    final packageName = m.namedGroup('package')!;
    final version = Version.parse(m.namedGroup('version')!);

    final package = _packages.firstWhereOrNull(
      (p) => p.name == packageName && p.version == version,
    );
    if (package == null) {
      return shelf.Response.notFound('Package not found');
    }
    return shelf.Response.ok(
      package.archive,
      headers: {'content-type': 'application/octet-stream'},
    );
  }
}
