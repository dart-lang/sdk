// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:linter/src/rules/use_build_context_synchronously.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AsyncStateTest);
    defineReflectiveTests(UseBuildContextSynchronouslyTest);
  });
}

@reflectiveTest
class AsyncStateTest extends PubPackageResolutionTest {
  @override
  bool get addFlutterPackageDep => true;

  FindNode get findNode => FindNode(result.content, result.unit);

  Future<void> assertNoErrorsInCode(String code) async {
    addTestFile(code);
    await resolveTestFile();
  }

  test_adjacentStrings_referenceAfter_awaitInString() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  '' '${await Future.value()}';
  context /* ref */;
}
''');
    var adjacentStrings = findNode.expressionStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(adjacentStrings.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_adjacentStrings_referenceInSecondString_awaitInFirstString() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  '${await Future.value()}' '${context /* ref */}';
}
''');
    var adjacentStrings = findNode.adjacentStrings('await');
    var reference = findNode.stringInterpolation('context /* ref */');
    expect(adjacentStrings.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_awaitExpression_referenceInExpression() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  await context /* ref */;
}
''');
    var await_ = findNode.awaitExpression('context /* ref */');
    var reference = findNode.simple('context /* ref */');
    expect(await_.asyncStateFor(reference), isNull);
  }

  test_block_referenceThenAwait() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  await Future.value();
  context /* ref */;
}
''');
    var block = findNode.block('context /* ref */');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(block.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_cascade_referenceAfter_awaitInTarget() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  (await Future.value())..toString();
  context /* ref */;
}
''');
    var cascade = findNode.expressionStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(cascade.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_cascade_referenceAfterTarget_awaitAfterTarget() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  []..add(await Future.value())..add(context /* ref */);
}
''');
    var cascade = findNode.expressionStatement('await');
    var reference = findNode.cascade('context /* ref */');
    expect(cascade.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_cascade_referenceAfterTarget_awaitInTarget() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  (await Future.value())..add(context /* ref */);
}
''');
    var cascade = findNode.cascade('await');
    var reference = findNode.methodInvocation('context /* ref */');
    expect(cascade.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_cascade_referenceAfterTarget_awaitInTarget2() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  (await Future.value())..add(1)..add(context /* ref */);
}
''');
    var cascade = findNode.cascade('await');
    var reference = findNode.methodInvocation('context /* ref */');
    expect(cascade.asyncStateFor(reference), AsyncState.asynchronous);
  }

  @FailingTest()
  test_conditional_referenceAfter_awaitInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  await Future.value(true) ? null : null;
  context /* ref */;
}
''');
    var conditional = findNode.expressionStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(conditional.asyncStateFor(reference), AsyncState.asynchronous);
  }

  @FailingTest()
  test_conditional_referenceAfter_awaitInThen() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  false ? await Future.value() : null;
  context /* ref */;
}
''');
    var conditional = findNode.expressionStatement('false');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(conditional.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_conditional_referenceInElse_mountedCheckInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  context.mounted ? null : context /* ref */;
}
''');
    var conditional = findNode.conditionalExpression('context /* ref */');
    var reference = findNode.simple('context /* ref */');
    expect(conditional.asyncStateFor(reference), isNull);
  }

  test_conditional_referenceInElse_notMountedCheckInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  !context.mounted ? null : context /* ref */;
}
''');
    var conditional = findNode.conditionalExpression('context /* ref */');
    var reference = findNode.simple('context /* ref */');
    expect(
        conditional.asyncStateFor(reference), equals(AsyncState.mountedCheck));
  }

  test_conditional_referenceInThen_mountedCheckInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  context.mounted ? context /* ref */ : null;
}
''');
    var conditional = findNode.conditionalExpression('context /* ref */');
    var reference = findNode.simple('context /* ref */');
    expect(
        conditional.asyncStateFor(reference), equals(AsyncState.mountedCheck));
  }

  test_conditional_referenceInThen_notMountedCheckInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  !context.mounted ? context /* ref */ : null;
}
''');
    var conditional = findNode.conditionalExpression('context /* ref */');
    var reference = findNode.simple('context /* ref */');
    expect(conditional.asyncStateFor(reference), isNull);
  }

  test_forElementWithDeclaration_referenceAfter_awaitInPartCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  [
    for (var i = 0; i < await Future.value(1); i++) null,
  ];
  context /* ref */;
}
''');
    var listLiteral = findNode.expressionStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(listLiteral.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_forElementWithDeclaration_referenceAfter_awaitInPartInitialization() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  [
    for (var i = await Future.value(1); i < 7; i++) null,
  ];
  context /* ref */;
}
''');
    var listLiteral = findNode.expressionStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(listLiteral.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_forElementWithDeclaration_referenceAfter_awaitInPartUpdaters() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  [
    for (var i = 0; i < 5; i += await Future.value()) null,
  ];
  context /* ref */;
}
''');
    var listLiteral = findNode.expressionStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(listLiteral.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_forElementWithDeclaration_referenceAfter_mountedCheckInPartCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  [
    for (var i = 0; context.mounted; i++) context /* ref */,
  ];
}
''');
    var forElement = findNode.forElement('for ');
    var reference = findNode.expression('context /* ref */');
    expect(forElement.asyncStateFor(reference), AsyncState.mountedCheck);
  }

  test_forElementWithEach_referenceAfter_awaitInExpression() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  [
    for (var e in []) await Future.value(),
  ];
  context /* ref */;
}
''');
    var listLiteral = findNode.expressionStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(listLiteral.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_forElementWithEach_referenceAfter_awaitInPartExpression() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  [
    for (var e in await Future.value([])) null,
  ];
  context /* ref */;
}
''');
    var listLiteral = findNode.expressionStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(listLiteral.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_forElementWithExpression_referenceAfter_awaitInPartCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context, int i) async {
  [
    for (i = 0; i < await Future.value(1); i++) null,
  ];
  context /* ref */;
}
''');
    var listLiteral = findNode.expressionStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(listLiteral.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_forElementWithExpression_referenceAfter_awaitInPartInitialization() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context, int i) async {
  [
    for (i = await Future.value(1); i < 7; i++) null,
  ];
  context /* ref */;
}
''');
    var listLiteral = findNode.expressionStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(listLiteral.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_forElementWithExpression_referenceAfter_awaitInPartUpdaters() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context, int i) async {
  [
    for (i = 0; i < 5; i += await Future.value()) null,
  ];
  context /* ref */;
}
''');
    var listLiteral = findNode.expressionStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(listLiteral.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_forElementWithExpression_referenceAfter_mountedCheckInPartCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context, int i) async {
  [
    for (i = 0; context.mounted; i++) context /* ref */,
  ];
}
''');
    var forElement = findNode.forElement('for ');
    var reference = findNode.expression('context /* ref */');
    expect(forElement.asyncStateFor(reference), AsyncState.mountedCheck);
  }

  test_functionExpressionInvocation_referenceAfter_awaitInTarget() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  ((await Future.value()).add)(1);
  context /* ref */;
}
''');
    var functionExpressionInvocation = findNode.expressionStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(functionExpressionInvocation.asyncStateFor(reference),
        AsyncState.asynchronous);
  }

  test_ifElement_referenceAfter_asyncInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  [
    if (await Future.value(true)) null,
    context /* ref */,
  ];
}
''');
    var ifElement = findNode.listLiteral('if (');
    var reference = findNode.expression('context /* ref */,');
    expect(ifElement.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_ifElement_referenceInElse_asyncInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  [
    if (await Future.value(true)) null else context /* ref */,
  ];
}
''');
    var ifElement = findNode.ifElement('if (');
    var reference = findNode.expression('context /* ref */');
    expect(ifElement.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_ifElement_referenceInElse_mountedGuardInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  [
    if (context.mounted) null else context /* ref */,
  ];
}
''');
    var ifElement = findNode.ifElement('if (');
    var reference = findNode.expression('context /* ref */');
    expect(ifElement.asyncStateFor(reference), isNull);
  }

  test_ifElement_referenceInElse_notMountedGuardInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  [
    if (!context.mounted) null else context /* ref */,
  ];
}
''');
    var ifElement = findNode.ifElement('if (');
    var reference = findNode.expression('context /* ref */');
    expect(ifElement.asyncStateFor(reference), AsyncState.mountedCheck);
  }

  test_ifElement_referenceInThen_asyncInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  [
    if (await Future.value(true)) context /* ref */,
  ];
}
''');
    var ifElement = findNode.ifElement('if (');
    var reference = findNode.expression('context /* ref */');
    expect(ifElement.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_ifStatement_referenceAfter_asyncInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  if (await Future.value(true)) {
    return;
  }
  context /* ref */;
}
''');
    var ifStatement = findNode.ifStatement('if (');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(ifStatement.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_ifStatement_referenceAfter_asyncInThen_notMountedGuardInElse() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  if (1 == 2) {
    await Future.value();
  } else {
    if (!mounted) return;
  }
  context /* ref */;
}
''');
    var ifStatement = findNode.ifStatement('if (1');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(ifStatement.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_ifStatement_referenceAfter_awaitThenExitInElse() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  if (1 == 2) {
  } else {
    await Future.value();
    return;
  }
  context /* ref */;
}
''');
    var ifStatement = findNode.ifStatement('if ');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(ifStatement.asyncStateFor(reference), isNull);
  }

  test_ifStatement_referenceAfter_awaitThenExitInThen() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  if (1 == 2) {
    await Future.value();
    return;
  }
  context /* ref */;
}
''');
    var ifStatement = findNode.ifStatement('if ');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(ifStatement.asyncStateFor(reference), isNull);
  }

  test_ifStatement_referenceAfter_notMountedCheckInCondition_break() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  switch (1) {
    case (1):
      if (!context.mounted) break;
      context /* ref */;
  }
}
''');
    var ifStatement = findNode.ifStatement('if ');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(ifStatement.asyncStateFor(reference), AsyncState.notMountedCheck);
  }

  test_ifStatement_referenceAfter_notMountedCheckInCondition_exit() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  if (!context.mounted) return;
  context /* ref */;
}
''');
    var ifStatement = findNode.ifStatement('if ');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(ifStatement.asyncStateFor(reference), AsyncState.notMountedCheck);
  }

  test_ifStatement_referenceAfter_notMountedGuardInCondition_exitInThen_awaitInElse() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  if (!context.mounted) {
    return;
  } else {
    await f();
  }
  context /* ref */;
}
''');
    var ifStatement = findNode.ifStatement('if (');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(ifStatement.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_ifStatement_referenceAfter_notMountedGuardsInThenAndElse() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  if (1 == 2) {
    if (!mounted) return;
  } else {
    if (!mounted) return;
  }
  context /* ref */;
}
''');
    var ifStatement = findNode.ifStatement('if (1');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(ifStatement.asyncStateFor(reference), AsyncState.notMountedCheck);
  }

  test_ifStatement_referenceInElse_asyncInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  if (await Future.value(true)) {
  } else {
    context /* ref */;
  }
}
''');
    var ifStatement = findNode.ifStatement('if (');
    var reference = findNode.block('context /* ref */');
    expect(ifStatement.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_ifStatement_referenceInElse_mountedGuardInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  if (context.mounted) {
  } else {
    context /* ref */;
  }
}
''');
    var ifStatement = findNode.ifStatement('if (');
    var reference = findNode.block('context /* ref */');
    expect(ifStatement.asyncStateFor(reference), isNull);
  }

  test_ifStatement_referenceInThen_asyncInAssignmentInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context, bool m) async {
  if (m = context.mounted) {
    context /* ref */;
  }
}
''');
    var ifStatement = findNode.ifStatement('if (');
    var reference = findNode.block('context /* ref */');
    expect(ifStatement.asyncStateFor(reference), AsyncState.mountedCheck);
  }

  test_ifStatement_referenceInThen_asyncInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  if (await Future.value(true)) {
    context /* ref */;
  }
}
''');
    var ifStatement = findNode.ifStatement('if (');
    var reference = findNode.block('context /* ref */');
    expect(ifStatement.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_ifStatement_referenceInThen_awaitAndMountedInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  if (await Future.value(true) && context.mounted) {
    context /* ref */;
  }
}
''');
    var ifStatement = findNode.ifStatement('if ');
    var reference = findNode.block('context /* ref */');
    expect(ifStatement.asyncStateFor(reference), AsyncState.mountedCheck);
  }

  test_ifStatement_referenceInThen_awaitOrMountedInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  if (await Future.value(true) || context.mounted) {
    context /* ref */;
  }
}
''');
    var ifStatement = findNode.ifStatement('if ');
    var reference = findNode.block('context /* ref */');
    expect(ifStatement.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_ifStatement_referenceInThen_conditionAndMountedInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  if (1 == 2 && context.mounted) {
    context /* ref */;
  }
}
''');
    var ifStatement = findNode.ifStatement('if ');
    var reference = findNode.block('context /* ref */');
    expect(ifStatement.asyncStateFor(reference), AsyncState.mountedCheck);
  }

  test_ifStatement_referenceInThen_conditionOrMountedInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  if (1 == 2 || context.mounted) {
    context /* ref */;
  }
}
''');
    var ifStatement = findNode.ifStatement('if ');
    var reference = findNode.block('context /* ref */');
    expect(ifStatement.asyncStateFor(reference), isNull);
  }

  test_ifStatement_referenceInThen_mountedAndAwaitInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  if (context.mounted && await Future.value(true)) {
    context /* ref */;
  }
}
''');
    var ifStatement = findNode.ifStatement('if ');
    var reference = findNode.block('context /* ref */');
    expect(ifStatement.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_ifStatement_referenceInThen_mountedInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  if (context.mounted) {
    context /* ref */;
  }
}
''');
    var ifStatement = findNode.ifStatement('if ');
    var reference = findNode.block('context /* ref */');
    expect(ifStatement.asyncStateFor(reference), AsyncState.mountedCheck);
  }

  test_ifStatement_referenceInThen_mountedOrAwaitInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  if (context.mounted || await Future.value(true)) {
    context /* ref */;
  }
}
''');
    var ifStatement = findNode.ifStatement('if ');
    var reference = findNode.block('context /* ref */');
    expect(ifStatement.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_indexExpression_referenceInRhs_asyncInIndex() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context, List<Object> list) async {
  list[await c()] = context /* ref */;
}
''');
    var indexExpression = findNode.assignment('[');
    var reference = findNode.expression('context /* ref */');
    expect(indexExpression.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_instanceCreationExpression_referenceInParameters_awaitInParameters() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  new List.filled(await Future.value(1), context /* ref */);
}
''');
    var instanceCreation = findNode.instanceCreation('await');
    var reference = findNode.argumentList('context /* ref */');
    expect(instanceCreation.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_isExpression_referenceAfter_awaitInExpression() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  await Future.value() is int;
  context /* ref */;
}
Future<void> c() async {}
''');
    var isExpression = findNode.expressionStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(isExpression.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_methodInvocation_referenceAfter_asyncInTarget() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  (await Future.value([])).add(1);
  context /* ref */;
}
''');
    var await_ = findNode.expressionStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(await_.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_methodInvocation_referenceAfter_awaitInParameters() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  [].indexOf(1, await Future.value());
  context /* ref */;
}
''');
    var methodInvocation = findNode.expressionStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(methodInvocation.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_methodInvocation_referenceAfter_awaitInTarget() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  (await Future.value()).add(1);
  context /* ref */;
}
''');
    var methodInvocation = findNode.expressionStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(methodInvocation.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_methodInvocation_referenceInParameters_awaitInParameters() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  f(await c(), context /* ref */);
}
void f(_, _) {}
''');
    var methodInvocation = findNode.methodInvocation('await');
    var reference = findNode.argumentList('context /* ref */');
    expect(methodInvocation.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_postfix_referenceAfter_awaitInExpression() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  (await Future.value())!;
  context /* ref */;
}
''');
    var postfix = findNode.expressionStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(postfix.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_propertyAccess_referenceAfter_awaitInTarget() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  (await Future.value(true)).isEven;
  context /* ref */;
}
''');
    var propertyAccess = findNode.expressionStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(propertyAccess.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_recordLiteral_referenceAfter_awaitInField() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  (await Future.value(), );
  context /* ref */;
}
''');
    var recordLiteral = findNode.expressionStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(recordLiteral.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_recordLiteral_referenceAfter_awaitInNamedField() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  (f: await Future.value(), );
  context /* ref */;
}
''');
    var recordLiteral = findNode.expressionStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(recordLiteral.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_spread_referenceAfter_awaitInSpread() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  [...(await Future.value())];
  context /* ref */;
}
''');
    var spread = findNode.expressionStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(spread.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_stringInterpolation_referenceAfter_awaitInStringInterpolation() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  '${await Future.value()}';
  context /* ref */;
}
''');
    var stringInterpolation = findNode.expressionStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(
        stringInterpolation.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_switchExpression_referenceAfter_awaitInCaseBody() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  (switch (1) {
    _ => await c(),
  });
  context /* ref */;
}
''');
    var switchExpression = findNode.expressionStatement('switch');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(switchExpression.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_switchExpression_referenceAfter_awaitInCondition() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  (switch (await Future.value()) {
    _ => null,
  });
  context /* ref */;
}
''');
    var switchExpression = findNode.expressionStatement('switch');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(switchExpression.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_switchStatement_referenceAfter_awaitInCaseBody() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  switch (1) {
    case 1:
      await Future.value();
  }
  context /* ref */;
}
''');
    var switchStatement = findNode.switchStatement('switch');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(switchStatement.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_switchStatement_referenceAfter_awaitInDefault() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  switch (1) {
    default:
      await Future.value();
  }
  context /* ref */;
}
''');
    var switchStatement = findNode.switchStatement('switch');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(switchStatement.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_switchStatement_referenceInCaseBody_awaitInCaseWhen() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  switch (1) {
    case 1 when await Future.value():
      context /* ref */;
  }
}
''');
    var switchStatement = findNode.switchPatternCase('case');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(switchStatement.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_tryStatement_referenceAfter_awaitInBody() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  try {
    await Future.value();
  }
  context /* ref */;
}
Future<void> c() async {}
''');
    var tryStatement = findNode.tryStatement('try');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(tryStatement.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_tryStatement_referenceAfter_notMountedGuardInCatch() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  try {
  } on Exception {
    if (!context.mounted) return;
  }
  context /* ref */;
}
Future<void> c() async {}
''');
    var tryStatement = findNode.tryStatement('try');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(tryStatement.asyncStateFor(reference), isNull);
  }

  test_tryStatement_referenceAfter_notMountedGuardInFinally() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  try {
  } finally {
    if (!context.mounted) return;
  }
  context /* ref */;
}
Future<void> c() async {}
''');
    var tryStatement = findNode.tryStatement('try');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(tryStatement.asyncStateFor(reference), AsyncState.notMountedCheck);
  }

  test_tryStatement_referenceAfter_notMountedGuardInTry() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  try {
    if (!context.mounted) return;
  }
  context /* ref */;
}
Future<void> c() async {}
''');
    var tryStatement = findNode.tryStatement('try');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(tryStatement.asyncStateFor(reference), isNull);
  }

  test_tryStatement_referenceInCatch_awaitInBody() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  try {
    await Future.value();
  } on Exception {
    context /* ref */;
  }
}
Future<void> c() async {}
''');
    var tryStatement = findNode.tryStatement('try');
    var reference = findNode.catchClause('context /* ref */');
    expect(tryStatement.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_whileStatement_referenceAfter_asyncInBody() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  while (true) {
    await Future.value();
    break;
  }
  context /* ref */;
}
''');
    var whileStatement = findNode.whileStatement('while (');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(whileStatement.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_whileStatement_referenceInBody_asyncInBody() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  while (true) {
    await Future.value();
    context /* ref */;
  }
}
''');
    var whileStatement = findNode.whileStatement('while (');
    var reference = findNode.block('context /* ref */');
    expect(whileStatement.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_whileStatement_referenceInBody_asyncInBody2() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  while (true) {
    context /* ref */;
    await Future.value();
  }
}
''');
    var whileStatement = findNode.whileStatement('while (');
    var reference = findNode.block('context /* ref */');
    expect(whileStatement.asyncStateFor(reference), AsyncState.asynchronous);
  }

  test_yield_referenceAfter_asyncInExpression() async {
    await assertNoErrorsInCode(r'''
