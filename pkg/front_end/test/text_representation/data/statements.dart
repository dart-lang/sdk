// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

/*member: stmtEmpty:
;*/
stmtEmpty() {
  ;
}

/*member: stmtExpression:
o;*/
stmtExpression(o) {
  o;
}

/*member: stmtEmptyBlock:
{}*/
stmtEmptyBlock(o) {
  {}
}

/*normal|verbose.member: stmtBlock:
{
  o;
}*/
/*limited.member: stmtBlock:
{ o; }*/
stmtBlock(o) {
  {
    o;
  }
}

/*member: stmtAssert:
assert(b);*/
stmtAssert(bool b) {
  assert(b);
}

/*member: stmtAssertMessage:
assert(b, m);*/
stmtAssertMessage(bool b, String m) {
  assert(b, m);
}

/*normal|verbose.member: stmtLabeledStatement:
label0:
break label0;*/
/*limited.member: stmtLabeledStatement:
label0: break label0;*/
stmtLabeledStatement() {
  label:
  break label;
}

/*member: stmtWhileTrue:
while (true) {}*/
stmtWhileTrue() {
  while (true) {}
}

/*normal|verbose.member: stmtWhileBreak:
label0:
while (b) break label0;*/
/*limited.member: stmtWhileBreak:
label0: while (b) break label0;*/
stmtWhileBreak(bool b) {
  while (b) break;
}

/*member: stmtWhileEmptyBlock:
while (b) {}*/
stmtWhileEmptyBlock(bool b) {
  while (b) {}
}

/*normal|verbose.member: stmtWhileBlockBreak:
label0:
while (b) {
  break label0;
}*/
/*limited.member: stmtWhileBlockBreak:
label0: while (b) { break label0; }*/
stmtWhileBlockBreak(bool b) {
  while (b) {
    break;
  }
}

/*member: stmtDoTrue:
do {} while (true);*/
stmtDoTrue() {
  do {} while (true);
}

/*normal|verbose.member: stmtDoBreak:
label0:
do {
  break label0;
} while (true);*/
/*limited.member: stmtDoBreak:
label0: do { break label0; } while (true);*/
stmtDoBreak() {
  do {
    break;
  } while (true);
}

/*member: stmtForEmpty:
for (; ; ) ;*/
stmtForEmpty() {
  for (;;);
}

/*normal.member: stmtFor:
for (int i = 0; i.{num.<}(list.{List.length}); i = i.{num.+}(1)) {
  list.{List.[]}(i);
}*/
/*verbose.member: stmtFor:
for (dart.core::int i = 0; i.{dart.core::num.<}(list.{dart.core::List.length}); i = i.{dart.core::num.+}(1)) {
  list.{dart.core::List.[]}(i);
}*/
/*limited.member: stmtFor:
for (int i = 0; i.{num.<}(list.{List.length}); i = i.{num.+}(1)) { list.{List.[]}(i); }*/
stmtFor(List list) {
  for (int i = 0; i < list.length; i++) {
    list[i];
  }
}

/*normal.member: stmtForMulti:
for (int i = 0, j = 0; i.{num.<}(list.{List.length}); i = i.{num.+}(1), j = j.{num.+}(1)) {
  list.{List.[]}(i);
}*/
/*verbose.member: stmtForMulti:
for (dart.core::int i = 0, j = 0; i.{dart.core::num.<}(list.{dart.core::List.length}); i = i.{dart.core::num.+}(1), j = j.{dart.core::num.+}(1)) {
  list.{dart.core::List.[]}(i);
}*/
/*limited.member: stmtForMulti:
for (int i = 0, j = 0; i.{num.<}(list.{List.length}); i = i.{num.+}(1), j = j.{num.+}(1)) { list.{List.[]}(i); }*/
stmtForMulti(List list) {
  for (int i = 0, j = 0; i < list.length; i++, j++) {
    list[i];
  }
}

/*member: stmtForInEmpty:
for (dynamic e in list) ;*/
stmtForInEmpty(List list) {
  for (var e in list);
}

