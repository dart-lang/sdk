// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.test.memory_source_file_helper;

import 'dart:async' show Future;
export 'dart:io' show Platform;

export 'package:compiler/implementation/apiimpl.dart'
       show Compiler;

export 'package:compiler/implementation/filenames.dart'
       show currentDirectory;

import 'package:compiler/implementation/source_file.dart'
       show StringSourceFile;

import 'package:compiler/implementation/source_file_provider.dart'
       show SourceFileProvider;

export 'package:compiler/implementation/source_file_provider.dart'
       show SourceFileProvider, FormattingDiagnosticHandler;

class MemorySourceFileProvider extends SourceFileProvider {
  Map<String, String> memorySourceFiles;

  MemorySourceFileProvider(Map<String, String> this.memorySourceFiles);

  Future<String> readStringFromUri(Uri resourceUri) {
    if (resourceUri.scheme != 'memory') {
      return super.readStringFromUri(resourceUri);
    }
    String source = memorySourceFiles[resourceUri.path];
    if (source == null) {
      return new Future.error(new Exception('No such file $resourceUri'));
    }
    String resourceName = '$resourceUri';
    this.sourceFiles[resourceName] = new StringSourceFile(resourceName, source);
    return new Future.value(source);
  }

  Future<String> call(Uri resourceUri) => readStringFromUri(resourceUri);
}
