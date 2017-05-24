// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.test.memory_source_file_helper;

import 'dart:async' show Future;
export 'dart:io' show Platform;

import 'package:compiler/compiler_new.dart';

export 'package:compiler/src/apiimpl.dart' show CompilerImpl;

export 'package:compiler/src/filenames.dart' show currentDirectory;

import 'package:compiler/src/io/source_file.dart'
    show Binary, StringSourceFile, SourceFile, Utf8BytesSourceFile;

import 'package:compiler/src/source_file_provider.dart' show SourceFileProvider;

export 'package:compiler/src/source_file_provider.dart'
    show SourceFileProvider, FormattingDiagnosticHandler;

class MemorySourceFileProvider extends SourceFileProvider {
  Map<String, dynamic> memorySourceFiles;

  /// MemorySourceFiles can contain maps of file names to string contents or
  /// file names to binary contents.
  MemorySourceFileProvider(Map<String, dynamic> this.memorySourceFiles);

  Future<Input> readBytesFromUri(Uri resourceUri, InputKind inputKind) {
    if (resourceUri.scheme != 'memory') {
      return super.readBytesFromUri(resourceUri, inputKind);
    }
    var source = memorySourceFiles[resourceUri.path];
    if (source == null) {
      return new Future.error(new Exception(
          'No such memory file $resourceUri in ${memorySourceFiles.keys}'));
    }
    Input input;
    switch (inputKind) {
      case InputKind.utf8:
        if (source is String) {
          input = new StringSourceFile.fromUri(resourceUri, source);
        } else {
          input = new Utf8BytesSourceFile(resourceUri, source);
        }
        break;
      case InputKind.binary:
        if (source is String) {
          source = source.codeUnits;
        }
        input = new Binary(resourceUri, source);
        break;
    }
    this.sourceFiles[resourceUri] = input;
    return new Future.value(input);
  }

  //Future<List<int>> call(Uri resourceUri) => readBytesFromUri(resourceUri, InputKind.utf8);

  SourceFile getSourceFile(Uri resourceUri) {
    if (resourceUri.scheme != 'memory') {
      return super.getSourceFile(resourceUri);
    }
    var source = memorySourceFiles[resourceUri.path];
    if (source == null) {
      throw new Exception(
          'No such memory file $resourceUri in ${memorySourceFiles.keys}');
    }
    if (source is String) {
      return new StringSourceFile.fromUri(resourceUri, source);
    }
    return new Utf8BytesSourceFile(resourceUri, source);
  }

  @override
  Future<Input> readFromUri(Uri resourceUri,
          {InputKind inputKind: InputKind.utf8}) =>
      readBytesFromUri(resourceUri, inputKind);
}
