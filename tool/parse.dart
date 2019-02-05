// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/string_source.dart';

import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:meta/meta.dart';

class _ErrorListener implements AnalysisErrorListener {
  final errors = <AnalysisError>[];

  @override
  void onError(AnalysisError error) {
    errors.add(error);
  }

  void throwIfErrors() {
    if (errors.isNotEmpty) {
      throw new Exception(errors);
    }
  }
}

class CompilationUnitParser {
  CompilationUnit parse({@required String contents, @required String name}) {
    var reader = new CharSequenceReader(contents);
    var stringSource = new StringSource(contents, name);
    var errorListener = new _ErrorListener();
    var scanner = new Scanner(stringSource, reader, errorListener);
    var startToken = scanner.tokenize();
    errorListener.throwIfErrors();

    var parser = new Parser(stringSource, errorListener);
    var cu = parser.parseCompilationUnit(startToken);
    errorListener.throwIfErrors();

    return cu;
  }
}
