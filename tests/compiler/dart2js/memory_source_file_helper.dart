// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.test.memory_source_file_helper;

import 'dart:async' show Future;
export 'dart:io' show Platform;

export 'package:compiler/src/apiimpl.dart' show CompilerImpl;

export 'package:compiler/src/filenames.dart' show currentDirectory;

import 'package:compiler/src/io/source_file.dart'
    show StringSourceFile, SourceFile, Utf8BytesSourceFile;

import 'package:compiler/src/source_file_provider.dart' show SourceFileProvider;

export 'package:compiler/src/source_file_provider.dart'
    show SourceFileProvider, FormattingDiagnosticHandler;

class MemorySourceFileProvider extends SourceFileProvider {
  Map<String, dynamic> memorySourceFiles;

  /// MemorySourceFiles can contain maps of file names to string contents or
  /// file names to binary contents.
  MemorySourceFileProvider(Map<String, dynamic> this.memorySourceFiles);

  Future<List<int>> readUtf8BytesFromUri(Uri resourceUri) {
    if (resourceUri.scheme != 'memory') {
      return super.readUtf8BytesFromUri(resourceUri);
    }
    var source = memorySourceFiles[resourceUri.path];
    if (source == null) {
      return new Future.error(new Exception(
          'No such memory file $resourceUri in ${memorySourceFiles.keys}'));
    }
    var sourceFile;
    if (source is String) {
      sourceFile = new StringSourceFile.fromUri(resourceUri, source);
    } else {
      sourceFile = new Utf8BytesSourceFile(resourceUri, source);
    }
    this.sourceFiles[resourceUri] = sourceFile;
    return new Future.value(source);
  }

  Future<List<int>> call(Uri resourceUri) => readUtf8BytesFromUri(resourceUri);

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
  Future readFromUri(Uri resourceUri) => readUtf8BytesFromUri(resourceUri);
}
