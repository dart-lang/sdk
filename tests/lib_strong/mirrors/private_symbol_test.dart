// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'dart:mirrors';
import 'package:expect/expect.dart';

typedef int _F(int i);

class _C<_T> {
  get g {}
  set s(x) {}
  m(_p) {}
  get _g {}
  set _s(x) {}
  _m() {}
}

main() {
  // Test private symbols are distinct across libraries, and the same within a
  // library when created multiple ways. Test the string can be properly
  // extracted.
  LibraryMirror libcore = currentMirrorSystem().findLibrary(#dart.core);
  LibraryMirror libmath = currentMirrorSystem().findLibrary(#dart.math);
  LibraryMirror libtest = currentMirrorSystem().findLibrary(#test);

  Symbol corefoo = MirrorSystem.getSymbol('foo', libcore);
  Symbol mathfoo = MirrorSystem.getSymbol('foo', libmath);
  Symbol testfoo = MirrorSystem.getSymbol('foo', libtest);
  Symbol nullfoo1 = MirrorSystem.getSymbol('foo');
  Symbol nullfoo2 = MirrorSystem.getSymbol('foo', null);

  Expect.equals(corefoo, mathfoo);
  Expect.equals(mathfoo, testfoo);
  Expect.equals(testfoo, corefoo);
  Expect.equals(nullfoo1, corefoo);
  Expect.equals(nullfoo2, corefoo);

  Expect.equals('foo', MirrorSystem.getName(corefoo));
  Expect.equals('foo', MirrorSystem.getName(mathfoo));
  Expect.equals('foo', MirrorSystem.getName(testfoo));
  Expect.equals('foo', MirrorSystem.getName(#foo));
  Expect.equals('foo', MirrorSystem.getName(nullfoo1));
  Expect.equals('foo', MirrorSystem.getName(nullfoo2));

  Symbol core_foo = MirrorSystem.getSymbol('_foo', libcore);
  Symbol math_foo = MirrorSystem.getSymbol('_foo', libmath);
  Symbol test_foo = MirrorSystem.getSymbol('_foo', libtest);

  Expect.equals('_foo', MirrorSystem.getName(core_foo));
  Expect.equals('_foo', MirrorSystem.getName(math_foo));
  Expect.equals('_foo', MirrorSystem.getName(test_foo));
  Expect.equals('_foo', MirrorSystem.getName(#_foo));

  Expect.notEquals(core_foo, math_foo);
  Expect.notEquals(math_foo, test_foo);
  Expect.notEquals(test_foo, core_foo);

  Expect.notEquals(corefoo, core_foo);
  Expect.notEquals(mathfoo, math_foo);
  Expect.notEquals(testfoo, test_foo);

  Expect.equals(test_foo, #_foo);

  // Test interactions with the manglings for getters and setters, etc.
  ClassMirror cm = reflectClass(_C);
  Expect.equals(#_C, cm.simpleName);
  Expect.equals('_C', MirrorSystem.getName(cm.simpleName));

  MethodMirror mm = cm.declarations[#g];
  Expect.isNotNull(mm);
  Expect.isTrue(mm.isGetter);
  Expect.equals(#g, mm.simpleName);
  Expect.equals('g', MirrorSystem.getName(mm.simpleName));

  mm = cm.declarations[const Symbol('s=')];
  Expect.isNotNull(mm);
  Expect.isTrue(mm.isSetter);
  Expect.equals(const Symbol('s='), mm.simpleName);
  Expect.equals('s=', MirrorSystem.getName(mm.simpleName));

  mm = cm.declarations[#m];
  Expect.isNotNull(mm);
  Expect.isTrue(mm.isRegularMethod);
  Expect.equals(#m, mm.simpleName);
  Expect.equals('m', MirrorSystem.getName(mm.simpleName));

  mm = cm.declarations[#_g];
  Expect.isNotNull(mm);
  Expect.isTrue(mm.isGetter);
  Expect.equals(#_g, mm.simpleName);
  Expect.equals('_g', MirrorSystem.getName(mm.simpleName));

  mm = cm.declarations[MirrorSystem.getSymbol('_s=', libtest)];
  Expect.isNotNull(mm);
  Expect.isTrue(mm.isSetter);
  Expect.equals(MirrorSystem.getSymbol('_s=', libtest), mm.simpleName);
  Expect.equals('_s=', MirrorSystem.getName(mm.simpleName));

  mm = cm.declarations[#_m];
  Expect.isNotNull(mm);
  Expect.isTrue(mm.isRegularMethod);
  Expect.equals(#_m, mm.simpleName);
  Expect.equals('_m', MirrorSystem.getName(mm.simpleName));

  TypeVariableMirror tvm = cm.typeVariables[0];
  Expect.isNotNull(tvm);
  Expect.equals(#_T, tvm.simpleName);
  Expect.equals('_T', MirrorSystem.getName(tvm.simpleName));

  TypedefMirror tdm = reflectType(_F);
  Expect.equals(#_F, tdm.simpleName);
  Expect.equals('_F', MirrorSystem.getName(tdm.simpleName));

  ParameterMirror pm = (cm.declarations[#m] as MethodMirror).parameters[0];
  Expect.equals(#_p, pm.simpleName);
  Expect.equals('_p', MirrorSystem.getName(pm.simpleName));

  // Private symbol without a library.
  Expect.throws(
      () => MirrorSystem.getSymbol('_private'), (e) => e is ArgumentError);

  var notALibraryMirror = 7;
  Expect.throws(() => MirrorSystem.getSymbol('_private', notALibraryMirror),
      (e) => e is ArgumentError || e is TypeError);

  Expect.throws(() => MirrorSystem.getSymbol('public', notALibraryMirror),
      (e) => e is ArgumentError || e is TypeError);
}
