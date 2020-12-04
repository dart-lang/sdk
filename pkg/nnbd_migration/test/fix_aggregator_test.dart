// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/edit_plan.dart';
import 'package:nnbd_migration/src/fix_aggregator.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/nullability_node_target.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FixAggregatorTest);
  });
}

@reflectiveTest
class FixAggregatorTest extends FixAggregatorTestBase {
  TypeProviderImpl get nnbdTypeProvider =>
      (testAnalysisResult.typeProvider as TypeProviderImpl)
          .asNonNullableByDefault;

  Future<void> test_addImport_after_library() async {
    await analyze('''
library foo;

main() {}
''');
    var previewInfo = run({
      findNode.unit: NodeChangeForCompilationUnit()
        ..addImport('package:collection/collection.dart', 'IterableExtension')
    });
    expect(previewInfo.applyTo(code), '''
library foo;

import 'package:collection/collection.dart' show IterableExtension;

main() {}
''');
  }

  Future<void> test_addImport_after_library_before_other() async {
    addPackageFile('fixnum', 'fixnum.dart', '');
    await analyze('''
library foo;

import 'package:fixnum/fixnum.dart';

main() {}
''');
    var previewInfo = run({
      findNode.unit: NodeChangeForCompilationUnit()
        ..addImport('package:collection/collection.dart', 'IterableExtension')
    });
    expect(previewInfo.applyTo(code), '''
library foo;

import 'package:collection/collection.dart' show IterableExtension;
import 'package:fixnum/fixnum.dart';

main() {}
''');
  }

  Future<void> test_addImport_atEnd_multiple() async {
    addPackageFile('args', 'args.dart', '');
    await analyze('''
import 'package:args/args.dart';

main() {}
''');
    var previewInfo = run({
      findNode.unit: NodeChangeForCompilationUnit()
        ..addImport('package:fixnum/fixnum.dart', 'Int32')
        ..addImport('package:collection/collection.dart', 'IterableExtension')
    });
    expect(previewInfo.applyTo(code), '''
import 'package:args/args.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:fixnum/fixnum.dart' show Int32;

main() {}
''');
  }

  Future<void> test_addImport_atStart_multiple() async {
    addPackageFile('fixnum', 'fixnum.dart', '');
    await analyze('''
import 'package:fixnum/fixnum.dart';

main() {}
''');
    var previewInfo = run({
      findNode.unit: NodeChangeForCompilationUnit()
        ..addImport('package:collection/collection.dart', 'IterableExtension')
        ..addImport('package:args/args.dart', 'ArgParser')
    });
    expect(previewInfo.applyTo(code), '''
import 'package:args/args.dart' show ArgParser;
import 'package:collection/collection.dart' show IterableExtension;
import 'package:fixnum/fixnum.dart';

main() {}
''');
  }

  Future<void> test_addImport_before_export() async {
    await analyze('''
export 'dart:async';

main() {}
''');
    var previewInfo = run({
      findNode.unit: NodeChangeForCompilationUnit()
        ..addImport('package:collection/collection.dart', 'IterableExtension')
    });
    expect(previewInfo.applyTo(code), '''
import 'package:collection/collection.dart' show IterableExtension;
export 'dart:async';

main() {}
''');
  }

  Future<void> test_addImport_no_previous_imports_multiple() async {
    await analyze('''
main() {}
''');
    var previewInfo = run({
      findNode.unit: NodeChangeForCompilationUnit()
        ..addImport('dart:async', 'Future')
        ..addImport('dart:math', 'sin')
    });
    expect(previewInfo.applyTo(code), '''
import 'dart:async' show Future;
import 'dart:math' show sin;

main() {}
''');
  }

  Future<void> test_addImport_recursive() async {
    addPackageFile('args', 'args.dart', '');
    addPackageFile('fixnum', 'fixnum.dart', 'class Int32 {}');
    await analyze('''
import 'package:args/args.dart';
import 'package:fixnum/fixnum.dart' show Int32;

main() => null;
''');
    var previewInfo = run({
      findNode.unit: NodeChangeForCompilationUnit()
        ..addImport('package:collection/collection.dart', 'IterableExtension'),
      findNode.import('package:fixnum').combinators[0]:
          NodeChangeForShowCombinator()..addName('Int64'),
      findNode.expression('null'): NodeChangeForExpression()..addNullCheck(null)
    });
    expect(previewInfo.applyTo(code), '''
import 'package:args/args.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:fixnum/fixnum.dart' show Int32, Int64;

main() => null!;
''');
  }

  Future<void> test_addImport_sort_shown_names() async {
    await analyze('''
main() {}
''');
    var previewInfo = run({
      findNode.unit: NodeChangeForCompilationUnit()
        ..addImport('dart:async', 'Stream')
        ..addImport('dart:async', 'Future')
    });
    expect(previewInfo.applyTo(code), '''
import 'dart:async' show Future, Stream;

main() {}
''');
  }

  Future<void> test_addImport_sorted() async {
    addPackageFile('args', 'args.dart', '');
    addPackageFile('fixnum', 'fixnum.dart', '');
    await analyze('''
import 'package:args/args.dart';
import 'package:fixnum/fixnum.dart';

main() {}
''');
    var previewInfo = run({
      findNode.unit: NodeChangeForCompilationUnit()
        ..addImport('package:collection/collection.dart', 'IterableExtension')
    });
    expect(previewInfo.applyTo(code), '''
import 'package:args/args.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:fixnum/fixnum.dart';

main() {}
''');
  }

  Future<void> test_addImport_sorted_multiple() async {
    addPackageFile('collection', 'collection.dart', '');
    await analyze('''
import 'package:collection/collection.dart';

main() {}
''');
    var previewInfo = run({
      findNode.unit: NodeChangeForCompilationUnit()
        ..addImport('package:fixnum/fixnum.dart', 'Int32')
        ..addImport('package:args/args.dart', 'ArgParser')
    });
    expect(previewInfo.applyTo(code), '''
import 'package:args/args.dart' show ArgParser;
import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart' show Int32;

main() {}
''');
  }

  Future<void> test_addRequired() async {
    await analyze('f({int x}) => 0;');
    var previewInfo = run({
      findNode.defaultParameter('int x'): NodeChangeForDefaultFormalParameter()
        ..addRequiredKeyword = true
    });
    expect(previewInfo.applyTo(code), 'f({required int x}) => 0;');
  }

  Future<void> test_addRequired_afterMetadata() async {
    await analyze('f({@deprecated int x}) => 0;');
    var previewInfo = run({
      findNode.defaultParameter('int x'): NodeChangeForDefaultFormalParameter()
        ..addRequiredKeyword = true
    });
    expect(previewInfo.applyTo(code), 'f({@deprecated required int x}) => 0;');
  }

  Future<void> test_addRequired_afterMetadata_andRequiredAnnotation() async {
    addMetaPackage();
    var content = '''
import 'package:meta/meta.dart';
f({@required @deprecated int x}) {}
''';
    await analyze(content);
    var annotation = findNode.annotation('required');
    var previewInfo = run({
      findNode.defaultParameter('int x'): NodeChangeForDefaultFormalParameter()
        ..addRequiredKeyword = true
        ..annotationToRemove = annotation
    });
    expect(previewInfo.applyTo(code), '''
import 'package:meta/meta.dart';
f({@deprecated required int x}) {}
''');
    expect(previewInfo.values, hasLength(2));

    expect(previewInfo[content.indexOf('int ')], hasLength(1));
    expect(previewInfo[content.indexOf('int ')].single.isInsertion, true);
    expect(previewInfo[content.indexOf('@required')], isNotNull);
    expect(previewInfo[content.indexOf('@required')].single.isDeletion, true);
  }

  Future<void> test_addRequired_afterMetadata_beforeFinal() async {
    await analyze('f({@deprecated final int x}) => 0;');
    var previewInfo = run({
      findNode.defaultParameter('int x'): NodeChangeForDefaultFormalParameter()
        ..addRequiredKeyword = true
    });
    expect(previewInfo.applyTo(code),
        'f({@deprecated required final int x}) => 0;');
  }

  Future<void> test_addRequired_afterMetadata_beforeFunctionTyped() async {
    await analyze('f({@deprecated int x()}) => 0;');
    var previewInfo = run({
      findNode.defaultParameter('int x'): NodeChangeForDefaultFormalParameter()
        ..addRequiredKeyword = true
    });
    expect(
        previewInfo.applyTo(code), 'f({@deprecated required int x()}) => 0;');
  }