import 'package:flutter/widgets.dart';
void foo(BuildContext context) async {
  yield (await Future.value());
  context /* ref */;
}
''');
    var yield_ = findNode.yieldStatement('await');
    var reference = findNode.expressionStatement('context /* ref */');
    expect(yield_.asyncStateFor(reference), AsyncState.asynchronous);
  }
}

@reflectiveTest
class UseBuildContextSynchronouslyTest extends LintRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  String get lintRule => 'use_build_context_synchronously';

  /// Ensure we're not run in the test dir.
  @override
  String get testPackageRootPath => '$workspaceRootPath/lib';

  test_assignmentExpressionContainsMountedCheck_thenReferenceToContext() async {
    // Assignment statement-expression with mounted check, then use of
    // BuildContext in if-then statement, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await c();
  var m = context.mounted;
  Navigator.of(context);
}

Future<void> c() async {}
''', [
      lint(121, 21),
    ]);
  }

  test_await_afterReferenceToContext() async {
    // Use of BuildContext, then await, in statement block is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  Navigator.of(context);
  await f();
}

Future<void> f() async {}
''');
  }

  test_await_beforeReferenceToContext() async {
    // Await, then use of BuildContext, in statement block is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await f();
  Navigator.of(context);
}

Future<void> f() async {}
''', [
      lint(94, 21),
    ]);
  }

  test_await_beforeReferenceToContext_inParens() async {
    // Await, then use of BuildContext in parentheses, in statement block is
    // REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await f();
  Navigator.of((context));
}

