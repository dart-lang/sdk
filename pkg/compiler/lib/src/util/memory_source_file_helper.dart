// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.test.memory_source_file_helper;

import 'dart:async' show Future;
export 'dart:io' show Platform;

import 'package:compiler/compiler_api.dart' as api;

import 'package:compiler/src/io/source_file.dart'
    show Binary, StringSourceFile, Utf8BytesSourceFile;

import 'package:compiler/src/source_file_provider.dart'
    show CompilerSourceFileProvider;

export 'package:compiler/src/source_file_provider.dart'
    show SourceFileProvider, FormattingDiagnosticHandler;

class MemorySourceFileProvider extends CompilerSourceFileProvider {
  Map<String, dynamic> memorySourceFiles;

  /// MemorySourceFiles can contain maps of file names to string contents or
  /// file names to binary contents.
  MemorySourceFileProvider(Map<String, dynamic> this.memorySourceFiles);

  @override
  Future<api.Input<List<int>>> readBytesFromUri(
      Uri resourceUri, api.InputKind inputKind) {
    if (!resourceUri.isScheme('memory')) {
      return super.readBytesFromUri(resourceUri, inputKind);
    }
    // TODO(johnniwinther): We should use inputs already in the cache. Some
    // tests currently require that we always create a fresh input.

    var source = memorySourceFiles[resourceUri.path];
    if (source == null) {
      return Future.error(Exception(
          'No such memory file $resourceUri in ${memorySourceFiles.keys}'));
    }
    api.Input<List<int>> input;
    StringSourceFile? stringFile;
    registerUri(resourceUri);
    if (source is String) {
      stringFile = StringSourceFile.fromUri(resourceUri, source);
    }
    switch (inputKind) {
      case api.InputKind.UTF8:
        input = stringFile ?? Utf8BytesSourceFile(resourceUri, source);
        break;
      case api.InputKind.binary:
        if (stringFile != null) {
          source = stringFile.data;
        }
        input = Binary(resourceUri, source);
        break;
    }
    return Future.value(input);
  }

  @override
  Future<api.Input<List<int>>> readFromUri(Uri resourceUri,
          {api.InputKind inputKind = api.InputKind.UTF8}) =>
      readBytesFromUri(resourceUri, inputKind);

  @override
  api.Input<List<int>>? getUtf8SourceFile(Uri resourceUri) {
    var source = memorySourceFiles[resourceUri.path];
    return source is String
        ? StringSourceFile.fromUri(resourceUri, source)
        : Utf8BytesSourceFile(resourceUri, source);
  }
}
