// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.test.memory_compiler;

import 'package:expect/expect.dart';
import 'memory_source_file_helper.dart';

import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart'
       show NullSink;

import '../../../sdk/lib/_internal/compiler/compiler.dart'
       show DiagnosticHandler;

import 'dart:async';

import '../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors.dart';
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/dart2js_mirror.dart';

Compiler compilerFor(Map<String,String> memorySourceFiles,
                     {DiagnosticHandler diagnosticHandler,
                      List<String> options: const []}) {
  Uri script = currentDirectory.resolve(nativeToUriPath(Platform.script));
  Uri libraryRoot = script.resolve('../../../sdk/');
  Uri packageRoot = script.resolve('./packages/');

  MemorySourceFileProvider.MEMORY_SOURCE_FILES = memorySourceFiles;
  var provider = new MemorySourceFileProvider();
  if (diagnosticHandler == null) {
    diagnosticHandler = new FormattingDiagnosticHandler(provider);
  }

  EventSink<String> outputProvider(String name, String extension) {
    if (name != '') throw 'Attempt to output file "$name.$extension"';
    return new NullSink('$name.$extension');
  }

  Compiler compiler = new Compiler(provider.readStringFromUri,
                                   outputProvider,
                                   diagnosticHandler,
                                   libraryRoot,
                                   packageRoot,
                                   options);
  return compiler;
}

Future<MirrorSystem> mirrorSystemFor(Map<String,String> memorySourceFiles,
                                     {DiagnosticHandler diagnosticHandler,
                                      List<String> options: const []}) {
  Uri script = currentDirectory.resolve(nativeToUriPath(Platform.script));
  Uri libraryRoot = script.resolve('../../../sdk/');
  Uri packageRoot = script.resolve('./packages/');

  MemorySourceFileProvider.MEMORY_SOURCE_FILES = memorySourceFiles;
  var provider = new MemorySourceFileProvider();
  if (diagnosticHandler == null) {
    diagnosticHandler = new FormattingDiagnosticHandler(provider);
  }

  List<Uri> libraries = <Uri>[];
  memorySourceFiles.forEach((String path, _) {
    libraries.add(new Uri(scheme: 'memory', path: path));
  });

  return analyze(libraries, libraryRoot, packageRoot,
                 provider, diagnosticHandler, options);
}