Future<void> f() async {}
''', [
      lint(94, 23),
    ]);
  }

  test_await_beforeReferenceToContext_nullAsserted() async {
    // Await, then use of null-asserted BuildContext, in statement block is
    // REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext? context) async {
  await f();
  Navigator.of(context!);
}

Future<void> f() async {}
''', [
      lint(95, 22),
    ]);
  }

  test_awaitBeforeIfStatement_withReferenceToContext() async {
    // Await, then use of BuildContext in an unrelated if-body, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  var b = await c();
  if (b) {
    Navigator.of(context);
  }
}
Future<bool> c() async => true;
''', [
      lint(115, 21),
    ]);
  }

  test_awaitBeforeReferenceToContext_inClosure() async {
    // Await, then use of BuildContext in a closure, is REPORTED.
    // todo (pq): what about closures?
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await c();
  f1(() {
    f2(context);
  });
}

void f1(Function f) {}
void f2(BuildContext c) {}
Future<bool> c() async => true;
''');
  }

  test_awaitBeforeWhileBody_referenceToContext_thenMountedGuard() async {
    // Await, then While-true statement, and inside the while-body: use of
    // BuildContext, then mounted guard, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await f();
  while (true) {
    Navigator.of(context);
    if (context.mounted) return;
  }
}