/*member: stmtForInEmptyBlock:
for (dynamic e in list) {}*/
stmtForInEmptyBlock(List list) {
  for (var e in list) {}
}

/*normal|verbose.member: stmtForInBreak:
label0:
for (dynamic e in list) {
  break label0;
}*/
/*limited.member: stmtForInBreak:
label0: for (dynamic e in list) { break label0; }*/
stmtForInBreak(List list) {
  for (var e in list) {
    break;
  }
}

/*normal|verbose.member: stmtSwitch1:
label0:
switch (i) {
  case 0:
    break label0;
  case 1:
    continue "default:";
  case 2:
  case 3:
  default:
    return;
}*/
/*limited.member: stmtSwitch1:
label0: switch (i) { case 0: break label0; case 1: continue "default:"; case 2: case 3: default: return; }*/
stmtSwitch1(int i) {
  switch (i) {
    case 0:
      break;
    case 1:
      continue label2;
    label2:
    case 2:
    case 3:
    default:
      return;
  }
}

/*normal|verbose.member: stmtSwitch2:
label0:
switch (i) {
  case 0:
  case 1:
    break label0;
  case 2:
  case 3:
    {
      continue "case 0:";
    }
  default:
    return;
}*/
/*limited.member: stmtSwitch2:
label0: switch (i) { case 0: case 1: break label0; case 2: case 3: { continue "case 0:"; } default: return; }*/
stmtSwitch2(int i) {
  switch (i) {
    label0:
    case 0:
    case 1:
      break;
    case 2:
    case 3:
      {
        continue label0;
      }
    default:
      return;
  }
}

/*normal|verbose.member: stmtSwitch3:
label0:
switch (i) {
  default:
    break label0;
}*/
/*limited.member: stmtSwitch3:
label0: switch (i) { default: break label0; }*/
stmtSwitch3(int i) {
  switch (i) {
    default:
      break;
  }
}

/*member: stmtIf:
if (b) return;*/
stmtIf(bool b) {
  if (b) return;
}

/*normal|verbose.member: stmtIfBlock:
if (b) {
  return;
}*/
/*limited.member: stmtIfBlock:
if (b) { return; }*/
stmtIfBlock(bool b) {
  if (b) {
    return;
  }
}

/*member: stmtIfThen:
if (b) return 0; else return 1;*/
stmtIfThen(bool b) {
  if (b)
    return 0;
  else
    return 1;
}

/*normal|verbose.member: stmtIfThenBlock:
if (b) {
  return 0;
} else {
  return 1;
}*/
/*limited.member: stmtIfThenBlock:
if (b) { return 0; } else { return 1; }*/
stmtIfThenBlock(bool b) {
  if (b) {
    return 0;
  } else {
    return 1;
  }
}

/*member: stmtReturn:
return;*/
stmtReturn() {
  return;
}

/*member: stmtReturnExpression:
return 1;*/
stmtReturnExpression() {
  return 1;
}

/*member: stmtTryCatchExceptionEmpty:
try {} catch (e) {}*/
stmtTryCatchExceptionEmpty() {
  try {} catch (e) {}
}

/*normal|limited.member: stmtTryCatchExplicitOnEmpty:
try {} on Object {}*/
/*verbose.member: stmtTryCatchExplicitOnEmpty:
try {} on dart.core::Object {}*/
stmtTryCatchExplicitOnEmpty() {
  try {} on Object {}
}

/*member: stmtTryCatchExplicitOnExceptionEmpty:
try {} catch (e) {}*/
stmtTryCatchExplicitOnExceptionEmpty() {
  try {} on Object catch (e) {}
}

/*normal|verbose.member: stmtTryCatchException:
try {
  return;
} catch (e) {
  return;
}*/
/*limited.member: stmtTryCatchException:
try { return; } catch (e) { return; }*/
stmtTryCatchException() {
  try {
    return;
  } catch (e) {
    return;
  }
}

/*normal|verbose.member: stmtTryCatchExceptionStackTrace:
try {
  return;
} catch (e, s) {
  return;
}*/
/*limited.member: stmtTryCatchExceptionStackTrace:
try { return; } catch (e, s) { return; }*/
stmtTryCatchExceptionStackTrace() {
  try {
    return;
  } catch (e, s) {
    return;
  }
}