  Future<void> test_addShownName_atEnd_multiple() async {
    await analyze("import 'dart:math' show cos;");
    var previewInfo = run({
      findNode.import('dart:math').combinators[0]: NodeChangeForShowCombinator()
        ..addName('tan')
        ..addName('sin')
    });
    expect(previewInfo.applyTo(code), "import 'dart:math' show cos, sin, tan;");
  }

  Future<void> test_addShownName_atStart_multiple() async {
    await analyze("import 'dart:math' show tan;");
    var previewInfo = run({
      findNode.import('dart:math').combinators[0]: NodeChangeForShowCombinator()
        ..addName('sin')
        ..addName('cos')
    });
    expect(previewInfo.applyTo(code), "import 'dart:math' show cos, sin, tan;");
  }

  Future<void> test_addShownName_sorted() async {
    await analyze("import 'dart:math' show cos, tan;");
    var previewInfo = run({
      findNode.import('dart:math').combinators[0]: NodeChangeForShowCombinator()
        ..addName('sin')
    });
    expect(previewInfo.applyTo(code), "import 'dart:math' show cos, sin, tan;");
  }

  Future<void> test_addShownName_sorted_multiple() async {
    await analyze("import 'dart:math' show sin;");
    var previewInfo = run({
      findNode.import('dart:math').combinators[0]: NodeChangeForShowCombinator()
        ..addName('tan')
        ..addName('cos')
    });
    expect(previewInfo.applyTo(code), "import 'dart:math' show cos, sin, tan;");
  }

  Future<void> test_adjacentFixes() async {
    await analyze('f(a, b) => a + b;');
    var aRef = findNode.simple('a +');
    var bRef = findNode.simple('b;');
    var previewInfo = run({
      aRef: NodeChangeForExpression()..addNullCheck(_MockInfo()),
      bRef: NodeChangeForExpression()..addNullCheck(_MockInfo()),
      findNode.binary('a + b'): NodeChangeForExpression()
        ..addNullCheck(_MockInfo())
    });
    expect(previewInfo.applyTo(code), 'f(a, b) => (a! + b!)!;');
  }

  Future<void> test_argument_list_drop_all_arguments() async {
    var content = '''
f([int x, int y]) => null;
g(int x, int y) => f(x, y);
''';
    await analyze(content);
    var previewInfo = run({
      findNode.methodInvocation('f(x').argumentList: NodeChangeForArgumentList()
        ..dropArgument(findNode.simple('y);'), null)
        ..dropArgument(findNode.simple('x, y'), null)
    });
    expect(previewInfo.applyTo(code), '''
f([int x, int y]) => null;
g(int x, int y) => f();
''');
  }

  Future<void> test_argument_list_drop_one_argument() async {
    var content = '''
f([int x, int y]) => null;
g(int x, int y) => f(x, y);
''';
    await analyze(content);
    var previewInfo = run({
      findNode.methodInvocation('f(x').argumentList: NodeChangeForArgumentList()
        ..dropArgument(findNode.simple('y);'), null)
    });
    expect(previewInfo.applyTo(code), '''
f([int x, int y]) => null;
g(int x, int y) => f(x);
''');
  }

  Future<void> test_argument_list_recursive_changes() async {
    var content = '''
f([int x, int y]) => null;
g(int x, int y) => f(x, y);
''';
    await analyze(content);
    var previewInfo = run({
      findNode.methodInvocation('f(x').argumentList: NodeChangeForArgumentList()
        ..dropArgument(findNode.simple('y);'), null),
      findNode.simple('x, y'): NodeChangeForExpression()..addNullCheck(null)
    });
    expect(previewInfo.applyTo(code), '''
f([int x, int y]) => null;
g(int x, int y) => f(x!);
''');
  }

  Future<void> test_assignment_add_null_check() async {
    var content = 'f(int x, int y) => x += y;';
    await analyze(content);
    var previewInfo = run({
      findNode.assignment('+='): NodeChangeForAssignment()..addNullCheck(null)
    });
    expect(previewInfo.applyTo(code), 'f(int x, int y) => (x += y)!;');
  }

  Future<void> test_assignment_change_lhs() async {
    var content = 'f(List<int> x, int y) => x[0] += y;';
    await analyze(content);
    var previewInfo = run({
      findNode.assignment('+='): NodeChangeForAssignment(),
      findNode.index('[0]').target: NodeChangeForExpression()
        ..addNullCheck(null)
    });
    expect(previewInfo.applyTo(code), 'f(List<int> x, int y) => x![0] += y;');
  }

  Future<void> test_assignment_change_rhs() async {
    var content = 'f(int x, int y) => x += y;';
    await analyze(content);
    var assignment = findNode.assignment('+=');
    var previewInfo = run({
      assignment: NodeChangeForAssignment(),
      assignment.rightHandSide: NodeChangeForExpression()..addNullCheck(null)
    });
    expect(previewInfo.applyTo(code), 'f(int x, int y) => x += y!;');
  }

  Future<void> test_assignment_compound_with_bad_combined_type() async {
    var content = 'f(int x, int y) => x += y;';
    await analyze(content);
    var previewInfo = run({
      findNode.assignment('+='): NodeChangeForAssignment()
        ..hasBadCombinedType = true
    });
    expect(previewInfo.applyTo(code), content);
    expect(previewInfo, hasLength(1));
    var edit = previewInfo[content.indexOf('+=')].single;
    expect(edit.info.description,
        NullabilityFixDescription.compoundAssignmentHasBadCombinedType);
    expect(edit.isInformative, isTrue);
    expect(edit.length, '+='.length);
  }

  Future<void> test_assignment_compound_with_nullable_source() async {
    var content = 'f(int x, int y) => x += y;';
    await analyze(content);
    var previewInfo = run({
      findNode.assignment('+='): NodeChangeForAssignment()
        ..hasNullableSource = true
    });
    expect(previewInfo.applyTo(code), content);
    expect(previewInfo, hasLength(1));
    var edit = previewInfo[content.indexOf('+=')].single;
    expect(edit.info.description,
        NullabilityFixDescription.compoundAssignmentHasNullableSource);
    expect(edit.isInformative, isTrue);
    expect(edit.length, '+='.length);
  }

  Future<void> test_assignment_introduce_as() async {
    var content = 'f(int x, int y) => x += y;';
    await analyze(content);
    var previewInfo = run({
      findNode.assignment('+='): NodeChangeForAssignment()
        ..introduceAs(nnbdTypeProvider.intType, null)
    });
    expect(previewInfo.applyTo(code), 'f(int x, int y) => (x += y) as int;');
  }

  Future<void> test_assignment_weak_null_aware() async {
    var content = 'f(int x, int y) => x ??= y;';
    await analyze(content);
    var previewInfo = run({
      findNode.assignment('??='): NodeChangeForAssignment()
        ..isWeakNullAware = true
    }, warnOnWeakCode: true);
    expect(previewInfo.applyTo(code), content);
    expect(previewInfo, hasLength(1));
    var edit = previewInfo[content.indexOf('??=')].single;
    expect(edit.info.description,
        NullabilityFixDescription.nullAwareAssignmentUnnecessaryInStrongMode);
    expect(edit.isInformative, isTrue);
    expect(edit.length, '??='.length);
  }

  Future<void> test_assignment_weak_null_aware_remove() async {
    var content = 'f(int x, int y) => x ??= y;';
    await analyze(content);
    var previewInfo = run({
      findNode.assignment('??='): NodeChangeForAssignment()
        ..isWeakNullAware = true
    }, warnOnWeakCode: false);
    expect(previewInfo.applyTo(code), 'f(int x, int y) => x;');
  }

  Future<void> test_eliminateDeadIf_changesInKeptCode() async {
    await analyze('''
f(int i, int/*?*/ j) {
  if (i != null) j.isEven;
}
''');
    var previewInfo = run({
      findNode.statement('if'): NodeChangeForIfStatement()
        ..conditionValue = true,
      findNode.simple('j.isEven'): NodeChangeForExpression()
        ..addNullCheck(_MockInfo())
    });
    expect(previewInfo.applyTo(code), '''
f(int i, int/*?*/ j) {
  j!.isEven;
}
''');
  }

