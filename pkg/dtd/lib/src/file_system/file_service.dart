// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart';

import '../../dtd.dart';
import 'constants.dart';
import 'types.dart';

class DTDFileService {
  static const String serviceName = 'FileService';

  static Future<void> register(DTDConnection connection) async {
    await connection.registerService(
      serviceName,
      FileSystemServiceMethods.readFileAsString.name,
      _readFileAsString,
    );
    await connection.registerService(
      serviceName,
      FileSystemServiceMethods.writeFileAsString.name,
      _writeFileAsString,
    );
    await connection.registerService(
      serviceName,
      FileSystemServiceMethods.listDirectories.name,
      _listDirectories,
    );
  }

  static Future<Map<String, Object?>> _readFileAsString(
    Parameters parameters,
  ) async {
    final uri = Uri.parse(parameters['uri'].value as String);
    _assertPermissions(uri);

    final content = File(uri.path).readAsStringSync();

    return FileContent(content: content).toJson();
  }

  static Future<Map<String, Object?>> _writeFileAsString(
    Parameters parameters,
  ) async {
    final uri = Uri.parse(parameters['uri'].value as String);
    final contents = parameters['contents'].value as String;
    final encoding = Encoding.getByName(
      parameters['encoding'].value as String,
    )!;

    _assertPermissions(uri);

    final file = File(uri.path);
    if (!file.existsSync()) {
      file.createSync();
    }

    await file.writeAsString(
      contents,
      encoding: encoding,
    );

    return {'type': 'Success'};
  }

  static Future<Map<String, Object?>> _listDirectories(
    Parameters parameters,
  ) async {
    final uri = Uri.parse(parameters['uri'].value as String);
    final uris = Directory(uri.path).listSync().map((e) => e.uri).toList();

    _assertPermissions(uri);

    return UriList(uris: uris).toJson();
  }

  static void _assertPermissions(Uri uri) {
    // TODO(danchevalier): Lock down api against directory allow list from
    // IDE.
  }
}
