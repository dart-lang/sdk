// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '' deferred as D0;
import '' deferred as D1;

void main() async {
  print('main ${int.parse('2') == 2}');

  // Move the testing to [D0] as expectation files will not write out the root
  // part.
  await D0.loadLibrary();
  await D0.d0();
}

Future d0() async {
  if (unguardedBool) await D1.loadLibrary();

  testAssertStatement();
  testAssertStatement2();
  testConditional();
  testIfElse();
  testIfElse2();
  testIfElse3();
  testIfElse4();
  testBlock();
  testLabeledStatement();
  testWhile();
  testWhile2();
  testDoWhile();
  testDoWhile2();
  testForIn();
  testForIn2();
  testFor();
  testFor2();
  testFor3();
  testSwitch();
  testSwitch2();
  testTryCatch();
  testTryFinally();
  testTryFinally2();
  testFunctionExpression();
  testFunctionExpression2();
  testFunctionDeclaration();
  testFunctionDeclaration2();
}

void testAssertStatement() {
  assertStatementUnguarded1();
  assert(D1.guardedBool ? assertStatementGuarded1() : assertStatementGuarded2(),
      '${assertStatementGuarded3()}');
  assertStatementGuarded4();
}

dynamic assertStatementUnguarded1() => opaque;
dynamic assertStatementGuarded1() => opaque;
dynamic assertStatementGuarded2() => opaque;
dynamic assertStatementGuarded3() => opaque;
dynamic assertStatementGuarded4() => opaque;

void testAssertStatement2() {
  assertStatement2Unguarded1();
  assert(unguardedBool ? D1.guardedFun() : assertStatement2Unguarded2(),
      '${assertStatement2Unguarded3()}');
  assertStatement2Unguarded4();
}

dynamic assertStatement2Unguarded1() => opaque;
dynamic assertStatement2Unguarded2() => opaque;
dynamic assertStatement2Unguarded3() => opaque;
dynamic assertStatement2Unguarded4() => opaque;

void testConditional() {
  conditionalUnguarded1();
  if (unguardedBool) {
    print(D1.guardedBool || conditionalGuarded1());
  }
  conditionalUnguarded2();
  if (unguardedBool) {
    print(D1.guardedBool && conditionalGuarded2());
  }
  if (unguardedBool) {
    print(unguardedBool ? D1.guardedBool : D1.guardedBool);
    // NOTE: With more sophisticated implementation we could defer the following
    // as well.
    conditionalUnguarded3();
  }
  conditionalUnguarded4();
}

dynamic conditionalGuarded1() => opaque;
dynamic conditionalGuarded2() => opaque;
dynamic conditionalGuarded3() => opaque;
dynamic conditionalGuarded4() => opaque;
dynamic conditionalGuarded5() => opaque;
dynamic conditionalGuarded6() => opaque;
dynamic conditionalUnguarded1() => opaque;
dynamic conditionalUnguarded2() => opaque;
dynamic conditionalUnguarded3() => opaque;
dynamic conditionalUnguarded4() => opaque;

void testIfElse() {
  if (D1.guardedBool || unguardedBool) {
    ifElseGuarded1();
  } else {
    ifElseGuarded2();
  }
  ifElseGuarded3();
}

dynamic ifElseGuarded1() => opaque;
dynamic ifElseGuarded2() => opaque;
dynamic ifElseGuarded3() => opaque;

void testIfElse2() {
  if (unguardedBool || D1.guardedBool) {
    ifElse2Unguarded1();
  } else {
    ifElse2Unguarded2();
  }
  ifElse2Unguarded3();
}

dynamic ifElse2Unguarded1() => opaque;
dynamic ifElse2Unguarded2() => opaque;
dynamic ifElse2Unguarded3() => opaque;

void testIfElse3() {
  if (unguardedBool && D1.guardedBool) {
    ifElse3Unguarded1();
  } else {
    ifElse3Unguarded2();
  }
  ifElse3Unguarded3();
}

dynamic ifElse3Unguarded1() => opaque;
dynamic ifElse3Unguarded2() => opaque;
dynamic ifElse3Unguarded3() => opaque;

void testIfElse4() {
  if (unguardedBool) {
    D1.guardedFun();
    ifElse4Guarded1();
  } else {
    ifElse4Unguarded1();
  }
  ifElse4Unguarded2();
}