  Future<void> test_eliminateDeadIf_changesInKeptCode_expandBlock() async {
    await analyze('''
f(int i, int/*?*/ j) {
  if (i != null) {
    j.isEven;
  }
}
''');
    var previewInfo = run({
      findNode.statement('if'): NodeChangeForIfStatement()
        ..conditionValue = true,
      findNode.simple('j.isEven'): NodeChangeForExpression()
        ..addNullCheck(_MockInfo())
    });
    expect(previewInfo.applyTo(code), '''
f(int i, int/*?*/ j) {
  j!.isEven;
}
''');
  }

  Future<void> test_eliminateDeadIf_element_delete_drop_completely() async {
    await analyze('''
List<int> f(int i) {
  return [if (i == null) null];
}
''');
    var previewInfo = run({
      findNode.ifElement('=='): NodeChangeForIfElement()..conditionValue = false
    });
    expect(previewInfo.applyTo(code), '''
List<int> f(int i) {
  return [];
}
''');
  }

  Future<void>
      test_eliminateDeadIf_element_delete_drop_completely_not_in_sequence() async {
    await analyze('''
List<int> f(int i) {
  return [for (var x in [1, 2, 3]) if (i == null) null];
}
''');
    var previewInfo = run({
      findNode.ifElement('=='): NodeChangeForIfElement()..conditionValue = false
    });
    // This is a little kludgy; we could drop the `for` loop, but it's difficult
    // to do so, and this is a rare enough corner case that it doesn't seem
    // worth it.  Replacing the `if` with `...{}` has the right effect, since
    // it expands to nothing.
    expect(previewInfo.applyTo(code), '''
List<int> f(int i) {
  return [for (var x in [1, 2, 3]) ...{}];
}
''');
  }

  Future<void> test_eliminateDeadIf_element_delete_keep_else() async {
    await analyze('''
List<int> f(int i) {
  return [if (i == null) null else i + 1];
}
''');
    var previewInfo = run({
      findNode.ifElement('=='): NodeChangeForIfElement()..conditionValue = false
    });
    expect(previewInfo.applyTo(code), '''
List<int> f(int i) {
  return [i + 1];
}
''');
  }

  Future<void> test_eliminateDeadIf_element_delete_keep_then() async {
    await analyze('''
List<int> f(int i) {
  return [if (i == null) null else i + 1];
}
''');
    var previewInfo = run({
      findNode.ifElement('=='): NodeChangeForIfElement()..conditionValue = true
    });
    expect(previewInfo.applyTo(code), '''
List<int> f(int i) {
  return [null];
}
''');
  }

  Future<void> test_eliminateDeadIf_expression_delete_keep_else() async {
    await analyze('''
int f(int i) {
  return i == null ? null : i + 1;
}
''');
    var previewInfo = run({
      findNode.conditionalExpression('=='): NodeChangeForConditionalExpression()
        ..conditionValue = false
    });
    expect(previewInfo.applyTo(code), '''
int f(int i) {
  return i + 1;
}
''');
  }

  Future<void> test_eliminateDeadIf_expression_delete_keep_then() async {
    await analyze('''
int f(int i) {
  return i == null ? null : i + 1;
}
''');
    var previewInfo = run({
      findNode.conditionalExpression('=='): NodeChangeForConditionalExpression()
        ..conditionValue = true
    });
    expect(previewInfo.applyTo(code), '''
int f(int i) {
  return null;
}
''');
  }

  Future<void> test_eliminateDeadIf_statement_comment_keep_else() async {
    await analyze('''
int f(int i) {
  if (i == null) {
    return null;
  } else {
    return i + 1;
  }
}
''');
    var previewInfo = run({
      findNode.statement('if'): NodeChangeForIfStatement()
        ..conditionValue = false
    }, removeViaComments: true);
    expect(previewInfo.applyTo(code), '''
int f(int i) {
  /* if (i == null) {
    return null;
  } else {
    */ return i + 1; /*
  } */
}
''');
  }

  Future<void> test_eliminateDeadIf_statement_comment_keep_then() async {
    await analyze('''
int f(int i) {
  if (i == null) {
    return null;
  } else {
    return i + 1;
  }
}
''');
    var previewInfo = run({
      findNode.statement('if'): NodeChangeForIfStatement()
        ..conditionValue = true
    }, removeViaComments: true);
    expect(previewInfo.applyTo(code), '''
int f(int i) {
  /* if (i == null) {
    */ return null; /*
  } else {
    return i + 1;
  } */
}
''');
  }

  Future<void>
      test_eliminateDeadIf_statement_delete_drop_completely_false() async {
    await analyze('''
void f(int i) {
  if (i == null) {
    print('null');
  }
}
''');
    var previewInfo = run({
      findNode.statement('if'): NodeChangeForIfStatement()
        ..conditionValue = false
    });
    expect(previewInfo.applyTo(code), '''
void f(int i) {}
''');
  }

  Future<void>
      test_eliminateDeadIf_statement_delete_drop_completely_not_in_block() async {
    await analyze('''
void f(int i) {
  while (true)
    if (i == null) {
      print('null');
    }
}
''');
    var previewInfo = run({
      findNode.statement('if'): NodeChangeForIfStatement()
        ..conditionValue = false
    });
    // Note: formatting is a little weird here but it's such a rare case that
    // we don't care.
    expect(previewInfo.applyTo(code), '''
void f(int i) {
  while (true)
    {}
}
''');
  }

  Future<void>
      test_eliminateDeadIf_statement_delete_drop_completely_true() async {
    await analyze('''
void f(int i) {
  if (i != null) {} else {
    print('null');
  }
}
''');
    var previewInfo = run({
      findNode.statement('if'): NodeChangeForIfStatement()
        ..conditionValue = true
    });
    expect(previewInfo.applyTo(code), '''
void f(int i) {}
''');
  }

  Future<void> test_eliminateDeadIf_statement_delete_keep_else() async {
    await analyze('''
int f(int i) {
  if (i == null) {
    return null;
  } else {
    return i + 1;
  }
}
''');
    var previewInfo = run({
      findNode.statement('if'): NodeChangeForIfStatement()
        ..conditionValue = false
    });
    expect(previewInfo.applyTo(code), '''
int f(int i) {
  return i + 1;
}
''');
  }

  Future<void> test_eliminateDeadIf_statement_delete_keep_then() async {
    await analyze('''
int f(int i) {
  if (i != null) {
    return i + 1;
  } else {
    return null;
  }
}
''');
    var previewInfo = run({
      findNode.statement('if'): NodeChangeForIfStatement()
        ..conditionValue = true
    });
    expect(previewInfo.applyTo(code), '''
int f(int i) {
  return i + 1;
}
''');
  }

  Future<void>
      test_eliminateDeadIf_statement_delete_keep_then_declaration() async {
    await analyze('''
void f(int i, String callback()) {
  if (i != null) {
    var i = callback();
  } else {
    return;
  }
  print(i);
}
''');
    // In this case we have to keep the block so that the scope of `var i`
    // doesn't widen.
    var previewInfo = run({
      findNode.statement('if'): NodeChangeForIfStatement()
        ..conditionValue = true
    });
    expect(previewInfo.applyTo(code), '''
void f(int i, String callback()) {
  {
    var i = callback();
  }
  print(i);
}
''');
  }

  Future<void> test_introduceAs_distant_parens_no_longer_needed() async {
    // Note: in principle it would be nice to delete the outer parens, but it's
    // difficult to see that they used to be necessary and aren't anymore, so we
    // leave them.
    await analyze('f(a, c) => a..b = (throw c..d);');
    var cd = findNode.cascade('c..d');
    var previewInfo = run({
      cd: NodeChangeForExpression()
        ..introduceAs(nnbdTypeProvider.intType, _MockInfo())
    });
    expect(
        previewInfo.applyTo(code), 'f(a, c) => a..b = (throw (c..d) as int);');
  }

  Future<void> test_introduceAs_dynamic() async {
    await analyze('f(Object o) => o;');
    var expr = findNode.simple('o;');
    var previewInfo = run({
      expr: NodeChangeForExpression()
        ..introduceAs(nnbdTypeProvider.dynamicType, _MockInfo())
    });
    expect(previewInfo.applyTo(code), 'f(Object o) => o as dynamic;');
  }

  Future<void> test_introduceAs_favorPrefix() async {
    await analyze('''
import 'dart:async' as a;
import 'dart:async';
f(Object o) => o;
''');
    var expr = findNode.simple('o;');
    var previewInfo = run({
      expr: NodeChangeForExpression()
        ..introduceAs(nnbdTypeProvider.futureNullType, _MockInfo())
    });
    expect(previewInfo.applyTo(code), '''
import 'dart:async' as a;
import 'dart:async';
f(Object o) => o as a.Future<Null>;
''');
  }

