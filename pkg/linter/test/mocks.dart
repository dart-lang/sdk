// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/error/error.dart';

class MockDiagnosticType implements DiagnosticType {
  @override
  late String displayName;

  @override
  late String name;

  @override
  late int ordinal;

  @override
  late DiagnosticSeverity severity;

  @override
  int compareTo(DiagnosticType other) => 0;

  @override
  String toString() => 'MockErrorType';
}

class MockIOSink implements IOSink {
  @override
  late Encoding encoding;

  @override
  Future<void> get done => Future.value();

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) => Future.value();

  @override
  Future<void> close() => Future.value();

  @override
  Future<void> flush() => Future.value();

  @override
  void write(Object? obj) {}

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? obj = '']) {}
}

class TestDiagnosticCode extends DiagnosticCode {
  @override
  late DiagnosticSeverity severity;

  @override
  late DiagnosticType type;

  TestDiagnosticCode(String name, String message)
    : super(
        problemMessage: message,
        name: name,
        uniqueName: 'TestErrorCode.$name',
      );
}
