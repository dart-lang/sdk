// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/project.dart';
import 'package:analyzer/src/lint/pub.dart';
import 'package:front_end/src/scanner/token.dart';

class CollectingSink extends MockIOSink {
  final StringBuffer buffer = new StringBuffer();

  @override
  String toString() => buffer.toString();

  String trim() => toString().trim();

  @override
  write(obj) {
    buffer.write(obj);
  }

  @override
  writeln([Object obj = '']) {
    buffer.writeln(obj);
  }
}

class MockErrorType implements ErrorType {
  @override
  String displayName;

  @override
  String name;

  @override
  int ordinal;

  @override
  ErrorSeverity severity;

  @override
  int compareTo(ErrorType other) => 0;

  @override
  String toString() => 'MockErrorType';
}

class MockIOSink implements IOSink {
  @override
  Encoding encoding;

  @override
  Future get done => null;

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace stackTrace]) {}

  @override
  Future addStream(Stream<List<int>> stream) => null;

  @override
  Future close() => null;

  @override
  Future flush() => null;

  @override
  void write(Object obj) {}

  @override
  void writeAll(Iterable objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object obj = '']) {}
}

class MockPubVisitor implements PubspecVisitor {
  @override
  visitPackageAuthor(PSEntry author) {
    throw new Exception();
  }

  @override
  visitPackageAuthors(PSNodeList authors) {
    throw new Exception();
  }

  @override
  visitPackageDependencies(PSDependencyList dependencies) {
    throw new Exception();
  }

  @override
  visitPackageDependency(PSDependency dependency) {
    throw new Exception();
  }

  @override
  visitPackageDescription(PSEntry description) {
    throw new Exception();
  }

  @override
  visitPackageDevDependencies(PSDependencyList dependencies) {
    throw new Exception();
  }

  @override
  visitPackageDevDependency(PSDependency dependency) {
    throw new Exception();
  }

  @override
  visitPackageDocumentation(PSEntry documentation) {
    throw new Exception();
  }

  @override
  visitPackageHomepage(PSEntry homepage) {
    throw new Exception();
  }

  @override
  visitPackageName(PSEntry name) {
    throw new Exception();
  }

  @override
  visitPackageVersion(PSEntry version) {
    throw new Exception();
  }
}

class MockReporter implements Reporter {
  List<LinterException> exceptions = <LinterException>[];

  List<String> warnings = <String>[];

  MockReporter();

  @override
  void exception(LinterException exception) {
    exceptions.add(exception);
  }

  @override
  void warn(String message) {
    warnings.add(message);
  }
}

class MockRule implements LintRule {
  @override
  ErrorReporter reporter;

  @override
  String description;

  @override
  String details;

  ProjectVisitor projectVisitor;

  PubspecVisitor pubspecVisitor;
  AstVisitor visitor;

  @override
  Group group;

  @override
  LintCode lintCode;

  @override
  Maturity maturity;

  @override
  String name;

  @override
  int compareTo(LintRule other) => 0;

  @override
  ProjectVisitor getProjectVisitor() => projectVisitor;

  @override
  PubspecVisitor getPubspecVisitor() => pubspecVisitor;

  @override
  AstVisitor getVisitor() => visitor;

  @override
  noSuchMethod(Invocation invocation) => null;

  @override
  void reportLint(AstNode node, {bool ignoreSyntheticNodes: true}) {}

  @override
  void reportLintForToken(Token token, {bool ignoreSyntheticTokens: true}) {}

  @override
  void reportPubLint(PSNode node) {}
}

class MockSource implements Source {
  @override
  TimestampedData<String> contents;

  @override
  String encoding;

  @override
  String fullName;

  @override
  bool isInSystemLibrary;

  @override
  Source librarySource;

  @override
  int modificationStamp;

  @override
  String shortName;

  @override
  Source source;

  @override
  Uri uri;

  @override
  UriKind uriKind;

  @override
  // ignore: avoid_returning_null
  bool exists() => null;
}

class TestErrorCode extends ErrorCode {
  @override
  ErrorSeverity errorSeverity;

  @override
  ErrorType type;

  TestErrorCode(String name, String message) : super(name, message);
}