  Future<void> test_introduceAs_functionType() async {
    await analyze('f(Object o) => o;');
    var expr = findNode.simple('o;');
    var previewInfo = run({
      expr: NodeChangeForExpression()
        ..introduceAs(
            FunctionTypeImpl(
                returnType: nnbdTypeProvider.boolType,
                typeFormals: [],
                parameters: [],
                nullabilitySuffix: NullabilitySuffix.none),
            _MockInfo())
    });
    expect(previewInfo.applyTo(code), 'f(Object o) => o as bool Function();');
  }

  Future<void> test_introduceAs_functionType_formal_bound() async {
    await analyze('f(Object o) => o;');
    var expr = findNode.simple('o;');
    var previewInfo = run({
      expr: NodeChangeForExpression()
        ..introduceAs(
            FunctionTypeImpl(
                returnType: nnbdTypeProvider.boolType,
                typeFormals: [
                  TypeParameterElementImpl.synthetic('T')
                    ..bound = nnbdTypeProvider.numType
                ],
                parameters: [],
                nullabilitySuffix: NullabilitySuffix.none),
            _MockInfo())
    });
    expect(previewInfo.applyTo(code),
        'f(Object o) => o as bool Function<T extends num>();');
  }

  Future<void> test_introduceAs_functionType_formal_bound_dynamic() async {
    await analyze('f(Object o) => o;');
    var expr = findNode.simple('o;');
    var previewInfo = run({
      expr: NodeChangeForExpression()
        ..introduceAs(
            FunctionTypeImpl(
                returnType: nnbdTypeProvider.boolType,
                typeFormals: [
                  TypeParameterElementImpl.synthetic('T')
                    ..bound = nnbdTypeProvider.dynamicType
                ],
                parameters: [],
                nullabilitySuffix: NullabilitySuffix.none),
            _MockInfo())
    });
    expect(
        previewInfo.applyTo(code), 'f(Object o) => o as bool Function<T>();');
  }

  Future<void> test_introduceAs_functionType_formal_bound_object() async {
    await analyze('f(Object o) => o;');
    var expr = findNode.simple('o;');
    var previewInfo = run({
      expr: NodeChangeForExpression()
        ..introduceAs(
            FunctionTypeImpl(
                returnType: nnbdTypeProvider.boolType,
                typeFormals: [
                  TypeParameterElementImpl.synthetic('T')
                    ..bound = nnbdTypeProvider.objectType
                ],
                parameters: [],
                nullabilitySuffix: NullabilitySuffix.none),
            _MockInfo())
    });
    expect(previewInfo.applyTo(code),
        'f(Object o) => o as bool Function<T extends Object>();');
  }

  Future<void>
      test_introduceAs_functionType_formal_bound_object_question() async {
    await analyze('f(Object o) => o;');
    var expr = findNode.simple('o;');
    var previewInfo = run({
      expr: NodeChangeForExpression()
        ..introduceAs(
            FunctionTypeImpl(
                returnType: nnbdTypeProvider.boolType,
                typeFormals: [
                  TypeParameterElementImpl.synthetic('T')
                    ..bound = (nnbdTypeProvider.objectType as TypeImpl)
                        .withNullability(NullabilitySuffix.question)
                ],
                parameters: [],
                nullabilitySuffix: NullabilitySuffix.none),
            _MockInfo())
    });
    expect(
        previewInfo.applyTo(code), 'f(Object o) => o as bool Function<T>();');
  }

  Future<void> test_introduceAs_functionType_formal_bound_question() async {
    await analyze('f(Object o) => o;');
    var expr = findNode.simple('o;');
    var previewInfo = run({
      expr: NodeChangeForExpression()
        ..introduceAs(
            FunctionTypeImpl(
                returnType: nnbdTypeProvider.boolType,
                typeFormals: [
                  TypeParameterElementImpl.synthetic('T')
                    ..bound = (nnbdTypeProvider.numType as TypeImpl)
                        .withNullability(NullabilitySuffix.question)
                ],
                parameters: [],
                nullabilitySuffix: NullabilitySuffix.none),
            _MockInfo())
    });
    expect(previewInfo.applyTo(code),
        'f(Object o) => o as bool Function<T extends num?>();');
  }

  Future<void> test_introduceAs_functionType_formals() async {
    await analyze('f(Object o) => o;');
    var expr = findNode.simple('o;');
    var previewInfo = run({
      expr: NodeChangeForExpression()
        ..introduceAs(
            FunctionTypeImpl(
                returnType: nnbdTypeProvider.boolType,
                typeFormals: [
                  TypeParameterElementImpl.synthetic('T'),
                  TypeParameterElementImpl.synthetic('U')
                ],
                parameters: [],
                nullabilitySuffix: NullabilitySuffix.none),
            _MockInfo())
    });
    expect(previewInfo.applyTo(code),
        'f(Object o) => o as bool Function<T, U>();');
  }

  Future<void> test_introduceAs_functionType_parameters() async {
    await analyze('f(Object o) => o;');
    var expr = findNode.simple('o;');
    var previewInfo = run({
      expr: NodeChangeForExpression()
        ..introduceAs(
            FunctionTypeImpl(
                returnType: nnbdTypeProvider.boolType,
                typeFormals: [],
                parameters: [
                  ParameterElementImpl.synthetic(
                      'x', nnbdTypeProvider.intType, ParameterKind.REQUIRED),
                  ParameterElementImpl.synthetic(
                      'y', nnbdTypeProvider.numType, ParameterKind.REQUIRED)
                ],
                nullabilitySuffix: NullabilitySuffix.none),
            _MockInfo())
    });
    expect(previewInfo.applyTo(code),
        'f(Object o) => o as bool Function(int, num);');
  }

  Future<void> test_introduceAs_functionType_parameters_named() async {
    await analyze('f(Object o) => o;');
    var expr = findNode.simple('o;');
    var previewInfo = run({
      expr: NodeChangeForExpression()
        ..introduceAs(
            FunctionTypeImpl(
                returnType: nnbdTypeProvider.boolType,
                typeFormals: [],
                parameters: [
                  ParameterElementImpl.synthetic(
                      'x', nnbdTypeProvider.intType, ParameterKind.NAMED),
                  ParameterElementImpl.synthetic(
                      'y', nnbdTypeProvider.numType, ParameterKind.NAMED)
                ],
                nullabilitySuffix: NullabilitySuffix.none),
            _MockInfo())
    });
    expect(previewInfo.applyTo(code),
        'f(Object o) => o as bool Function({int x, num y});');
  }

  Future<void> test_introduceAs_functionType_parameters_optional() async {
    await analyze('f(Object o) => o;');
    var expr = findNode.simple('o;');
    var previewInfo = run({
      expr: NodeChangeForExpression()
        ..introduceAs(
            FunctionTypeImpl(
                returnType: nnbdTypeProvider.boolType,
                typeFormals: [],
                parameters: [
                  ParameterElementImpl.synthetic(
                      'x', nnbdTypeProvider.intType, ParameterKind.POSITIONAL),
                  ParameterElementImpl.synthetic(
                      'y', nnbdTypeProvider.numType, ParameterKind.POSITIONAL)
                ],
                nullabilitySuffix: NullabilitySuffix.none),
            _MockInfo())
    });
    expect(previewInfo.applyTo(code),
        'f(Object o) => o as bool Function([int, num]);');
  }

  Future<void> test_introduceAs_interfaceType_parameterized() async {
    await analyze('f(Object o) => o;');
    var expr = findNode.simple('o;');
    var previewInfo = run({
      expr: NodeChangeForExpression()
        ..introduceAs(
            nnbdTypeProvider.mapType2(
                nnbdTypeProvider.intType, nnbdTypeProvider.boolType),
            _MockInfo())
    });
    expect(previewInfo.applyTo(code), 'f(Object o) => o as Map<int, bool>;');
  }

  Future<void> test_introduceAs_no_parens() async {
    await analyze('f(a, b) => a | b;');
    var expr = findNode.binary('a | b');
    var previewInfo = run({
      expr: NodeChangeForExpression()
        ..introduceAs(nnbdTypeProvider.intType, _MockInfo())
    });
    expect(previewInfo.applyTo(code), 'f(a, b) => a | b as int;');
  }