bool mounted = false;
Future<void> f() async {}
''', [
      lint(113, 21),
    ]);
  }

  test_awaitInIfCondition_expressionContainsReferenceToContext() async {
    // Await expression contains use of BuildContext, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(
    BuildContext context, Future<bool> Function(BuildContext) condition) async {
  if (await condition(context)) {
    return;
  }
}
''');
  }

  test_awaitInIfThenAndExitInElse_beforeReferenceToContext() async {
    // Await in an if-body and await-and-exit in the associated else, then use
    // of BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  if (1 == 2) {
    await c();
  } else {
    await c();
    return;
  }
  Navigator.of(context);
}
Future<bool> c() async => true;
''', [
      lint(154, 21),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/3818
  test_context_propertyAccess() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

class W {
  final BuildContext context;
  W(this.context);

  Future<void> f() async {
    await Future.value();
    g(this.context);
  }

  Future<void> g(BuildContext context) async {}
}
''', [
      lint(157, 15),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/3676
  test_contextPassedAsNamedParam() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

Future<void> foo(BuildContext context) async {
    await Future.value();
    bar(context: context);
}

Future<void> bar({required BuildContext context}) async {}
''', [
      lint(117, 21),
    ]);
  }

  test_ifConditionContainsMountedAndReferenceToContext() async {
    // Binary expression contains mounted check AND use of BuildContext, is
    // OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(
    BuildContext context, bool Function(BuildContext) condition) async {
  await c();
  if (context.mounted && condition(context)) {
    return;
  }
}

Future<void> c() async {}
''');
  }

  test_ifConditionContainsMountedCheckInAssignmentLhs_thenReferenceToContext() async {
    // If-condition contains assignment with mounted check on LHS, then use of
    // BuildContext in if-then statement, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await c();
  if (A(context.mounted).b = false) {
    Navigator.of(context);
  }
}

