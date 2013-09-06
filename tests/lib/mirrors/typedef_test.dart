// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test is a multi-test with three positive tests. "01" pass on dart2js,
// "02" pass on the VM, and "none" is the correct behavior.
// The goal is to remove all "01" and "02" lines.

library test.typedef_test;

@MirrorsUsed(targets: 'test.typedef_test')
import 'dart:mirrors';

import 'package:expect/expect.dart';

typedef Func();
typedef void Void();
typedef String Foo(int x);
typedef String Bar(int x, [num y]);
typedef String Baz(int x, {num y});
typedef String Foo2(int x, num y);
typedef String Bar2(int x, [num y, num z]);
typedef String Baz2(int x, {num y, num z});

check(t) {
  var sb = new StringBuffer();
  writeln(o) {
    sb.write(o);
    sb.write('\n');
  }
  writeln(t);
  t = t.referent;
  writeln(t);
  writeln(t.returnType);
  writeln(t.parameters);
  for (var p in t.parameters) {
    writeln(p.simpleName);
    writeln(p.type);
  }

  return sb.toString();
}

// Return "$args -> $ret".
ft(args, ret) {
  return '$args -> $ret'
      // TODO(ahe): dart2js doesn't fully qualify type names.
      .replaceAll('dart.core.', '') /// 01: ok
      ;
}

void main() {
  String x = 'x';
  String y = 'y';
  String z = 'z';
  x = 'argument0'; /// 01: ok
  y = 'argument1'; /// 01: ok
  z = 'argument2'; /// 01: ok

  Expect.stringEquals(
      """
TypedefMirror on 'Func'
FunctionTypeMirror on '${ft('()', 'dynamic')}'
TypeMirror on 'dynamic'
[]
""",
      check(reflectClass(Func)));
  Expect.stringEquals(
      """
TypedefMirror on 'Void'
FunctionTypeMirror on '${ft('()', 'void')}'
TypeMirror on 'void'
[]
""",
      check(reflectClass(Void)));
  Expect.stringEquals(
      """
TypedefMirror on 'Foo'
FunctionTypeMirror on '${ft('(dart.core.int)', 'dart.core.String')}'
ClassMirror on 'String'
[ParameterMirror on '$x']
Symbol(\"$x\")
ClassMirror on 'int'
""",
      check(reflectClass(Foo)));
  String type = ft('(dart.core.int, dart.core.num)', 'dart.core.String');
  Expect.stringEquals(
      """
TypedefMirror on 'Foo2'
FunctionTypeMirror on '$type'
ClassMirror on 'String'
[ParameterMirror on '$x', ParameterMirror on '$y']
Symbol(\"$x\")
ClassMirror on 'int'
Symbol(\"$y\")
ClassMirror on 'num'
""",
      check(reflectClass(Foo2)));
  type = ft('(dart.core.int, [dart.core.num])', 'dart.core.String');
  Expect.stringEquals(
      """
TypedefMirror on 'Bar'
FunctionTypeMirror on '$type'
ClassMirror on 'String'
[ParameterMirror on '$x', ParameterMirror on '$y']
Symbol(\"$x\")
ClassMirror on 'int'
Symbol(\"$y\")
ClassMirror on 'num'
""",
      check(reflectClass(Bar)));
  type = ft('(dart.core.int, [dart.core.num, dart.core.num])',
            'dart.core.String');
  Expect.stringEquals(
      """
TypedefMirror on 'Bar2'
FunctionTypeMirror on '$type'
ClassMirror on 'String'
[ParameterMirror on '$x', ParameterMirror on '$y', ParameterMirror on '$z']
Symbol(\"$x\")
ClassMirror on 'int'
Symbol(\"$y\")
ClassMirror on 'num'
Symbol(\"$z\")
ClassMirror on 'num'
""",
      check(reflectClass(Bar2)));
  type = ft('(dart.core.int, {y: dart.core.num})', 'dart.core.String');
  Expect.stringEquals(
      """
TypedefMirror on 'Baz'
FunctionTypeMirror on '$type'
ClassMirror on 'String'
[ParameterMirror on '$x', ParameterMirror on 'y']
Symbol(\"$x\")
ClassMirror on 'int'
Symbol(\"y\")
ClassMirror on 'num'
""",
      check(reflectClass(Baz)));
  type = ft('(dart.core.int, {y: dart.core.num, z: dart.core.num})',
            'dart.core.String');
  Expect.stringEquals(
      """
TypedefMirror on 'Baz2'
FunctionTypeMirror on '$type'
ClassMirror on 'String'
[ParameterMirror on '$x', ParameterMirror on 'y', ParameterMirror on 'z']
Symbol(\"$x\")
ClassMirror on 'int'
Symbol(\"y\")
ClassMirror on 'num'
Symbol(\"z\")
ClassMirror on 'num'
""",
      check(reflectClass(Baz2)));
}