  Future<void> test_introduceAs_parens() async {
    await analyze('f(a, b) => a < b;');
    var expr = findNode.binary('a < b');
    var previewInfo = run({
      expr: NodeChangeForExpression()
        ..introduceAs(nnbdTypeProvider.boolType, _MockInfo())
    });
    expect(previewInfo.applyTo(code), 'f(a, b) => (a < b) as bool;');
  }

  Future<void> test_introduceAs_usePrefix() async {
    await analyze('''
import 'dart:async' as a;
f(Object o) => o;
''');
    var expr = findNode.simple('o;');
    var previewInfo = run({
      expr: NodeChangeForExpression()
        ..introduceAs(nnbdTypeProvider.futureNullType, _MockInfo())
    });
    expect(previewInfo.applyTo(code), '''
import 'dart:async' as a;
f(Object o) => o as a.Future<Null>;
''');
  }

  Future<void> test_introduceAs_withNullCheck() async {
    await analyze('f(x) => x;');
    var expr = findNode.simple('x;');
    var previewInfo = run({
      expr: NodeChangeForExpression()
        ..introduceAs(nnbdTypeProvider.intType, _MockInfo())
        ..addNullCheck(_MockInfo())
    });
    expect(previewInfo.applyTo(code), 'f(x) => x! as int;');
  }

  Future<void> test_keep_redundant_parens() async {
    await analyze('f(a, b, c) => a + (b * c);');
    var previewInfo = run({});
    expect(previewInfo, isEmpty);
  }

  Future<void> test_makeNullable() async {
    await analyze('f(int x) {}');
    var typeName = findNode.typeName('int');
    var previewInfo = run({
      typeName: NodeChangeForTypeAnnotation()
        ..recordNullability(
            MockDecoratedType(
                MockDartType(toStringValueWithoutNullability: 'int')),
            true)
    });
    expect(previewInfo.applyTo(code), 'f(int? x) {}');
  }

  Future<void> test_methodName_change() async {
    await analyze('f() => f();');
    var previewInfo = run({
      findNode.methodInvocation('f();').methodName: NodeChangeForMethodName()
        ..replaceWith('g', null)
    });
    expect(previewInfo.applyTo(code), 'f() => g();');
  }

  Future<void> test_methodName_no_change() async {
    await analyze('f() => f();');
    var previewInfo = run({
      findNode.methodInvocation('f();').methodName: NodeChangeForMethodName()
    });
    expect(previewInfo, isNull);
  }

  Future<void> test_noChangeToTypeAnnotation() async {
    await analyze('int x = 0;');
    var typeName = findNode.typeName('int');
    var previewInfo = run({
      typeName: NodeChangeForTypeAnnotation()
        ..recordNullability(
            MockDecoratedType(
                MockDartType(toStringValueWithoutNullability: 'int')),
            false)
    });
    expect(previewInfo.applyTo(code), 'int x = 0;');
    expect(previewInfo.applyTo(code, includeInformative: true), 'int  x = 0;');
    expect(previewInfo.values.single.single.info.description.appliedMessage,
        "Type 'int' was not made nullable");
  }

  Future<void> test_noInfoForTypeAnnotation() async {
    await analyze('int x = 0;');
    var typeName = findNode.typeName('int');
    var previewInfo = run({typeName: NodeChangeForTypeAnnotation()});
    expect(previewInfo, null);
  }

  Future<void> test_noValidMigration() async {
    await analyze('f(a) => null;');
    var literal = findNode.nullLiteral('null');
    var previewInfo = run(
        {literal: NodeChangeForExpression()..addNoValidMigration(_MockInfo())});
    expect(previewInfo.applyTo(code), code);
    expect(previewInfo.applyTo(code, includeInformative: true),
        'f(a) => null /* no valid migration */;');
  }

  Future<void> test_nullCheck_index_cascadeResult() async {
    await analyze('f(a) => a..[0].c;');
    var index = findNode.index('[0]');
    var previewInfo =
        run({index: NodeChangeForExpression()..addNullCheck(_MockInfo())});
    expect(previewInfo.applyTo(code), 'f(a) => a..[0]!.c;');
  }

  Future<void> test_nullCheck_methodInvocation_cascadeResult() async {
    await analyze('f(a) => a..b().c;');
    var method = findNode.methodInvocation('b()');
    var previewInfo = run(
        {method: NodeChangeForMethodInvocation()..addNullCheck(_MockInfo())});
    expect(previewInfo.applyTo(code), 'f(a) => a..b()!.c;');
  }

  Future<void> test_nullCheck_no_parens() async {
    await analyze('f(a) => a++;');
    var expr = findNode.postfix('a++');
    var previewInfo =
        run({expr: NodeChangeForExpression()..addNullCheck(_MockInfo())});
    expect(previewInfo.applyTo(code), 'f(a) => a++!;');
  }

  Future<void> test_nullCheck_parens() async {
    await analyze('f(a) => -a;');
    var expr = findNode.prefix('-a');
    var previewInfo =
        run({expr: NodeChangeForExpression()..addNullCheck(_MockInfo())});
    expect(previewInfo.applyTo(code), 'f(a) => (-a)!;');
  }

  Future<void> test_nullCheck_propertyAccess_cascadeResult() async {
    await analyze('f(a) => a..b.c;');
    var property = findNode.propertyAccess('b');
    var previewInfo = run(
        {property: NodeChangeForPropertyAccess()..addNullCheck(_MockInfo())});
    expect(previewInfo.applyTo(code), 'f(a) => a..b!.c;');
  }

  Future<void> test_parameter_addExplicitType_annotated() async {
    await analyze('f({@deprecated x = 0}) {}');
    var previewInfo = run({
      findNode.simpleParameter('x'): NodeChangeForSimpleFormalParameter()
        ..addExplicitType = nnbdTypeProvider.intType
    });
    expect(previewInfo.applyTo(code), 'f({@deprecated int x = 0}) {}');
  }

  Future<void> test_parameter_addExplicitType_declared_with_covariant() async {
    await analyze('''
class C {
  m({num x}) {}
}
class D extends C {
  m({covariant x = 3}) {}
}
''');
    var previewInfo = run({
      findNode.simpleParameter('x = 3'): NodeChangeForSimpleFormalParameter()
        ..addExplicitType = nnbdTypeProvider.intType
    });
    expect(previewInfo.applyTo(code), '''
class C {
  m({num x}) {}
}
class D extends C {
  m({covariant int x = 3}) {}
}
''');
  }

  Future<void> test_parameter_addExplicitType_declared_with_final() async {
    await analyze('f({final x = 0}) {}');
    var previewInfo = run({
      findNode.simpleParameter('x'): NodeChangeForSimpleFormalParameter()
        ..addExplicitType = nnbdTypeProvider.intType
    });
    expect(previewInfo.applyTo(code), 'f({final int x = 0}) {}');
  }

  Future<void> test_parameter_addExplicitType_declared_with_var() async {
    await analyze('f({var x = 0}) {}');
    var previewInfo = run({
      findNode.simpleParameter('x'): NodeChangeForSimpleFormalParameter()
        ..addExplicitType = nnbdTypeProvider.intType
    });
    expect(previewInfo.applyTo(code), 'f({int x = 0}) {}');
  }

  Future<void> test_parameter_addExplicitType_named() async {
    await analyze('f({x = 0}) {}');
    var previewInfo = run({
      findNode.simpleParameter('x'): NodeChangeForSimpleFormalParameter()
        ..addExplicitType = nnbdTypeProvider.intType
    });
    expect(previewInfo.applyTo(code), 'f({int x = 0}) {}');
  }

  Future<void> test_parameter_addExplicitType_no() async {
    await analyze('f([x = 0]) {}');
    var previewInfo = run(
        {findNode.simpleParameter('x'): NodeChangeForSimpleFormalParameter()});
    expect(previewInfo, isNull);
  }

  Future<void> test_parameter_addExplicitType_optional_insert() async {
    await analyze('f([x = 0]) {}');
    var previewInfo = run({
      findNode.simpleParameter('x'): NodeChangeForSimpleFormalParameter()
        ..addExplicitType = nnbdTypeProvider.intType
    });
    expect(previewInfo.applyTo(code), 'f([int x = 0]) {}');
  }

  Future<void> test_parameter_addExplicitType_prefixed_type() async {
    await analyze('''
import 'dart:core' as core;
f({x = 0}) {}
''');
    var previewInfo = run({
      findNode.simpleParameter('x'): NodeChangeForSimpleFormalParameter()
        ..addExplicitType = nnbdTypeProvider.intType
    });
    expect(previewInfo.applyTo(code), '''
import 'dart:core' as core;
f({core.int x = 0}) {}
''');
  }