dynamic ifElse4Guarded1() => opaque;
dynamic ifElse4Unguarded1() => opaque;
dynamic ifElse4Unguarded2() => opaque;

void testBlock() {
  blockUnguarded1();
  D1.guardedFun();
  blockGuarded1();
}

dynamic blockUnguarded1() => opaque;
dynamic blockGuarded1() => opaque;

void testLabeledStatement() {
  label:
  {
    labeledStatementUnguarded1();
    D1.guardedFun();
    labeledStatementGuarded1();
    break label;
  }
  labeledStatementUnguarded2();
}

dynamic labeledStatementUnguarded1() => opaque;
dynamic labeledStatementGuarded1() => opaque;
dynamic labeledStatementUnguarded2() => opaque;

void testWhile() {
  while (D1.guardedBool) {
    whileGuarded1();
  }
  whileGuarded2();
}

dynamic whileGuarded1() => opaque;
dynamic whileGuarded2() => opaque;

void testWhile2() {
  while (unguardedBool) {
    while2Unguarded1();
    D1.guardedFun();
    while2Guarded1();
  }
  while2Unguarded2();
}

dynamic while2Unguarded1() => opaque;
dynamic while2Guarded1() => opaque;
dynamic while2Unguarded2() => opaque;

void testDoWhile() {
  do {
    D1.guardedFun();
    doWhileGuarded1();
  } while (false);
  doWhileGuarded2();
}

dynamic doWhileGuarded1() => opaque;
dynamic doWhileGuarded2() => opaque;

void testDoWhile2() {
  do {
    doWhile2Unguarded1();
    unguardedFun();
    doWhile2Unguarded2();
  } while (D1.guardedBool);
  doWhile2Guarded1();
}

dynamic doWhile2Unguarded1() => opaque;
dynamic doWhile2Unguarded2() => opaque;
dynamic doWhile2Guarded1() => opaque;

void testForIn() {
  forInUnguarded1();
  for (final x in D1.guardedBool ? [] : {}) {
    print(x);
    forInGuarded1();
  }
  forInGuarded2();
}

dynamic forInUnguarded1() => opaque;
dynamic forInGuarded1() => opaque;
dynamic forInGuarded2() => opaque;

void testForIn2() {
  for (final x in [1]) {
    forIn2Unguarded1();
    print(x);
    D1.guardedFun();
    forIn2Guarded1();
  }
  forIn2Unguarded2();
}

dynamic forIn2Unguarded1() => opaque;
dynamic forIn2Guarded1() => opaque;
dynamic forIn2Unguarded2() => opaque;

void testFor() {
  for (var a = forUnguarded1(), b = D1.guardedFun(), c = forGuarded1();
      b < 2;
      ++b) {
    forGuarded2();
    print(a);
    print(b);
    print(c);
  }
  forGuarded3();
}

dynamic forUnguarded1() => opaque;
dynamic forGuarded1() => opaque;
dynamic forGuarded2() => opaque;
dynamic forGuarded3() => opaque;

void testFor2() {
  for2Unguarded1();
  for (var x = 1; x < (D1.guardedBool ? for2Guarded1() : 2); ++x) {
    for2Guarded2();
    print(x);
  }
  for2Guarded3();
}

dynamic for2Unguarded1() => opaque;
dynamic for2Guarded1() => opaque;
dynamic for2Guarded2() => opaque;
dynamic for2Guarded3() => opaque;

void testFor3() {
  for (dynamic x = for3Unguarded1();
      x < for3Unguarded2();
      x += for3Guarded2()) {
    D1.guardedFun();
    for3Guarded1();
    print(x);
  }
  for3Unguarded4();
}

dynamic for3Unguarded1() => opaque;
dynamic for3Unguarded2() => opaque;
dynamic for3Guarded1() => opaque;
dynamic for3Guarded2() => opaque;
dynamic for3Unguarded4() => opaque;

void testSwitch() {
  switchUnguarded1();
  switch (unguardedBool ? 1 : 0) {
    case 0:
      D1.guardedFun();
      switchGuarded1();
      break;
    case 1:
      switchUnguarded2();
      break;
  }
  switchUnguarded3();
}

dynamic switchUnguarded1() => opaque;
dynamic switchGuarded1() => opaque;
dynamic switchUnguarded2() => opaque;
dynamic switchUnguarded3() => opaque;

