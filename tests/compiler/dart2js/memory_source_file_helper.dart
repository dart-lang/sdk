// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.test.memory_source_file_helper;

import 'dart:async' show Future;
import 'dart:uri' show Uri;
export 'dart:uri' show Uri;
import 'dart:io';
export 'dart:io' show Options;

export '../../../sdk/lib/_internal/compiler/implementation/apiimpl.dart'
       show Compiler;

export '../../../sdk/lib/_internal/compiler/implementation/filenames.dart'
       show getCurrentDirectory, nativeToUriPath;

import '../../../sdk/lib/_internal/compiler/implementation/source_file.dart'
       show SourceFile;

import '../../../sdk/lib/_internal/compiler/implementation/source_file_provider.dart'
       show SourceFileProvider;

export '../../../sdk/lib/_internal/compiler/implementation/source_file_provider.dart'
       show FormattingDiagnosticHandler;

class MemorySourceFileProvider extends SourceFileProvider {
  static Map MEMORY_SOURCE_FILES;
  Future<String> readStringFromUri(Uri resourceUri) {
    if (resourceUri.scheme != 'memory') {
      return super.readStringFromUri(resourceUri);
    }
    String source = MEMORY_SOURCE_FILES[resourceUri.path];
    // TODO(ahe): Return new Future.error(...) ?
    if (source == null) throw 'No such file $resourceUri';
    String resourceName = '$resourceUri';
    this.sourceFiles[resourceName] = new SourceFile(resourceName, source);
    return new Future.value(source);
  }
}