  Future<void> test_parameter_field_formal_addExplicitType() async {
    await analyze('''
class C {
  int x;
  C(this.x) {}
}
''');
    var previewInfo = run({
      findNode.fieldFormalParameter('this.x'):
          NodeChangeForFieldFormalParameter()
            ..addExplicitType = nnbdTypeProvider.intType
    });
    expect(previewInfo.applyTo(code), '''
class C {
  int x;
  C(int this.x) {}
}
''');
  }

  Future<void>
      test_parameter_field_formal_addExplicitType_declared_with_final() async {
    await analyze('''
class C {
  int x;
  C(final this.x) {}
}
''');
    var previewInfo = run({
      findNode.fieldFormalParameter('this.x'):
          NodeChangeForFieldFormalParameter()
            ..addExplicitType = nnbdTypeProvider.intType
    });
    expect(previewInfo.applyTo(code), '''
class C {
  int x;
  C(final int this.x) {}
}
''');
  }

  Future<void>
      test_parameter_field_formal_addExplicitType_declared_with_var() async {
    await analyze('''
class C {
  int x;
  C(var this.x) {}
}
''');
    var previewInfo = run({
      findNode.fieldFormalParameter('this.x'):
          NodeChangeForFieldFormalParameter()
            ..addExplicitType = nnbdTypeProvider.intType
    });
    expect(previewInfo.applyTo(code), '''
class C {
  int x;
  C(int this.x) {}
}
''');
  }

  Future<void> test_parameter_field_formal_addExplicitType_no() async {
    await analyze('''
class C {
  int x;
  C(this.x) {}
}
''');
    var previewInfo = run({
      findNode.fieldFormalParameter('this.x'):
          NodeChangeForFieldFormalParameter()
    });
    expect(previewInfo, isNull);
  }

  Future<void> test_post_increment_add_null_check() async {
    var content = 'f(int x) => x++;';
    await analyze(content);
    var previewInfo = run({
      findNode.postfix('++'): NodeChangeForPostfixExpression()
        ..addNullCheck(null)
    });
    expect(previewInfo.applyTo(code), 'f(int x) => x++!;');
  }

  Future<void> test_post_increment_change_target() async {
    var content = 'f(List<int> x) => x[0]++;';
    await analyze(content);
    var previewInfo = run({
      findNode.postfix('++'): NodeChangeForPostfixExpression(),
      findNode.index('[0]').target: NodeChangeForExpression()
        ..addNullCheck(null)
    });
    expect(previewInfo.applyTo(code), 'f(List<int> x) => x![0]++;');
  }

  Future<void> test_post_increment_introduce_as() async {
    var content = 'f(int x) => x++;';
    await analyze(content);
    var previewInfo = run({
      findNode.postfix('++'): NodeChangeForPostfixExpression()
        ..introduceAs(nnbdTypeProvider.intType, null)
    });
    expect(previewInfo.applyTo(code), 'f(int x) => x++ as int;');
  }

  Future<void> test_post_increment_with_bad_combined_type() async {
    var content = 'f(int x) => x++;';
    await analyze(content);
    var previewInfo = run({
      findNode.postfix('++'): NodeChangeForPostfixExpression()
        ..hasBadCombinedType = true
    });
    expect(previewInfo.applyTo(code), content);
    expect(previewInfo, hasLength(1));
    var edit = previewInfo[content.indexOf('++')].single;
    expect(edit.info.description,
        NullabilityFixDescription.compoundAssignmentHasBadCombinedType);
    expect(edit.isInformative, isTrue);
    expect(edit.length, '++'.length);
  }

  Future<void> test_post_increment_with_nullable_source() async {
    var content = 'f(int x) => x++;';
    await analyze(content);
    var previewInfo = run({
      findNode.postfix('++'): NodeChangeForPostfixExpression()
        ..hasNullableSource = true
    });
    expect(previewInfo.applyTo(code), content);
    expect(previewInfo, hasLength(1));
    var edit = previewInfo[content.indexOf('++')].single;
    expect(edit.info.description,
        NullabilityFixDescription.compoundAssignmentHasNullableSource);
    expect(edit.isInformative, isTrue);
    expect(edit.length, '++'.length);
  }

  Future<void> test_pre_increment_add_null_check() async {
    var content = 'f(int x) => ++x;';
    await analyze(content);
    var previewInfo = run({
      findNode.prefix('++'): NodeChangeForPrefixExpression()..addNullCheck(null)
    });
    expect(previewInfo.applyTo(code), 'f(int x) => (++x)!;');
  }

  Future<void> test_pre_increment_change_target() async {
    var content = 'f(List<int> x) => ++x[0];';
    await analyze(content);
    var previewInfo = run({
      findNode.prefix('++'): NodeChangeForPrefixExpression(),
      findNode.index('[0]').target: NodeChangeForExpression()
        ..addNullCheck(null)
    });
    expect(previewInfo.applyTo(code), 'f(List<int> x) => ++x![0];');
  }

  Future<void> test_pre_increment_introduce_as() async {
    var content = 'f(int x) => ++x;';
    await analyze(content);
    var previewInfo = run({
      findNode.prefix('++'): NodeChangeForPrefixExpression()
        ..introduceAs(nnbdTypeProvider.intType, null)
    });
    expect(previewInfo.applyTo(code), 'f(int x) => ++x as int;');
  }

  Future<void> test_pre_increment_with_bad_combined_type() async {
    var content = 'f(int x) => ++x;';
    await analyze(content);
    var previewInfo = run({
      findNode.prefix('++'): NodeChangeForPrefixExpression()
        ..hasBadCombinedType = true
    });
    expect(previewInfo.applyTo(code), content);
    expect(previewInfo, hasLength(1));
    var edit = previewInfo[content.indexOf('++')].single;
    expect(edit.info.description,
        NullabilityFixDescription.compoundAssignmentHasBadCombinedType);
    expect(edit.isInformative, isTrue);
    expect(edit.length, '++'.length);
  }

  Future<void> test_pre_increment_with_nullable_source() async {
    var content = 'f(int x) => ++x;';
    await analyze(content);
    var previewInfo = run({
      findNode.prefix('++'): NodeChangeForPrefixExpression()
        ..hasNullableSource = true
    });
    expect(previewInfo.applyTo(code), content);
    expect(previewInfo, hasLength(1));
    var edit = previewInfo[content.indexOf('++')].single;
    expect(edit.info.description,
        NullabilityFixDescription.compoundAssignmentHasNullableSource);
    expect(edit.isInformative, isTrue);
    expect(edit.length, '++'.length);
  }

  Future<void>
      test_removeAs_in_cascade_target_no_parens_needed_cascade() async {
    await analyze('f(a) => ((a..b) as dynamic)..c;');
    var cascade = findNode.cascade('a..b');
    var cast = cascade.parent.parent;
    var previewInfo = run({cast: NodeChangeForAsExpression()..removeAs = true});
    expect(previewInfo.applyTo(code), 'f(a) => a..b..c;');
  }

  Future<void>
      test_removeAs_in_cascade_target_no_parens_needed_conditional() async {
    // TODO(paulberry): would it be better to keep the parens in this case for
    // clarity, even though they're not needed?
    await analyze('f(a, b, c) => ((a ? b : c) as dynamic)..d;');
    var conditional = findNode.conditionalExpression('a ? b : c');
    var cast = conditional.parent.parent;
    var previewInfo = run({cast: NodeChangeForAsExpression()..removeAs = true});
    expect(previewInfo.applyTo(code), 'f(a, b, c) => a ? b : c..d;');
  }

  Future<void>
      test_removeAs_in_cascade_target_parens_needed_assignment() async {
    await analyze('f(a, b) => ((a = b) as dynamic)..c;');
    var assignment = findNode.assignment('a = b');
    var cast = assignment.parent.parent;
    var previewInfo = run({cast: NodeChangeForAsExpression()..removeAs = true});
    expect(previewInfo.applyTo(code), 'f(a, b) => (a = b)..c;');
  }

  Future<void> test_removeAs_in_cascade_target_parens_needed_throw() async {
    await analyze('f(a) => ((throw a) as dynamic)..b;');
    var throw_ = findNode.throw_('throw a');
    var cast = throw_.parent.parent;
    var previewInfo = run({cast: NodeChangeForAsExpression()..removeAs = true});
    expect(previewInfo.applyTo(code), 'f(a) => (throw a)..b;');
  }

