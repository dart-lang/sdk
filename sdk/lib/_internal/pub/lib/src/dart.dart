// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library for compiling Dart code and manipulating analyzer parse trees.
library pub.dart;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:analyzer_experimental/analyzer.dart';
import 'package:pathos/path.dart' as path;
import '../../../compiler/compiler.dart' as compiler;
import '../../../compiler/implementation/mirrors/dart2js_mirror.dart' as dart2js
    show analyze, Dart2JsMirrorSystem;
import '../../../compiler/implementation/mirrors/mirrors.dart'
    show MirrorSystem;
import '../../../compiler/implementation/source_file_provider.dart'
    show FormattingDiagnosticHandler, SourceFileProvider;
import '../../../compiler/implementation/filenames.dart'
    show appendSlash;

import 'io.dart';
import 'sdk.dart' as sdk;
import 'utils.dart';

/// Returns [entrypoint] compiled to JavaScript (or to Dart if [toDart] is
/// true).
///
/// By default, the package root is assumed to be adjacent to [entrypoint], but
/// if [packageRoot] is passed that will be used instead.
Future<String> compile(String entrypoint, {String packageRoot,
    bool toDart: false}) {
  return new Future.sync(() {
    var provider = new SourceFileProvider();
    var options = <String>['--categories=Client,Server', '--minify'];
    if (toDart) options.add('--output-type=dart');
    if (packageRoot == null) {
      packageRoot = path.join(path.dirname(entrypoint), 'packages');
    }

    return compiler.compile(
        path.toUri(entrypoint),
        path.toUri(appendSlash(_libPath)),
        path.toUri(appendSlash(packageRoot)),
        provider.readStringFromUri,
        new FormattingDiagnosticHandler(provider).diagnosticHandler,
        options);
  }).then((result) {
    if (result != null) return result;
    throw new ApplicationException('Failed to compile "$entrypoint".');
  });
}

/// Returns the path to the library directory. This corresponds to the "sdk"
/// directory in the repo and to the root of the compiled SDK.
String get _libPath {
  if (runningFromSdk) return sdk.rootDirectory;
  return path.join(repoRoot, 'sdk');
}

/// Returns whether [dart] looks like an entrypoint file.
bool isEntrypoint(CompilationUnit dart) {
  // TODO(nweiz): this misses the case where a Dart file doesn't contain main(),
  // but it parts in another file that does.
  return dart.declarations.any((node) {
    return node is FunctionDeclaration && node.name.name == "main" &&
        node.functionExpression.parameters.elements.isEmpty;
  });
}
