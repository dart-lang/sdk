// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../dart2js_native/compiler_test_internals.dart';
import 'package:expect/expect.dart';

// The function ast01 is built by an SsaFromAstBuilder.
// Ir functions are inlined by an SsaFromIrInliner.

@NoInline()
@IrRepresentation(false)
ast01() {
  checkAst01(JS('', 'arguments.callee'));
  print(ir01());
  print(ir02());
  return ast02(11);
}

@IrRepresentation(true)
ir01() => ir04();

@IrRepresentation(true)
ir02() => ast06(10, 20);

@IrRepresentation(false)
ast06(a,b) {
  JS('', 'String("in ast06")');
  return 3*a + b;
}

@IrRepresentation(true)
ir04() => ir05();

@IrRepresentation(true)
ir05() => ast07(1, 22);

@IrRepresentation(false)
ast07(i, j) {
  var x = 0;
  return ast08(i,j) ? i : j;
}

@IrRepresentation(false)
ast08(x,y) {
  JS('', 'String("in ast08")');
  return x - y < 0;
}

@IrRepresentation(false)
ast02(x) {
  print(x);
  ir06();
  print(ir07());
}

@IrRepresentation(true)
ir06() => ast04(1,2,3);

@IrRepresentation(false)
ast04(a, b, c) {
  print(a + b - c);
  JS('', 'String("in ast04")');
}

@IrRepresentation(true)
ir07() => ir03();

@IrRepresentation(true)
ir03() => ast05(1,3);

@IrRepresentation(false)
ast05(a, b) {
  JS('', 'String("in ast05")');
  return (a+b)/2;
}

// The function ir08 is built by an SsaFromIrBuilder.
// Ast functions are inlined by an SsaFromAstInliner.

@NoInline()
@IrRepresentation(true)
ir08() => ir09();

ir09() => ast09();

ast09() {
  checkIr08(JS('', 'arguments.callee'));
  JS('', 'String("in ast09")');
  print(ir01());
  print(ir02());
  print(ast02(11));
}

main() {
  ast01();
  ir08();
}

@NoInline()
check(func, names) {
  var source = JS('String', 'String(#)', func);
  print(source);
  for (var f in names) {
    Expect.isTrue(source.contains('"in $f"'), "should inline '$f'");
  }
}

@NoInline
checkAst01(func) {
  var names = ["ast04", "ast05", "ast06", "ast08"];
  check(func, names);
}

checkIr08(func) {
  var names = ["ast09", "ast04", "ast05", "ast06", "ast08"];
  check(func, names);
}
