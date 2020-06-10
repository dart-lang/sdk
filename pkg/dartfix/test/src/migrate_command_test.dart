// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analysis_server_client/protocol.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dartfix/src/migrate/apply.dart';
import 'package:dartfix/src/migrate/display.dart';
import 'package:test/test.dart';

void main() {
  defineMigrateTests();
}

void defineMigrateTests() {
  group('issue render', defineIssueRenderTests);
  group('SourcePrinter', defineSourcePrinterTests);
  group('applyEdits', defineApplyEditsTests);
}

void defineIssueRenderTests() {
  IssueRenderer renderer;
  TestLogger logger;

  setUp(() {
    logger = TestLogger();
    renderer = IssueRenderer(logger, '.');
  });

  test('issue1', () {
    AnalysisError issue = AnalysisError(
      AnalysisErrorSeverity.ERROR,
      AnalysisErrorType.COMPILE_TIME_ERROR,
      Location('foo/bar/baz.dart', 1, 2, 3, 4),
      'My message.',
      'my_error_code',
    );

    renderer.render(issue);

    expect(
      logger.stdoutText.trim(),
      contains(platformPath(
          'error • My message at foo/bar/baz.dart:3:4 • (my_error_code)')),
    );
    expect(logger.stderrText, isEmpty);
  });

  test('issue2', () {
    AnalysisError issue = AnalysisError(
      AnalysisErrorSeverity.INFO,
      AnalysisErrorType.TODO,
      Location('foo/bar/qux.dart', 1, 2, 3, 4),
      'todo: My message.',
      'todo',
    );

    renderer.render(issue);

    expect(
        logger.stdoutText,
        contains(platformPath(
            'info • todo: My message at foo/bar/qux.dart:3:4 • (todo)')));

    expect(logger.stderrText, isEmpty);
  });
}

void defineSourcePrinterTests() {
  SourcePrinter printer;

  setUp(() {
    printer = SourcePrinter('''
void main() {
  Cat one = Cat('Tabby');
  print(one);
}

class Cat {
  final String name;
  String color;

  Cat(this.name);

  String toString() {
    return name?.toString() + ' is ' + color.toString();
  }
}
''');
  });

  test('add and remove', () {
    printer.insertText(192, '?');
    printer.deleteRange(164, 1);
    printer.insertText(98, '?');

    StringBuffer buf = StringBuffer();
    printer.processChangedLines((lineNumber, lineText) {
      buf.writeln('$lineNumber ${lineText.trim()}');
    });

    expect(buf.toString().trim(), '''
8 String\x1B[7m?\x1B[0m color;
13 return name?\x1B[31m\x1B[7m.\x1B[0mtoString() + \' is \' + color\x1B[7m?\x1B[0m.toString();''');
  });
}

void defineApplyEditsTests() {
  test('insert', () {
    String source = 'one two\nthree four';
    SourceFileEdit edit = SourceFileEdit('foo.dart', 0, edits: [
      SourceEdit(0, 0, 'five '),
    ]);

    String result = applyEdits(edit, source);
    expect(result, 'five one two\nthree four');
  });

  test('delete', () {
    String source = 'one two\nthree four';
    SourceFileEdit edit = SourceFileEdit('foo.dart', 0, edits: [
      SourceEdit(0, 4, ''),
      SourceEdit(8, 6, ''),
    ]);

    String result = applyEdits(edit, source);
    expect(result, 'two\nfour');
  });

  test('insert and delete', () {
    String source = 'one two\nthree four';
    SourceFileEdit edit = SourceFileEdit('foo.dart', 0, edits: [
      SourceEdit(13, 5, ''),
      SourceEdit(8, 0, 'six '),
      SourceEdit(7, 1, ' '),
    ]);

    String result = applyEdits(edit, source);
    expect(result, 'one two six three');
  });
}

class TestLogger implements Logger {
  final bool debug;

  @override
  final Ansi ansi;
  final stdoutBuffer = StringBuffer();
  final stderrBuffer = StringBuffer();

  TestLogger({this.debug = false}) : ansi = Ansi(false);

  @override
  void flush() {}

  @override
  bool get isVerbose => debug;

  @override
  Progress progress(String message) {
    return SimpleProgress(this, message);
  }

  @override
  void stdout(String message) {
    stdoutBuffer.writeln(message);
  }

  @override
  void stderr(String message) {
    stderrBuffer.writeln(message);
  }

  @override
  void trace(String message) {
    if (debug) {
      stdoutBuffer.writeln(message);
    }
  }

  String get stdoutText => stdoutBuffer.toString();

  String get stderrText => stderrBuffer.toString();
}

String platformPath(String path) {
  return path.replaceAll('/', Platform.pathSeparator);
}