  Future<void>
      test_removeAs_lower_precedence_do_not_remove_inner_parens() async {
    await analyze('f(a, b, c) => (a == b) as Null == c;');
    var expr = findNode.binary('a == b');
    var previewInfo =
        run({expr.parent.parent: NodeChangeForAsExpression()..removeAs = true});
    expect(previewInfo.applyTo(code), 'f(a, b, c) => (a == b) == c;');
  }

  Future<void> test_removeAs_lower_precedence_remove_inner_parens() async {
    await analyze('f(a, b) => (a == b) as Null;');
    var expr = findNode.binary('a == b');
    var previewInfo =
        run({expr.parent.parent: NodeChangeForAsExpression()..removeAs = true});
    expect(previewInfo.applyTo(code), 'f(a, b) => a == b;');
  }

  Future<void> test_removeAs_parens_needed_due_to_cascade() async {
    // Note: parens are needed, and they could either be around `c..d` or around
    // `throw c..d`.  In an ideal world, we would see that we can just keep the
    // parens we have, but this is difficult because we don't see that the
    // parens are needed until we walk far enough up the AST to see that we're
    // inside a casade expression.  So we drop the parens and then create new
    // ones surrounding `throw c..d`.
    //
    // Strictly speaking the code we produce is correct, it's just making a
    // slightly larger edit than necessary.  This is presumably a really rare
    // corner case so for now we're not worrying about it.
    await analyze('f(a, c) => a..b = throw (c..d) as int;');
    var cd = findNode.cascade('c..d');
    var cast = cd.parent.parent;
    var previewInfo = run({cast: NodeChangeForAsExpression()..removeAs = true});
    expect(previewInfo.applyTo(code), 'f(a, c) => a..b = (throw c..d);');
  }

  Future<void>
      test_removeAs_parens_needed_due_to_cascade_in_conditional_else() async {
    await analyze('f(a, b, c) => a ? b : (c..d) as int;');
    var cd = findNode.cascade('c..d');
    var cast = cd.parent.parent;
    var previewInfo = run({cast: NodeChangeForAsExpression()..removeAs = true});
    expect(previewInfo.applyTo(code), 'f(a, b, c) => a ? b : (c..d);');
  }

  Future<void>
      test_removeAs_parens_needed_due_to_cascade_in_conditional_then() async {
    await analyze('f(a, b, d) => a ? (b..c) as int : d;');
    var bc = findNode.cascade('b..c');
    var cast = bc.parent.parent;
    var previewInfo = run({cast: NodeChangeForAsExpression()..removeAs = true});
    expect(previewInfo.applyTo(code), 'f(a, b, d) => a ? (b..c) : d;');
  }

  Future<void> test_removeAs_raise_precedence_do_not_remove_parens() async {
    await analyze('f(a, b, c) => a | (b | c as int);');
    var expr = findNode.binary('b | c');
    var previewInfo =
        run({expr.parent: NodeChangeForAsExpression()..removeAs = true});
    expect(previewInfo.applyTo(code), 'f(a, b, c) => a | (b | c);');
  }

  Future<void> test_removeAs_raise_precedence_no_parens_to_remove() async {
    await analyze('f(a, b, c) => a = b | c as int;');
    var expr = findNode.binary('b | c');
    var previewInfo =
        run({expr.parent: NodeChangeForAsExpression()..removeAs = true});
    expect(previewInfo.applyTo(code), 'f(a, b, c) => a = b | c;');
  }

  Future<void> test_removeAs_raise_precedence_remove_parens() async {
    await analyze('f(a, b, c) => a < (b | c as int);');
    var expr = findNode.binary('b | c');
    var previewInfo =
        run({expr.parent: NodeChangeForAsExpression()..removeAs = true});
    expect(previewInfo.applyTo(code), 'f(a, b, c) => a < b | c;');
  }

  Future<void> test_removeLanguageVersion() async {
    await analyze('''
//@dart=2.6
void main() {}
''');
    var previewInfo = run({
      findNode.unit: NodeChangeForCompilationUnit()
        ..removeLanguageVersionComment = true
    });
    // TODO(mfairhurst): Remove beginning \n once it renders properly in preview
    expect(previewInfo.applyTo(code), '\nvoid main() {}\n');
  }

  Future<void> test_removeLanguageVersion_after_license() async {
    await analyze('''
// Some licensing stuff here...
// Some copyrighting stuff too...
// etc...
// @dart = 2.6
void main() {}
''');
    var previewInfo = run({
      findNode.unit: NodeChangeForCompilationUnit()
        ..removeLanguageVersionComment = true
    });
    // TODO(mfairhurst): Remove beginning \n once it renders properly in preview
    expect(previewInfo.applyTo(code), '''
// Some licensing stuff here...
// Some copyrighting stuff too...
// etc...

void main() {}
''');
  }

  Future<void> test_removeLanguageVersion_spaces() async {
    await analyze('''
// @dart = 2.6
void main() {}
''');
    var previewInfo = run({
      findNode.unit: NodeChangeForCompilationUnit()
        ..removeLanguageVersionComment = true
    });
    // TODO(mfairhurst): Remove beginning \n once it renders properly in preview
    expect(previewInfo.applyTo(code), '\nvoid main() {}\n');
  }

  Future<void> test_removeLanguageVersion_withOtherChanges() async {
    await analyze('''
//@dart=2.6
int f() => null;
''');
    var previewInfo = run({
      findNode.unit: NodeChangeForCompilationUnit()
        ..removeLanguageVersionComment = true,
      findNode.typeAnnotation('int'): NodeChangeForTypeAnnotation()
        ..recordNullability(
            MockDecoratedType(
                MockDartType(toStringValueWithoutNullability: 'int')),
            true)
    });
    // TODO(mfairhurst): Remove beginning \n once it renders properly in preview
    expect(previewInfo.applyTo(code), '\nint? f() => null;\n');
  }

  Future<void> test_removeNullAwarenessFromMethodInvocation() async {
    await analyze('f(x) => x?.m();');
    var methodInvocation = findNode.methodInvocation('?.');
    var previewInfo = run({
      methodInvocation: NodeChangeForMethodInvocation()
        ..removeNullAwareness = true
    });
    expect(previewInfo.applyTo(code), 'f(x) => x.m();');
  }

  Future<void>
      test_removeNullAwarenessFromMethodInvocation_changeArgument() async {
    await analyze('f(x) => x?.m(x);');
    var methodInvocation = findNode.methodInvocation('?.');
    var argument = findNode.simple('x);');
    var previewInfo = run({
      methodInvocation: NodeChangeForMethodInvocation()
        ..removeNullAwareness = true,
      argument: NodeChangeForExpression()..addNullCheck(_MockInfo())
    });
    expect(previewInfo.applyTo(code), 'f(x) => x.m(x!);');
  }

  Future<void>
      test_removeNullAwarenessFromMethodInvocation_changeTarget() async {
    await analyze('f(x) => (x as dynamic)?.m();');
    var methodInvocation = findNode.methodInvocation('?.');
    var cast = findNode.as_('as');
    var previewInfo = run({
      methodInvocation: NodeChangeForMethodInvocation()
        ..removeNullAwareness = true,
      cast: NodeChangeForAsExpression()..removeAs = true
    });
    expect(previewInfo.applyTo(code), 'f(x) => x.m();');
  }

  Future<void>
      test_removeNullAwarenessFromMethodInvocation_changeTypeArgument() async {
    await analyze('f(x) => x?.m<int>();');
    var methodInvocation = findNode.methodInvocation('?.');
    var typeAnnotation = findNode.typeAnnotation('int');
    var previewInfo = run({
      methodInvocation: NodeChangeForMethodInvocation()
        ..removeNullAwareness = true,
      typeAnnotation: NodeChangeForTypeAnnotation()
        ..recordNullability(
            MockDecoratedType(
                MockDartType(toStringValueWithoutNullability: 'int')),
            true)
    });
    expect(previewInfo.applyTo(code), 'f(x) => x.m<int?>();');
  }

  Future<void> test_removeNullAwarenessFromPropertyAccess() async {
    await analyze('f(x) => x?.y;');
    var propertyAccess = findNode.propertyAccess('?.');
    var previewInfo = run({
      propertyAccess: NodeChangeForPropertyAccess()..removeNullAwareness = true
    });
    expect(previewInfo.applyTo(code), 'f(x) => x.y;');
  }

