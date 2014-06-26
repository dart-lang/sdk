// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';

import 'package:compiler/implementation/mirrors/source_mirrors.dart';
import 'package:compiler/implementation/mirrors/analyze.dart' as source_mirrors;
import 'package:compiler/implementation/source_file_provider.dart';

TypeMirror createInstantiation(TypeSourceMirror type,
                               List<TypeMirror> typeArguments) {
  return type.createInstantiation(typeArguments);
}

Future<MirrorSystem> analyze(String test) {
  Uri repository = Platform.script.resolve('../../../../');
  Uri testUri = repository.resolve('tests/lib/mirrors/$test');
  return analyzeUri(testUri);
}


Future<MirrorSystem> analyzeUri(Uri testUri) {
  Uri repository = Platform.script.resolve('../../../../');
  Uri libraryRoot = repository.resolve('sdk/');
  Uri packageRoot = Uri.base.resolveUri(
      new Uri.file('${Platform.packageRoot}/'));
  var provider = new CompilerSourceFileProvider();
  var handler = new FormattingDiagnosticHandler(provider);
  return source_mirrors.analyze(
      [testUri],
      libraryRoot,
      packageRoot,
      provider,
      handler);
}