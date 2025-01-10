// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:source_span/source_span.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../generated/test_support.dart';
import '../src/dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ErrorReporterTest);
  });
}

@reflectiveTest
class ErrorReporterTest extends PubPackageResolutionTest {
  var listener = GatheringErrorListener();

  test_atElement_named() async {
    await resolveTestCode('class A {}');
    var element = findElement2.class_('A');
    var firstFragment = element.firstFragment;
    var reporter =
        ErrorReporter(listener, firstFragment.libraryFragment.source);
    reporter.atElement2(
      element,
      CompileTimeErrorCode.CAST_TO_NON_TYPE,
      arguments: ['A'],
    );

    var error = listener.errors[0];
    expect(error.offset, firstFragment.nameOffset2);
  }

  test_atElement_unnamed() async {
    await resolveTestCode(r'''
extension on int {}
''');
    var element = findElement2.unnamedExtension();

    var firstFragment = element.firstFragment;
    var reporter =
        ErrorReporter(listener, firstFragment.libraryFragment.source);
    reporter.atElement2(
      element,
      CompileTimeErrorCode.CAST_TO_NON_TYPE,
      arguments: ['A'],
    );

    var error = listener.errors[0];
    expect(error.offset, -1);
  }

  test_atNode_types_differentNames() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    newFile('$testPackageLibPath/b.dart', 'class B {}');
    await resolveTestCode(r'''
import 'package:test/a.dart';
import 'package:test/b.dart';

main() {
  x;
}
''');
    var aImport = findElement2.importFind('package:test/a.dart');
    var bImport = findElement2.importFind('package:test/b.dart');

    var firstType = aImport.class_('A').instantiate(
      typeArguments: [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    var secondType = bImport.class_('B').instantiate(
      typeArguments: [],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    var reporter = ErrorReporter(
        listener, firstType.element3.firstFragment.libraryFragment.source);

    reporter.atNode(
      findNode.simple('x'),
      CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
      arguments: [firstType, secondType, ''],
    );

    var error = listener.errors[0];
    expect(error.message, isNot(contains('(')));
  }

  test_atNode_types_sameName() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    newFile('$testPackageLibPath/b.dart', 'class A {}');
    await resolveTestCode(r'''
import 'package:test/a.dart';
import 'package:test/b.dart';

main() {
  x;
}
''');
    var aImport = findElement2.importFind('package:test/a.dart');
    var bImport = findElement2.importFind('package:test/b.dart');

    var firstType = aImport.class_('A').instantiate(
      typeArguments: [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    var secondType = bImport.class_('A').instantiate(
      typeArguments: [],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    var reporter = ErrorReporter(
        listener, firstType.element3.firstFragment.libraryFragment.source);
    reporter.atNode(
      findNode.simple('x'),
      CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
      arguments: [firstType, secondType, ''],
    );

    var error = listener.errors[0];
    expect(error.message, contains('('));
  }

  test_atNode_types_sameName_functionType() async {
    newFile('$testPackageLibPath/a.dart', 'class A{}');
    newFile('$testPackageLibPath/b.dart', 'class A{}');
    await resolveTestCode(r'''
import 'a.dart' as a;
import 'b.dart' as b;

a.A Function() fa;
b.A Function() fb;

main() {
  x;
}
''');
    var fa = findNode.topLevelVariableDeclaration('fa');
    var fb = findNode.topLevelVariableDeclaration('fb');

    var source = result.unit.declaredFragment!.libraryFragment!.source;
    var reporter = ErrorReporter(listener, source);
    reporter.atNode(
      findNode.simple('x'),
      CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
      arguments: [fa.variables.type!.type!, fb.variables.type!.type!, ''],
    );

    var error = listener.errors[0];
    expect(error.message, contains('a.dart'));
    expect(error.message, contains('b.dart'));
  }

  test_atNode_types_sameName_nested() async {
    newFile('$testPackageLibPath/a.dart', 'class A{}');
    newFile('$testPackageLibPath/b.dart', 'class A{}');
    await resolveTestCode(r'''
import 'a.dart' as a;
import 'b.dart' as b;

B<a.A> ba;
B<b.A> bb;
class B<T> {}

main() {
  x;
}
''');
    var ba = findNode.topLevelVariableDeclaration('ba');
    var bb = findNode.topLevelVariableDeclaration('bb');

    var source = result.unit.declaredFragment!.libraryFragment!.source;
    var reporter = ErrorReporter(listener, source);
    reporter.atNode(
      findNode.simple('x'),
      CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
      arguments: [ba.variables.type!.type!, bb.variables.type!.type!, ''],
    );

    var error = listener.errors[0];
    expect(error.message, contains('a.dart'));
    expect(error.message, contains('b.dart'));
  }

  test_atSourceSpan() async {
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

    reporter.atSourceSpan(
      span,
      AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUE,
      arguments: ['test', 'zip', 'zap'],
    );
    expect(listener.errors, hasLength(1));
    expect(listener.errors.first.offset, offset);
    expect(listener.errors.first.length, length);
  }

  test_creation() async {
    var source = TestSource();
    var reporter = ErrorReporter(listener, source);
    expect(reporter, isNotNull);
  }
}
