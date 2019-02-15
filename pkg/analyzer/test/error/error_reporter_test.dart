// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:source_span/source_span.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../generated/test_support.dart';
import '../src/dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ErrorReporterTest);
  });
}

@reflectiveTest
class ErrorReporterTest extends DriverResolutionTest {
  var listener = GatheringErrorListener();

  test_creation() async {
    var source = TestSource();
    expect(ErrorReporter(listener, source), isNotNull);
  }

  test_reportErrorForElement_named() async {
    addTestFile('class A {}');
    await resolveTestFile();

    var element = findElement.class_('A');
    var reporter = ErrorReporter(listener, element.source);
    reporter.reportErrorForElement(
      StaticWarningCode.CAST_TO_NON_TYPE,
      element,
      ['A'],
    );

    var error = listener.errors[0];
    expect(error.offset, element.nameOffset);
  }

  test_reportErrorForElement_unnamed() async {
    addTestFile(r'''
import 'dart:async';
import 'dart:math';
''');
    await resolveTestFile();

    var element = findElement.import('dart:math');

    var reporter = ErrorReporter(listener, element.source);
    reporter.reportErrorForElement(
      StaticWarningCode.CAST_TO_NON_TYPE,
      element,
      ['A'],
    );

    var error = listener.errors[0];
    expect(error.offset, element.nameOffset);
  }

  test_reportErrorForSpan() async {
    var source = TestSource();
    var reporter = ErrorReporter(listener, source);

    var text = '''
foo: bar
zap: baz
''';

    var offset = text.indexOf('baz');
    var length = 'baz'.length;

    var span = SourceSpanBase(
      SourceLocation(offset),
      SourceLocation(offset + length),
      'baz',
    );

    reporter.reportErrorForSpan(
      AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUE,
      span,
      ['test', 'zip', 'zap'],
    );
    expect(listener.errors, hasLength(1));
    expect(listener.errors.first.offset, offset);
    expect(listener.errors.first.length, length);
  }

  test_reportTypeErrorForNode_differentNames() async {
    newFile('/test/lib/a.dart', content: 'class A {}');
    newFile('/test/lib/b.dart', content: 'class B {}');
    addTestFile(r'''
import 'package:test/a.dart';
import 'package:test/b.dart';

main() {
  x;
}
''');
    await resolveTestFile();

    var aImport = findElement.importFind('package:test/a.dart');
    var bImport = findElement.importFind('package:test/b.dart');

    var firstType = aImport.class_('A').type;
    var secondType = bImport.class_('B').type;

    var reporter = ErrorReporter(listener, firstType.element.source);

    reporter.reportTypeErrorForNode(
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
      findNode.simple('x'),
      [firstType, secondType],
    );

    var error = listener.errors[0];
    expect(error.message, isNot(contains('(')));
  }

  test_reportTypeErrorForNode_sameName() async {
    newFile('/test/lib/a.dart', content: 'class A {}');
    newFile('/test/lib/b.dart', content: 'class A {}');
    addTestFile(r'''
import 'package:test/a.dart';
import 'package:test/b.dart';

main() {
  x;
}
''');
    await resolveTestFile();

    var aImport = findElement.importFind('package:test/a.dart');
    var bImport = findElement.importFind('package:test/b.dart');

    var firstType = aImport.class_('A').type;
    var secondType = bImport.class_('A').type;

    var reporter = ErrorReporter(listener, firstType.element.source);
    reporter.reportTypeErrorForNode(
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
      findNode.simple('x'),
      [firstType, secondType],
    );

    var error = listener.errors[0];
    expect(error.message, contains('('));
  }

  test_reportTypeErrorForNode_sameName_functionType() async {
    newFile('/test/lib/a.dart', content: 'class A{}');
    newFile('/test/lib/b.dart', content: 'class A{}');
    addTestFile(r'''
import 'a.dart' as a;
import 'b.dart' as b;

a.A Function() fa;
b.A Function() fb;

main() {
  x;
}
''');
    await resolveTestFile();

    var fa = findNode.topLevelVariableDeclaration('fa');
    var fb = findNode.topLevelVariableDeclaration('fb');

    var source = result.unit.declaredElement.source;
    var reporter = ErrorReporter(listener, source);
    reporter.reportTypeErrorForNode(
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
      findNode.simple('x'),
      [fa.variables.type.type, fb.variables.type.type],
    );

    var error = listener.errors[0];
    expect(error.message, contains('a.dart'));
    expect(error.message, contains('b.dart'));
  }

  test_reportTypeErrorForNode_sameName_nested() async {
    newFile('/test/lib/a.dart', content: 'class A{}');
    newFile('/test/lib/b.dart', content: 'class A{}');
    addTestFile(r'''
import 'a.dart' as a;
import 'b.dart' as b;

B<a.A> ba;
B<b.A> bb;
class B<T> {}

main() {
  x;
}
''');
    await resolveTestFile();

    var ba = findNode.topLevelVariableDeclaration('ba');
    var bb = findNode.topLevelVariableDeclaration('bb');

    var source = result.unit.declaredElement.source;
    var reporter = ErrorReporter(listener, source);
    reporter.reportTypeErrorForNode(
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
      findNode.simple('x'),
      [ba.variables.type.type, bb.variables.type.type],
    );

    var error = listener.errors[0];
    expect(error.message, contains('a.dart'));
    expect(error.message, contains('b.dart'));
  }
}