/*normal.member: stmtTryCatchOnEmpty:
try {
  return;
} on String {
  return;
}*/
/*verbose.member: stmtTryCatchOnEmpty:
try {
  return;
} on dart.core::String {
  return;
}*/
/*limited.member: stmtTryCatchOnEmpty:
try { return; } on String { return; }*/
stmtTryCatchOnEmpty() {
  try {
    return;
  } on String {
    return;
  }
}

/*normal.member: stmtTryCatchOnException:
try {
  return;
} on String catch (e) {
  return;
}*/
/*verbose.member: stmtTryCatchOnException:
try {
  return;
} on dart.core::String catch (e) {
  return;
}*/
/*limited.member: stmtTryCatchOnException:
try { return; } on String catch (e) { return; }*/
stmtTryCatchOnException() {
  try {
    return;
  } on String catch (e) {
    return;
  }
}

/*normal.member: stmtTryCatchOnExceptionStackTrace:
try {
  return;
} on String catch (e, s) {
  return;
}*/
/*verbose.member: stmtTryCatchOnExceptionStackTrace:
try {
  return;
} on dart.core::String catch (e, s) {
  return;
}*/
/*limited.member: stmtTryCatchOnExceptionStackTrace:
try { return; } on String catch (e, s) { return; }*/
stmtTryCatchOnExceptionStackTrace() {
  try {
    return;
  } on String catch (e, s) {
    return;
  }
}

/*normal.member: stmtTryCatchOnMultiple:
try {
  return;
} on int catch (e) {
  return;
} on String catch (e, s) {
  return;
} catch (e) {
  return;
}*/
/*verbose.member: stmtTryCatchOnMultiple:
try {
  return;
} on dart.core::int catch (e) {
  return;
} on dart.core::String catch (e, s) {
  return;
} catch (e) {
  return;
}*/
/*limited.member: stmtTryCatchOnMultiple:
try { return; } on int catch (e) { return; } on String catch (e, s) { return; } catch (e) { return; }*/
stmtTryCatchOnMultiple() {
  try {
    return;
  } on int catch (e) {
    return;
  } on String catch (e, s) {
    return;
  } catch (e) {
    return;
  }
}

/*member: stmtTryFinallyEmpty:
try {} finally {}*/
stmtTryFinallyEmpty() {
  try {} finally {}
}

/*normal|verbose.member: stmtTryFinally:
try {
  return;
} finally {
  return;
}*/
/*limited.member: stmtTryFinally:
try { return; } finally { return; }*/
stmtTryFinally() {
  try {
    return;
  } finally {
    return;
  }
}

/*normal|verbose.member: stmtTryCatchFinally:
try {
  return;
} catch (e) {
  return;
} finally {
  return;
}*/
/*limited.member: stmtTryCatchFinally:
try { return; } catch (e) { return; } finally { return; }*/
stmtTryCatchFinally() {
  try {
    return;
  } catch (e) {
    return;
  } finally {
    return;
  }
}

/*normal|verbose.member: stmtTryCatchFinallyNested:
try {
  try {
    return;
  } catch (e) {
    return;
  }
} finally {
  return;
}*/
/*limited.member: stmtTryCatchFinallyNested:
try { try { return; } catch (e) { return; } } finally { return; }*/
stmtTryCatchFinallyNested() {
  try {
    try {
      return;
    } catch (e) {
      return;
    }
  } finally {
    return;
  }
}

/*member: stmtYield:
yield 0;*/
stmtYield() sync* {
  yield 0;
}

/*normal|limited.member: stmtYieldStar:
yield* <int>[0];*/
/*verbose.member: stmtYieldStar:
yield* <dart.core::int>[0];*/
stmtYieldStar() sync* {
  yield* [0];
}

/*member: stmtVariableDeclaration:
dynamic o;*/
stmtVariableDeclaration() {
  var o;
}

