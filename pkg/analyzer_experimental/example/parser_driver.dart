#!/usr/bin/env dart

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_experimental/src/generated/ast.dart';
import 'package:analyzer_experimental/src/generated/error.dart';
import 'package:analyzer_experimental/src/generated/java_core.dart';
import 'package:analyzer_experimental/src/generated/parser.dart';
import 'package:analyzer_experimental/src/generated/scanner.dart';

import 'dart:io';


main() {

  print('working dir ${new File('.').fullPathSync()}');

  var args = new Options().arguments;
  if (args.length == 0) {
    print('Usage: parser_driver [files_to_parse]');
    exit(0);
  }

  for (var arg in args) {
    _parse(new File(arg));
  }

}

_parse(File file) {
  var src = file.readAsStringSync();
  var errorListener = new _ErrorCollector();
  var scanner = new StringScanner(null, src, errorListener);
  var token = scanner.tokenize();
  var parser = new Parser(null, errorListener);
  var unit = parser.parseCompilationUnit(token);

  var visitor = new _ASTVisitor();
  unit.accept(visitor);

  for (var error in errorListener.errors) {
    print(error);
  }
}

class _ErrorCollector extends AnalysisErrorListener {
  List<AnalysisError> errors;
  _ErrorCollector() : errors = new List<AnalysisError>();
  onError(error) => errors.add(error);
}

class _ASTVisitor extends GeneralizingASTVisitor {
  visitNode(ASTNode node) {
    print('${node.runtimeType} : <"${node.toString()}">');
    return super.visitNode(node);
  }
}

