// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart'
    show SourceChange, SourceEdit;
import 'package:analysis_server/src/services/refactoring/agnostic/change_method_signature.dart';
import 'package:analysis_server/src/services/refactoring/framework/formal_parameter.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_context.dart';
import 'package:analysis_server/src/services/refactoring/framework/write_invocation_arguments.dart'
    show ArgumentsTrailingComma;
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../abstract_context.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ChangeMethodSignatureTest_analyzeSelection);
    defineReflectiveTests(ChangeMethodSignatureTest_computeSourceChange);
  });
}

class AbstractChangeMethodSignatureTest extends AbstractContextTest {
  late final AbstractRefactoringContext refactoringContext;
  late final SelectionState selectionState;
  late final ValidSelectionState validSelectionState;

  /// Create [testFile] with [rawCode], analyze availability in it.
  Future<Availability> _analyzeAvailability(String rawCode) async {
    final testCode = TestCode.parse(rawCode);
    newFile(testFile.path, testCode.code);

    await _buildRefactoringContext(
      file: testFile,
      testCode: testCode,
    );

    return analyzeAvailability(
      refactoringContext: refactoringContext,
    );
  }

  /// Create [testFile] with [rawCode], analyze selection in it.
  Future<void> _analyzeSelection(String rawCode) async {
    final availability = await _analyzeAvailability(rawCode);
    availability as Available;

    selectionState = await analyzeSelection(
      available: availability,
    );
  }

  Future<void> _analyzeValidSelection(String rawCode) async {
    await _analyzeSelection(rawCode);
    validSelectionState = selectionState as ValidSelectionState;
  }

  void _assertTextExpectation(String actual, String expected) {
    if (actual != expected) {
      print('-' * 64);
      print(actual.trimRight());
      print('-' * 64);
    }
    expect(actual, expected);
  }

  Future<void> _buildRefactoringContext({
    required File file,
    required TestCode testCode,
  }) async {
    // There must be exactly one position.
    final singlePosition = testCode.positions.singleOrNull;
    final singleRange = testCode.ranges.singleOrNull;
    final SourceRange selectionRange;
    if (singlePosition != null && singleRange == null) {
      selectionRange = SourceRange(singlePosition.offset, 0);
    } else if (singlePosition == null && singleRange != null) {
      selectionRange = singleRange.sourceRange;
    } else {
      fail('Expected exactly one: $singlePosition $singleRange');
    }

    final analysisSession = await session;

    final resolvedLibraryResult = await analysisSession.getResolvedLibrary(
      file.path,
    );
    resolvedLibraryResult as ResolvedLibraryResult;

    final unitResult = resolvedLibraryResult.unitWithPath(file.path)!;

    refactoringContext = AbstractRefactoringContext(
      searchEngine: SearchEngineImpl(allDrivers),
      startSessions: [resolvedLibraryResult.session],
      resolvedLibraryResult: resolvedLibraryResult,
      resolvedUnitResult: unitResult,
      selectionOffset: selectionRange.offset,
      selectionLength: selectionRange.length,
      includeExperimental: true,
    );
  }

  String _elementToReferenceString(Element element) {
    final enclosingElement = element.enclosingElement2;
    final reference = (element as ElementImpl).reference;
    if (reference != null) {
      return _referenceToString(reference);
    } else if (element is ParameterElement) {
      final enclosingStr = enclosingElement != null
          ? _elementToReferenceString(enclosingElement)
          : 'root';
      return '$enclosingStr::@parameter::${element.name}';
    } else {
      return '${element.name}@${element.nameOffset}';
    }
  }

  String _referenceToString(Reference reference) {
    final selfLibrary = refactoringContext.resolvedLibraryResult.element;
    final selfUriStr = '${selfLibrary.source.uri}';

    var name = reference.name;
    if (name == selfUriStr) {
      name = 'self';
    }

    final parent =
        reference.parent ?? (throw StateError('Should not go past libraries'));

    // A library.
    if (parent.parent == null) {
      return name;
    }

    // A unit of the self library.
    if (parent.name == '@unit' && name == 'self') {
      return 'self';
    }

    return '${_referenceToString(parent)}::$name';
  }
}