/*normal|limited.member: stmtVariableDeclarationInitializer:
int o = 42;*/
/*verbose.member: stmtVariableDeclarationInitializer:
dart.core::int o = 42;*/
stmtVariableDeclarationInitializer() {
  var o = 42;
}

/*normal|limited.member: stmtVariableDeclarationFinal:
final int o = 42;*/
/*verbose.member: stmtVariableDeclarationFinal:
final dart.core::int o = 42;*/
stmtVariableDeclarationFinal() {
  final o = 42;
}

/*normal|limited.member: stmtVariableDeclarationLate:
late int i = 42;*/
/*verbose.member: stmtVariableDeclarationLate:
late dart.core::int i = 42;*/
stmtVariableDeclarationLate() {
  late int i = 42;
}

/*normal.member: stmtVariableDeclarations:
{
  int i;
  int j = 42;
}*/
/*verbose.member: stmtVariableDeclarations:
{
  dart.core::int i;
  dart.core::int j = 42;
}*/
/*limited.member: stmtVariableDeclarations:
{ int i; int j = 42; }*/
stmtVariableDeclarations() {
  {
    int i, j = 42;
  }
}

/*normal|limited.member: stmtFunctionDeclarationPositional:
int localFunction(dynamic a, [dynamic b = 0]) => 0;*/
/*verbose.member: stmtFunctionDeclarationPositional:
dart.core::int localFunction(dynamic a, [dynamic b = 0]) => 0;*/
stmtFunctionDeclarationPositional() {
  int localFunction(a, [b = 0]) => 0;
}

/*normal.member: stmtFunctionDeclarationNamed:
int localFunction(dynamic a, {dynamic b = 0, required dynamic c}) {
  return 0;
}*/
/*verbose.member: stmtFunctionDeclarationNamed:
dart.core::int localFunction(dynamic a, {dynamic b = 0, required dynamic c}) {
  return 0;
}*/
/*limited.member: stmtFunctionDeclarationNamed:
int localFunction(dynamic a, {dynamic b = 0, required dynamic c}) { return 0; }*/
stmtFunctionDeclarationNamed() {
  int localFunction(a, {b: 0, required c}) {
    return 0;
  }
}

/*normal|limited.member: stmtFunctionDeclarationGeneric:
T% localFunction<T extends Object?, S extends num>(T% t, dynamic S) => t;*/
/*verbose.member: stmtFunctionDeclarationGeneric:
T% localFunction<T extends dart.core::Object?, S extends dart.core::num>(T% t, dynamic S) => t;*/
stmtFunctionDeclarationGeneric() {
  T localFunction<T, S extends num>(T t, S) => t;
}

/*normal|verbose.member: stmtNestedDeep:
{
  1;
  {
    2;
    {
      3;
      {
        4;
      }
    }
  }
}*/
/*limited.member: stmtNestedDeep:
{ 1; { 2; { 3; { 4; } } } }*/
stmtNestedDeep() {
  {
    1;
    {
      2;
      {
        3;
        {
          4;
        }
      }
    }
  }
}

/*normal|verbose.member: stmtNestedTooDeep:
{
  1;
  {
    2;
    {
      3;
      {
        4;
        {
          5;
          {
            6;
          }
        }
      }
    }
  }
}*/
/*limited.member: stmtNestedTooDeep:
{ 1; { 2; { 3; { 4; { ... } } } } }*/
stmtNestedTooDeep() {
  {
    1;
    {
      2;
      {
        3;
        {
          4;
          {
            5;
            {
              6;
            }
          }
        }
      }
    }
  }
}

/*normal|verbose.member: stmtManySiblings:
{
  1;
  2;
  3;
  4;
}*/
/*limited.member: stmtManySiblings:
{ 1; 2; 3; 4; }*/
stmtManySiblings() {
  {
    1;
    2;
    3;
    4;
  }
}

/*normal|verbose.member: stmtTooManySiblings:
{
  1;
  2;
  3;
  4;
  5;
}*/
/*limited.member: stmtTooManySiblings:
{ ... }*/
stmtTooManySiblings() {
  {
    1;
    2;
    3;
    4;
    5;
  }
}
