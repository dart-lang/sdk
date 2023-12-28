// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: comment_references

import 'dart:convert';

import 'package:json_rpc_2/json_rpc_2.dart';

import '../../dtd.dart';
import '../../dtd_file_system_service.dart';
import 'constants.dart';

extension FileSystemExtension on DTDConnection {
  /// Reads the file at [uri] from disk and returns the content as a
  /// String.
  ///
  /// If there are unsaved changes to the file at [uri], for example
  /// from an IDE, those will be ignored.
  ///
  /// The return value can be one of {'type': 'Success'} or an [RpcException].
  Future<FileContent> readFileAsString(
    Uri uri, {
    String encoding = 'utf8',
  }) async {
    final result = await call(
      DTDFileService.serviceName,
      FileSystemServiceMethods.readFileAsString.name,
      params: {
        'uri': uri.toString(),
        'encoding': encoding,
      },
    );
    return FileContent.fromDTDResponse(result);
  }

  /// Writes [contents] to the file at [uri].
  ///
  /// The file will be created if it does not exist, and it will be
  /// overwritten if it already does exist.
  ///
  /// If there are unsaved changes to the file at [uri], for example
  /// from an IDE, those will be ignored and the IDE will handle any
  /// conflicts that occur from writing the file on disk.
  ///
  /// The return value can be one of {'type': 'Success'} or an [RpcException].
  Future<bool> writeFileAsString(
    Uri uri,
    String contents, {
    Encoding encoding = utf8,
  }) async {
    final response = await call(
      DTDFileService.serviceName,
      FileSystemServiceMethods.writeFileAsString.name,
      params: {
        'uri': uri.toString(),
        'contents': contents,
        'encoding': encoding.name,
      },
    );
    return response.result['result'] == true;
  }

  /// Lists the subdirectories and files under the directory at [uri].
  ///
  /// Returns an [Error] if [uri] resolves to a [FileSystemEntity] that
  /// is not a [Directory].
  ///
  /// The file will be created if it does not exist, and it will be
  /// overwritten if it already does exist.
  ///
  /// If there are unsaved changes under the directory at [uri], for
  /// example, an unsaved new file from an IDE, those will be ignored.
  ///
  /// The return value can be one of {'type': 'Success'} or an [RpcException].
  Future<UriList?> listDirectories(Uri uri) async {
    final result = await call(
      DTDFileService.serviceName,
      FileSystemServiceMethods.listDirectories.name,
      params: {
        'uri': uri.toString(),
      },
    );
    return UriList.fromDTDResponse(result);
  }
}