@reflectiveTest
class ChangeMethodSignatureTest_analyzeSelection
    extends AbstractChangeMethodSignatureTest {
  Future<void> test_classConstructor_fieldFormal_explicitType() async {
    await _analyzeSelection(r'''
class A {
  final num a;
  ^A(int this.a);
}
''');

    _assertSelectionState(selectionState, r'''
element: self::@class::A::@constructor::new
formalParameters
  id: 0
    kind: requiredPositional
    name: a
    typeStr: int
''');
  }

  Future<void> test_classConstructor_fieldFormal_implicitType() async {
    await _analyzeSelection(r'''
class A {
  final int a;
  ^A(this.a);
}
''');

    _assertSelectionState(selectionState, r'''
element: self::@class::A::@constructor::new
formalParameters
  id: 0
    kind: requiredPositional
    name: a
    typeStr: int
''');
  }

  Future<void> test_classConstructor_named_className() async {
    await _analyzeSelection(r'''
class A {
  A^.named(int a);
}
''');

    _assertSelectionState(selectionState, r'''
element: self::@class::A::@constructor::named
formalParameters
  id: 0
    kind: requiredPositional
    name: a
    typeStr: int
''');
  }

  Future<void> test_classConstructor_named_constructorName() async {
    await _analyzeSelection(r'''
class A {
  A.^named(int a);
}
''');

    _assertSelectionState(selectionState, r'''
element: self::@class::A::@constructor::named
formalParameters
  id: 0
    kind: requiredPositional
    name: a
    typeStr: int
''');
  }

  Future<void> test_classConstructor_named_constructorName2() async {
    await _analyzeSelection(r'''
class A {
  A.named^(int a);
}
''');

    _assertSelectionState(selectionState, r'''
element: self::@class::A::@constructor::named
formalParameters
  id: 0
    kind: requiredPositional
    name: a
    typeStr: int
''');
  }

  Future<void> test_classConstructor_superFormal_optionalNamed() async {
    await _analyzeSelection(r'''
class A {
  final int a;
  A({this.a});
}

class B extends A {
  ^B({super.a});
}
''');

    _assertSelectionState(selectionState, r'''
element: self::@class::B::@constructor::new
formalParameters
  id: 0
    kind: optionalNamed
    name: a
    typeStr: int
''');
  }

  Future<void> test_classConstructor_superFormal_optionalPositional() async {
    await _analyzeSelection(r'''
class A {
  final int? a;
  A([this.a]);
}

class B extends A {
  ^B([super.a]);
}
''');

    _assertSelectionState(selectionState, r'''
element: self::@class::B::@constructor::new
formalParameters
  id: 0
    kind: optionalPositional
    name: a
    typeStr: int?
''');
  }

  Future<void> test_classConstructor_superFormal_requiredNamed() async {
    await _analyzeSelection(r'''
class A {
  final int a;
  A({
    required this.a,
  });
}

class B extends A {
  ^B({
    required super.a,
  });
}
''');

    _assertSelectionState(selectionState, r'''
element: self::@class::B::@constructor::new
formalParameters
  id: 0
    kind: requiredNamed
    name: a
    typeStr: int
''');
  }

  Future<void> test_classConstructor_superFormal_requiredPositional() async {
    await _analyzeSelection(r'''
class A {
  final int a;
  A(this.a);
}

class B extends A {
  ^B(super.a);
}
''');

    _assertSelectionState(selectionState, r'''
element: self::@class::B::@constructor::new
formalParameters
  id: 0
    kind: requiredPositional
    name: a
    typeStr: int
''');
  }

  Future<void> test_classConstructor_unnamed_className() async {
    await _analyzeSelection(r'''
class A {
  ^A(int a);
}
''');

    _assertSelectionState(selectionState, r'''
element: self::@class::A::@constructor::new
formalParameters
  id: 0
    kind: requiredPositional
    name: a
    typeStr: int
''');
  }

  Future<void> test_classMethodDeclaration_atName() async {
    await _analyzeSelection(r'''
class A {
  void ^test(int a) {}
}
''');

    _assertSelectionState(selectionState, r'''
element: self::@class::A::@method::test
formalParameters
  id: 0
    kind: requiredPositional
    name: a
    typeStr: int
''');
  }

  Future<void> test_formalParameters_requiredNamed_full() async {
    await _analyzeSelection(r'''
void test({
  [!required int a!],
  required int b,
}) {}
''');

    _assertSelectionState(selectionState, r'''
element: self::@function::test
formalParameters
  id: 0
    kind: requiredNamed
    name: a
    typeStr: int
    selected
  id: 1
    kind: requiredNamed
    name: b
    typeStr: int
''');
  }

  Future<void> test_formalParameters_requiredNamed_multiple() async {
    await _analyzeSelection(r'''
void test({
  required int a,
  [!required int b,
  required int c,!]
  required int d,
}) {}
''');

    _assertSelectionState(selectionState, r'''
element: self::@function::test
formalParameters
  id: 0
    kind: requiredNamed
    name: a
    typeStr: int
  id: 1
    kind: requiredNamed
    name: b
    typeStr: int
    selected
  id: 2
    kind: requiredNamed
    name: c
    typeStr: int
    selected
  id: 3
    kind: requiredNamed
    name: d
    typeStr: int
''');
  }

  Future<void> test_formalParameters_requiredNamed_name_full() async {
    await _analyzeSelection(r'''
void test({
  required int [!aaaa!],
  required int bbbb,
}) {}
''');

    _assertSelectionState(selectionState, r'''
element: self::@function::test
formalParameters
  id: 0
    kind: requiredNamed
    name: aaaa
    typeStr: int
    selected
  id: 1
    kind: requiredNamed
    name: bbbb
    typeStr: int
''');
  }

  Future<void> test_formalParameters_requiredNamed_name_partial() async {
    await _analyzeSelection(r'''
void test({
  required int a[!aa!]a,
  required int bbbb,
}) {}
''');

    _assertSelectionState(selectionState, r'''
element: self::@function::test
formalParameters
  id: 0
    kind: requiredNamed
    name: aaaa
    typeStr: int
    selected
  id: 1
    kind: requiredNamed
    name: bbbb
    typeStr: int
''');
  }

  Future<void> test_formalParameters_requiredNamed_name_position() async {
    await _analyzeSelection(r'''
void test({
  required int ^a,
  required int b
}) {}
''');

    _assertSelectionState(selectionState, r'''
element: self::@function::test
formalParameters
  id: 0
    kind: requiredNamed
    name: a
    typeStr: int
    selected
  id: 1
    kind: requiredNamed
    name: b
    typeStr: int
''');
  }

  Future<void> test_formalParameters_requiredPositional_multiple() async {
    await _analyzeSelection(r'''
void test(int a, [!int b, int c,!] int d) {}
''');

    _assertSelectionState(selectionState, r'''
element: self::@function::test
formalParameters
  id: 0
    kind: requiredPositional
    name: a
    typeStr: int
  id: 1
    kind: requiredPositional
    name: b
    typeStr: int
    selected
  id: 2
    kind: requiredPositional
    name: c
    typeStr: int
    selected
  id: 3
    kind: requiredPositional
    name: d
    typeStr: int
''');
  }

  Future<void> test_formalParameters_requiredPositional_name() async {
    await _analyzeSelection(r'''
void test(int ^a, int b) {}
''');

    _assertSelectionState(selectionState, r'''
element: self::@function::test
formalParameters
  id: 0
    kind: requiredPositional
    name: a
    typeStr: int
    selected
  id: 1
    kind: requiredPositional
    name: b
    typeStr: int
''');
  }

  Future<void> test_kind_optionalNamed() async {
    await _analyzeSelection(r'''
void ^test({int? a}) {}
''');

    _assertSelectionState(selectionState, r'''
element: self::@function::test
formalParameters
  id: 0
    kind: optionalNamed
    name: a
    typeStr: int?
''');
  }

  Future<void> test_kind_optionalPositional() async {
    await _analyzeSelection(r'''
void ^test([int? a]) {}
''');

    _assertSelectionState(selectionState, r'''
element: self::@function::test
formalParameters
  id: 0
    kind: optionalPositional
    name: a
    typeStr: int?
''');
  }

  Future<void> test_kind_requiredNamed() async {
    await _analyzeSelection(r'''
void ^test({required int a}) {}
''');

    _assertSelectionState(selectionState, r'''
element: self::@function::test
formalParameters
  id: 0
    kind: requiredNamed
    name: a
    typeStr: int
''');
  }

  Future<void> test_kind_requiredPositional() async {
    await _analyzeSelection(r'''
void ^test(int a, String b) {}
''');

    _assertSelectionState(selectionState, r'''
element: self::@function::test
formalParameters
  id: 0
    kind: requiredPositional
    name: a
    typeStr: int
  id: 1
    kind: requiredPositional
    name: b
    typeStr: String
''');
  }

  Future<void> test_methodInvocation_notAvailable_externalPackage() async {
    newFile('$packagesRootPath/foo/lib/foo.dart', r'''
void test(int a, int b) {}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: '$packagesRootPath/foo'),
    );

    final availability = await _analyzeAvailability(r'''
import 'package:foo/foo.dart';

void f() {
  ^test(0, 1);
}
''');

    _assertAvailability(availability, r'''
NotAvailableExternalElement
''');
  }

  Future<void> test_methodInvocation_notAvailable_sdk() async {
    final availability = await _analyzeAvailability(r'''
import 'dart:math';

void f() {
  ^min(0, 1);
}
''');

    _assertAvailability(availability, r'''
NotAvailableExternalElement
''');
  }

  Future<void> test_methodInvocation_topFunction() async {
    await _analyzeSelection(r'''
void f() {
  ^test(0);
}

void test(int a) {}
''');

    _assertSelectionState(selectionState, r'''
element: self::@function::test
formalParameters
  id: 0
    kind: requiredPositional
    name: a
    typeStr: int
''');
  }

  Future<void> test_topFunctionDeclaration_afterParameterList() async {
    final availability = await _analyzeAvailability(r'''
void test()^ {}
''');

    _assertAvailability(availability, r'''
NotAvailableNoExecutableElement
''');
  }

  Future<void> test_topFunctionDeclaration_atName() async {
    await _analyzeSelection(r'''
void ^test(int a) {}
''');

    _assertSelectionState(selectionState, r'''
element: self::@function::test
formalParameters
  id: 0
    kind: requiredPositional
    name: a
    typeStr: int
''');
  }

  Future<void> test_topFunctionDeclaration_beforeName() async {
    final availability = await _analyzeAvailability(r'''
void ^ test() {}
''');

    _assertAvailability(availability, r'''
NotAvailableNoExecutableElement
''');
  }

  void _assertAvailability(Availability availability, String expected) {
    final buffer = StringBuffer();
    switch (availability) {
      case Available():
        buffer.writeln('Available');
      case NotAvailableExternalElement():
        buffer.writeln('NotAvailableExternalElement');
      case NotAvailableNoExecutableElement():
        buffer.writeln('NotAvailableNoExecutableElement');
    }

    _assertTextExpectation(buffer.toString(), expected);
  }

  void _assertSelectionState(SelectionState selectionState, String expected) {
    final buffer = StringBuffer();
    switch (selectionState) {
      case NoExecutableElementSelectionState():
        buffer.writeln('NoExecutableElementSelectionState');
      case UnexpectedSelectionState():
        buffer.writeln('UnexpectedSelectionState');
      case ValidSelectionState():
        buffer.write('element: ');
        buffer.writeln(_elementToReferenceString(selectionState.element));
        buffer.writeln('formalParameters');
        for (final formalParameter in selectionState.formalParameters) {
          buffer.writeln('  id: ${formalParameter.id}');
          buffer.writeln('    kind: ${formalParameter.kind.name}');
          buffer.writeln('    name: ${formalParameter.name}');
          buffer.writeln('    typeStr: ${formalParameter.typeStr}');
          if (formalParameter.isSelected) {
            buffer.writeln('    selected');
          }
        }
    }

    _assertTextExpectation(buffer.toString(), expected);
  }
}

@reflectiveTest
class ChangeMethodSignatureTest_computeSourceChange
    extends AbstractChangeMethodSignatureTest {
  Future<void> test_argumentsTrailingComma_always_add() async {
    await _analyzeValidSelection(r'''
void ^test(int a, double b) {}

void f() {
  test(0, 1.2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.always,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test(double b, int a) {}

void f() {
  test(
    1.2,
    0,
  );
}
''');
  }

  Future<void> test_argumentsTrailingComma_ifPresent_false() async {
    await _analyzeValidSelection(r'''
void ^test(int a, double b) {}

void f() {
  test(0, 1.2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test(double b, int a) {}

void f() {
  test(1.2, 0);
}
''');
  }

  Future<void> test_argumentsTrailingComma_ifPresent_true() async {
    await _analyzeValidSelection(r'''
void ^test(int a, double b) {}

void f() {
  test(
    0,
    1.2,
  );
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test(double b, int a) {}

void f() {
  test(
    1.2,
    0,
  );
}
''');
  }

  Future<void> test_argumentsTrailingComma_never_remove() async {
    await _analyzeValidSelection(r'''
void ^test(int a, double b) {}

void f() {
  test(
    0,
    1.2,
  );
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.never,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test(double b, int a) {}

void f() {
  test(1.2, 0);
}
''');
  }

  Future<void>
      test_classConstructor_optionalNamed_toRequiredPositional() async {
    await _analyzeValidSelection(r'''
class A {
  final int a;
  final int b;
  ^A({
    this.a = 0,
    this.b = 1,
  });
}

class B extends A {
  B() : super(a: 2, b: 3);
}

void f() {
  A(a: 4, b: 5);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
class A {
  final int a;
  final int b;
  A(this.a, this.b);
}

class B extends A {
  B() : super(2, 3);
}

void f() {
  A(4, 5);
}
''');
  }

  Future<void>
      test_classConstructor_redirectingConstructorInvocation_named() async {
    await _analyzeValidSelection(r'''
class A {
  final int a;
  ^A.named(int a);
  A() : this.named(0);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
class A {
  final int a;
  A.named({required int a});
  A() : this.named(a: 0);
}
''');
  }

  Future<void>
      test_classConstructor_redirectingConstructorInvocation_unnamed() async {
    await _analyzeValidSelection(r'''
class A {
  final int a;
  ^A(int a);
  A.named() : this(0);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
class A {
  final int a;
  A({required int a});
  A.named() : this(a: 0);
}
''');
  }

  Future<void> test_classConstructor_requiredNamed_reorder() async {
    await _analyzeValidSelection(r'''
class A {
  final int a;
  final int b;
  ^A({
    required this.a,
    required this.b,
  });
}

class B extends A {
  B() : super(a: 0, b: 1);
}

void f() {
  A(a: 2, b: 3);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredNamed,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.always,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
class A {
  final int a;
  final int b;
  A({
    required this.b,
    required this.a,
  });
}

class B extends A {
  B() : super(b: 1, a: 0);
}

void f() {
  A(b: 3, a: 2);
}
''');
  }

  Future<void>
      test_classConstructor_requiredNamed_toRequiredPositional() async {
    await _analyzeValidSelection(r'''
class A {
  final int a;
  final int b;
  ^A({
    required this.a,
    required this.b,
  });
}

class B extends A {
  B() : super(a: 0, b: 1);
}

void f() {
  A(a: 2, b: 3);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
class A {
  final int a;
  final int b;
  A(this.a, this.b);
}

class B extends A {
  B() : super(0, 1);
}

void f() {
  A(2, 3);
}
''');
  }

  Future<void> test_classConstructor_requiredPositional_reorder() async {
    await _analyzeValidSelection(r'''
class A {
  final int a;
  final int b;
  ^A(this.a, this.b);
}

class B extends A {
  B() : super(0, 1);
}

void f() {
  A(2, 3);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
class A {
  final int a;
  final int b;
  A(this.b, this.a);
}

class B extends A {
  B() : super(1, 0);
}

void f() {
  A(3, 2);
}
''');
  }

  Future<void>
      test_classConstructor_requiredPositional_toRequiredNamed() async {
    await _analyzeValidSelection(r'''
class A {
  final int a;
  final int b;
  ^A(this.a, this.b);
}

class B extends A {
  B() : super(0, 1);
}

void f() {
  A(2, 3);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.always,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
class A {
  final int a;
  final int b;
  A({
    required this.a,
    required this.b,
  });
}

class B extends A {
  B() : super(a: 0, b: 1);
}

void f() {
  A(a: 2, b: 3);
}
''');
  }

  Future<void> test_classConstructor_superConstructorInvocation_named() async {
    await _analyzeValidSelection(r'''
class A {
  final int a;
  ^A.named(int a);
}

class B extends A {
  B() : super.named(0);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
class A {
  final int a;
  A.named({required int a});
}

class B extends A {
  B() : super.named(a: 0);
}
''');
  }

  Future<void>
      test_classConstructor_superConstructorInvocation_unnamed() async {
    await _analyzeValidSelection(r'''
class A {
  final int a;
  ^A(int a);
}

class B extends A {
  B() : super(0);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
class A {
  final int a;
  A({required int a});
}

class B extends A {
  B() : super(a: 0);
}
''');
  }

  Future<void> test_classMethod_optionalNamed_reorder_less() async {
    await _analyzeValidSelection(r'''
class A {
  void ^test({int? a, int? b, int? c}) {}
}

class B extends A {
  void test({int? a, int? b}) {}
}

void f(A a, B b) {
  a.test(a: 0, b: 1, c: 2);
  b.test(a: 3, b: 4);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 2,
          kind: FormalParameterKind.optionalNamed,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.optionalNamed,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.optionalNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
class A {
  void test({int? c, int? b, int? a}) {}
}

class B extends A {
  void test({int? b, int? a}) {}
}

void f(A a, B b) {
  a.test(c: 2, b: 1, a: 0);
  b.test(b: 4, a: 3);
}
''');
  }

  Future<void> test_classMethod_optionalNamed_reorder_more() async {
    await _analyzeValidSelection(r'''
class A {
  void ^test({int? a, int? b}) {}
}

class B extends A {
  void test({int? a, int? b, int? c, int? d}) {}
}

void f(A a, B b) {
  a.test(a: 0, b: 1);
  b.test(a: 2, b: 3, c: 4, d: 5);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.optionalNamed,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.optionalNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
class A {
  void test({int? b, int? a}) {}
}

class B extends A {
  void test({int? b, int? a, int? c, int? d}) {}
}

void f(A a, B b) {
  a.test(b: 1, a: 0);
  b.test(b: 3, a: 2, c: 4, d: 5);
}
''');
  }

  Future<void> test_classMethod_requiredNamed_remove() async {
    await _analyzeValidSelection(r'''
class A {
  void ^test({
    required int a,
    required int b,
    required int c,
  }) {}
}

class B extends A {
  void test({
    required int a,
    required int b,
    required int c,
  }) {}
}

void f(A a, B b) {
  a.test(a: 0, b: 1, c: 2);
  b.test(a: 3, b: 4, c: 5);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
        FormalParameterUpdate(
          id: 2,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      removedNamedFormalParameters: {'b'},
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
class A {
  void test({
    required int a,
    required int c,
  }) {}
}

class B extends A {
  void test({
    required int a,
    required int c,
  }) {}
}

void f(A a, B b) {
  a.test(a: 0, c: 2);
  b.test(a: 3, c: 5);
}
''');
  }

  Future<void> test_classMethod_requiredPositional_reorder() async {
    await _analyzeValidSelection(r'''
class A {
  void ^test(int a, int b) {}
}

class B extends A {
  void test(int a, int b) {}
}

void f(A a, B b) {
  a.test(0, 1);
  b.test(2, 3);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
class A {
  void test(int b, int a) {}
}

class B extends A {
  void test(int b, int a) {}
}

void f(A a, B b) {
  a.test(1, 0);
  b.test(3, 2);
}
''');
  }

  Future<void> test_classMethod_requiredPositional_reorder_less() async {
    await _analyzeValidSelection(r'''
class A {
  void ^test(int a, int b) {}
}

class B extends A {
  void test(int a) {}
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
ChangeStatusFailure
''');
  }

  Future<void> test_classMethod_requiredPositional_reorder_more() async {
    await _analyzeValidSelection(r'''
class A {
  void ^test(int a, int b) {}
}

class B extends A {
  void test(int a, int b, int c) {}
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
ChangeStatusFailure
''');
  }

  Future<void>
      test_classMethod_requiredPositional_reorder_more_optional() async {
    await _analyzeValidSelection(r'''
class A {
  void ^test(int a, int b) {}
}

class B extends A {
  void test(int a, int b, [int c]) {}
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
ChangeStatusFailure
''');
  }

  Future<void>
      test_formalParametersTrailingComma_requiredNamed_always_add() async {
    await _analyzeValidSelection(r'''
void ^test({required int a, required int b}) {}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredNamed,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.always,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test({
  required int b,
  required int a,
}) {}
''');
  }

  Future<void>
      test_formalParametersTrailingComma_requiredNamed_ifPresent_false() async {
    await _analyzeValidSelection(r'''
void ^test({required int a, required int b}) {}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredNamed,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test({required int b, required int a}) {}
''');
  }

  Future<void>
      test_formalParametersTrailingComma_requiredNamed_ifPresent_true() async {
    await _analyzeValidSelection(r'''
void ^test({
  required int a,
  required int b,
}) {}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredNamed,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test({
  required int b,
  required int a,
}) {}
''');
  }

  Future<void>
      test_formalParametersTrailingComma_requiredNamed_never_remove() async {
    await _analyzeValidSelection(r'''
void ^test({
  required int b,
  required int a,
}) {}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredNamed,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test({required int a, required int b}) {}
''');
  }

  Future<void>
      test_formalParametersTrailingComma_requiredPositional_always_add() async {
    await _analyzeValidSelection(r'''
void ^test(int a, int b) {}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.always,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test(
  int b,
  int a,
) {}
''');
  }

  Future<void>
      test_formalParametersTrailingComma_requiredPositional_never_remove() async {
    await _analyzeValidSelection(r'''
void ^test(
  int a,
  int b,
) {}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test(int b, int a) {}
''');
  }

  Future<void> test_topFunction_fail_noSuchId_greater() async {
    await _analyzeValidSelection(r'''
void ^test(int a) {}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
ChangeStatusFailure
''');
  }

  Future<void> test_topFunction_fail_noSuchId_negative() async {
    await _analyzeValidSelection(r'''
void ^test(int a) {}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: -1,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
ChangeStatusFailure
''');
  }

  Future<void> test_topFunction_fail_optionalNamed_optionalPositional() async {
    await _analyzeValidSelection(r'''
void ^test(int a, int b) {}

void f() {
  test(0, 1);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.optionalNamed,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.optionalPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
ChangeStatusFailure
''');
  }

  Future<void> test_topFunction_fail_optionalNamed_requiredPositional() async {
    await _analyzeValidSelection(r'''
void ^test(int a, int b) {}

void f() {
  test(0, 1);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.optionalNamed,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
ChangeStatusFailure
''');
  }

  Future<void> test_topFunction_fail_optionalPositional_optionalNamed() async {
    await _analyzeValidSelection(r'''
void ^test(int a, int b) {}

void f() {
  test(0, 1);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.optionalPositional,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.optionalNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
ChangeStatusFailure
''');
  }

  Future<void>
      test_topFunction_fail_optionalPositional_requiredPositional() async {
    await _analyzeValidSelection(r'''
void ^test(int a, int b) {}

void f() {
  test(0, 1);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.optionalPositional,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
ChangeStatusFailure
''');
  }

  Future<void> test_topFunction_fail_requiredNamed_requiredPositional() async {
    await _analyzeValidSelection(r'''
void ^test(int a, int b) {}

void f() {
  test(0, 1);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
ChangeStatusFailure
''');
  }

  Future<void> test_topFunction_functionTypedFormalParameter() async {
    await _analyzeValidSelection(r'''
void ^test(int a()) {}

void f() {
  test(() => 0);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.always,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test({
  required int a(),
}) {}

void f() {
  test(a: () => 0);
}
''');
  }

  Future<void> test_topFunction_multipleFiles() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'test.dart';

void f() {
  test(0);
}
''');

    await _analyzeValidSelection(r'''
void ^test(int a) {}

void f() {
  test(1);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.always,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/a.dart
import 'test.dart';

void f() {
  test(a: 0);
}
>>>>>>> /home/test/lib/test.dart
void test({
  required int a,
}) {}

void f() {
  test(a: 1);
}
''');
  }

  Future<void> test_topFunction_optionalNamed_remove() async {
    await _analyzeValidSelection(r'''
void ^test({int a, int b, int c}) {}

void f() {
  test(a: 0, b: 1, c: 2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.optionalNamed,
        ),
        FormalParameterUpdate(
          id: 2,
          kind: FormalParameterKind.optionalNamed,
        ),
      ],
      removedNamedFormalParameters: {'b'},
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test({int a, int c}) {}

void f() {
  test(a: 0, c: 2);
}
''');
  }

  Future<void> test_topFunction_optionalNamed_reorder() async {
    await _analyzeValidSelection(r'''
void ^test({
  int a = 0,
  double b = 1.2,
}) {}

void f() {
  test(a: 0, b: 1.2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.optionalNamed,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.optionalNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.always,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test({
  double b = 1.2,
  int a = 0,
}) {}

void f() {
  test(b: 1.2, a: 0);
}
''');
  }

  Future<void> test_topFunction_optionalNamed_reorder_notAll() async {
    await _analyzeValidSelection(r'''
void ^test({int? a, int? b}) {}

void f() {
  test(a: 0);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.optionalNamed,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.optionalNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test({int? b, int? a}) {}

void f() {
  test(a: 0);
}
''');
  }

  Future<void> test_topFunction_optionalNamed_toOptionalPositional() async {
    await _analyzeValidSelection(r'''
void ^test({
  int a = 0,
  double b = 1.2,
}) {}

void f() {
  test(a: 0, b: 1.2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.optionalPositional,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.optionalPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test([int a = 0, double b = 1.2]) {}

void f() {
  test(0, 1.2);
}
''');
  }

  Future<void> test_topFunction_optionalNamed_toRequiredNamed() async {
    await _analyzeValidSelection(r'''
void ^test({
  int a = 0,
  double b = 1.2,
}) {}

void f() {
  test(a: 0, b: 1.2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.always,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test({
  required int a,
  required double b,
}) {}

void f() {
  test(a: 0, b: 1.2);
}
''');
  }

  Future<void> test_topFunction_optionalNamed_toRequiredNamed_notAll() async {
    await _analyzeValidSelection(r'''
void ^test({int? a, double? b}) {}

void f() {
  test(a: 0);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.always,
      argumentsTrailingComma: ArgumentsTrailingComma.never,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test({
  required int? a,
  required double? b,
}) {}

void f() {
  test(a: 0);
}
''');
  }

  Future<void> test_topFunction_optionalNamed_toRequiredPositional() async {
    await _analyzeValidSelection(r'''
void ^test({
  int a = 0,
  double b = 1.2,
}) {}

void f() {
  test(a: 0, b: 1.2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test(int a, double b) {}

void f() {
  test(0, 1.2);
}
''');
  }

  Future<void> test_topFunction_optionalPositional_remove() async {
    await _analyzeValidSelection(r'''
void ^test([int? a, int? b, int? c]) {}

void f() {
  test(0, 1, 2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.optionalPositional,
        ),
        FormalParameterUpdate(
          id: 2,
          kind: FormalParameterKind.optionalPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test([int? a, int? c]) {}

void f() {
  test(0, 2);
}
''');
  }

  Future<void> test_topFunction_optionalPositional_reorder() async {
    await _analyzeValidSelection(r'''
void ^test([int a, double b]) {}

void f() {
  test(0, 1.2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.optionalPositional,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.optionalPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test([double b, int a]) {}

void f() {
  test(1.2, 0);
}
''');
  }

  Future<void> test_topFunction_optionalPositional_reorder_notAll() async {
    await _analyzeValidSelection(r'''
void ^test([int? a, int? b]) {}

void f() {
  test(0);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.optionalPositional,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.optionalPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
ChangeStatusFailure
''');
  }

  Future<void> test_topFunction_optionalPositional_toOptionalNamed() async {
    await _analyzeValidSelection(r'''
void ^test([int a, double b]) {}

void f() {
  test(0, 1.2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.optionalNamed,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.optionalNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test({int a, double b}) {}

void f() {
  test(a: 0, b: 1.2);
}
''');
  }

  Future<void> test_topFunction_optionalPositional_toRequiredNamed() async {
    await _analyzeValidSelection(r'''
void ^test([int a, double b]) {}

void f() {
  test(0, 1.2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.always,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test({
  required int a,
  required double b,
}) {}

void f() {
  test(a: 0, b: 1.2);
}
''');
  }

  Future<void>
      test_topFunction_optionalPositional_toRequiredPositional() async {
    await _analyzeValidSelection(r'''
void ^test([int a, double b]) {}

void f() {
  test(0, 1.2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test(int a, double b) {}

void f() {
  test(0, 1.2);
}
''');
  }

  Future<void>
      test_topFunction_optionalPositional_toRequiredPositional_notAll() async {
    await _analyzeValidSelection(r'''
void ^test([int a, double b]) {}

void f() {
  test(0);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
ChangeStatusFailure
''');
  }

  Future<void> test_topFunction_requiredNamed_remove_all() async {
    await _analyzeValidSelection(r'''
void ^test({
  required int a,
}) {}

void f() {
  test(a: 0);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [],
      removedNamedFormalParameters: {'a'},
      formalParametersTrailingComma: TrailingComma.always,
      argumentsTrailingComma: ArgumentsTrailingComma.always,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test() {}

void f() {
  test();
}
''');
  }

  Future<void> test_topFunction_requiredNamed_remove_first() async {
    await _analyzeValidSelection(r'''
void ^test({
  required int a,
  required int b,
  required int c,
}) {}

void f() {
  test(a: 0, b: 1, c: 2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredNamed,
        ),
        FormalParameterUpdate(
          id: 2,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      removedNamedFormalParameters: {'a'},
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test({
  required int b,
  required int c,
}) {}

void f() {
  test(b: 1, c: 2);
}
''');
  }

  Future<void> test_topFunction_requiredNamed_remove_last() async {
    await _analyzeValidSelection(r'''
void ^test({
  required int a,
  required int b,
  required int c,
}) {}

void f() {
  test(a: 0, b: 1, c: 2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      removedNamedFormalParameters: {'c'},
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test({
  required int a,
  required int b,
}) {}

void f() {
  test(a: 0, b: 1);
}
''');
  }

  Future<void> test_topFunction_requiredNamed_remove_middle() async {
    await _analyzeValidSelection(r'''
void ^test({
  required int a,
  required int b,
  required int c,
}) {}

void f() {
  test(a: 0, b: 1, c: 2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
        FormalParameterUpdate(
          id: 2,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      removedNamedFormalParameters: {'b'},
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test({
  required int a,
  required int c,
}) {}

void f() {
  test(a: 0, c: 2);
}
''');
  }

  Future<void> test_topFunction_requiredNamed_reorder() async {
    await _analyzeValidSelection(r'''
void ^test({
  required int a,
  required double b,
}) {}

void f() {
  test(a: 0, b: 1.2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredNamed,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.always,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test({
  required double b,
  required int a,
}) {}

void f() {
  test(b: 1.2, a: 0);
}
''');
  }

  Future<void> test_topFunction_requiredNamed_reorder_hasTrailingComma() async {
    await _analyzeValidSelection(r'''
void ^test({
  required int a,
  required double b,
}) {}

void f() {
  test(
    a: 0,
    b: 1.2,
  );
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredNamed,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.always,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test({
  required double b,
  required int a,
}) {}

void f() {
  test(
    b: 1.2,
    a: 0,
  );
}
''');
  }

  Future<void> test_topFunction_requiredNamed_reorder_notAll() async {
    await _analyzeValidSelection(r'''
void ^test({required int a, required int b}) {}

void f() {
  test(a: 0);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredNamed,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test({required int b, required int a}) {}

void f() {
  test(a: 0);
}
''');
  }

  Future<void> test_topFunction_requiredNamed_toOptionalNamed() async {
    await _analyzeValidSelection(r'''
void ^test({
  required int a,
  required double b,
}) {}

void f() {
  test(a: 0, b: 1.2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.optionalNamed,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.optionalNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test({int a, double b}) {}

void f() {
  test(a: 0, b: 1.2);
}
''');
  }

  Future<void> test_topFunction_requiredNamed_toOptionalPositional() async {
    await _analyzeValidSelection(r'''
void ^test({
  required int a,
  required double b,
}) {}

void f() {
  test(a: 0, b: 1.2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.optionalPositional,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.optionalPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test([int a, double b]) {}

void f() {
  test(0, 1.2);
}
''');
  }

  Future<void> test_topFunction_requiredPositional_remove_all() async {
    await _analyzeValidSelection(r'''
void ^test(int a) {}

void f() {
  test(0);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [],
      formalParametersTrailingComma: TrailingComma.always,
      argumentsTrailingComma: ArgumentsTrailingComma.always,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test() {}

void f() {
  test();
}
''');
  }

  Future<void> test_topFunction_requiredPositional_remove_first() async {
    await _analyzeValidSelection(r'''
void ^test(int a, int b, int c) {}

void f() {
  test(0, 1, 2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 2,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test(int b, int c) {}

void f() {
  test(1, 2);
}
''');
  }

  Future<void> test_topFunction_requiredPositional_remove_last() async {
    await _analyzeValidSelection(r'''
void ^test(int a, int b, int c) {}

void f() {
  test(0, 1, 2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test(int a, int b) {}

void f() {
  test(0, 1);
}
''');
  }

  Future<void> test_topFunction_requiredPositional_remove_middle() async {
    await _analyzeValidSelection(r'''
void ^test(int a, int b, int c) {}

void f() {
  test(0, 1, 2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 2,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test(int a, int c) {}

void f() {
  test(0, 2);
}
''');
  }

  Future<void> test_topFunction_requiredPositional_reorder() async {
    await _analyzeValidSelection(r'''
void ^test(int a, double b) {}

void f() {
  test(0, 1.2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test(double b, int a) {}

void f() {
  test(1.2, 0);
}
''');
  }

  Future<void>
      test_topFunction_requiredPositional_reorder_hasNamedArgumentMiddle() async {
    await _analyzeValidSelection(r'''
void ^test(int a, double b, {int? c}) {}

void f() {
  test(0, c: 2, 1.2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 2,
          kind: FormalParameterKind.optionalNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test(double b, int a, {int? c}) {}

void f() {
  test(1.2, 0, c: 2);
}
''');
  }

  Future<void> test_topFunction_requiredPositional_reorder_notAll() async {
    await _analyzeValidSelection(r'''
void ^test(int a, int b) {}

void f() {
  test(0);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
ChangeStatusFailure
''');
  }

  Future<void> test_topFunction_requiredPositional_toOptionalNamed() async {
    await _analyzeValidSelection(r'''
void ^test(int a, double b) {}

void f() {
  test(0, 1.2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.optionalNamed,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.optionalNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test({int a, double b}) {}

void f() {
  test(a: 0, b: 1.2);
}
''');
  }

  Future<void>
      test_topFunction_requiredPositional_toOptionalPositional() async {
    await _analyzeValidSelection(r'''
void ^test(int a, double b) {}

void f() {
  test(0, 1.2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.optionalPositional,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.optionalPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test([int a, double b]) {}

void f() {
  test(0, 1.2);
}
''');
  }

  Future<void>
      test_topFunction_requiredPositional_toOptionalPositional1() async {
    await _analyzeValidSelection(r'''
void ^test(int a, double b) {}

void f() {
  test(0, 1.2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredPositional,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.optionalPositional,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.never,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test(int a, [double b]) {}

void f() {
  test(0, 1.2);
}
''');
  }

  Future<void> test_topFunction_requiredPositional_toRequiredNamed() async {
    await _analyzeValidSelection(r'''
void ^test(int a, double b) {}

void f() {
  test(0, 1.2);
}
''');

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: [
        FormalParameterUpdate(
          id: 0,
          kind: FormalParameterKind.requiredNamed,
        ),
        FormalParameterUpdate(
          id: 1,
          kind: FormalParameterKind.requiredNamed,
        ),
      ],
      formalParametersTrailingComma: TrailingComma.always,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await _assertUpdate(signatureUpdate, r'''
>>>>>>> /home/test/lib/test.dart
void test({
  required int a,
  required double b,
}) {}

void f() {
  test(a: 0, b: 1.2);
}
''');
  }

  Future<void> _assertUpdate(
    MethodSignatureUpdate signatureUpdate,
    String expected,
  ) async {
    final builder = ChangeBuilder(
      session: refactoringContext.session,
      eol: refactoringContext.utils.endOfLine,
    );

    final status = await computeSourceChange(
      selectionState: validSelectionState,
      signatureUpdate: signatureUpdate,
      builder: builder,
    );

    final buffer = StringBuffer();
    switch (status) {
      case ChangeStatusSuccess():
        _writeSourceChangeToBuffer(
          buffer: buffer,
          sourceChange: builder.sourceChange,
        );
      case ChangeStatusFailure():
        buffer.writeln('${status.runtimeType}');
    }

    _assertTextExpectation(buffer.toString(), expected);
  }

  /// If the path style is `Windows`, returns the corresponding Posix path.
  /// Otherwise the path is already a Posix path, and it is returned as is.
  /// TODO(scheglov) This is duplicate.
  String _posixPath(File file) {
    final pathContext = resourceProvider.pathContext;
    if (pathContext.style == Style.windows) {
      final components = pathContext.split(file.path);
      return '/${components.skip(1).join('/')}';
    } else {
      return file.path;
    }
  }

  void _writeSourceChangeToBuffer({
    required StringBuffer buffer,
    required SourceChange sourceChange,
  }) {
    final fileEdits = sourceChange.edits.sortedBy((e) => e.file);
    for (final fileEdit in fileEdits) {
      final file = getFile(fileEdit.file);
      buffer.writeln('>>>>>>> ${_posixPath(file)}');
      final current = file.readAsStringSync();
      final updated = SourceEdit.applySequence(current, fileEdit.edits);
      buffer.write(updated);
    }
  }
}