  Future<void> test_removeNullAwarenessFromPropertyAccess_changeTarget() async {
    await analyze('f(x) => (x as dynamic)?.y;');
    var propertyAccess = findNode.propertyAccess('?.');
    var cast = findNode.as_('as');
    var previewInfo = run({
      propertyAccess: NodeChangeForPropertyAccess()..removeNullAwareness = true,
      cast: NodeChangeForAsExpression()..removeAs = true
    });
    expect(previewInfo.applyTo(code), 'f(x) => x.y;');
  }

  Future<void>
      test_requiredAnnotationToRequiredKeyword_leadingAnnotations() async {
    addMetaPackage();
    await analyze('''
import 'package:meta/meta.dart';
f({@deprecated @required int x}) {}
''');
    var annotation = findNode.annotation('required');
    var previewInfo = run({
      annotation: NodeChangeForAnnotation()..changeToRequiredKeyword = true
    });
    expect(previewInfo.applyTo(code), '''
import 'package:meta/meta.dart';
f({@deprecated required int x}) {}
''');
    expect(previewInfo.values.single.single.isDeletion, true);
  }

  Future<void> test_requiredAnnotationToRequiredKeyword_prefixed() async {
    addMetaPackage();
    await analyze('''
import 'package:meta/meta.dart' as meta;
f({@meta.required int x}) {}
''');
    var annotation = findNode.annotation('required');
    var previewInfo = run({
      annotation: NodeChangeForAnnotation()..changeToRequiredKeyword = true
    });
    expect(previewInfo.applyTo(code), '''
import 'package:meta/meta.dart' as meta;
f({required int x}) {}
''');
    expect(previewInfo.values.single.single.isDeletion, true);
  }

  Future<void> test_requiredAnnotationToRequiredKeyword_renamed() async {
    addMetaPackage();
    await analyze('''
import 'package:meta/meta.dart';
const foo = required;
f({@foo int x}) {}
''');
    var annotation = findNode.annotation('@foo');
    var previewInfo = run({
      annotation: NodeChangeForAnnotation()..changeToRequiredKeyword = true
    });
    expect(previewInfo.applyTo(code), '''
import 'package:meta/meta.dart';
const foo = required;
f({required int x}) {}
''');
  }

  Future<void> test_requiredAnnotationToRequiredKeyword_simple() async {
    addMetaPackage();
    await analyze('''
import 'package:meta/meta.dart';
f({@required int x}) {}
''');
    var annotation = findNode.annotation('required');
    var previewInfo = run({
      annotation: NodeChangeForAnnotation()..changeToRequiredKeyword = true
    });
    expect(previewInfo.applyTo(code), '''
import 'package:meta/meta.dart';
f({required int x}) {}
''');
    expect(previewInfo.values.single.single.isDeletion, true);
  }

  Future<void>
      test_requiredAnnotationToRequiredKeyword_simple_removeViaComment() async {
    addMetaPackage();
    await analyze('''
import 'package:meta/meta.dart';
f({@required int x}) {}
''');
    var annotation = findNode.annotation('required');
    var previewInfo = run(
        {annotation: NodeChangeForAnnotation()..changeToRequiredKeyword = true},
        removeViaComments: true);
    expect(previewInfo.applyTo(code), '''
import 'package:meta/meta.dart';
f({required int x}) {}
''');
    expect(previewInfo.values.single.single.isDeletion, true);
  }

  Future<void> test_variableDeclarationList_addExplicitType_insert() async {
    await analyze('final x = 0;');
    var previewInfo = run({
      findNode.variableDeclarationList('final'):
          NodeChangeForVariableDeclarationList()
            ..addExplicitType = nnbdTypeProvider.intType
    });
    expect(previewInfo.applyTo(code), 'final int x = 0;');
  }

  Future<void> test_variableDeclarationList_addExplicitType_metadata() async {
    await analyze('@deprecated var x = 0;');
    var previewInfo = run({
      findNode.variableDeclarationList('var'):
          NodeChangeForVariableDeclarationList()
            ..addExplicitType = nnbdTypeProvider.intType
    });
    expect(previewInfo.applyTo(code), '@deprecated int x = 0;');
  }

  Future<void> test_variableDeclarationList_addExplicitType_no() async {
    await analyze('var x = 0;');
    var previewInfo = run({
      findNode.variableDeclarationList('var'):
          NodeChangeForVariableDeclarationList()
    });
    expect(previewInfo, isNull);
  }

  Future<void> test_variableDeclarationList_addExplicitType_otherPlans() async {
    await analyze('var x = 0;');
    var previewInfo = run({
      findNode.variableDeclarationList('var'):
          NodeChangeForVariableDeclarationList()
            ..addExplicitType = nnbdTypeProvider.intType,
      findNode.integerLiteral('0'): NodeChangeForExpression()
        ..addNullCheck(_MockInfo())
    });
    expect(previewInfo.applyTo(code), 'int x = 0!;');
  }

  Future<void> test_variableDeclarationList_addExplicitType_prefixed() async {
    await analyze('''
import 'dart:core' as core;
final x = 0;
''');
    var previewInfo = run({
      findNode.variableDeclarationList('final'):
          NodeChangeForVariableDeclarationList()
            ..addExplicitType = nnbdTypeProvider.intType
    });
    expect(previewInfo.applyTo(code), '''
import 'dart:core' as core;
final core.int x = 0;
''');
  }

  Future<void> test_variableDeclarationList_addExplicitType_replaceVar() async {
    await analyze('var x = 0;');
    var previewInfo = run({
      findNode.variableDeclarationList('var'):
          NodeChangeForVariableDeclarationList()
            ..addExplicitType = nnbdTypeProvider.intType
    });
    expect(previewInfo.applyTo(code), 'int x = 0;');
  }

  Future<void> test_warnOnDeadIf_false() async {
    await analyze('''
f(int i) {
  if (i == null) print(i);
}
''');
    var previewInfo = run({
      findNode.statement('if'): NodeChangeForIfStatement()
        ..conditionValue = false
    }, warnOnWeakCode: true);
    expect(previewInfo.applyTo(code, includeInformative: true), '''
f(int i) {
  if (i == null /* == false */) print(i);
}
''');
  }

  Future<void> test_warnOnDeadIf_true() async {
    await analyze('''
f(int i) {
  if (i != null) print(i);
}
''');
    var previewInfo = run({
      findNode.statement('if'): NodeChangeForIfStatement()
        ..conditionValue = true
    }, warnOnWeakCode: true);
    expect(previewInfo.applyTo(code, includeInformative: true), '''
f(int i) {
  if (i != null /* == true */) print(i);
}
''');
  }

  Future<void> test_warnOnNullAwareAccess() async {
    var content = '''
f(int i) {
  print(i?.isEven);
}
''';
    await analyze(content);
    var previewInfo = run({
      findNode.propertyAccess('?.'): NodeChangeForPropertyAccess()
        ..removeNullAwareness = true
    }, warnOnWeakCode: true);
    expect(previewInfo.applyTo(code), content);
    expect(previewInfo, hasLength(1));
    var edit = previewInfo[content.indexOf('?')].single;
    expect(edit.isInformative, isTrue);
    expect(edit.length, '?'.length);
  }
}

class FixAggregatorTestBase extends AbstractSingleUnitTest {
  String code;

  Future<void> analyze(String code) async {
    this.code = code;
    await resolveTestUnit(code);
  }

  Map<int, List<AtomicEdit>> run(Map<AstNode, NodeChange> changes,
      {bool removeViaComments = false, bool warnOnWeakCode = false}) {
    return FixAggregator.run(testUnit, testCode, changes,
        removeViaComments: removeViaComments, warnOnWeakCode: warnOnWeakCode);
  }
}

class MockDartType implements TypeImpl {
  final String toStringValueWithNullability;

  final String toStringValueWithoutNullability;

  const MockDartType(
      {this.toStringValueWithNullability,
      this.toStringValueWithoutNullability});

  @override
  String getDisplayString({
    bool skipAllDynamicArguments = false,
    bool withNullability = false,
  }) {
    var result = withNullability
        ? toStringValueWithNullability
        : toStringValueWithoutNullability;
    expect(result, isNotNull);
    return result;
  }

  @override
  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockDecoratedType implements DecoratedType {
  @override
  final DartType type;

  const MockDecoratedType(this.type);

  @override
  NullabilityNode get node =>
      NullabilityNode.forTypeAnnotation(NullabilityNodeTarget.text('test'));

  @override
  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class _MockInfo implements AtomicEditInfo {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
