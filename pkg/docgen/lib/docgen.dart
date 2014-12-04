// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// **docgen** is a tool for creating machine readable representations of Dart
/// code metadata, including: classes, members, comments and annotations.
///
/// docgen is run on a `.dart` file or a directory containing `.dart` files.
///
///      $ dart docgen.dart [OPTIONS] [FILE/DIR]
///
/// This creates files called `docs/<library_name>.yaml` in your current
/// working directory.
library docgen;

import 'dart:async';

import 'src/generator.dart' as gen;
import 'src/viewer.dart' as viewer;

export 'src/generator.dart' show getMirrorSystem;
export 'src/library_helpers.dart' show getDocgenObject;
export 'src/models.dart';
export 'src/package_helpers.dart' show packageNameFor;

/// Docgen constructor initializes the link resolver for markdown parsing.
/// Also initializes the command line arguments.
///
/// [packageRoot] is the packages directory of the directory being analyzed.
/// If [includeSdk] is `true`, then any SDK libraries explicitly imported will
/// also be documented.
/// If [parseSdk] is `true`, then all Dart SDK libraries will be documented.
/// This option is useful when only the SDK libraries are needed.
/// If [compile] is `true`, then after generating the documents, compile the
/// viewer with dart2js.
/// If [serve] is `true`, then after generating the documents we fire up a
/// simple server to view the documentation.
///
/// Returned Future completes with true if document generation is successful.
Future<bool> docgen(List<String> files, {String packageRoot,
    bool includePrivate: false, bool includeSdk: false, bool parseSdk: false,
    String introFileName: '', String out: gen.DEFAULT_OUTPUT_DIRECTORY,
    List<String> excludeLibraries: const [],
    bool includeDependentPackages: false, bool compile: false,
    bool serve: false, bool noDocs: false, String startPage,
    String pubScript : 'pub', String dartBinary: 'dart',
    bool indentJSON: false, String sdk}) {
  var result;
  if (!noDocs) {
    viewer.ensureMovedViewerCode();
    result = gen.generateDocumentation(files, packageRoot: packageRoot,
        includePrivate: includePrivate,
        includeSdk: includeSdk, parseSdk: parseSdk,
        introFileName: introFileName, out: out,
        excludeLibraries: excludeLibraries,
        includeDependentPackages: includeDependentPackages,
        startPage: startPage, pubScriptValue: pubScript,
        dartBinaryValue: dartBinary, indentJSON: indentJSON, sdk: sdk);
    viewer.addBackViewerCode();
    if (compile || serve) {
      result.then((success) {
        if (success) {
          viewer.createViewer(serve);
        }
      });
    }
  } else if (compile || serve) {
    gen.pubScript = pubScript;
    gen.dartBinary = dartBinary;
    viewer.createViewer(serve);
  }
  return result;
}
