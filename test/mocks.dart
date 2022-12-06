// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/linter.dart';

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

class MockReporter extends Reporter {
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

class MockSource extends BasicSource {
  @override
  final String fullName;

  MockSource(this.fullName) : super(Uri.file(fullName));

  @override
  TimestampedData<String> get contents => TimestampedData<String>(0, '');

  @override
  bool exists() => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestErrorCode extends ErrorCode {
  @override
  late ErrorSeverity errorSeverity;

  @override
  late ErrorType type;

  TestErrorCode(String name, String message)
      : super(
          problemMessage: message,
          name: name,
          uniqueName: 'TestErrorCode.$name',
        );
}