class A {
  bool b;
  A(this.b);
}

Future<void> c() async {}
''', [
      lint(134, 21),
    ]);
  }

  test_ifConditionContainsMountedOrReferenceToContext() async {
    // Binary expression contains mounted check OR use of BuildContext, is
    // REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(
    BuildContext context, bool Function(BuildContext) condition) async {
  await c();
  if (context.mounted || condition(context)) {
    return;
  }
}

Future<void> c() async {}
''', [
      lint(161, 18),
    ]);
  }

  test_ifConditionContainsNotMountedAndReferenceToContext() async {
    // Binary expression contains not-mounted check AND use of BuildContext, is
    // REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(
    BuildContext context, bool Function(BuildContext) condition) async {
  await c();
  if (!context.mounted && condition(context)) {
    return;
  }
}

Future<void> c() async {}
''', [
      lint(162, 18),
    ]);
  }

  test_noAwaitBefore_ifEmptyThen_methodInvocation() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void f(BuildContext context) async {
  if (true) {}
  context.foo();
}

extension on BuildContext {
  void foo() {}
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/3700
  test_propertyAccess_getter() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

extension on BuildContext {
  BuildContext get foo => this;
}

Future<void> f(BuildContext context) async {
  await Future.value();
  context.foo;
}
''', [
      lint(174, 11),
    ]);
  }

  test_propertyAccess_setter() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

extension on BuildContext {
  set foo(int x){ }
}

Future<void> f(BuildContext context) async {
  await Future.value();
  context.foo = 1;
}
''', [
      lint(162, 11),
    ]);
  }
}