void testSwitch2() {
  switch2Unguarded1();
  switch (D1.guardedBool ? 1 : 0) {
    case 0:
      switch2Guarded1();
      break;
    case 1:
      switch2Guarded2();
      break;
  }
  // CFE lowers breaks to [LabeledStatement]s which are outside the switch. It
  // will save&restore guards.
  //
  // We could also defer this with more sophisticated implementation.
  switch2Unguarded3();
}

dynamic switch2Unguarded1() => opaque;
dynamic switch2Guarded1() => opaque;
dynamic switch2Guarded2() => opaque;
dynamic switch2Unguarded3() => opaque;

void testTryCatch() {
  tryCatchUnguarded();
  try {
    tryCatchUnguarded2();
    D1.guardedFun();
    tryCatchGuarded1();
  } catch (e) {
    tryCatchUnguarded3();
    D1.guardedFun();
    tryCatchGuarded2();
  }
  tryCatchUnguarded4();
}

dynamic tryCatchUnguarded() => opaque;
dynamic tryCatchUnguarded2() => opaque;
dynamic tryCatchGuarded1() => opaque;
dynamic tryCatchUnguarded3() => opaque;
dynamic tryCatchGuarded2() => opaque;
dynamic tryCatchUnguarded4() => opaque;

void testTryFinally() {
  tryFinallyUnguarded1();
  try {
    tryFinallyUnguarded2();
    D1.guardedFun();
    tryFinallyGuarded1();
  } finally {
    tryFinallyUnguarded3();
  }
  tryFinallyUnguarded4();
}

dynamic tryFinallyUnguarded1() => opaque;
dynamic tryFinallyUnguarded2() => opaque;
dynamic tryFinallyGuarded1() => opaque;
dynamic tryFinallyUnguarded3() => opaque;
dynamic tryFinallyUnguarded4() => opaque;

void testTryFinally2() {
  tryFinally2Unguarded1();
  try {
    tryFinally2Unguarded2();
  } finally {
    D1.guardedFun();
    tryFinally2Guarded1();
  }
  tryFinally2Guarded2();
}

dynamic tryFinally2Unguarded1() => opaque;
dynamic tryFinally2Unguarded2() => opaque;
dynamic tryFinally2Guarded1() => opaque;
dynamic tryFinally2Guarded2() => opaque;

void testFunctionExpression() {
  functionExpressionUnguarded1();
  print(() {
    functionExpressionUnguarded2();
    D1.guardedFun();
    functionExpressionGuarded1();
  });
  functionExpressionUnguarded3();
}

dynamic functionExpressionUnguarded1() => opaque;
dynamic functionExpressionUnguarded2() => opaque;
dynamic functionExpressionUnguarded3() => opaque;
dynamic functionExpressionGuarded1() => opaque;

void testFunctionExpression2() {
  functionExpression2Unguarded1();
  D1.guardedFun();
  print(() {
    functionExpression2Guarded1();
  });
  functionExpression2Guarded2();
}

dynamic functionExpression2Unguarded1() => opaque;
dynamic functionExpression2Guarded1() => opaque;
dynamic functionExpression2Guarded2() => opaque;

void testFunctionDeclaration() {
  functionDeclarationUnguarded1();
  void foo() {
    functionDeclarationUnguarded2();
    D1.guardedFun();
    functionDeclarationGuarded1();
  }

  functionDeclarationUnguarded3();
  foo();
}

dynamic functionDeclarationUnguarded1() => opaque;
dynamic functionDeclarationUnguarded2() => opaque;
dynamic functionDeclarationUnguarded3() => opaque;
dynamic functionDeclarationGuarded1() => opaque;

void testFunctionDeclaration2() {
  functionDeclaration2Unguarded1();
  D1.guardedFun();
  void foo() {
    functionDeclaration2Guarded1();
  }

  functionDeclaration2Guarded2();
  foo();
}

dynamic functionDeclaration2Unguarded1() => opaque;
dynamic functionDeclaration2Guarded1() => opaque;
dynamic functionDeclaration2Guarded2() => opaque;

final bool unguardedBool = int.parse('1') == 1;
final bool guardedBool = int.parse('1') == 1;

dynamic unguardedFun() => opaque;
dynamic guardedFun() => opaque;

dynamic opaque = int.parse('1') == 1 ? 'a' : false;
