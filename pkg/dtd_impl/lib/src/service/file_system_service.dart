// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dtd/dtd.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:path/path.dart' as path;

import '../constants.dart';
import '../dtd_client.dart';
import 'internal_service.dart';

class FileSystemService extends InternalService {
  FileSystemService({required this.secret, required this.unrestrictedMode});

  final String secret;
  final bool unrestrictedMode;
  final List<Uri> _ideWorkspaceRoots = [];

  // Note: These values should match the values from
  // package:dtd/src/constants.dart.
  @override
  String get serviceName => 'FileSystem';

  static const int _defaultGetProjectRootsDepth = 4;

  @override
  void register(DTDClient client) {
    client
      ..registerServiceMethod(
        serviceName,
        'readFileAsString',
        _readFileAsString,
      )
      ..registerServiceMethod(
        serviceName,
        'writeFileAsString',
        _writeFileAsString,
      )
      ..registerServiceMethod(
        serviceName,
        'listDirectoryContents',
        _listDirectoryContents,
      )
      ..registerServiceMethod(
        serviceName,
        'setIDEWorkspaceRoots',
        _setIDEWorkspaceRoots,
      )
      ..registerServiceMethod(
        serviceName,
        'getIDEWorkspaceRoots',
        _getIDEWorkspaceRoots,
      )
      ..registerServiceMethod(
        serviceName,
        'getProjectRoots',
        _getProjectRoots,
      );
  }

  void _ensureIDEWorkspaceRootsContainUri(Uri uri) {
    // If in unrestricted mode, no need to do these checks.
    if (unrestrictedMode) return;
    if (_ideWorkspaceRoots.any(
      (root) =>
          path.isWithin(root.path, uri.path) ||
          path.equals(root.path, uri.path),
    )) {
      return;
    }

    throw RpcErrorCodes.buildRpcException(
      RpcErrorCodes.kPermissionDenied,
    );
  }

  Map<String, Object?> _setIDEWorkspaceRoots(Parameters parameters) {
    final incomingSecret = parameters['secret'].asString;

    if (!unrestrictedMode && secret != incomingSecret) {
      throw RpcErrorCodes.buildRpcException(
        RpcErrorCodes.kPermissionDenied,
      );
    }
    final newRoots = <Uri>[];
    for (final root in parameters['roots'].asList.cast<String>()) {
      final rootUri = Uri.parse(path.normalize(root));
      if (rootUri.scheme != 'file') {
        throw RpcErrorCodes.buildRpcException(
          RpcErrorCodes.kExpectsUriParamWithFileScheme,
        );
      }

      newRoots.add(rootUri);
    }

    _ideWorkspaceRoots.clear();
    _ideWorkspaceRoots.addAll(newRoots);

    return RPCResponses.success;
  }

  Map<String, Object?> _getIDEWorkspaceRoots(Parameters _) {
    return IDEWorkspaceRoots(ideWorkspaceRoots: _ideWorkspaceRoots).toJson();
  }

  Future<Map<String, Object?>> _getProjectRoots(Parameters parameters) async {
    final searchDepth =
        parameters['depth'].asIntOr(_defaultGetProjectRootsDepth);

    final projectRoots = <Uri>[];

    // Recursive helper method to find all project roots within [directory], up
    // to a maximum depth of [maxSearchDepth].
    Future<void> findProjectRoots(
      Directory dir, {
      required int currentDepth,
    }) async {
      if (await dir.exists()) {
        // Setting 'followLinks' to false means that any symbolic links returned
        // in this list will have type [Link], and therefore will fail the type
        // checks below for `whereType<File>` and `whereType<Directory>`. This
        // ensures that we are not returning project roots that are outside of
        // [_ideWorkspaceRoots].
        final directoryContents = await (dir.list(followLinks: false)).toList();
        final pubspec = directoryContents
            .whereType<File>()
            .firstWhereOrNull((entity) => entity.path.endsWith('pubspec.yaml'));
        if (pubspec != null) {
          projectRoots.add(dir.uri);
        }

        final nextLevel = currentDepth + 1;
        if (nextLevel < searchDepth) {
          await Future.wait([
            for (final dir in directoryContents.whereType<Directory>())
              findProjectRoots(dir, currentDepth: nextLevel),
          ]);
        }
      }
    }

    await Future.wait([
      for (final workspaceRoot in _ideWorkspaceRoots)
        findProjectRoots(Directory.fromUri(workspaceRoot), currentDepth: 0),
    ]);

    return UriList(uris: projectRoots).toJson();
  }

  Future<Map<String, Object?>> _readFileAsString(Parameters parameters) async {
    final uri = _extractUri(parameters);
    _ensureIDEWorkspaceRootsContainUri(uri);
    final file = File.fromUri(uri);

    if (!(await file.exists())) {
      throw RpcErrorCodes.buildRpcException(
        RpcErrorCodes.kFileDoesNotExist,
      );
    }

    final content = await file.readAsString();

    return FileContent(content: content).toJson();
  }

  Uri _extractUri(Parameters parameters) {
    final uriString = parameters['uri'].asString;
    final uri = Uri.parse(path.normalize(uriString));
    if (uri.scheme != 'file') {
      throw RpcErrorCodes.buildRpcException(
        RpcErrorCodes.kExpectsUriParamWithFileScheme,
      );
    }
    return uri;
  }

  Future<Map<String, Object?>> _writeFileAsString(Parameters parameters) async {
    final uri = _extractUri(parameters);
    final contents = parameters['contents'].asString;
    final encoding = Encoding.getByName(
      parameters['encoding'].asString,
    )!;

    _ensureIDEWorkspaceRootsContainUri(uri);
    final file = File.fromUri(uri);
    if (!(await file.exists())) {
      await file.create(recursive: true);
    }

    await file.writeAsString(
      contents,
      encoding: encoding,
    );

    return RPCResponses.success;
  }

  Future<Map<String, Object?>> _listDirectoryContents(
    Parameters parameters,
  ) async {
    final uri = _extractUri(parameters);
    _ensureIDEWorkspaceRootsContainUri(uri);
    final dir = Directory.fromUri(uri);
    if (!(await dir.exists())) {
      throw RpcErrorCodes.buildRpcException(
        RpcErrorCodes.kDirectoryDoesNotExist,
        data: {'directory': dir.uri.toFilePath()},
      );
    }

    final response = await (dir.list()).toList();

    final uris = response.map((e) => e.uri).toList();

    return UriList(uris: uris).toJson();
  }
}
