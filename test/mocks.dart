// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/project.dart';
import 'package:analyzer/src/lint/pub.dart';
import 'package:linter/src/analyzer.dart';

class CollectingSink extends MockIOSink {
  final StringBuffer buffer = StringBuffer();

  @override
  String toString() => buffer.toString();

  String trim() => toString().trim();

  @override
  void write(obj) {
    buffer.write(obj);
  }

  @override
  void writeln([Object? obj = '']) {
    buffer.writeln(obj);
  }
}

class MockErrorType implements ErrorType {
  @override
  late String displayName;

  @override
  late String name;

  @override
  late int ordinal;

  @override
  late ErrorSeverity severity;

  @override
  int compareTo(ErrorType other) => 0;

  @override
  String toString() => 'MockErrorType';
}

class MockIOSink implements IOSink {
  @override
  late Encoding encoding;

  @override
  Future get done => Future.value();

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future addStream(Stream<List<int>> stream) => Future.value();

  @override
  Future close() => Future.value();

  @override
  Future flush() => Future.value();

  @override
  void write(Object? obj) {}

  @override
  void writeAll(Iterable objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? obj = '']) {}
}

class MockPubVisitor implements PubspecVisitor {
  @override
  void visitPackageAuthor(PSEntry author) {
    throw Exception();
  }

  @override
  void visitPackageAuthors(PSNodeList authors) {
    throw Exception();
  }

  @override
  void visitPackageDependencies(PSDependencyList dependencies) {
    throw Exception();
  }

  @override
  void visitPackageDependency(PSDependency dependency) {
    throw Exception();
  }

  @override
  void visitPackageDependencyOverride(PSDependency dependency) {
    throw Exception();
  }

  @override
  void visitPackageDependencyOverrides(PSDependencyList dependencies) {
    throw Exception();
  }

  @override
  void visitPackageDescription(PSEntry description) {
    throw Exception();
  }

  @override
  void visitPackageDevDependencies(PSDependencyList dependencies) {
    throw Exception();
  }

  @override
  void visitPackageDevDependency(PSDependency dependency) {
    throw Exception();
  }

  @override
  void visitPackageDocumentation(PSEntry documentation) {
    throw Exception();
  }

  @override
  void visitPackageHomepage(PSEntry homepage) {
    throw Exception();
  }

  @override
  void visitPackageName(PSEntry name) {
    throw Exception();
  }

  @override
  void visitPackageVersion(PSEntry version) {
    throw Exception();
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
  late ErrorReporter reporter;

  @override
  late String description;

  @override
  late String details;

  ProjectVisitor? projectVisitor;

  PubspecVisitor? pubspecVisitor;
  AstVisitor? visitor;

  @override
  late Group group;

  @override
  late LintCode lintCode;

  @override
  late Maturity maturity;

  @override
  late String name;

  @override
  int compareTo(LintRule other) => 0;

  @override
  ProjectVisitor? getProjectVisitor() => projectVisitor;

  @override
  PubspecVisitor? getPubspecVisitor() => pubspecVisitor;

  @override
  AstVisitor? getVisitor() => visitor;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  void reportPubLint(PSNode node) {}
}

class MockSource implements Source {
  @override
  late TimestampedData<String> contents;

  @override
  late String encoding;

  @override
  late String fullName;

  @override
  late bool isInSystemLibrary;

  @override
  late Source librarySource;

  @override
  late int modificationStamp;

  @override
  late String shortName;

  @override
  late Source source;

  @override
  late Uri uri;

  @override
  late UriKind uriKind;

  @override
  bool exists() => false;
}

class TestErrorCode extends ErrorCode {
  @override
  late ErrorSeverity errorSeverity;

  @override
  late ErrorType type;

  TestErrorCode(String name, String message)
      : super(
          message: message,
          name: name,
          uniqueName: 'TestErrorCode.$name',
        );
}
