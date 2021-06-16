// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var b = true;

@pragma("vm:never-inline")
void checkSymbol(String string) {
  // Just check that it can be created.
  new Symbol(string);
  // Prevent inlining.
  try {} finally {}
}

main() {
  var x;

  // 'void' is allowed as a symbol name.
  x = const Symbol('void');
  x = #void;
  x = new Symbol('void');

  // 'void' can be part of a dotted symbol name, via the constructor.
  checkSymbol('void.foo');
  checkSymbol('foo.void');

  // Reserved words are allowed, via the constructor.
  checkSymbol('assert');
  checkSymbol('break');
  checkSymbol('case');
  checkSymbol('catch');
  checkSymbol('class');
  checkSymbol('const');
  checkSymbol('continue');
  checkSymbol('default');
  checkSymbol('do');
  checkSymbol('else');
  checkSymbol('enum');
  checkSymbol('extends');
  checkSymbol('false');
  checkSymbol('final');
  checkSymbol('finally');
  checkSymbol('for');
  checkSymbol('if');
  checkSymbol('in');
  checkSymbol('is');
  checkSymbol('new');
  checkSymbol('null');
  checkSymbol('rethrow');
  checkSymbol('return');
  checkSymbol('super');
  checkSymbol('switch');
  checkSymbol('this');
  checkSymbol('throw');
  checkSymbol('true');
  checkSymbol('try');
  checkSymbol('var');
  checkSymbol('while');
  checkSymbol('with');

  // Reserved words can also be part of a dot separated list, via constructor.
  checkSymbol('foo.assert');
  checkSymbol('foo.break');
  checkSymbol('foo.case');
  checkSymbol('foo.catch');
  checkSymbol('foo.class');
  checkSymbol('foo.const');
  checkSymbol('foo.continue');
  checkSymbol('foo.default');
  checkSymbol('foo.do');
  checkSymbol('foo.else');
  checkSymbol('foo.enum');
  checkSymbol('foo.extends');
  checkSymbol('foo.false');
  checkSymbol('foo.final');
  checkSymbol('foo.finally');
  checkSymbol('foo.for');
  checkSymbol('foo.if');
  checkSymbol('foo.in');
  checkSymbol('foo.is');
  checkSymbol('foo.new');
  checkSymbol('foo.null');
  checkSymbol('foo.rethrow');
  checkSymbol('foo.return');
  checkSymbol('foo.super');
  checkSymbol('foo.switch');
  checkSymbol('foo.this');
  checkSymbol('foo.throw');
  checkSymbol('foo.true');
  checkSymbol('foo.try');
  checkSymbol('foo.var');
  checkSymbol('foo.while');
  checkSymbol('foo.with');
  checkSymbol('assert.foo');
  checkSymbol('break.foo');
  checkSymbol('case.foo');
  checkSymbol('catch.foo');
  checkSymbol('class.foo');
  checkSymbol('const.foo');
  checkSymbol('continue.foo');
  checkSymbol('default.foo');
  checkSymbol('do.foo');
  checkSymbol('else.foo');
  checkSymbol('enum.foo');
  checkSymbol('extends.foo');
  checkSymbol('false.foo');
  checkSymbol('final.foo');
  checkSymbol('finally.foo');
  checkSymbol('for.foo');
  checkSymbol('if.foo');
  checkSymbol('in.foo');
  checkSymbol('is.foo');
  checkSymbol('new.foo');
  checkSymbol('null.foo');
  checkSymbol('rethrow.foo');
  checkSymbol('return.foo');
  checkSymbol('super.foo');
  checkSymbol('switch.foo');
  checkSymbol('this.foo');
  checkSymbol('throw.foo');
  checkSymbol('true.foo');
  checkSymbol('try.foo');
  checkSymbol('var.foo');
  checkSymbol('while.foo');
  checkSymbol('with.foo');

  // A constant symbol with a reserved word is allowed, via constructor.
  x = const Symbol('void.foo');
  x = const Symbol('foo.void');
  x = const Symbol('assert');
  x = const Symbol('break');
  x = const Symbol('case');
  x = const Symbol('catch');
  x = const Symbol('class');
  x = const Symbol('const');
  x = const Symbol('continue');
  x = const Symbol('default');
  x = const Symbol('do');
  x = const Symbol('else');
  x = const Symbol('enum');
  x = const Symbol('extends');
  x = const Symbol('false');
  x = const Symbol('final');
  x = const Symbol('finally');
  x = const Symbol('for');
  x = const Symbol('if');
  x = const Symbol('in');
  x = const Symbol('is');
  x = const Symbol('new');
  x = const Symbol('null');
  x = const Symbol('rethrow');
  x = const Symbol('return');
  x = const Symbol('super');
  x = const Symbol('switch');
  x = const Symbol('this');
  x = const Symbol('throw');
  x = const Symbol('true');
  x = const Symbol('try');
  x = const Symbol('var');
  x = const Symbol('while');
  x = const Symbol('with');
  x = const Symbol('foo.assert');
  x = const Symbol('foo.break');
  x = const Symbol('foo.case');
  x = const Symbol('foo.catch');
  x = const Symbol('foo.class');
  x = const Symbol('foo.const');
  x = const Symbol('foo.continue');
  x = const Symbol('foo.default');
  x = const Symbol('foo.do');
  x = const Symbol('foo.else');
  x = const Symbol('foo.enum');
  x = const Symbol('foo.extends');
  x = const Symbol('foo.false');
  x = const Symbol('foo.final');
  x = const Symbol('foo.finally');
  x = const Symbol('foo.for');
  x = const Symbol('foo.if');
  x = const Symbol('foo.in');
  x = const Symbol('foo.is');
  x = const Symbol('foo.new');
  x = const Symbol('foo.null');
  x = const Symbol('foo.rethrow');
  x = const Symbol('foo.return');
  x = const Symbol('foo.super');
  x = const Symbol('foo.switch');
  x = const Symbol('foo.this');
  x = const Symbol('foo.throw');
  x = const Symbol('foo.true');
  x = const Symbol('foo.try');
  x = const Symbol('foo.var');
  x = const Symbol('foo.while');
  x = const Symbol('foo.with');
  x = const Symbol('assert.foo');
  x = const Symbol('break.foo');
  x = const Symbol('case.foo');
  x = const Symbol('catch.foo');
  x = const Symbol('class.foo');
  x = const Symbol('const.foo');
  x = const Symbol('continue.foo');
  x = const Symbol('default.foo');
  x = const Symbol('do.foo');
  x = const Symbol('else.foo');
  x = const Symbol('enum.foo');
  x = const Symbol('extends.foo');
  x = const Symbol('false.foo');
  x = const Symbol('final.foo');
  x = const Symbol('finally.foo');
  x = const Symbol('for.foo');
  x = const Symbol('if.foo');
  x = const Symbol('in.foo');
  x = const Symbol('is.foo');
  x = const Symbol('new.foo');
  x = const Symbol('null.foo');
  x = const Symbol('rethrow.foo');
  x = const Symbol('return.foo');
  x = const Symbol('super.foo');
  x = const Symbol('switch.foo');
  x = const Symbol('this.foo');
  x = const Symbol('throw.foo');
  x = const Symbol('true.foo');
  x = const Symbol('try.foo');
  x = const Symbol('var.foo');
  x = const Symbol('while.foo');
  x = const Symbol('with.foo');
}
