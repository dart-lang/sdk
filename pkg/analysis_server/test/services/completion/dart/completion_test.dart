// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../client/completion_driver_test.dart';

// TODO(brianwilkerson) The contents of this file were generated from an older
//  style of tests. They need to be cleaned up (many contain test code that
//  isn't used in the test), renamed, and moved into the appropriate 'location'
//  or 'declaration' test class.
void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertedTest1);
    defineReflectiveTests(ConvertedTest2);
  });
}

@reflectiveTest
class ConvertedTest1 extends AbstractCompletionDriverTest
    with ConvertedTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ConvertedTest2 extends AbstractCompletionDriverTest
    with ConvertedTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ConvertedTestCases on AbstractCompletionDriverTest {
  Future<void> test_001_1() async {
    allowedIdentifiers = {'toString', '=='};
    await computeSuggestions('''
void r1(var v) {
  v.^toString().hashCode
}
''');
    assertResponse(r'''
replacement
  right: 8
suggestions
  toString
    kind: methodInvocation
''');
  }

  Future<void> test_001_2() async {
    allowedIdentifiers = {'toString'};
    await computeSuggestions('''
void r1(var v) {
  v.toString^().hashCode
}
''');
    assertResponse(r'''
replacement
  left: 8
suggestions
  toString
    kind: methodInvocation
''');
  }

  Future<void> test_001_3() async {
    allowedIdentifiers = {'hashCode', 'toString'};
    await computeSuggestions('''
void r1(var v) {
  v.toString().^hashCode
}
''');
    assertResponse(r'''
replacement
  right: 8
suggestions
  hashCode
    kind: getter
  toString
    kind: methodInvocation
''');
  }

  Future<void> test_001_4() async {
    allowedIdentifiers = {'hashCode', 'toString'};
    await computeSuggestions('''
void r1(var v) {
  v.toString().hash^Code
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 4
  right: 4
suggestions
  hashCode
    kind: getter
''');
    } else {
      assertResponse(r'''
replacement
  left: 4
  right: 4
suggestions
  hashCode
    kind: getter
  toString
    kind: methodInvocation
''');
    }
  }

  Future<void> test_002_1() async {
    allowedIdentifiers = {'vim'};
    await computeSuggestions('''
void r2(var vim) {
  v^.toString()
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  var
    kind: keyword
  vim
    kind: parameter
  void
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  r2
    kind: functionInvocation
  return
    kind: keyword
  switch
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  vim
    kind: parameter
  void
    kind: keyword
  while
    kind: keyword
''');
    }
  }

  Future<void> test_003_1() async {
    allowedIdentifiers = {'a'};
    await computeSuggestions('''
class A {
  int a() => 3;
  int b() => this.^a();
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  a
    kind: methodInvocation
''');
  }

  @failingTest
  Future<void> test_004_1() async {
    allowedIdentifiers = {'x'};
    await computeSuggestions('''
class A {
  int x;
  A() : this.^x = 1;
  A.b() : this();
  A.c() : this.b();
  g() => new A.c();
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  assert
    kind: keyword
  x
    kind: localVariable
''');
  }

  @failingTest
  Future<void> test_004_2() async {
    allowedIdentifiers = {'b'};
    await computeSuggestions('''
class A {
  int x;
  A() : this.x = 1;
  A.b() : this();
  A.c() : this.^b();
  g() => new A.c();
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  assert
    kind: keyword
  b
    kind: constructorInvocation
''');
  }

  Future<void> test_004_3() async {
    allowedIdentifiers = {'c'};
    await computeSuggestions('''
class A {
  int x;
  A() : this.x = 1;
  A.b() : this();
  A.c() : this.b();
  g() => new A.^c();
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  c
    kind: constructorInvocation
''');
  }

  Future<void> test_005_1() async {
    allowedIdentifiers = {
      'vq',
      'A',
      'vim',
      'vf',
      'this',
      'void',
      'null',
      'false'
    };
    await computeSuggestions('''
class A {}
void rr(var vim) {
  var ^vq = v.toString();
  var vf;
  v.toString();
}
''');
    assertResponse(r'''
replacement
  right: 2
suggestions
''');
  }

  Future<void> test_005_2() async {
    allowedIdentifiers = {
      'vim',
      'A',
      'vf',
      'vq',
      'this',
      'void',
      'null',
      'false'
    };
    await computeSuggestions('''
class A {}
void rr(var vim) {
  var vq = v^.toString();
  var vf;
  v.toString();
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  vim
    kind: parameter
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  A
    kind: class
  A
    kind: constructorInvocation
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
  vim
    kind: parameter
''');
    }
  }

  Future<void> test_005_3() async {
    allowedIdentifiers = {'vf', 'vq', 'vim', 'A'};
    await computeSuggestions('''
class A {}
void rr(var vim) {
  var vq = v.toString();
  var vf;
  v^.toString();
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  var
    kind: keyword
  vf
    kind: localVariable
  vim
    kind: parameter
  void
    kind: keyword
  vq
    kind: localVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  A
    kind: class
  A
    kind: constructorInvocation
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  vf
    kind: localVariable
  vim
    kind: parameter
  void
    kind: keyword
  vq
    kind: localVariable
  while
    kind: keyword
''');
    }
  }

  Future<void> test_006_1() async {
    allowedIdentifiers = {'va', 'b'};
    await computeSuggestions('''
void r2(var vim, {va: 2, b: 3}) {
  v^.toString()
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  va
    kind: parameter
  var
    kind: keyword
  void
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  assert
    kind: keyword
  b
    kind: parameter
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  r2
    kind: functionInvocation
  return
    kind: keyword
  switch
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  va
    kind: parameter
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
    }
  }

  Future<void> test_007_1() async {
    allowedIdentifiers = {'va', 'b'};
    await computeSuggestions('''
void r2(var vim, [va: 2, b: 3]) {
  v^.toString()
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  va
    kind: parameter
  var
    kind: keyword
  void
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  assert
    kind: keyword
  b
    kind: parameter
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  r2
    kind: functionInvocation
  return
    kind: keyword
  switch
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  va
    kind: parameter
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
    }
  }

  Future<void> test_008_1() async {
    await computeSuggestions('''
^class Aclass {}
class Bclass extends Aclass {}
abstract class Eclass implements Aclass, Bclass {}
class Fclass extends Bclass with  Eclass {}
''');
    assertResponse(r'''
replacement
  right: 5
suggestions
  class
    kind: keyword
''');
  }

  Future<void> test_008_2() async {
    await computeSuggestions('''
class Aclass {}
class Bclass ^extends Aclass {}
abstract class Eclass implements Aclass, Bclass {}
class Fclass extends Bclass with  Eclass {}
''');
    assertResponse(r'''
replacement
  right: 7
suggestions
  extends
    kind: keyword
  implements
    kind: keyword
  with
    kind: keyword
''');
  }

  Future<void> test_008_3() async {
    await computeSuggestions('''
class Aclass {}
class Bclass extends^ Aclass {}
abstract class Eclass implements Aclass, Bclass {}
class Fclass extends Bclass with  Eclass {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 7
suggestions
  extends
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 7
suggestions
  extends
    kind: keyword
  implements
    kind: keyword
  with
    kind: keyword
''');
    }
  }

  @FailingTest(reason: 'Bclass is being suggested, but it cannot extend itself')
  Future<void> test_008_4() async {
    allowedIdentifiers = {'Aclass', 'Bclass'};
    await computeSuggestions('''
class Aclass {}
class Bclass extends ^Aclass {}
abstract class Eclass implements Aclass, Bclass {}
class Fclass extends Bclass with  Eclass {}
''');
    assertResponse(r'''
replacement
  right: 6
suggestions
  Aclass
    kind: class
''');
  }

  Future<void> test_008_5() async {
    await computeSuggestions('''
class Aclass {}
class Bclass extends Aclass {}
^abstract class Eclass implements Aclass, Bclass {}
class Fclass extends Bclass with Eclass {}
''');
    assertResponse(r'''
replacement
  right: 8
suggestions
  abstract
    kind: keyword
  base
    kind: keyword
  final
    kind: keyword
  interface
    kind: keyword
  mixin
    kind: keyword
''');
  }

  Future<void> test_008_6() async {
    await computeSuggestions('''
class Aclass {}
class Bclass extends Aclass {}
abstract class Eclass implements Aclass, Bclass {}
class Fclass extends Bclass ^with  Eclass {}
''');
    assertResponse(r'''
replacement
  right: 4
suggestions
  implements
    kind: keyword
  with
    kind: keyword
''');
  }

  Future<void> test_008_7() async {
    allowedIdentifiers = {'Eclass', 'Dclass', 'Ctype'};
    await computeSuggestions('''
class Aclass {}
class Bclass extends Aclass {}
abstract class Eclass implements Aclass, Bclass {}
class Fclass extends Bclass with ^ Eclass {}
''');
    assertResponse(r'''
suggestions
  Eclass
    kind: class
''');
  }

  @failingTest
  Future<void> test_009_1() async {
    allowedIdentifiers = {'void', 'TestFn2'};
    await computeSuggestions('''
typedef ^dynamic TestFn1();
typedef void TestFn2();
typedef n
''');
    assertResponse(r'''
replacement
  right: 7
suggestions
  dynamic
    kind: keyword
  TestFn2
    kind: typeAlias
  void
    kind: keyword
''');
  }

  @failingTest
  Future<void> test_009_2() async {
    allowedIdentifiers = {'dynamic', 'void'};
    await computeSuggestions('''
typedef dy^namic TestFn1();
typedef void TestFn2();
typedef n
''');
    assertResponse(r'''
replacement
  left: 2
  right: 5
suggestions
  dynamic
    kind: keyword
  void
    kind: keyword
''');
  }

  @failingTest
  Future<void> test_009_3() async {
    allowedIdentifiers = {'dynamic'};
    await computeSuggestions('''
typedef dynamic TestFn1();
typedef ^void TestFn2();
typedef n
''');
    assertResponse(r'''
replacement
  right: 4
suggestions
  dynamic
    kind: keyword
  void
    kind: keyword
''');
  }

  @failingTest
  Future<void> test_009_4() async {
    allowedIdentifiers = {'void', 'dynamic'};
    await computeSuggestions('''
typedef dynamic TestFn1();
typedef vo^id TestFn2();
typedef n
''');
    assertResponse(r'''
replacement
  left: 2
  right: 2
suggestions
  dynamic
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_009_5() async {
    allowedIdentifiers = {'TestFn2'};
    await computeSuggestions('''
typedef dynamic TestFn1();
typedef void TestFn2();
typedef ^n
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  TestFn2
    kind: typeAlias
''');
  }

  Future<void> test_009_6() async {
    allowedIdentifiers = {'num'};
    await computeSuggestions('''
typedef dynamic TestFn1();
typedef void TestFn2();
typedef n^
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  num
    kind: class
''');
  }

  Future<void> test_009_7() async {
    await computeSuggestions('''
typedef dynamic TestFn1();
typedef void TestFn2();
typ^edef n
''');
    assertResponse(r'''
replacement
  left: 3
  right: 4
suggestions
  typedef
    kind: keyword
''');
  }

  Future<void> test_010_1() async {
    allowedIdentifiers = {'String', 'List', 'test'};
    await computeSuggestions('''
class test <^t  extends String, List, > {}
class tezetst <String, List> {}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
''');
  }

  @failingTest
  Future<void> test_010_2() async {
    allowedIdentifiers = {'String', 'test'};
    await computeSuggestions('''
class test <t ^ extends String, List, > {}
class tezetst <String, List> {}
''');
    assertResponse(r'''
suggestions
''');
  }

  @failingTest
  Future<void> test_010_3() async {
    await computeSuggestions('''
class test <t  ^extends String, List, > {}
class tezetst <String, List> {}
''');
    assertResponse(r'''
replacement
  right: 7
suggestions
  extends
    kind: keyword
''');
  }

  Future<void> test_010_4() async {
    allowedIdentifiers = {'tezetst', 'test'};
    await computeSuggestions('''
class test <t  extends String,^ List, > {}
class tezetst <String, List> {}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_010_5() async {
    allowedIdentifiers = {'String'};
    await computeSuggestions('''
class test <t  extends String, List,^ > {}
class tezetst <String, List> {}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_010_6() async {
    allowedIdentifiers = {'List'};
    await computeSuggestions('''
class test <t  extends String, List, ^> {}
class tezetst <String, List> {}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_010_7() async {
    allowedIdentifiers = {'List'};
    await computeSuggestions('''
class test <t  extends String, List, >^ {}
class tezetst <String, List> {}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_010_8() async {
    allowedIdentifiers = {'List'};
    await computeSuggestions('''
class test ^<t  extends String, List, > {}
class tezetst <String, List> {}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_010_9() async {
    allowedIdentifiers = {'String'};
    await computeSuggestions('''
class test <t  extends String, List, > {}
class tezetst ^<String, List> {}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_010_A() async {
    allowedIdentifiers = {'String'};
    await computeSuggestions('''
class test <t  extends String, List, > {}
class tezetst <String, List>^ {}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_010_B() async {
    allowedIdentifiers = {'String'};
    await computeSuggestions('''
class test <t  extends String, List, > {}
class tezetst <^String, List> {}
''');
    assertResponse(r'''
replacement
  right: 6
suggestions
''');
  }

  Future<void> test_010_C() async {
    allowedIdentifiers = {'List', 'tezetst'};
    await computeSuggestions('''
class test <t  extends String, List, > {}
class tezetst <String,^ List> {}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_010_D() async {
    allowedIdentifiers = {'List', 'test'};
    await computeSuggestions('''
class test <t  extends String, List, > {}
class tezetst <String, ^List> {}
''');
    assertResponse(r'''
replacement
  right: 4
suggestions
''');
  }

  @failingTest
  Future<void> test_011_1() async {
    allowedIdentifiers = {'object2'};
    await computeSuggestions('''
r2(var object, Object object1, Object ^);
''');
    assertResponse(r'''
suggestions
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  object2
    kind: identifier
  void
    kind: keyword
''');
  }

  @failingTest
  Future<void> test_012_1() async {
    allowedIdentifiers = {'var', 'dynamic', 'f'};
    await computeSuggestions('''
class X {
  f() {
    g(^var z) {true.toString();};
  }
}
''');
    assertResponse(r'''
replacement
  right: 3
suggestions
  dynamic
    kind: keyword
  var
    kind: keyword
''');
  }

  @failingTest
  Future<void> test_012_2() async {
    allowedIdentifiers = {'var', 'dynamic'};
    await computeSuggestions('''
class X {
  f() {
    g(var^ z) {true.toString();};
  }
}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  void
    kind: keyword
''');
  }

  Future<void> test_012_3() async {
    await computeSuggestions('''
class X {
  f() {
    g(var z) {^true.toString();};
  }
}
''');
    assertResponse(r'''
replacement
  right: 4
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_012_4() async {
    allowedIdentifiers = {'toString'};
    await computeSuggestions('''
class X {
  f() {
    g(var z) {true.^toString();};
  }
}
''');
    assertResponse(r'''
replacement
  right: 8
suggestions
  toString
    kind: methodInvocation
''');
  }

  Future<void> test_013_0() async {
    allowedIdentifiers = {'k'};
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  mth() {
    while (x );
    do{} while(x );
    for(z in zs) {}
    switch(k) {case 1:{^}}
    try {
    } on Object catch(a){}
    if (x ) {} else {};
  }
}
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  break
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  k
    kind: field
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_013_1() async {
    allowedIdentifiers = {'x'};
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  mth() {
    while (^x );
    do{} while(x );
    for(z in zs) {}
    switch(k) {case 1:{}}
    try {
    } on Object catch(a){}
    if (x ) {} else {};
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
  x
    kind: field
''');
  }

  Future<void> test_013_2() async {
    allowedIdentifiers = {'x'};
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  mth() {
    while (x );
    do{} while(^x );
    for(z in zs) {}
    switch(k) {case 1:{}}
    try {
    } on Object catch(a){}
    if (x ) {} else {};
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
  x
    kind: field
''');
  }

  Future<void> test_013_3() async {
    allowedIdentifiers = {'zs'};
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  mth() {
    while (x );
    do{} while(x );
    for(z in ^zs) {}
    switch(k) {case 1:{}}
    try {
    } on Object catch(a){}
    if (x ) {} else {};
  }
}
''');
    assertResponse(r'''
replacement
  right: 2
suggestions
  await
    kind: keyword
  zs
    kind: field
''');
  }

  Future<void> test_013_4() async {
    allowedIdentifiers = {'k'};
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  mth() {
    while (x );
    do{} while(x );
    for(z in zs) {}
    switch(^k) {case 1:{}}
    try {
    } on Object catch(a){}
    if (x ) {} else {};
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  k
    kind: field
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_013_5() async {
    allowedIdentifiers = {'Q', 'a'};
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  mth() {
    while (x );
    do{} while(x );
    for(z in zs) {}
    switch(k) {case 1:{}}
    try {
    } on ^Object catch(a){}
    if (x ) {} else {};
  }
}
''');
    assertResponse(r'''
replacement
  right: 6
suggestions
  Q
    kind: class
  dynamic
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_013_6() async {
    allowedIdentifiers = {'=='};
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  mth() {
    while (x );
    do{} while(x );
    for(z in zs) {}
    switch(k) {case 1:{}}
    try {
    } on Object catch(a){}
    if (x ^) {} else {};
  }
}
''');
    assertResponse(r'''
suggestions
  case
    kind: keyword
  is
    kind: keyword
''');
  }

  Future<void> test_013_7() async {
    allowedIdentifiers = {'x'};
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  mth() {
    while (x );
    do{} while(x );
    for(z in zs) {}
    switch(k) {case 1:{}}
    try {
    } on Object catch(a){}
    if (^x ) {} else {};
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
  x
    kind: field
''');
  }

  Future<void> test_013_8() async {
    allowedIdentifiers = {'=='};
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  mth() {
    while (x );
    do{} while(x ^);
    for(z in zs) {}
    switch(k) {case 1:{}}
    try {
    } on Object catch(a){}
    if (x ) {} else {};
  }
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_013_9() async {
    allowedIdentifiers = {'=='};
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  mth() {
    while (x ^);
    do{} while(x );
    for(z in zs) {}
    switch(k) {case 1:{}}
    try {
    } on Object catch(a){}
    if (x ) {} else {};
  }
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_014_1() async {
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  void mth() {
    ^while (z) { continue; };
    do{ break; } while(x);
    for(z in zs) {}
    for (int i; i < 3; i++);
    switch(k) {case 1:{} default:{}}
    try {
    } on Object catch(a){}
    assert true;
    if (x) {} else {};
    return;
  }
}
''');
    assertResponse(r'''
replacement
  right: 5
suggestions
  assert
    kind: keyword
  break
    kind: keyword
  continue
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_014_2() async {
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  void mth() {
    while (z) { continue; };
    ^do{ break; } while(x);
    for(z in zs) {}
    for (int i; i < 3; i++);
    switch(k) {case 1:{} default:{}}
    try {
    } on Object catch(a){}
    assert true;
    if (x) {} else {};
    return;
  }
}
''');
    assertResponse(r'''
replacement
  right: 2
suggestions
  assert
    kind: keyword
  break
    kind: keyword
  continue
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  @failingTest
  Future<void> test_014_3() async {
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  void mth() {
    while (z) { continue; };
    do{ break; } ^while(x);
    for(z in zs) {}
    for (int i; i < 3; i++);
    switch(k) {case 1:{} default:{}}
    try {
    } on Object catch(a){}
    assert true;
    if (x) {} else {};
    return;
  }
}
''');
    assertResponse(r'''
replacement
  right: 5
suggestions
  while
    kind: keyword
''');
  }

  Future<void> test_014_4() async {
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  void mth() {
    while (z) { continue; };
    do{ break; } while(x);
    ^for(z in zs) {}
    for (int i; i < 3; i++);
    switch(k) {case 1:{} default:{}}
    try {
    } on Object catch(a){}
    assert true;
    if (x) {} else {};
    return;
  }
}
''');
    assertResponse(r'''
replacement
  right: 3
suggestions
  assert
    kind: keyword
  break
    kind: keyword
  continue
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_014_5() async {
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  void mth() {
    while (z) { continue; };
    do{ break; } while(x);
    for(z ^in zs) {}
    for (int i; i < 3; i++);
    switch(k) {case 1:{} default:{}}
    try {
    } on Object catch(a){}
    assert true;
    if (x) {} else {};
    return;
  }
}
''');
    assertResponse(r'''
replacement
  right: 2
suggestions
  in
    kind: keyword
''');
  }

  Future<void> test_014_6() async {
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  void mth() {
    while (z) { continue; };
    do{ break; } while(x);
    for(z in zs) {}
    ^for (int i; i < 3; i++);
    switch(k) {case 1:{} default:{}}
    try {
    } on Object catch(a){}
    assert true;
    if (x) {} else {};
    return;
  }
}
''');
    assertResponse(r'''
replacement
  right: 3
suggestions
  assert
    kind: keyword
  break
    kind: keyword
  continue
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_014_7() async {
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  void mth() {
    while (z) { continue; };
    do{ break; } while(x);
    for(z in zs) {}
    for (int i; i < 3; i++);
    ^switch(k) {case 1:{} default:{}}
    try {
    } on Object catch(a){}
    assert true;
    if (x) {} else {};
    return;
  }
}
''');
    assertResponse(r'''
replacement
  right: 6
suggestions
  assert
    kind: keyword
  break
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_014_8() async {
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  void mth() {
    while (z) { continue; };
    do{ break; } while(x);
    for(z in zs) {}
    for (int i; i < 3; i++);
    switch(k) {^case 1:{} default:{}}
    try {
    } on Object catch(a){}
    assert true;
    if (x) {} else {};
    return;
  }
}
''');
    assertResponse(r'''
replacement
  right: 4
suggestions
  case
    kind: keyword
''');
  }

  Future<void> test_014_9() async {
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  void mth() {
    while (z) { continue; };
    do{ break; } while(x);
    for(z in zs) {}
    for (int i; i < 3; i++);
    switch(k) {case 1:{} ^default:{}}
    try {
    } on Object catch(a){}
    assert true;
    if (x) {} else {};
    return;
  }
}
''');
    assertResponse(r'''
replacement
  right: 7
suggestions
  case
    kind: keyword
  default:
    kind: keyword
''');
  }

  Future<void> test_014_A() async {
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  void mth() {
    while (z) { continue; };
    do{ break; } while(x);
    for(z in zs) {}
    for (int i; i < 3; i++);
    switch(k) {case 1:{} default:{}}
    ^try {
    } on Object catch(a){}
    assert true;
    if (x) {} else {};
    return;
  }
}
''');
    assertResponse(r'''
replacement
  right: 3
suggestions
  assert
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_014_B() async {
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  void mth() {
    while (z) { continue; };
    do{ break; } while(x);
    for(z in zs) {}
    for (int i; i < 3; i++);
    switch(k) {case 1:{} default:{}}
    try {
    } ^on Object catch(a){}
    assert true;
    if (x) {} else {};
    return;
  }
}
''');
    assertResponse(r'''
replacement
  right: 2
suggestions
  on
    kind: keyword
''');
  }

  Future<void> test_014_C() async {
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  void mth() {
    while (z) { continue; };
    do{ break; } while(x);
    for(z in zs) {}
    for (int i; i < 3; i++);
    switch(k) {case 1:{} default:{}}
    try {
    } on Object ^catch(a){}
    assert true;
    if (x) {} else {};
    return;
  }
}
''');
    assertResponse(r'''
replacement
  right: 5
suggestions
  catch
    kind: keyword
''');
  }

  Future<void> test_014_D() async {
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  ^var a;
  void mth() {
    while (z) { continue; };
    do{ break; } while(x);
    for(z in zs) {}
    for (int i; i < 3; i++);
    switch(k) {case 1:{} default:{}}
    try {
    } on Object catch(a){}
    assert true;
    if (x) {} else {};
    return;
  }
}
''');
    assertResponse(r'''
replacement
  right: 3
suggestions
  abstract
    kind: keyword
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  external
    kind: keyword
  final
    kind: keyword
  late
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_014_E() async {
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  ^void mth() {
    while (z) { continue; };
    do{ break; } while(x);
    for(z in zs) {}
    for (int i; i < 3; i++);
    switch(k) {case 1:{} default:{}}
    try {
    } on Object catch(a){}
    assert true;
    if (x) {} else {};
    return;
  }
}
''');
    assertResponse(r'''
replacement
  right: 4
suggestions
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_014_F() async {
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  void mth() {
    while (z) { continue; };
    do{ break; } while(x);
    for(z in zs) {}
    for (int i; i < 3; i++);
    switch(k) {case 1:{} default:{}}
    try {
    } on Object catch(a){}
    ^assert true;
    if (x) {} else {};
    return;
  }
}
''');
    assertResponse(r'''
replacement
  right: 6
suggestions
  assert
    kind: keyword
''');
  }

  Future<void> test_014_G() async {
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  void mth() {
    while (z) { ^continue; };
    do{ break; } while(x);
    for(z in zs) {}
    for (int i; i < 3; i++);
    switch(k) {case 1:{} default:{}}
    try {
    } on Object catch(a){}
    assert true;
    if (x) {} else {};
    return;
  }
}
''');
    assertResponse(r'''
replacement
  right: 8
suggestions
  continue
    kind: keyword
''');
  }

  Future<void> test_014_H() async {
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  void mth() {
    while (z) { continue; };
    do{ ^break; } while(x);
    for(z in zs) {}
    for (int i; i < 3; i++);
    switch(k) {case 1:{} default:{}}
    try {
    } on Object catch(a){}
    assert true;
    if (x) {} else {};
    return;
  }
}
''');
    assertResponse(r'''
replacement
  right: 5
suggestions
  break
    kind: keyword
''');
  }

  Future<void> test_014_J() async {
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  void mth() {
    while (z) { continue; };
    do{ break; } while(x);
    for(z in zs) {}
    for (int i; i < 3; i++);
    switch(k) {case 1:{} default:{}}
    try {
    } on Object catch(a){}
    assert true;
    ^if (x) {} else {};
    return;
  }
}
''');
    assertResponse(r'''
replacement
  right: 2
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  @failingTest
  Future<void> test_014_K() async {
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  void mth() {
    while (z) { continue; };
    do{ break; } while(x);
    for(z in zs) {}
    for (int i; i < 3; i++);
    switch(k) {case 1:{} default:{}}
    try {
    } on Object catch(a){}
    assert true;
    if (x) {} ^else {};
    return;
  }
}
''');
    assertResponse(r'''
replacement
  right: 4
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  else
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_014_L() async {
    await computeSuggestions('''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  void mth() {
    while (z) { continue; };
    do{ break; } while(x);
    for(z in zs) {}
    for (int i; i < 3; i++);
    switch(k) {case 1:{} default:{}}
    try {
    } on Object catch(a){}
    assert true;
    if (x) {} else {};
    ^return;
  }
}
''');
    assertResponse(r'''
replacement
  right: 6
suggestions
  assert
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_015_1() async {
    allowedIdentifiers = {'=='};
    await computeSuggestions('''
f(a,b,c) => a + b * c ^;
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_016_1() async {
    allowedIdentifiers = {'=='};
    await computeSuggestions('''
class X {dynamic f(a,b,c) {return a + b * c ^;}}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
  }

  @failingTest
  Future<void> test_017_1() async {
    await computeSuggestions('''
^import 'x' as r;
export 'uri' hide Q show X;
part 'x';
''');
    assertResponse(r'''
replacement
  right: 6
suggestions
  library
    kind: keyword
''');
  }

  @failingTest
  Future<void> test_017_2() async {
    await computeSuggestions('''
^import 'x' as r;
export 'uri' hide Q show X;
part 'x';
''');
    assertResponse(r'''
replacement
  right: 6
suggestions
  import
    kind: keyword
''');
  }

  @failingTest
  Future<void> test_017_3() async {
    await computeSuggestions('''
import 'x' as r;
^export 'uri' hide Q show X;
part 'x';
''');
    assertResponse(r'''
replacement
  right: 6
suggestions
  export
    kind: keyword
''');
  }

  @failingTest
  Future<void> test_017_4() async {
    await computeSuggestions('''
import 'x' as r;
export 'uri' hide Q show X;
^part 'x';
''');
    assertResponse(r'''
replacement
  right: 4
suggestions
  part
    kind: keyword
''');
  }

  @failingTest
  Future<void> test_017_5() async {
    await computeSuggestions('''
import 'x' ^as r;
export 'uri' hide Q show X;
part 'x';
''');
    assertResponse(r'''
replacement
  right: 2
suggestions
  as
    kind: keyword
''');
  }

  @failingTest
  Future<void> test_017_6() async {
    await computeSuggestions('''
import 'x' as r;
export 'uri' ^hide Q show X;
part 'x';
''');
    assertResponse(r'''
replacement
  right: 4
suggestions
  hide
    kind: keyword
''');
  }

  @failingTest
  Future<void> test_017_7() async {
    await computeSuggestions('''
import 'x' as r;
export 'uri' hide Q ^show X;
part 'x';
''');
    assertResponse(r'''
replacement
  right: 4
suggestions
  show
    kind: keyword
''');
  }

  Future<void> test_017_8() async {
    await computeSuggestions('''
import 'x' as r;
export '^uri' hide Q show X;
part 'x';
''');
    assertResponse(r'''
replacement
  right: 3
suggestions
  dart:
    kind: import
  dart:async
    kind: import
  dart:async2
    kind: import
  dart:collection
    kind: import
  dart:convert
    kind: import
  dart:core
    kind: import
  dart:ffi
    kind: import
  dart:html
    kind: import
  dart:io
    kind: import
  dart:isolate
    kind: import
  dart:math
    kind: import
  package:
    kind: import
  package:test/
    kind: import
  package:test/test.dart
    kind: import
''');
  }

  @failingTest
  Future<void> test_018_1() async {
    await computeSuggestions('''
^part of foo;
''');
    assertResponse(r'''
replacement
  right: 4
suggestions
  part
    kind: keyword
''');
  }

  @failingTest
  Future<void> test_018_2() async {
    await computeSuggestions('''
part ^of foo;
''');
    assertResponse(r'''
replacement
  right: 2
suggestions
  of
    kind: keyword
''');
  }

  Future<void> test_019_1() async {
    allowedIdentifiers = {'true', 'truefalse', 'falsetrue'};
    await computeSuggestions('''
var truefalse = 0;
var falsetrue = 1;
void f() {
  var foo = true^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 4
suggestions
  falsetrue
    kind: topLevelVariable
  true
    kind: keyword
  truefalse
    kind: topLevelVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 4
suggestions
  const
    kind: keyword
  false
    kind: keyword
  falsetrue
    kind: topLevelVariable
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
  truefalse
    kind: topLevelVariable
''');
    }
  }

  Future<void> test_020_1() async {
    allowedIdentifiers = {'toString'};
    await computeSuggestions('''
var x = null.^
''');
    assertResponse(r'''
suggestions
  toString
    kind: methodInvocation
''');
  }

  Future<void> test_021_1() async {
    allowedIdentifiers = {'toString'};
    await computeSuggestions('''
var x = .^
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_022_1() async {
    allowedIdentifiers = {'toString'};
    await computeSuggestions('''
var x = .^;
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_023_1() async {
    allowedIdentifiers = {'getKeys'};
    await computeSuggestions('''
class Map{getKeys(){}}
class X {
  static x1(Map m) {
    m.^getKeys;
  }
  x2(Map m) {
    m.getKeys;
  }
}
''');
    assertResponse(r'''
replacement
  right: 7
suggestions
  getKeys
    kind: methodInvocation
''');
  }

  Future<void> test_023_2() async {
    allowedIdentifiers = {'getKeys'};
    await computeSuggestions('''
class Map{getKeys(){}}
class X {
  static x1(Map m) {
    m.getKeys;
  }
  x2(Map m) {
    m.^getKeys;
  }
}
''');
    assertResponse(r'''
replacement
  right: 7
suggestions
  getKeys
    kind: methodInvocation
''');
  }

  Future<void> test_024_1() async {
    allowedIdentifiers = {'from'};
    await computeSuggestions('''
class List{factory List.from(Iterable other) {}}
class F {
  f() {
    new List.^
  }
}
''');
    assertResponse(r'''
suggestions
  from
    kind: constructorInvocation
''');
  }

  Future<void> test_025_1() async {
    allowedIdentifiers = {'m'};
    await computeSuggestions('''
class R {
  static R _m;
  static R m;
  f() {
    var a = ^m;
    var b = _m;
    var c = g();
  }
  static g() {
    var a = m;
    var b = _m;
    var c = g();
  }
}
class T {
  f() {
    R x;
    x.g();
    x.m;
    x._m;
  }
  static g() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
  h() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  m
    kind: field
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_025_2() async {
    allowedIdentifiers = {'_m'};
    await computeSuggestions('''
class R {
  static R _m;
  static R m;
  f() {
    var a = m;
    var b = _^m;
    var c = g();
  }
  static g() {
    var a = m;
    var b = _m;
    var c = g();
  }
}
class T {
  f() {
    R x;
    x.g();
    x.m;
    x._m;
  }
  static g() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
  h() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
  right: 1
suggestions
  _m
    kind: field
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
  right: 1
suggestions
  _m
    kind: field
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_025_3() async {
    allowedIdentifiers = {'g'};
    await computeSuggestions('''
class R {
  static R _m;
  static R m;
  f() {
    var a = m;
    var b = _m;
    var c = ^g();
  }
  static g() {
    var a = m;
    var b = _m;
    var c = g();
  }
}
class T {
  f() {
    R x;
    x.g();
    x.m;
    x._m;
  }
  static g() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
  h() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  g
    kind: methodInvocation
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_025_4() async {
    allowedIdentifiers = {'m'};
    await computeSuggestions('''
class R {
  static R _m;
  static R m;
  f() {
    var a = m;
    var b = _m;
    var c = g();
  }
  static g() {
    var a = ^m;
    var b = _m;
    var c = g();
  }
}
class T {
  f() {
    R x;
    x.g();
    x.m;
    x._m;
  }
  static g() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
  h() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  m
    kind: field
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_025_5() async {
    allowedIdentifiers = {'_m'};
    await computeSuggestions('''
class R {
  static R _m;
  static R m;
  f() {
    var a = m;
    var b = _m;
    var c = g();
  }
  static g() {
    var a = m;
    var b = _^m;
    var c = g();
  }
}
class T {
  f() {
    R x;
    x.g();
    x.m;
    x._m;
  }
  static g() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
  h() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
  right: 1
suggestions
  _m
    kind: field
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
  right: 1
suggestions
  _m
    kind: field
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_025_6() async {
    allowedIdentifiers = {'g'};
    await computeSuggestions('''
class R {
  static R _m;
  static R m;
  f() {
    var a = m;
    var b = _m;
    var c = g();
  }
  static g() {
    var a = m;
    var b = _m;
    var c = ^g();
  }
}
class T {
  f() {
    R x;
    x.g();
    x.m;
    x._m;
  }
  static g() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
  h() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  g
    kind: methodInvocation
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_025_7() async {
    allowedIdentifiers = {'g'};
    await computeSuggestions('''
class R {
  static R _m;
  static R m;
  f() {
    var a = m;
    var b = _m;
    var c = g();
  }
  static g() {
    var a = m;
    var b = _m;
    var c = g();
  }
}
class T {
  f() {
    R x;
    x.^g();
    x.m;
    x._m;
  }
  static g() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
  h() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
''');
  }

  Future<void> test_025_8() async {
    allowedIdentifiers = {'m'};
    await computeSuggestions('''
class R {
  static R _m;
  static R m;
  f() {
    var a = m;
    var b = _m;
    var c = g();
  }
  static g() {
    var a = m;
    var b = _m;
    var c = g();
  }
}
class T {
  f() {
    R x;
    x.g();
    x.^m;
    x._m;
  }
  static g() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
  h() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
''');
  }

  Future<void> test_025_9() async {
    allowedIdentifiers = {'_m'};
    await computeSuggestions('''
class R {
  static R _m;
  static R m;
  f() {
    var a = m;
    var b = _m;
    var c = g();
  }
  static g() {
    var a = m;
    var b = _m;
    var c = g();
  }
}
class T {
  f() {
    R x;
    x.g();
    x.m;
    x._^m;
  }
  static g() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
  h() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
}
''');
    assertResponse(r'''
replacement
  left: 1
  right: 1
suggestions
''');
  }

  Future<void> test_025_A() async {
    allowedIdentifiers = {'_m'};
    await computeSuggestions('''
class R {
  static R _m;
  static R m;
  f() {
    var a = m;
    var b = _m;
    var c = g();
  }
  static g() {
    var a = m;
    var b = _m;
    var c = g();
  }
}
class T {
  f() {
    R x;
    x.g();
    x.m;
    x._m;
  }
  static g() {
    var q = R._^m;
    var g = R.m;
    var h = R.g();
  }
  h() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
}
''');
    assertResponse(r'''
replacement
  left: 1
  right: 1
suggestions
  _m
    kind: field
''');
  }

  Future<void> test_025_B() async {
    allowedIdentifiers = {'m'};
    await computeSuggestions('''
class R {
  static R _m;
  static R m;
  f() {
    var a = m;
    var b = _m;
    var c = g();
  }
  static g() {
    var a = m;
    var b = _m;
    var c = g();
  }
}
class T {
  f() {
    R x;
    x.g();
    x.m;
    x._m;
  }
  static g() {
    var q = R._m;
    var g = R.^m;
    var h = R.g();
  }
  h() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  m
    kind: field
''');
  }

  Future<void> test_025_C() async {
    allowedIdentifiers = {'g'};
    await computeSuggestions('''
class R {
  static R _m;
  static R m;
  f() {
    var a = m;
    var b = _m;
    var c = g();
  }
  static g() {
    var a = m;
    var b = _m;
    var c = g();
  }
}
class T {
  f() {
    R x;
    x.g();
    x.m;
    x._m;
  }
  static g() {
    var q = R._m;
    var g = R.m;
    var h = R.^g();
  }
  h() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  g
    kind: methodInvocation
''');
  }

  Future<void> test_025_D() async {
    allowedIdentifiers = {'_m'};
    await computeSuggestions('''
class R {
  static R _m;
  static R m;
  f() {
    var a = m;
    var b = _m;
    var c = g();
  }
  static g() {
    var a = m;
    var b = _m;
    var c = g();
  }
}
class T {
  f() {
    R x;
    x.g();
    x.m;
    x._m;
  }
  static g() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
  h() {
    var q = R._^m;
    var g = R.m;
    var h = R.g();
  }
}
''');
    assertResponse(r'''
replacement
  left: 1
  right: 1
suggestions
  _m
    kind: field
''');
  }

  Future<void> test_025_E() async {
    allowedIdentifiers = {'m'};
    await computeSuggestions('''
class R {
  static R _m;
  static R m;
  f() {
    var a = m;
    var b = _m;
    var c = g();
  }
  static g() {
    var a = m;
    var b = _m;
    var c = g();
  }
}
class T {
  f() {
    R x;
    x.g();
    x.m;
    x._m;
  }
  static g() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
  h() {
    var q = R._m;
    var g = R.^m;
    var h = R.g();
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  m
    kind: field
''');
  }

  Future<void> test_025_F() async {
    allowedIdentifiers = {'g'};
    await computeSuggestions('''
class R {
  static R _m;
  static R m;
  f() {
    var a = m;
    var b = _m;
    var c = g();
  }
  static g() {
    var a = m;
    var b = _m;
    var c = g();
  }
}
class T {
  f() {
    R x;
    x.g();
    x.m;
    x._m;
  }
  static g() {
    var q = R._m;
    var g = R.m;
    var h = R.g();
  }
  h() {
    var q = R._m;
    var g = R.m;
    var h = R.^g();
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  g
    kind: methodInvocation
''');
  }

  Future<void> test_026_1() async {
    allowedIdentifiers = {'aBcD'};
    await computeSuggestions('''
var aBcD; var x=ab^
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  aBcD
    kind: topLevelVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  aBcD
    kind: topLevelVariable
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_027_1() async {
    allowedIdentifiers = {'ssss'};
    await computeSuggestions('''
m(){try{}catch(eeee,ssss){s^}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  ssss
    kind: localVariable
  switch
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  ssss
    kind: localVariable
  switch
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
    }
  }

  @failingTest
  Future<void> test_028_1() async {
    allowedIdentifiers = {'isX'};
    await computeSuggestions('''
m(){var isX=3;if(is^)
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  is
    kind: keyword
  isX
    kind: localVariable
''');
  }

  Future<void> test_029_1() async {
    allowedIdentifiers = {'x'};
    await computeSuggestions('''
m(){[1].forEach((x)=>^x);}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
  x
    kind: parameter
''');
  }

  Future<void> test_030_1() async {
    allowedIdentifiers = {'x'};
    await computeSuggestions('''
n(){[1].forEach((x){^});}
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
  x
    kind: parameter
''');
  }

  Future<void> test_031_1() async {
    allowedIdentifiers = {'Caster', 'CastBlock'};
    await computeSuggestions('''
class Caster {} m() {try {} on Cas^ter catch (CastBlock) {}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
  right: 3
suggestions
  Caster
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
  right: 3
suggestions
  Caster
    kind: class
  dynamic
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_031_2() async {
    allowedIdentifiers = {'Caster', 'CastBlock'};
    await computeSuggestions('''
class Caster {} m() {try {} on Caster catch (CastBlock) {^}}
''');
    assertResponse(r'''
suggestions
  CastBlock
    kind: localVariable
  Caster
    kind: class
  Caster
    kind: constructorInvocation
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  rethrow
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  @failingTest
  Future<void> test_032_1() async {
    allowedIdentifiers = {'ONE', 'UKSI'};
    await computeSuggestions('''
const ONE = 1;
const ICHI = 10;
const UKSI = 100;
const EIN = 1000;
m() {
  int x;
  switch (x) {
    case ICHI:
    case UKSI:
    case EIN:
    case ONE^: return;
    default: return;
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
  ONE
    kind: topLevelVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  const
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  null
    kind: keyword
  ONE
    kind: topLevelVariable
  true
    kind: keyword
  var
    kind: keyword
''');
    }
  }

  @failingTest
  Future<void> test_032_2() async {
    allowedIdentifiers = {'EIN', 'ICHI'};
    await computeSuggestions('''
const ONE = 1;
const ICHI = 10;
const UKSI = 100;
const EIN = 1000;
m() {
  int x;
  switch (x) {
    case ICHI:
    case UKSI:
    case EIN^:
    case ONE: return;
    default: return;
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
  EIN
    kind: topLevelVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  const
    kind: keyword
  EIN
    kind: topLevelVariable
  false
    kind: keyword
  final
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  var
    kind: keyword
''');
    }
  }

  @failingTest
  Future<void> test_032_3() async {
    allowedIdentifiers = {'ICHI', 'UKSI', 'EIN', 'ONE'};
    await computeSuggestions('''
const ONE = 1;
const ICHI = 10;
const UKSI = 100;
const EIN = 1000;
m() {
  int x;
  switch (x) {
    case ^ICHI:
    case UKSI:
    case EIN:
    case ONE: return;
    default: return;
  }
}
''');
    assertResponse(r'''
replacement
  right: 4
suggestions
  const
    kind: keyword
  EIN
    kind: topLevelVariable
  false
    kind: keyword
  final
    kind: keyword
  ICHI
    kind: topLevelVariable
  null
    kind: keyword
  ONE
    kind: topLevelVariable
  true
    kind: keyword
  UKSI
    kind: topLevelVariable
  var
    kind: keyword
''');
  }

  Future<void> test_033_1() async {
    allowedIdentifiers = {'b', 'c'};
    await computeSuggestions('''
class A{}class B extends A{b(){}}class C implements A {c(){}}class X{x(){A f;f.^}}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_034_1() async {
    allowedIdentifiers = {'top'};
    await computeSuggestions('''
var topvar;
class Top {top(){}}
class Left extends Top {left(){}}
class Right extends Top {right(){}}
t1() {
  topvar = new Left();
}
t2() {
  topvar = new Right();
}
class A {
  var field;
  a() {
    field = new Left();
  }
  b() {
    field = new Right();
  }
  test() {
    topvar.^top();
    field.top();
  }
}
''');
    assertResponse(r'''
replacement
  right: 3
suggestions
''');
  }

  Future<void> test_034_2() async {
    allowedIdentifiers = {'top'};
    await computeSuggestions('''
var topvar;
class Top {top(){}}
class Left extends Top {left(){}}
class Right extends Top {right(){}}
t1() {
  topvar = new Left();
}
t2() {
  topvar = new Right();
}
class A {
  var field;
  a() {
    field = new Left();
  }
  b() {
    field = new Right();
  }
  test() {
    topvar.top();
    field.^top();
  }
}
''');
    assertResponse(r'''
replacement
  right: 3
suggestions
''');
  }

  Future<void> test_035_1() async {
    allowedIdentifiers = {'length'};
    await computeSuggestions('''
class Y {final x='hi';mth() {x.^length;}}
''');
    assertResponse(r'''
replacement
  right: 6
suggestions
  length
    kind: getter
''');
  }

  Future<void> test_036_1() async {
    allowedIdentifiers = {'round'};
    await computeSuggestions('''
class A1 {
  var field;
  A1() : field = 0;
  q() {
    A1 a = new A1();
    a.field.^
  }
}
void f() {
  A1 a = new A1();
  a.field.
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_036_2() async {
    allowedIdentifiers = {'round'};
    await computeSuggestions('''
class A1 {
  var field;
  A1() : field = 0;
  q() {
    A1 a = new A1();
    a.field.
  }
}
void f() {
  A1 a = new A1();
  a.field.^
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_037_1() async {
    allowedIdentifiers = {'HttpServer', 'HttpClient'};
    await computeSuggestions('''
class HttpServer{}
class HttpClient{}
void f() {
  new HtS^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
  HttpServer
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  HttpClient
    kind: constructorInvocation
  HttpServer
    kind: constructorInvocation
''');
    }
  }

  Future<void> test_038_1() async {
    allowedIdentifiers = {'y', 'x'};
    await computeSuggestions('''
class X {
  x(){}
}
class Y {
  y(){}
}
class A<Z extends X> {
  Y ay;
  Z az;
  A(this.ay, this.az) {
    ay.^y;
    az.x;
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  y
    kind: methodInvocation
''');
  }

  Future<void> test_038_2() async {
    allowedIdentifiers = {'x', 'y'};
    await computeSuggestions('''
class X {
  x(){}
}
class Y {
  y(){}
}
class A<Z extends X> {
  Y ay;
  Z az;
  A(this.ay, this.az) {
    ay.y;
    az.^x;
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  x
    kind: methodInvocation
''');
  }

  Future<void> test_039_1() async {
    await computeSuggestions('''
class X{}var x = null as ^X;
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  dynamic
    kind: keyword
''');
  }

  Future<void> test_040_1() async {
    await computeSuggestions('''
m(){f(a, b, {x1, x2, y}) {};f(1, 2, ^);}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
  |x1: |
    kind: namedArgument
  |x2: |
    kind: namedArgument
  |y: |
    kind: namedArgument
''');
  }

  Future<void> test_040_2() async {
    await computeSuggestions('''
m(){f(a, b, {x1, x2, y}) {};f(1, 2, )^;}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_041_1() async {
    allowedIdentifiers = {'y'};
    await computeSuggestions('''
m(){f(a, b, {x1, x2, y}) {};f(1, 2, ^
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
  |x1: |
    kind: namedArgument
  |x2: |
    kind: namedArgument
  |y: |
    kind: namedArgument
''');
  }

  Future<void> test_042_1() async {
    await computeSuggestions('''
m(){f(a, b, {x1, x2, y}) {};f(1, 2, ^;
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
  |x1: |
    kind: namedArgument
  |x2: |
    kind: namedArgument
  |y: |
    kind: namedArgument
''');
  }

  Future<void> test_042_2() async {
    allowedIdentifiers = {'y'};
    await computeSuggestions('''
m(){f(a, b, {x1, x2, y}) {};f(1, 2, ;^
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_classMembers_inGetter_1() async {
    allowedIdentifiers = {'fff'};
    await computeSuggestions('''
class A { var fff; get z {ff^}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  fff
    kind: field
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  fff
    kind: field
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets001_1() async {
    allowedIdentifiers = {'MAX'};
    await computeSuggestions('''
class X {static final num MAX = 0;num yc,xc;mth() {xc = yc = MA^X;xc.abs();num f = MAX;}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
  right: 1
suggestions
  MAX
    kind: field
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
  right: 1
suggestions
  MAX
    kind: field
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets001_2() async {
    allowedIdentifiers = {'xc'};
    await computeSuggestions('''
class X {static final num MAX = 0;num yc,xc;mth() {xc = yc = MAX;x^c.abs();num f = MAX;}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
  right: 1
suggestions
  xc
    kind: field
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
  right: 1
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
  xc
    kind: field
''');
    }
  }

  Future<void> test_commentSnippets001_3() async {
    allowedIdentifiers = {'MAX'};
    await computeSuggestions('''
class X {static final num MAX = 0;num yc,xc;mth() {xc = yc = MAX;xc.abs();num f = M^AX;}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
  right: 2
suggestions
  MAX
    kind: field
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
  right: 2
suggestions
  MAX
    kind: field
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets002_1() async {
    allowedIdentifiers = {'length'};
    await computeSuggestions('''
class Y {String x='hi';mth() {x.l^ength;int n = 0;x.codeUnitAt(n);}}
''');
    assertResponse(r'''
replacement
  left: 1
  right: 5
suggestions
  length
    kind: getter
''');
  }

  Future<void> test_commentSnippets002_2() async {
    allowedIdentifiers = {'x'};
    await computeSuggestions('''
class Y {String x='hi';mth() {x.length;int n = 0;x^.codeUnitAt(n);}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  x
    kind: field
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
  x
    kind: field
''');
    }
  }

  Future<void> test_commentSnippets002_3() async {
    allowedIdentifiers = {'n'};
    await computeSuggestions('''
class Y {String x='hi';mth() {x.length;int n = 0;x.codeUnitAt(n^);}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  n
    kind: localVariable
  null
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  n
    kind: localVariable
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets004_1() async {
    allowedIdentifiers = {'A'};
    await computeSuggestions('''
class A {^int x; mth() {int y = this.x;}}class B{}
''');
    assertResponse(r'''
replacement
  right: 3
suggestions
  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;
    kind: override
    selection: 62 14
  @override
  // TODO: implement runtimeType
  Type get runtimeType => super.runtimeType;
    kind: override
    selection: 69 17
  @override
  String toString() {
    // TODO: implement toString
    return super.toString();
  }
    kind: override
    selection: 68 24
  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
    kind: override
    selection: 75 22
  @override
  noSuchMethod(Invocation invocation) {
    // TODO: implement noSuchMethod
    return super.noSuchMethod(invocation);
  }
    kind: override
    selection: 90 38
  A
    kind: class
  abstract
    kind: keyword
  const
    kind: keyword
  covariant
    kind: keyword
  external
    kind: keyword
  final
    kind: keyword
  late
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
''');
  }

  Future<void> test_commentSnippets004_2() async {
    allowedIdentifiers = {'B'};
    await computeSuggestions('''
class A {int x; ^mth() {int y = this.x;}}class B{}
''');
    assertResponse(r'''
replacement
  right: 3
suggestions
  B
    kind: class
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_commentSnippets004_3() async {
    allowedIdentifiers = {'x', 'y'};
    await computeSuggestions('''
class A {int x; mth() {^int y = this.x;}}class B{}
''');
    assertResponse(r'''
replacement
  right: 3
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
  x
    kind: field
''');
  }

  Future<void> test_commentSnippets004_5() async {
    allowedIdentifiers = {'mth'};
    await computeSuggestions('''
class A {int x; mth() {int y = this.^x;}}class B{}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  mth
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets004_6() async {
    allowedIdentifiers = {'x'};
    await computeSuggestions('''
class A {int x; mth() {int y = this.x^;}}class B{}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  x
    kind: field
''');
  }

  Future<void> test_commentSnippets005_1() async {
    allowedIdentifiers = {'Date'};
    await computeSuggestions('''
class Date { static Date JUN, JUL;}class X { m() { return Da^te.JUL; }}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
  right: 2
suggestions
  Date
    kind: class
  Date
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
  right: 2
suggestions
  Date
    kind: class
  Date
    kind: constructorInvocation
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets005_2() async {
    allowedIdentifiers = {'JUN', 'JUL'};
    await computeSuggestions('''
class Date { static Date JUN, JUL;}class X { m() { return Date.JU^L; }}
''');
    assertResponse(r'''
replacement
  left: 2
  right: 1
suggestions
  JUL
    kind: field
  JUN
    kind: field
''');
  }

  Future<void> test_commentSnippets007_1() async {
    allowedIdentifiers = {'bool'};
    await computeSuggestions('''
class C {mth(Map x, ^) {}mtf(, Map x) {}m() {for (int i=0; i<5; i++); A x;}}class int{}class Arrays{}
''');
    assertResponse(r'''
suggestions
  bool
    kind: class
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_commentSnippets007_2() async {
    allowedIdentifiers = {'bool'};
    await computeSuggestions('''
class C {mth(Map x, ) {}mtf(^, Map x) {}m() {for (int i=0; i<5; i++); A x;}}class int{}class Arrays{}
''');
    assertResponse(r'''
suggestions
  bool
    kind: class
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_commentSnippets007_3() async {
    allowedIdentifiers = {'int'};
    await computeSuggestions('''
class C {mth(Map x, ) {}mtf(, Map x) {}m() {for (in^t i=0; i<5; i++); A x;}}class int{}class Arrays{}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
  right: 1
suggestions
  int
    kind: class
''');
    } else {
      // TODO(brianwilkerson) 'int' should not be suggested twice
      assertResponse(r'''
replacement
  left: 2
  right: 1
suggestions
  int
    kind: class
  int
    kind: class
''');
    }
  }

  Future<void> test_commentSnippets007_4() async {
    allowedIdentifiers = {'Arrays'};
    await computeSuggestions('''
class C {mth(Map x, ) {}mtf(, Map x) {}m() {for (int i=0; i<5; i++); A^ x;}}class int{}class Arrays{}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  Arrays
    kind: class
  Arrays
    kind: constructorInvocation
  assert
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  Arrays
    kind: class
  Arrays
    kind: constructorInvocation
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets008_1() async {
    allowedIdentifiers = {'Date'};
    await computeSuggestions('''
class Date{}final num M = Dat^
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
  Date
    kind: class
  Date
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  Date
    kind: class
  Date
    kind: constructorInvocation
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets009_1() async {
    allowedIdentifiers = {'Map'};
    await computeSuggestions('''
class Maps{}class x extends M implements ^
{}
''');
    assertResponse(r'''
suggestions
  Map
    kind: class
''');
  }

  Future<void> test_commentSnippets009_2() async {
    allowedIdentifiers = {'Maps'};
    await computeSuggestions('''
class Maps{}class x extends ^M implements
{}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  Maps
    kind: class
''');
  }

  Future<void> test_commentSnippets009_3() async {
    allowedIdentifiers = {'Maps'};
    await computeSuggestions('''
class Maps{}class x extends M^ implements
{}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  Maps
    kind: class
''');
  }

  Future<void> test_commentSnippets009_4() async {
    allowedIdentifiers = {'Maps'};
    await computeSuggestions('''
class Maps{}class x extends M ^implements
{}
''');
    assertResponse(r'''
replacement
  right: 10
suggestions
  implements
    kind: keyword
  with
    kind: keyword
''');
  }

  Future<void> test_commentSnippets009_5() async {
    allowedIdentifiers = {'Maps'};
    await computeSuggestions('''
class Maps{}class x extends^ M implements
{}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 7
suggestions
  extends
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 7
suggestions
  extends
    kind: keyword
  with
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets009_6() async {
    allowedIdentifiers = {'Map'};
    await computeSuggestions('''
class Maps{}class x extends M implements^
{}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 10
suggestions
  implements
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 10
suggestions
  implements
    kind: keyword
  with
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets010_1() async {
    allowedIdentifiers = {'Map'};
    await computeSuggestions('''
class x implements ^{}
''');
    assertResponse(r'''
suggestions
  Map
    kind: class
  dynamic
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_commentSnippets011_1() async {
    allowedIdentifiers = {'Map'};
    await computeSuggestions('''
class x implements M^{}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  Map
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  Map
    kind: class
  dynamic
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets012_1() async {
    allowedIdentifiers = {'Map'};
    await computeSuggestions('''
class x implements M^
{}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  Map
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  Map
    kind: class
  dynamic
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets013_1() async {
    allowedIdentifiers = {'num'};
    await computeSuggestions('''
class x {^}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  num
    kind: class
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_commentSnippets013_2() async {
    allowedIdentifiers = {'num'};
    await computeSuggestions('''
class x ^{}
''');
    assertResponse(r'''
suggestions
  extends
    kind: keyword
  implements
    kind: keyword
  with
    kind: keyword
''');
  }

  Future<void> test_commentSnippets013_3() async {
    allowedIdentifiers = {'num'};
    await computeSuggestions('''
class x {}^
''');
    assertResponse(r'''
suggestions
  num
    kind: class
''');
  }

  Future<void> test_commentSnippets014_1() async {
    allowedIdentifiers = {'num'};
    await computeSuggestions('''
typedef n^ ;
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  num
    kind: class
''');
  }

  Future<void> test_commentSnippets015_1() async {
    allowedIdentifiers = {'f'};
    await computeSuggestions('''
class D {f(){} g(){f^(f);}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  f
    kind: methodInvocation
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  f
    kind: methodInvocation
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets015_2() async {
    allowedIdentifiers = {'f'};
    await computeSuggestions('''
class D {f(){} g(){f(f^);}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  f
    kind: methodInvocation
  false
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
  f
    kind: methodInvocation
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets016_1() async {
    allowedIdentifiers = {'m'};
    await computeSuggestions('''
class F {m() { m(); ^}}
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  m
    kind: methodInvocation
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_commentSnippets017_1() async {
    await computeSuggestions('''
class F {var x = ^false;}
''');
    assertResponse(r'''
replacement
  right: 5
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_commentSnippets018_1() async {
    allowedIdentifiers = {'Map', 'dynamic', 'void', 'null'};
    await computeSuggestions('''
class Map{}class Arrays{}class C{ m(^){} n( x, q)
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  Map
    kind: class
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  void
    kind: keyword
''');
    } else {
      assertResponse(r'''
suggestions
  Map
    kind: class
  Map
    kind: class
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets018_2() async {
    allowedIdentifiers = {'Arrays', 'void', 'null'};
    await computeSuggestions('''
class Map{}class Arrays{}class C{ m(){} n(^ x, q)
''');
    assertResponse(r'''
suggestions
  Arrays
    kind: class
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_commentSnippets019_1() async {
    allowedIdentifiers = {'toString'};
    await computeSuggestions('''
class A{m(){Object x;x.^/**/clear()
''');
    assertResponse(r'''
suggestions
  toString
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets020_1() async {
    allowedIdentifiers = {'newt', 'newf', 'newz', 'Map'};
    await computeSuggestions('''
classMap{}class tst {var newt;void newf(){}test() {var newz;new^/**/;}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
  newf
    kind: methodInvocation
  newt
    kind: field
  newz
    kind: localVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  Map
    kind: class
  Map
    kind: constructorInvocation
  Map.from
    kind: constructorInvocation
  Map.fromEntries
    kind: constructorInvocation
  Map.fromIterable
    kind: constructorInvocation
  Map.fromIterables
    kind: constructorInvocation
  Map.identity
    kind: constructorInvocation
  Map.unmodifiable
    kind: constructorInvocation
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  newf
    kind: methodInvocation
  newt
    kind: field
  newz
    kind: localVariable
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets021_1() async {
    allowedIdentifiers = {'Map', 'newt'};
    await computeSuggestions('''
class Map{}class tst {var newt;void newf(){}test() {var newz;new ^/**/;}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  Map
    kind: constructorInvocation
  Map.from
    kind: constructorInvocation
  Map.fromEntries
    kind: constructorInvocation
  Map.fromIterable
    kind: constructorInvocation
  Map.fromIterables
    kind: constructorInvocation
  Map.identity
    kind: constructorInvocation
  Map.unmodifiable
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
suggestions
  Map
    kind: constructorInvocation
  Map
    kind: constructorInvocation
  Map.from
    kind: constructorInvocation
  Map.fromEntries
    kind: constructorInvocation
  Map.fromIterable
    kind: constructorInvocation
  Map.fromIterables
    kind: constructorInvocation
  Map.identity
    kind: constructorInvocation
  Map.unmodifiable
    kind: constructorInvocation
''');
    }
  }

  Future<void> test_commentSnippets022_1() async {
    allowedIdentifiers = {'Map'};
    await computeSuggestions('''
class Map{}class F{m(){new ^;}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  Map
    kind: constructorInvocation
  Map.from
    kind: constructorInvocation
  Map.fromEntries
    kind: constructorInvocation
  Map.fromIterable
    kind: constructorInvocation
  Map.fromIterables
    kind: constructorInvocation
  Map.identity
    kind: constructorInvocation
  Map.unmodifiable
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
suggestions
  Map
    kind: constructorInvocation
  Map
    kind: constructorInvocation
  Map.from
    kind: constructorInvocation
  Map.fromEntries
    kind: constructorInvocation
  Map.fromIterable
    kind: constructorInvocation
  Map.fromIterables
    kind: constructorInvocation
  Map.identity
    kind: constructorInvocation
  Map.unmodifiable
    kind: constructorInvocation
''');
    }
  }

  Future<void> test_commentSnippets022a_1() async {
    allowedIdentifiers = {'Map'};
    await computeSuggestions('''
class Map{}class F{m(){new ^
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  Map
    kind: constructorInvocation
  Map.from
    kind: constructorInvocation
  Map.fromEntries
    kind: constructorInvocation
  Map.fromIterable
    kind: constructorInvocation
  Map.fromIterables
    kind: constructorInvocation
  Map.identity
    kind: constructorInvocation
  Map.unmodifiable
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
suggestions
  Map
    kind: constructorInvocation
  Map
    kind: constructorInvocation
  Map.from
    kind: constructorInvocation
  Map.fromEntries
    kind: constructorInvocation
  Map.fromIterable
    kind: constructorInvocation
  Map.fromIterables
    kind: constructorInvocation
  Map.identity
    kind: constructorInvocation
  Map.unmodifiable
    kind: constructorInvocation
''');
    }
  }

  Future<void> test_commentSnippets022b_1() async {
    allowedIdentifiers = {'qq'};
    await computeSuggestions('''
class Map{factory Map.qq(){return null;}}class F{m(){new Map.^qq();}}
''');
    assertResponse(r'''
replacement
  right: 2
suggestions
  qq
    kind: constructorInvocation
''');
  }

  Future<void> test_commentSnippets023_1() async {
    allowedIdentifiers = {'c'};
    await computeSuggestions('''
class X {X c; X(this.^c) : super() {c.}}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  c
    kind: field
''');
  }

  Future<void> test_commentSnippets023_2() async {
    allowedIdentifiers = {'c'};
    await computeSuggestions('''
class X {X c; X(this.c) : super() {c.^}}
''');
    assertResponse(r'''
suggestions
  c
    kind: field
''');
  }

  Future<void> test_commentSnippets023_3() async {
    allowedIdentifiers = {'c'};
    await computeSuggestions('''
class X {X c; X(this.c^) : super() {c.}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  c
    kind: field
''');
  }

  Future<void> test_commentSnippets024_1() async {
    allowedIdentifiers = {'x'};
    await computeSuggestions('''
class q {m(Map q){var x;m(^)}n(){var x;n()}}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
  x
    kind: localVariable
''');
  }

  Future<void> test_commentSnippets024_2() async {
    allowedIdentifiers = {'x'};
    await computeSuggestions('''
class q {m(Map q){var x;m()}n(){var x;n(^)}}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_commentSnippets025_1() async {
    allowedIdentifiers = {'q'};
    await computeSuggestions('''
class C {num m() {var q; num x=^ q + /**/;}}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  q
    kind: localVariable
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_commentSnippets025_2() async {
    allowedIdentifiers = {'q'};
    await computeSuggestions('''
class C {num m() {var q; num x= q + ^/**/;}}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  q
    kind: localVariable
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_commentSnippets025_3() async {
    allowedIdentifiers = {'q'};
    await computeSuggestions('''
class C {num m() {var q; num x= q^ + /**/;}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  q
    kind: localVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  q
    kind: localVariable
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets026_1() async {
    allowedIdentifiers = {'List'};
    await computeSuggestions('''
class List{}class a implements ^{}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  List
    kind: class
  dynamic
    kind: keyword
  void
    kind: keyword
''');
    } else {
      assertResponse(r'''
suggestions
  List
    kind: class
  List
    kind: class
  dynamic
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets027_1() async {
    allowedIdentifiers = {'List'};
    await computeSuggestions('''
class String{}class List{}class test <X extends ^String> {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  right: 6
suggestions
  List
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  right: 6
suggestions
  List
    kind: class
  List
    kind: class
''');
    }
  }

  Future<void> test_commentSnippets027_2() async {
    allowedIdentifiers = {'String', 'List'};
    await computeSuggestions('''
class String{}class List{}class test <X extends String^> {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 6
suggestions
  String
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 6
suggestions
  List
    kind: class
  List
    kind: class
  String
    kind: class
  String
    kind: class
''');
    }
  }

  Future<void> test_commentSnippets028_1() async {
    allowedIdentifiers = {'DateTime', 'String'};
    await computeSuggestions('''
class String{}class List{}class DateTime{}typedef T Y<T extends ^>(List input);
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  DateTime
    kind: class
  String
    kind: class
''');
    } else {
      assertResponse(r'''
suggestions
  DateTime
    kind: class
  DateTime
    kind: class
  String
    kind: class
  String
    kind: class
''');
    }
  }

  Future<void> test_commentSnippets029_1() async {
    allowedIdentifiers = {'DateTime'};
    await computeSuggestions('''
interface A<X> default B<X extends ^List> {}
''');
    assertResponse(r'''
replacement
  right: 4
suggestions
  DateTime
    kind: class
''');
  }

  Future<void> test_commentSnippets029_2() async {
    allowedIdentifiers = {'List'};
    await computeSuggestions('''
interface A<X> default B<X extends List^> {}
''');
    assertResponse(r'''
replacement
  left: 4
suggestions
  List
    kind: class
''');
  }

  Future<void> test_commentSnippets030_1() async {
    allowedIdentifiers = {'T'};
    await computeSuggestions('''
class Bar<T extends Foo> {const Bar(^T k);T m(T a, T b){}final T f = null;}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  T
    kind: typeParameter
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  super
    kind: keyword
  this
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_commentSnippets030_2() async {
    allowedIdentifiers = {'T'};
    await computeSuggestions('''
class Bar<T extends Foo> {const Bar(T^ k);T m(T a, T b){}final T f = null;}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  T
    kind: typeParameter
  this
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  T
    kind: typeParameter
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  super
    kind: keyword
  this
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets030_3() async {
    allowedIdentifiers = {'T'};
    await computeSuggestions('''
class Bar<T extends Foo> {const Bar(T k);T^ m(T a, T b){}final T f = null;}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  T
    kind: typeParameter
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  T
    kind: typeParameter
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets030_4() async {
    allowedIdentifiers = {'T'};
    await computeSuggestions('''
class Bar<T extends Foo> {const Bar(T k);T m(T^ a, T b){}final T f = null;}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  T
    kind: typeParameter
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  T
    kind: typeParameter
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets030_5() async {
    allowedIdentifiers = {'T'};
    await computeSuggestions('''
class Bar<T extends Foo> {const Bar(T k);T m(T a, T^ b){}final T f = null;}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  T
    kind: typeParameter
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  T
    kind: typeParameter
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets030_6() async {
    allowedIdentifiers = {'T'};
    await computeSuggestions('''
class Bar<T extends Foo> {const Bar(T k);T m(T a, T b){}final T^ f = null;}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  T
    kind: typeParameter
''');
  }

  Future<void> test_commentSnippets031_1() async {
    allowedIdentifiers = {'Bar', 'T'};
    await computeSuggestions('''
class Bar<T extends Foo> {m(x){if (x is ^) return;if (x is!)}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  Bar
    kind: class
  T
    kind: typeParameter
''');
    } else {
      assertResponse(r'''
suggestions
  Bar
    kind: class
  T
    kind: typeParameter
''');
    }
  }

  Future<void> test_commentSnippets031_2() async {
    allowedIdentifiers = {'T', 'Bar'};
    await computeSuggestions('''
class Bar<T extends Foo> {m(x){if (x is ) return;if (x is!^)}}
''');
    assertResponse(r'''
suggestions
  Bar
    kind: class
  T
    kind: typeParameter
''');
  }

  Future<void> test_commentSnippets032_1() async {
    allowedIdentifiers = {'Fit', 'Fara', 'Bar'};
    await computeSuggestions('''
class Fit{}class Bar<T extends Fooa> {const F^ara();}
''');
    if (isProtocolVersion2) {
      assertResponse('''
replacement
  left: 1
  right: 3
suggestions
  Fit
    kind: class
  factory
    kind: keyword
  final
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
  right: 3
suggestions
  Bar
    kind: class
  Fit
    kind: class
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets032_2() async {
    allowedIdentifiers = {'Fit'};
    await computeSuggestions('''
class Fit{}class Bar<T extends Fooa> {const ^Fara();}
''');
    assertResponse(r'''
replacement
  right: 4
suggestions
  Fit
    kind: class
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_commentSnippets033_1() async {
    allowedIdentifiers = {'add', 'length'};
    await computeSuggestions('''
class List{add(){}length(){}}t1() {var x;if (x is List) {x.^add(3);}}
''');
    assertResponse(r'''
replacement
  right: 3
suggestions
  add
    kind: methodInvocation
  length
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets035_1() async {
    allowedIdentifiers = {'length'};
    await computeSuggestions('''
class List{clear(){}length(){}}t3() {var x=[], y=x.^length();x.clear();}
''');
    assertResponse(r'''
replacement
  right: 6
suggestions
  length
    kind: getter
''');
  }

  Future<void> test_commentSnippets035_2() async {
    allowedIdentifiers = {'clear'};
    await computeSuggestions('''
class List{clear(){}length(){}}t3() {var x=[], y=x.length();x.^clear();}
''');
    assertResponse(r'''
replacement
  right: 5
suggestions
  clear
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets036_1() async {
    allowedIdentifiers = {'List'};
    await computeSuggestions('''
class List{}t3() {var x=new List^}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 4
suggestions
  List
    kind: constructorInvocation
  List.empty
    kind: constructorInvocation
  List.generate
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 4
suggestions
  List
    kind: constructorInvocation
  List.empty
    kind: constructorInvocation
  List.filled
    kind: constructorInvocation
  List.from
    kind: constructorInvocation
  List.generate
    kind: constructorInvocation
  List.of
    kind: constructorInvocation
  List.unmodifiable
    kind: constructorInvocation
''');
    }
  }

  Future<void> test_commentSnippets037_1() async {
    allowedIdentifiers = {'from'};
    await computeSuggestions('''
class List{factory List.from(){}}t3() {var x=new List.^}
''');
    assertResponse(r'''
suggestions
  from
    kind: constructorInvocation
''');
  }

  Future<void> test_commentSnippets038_1() async {
    allowedIdentifiers = {'xa'};
    await computeSuggestions('''
f(){int xa; String s = '\$x^';}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  xa
    kind: localVariable
''');
  }

  Future<void> test_commentSnippets038a_1() async {
    allowedIdentifiers = {'xa'};
    await computeSuggestions('''
int xa; String s = '\$x^'
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  xa
    kind: topLevelVariable
''');
  }

  Future<void> test_commentSnippets039_1() async {
    allowedIdentifiers = {'xa'};
    await computeSuggestions('''
f(){int xa; String s = '\$^';}
''');
    assertResponse(r'''
suggestions
  xa
    kind: localVariable
''');
  }

  Future<void> test_commentSnippets039a_1() async {
    allowedIdentifiers = {'xa'};
    await computeSuggestions('''
int xa; String s = '\$^'
''');
    assertResponse(r'''
suggestions
  xa
    kind: topLevelVariable
''');
  }

  Future<void> test_commentSnippets040_1() async {
    allowedIdentifiers = {'add'};
    await computeSuggestions('''
class List{add(){}}class Map{}class X{m(){List list; list.^ Map map;}}
''');
    assertResponse(r'''
suggestions
  add
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets041_1() async {
    allowedIdentifiers = {'add'};
    await computeSuggestions('''
class List{add(){}length(){}}class X{m(){List list; list.^ zox();}}
''');
    assertResponse(r'''
suggestions
  add
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets042_1() async {
    allowedIdentifiers = {'day'};
    await computeSuggestions('''
class DateTime{static const int WED=3;int get day;}fd(){DateTime d=new DateTime.now();d.^WED;}
''');
    assertResponse(r'''
replacement
  right: 3
suggestions
  day
    kind: getter
''');
  }

  Future<void> test_commentSnippets042_2() async {
    allowedIdentifiers = {'WED'};
    await computeSuggestions('''
class DateTime{static const int WED=3;int get day;}fd(){DateTime d=new DateTime.now();d.WED^;}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
''');
  }

  Future<void> test_commentSnippets043_1() async {
    allowedIdentifiers = {'k'};
    await computeSuggestions('''
class L{var k;void.^}
''');
    assertResponse(r'''
suggestions
  abstract
    kind: keyword
  covariant
    kind: keyword
  external
    kind: keyword
  late
    kind: keyword
  static
    kind: keyword
''');
  }

  Future<void> test_commentSnippets044_1() async {
    allowedIdentifiers = {'List', 'XXX', 'fisk'};
    await computeSuggestions('''
class List{}class XXX {XXX.fisk();}void f() {f(); new ^}}
''');
    assertResponse(r'''
suggestions
  List
    kind: constructorInvocation
  List.empty
    kind: constructorInvocation
  List.filled
    kind: constructorInvocation
  List.from
    kind: constructorInvocation
  List.generate
    kind: constructorInvocation
  List.of
    kind: constructorInvocation
  List.unmodifiable
    kind: constructorInvocation
  XXX.fisk
    kind: constructorInvocation
''');
  }

  Future<void> test_commentSnippets045_1() async {
    allowedIdentifiers = {'List', 'XXX', 'fisk'};
    await computeSuggestions('''
class List{}class XXX {XXX.fisk();}void f() {f(); ^}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  List
    kind: class
  List
    kind: constructorInvocation
  List.empty
    kind: constructorInvocation
  List.filled
    kind: constructorInvocation
  List.from
    kind: constructorInvocation
  List.generate
    kind: constructorInvocation
  List.of
    kind: constructorInvocation
  List.unmodifiable
    kind: constructorInvocation
  XXX
    kind: class
  XXX.fisk
    kind: constructorInvocation
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
    } else {
      assertResponse(r'''
suggestions
  List
    kind: class
  List
    kind: class
  List
    kind: constructorInvocation
  List.empty
    kind: constructorInvocation
  List.filled
    kind: constructorInvocation
  List.from
    kind: constructorInvocation
  List.generate
    kind: constructorInvocation
  List.of
    kind: constructorInvocation
  List.unmodifiable
    kind: constructorInvocation
  XXX
    kind: class
  XXX.fisk
    kind: constructorInvocation
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets047_1() async {
    allowedIdentifiers = {'x'};
    await computeSuggestions('''
f(){int x;int y=^;}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
  x
    kind: localVariable
''');
  }

  Future<void> test_commentSnippets048_1() async {
    allowedIdentifiers = {'json'};
    await computeSuggestions('''
import 'dart:convert' as json;f() {var x=new js^}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  json
    kind: library
  json.JsonCodec
    kind: constructorInvocation
  json.JsonDecoder
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  json
    kind: library
''');
    }
  }

  Future<void> test_commentSnippets049_1() async {
    allowedIdentifiers = {'json', 'jxx'};
    await computeSuggestions('''
import 'dart:convert' as json;
import 'dart:convert' as jxx;
class JsonDecoderX{}
f1() {var x=new j^s}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
  right: 1
suggestions
  json
    kind: library
  json.JsonCodec
    kind: constructorInvocation
  json.JsonDecoder
    kind: constructorInvocation
  jxx
    kind: library
  jxx.JsonCodec
    kind: constructorInvocation
  jxx.JsonDecoder
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
  right: 1
suggestions
  json
    kind: library
  jxx
    kind: library
''');
    }
  }

  Future<void> test_commentSnippets049_2() async {
    allowedIdentifiers = {'json', 'jxx', 'JsonDecoder'};
    await computeSuggestions('''
import 'dart:convert' as json;
import 'dart:convert' as jxx;
class JsonDecoderX{}
f1() {var x=new ^js}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  right: 2
suggestions
  json
    kind: library
  json.JsonCodec
    kind: constructorInvocation
  json.JsonDecoder
    kind: constructorInvocation
  jxx
    kind: library
  jxx.JsonCodec
    kind: constructorInvocation
  jxx.JsonDecoder
    kind: constructorInvocation
''');
    } else {
      // TODO(brianwilkerson) We should not be suggesting 'JsonDecoder'.
      assertResponse(r'''
replacement
  right: 2
suggestions
  JsonDecoder
    kind: constructorInvocation
  json
    kind: library
  jxx
    kind: library
''');
    }
  }

  Future<void> test_commentSnippets049_3() async {
    allowedIdentifiers = {'json', 'jxx'};
    await computeSuggestions('''
import 'dart:convert' as json;
import 'dart:convert' as jxx;
class JsonDecoderX{}
f1() {var x=new js^}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  json
    kind: library
  json.JsonCodec
    kind: constructorInvocation
  json.JsonDecoder
    kind: constructorInvocation
  jxx.JsonCodec
    kind: constructorInvocation
  jxx.JsonDecoder
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  json
    kind: library
  jxx
    kind: library
''');
    }
  }

  Future<void> test_commentSnippets050_1() async {
    allowedIdentifiers = {'xdr', 'xa', 'a', 'b'};
    await computeSuggestions('''
class xdr {
  xdr();
  const xdr.a(a,b,c);
  xdr.b();
  f() => 3;
}
class xa{}
k() {
  new x^dr().f();
  const xdr.a(1, 2, 3);
}
''');
    if (isProtocolVersion2) {
      // TODO(brianwilkerson) We ought to be suggesting 'xdr.a' and 'xdr.b'.
      assertResponse(r'''
replacement
  left: 1
  right: 2
suggestions
  xa
    kind: constructorInvocation
  xdr
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
  right: 2
suggestions
  xa
    kind: constructorInvocation
  xdr
    kind: constructorInvocation
  xdr.a
    kind: constructorInvocation
  xdr.b
    kind: constructorInvocation
''');
    }
  }

  Future<void> test_commentSnippets050_2() async {
    allowedIdentifiers = {'xa', 'xdr', 'a', 'b'};
    await computeSuggestions('''
class xdr {
  xdr();
  const xdr.a(a,b,c);
  xdr.b();
  f() => 3;
}
class xa{}
k() {
  new xdr().f();
  const x^dr.a(1, 2, 3);
}
''');
    if (isProtocolVersion2) {
      // TODO(brianwilkerson) We ought to be suggesting 'xdr.a' and 'xdr.b'.
      assertResponse(r'''
replacement
  left: 1
  right: 2
suggestions
  xa
    kind: constructorInvocation
  xdr
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
  right: 2
suggestions
  xa
    kind: constructorInvocation
  xdr
    kind: constructorInvocation
  xdr.a
    kind: constructorInvocation
  xdr.b
    kind: constructorInvocation
''');
    }
  }

  Future<void> test_commentSnippets050_3() async {
    allowedIdentifiers = {'b', 'a'};
    await computeSuggestions('''
class xdr {
  xdr();
  const xdr.a(a,b,c);
  xdr.b();
  f() => 3;
}
class xa{}
k() {
  new xdr().f();
  const xdr.^a(1, 2, 3);
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  a
    kind: constructorInvocation
  b
    kind: constructorInvocation
''');
  }

  Future<void> test_commentSnippets051_1() async {
    allowedIdentifiers = {'length'};
    await computeSuggestions('''
class String{int length(){} String toUpperCase(){} bool isEmpty(){}}class Map{getKeys(){}}
void r() {
  var v;
  if (v is String) {
    v.^length;
    v.getKeys;
  }
}
''');
    assertResponse(r'''
replacement
  right: 6
suggestions
  length
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets051_2() async {
    allowedIdentifiers = {'getKeys'};
    await computeSuggestions('''
class String{int length(){} String toUpperCase(){} bool isEmpty(){}}class Map{getKeys(){}}
void r() {
  var v;
  if (v is String) {
    v.length;
    v.^getKeys;
  }
}
''');
    assertResponse(r'''
replacement
  right: 7
suggestions
''');
  }

  Future<void> test_commentSnippets052_1() async {
    allowedIdentifiers = {'toUpperCase'};
    await computeSuggestions('''
class String{int length(){} String toUpperCase(){} bool isEmpty(){}}class Map{getKeys(){}}
void r() {
  List<String> values = ['a','b','c'];
  for (var v in values) {
    v.^toUpperCase;
    v.getKeys;
  }
}
''');
    assertResponse(r'''
replacement
  right: 11
suggestions
  toUpperCase
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets052_2() async {
    allowedIdentifiers = {'getKeys'};
    await computeSuggestions('''
class String{int length(){} String toUpperCase(){} bool isEmpty(){}}class Map{getKeys(){}}
void r() {
  List<String> values = ['a','b','c'];
  for (var v in values) {
    v.toUpperCase;
    v.^getKeys;
  }
}
''');
    assertResponse(r'''
replacement
  right: 7
suggestions
''');
  }

  Future<void> test_commentSnippets055_1() async {
    allowedIdentifiers = {'toUpperCase'};
    await computeSuggestions('''
class String{int length(){} String toUpperCase(){} bool isEmpty(){}}class Map{getKeys(){}}
void r() {
  String v;
  if (v is Object) {
    v.^toUpperCase;
  }
}
''');
    assertResponse(r'''
replacement
  right: 11
suggestions
  toUpperCase
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets058_1() async {
    allowedIdentifiers = {'v'};
    await computeSuggestions('''
typedef void callback(int k);
void x(callback q){}
void r() {
  callback v;
  x(^);
}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
  v
    kind: localVariable
''');
  }

  @failingTest
  Future<void> test_commentSnippets058_2() async {
    await computeSuggestions('''
typedef vo^id callback(int k);
void x(callback q){}
void r() {
  callback v;
  x();
}
''');
    assertResponse(r'''
replacement
  left: 2
  right: 2
suggestions
  void
    kind: keyword
''');
  }

  Future<void> test_commentSnippets060_1() async {
    allowedIdentifiers = {'x'};
    await computeSuggestions('''
class Map{}
abstract class MM extends Map{factory MM() => new Map();}
class Z {
  MM x;
  f() {
    x^
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  x
    kind: field
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
  x
    kind: field
''');
    }
  }

  Future<void> test_commentSnippets061_1() async {
    allowedIdentifiers = {'f', 'n'};
    await computeSuggestions('''
class A{m(){^f(3);}}n(){f(3);}f(x)=>x*3;
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  f
    kind: functionInvocation
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  n
    kind: functionInvocation
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_commentSnippets061_2() async {
    allowedIdentifiers = {'f', 'n'};
    await computeSuggestions('''
class A{m(){f(3);^}}n(){f(3);}f(x)=>x*3;
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  f
    kind: functionInvocation
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  n
    kind: functionInvocation
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_commentSnippets061_3() async {
    allowedIdentifiers = {'f', 'n'};
    await computeSuggestions('''
class A{m(){f(3);}}n(){^f(3);}f(x)=>x*3;
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  f
    kind: functionInvocation
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  n
    kind: functionInvocation
  null
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_commentSnippets061_4() async {
    allowedIdentifiers = {'f', 'n'};
    await computeSuggestions('''
class A{m(){f(3);}}n(){f(3);^}f(x)=>x*3;
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  f
    kind: functionInvocation
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  n
    kind: functionInvocation
  null
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_commentSnippets064_1() async {
    allowedIdentifiers = {'a', 'g'};
    await computeSuggestions('''
class Spline {
  Line c;
  Spline a() {
    return this;
  }
  Line b() {
    return null;
  }
  Spline f() {
    Line x = new Line();
    x.h()..^a()..b().g();
    x.j..b()..c..c..a();
  }
}
class Line {
  Spline j;
  Line g() {
    return this;
  }
  Spline h() {
    return null;
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  a
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets064_2() async {
    allowedIdentifiers = {'b', 'h'};
    await computeSuggestions('''
class Spline {
  Line c;
  Spline a() {
    return this;
  }
  Line b() {
    return null;
  }
  Spline f() {
    Line x = new Line();
    x.h()..a()..^b().g();
    x.j..b()..c..c..a();
  }
}
class Line {
  Spline j;
  Line g() {
    return this;
  }
  Spline h() {
    return null;
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  b
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets064_3() async {
    allowedIdentifiers = {'b'};
    await computeSuggestions('''
class Spline {
  Line c;
  Spline a() {
    return this;
  }
  Line b() {
    return null;
  }
  Spline f() {
    Line x = new Line();
    x.h()..a()..b().g();
    x.j..^b()..c..c..a();
  }
}
class Line {
  Spline j;
  Line g() {
    return this;
  }
  Spline h() {
    return null;
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  b
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets064_4() async {
    allowedIdentifiers = {'c'};
    await computeSuggestions('''
class Spline {
  Line c;
  Spline a() {
    return this;
  }
  Line b() {
    return null;
  }
  Spline f() {
    Line x = new Line();
    x.h()..a()..b().g();
    x.j..b()..^c..c..a();
  }
}
class Line {
  Spline j;
  Line g() {
    return this;
  }
  Spline h() {
    return null;
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  c
    kind: field
''');
  }

  Future<void> test_commentSnippets064_5() async {
    allowedIdentifiers = {'a'};
    await computeSuggestions('''
class Spline {
  Line c;
  Spline a() {
    return this;
  }
  Line b() {
    return null;
  }
  Spline f() {
    Line x = new Line();
    x.h()..a()..b().g();
    x.j..b()..c..c..^a();
  }
}
class Line {
  Spline j;
  Line g() {
    return this;
  }
  Spline h() {
    return null;
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  a
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets064_6() async {
    allowedIdentifiers = {'c'};
    await computeSuggestions('''
class Spline {
  Line c;
  Spline a() {
    return this;
  }
  Line b() {
    return null;
  }
  Spline f() {
    Line x = new Line();
    x.h()..a()..b().g();
    x.j..b()..c..^c..a();
  }
}
class Line {
  Spline j;
  Line g() {
    return this;
  }
  Spline h() {
    return null;
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  c
    kind: field
''');
  }

  Future<void> test_commentSnippets064_7() async {
    allowedIdentifiers = {'g'};
    await computeSuggestions('''
class Spline {
  Line c;
  Spline a() {
    return this;
  }
  Line b() {
    return null;
  }
  Spline f() {
    Line x = new Line();
    x.h()..a()..b().^g();
    x.j..b()..c..c..a();
  }
}
class Line {
  Spline j;
  Line g() {
    return this;
  }
  Spline h() {
    return null;
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  g
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets064_8() async {
    allowedIdentifiers = {'j'};
    await computeSuggestions('''
class Spline {
  Line c;
  Spline a() {
    return this;
  }
  Line b() {
    return null;
  }
  Spline f() {
    Line x = new Line();
    x.h()..a()..b().g();
    x.^j..b()..c..c..a();
  }
}
class Line {
  Spline j;
  Line g() {
    return this;
  }
  Spline h() {
    return null;
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  j
    kind: field
''');
  }

  Future<void> test_commentSnippets064_9() async {
    allowedIdentifiers = {'h'};
    await computeSuggestions('''
class Spline {
  Line c;
  Spline a() {
    return this;
  }
  Line b() {
    return null;
  }
  Spline f() {
    Line x = new Line();
    x.^h()..a()..b().g();
    x.j..b()..c..c..a();
  }
}
class Line {
  Spline j;
  Line g() {
    return this;
  }
  Spline h() {
    return null;
  }
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  h
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets065_1() async {
    allowedIdentifiers = {'a'};
    await computeSuggestions('''
class Spline {
  Line c;
  Spline a() {
    return this;
  }
  Line b() {
    return null;
  }
  Spline f() {
    Line x = new Line();
    x.h()..^;
  }
}
class Line {
  Spline j;
  Line g() {
    return this;
  }
  Spline h() {
    return null;
  }
}
''');
    assertResponse(r'''
suggestions
  a
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets066_1() async {
    allowedIdentifiers = {'b'};
    await computeSuggestions('''
class Spline {
  Line c;
  Spline a() {
    return this;
  }
  Line b() {
    return null;
  }
  Spline f() {
    Line x = new Line();
    x.h()..a()..^;
  }
}
class Line {
  Spline j;
  Line g() {
    return this;
  }
  Spline h() {
    return null;
  }
}
''');
    assertResponse(r'''
suggestions
  b
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets067_1() async {
    allowedIdentifiers = {'b'};
    await computeSuggestions('''
class Spline {
  Line c;
  Spline a() {
    return this;
  }
  Line b() {
    return null;
  }
  Spline f() {
    Line x = new Line();
    x.h()..a()..c..^;
  }
}
class Line {
  Spline j;
  Line g() {
    return this;
  }
  Spline h() {
    return null;
  }
}
''');
    assertResponse(r'''
suggestions
  b
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets068_1() async {
    allowedIdentifiers = {'c'};
    await computeSuggestions('''
class Spline {
  Line c;
  Spline a() {
    return this;
  }
  Line b() {
    return null;
  }
  Spline f() {
    Line x = new Line();
    x.j..b()..c..^;
  }
}
class Line {
  Spline j;
  Line g() {
    return this;
  }
  Spline h() {
    return null;
  }
}
''');
    assertResponse(r'''
suggestions
  c
    kind: field
''');
  }

  Future<void> test_commentSnippets069_1() async {
    allowedIdentifiers = {'c'};
    await computeSuggestions('''
class Spline {
  Line c;
  Spline a() {
    return this;
  }
  Line b() {
    return null;
  }
  Spline f() {
    Line x = new Line();
    x.j..b()..^;
  }
}
class Line {
  Spline j;
  Line g() {
    return this;
  }
  Spline h() {
    return null;
  }
}
''');
    assertResponse(r'''
suggestions
  c
    kind: field
''');
  }

  Future<void> test_commentSnippets070_1() async {
    allowedIdentifiers = {'b'};
    await computeSuggestions('''
class Spline {
  Line c;
  Spline a() {
    return this;
  }
  Line b() {
    return null;
  }
  Spline f() {
    Line x = new Line();
    x.j..^;
  }
}
class Line {
  Spline j;
  Line g() {
    return this;
  }
  Spline h() {
    return null;
  }
}
''');
    assertResponse(r'''
suggestions
  b
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets072_1() async {
    allowedIdentifiers = {'p'};
    await computeSuggestions('''
class X {
  int _p;
  set p(int x) => _p = x;
}
f() {
  X x = new X();
  x.^p = 3;
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  p
    kind: setter
''');
  }

  Future<void> test_commentSnippets073_1() async {
    allowedIdentifiers = {'stringify'};
    await computeSuggestions('''
class X {
  m() {
    JSON.stri^;
    X f = null;
  }
}
class JSON {
  static stringify() {}
}
''');
    assertResponse(r'''
replacement
  left: 4
suggestions
  stringify
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets074_1() async {
    allowedIdentifiers = {'_x1'};
    await computeSuggestions('''
class X {
  m() {
    _x^
  }
  _x1(){}
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  _x1
    kind: methodInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  _x1
    kind: methodInvocation
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets075_1() async {
    allowedIdentifiers = {'p'};
    await computeSuggestions('''
p(x)=>0;var E;f(q)=>^p(E);
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  p
    kind: functionInvocation
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_commentSnippets075_2() async {
    allowedIdentifiers = {'E'};
    await computeSuggestions('''
p(x)=>0;var E;f(q)=>p(^E);
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  E
    kind: topLevelVariable
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_commentSnippets076_1() async {
    allowedIdentifiers = {'List'};
    await computeSuggestions('''
class Map<K,V>{}class List<E>{}class int{}void f() {var m=new Map<Lis^t<Map<int,int>>,List<int>>();}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
  right: 1
suggestions
  List
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
  right: 1
suggestions
  List
    kind: class
  List
    kind: class
  dynamic
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets076_2() async {
    allowedIdentifiers = {'int'};
    await computeSuggestions('''
class Map<K,V>{}class List<E>{}class int{}void f() {var m=new Map<List<Map<int,in^t>>,List<int>>();}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
  right: 1
suggestions
  int
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
  right: 1
suggestions
  dynamic
    kind: keyword
  int
    kind: class
  int
    kind: class
  void
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets076_3() async {
    allowedIdentifiers = {'int'};
    await computeSuggestions('''
class Map<K,V>{}class List<E>{}class int{}void f() {var m=new Map<List<Map<int,int>>,List<^int>>();}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  right: 3
suggestions
  dynamic
    kind: keyword
  int
    kind: class
  void
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  right: 3
suggestions
  dynamic
    kind: keyword
  int
    kind: class
  int
    kind: class
  void
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets076a_1() async {
    allowedIdentifiers = {'List'};
    await computeSuggestions('''
class Map<K,V>{}class List<E>{}class int{}void f() {var m=new Map<Lis^t<Map<int,int>>,List<>>();}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
  right: 1
suggestions
  List
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
  right: 1
suggestions
  List
    kind: class
  List
    kind: class
  dynamic
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets076a_2() async {
    allowedIdentifiers = {'int'};
    await computeSuggestions('''
class Map<K,V>{}class List<E>{}class int{}void f() {var m=new Map<List<Map<int,in^t>>,List<>>();}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
  right: 1
suggestions
  int
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
  right: 1
suggestions
  dynamic
    kind: keyword
  int
    kind: class
  int
    kind: class
  void
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets076a_3() async {
    allowedIdentifiers = {'int'};
    await computeSuggestions('''
class Map<K,V>{}class List<E>{}class int{}void f() {var m=new Map<List<Map<int,int>>,List<^>>();}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  dynamic
    kind: keyword
  int
    kind: class
  void
    kind: keyword
''');
    } else {
      assertResponse(r'''
suggestions
  dynamic
    kind: keyword
  int
    kind: class
  int
    kind: class
  void
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets077_1() async {
    allowedIdentifiers = {
      'File',
      'fromPath',
      'FileMode',
      '_internal1',
      '_internal'
    };
    await computeSuggestions('''
class FileMode {
  static const READ = const FileMode._internal(0);
  static const WRITE = const FileMode._internal(1);
  static const APPEND = const FileMode._internal(2);
  const FileMode._internal(int this._mode);
  factory FileMode._internal1(int this._mode);
  factory FileMode(_mode);
  final int _mode;
}
class File {
  File(String path);
  File.fromPath(Path path);
}
f() => new Fil^
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
  File
    kind: constructorInvocation
  FileMode
    kind: constructorInvocation
  FileMode._internal
    kind: constructorInvocation
  FileMode._internal1
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  File
    kind: constructorInvocation
  File
    kind: constructorInvocation
  File
    kind: constructorInvocation
  File.fromPath
    kind: constructorInvocation
  FileMode
    kind: constructorInvocation
  FileMode._internal
    kind: constructorInvocation
  FileMode._internal1
    kind: constructorInvocation
''');
    }
  }

  Future<void> test_commentSnippets078_1() async {
    allowedIdentifiers = {'from', 'clear'};
    await computeSuggestions('''
class Map{static from()=>null;clear(){}}void f() { Map.^ }
''');
    assertResponse(r'''
suggestions
  from
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets079_1() async {
    allowedIdentifiers = {'clear', 'from'};
    await computeSuggestions('''
class Map{static from()=>null;clear(){}}void f() { Map s; s.^ }
''');
    assertResponse(r'''
suggestions
  clear
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets080_1() async {
    allowedIdentifiers = {'message'};
    await computeSuggestions('''
class RuntimeError{var message;}void f() { RuntimeError.^ }
''');
    assertResponse(r'''
suggestions
''');
  }

  @failingTest
  Future<void> test_commentSnippets081_1() async {
    allowedIdentifiers = {'Object'};
    await computeSuggestions('''
class Foo {this.^}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  @failingTest
  Future<void> test_commentSnippets082_1() async {
    allowedIdentifiers = {'HttpResponse'};
    await computeSuggestions('''
        class HttpRequest {}
        class HttpResponse {}
        void f() {
          var v = (HttpRequest req, HttpResp^)
        }
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 8
suggestions
  HttpResponse
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 8
suggestions
  HttpResponse
    kind: class
''');
    }
  }

  Future<void> test_commentSnippets083_1() async {
    allowedIdentifiers = {'toString'};
    await computeSuggestions('''
void f() {(.^)}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_commentSnippets083a_1() async {
    allowedIdentifiers = {'toString'};
    await computeSuggestions('''
void f() { .^ }
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_commentSnippets083b_1() async {
    allowedIdentifiers = {'toString'};
    await computeSuggestions('''
void f() { null.^ }
''');
    assertResponse(r'''
suggestions
  toString
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets085_1() async {
    allowedIdentifiers = {'List', 'Map'};
    await computeSuggestions('''
class List{}class Map{}class Z extends List with ^Map {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  right: 3
suggestions
  List
    kind: class
  Map
    kind: class
  dynamic
    kind: keyword
  void
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  right: 3
suggestions
  List
    kind: class
  List
    kind: class
  Map
    kind: class
  Map
    kind: class
  dynamic
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets085_2() async {
    allowedIdentifiers = {'Map', 'List'};
    await computeSuggestions('''
class List{}class Map{}class Z extends List with Ma^p {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
  right: 1
suggestions
  Map
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
  right: 1
suggestions
  List
    kind: class
  List
    kind: class
  Map
    kind: class
  Map
    kind: class
  dynamic
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets086_1() async {
    allowedIdentifiers = {'xy'};
    await computeSuggestions('''
class Q{f(){xy() {};x^y();}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
  right: 1
suggestions
  xy
    kind: functionInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
  right: 1
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
  xy
    kind: functionInvocation
''');
    }
  }

  Future<void> test_commentSnippets086_2() async {
    allowedIdentifiers = {'f', 'xy'};
    await computeSuggestions('''
class Q{f(){xy() {^};xy();}}
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  f
    kind: methodInvocation
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
  xy
    kind: functionInvocation
''');
  }

  Future<void> test_commentSnippets087_1() async {
    allowedIdentifiers = {'Map', 'HashMap'};
    await computeSuggestions('''
class Map{}class Q extends Object with ^Map {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  right: 3
suggestions
  Map
    kind: class
  dynamic
    kind: keyword
  void
    kind: keyword
''');
    } else {
      // TODO(brianwilkerson) Don't suggest 'HashMap'.
      assertResponse(r'''
replacement
  right: 3
suggestions
  HashMap
    kind: class
  Map
    kind: class
  Map
    kind: class
  dynamic
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_commentSnippets088_1() async {
    allowedIdentifiers = {'f', 'm'};
    await computeSuggestions('''
class A {
  int f;
  B m(){}
}
class B extends A {
  num f;
  A m(){}
}
class Z {
  B q;
  f() {q.^}
}
''');
    assertResponse(r'''
suggestions
  f
    kind: field
  m
    kind: methodInvocation
''');
  }

  Future<void> test_commentSnippets089_1() async {
    allowedIdentifiers = {'fqe', 'fqi', 'Q', 'xya', 'xyb', 'xza'};
    await computeSuggestions('''
class Q {
  fqe() {
    xya() {
      xyb() {
        ^
      }
       xyb();
    };
    xza() {

    }
    xya();
    xza();
  }
  fqi() {

  }
}
''');
    assertResponse(r'''
suggestions
  Q
    kind: class
  Q
    kind: constructorInvocation
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  fqe
    kind: methodInvocation
  fqi
    kind: methodInvocation
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
  xya
    kind: functionInvocation
  xyb
    kind: functionInvocation
''');
  }

  Future<void> test_commentSnippets089_2() async {
    allowedIdentifiers = {'fqe', 'fqi', 'Q', 'xya', 'xyb', 'xza'};
    await computeSuggestions('''
class Q {
  fqe() {
    xya() {
      xyb() {

      }
       xyb();
    };
    xza() {
      ^
    }
    xya();
    xza();
  }
  fqi() {

  }
}
''');
    assertResponse(r'''
suggestions
  Q
    kind: class
  Q
    kind: constructorInvocation
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  fqe
    kind: methodInvocation
  fqi
    kind: methodInvocation
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
  xya
    kind: functionInvocation
  xza
    kind: functionInvocation
''');
  }

  Future<void> test_commentSnippets089_3() async {
    allowedIdentifiers = {'fqe', 'fqi', 'Q', 'xyb', 'xya', 'xza'};
    await computeSuggestions('''
class Q {
  fqe() {
    xya() {
      xyb() {

      }
      ^ xyb();
    };
    xza() {

    }
    xya();
    xza();
  }
  fqi() {

  }
}
''');
    assertResponse(r'''
suggestions
  Q
    kind: class
  Q
    kind: constructorInvocation
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  fqe
    kind: methodInvocation
  fqi
    kind: methodInvocation
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
  xya
    kind: functionInvocation
  xyb
    kind: functionInvocation
''');
  }

  Future<void> test_commentSnippets089_4() async {
    allowedIdentifiers = {'fqe', 'fqi', 'Q', 'xya', 'xza', 'xyb'};
    await computeSuggestions('''
class Q {
  fqe() {
    xya() {
      xyb() {

      }
       xyb();
    };
    xza() {

    }
    xya();
    ^ xza();
  }
  fqi() {

  }
}
''');
    assertResponse(r'''
suggestions
  Q
    kind: class
  Q
    kind: constructorInvocation
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  fqe
    kind: methodInvocation
  fqi
    kind: methodInvocation
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
  xya
    kind: functionInvocation
  xza
    kind: functionInvocation
''');
  }

  Future<void> test_commentSnippets089_5() async {
    allowedIdentifiers = {'fqe', 'fqi', 'Q', 'xya', 'xyb', 'xza'};
    await computeSuggestions('''
class Q {
  fqe() {
    xya() {
      xyb() {

      }
       xyb();
    };
    xza() {

    }
    xya();
     xza();
  }
  fqi() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  Q
    kind: class
  Q
    kind: constructorInvocation
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  fqe
    kind: methodInvocation
  fqi
    kind: methodInvocation
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_commentSnippets090_1() async {
    allowedIdentifiers = {'length'};
    await computeSuggestions('''
class X { f() { var a = 'x'; a.^ }}
''');
    assertResponse(r'''
suggestions
  length
    kind: getter
''');
  }

  Future<void> test_completion_alias_field_1() async {
    allowedIdentifiers = {'fnint'};
    await computeSuggestions('''
typedef int fnint(int k); fn^int x;
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
  right: 3
suggestions
  final
    kind: keyword
  fnint
    kind: typeAlias
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
  right: 3
suggestions
  const
    kind: keyword
  external
    kind: keyword
  final
    kind: keyword
  fnint
    kind: typeAlias
  late
    kind: keyword
''');
    }
  }

  @FailingTest(reason: 'The constructor for AAA is not being suggested')
  Future<void> test_completion_annotation_argumentList_1() async {
    allowedIdentifiers = {'AAA', 'aaa', 'bbb'};
    await computeSuggestions('''
class AAA {
  const AAA({int aaa, int bbb});
}

@AAA(^)
void f() {
}
''');
    assertResponse(r'''
suggestions
  AAA
    kind: constructorInvocation
  |aaa: |
    kind: namedArgument
  |bbb: |
    kind: namedArgument
''');
  }

  Future<void> test_completion_annotation_topLevelVar_1() async {
    allowedIdentifiers = {'fooConst', 'fooNotConst', 'bar'};
    await computeSuggestions('''
const fooConst = null;
final fooNotConst = null;
const bar = null;

@foo^
void f() {
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
  fooConst
    kind: topLevelVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  bar
    kind: topLevelVariable
  fooConst
    kind: topLevelVariable
''');
    }
  }

  // resume here
  Future<void> test_completion_annotation_type_1() async {
    allowedIdentifiers = {'AAA', 'nnn'};
    await computeSuggestions('''
class AAA {
  const AAA({int a, int b});
  const AAA.nnn(int c, int d);
}
@AAA^
void f() {
}
''');
    if (isProtocolVersion2) {
      // TODO(brianwilkerson) We should be suggesting the named constructor here.
      assertResponse(r'''
replacement
  left: 3
suggestions
  AAA
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  AAA
    kind: constructorInvocation
  AAA.nnn
    kind: constructorInvocation
''');
    }
  }

  Future<void> test_completion_annotation_type_inClass_withoutMember_1() async {
    allowedIdentifiers = {'AAA'};
    await computeSuggestions('''
class AAA {
  const AAA();
}

class C {
  @A^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  AAA
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  AAA
    kind: constructorInvocation
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_completion_argument_typeName_1() async {
    allowedIdentifiers = {'Enum'};
    await computeSuggestions('''
class Enum {
  static Enum FOO = new Enum();
}
f(Enum e) {}
void f() {
  f(En^);
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  Enum
    kind: class
  Enum
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  Enum
    kind: class
  Enum
    kind: class
  Enum
    kind: constructorInvocation
  Enum
    kind: constructorInvocation
  Enum.FOO
    kind: field
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_completion_arguments_ignoreEmpty_1() async {
    allowedIdentifiers = {'test'};
    await computeSuggestions('''
class A {
  test() {}
}
void f(A a) {
  a.test(^);
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_completion_as_asIdentifierPrefix_1() async {
    allowedIdentifiers = {'asVisible'};
    await computeSuggestions('''
void f(p) {
  var asVisible;
  var v = as^;
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  asVisible
    kind: localVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  asVisible
    kind: localVariable
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_completion_as_asPrefixedIdentifierStart_1() async {
    allowedIdentifiers = {'asVisible'};
    await computeSuggestions('''
class A {
  var asVisible;
}

void f(A p) {
  var v = p.as^;
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  asVisible
    kind: field
''');
  }

  Future<void> test_completion_as_incompleteStatement_1() async {
    allowedIdentifiers = {'MyClass', 'justSomeVar'};
    await computeSuggestions('''
class MyClass {}
void f(p) {
  var justSomeVar;
  var v = p as ^
}
''');
    assertResponse(r'''
suggestions
  MyClass
    kind: class
''');
  }

  Future<void> test_completion_cascade_1() async {
    allowedIdentifiers = {'aaa', 'f'};
    await computeSuggestions('''
class A {
  aaa() {}
}


void f(A a) {
  a..^ aaa();
}
''');
    assertResponse(r'''
suggestions
  aaa
    kind: methodInvocation
''');
  }

  Future<void> test_completion_combinator_afterComma_1() async {
    allowedIdentifiers = {'pi', 'sin', 'Random', 'String'};
    await computeSuggestions('''
import 'dart:math' show cos, ^;
''');
    assertResponse(r'''
suggestions
  Random
    kind: class
  pi
    kind: topLevelVariable
  sin
    kind: function
''');
  }

  Future<void> test_completion_combinator_ended_1() async {
    allowedIdentifiers = {'pi', 'sin', 'Random', 'String'};
    await computeSuggestions('''
import 'dart:math' show ^;"
''');
    assertResponse(r'''
suggestions
  Random
    kind: class
  pi
    kind: topLevelVariable
  sin
    kind: function
''');
  }

  Future<void> test_completion_combinator_export_1() async {
    allowedIdentifiers = {'pi', 'sin', 'Random', 'String'};
    await computeSuggestions('''
export 'dart:math' show ^;"
''');
    assertResponse(r'''
suggestions
  Random
    kind: class
  pi
    kind: topLevelVariable
  sin
    kind: function
''');
  }

  Future<void> test_completion_combinator_hide_1() async {
    allowedIdentifiers = {'pi', 'sin', 'Random', 'String'};
    await computeSuggestions('''
import 'dart:math' hide ^;"
''');
    assertResponse(r'''
suggestions
  Random
    kind: class
  pi
    kind: topLevelVariable
  sin
    kind: function
''');
  }

  Future<void> test_completion_combinator_notEnded_1() async {
    allowedIdentifiers = {'pi', 'sin', 'Random', 'String'};
    await computeSuggestions('''
import 'dart:math' show ^"
''');
    assertResponse(r'''
suggestions
  Random
    kind: class
  pi
    kind: topLevelVariable
  sin
    kind: function
''');
  }

  Future<void> test_completion_combinator_usePrefix_1() async {
    allowedIdentifiers = {'sin', 'sqrt', 'cos', 'String'};
    await computeSuggestions('''
import 'dart:math' show s^"
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  sin
    kind: function
  sqrt
    kind: function
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  cos
    kind: function
  sin
    kind: function
  sqrt
    kind: function
''');
    }
  }

  Future<void> test_completion_constructor_field_1() async {
    allowedIdentifiers = {'field'};
    await computeSuggestions('''
class X { X(this.field); int f^ield;}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
  right: 4
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
  right: 4
suggestions
  abstract
    kind: keyword
  covariant
    kind: keyword
  external
    kind: keyword
  late
    kind: keyword
  static
    kind: keyword
''');
    }
  }

  Future<void> test_completion_constructorArguments_showOnlyCurrent_1() async {
    allowedIdentifiers = {'A', 'first', 'second'};
    await computeSuggestions('''
class A {
  A.first(int p);
  A.second(double p);
}
void f() {
  new A.first(^);
}
''');
    assertResponse(r'''
suggestions
  A
    kind: class
  A.first
    kind: constructorInvocation
  A.second
    kind: constructorInvocation
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  @failingTest
  Future<void> test_completion_constructorArguments_whenPrefixedType_1() async {
    allowedIdentifiers = {'Random', 'm'};
    await computeSuggestions('''
import 'dart:math' as m;
void f() {
  new m.Random(^);
}
''');
    if (isProtocolVersion2) {
      // TODO(brianwilkerson) The suggestions here are correct, except for the
      //  last line, which needs to be removed.
      assertResponse(r'''
suggestions
  m
    kind: library
  m.Point
    kind: class
  m.Point
    kind: constructorInvocation
  m.Random
    kind: class
  m.Random
    kind: constructorInvocation
  m.cos
    kind: functionInvocation
  m.max
    kind: functionInvocation
  m.min
    kind: functionInvocation
  m.sin
    kind: functionInvocation
  m.sqrt
    kind: functionInvocation
  m.tan
    kind: functionInvocation
  forced fail
''');
    } else {
      assertResponse(r'''
suggestions
  m
    kind: library
  m.Point
    kind: class
  m.Point
    kind: constructorInvocation
  m.Random
    kind: class
  m.Random
    kind: constructorInvocation
  m.cos
    kind: functionInvocation
  m.max
    kind: functionInvocation
  m.min
    kind: functionInvocation
  m.sin
    kind: functionInvocation
  m.sqrt
    kind: functionInvocation
  m.tan
    kind: functionInvocation
''');
    }
  }

  Future<void> test_completion_dartDoc_reference_forClass_1() async {
    allowedIdentifiers = {'int', 'method'};
    await computeSuggestions('''
/**
 * [int^]
 * [method]
 */
class AAA {
  methodA() {}
}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
''');
  }

  Future<void> test_completion_dartDoc_reference_forClass_2() async {
    allowedIdentifiers = {'methodA', 'int'};
    await computeSuggestions('''
/**
 * [int]
 * [method^]
 */
class AAA {
  methodA() {}
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 6
suggestions
  methodA
    kind: method
''');
    } else {
      assertResponse(r'''
replacement
  left: 6
suggestions
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
  methodA
    kind: method
''');
    }
  }

  Future<void> test_completion_dartDoc_reference_forConstructor_1() async {
    allowedIdentifiers = {'aaa', 'bbb'};
    await computeSuggestions('''
class A {
  /**
   * [aa^]
   * [int]
   * [method]
   */
  A.named(aaa, bbb) {}
  methodA() {}
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  aaa
    kind: parameter
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  aaa
    kind: parameter
  bbb
    kind: parameter
''');
    }
  }

  Future<void> test_completion_dartDoc_reference_forConstructor_2() async {
    allowedIdentifiers = {'int', 'double'};
    await computeSuggestions('''
class A {
  /**
   * [aa]
   * [int^]
   * [method]
   */
  A.named(aaa, bbb) {}
  methodA() {}
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  double
    kind: class
  double
    kind: constructorInvocation
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
''');
    }
  }

  Future<void> test_completion_dartDoc_reference_forConstructor_3() async {
    allowedIdentifiers = {'methodA'};
    await computeSuggestions('''
class A {
  /**
   * [aa]
   * [int]
   * [method^]
   */
  A.named(aaa, bbb) {}
  methodA() {}
}
''');
    assertResponse(r'''
replacement
  left: 6
suggestions
  methodA
    kind: method
''');
  }

  Future<void> test_completion_dartDoc_reference_forFunction_1() async {
    allowedIdentifiers = {'aaa', 'bbb'};
    await computeSuggestions('''
/**
 * [aa^]
 * [int]
 * [function]
 */
functionA(aaa, bbb) {}
functionB() {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  aaa
    kind: parameter
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  aaa
    kind: parameter
  bbb
    kind: parameter
''');
    }
  }

  Future<void> test_completion_dartDoc_reference_forFunction_2() async {
    allowedIdentifiers = {'int', 'double'};
    await computeSuggestions('''
/**
 * [aa]
 * [int^]
 * [function]
 */
functionA(aaa, bbb) {}
functionB() {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  double
    kind: class
  double
    kind: constructorInvocation
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
''');
    }
  }

  Future<void> test_completion_dartDoc_reference_forFunction_3() async {
    allowedIdentifiers = {'functionA', 'functionB', 'int'};
    await computeSuggestions('''
/**
 * [aa]
 * [int]
 * [function^]
 */
functionA(aaa, bbb) {}
functionB() {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 8
suggestions
  functionA
    kind: function
  functionB
    kind: function
''');
    } else {
      assertResponse(r'''
replacement
  left: 8
suggestions
  functionA
    kind: function
  functionB
    kind: function
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
''');
    }
  }

  @failingTest
  Future<void>
      test_completion_dartDoc_reference_forFunctionTypeAlias_1() async {
    allowedIdentifiers = {'aaa', 'bbb'};
    await computeSuggestions('''
/**
 * [aa^]
 * [int]
 * [Function]
 */
typedef FunctionA(aaa, bbb) {}
typedef FunctionB() {}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  aaa
    kind: parameter
  bbb
    kind: parameter
''');
  }

  Future<void>
      test_completion_dartDoc_reference_forFunctionTypeAlias_2() async {
    allowedIdentifiers = {'int', 'double'};
    await computeSuggestions('''
/**
 * [aa]
 * [int^]
 * [Function]
 */
typedef FunctionA(aaa, bbb) {}
typedef FunctionB() {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  double
    kind: class
  double
    kind: constructorInvocation
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
''');
    }
  }

  Future<void>
      test_completion_dartDoc_reference_forFunctionTypeAlias_3() async {
    allowedIdentifiers = {'FunctionA', 'FunctionB', 'int'};
    await computeSuggestions('''
/**
 * [aa]
 * [int]
 * [Function^]
 */
typedef FunctionA(aaa, bbb) {}
typedef FunctionB() {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 8
suggestions
  FunctionA
    kind: typeAlias
  FunctionB
    kind: typeAlias
''');
    } else {
      assertResponse(r'''
replacement
  left: 8
suggestions
  FunctionA
    kind: typeAlias
  FunctionB
    kind: typeAlias
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
''');
    }
  }

  Future<void> test_completion_dartDoc_reference_forMethod_1() async {
    allowedIdentifiers = {'aaa', 'bbb'};
    await computeSuggestions('''
class A {
  /**
   * [aa^]
   * [int]
   * [method]
   */
  methodA(aaa, bbb) {}
  methodB() {}
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  aaa
    kind: parameter
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  aaa
    kind: parameter
  bbb
    kind: parameter
''');
    }
  }

  Future<void> test_completion_dartDoc_reference_forMethod_2() async {
    allowedIdentifiers = {'int', 'double'};
    await computeSuggestions('''
class A {
  /**
   * [aa]
   * [int^]
   * [method]
   */
  methodA(aaa, bbb) {}
  methodB() {}
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  double
    kind: class
  double
    kind: constructorInvocation
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
''');
    }
  }

  Future<void> test_completion_dartDoc_reference_forMethod_3() async {
    allowedIdentifiers = {'methodA', 'methodB', 'int'};
    await computeSuggestions('''
class A {
  /**
   * [aa]
   * [int]
   * [method^]
   */
  methodA(aaa, bbb) {}
  methodB() {}
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 6
suggestions
  methodA
    kind: method
  methodB
    kind: method
''');
    } else {
      assertResponse(r'''
replacement
  left: 6
suggestions
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
  methodA
    kind: method
  methodB
    kind: method
''');
    }
  }

  Future<void> test_completion_dartDoc_reference_incomplete_1() async {
    allowedIdentifiers = {'double', 'int'};
    await computeSuggestions('''
/**
 * [doubl^ some text
 * other text
 */
class A {}
/**
 * [ some text
 * other text
 */
class B {}
/**
 * [] some text
 */
class C {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 5
suggestions
  double
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 5
suggestions
  double
    kind: class
  double
    kind: constructorInvocation
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
''');
    }
  }

  Future<void> test_completion_dartDoc_reference_incomplete_2() async {
    allowedIdentifiers = {'int', 'String'};
    await computeSuggestions('''
/**
 * [doubl some text
 * other text
 */
class A {}
/**
 * [^ some text
 * other text
 */
class B {}
/**
 * [] some text
 */
class C {}
''');
    assertResponse(r'''
suggestions
  String
    kind: class
  String.fromCharCode
    kind: constructorInvocation
  String.fromCharCodes
    kind: constructorInvocation
  String.fromEnvironment
    kind: constructorInvocation
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
''');
  }

  Future<void> test_completion_dartDoc_reference_incomplete_3() async {
    allowedIdentifiers = {'int', 'String'};
    await computeSuggestions('''
/**
 * [doubl some text
 * other text
 */
class A {}
/**
 * [ some text
 * other text
 */
class B {}
/**
 * [^] some text
 */
class C {}
''');
    assertResponse(r'''
suggestions
  String
    kind: class
  String.fromCharCode
    kind: constructorInvocation
  String.fromCharCodes
    kind: constructorInvocation
  String.fromEnvironment
    kind: constructorInvocation
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
''');
  }

  Future<void> test_completion_double_inFractionPart_1() async {
    allowedIdentifiers = {'abs', 'f'};
    await computeSuggestions('''
void f() {
  1.0^
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_completion_enum_1() async {
    allowedIdentifiers = {'values', 'A', 'B', 'C'};
    await computeSuggestions('''
enum MyEnum {A, B, C}
void f() {
  MyEnum.^;
}
''');
    assertResponse(r'''
suggestions
  A
    kind: enumConstant
  B
    kind: enumConstant
  C
    kind: enumConstant
  values
    kind: field
''');
  }

  Future<void> test_completion_exactPrefix_hasHigherRelevance_1() async {
    allowedIdentifiers = {'str', 'STR'};
    await computeSuggestions('''
var STR;
void f(p) {
  var str;
  str^;
  STR;
  Str;
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
  STR
    kind: topLevelVariable
  str
    kind: localVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  STR
    kind: topLevelVariable
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  str
    kind: localVariable
  switch
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
    }
  }

  Future<void> test_completion_exactPrefix_hasHigherRelevance_2() async {
    allowedIdentifiers = {'STR', 'str'};
    await computeSuggestions('''
var STR;
void f(p) {
  var str;
  str;
  STR^;
  Str;
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
  STR
    kind: topLevelVariable
  str
    kind: localVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  STR
    kind: topLevelVariable
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  str
    kind: localVariable
  switch
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
    }
  }

  Future<void> test_completion_exactPrefix_hasHigherRelevance_3() async {
    allowedIdentifiers = {'String', 'STR', 'str'};
    await computeSuggestions('''
var STR;
void f(p) {
  var str;
  str;
  STR;
  Str^;
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
  STR
    kind: topLevelVariable
  String
    kind: class
  String.fromCharCode
    kind: constructorInvocation
  String.fromCharCodes
    kind: constructorInvocation
  String.fromEnvironment
    kind: constructorInvocation
  str
    kind: localVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  STR
    kind: topLevelVariable
  String
    kind: class
  String.fromCharCode
    kind: constructorInvocation
  String.fromCharCodes
    kind: constructorInvocation
  String.fromEnvironment
    kind: constructorInvocation
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  str
    kind: localVariable
  switch
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
    }
  }

  @failingTest
  Future<void> test_completion_export_dart_1() async {
    allowedIdentifiers = {'dart:core', 'dart:math', 'dart:_collection.dev'};
    await computeSuggestions('''
import 'dart:math
import 'dart:_collection.dev
export 'dart:^
''');
    assertResponse(r'''
replacement
  left: 5
suggestions
  |dart:core|
  |dart:math|
''');
  }

  @failingTest
  Future<void> test_completion_export_noStringLiteral_noSemicolon_1() async {
    allowedIdentifiers = {'dart:', 'package:'};
    await computeSuggestions('''
import ^

class A {}
''');
    assertResponse(r'''
suggestions
  |dart:|
  |package:|
''');
  }

  Future<void> test_completion_forStmt_vars_1() async {
    allowedIdentifiers = {'int'};
    await computeSuggestions('''
class int{}class Foo { mth() { for (in^t i = 0; i < 5; i++); }}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
  right: 1
suggestions
  int
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
  right: 1
suggestions
  int
    kind: class
  int
    kind: class
''');
    }
  }

  Future<void> test_completion_forStmt_vars_2() async {
    allowedIdentifiers = {'i'};
    await computeSuggestions('''
class int{}class Foo { mth() { for (int i = 0; i^ < 5; i++); }}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  i
    kind: localVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  false
    kind: keyword
  i
    kind: localVariable
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_completion_forStmt_vars_3() async {
    allowedIdentifiers = {'i'};
    await computeSuggestions('''
class int{}class Foo { mth() { for (int i = 0; i < 5; i^++); }}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  i
    kind: localVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  i
    kind: localVariable
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_completion_function_1() async {
    allowedIdentifiers = {'String'};
    await computeSuggestions('''
class Foo { int boo = 7; mth() { PNGS.sort((String a, Str^) => a.compareTo(b)); }}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
  String
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  String
    kind: class
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  @failingTest
  Future<void> test_completion_function_partial_1() async {
    allowedIdentifiers = {'String'};
    await computeSuggestions('''
class Foo { int boo = 7; mth() { PNGS.sort((String a, Str^)); }}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
  String
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  String
    kind: class
''');
    }
  }

  Future<void> test_completion_functionTypeParameter_namedArgument_1() async {
    await computeSuggestions('''
typedef FFF(a, b, {x1, x2, y});
void f(FFF fff) {
  fff(1, 2, ^);
}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
  |x1: |
    kind: namedArgument
  |x2: |
    kind: namedArgument
  |y: |
    kind: namedArgument
''');
  }

  Future<void> test_completion_functionTypeParameter_namedArgument_2() async {
    await computeSuggestions('''
typedef FFF(a, b, {x1, x2, y});
void f(FFF fff) {
  fff(1, 2, )^;
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_completion_ifStmt_field1_1() async {
    allowedIdentifiers = {'myField'};
    await computeSuggestions('''
class Foo { int myField = 7; mth() { if (^) {}}}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  myField
    kind: field
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_completion_ifStmt_field1a_1() async {
    allowedIdentifiers = {'myField'};
    await computeSuggestions('''
class Foo { int myField = 7; mth() { if (^) }}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  myField
    kind: field
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_completion_ifStmt_field2_1() async {
    allowedIdentifiers = {'myField'};
    await computeSuggestions('''
class Foo { int myField = 7; mth() { if (m^) {}}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  myField
    kind: field
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  myField
    kind: field
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_completion_ifStmt_field2a_1() async {
    allowedIdentifiers = {'myField'};
    await computeSuggestions('''
class Foo { int myField = 7; mth() { if (m^) }}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  myField
    kind: field
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  myField
    kind: field
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_completion_ifStmt_field2b_1() async {
    allowedIdentifiers = {'myField'};
    await computeSuggestions('''
class Foo { myField = 7; mth() { if (m^) {}}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  myField
    kind: field
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  myField
    kind: field
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_completion_ifStmt_localVar_1() async {
    allowedIdentifiers = {'value'};
    await computeSuggestions('''
class Foo { mth() { int value = 7; if (v^) {}}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  value
    kind: localVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
  value
    kind: localVariable
''');
    }
  }

  Future<void> test_completion_ifStmt_localVara_1() async {
    allowedIdentifiers = {'value'};
    await computeSuggestions('''
class Foo { mth() { value = 7; if (v^) {}}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_completion_ifStmt_topLevelVar_1() async {
    allowedIdentifiers = {'topValue'};
    await computeSuggestions('''
int topValue = 7; class Foo { mth() { if (t^) {}}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  this
    kind: keyword
  topValue
    kind: topLevelVariable
  true
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  topValue
    kind: topLevelVariable
  true
    kind: keyword
''');
    }
  }

  Future<void> test_completion_ifStmt_topLevelVara_1() async {
    allowedIdentifiers = {'topValue'};
    await computeSuggestions('''
topValue = 7; class Foo { mth() { if (t^) {}}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  this
    kind: keyword
  topValue
    kind: topLevelVariable
  true
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  topValue
    kind: topLevelVariable
  true
    kind: keyword
''');
    }
  }

  Future<void> test_completion_ifStmt_unionType_nonStrict_1() async {
    allowedIdentifiers = {'a', 'x', 'y'};
    await computeSuggestions('''
class A { a() => null; x() => null}
class B { a() => null; y() => null}
void f() {
  var x;
  var c;
  if(c) {
    x = new A();
  } else {
    x = new B();
  }
  x.^;
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_completion_ifStmt_unionType_strict_1() async {
    allowedIdentifiers = {'a', 'x', 'y'};
    await computeSuggestions('''
class A { a() => null; x() => null}
class B { a() => null; y() => null}
void f() {
  var x;
  var c;
  if(c) {
    x = new A();
  } else {
    x = new B();
  }
  x.^;
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_completion_import_1() async {
    allowedIdentifiers = {'dart:', 'package:'};
    await computeSuggestions('''
import '^';
''');
    assertResponse(r'''
suggestions
  dart:
    kind: import
  dart:async
    kind: import
  dart:async2
    kind: import
  dart:collection
    kind: import
  dart:convert
    kind: import
  dart:core
    kind: import
  dart:ffi
    kind: import
  dart:html
    kind: import
  dart:io
    kind: import
  dart:isolate
    kind: import
  dart:math
    kind: import
  package:
    kind: import
  package:test/
    kind: import
  package:test/test.dart
    kind: import
''');
  }

  @failingTest
  Future<void> test_completion_import_dart_1() async {
    allowedIdentifiers = {'dart:'};
    await computeSuggestions('''
import 'dart:math
import 'dart:_collection.dev
import 'dart:^
''');
    assertResponse(r'''
replacement
  left: 5
suggestions
  dart:core
    kind: import
  dart:math
    kind: import
''');
  }

  Future<void> test_completion_import_hasStringLiteral_noSemicolon_1() async {
    allowedIdentifiers = {'dart:', 'package:'};
    await computeSuggestions('''
import '^'

class A {}
''');
    assertResponse(r'''
suggestions
  dart:
    kind: import
  dart:async
    kind: import
  dart:async2
    kind: import
  dart:collection
    kind: import
  dart:convert
    kind: import
  dart:core
    kind: import
  dart:ffi
    kind: import
  dart:html
    kind: import
  dart:io
    kind: import
  dart:isolate
    kind: import
  dart:math
    kind: import
  package:
    kind: import
  package:test/
    kind: import
  package:test/test.dart
    kind: import
''');
  }

  @failingTest
  Future<void> test_completion_import_lib_1() async {
    allowedIdentifiers = {'my_lib.dart'};
    newFile('$testPackageLibPath/my_lib.dart', '''

''');
    await computeSuggestions('''
import '^
''');
    assertResponse(r'''
suggestions
  dart:
    kind: import
  dart:async
    kind: import
  dart:async2
    kind: import
  dart:collection
    kind: import
  dart:convert
    kind: import
  dart:core
    kind: import
  dart:ffi
    kind: import
  dart:html
    kind: import
  dart:io
    kind: import
  dart:isolate
    kind: import
  dart:math
    kind: import
  my_lib.dart
    kind: import
  package:
    kind: import
  package:test/
    kind: import
  package:test/test.dart
    kind: import
''');
  }

  Future<void> test_completion_import_noSpace_1() async {
    allowedIdentifiers = {'dart:', 'package:'};
    await computeSuggestions('''
import^
''');
    assertResponse(r'''
replacement
  left: 6
suggestions
''');
  }

  @FailingTest(reason: 'We only suggest URIs inside a string literal')
  Future<void> test_completion_import_noStringLiteral_1() async {
    allowedIdentifiers = {'dart:', 'package:'};
    await computeSuggestions('''
import ^;
''');
    assertResponse(r'''
suggestions
  dart:
    kind: import
  package:
    kind: import
''');
  }

  @FailingTest(reason: 'We only suggest URIs inside a string literal')
  Future<void> test_completion_import_noStringLiteral_noSemicolon_1() async {
    allowedIdentifiers = {'dart:', 'package:'};
    await computeSuggestions('''
import ^

class A {}
''');
    assertResponse(r'''
suggestions
  dart:
    kind: import
  package:
    kind: import
''');
  }

  Future<void> test_completion_incompleteClassMember_1() async {
    allowedIdentifiers = {'String', 'bool'};
    await computeSuggestions('''
class A {
  Str^
  final f = null;
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
  @override
  String toString() {
    // TODO: implement toString
    return super.toString();
  }
    kind: override
    selection: 68 24
  String
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;
    kind: override
    selection: 62 14
  @override
  // TODO: implement runtimeType
  Type get runtimeType => super.runtimeType;
    kind: override
    selection: 69 17
  @override
  String toString() {
    // TODO: implement toString
    return super.toString();
  }
    kind: override
    selection: 68 24
  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
    kind: override
    selection: 75 22
  @override
  noSuchMethod(Invocation invocation) {
    // TODO: implement noSuchMethod
    return super.noSuchMethod(invocation);
  }
    kind: override
    selection: 90 38
  String
    kind: class
  abstract
    kind: keyword
  bool
    kind: class
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  external
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_completion_incompleteClosure_parameterType_1() async {
    allowedIdentifiers = {'String', 'bool'};
    await computeSuggestions('''
f1(cb(String s)) {}
f2(String s) {}
void f() {
  f1((Str^));
  f2((Str));
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
  String
    kind: class
  String.fromCharCode
    kind: constructorInvocation
  String.fromCharCodes
    kind: constructorInvocation
  String.fromEnvironment
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  String
    kind: class
  String.fromCharCode
    kind: constructorInvocation
  String.fromCharCodes
    kind: constructorInvocation
  String.fromEnvironment
    kind: constructorInvocation
  bool
    kind: class
  bool.fromEnvironment
    kind: constructorInvocation
  bool.hasEnvironment
    kind: constructorInvocation
  const
    kind: keyword
  f1
    kind: functionInvocation
  f2
    kind: functionInvocation
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_completion_incompleteClosure_parameterType_2() async {
    allowedIdentifiers = {'String', 'bool'};
    await computeSuggestions('''
f1(cb(String s)) {}
f2(String s) {}
void f() {
  f1((Str));
  f2((Str^));
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
  String
    kind: class
  String.fromCharCode
    kind: constructorInvocation
  String.fromCharCodes
    kind: constructorInvocation
  String.fromEnvironment
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  String
    kind: class
  String.fromCharCode
    kind: constructorInvocation
  String.fromCharCodes
    kind: constructorInvocation
  String.fromEnvironment
    kind: constructorInvocation
  bool
    kind: class
  bool.fromEnvironment
    kind: constructorInvocation
  bool.hasEnvironment
    kind: constructorInvocation
  const
    kind: keyword
  f1
    kind: functionInvocation
  f2
    kind: functionInvocation
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  @failingTest
  Future<void> test_completion_inPeriodPeriod_1() async {
    allowedIdentifiers = {'codeUnits'};
    await computeSuggestions('''
void f(String str) {
  1 < str.^.length;
  1 + str..length;
  1 + 2 * str..length;
}
''');
    assertResponse(r'''
suggestions
  codeUnits
    kind: methodInvocation
''');
  }

  @failingTest
  Future<void> test_completion_inPeriodPeriod_2() async {
    allowedIdentifiers = {'codeUnits'};
    await computeSuggestions('''
void f(String str) {
  1 < str..length;
  1 + str.^.length;
  1 + 2 * str..length;
}
''');
    assertResponse(r'''
suggestions
  codeUnits
    kind: methodInvocation
''');
  }

  @failingTest
  Future<void> test_completion_inPeriodPeriod_3() async {
    allowedIdentifiers = {'codeUnits'};
    await computeSuggestions('''
void f(String str) {
  1 < str..length;
  1 + str..length;
  1 + 2 * str.^.length;
}
''');
    assertResponse(r'''
suggestions
  codeUnits
    kind: methodInvocation
''');
  }

  Future<void> test_completion_instanceCreation_unresolved_1() async {
    allowedIdentifiers = {'int'};
    await computeSuggestions('''
class A {
}
void f() {
  new NoSuchClass(^);
  new A.noSuchConstructor();
}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_completion_instanceCreation_unresolved_2() async {
    allowedIdentifiers = {'int'};
    await computeSuggestions('''
class A {
}
void f() {
  new NoSuchClass();
  new A.noSuchConstructor(^);
}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_completion_is_1() async {
    allowedIdentifiers = {'MyClass'};
    await computeSuggestions('''
class MyClass {}
void f(p) {
  var isVariable;
  if (p is MyCla^) {}
  var v1 = p is MyCla;
  var v2 = p is ;
  var v2 = p is;
}
''');
    assertResponse(r'''
replacement
  left: 5
suggestions
  MyClass
    kind: class
''');
  }

  Future<void> test_completion_is_2() async {
    allowedIdentifiers = {'MyClass'};
    await computeSuggestions('''
class MyClass {}
void f(p) {
  var isVariable;
  if (p is MyCla) {}
  var v1 = p is MyCla^;
  var v2 = p is ;
  var v2 = p is;
}
''');
    assertResponse(r'''
replacement
  left: 5
suggestions
  MyClass
    kind: class
''');
  }

  Future<void> test_completion_is_3() async {
    allowedIdentifiers = {'MyClass', 'v1'};
    await computeSuggestions('''
class MyClass {}
void f(p) {
  var isVariable;
  if (p is MyCla) {}
  var v1 = p is MyCla;
  var v2 = p is ^;
  var v2 = p is;
}
''');
    assertResponse(r'''
suggestions
  MyClass
    kind: class
''');
  }

  Future<void> test_completion_is_4() async {
    allowedIdentifiers = {'is', 'isVariable'};
    await computeSuggestions('''
class MyClass {}
void f(p) {
  var isVariable;
  if (p is MyCla) {}
  var v1 = p is MyCla;
  var v2 = p is ;
  var v2 = p is^;
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  is
    kind: keyword
''');
  }

  @failingTest
  Future<void> test_completion_is_asIdentifierStart_1() async {
    allowedIdentifiers = {'isVisible'};
    await computeSuggestions('''
void f(p) {
  var isVisible;
  var v1 = is^;
  var v2 = is
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  is
    kind: keyword
  isVisible
    kind: localVariable
''');
  }

  @failingTest
  Future<void> test_completion_is_asIdentifierStart_2() async {
    allowedIdentifiers = {'isVisible'};
    await computeSuggestions('''
void f(p) {
  var isVisible;
  var v1 = is;
  var v2 = is^
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  is
    kind: keyword
  isVisible
    kind: localVariable
''');
  }

  Future<void> test_completion_is_asPrefixedIdentifierStart_1() async {
    allowedIdentifiers = {'isVisible'};
    await computeSuggestions('''
class A {
  var isVisible;
}

void f(A p) {
  var v1 = p.is^;
  var v2 = p.is
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  isVisible
    kind: field
''');
  }

  Future<void> test_completion_is_asPrefixedIdentifierStart_2() async {
    allowedIdentifiers = {'isVisible'};
    await computeSuggestions('''
class A {
  var isVisible;
}

void f(A p) {
  var v1 = p.is;
  var v2 = p.is^
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  isVisible
    kind: field
''');
  }

  Future<void> test_completion_is_incompleteStatement1_1() async {
    allowedIdentifiers = {'MyClass', 'justSomeVar'};
    await computeSuggestions('''
class MyClass {}
void f(p) {
  var justSomeVar;
  var v = p is ^
}
''');
    assertResponse(r'''
suggestions
  MyClass
    kind: class
''');
  }

  Future<void> test_completion_is_incompleteStatement2_1() async {
    allowedIdentifiers = {'is', 'isVariable'};
    await computeSuggestions('''
class MyClass {}
void f(p) {
  var isVariable;
  var v = p is^
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  is
    kind: keyword
''');
  }

  Future<void> test_completion_keyword_in_1() async {
    allowedIdentifiers = {'input'};
    await computeSuggestions('''
class Foo { int input = 7; mth() { if (in^) {}}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  input
    kind: field
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  const
    kind: keyword
  false
    kind: keyword
  input
    kind: field
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_completion_keyword_syntheticIdentifier_1() async {
    allowedIdentifiers = {'caseVar', 'otherVar'};
    await computeSuggestions('''
void f() {
  var caseVar;
  var otherVar;
  var v = case^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 4
suggestions
  caseVar
    kind: localVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 4
suggestions
  caseVar
    kind: localVariable
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  otherVar
    kind: localVariable
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_completion_libraryIdentifier_atEOF_1() async {
    allowedIdentifiers = {'parse', 'bool'};
    await computeSuggestions('''
library int.^
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_completion_libraryIdentifier_notEOF_1() async {
    allowedIdentifiers = {'parse', 'bool'};
    // TODO(brianwilkerson) This is the same as
    //  test_completion_libraryIdentifier_atEOF_1, probably this one needs
    //  something following the directive.
    await computeSuggestions('''
library int.^
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void>
      test_completion_methodRef_asArg_incompatibleFunctionType_1() async {
    allowedIdentifiers = {'myFuncInt', 'myFuncDouble'};
    await computeSuggestions('''
foo( f(int p) ) {}
class Functions {
  static myFuncInt(int p) {}
  static myFuncDouble(double p) {}
}
bar(p) {}
void f(p) {
  foo( Functions.^; );
}
''');
    assertResponse(r'''
suggestions
  myFuncDouble
    kind: methodInvocation
  myFuncInt
    kind: methodInvocation
''');
  }

  Future<void> test_completion_methodRef_asArg_notFunctionType_1() async {
    allowedIdentifiers = {'myFunc'};
    await computeSuggestions('''
foo( f(int p) ) {}
class Functions {
  static myFunc(int p) {}
}
bar(p) {}
void f(p) {
  foo( (int p) => Functions.^; );
}
''');
    assertResponse(r'''
suggestions
  myFunc
    kind: methodInvocation
''');
  }

  Future<void> test_completion_methodRef_asArg_ofFunctionType_1() async {
    allowedIdentifiers = {'myFunc'};
    await computeSuggestions('''
foo( f(int p) ) {}
class Functions {
  static int myFunc(int p) {}
}
void f(p) {
  foo(Functions.^);
}
''');
    assertResponse(r'''
suggestions
  myFunc
    kind: methodInvocation
''');
  }

  Future<void> test_completion_namedArgument_alreadyUsed_1() async {
    allowedIdentifiers = {'foo'};
    await computeSuggestions('''
func({foo}) {} void f() { func(foo: 0, fo^); }
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_completion_namedArgument_constructor_1() async {
    allowedIdentifiers = {'foo', 'bar'};
    await computeSuggestions('''
class A {A({foo, bar}) {}} void f() { new A(fo^); }
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  |foo: |
    kind: namedArgument
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  |bar: |
    kind: namedArgument
  const
    kind: keyword
  false
    kind: keyword
  |foo: |
    kind: namedArgument
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_completion_namedArgument_empty_1() async {
    allowedIdentifiers = {'foo'};
    await computeSuggestions('''
func({foo, bar}) {} void f() { func(^); }
''');
    assertResponse(r'''
suggestions
  |bar: |
    kind: namedArgument
  |foo: |
    kind: namedArgument
''');
  }

  Future<void> test_completion_namedArgument_function_1() async {
    allowedIdentifiers = {'foo', 'bar'};
    await computeSuggestions('''
func({foo, bar}) {} void f() { func(fo^); }
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  |foo: |
    kind: namedArgument
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  |bar: |
    kind: namedArgument
  const
    kind: keyword
  false
    kind: keyword
  |foo: |
    kind: namedArgument
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_completion_namedArgument_notNamed_1() async {
    allowedIdentifiers = {'foo'};
    await computeSuggestions('''
func([foo]) {} void f() { func(fo^); }
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_completion_namedArgument_unresolvedFunction_1() async {
    allowedIdentifiers = {'foo'};
    await computeSuggestions('''
void f() { func(fo^); }
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_completion_newMemberType1_1() async {
    allowedIdentifiers = {'Collection', 'List'};
    await computeSuggestions('''
class Collection{}class List extends Collection{}class Foo { ^ }
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  Collection
    kind: class
  List
    kind: class
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
    } else {
      assertResponse(r'''
suggestions
  Collection
    kind: class
  List
    kind: class
  List
    kind: class
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_completion_newMemberType2_1() async {
    allowedIdentifiers = {'Collection', 'List'};
    await computeSuggestions('''
class Collection{}class List extends Collection{}class Foo {^}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  Collection
    kind: class
  List
    kind: class
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
    } else {
      assertResponse(r'''
suggestions
  Collection
    kind: class
  List
    kind: class
  List
    kind: class
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_completion_newMemberType3_1() async {
    allowedIdentifiers = {'List', 'Collection'};
    await computeSuggestions('''
class Collection{}class List extends Collection{}class Foo {L^}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  List
    kind: class
  late
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;
    kind: override
    selection: 62 14
  @override
  // TODO: implement runtimeType
  Type get runtimeType => super.runtimeType;
    kind: override
    selection: 69 17
  @override
  String toString() {
    // TODO: implement toString
    return super.toString();
  }
    kind: override
    selection: 68 24
  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
    kind: override
    selection: 75 22
  @override
  noSuchMethod(Invocation invocation) {
    // TODO: implement noSuchMethod
    return super.noSuchMethod(invocation);
  }
    kind: override
    selection: 90 38
  Collection
    kind: class
  List
    kind: class
  List
    kind: class
  abstract
    kind: keyword
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  external
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_completion_newMemberType4_1() async {
    allowedIdentifiers = {'Collection', 'List'};
    await computeSuggestions('''
class Collection{}class List extends Collection{}class Foo {C^}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  Collection
    kind: class
  const
    kind: keyword
  covariant
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;
    kind: override
    selection: 62 14
  @override
  // TODO: implement runtimeType
  Type get runtimeType => super.runtimeType;
    kind: override
    selection: 69 17
  @override
  String toString() {
    // TODO: implement toString
    return super.toString();
  }
    kind: override
    selection: 68 24
  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
    kind: override
    selection: 75 22
  @override
  noSuchMethod(Invocation invocation) {
    // TODO: implement noSuchMethod
    return super.noSuchMethod(invocation);
  }
    kind: override
    selection: 90 38
  Collection
    kind: class
  List
    kind: class
  List
    kind: class
  abstract
    kind: keyword
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  external
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_completion_positionalArgument_constructor_1() async {
    allowedIdentifiers = {'foo', 'bar'};
    await computeSuggestions('''
class A {
  A([foo, bar]);
}
void f() {
  new A(^);
  new A(0, );
}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_completion_positionalArgument_constructor_2() async {
    allowedIdentifiers = {'bar', 'foo'};
    await computeSuggestions('''
class A {
  A([foo, bar]);
}
void f() {
  new A();
  new A(0, ^);
}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_completion_positionalArgument_function_1() async {
    allowedIdentifiers = {'foo', 'bar'};
    await computeSuggestions('''
func([foo, bar]) {}
void f() {
  func(^);
  func(0, );
}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_completion_positionalArgument_function_2() async {
    allowedIdentifiers = {'bar', 'foo'};
    await computeSuggestions('''
func([foo, bar]) {}
void f() {
  func();
  func(0, ^);
}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_completion_preferStaticType_1() async {
    allowedIdentifiers = {'foo', 'bar'};
    await computeSuggestions('''
class A {
  foo() {}
}
class B extends A {
  bar() {}
}
void f() {
  A v = new B();
  v.^
}
''');
    assertResponse(r'''
suggestions
  foo
    kind: methodInvocation
''');
  }

  Future<void>
      test_completion_privateElement_sameLibrary_constructor_1() async {
    allowedIdentifiers = {'_c', 'c'};
    await computeSuggestions('''
class A {
  A._c();
  A.c();
}
void f() {
  new A.^
}
''');
    assertResponse(r'''
suggestions
  _c
    kind: constructorInvocation
  c
    kind: constructorInvocation
''');
  }

  Future<void> test_completion_privateElement_sameLibrary_member_1() async {
    allowedIdentifiers = {'_m', 'm'};
    await computeSuggestions('''
class A {
  _m() {}
  m() {}
}
void f(A a) {
  a.^
}
''');
    assertResponse(r'''
suggestions
  _m
    kind: methodInvocation
  m
    kind: methodInvocation
''');
  }

  Future<void> test_completion_propertyAccess_whenClassTarget_1() async {
    allowedIdentifiers = {'FIELD', 'field'};
    await computeSuggestions('''
class A {
  static int FIELD;
  int field;
}
void f() {
  A.^
}
''');
    assertResponse(r'''
suggestions
  FIELD
    kind: field
''');
  }

  Future<void>
      test_completion_propertyAccess_whenClassTarget_excludeSuper_1() async {
    allowedIdentifiers = {'FIELD_B', 'methodB', 'FIELD_A', 'methodA'};
    await computeSuggestions('''
class A {
  static int FIELD_A;
  static int methodA() {}
}
class B extends A {
  static int FIELD_B;
  static int methodB() {}
}
void f() {
  B.^;
}
''');
    assertResponse(r'''
suggestions
  FIELD_B
    kind: field
  methodB
    kind: methodInvocation
''');
  }

  Future<void> test_completion_propertyAccess_whenInstanceTarget_1() async {
    allowedIdentifiers = {'fieldA', 'FIELD'};
    await computeSuggestions('''
class A {
  static int FIELD;
  int fieldA;
}
class B {
  A a;
}
class C extends A {
  int fieldC;
}
void f(B b, C c) {
  b.a.^;
  c.;
}
''');
    assertResponse(r'''
suggestions
  fieldA
    kind: field
''');
  }

  Future<void> test_completion_propertyAccess_whenInstanceTarget_2() async {
    allowedIdentifiers = {'fieldC', 'fieldA'};
    await computeSuggestions('''
class A {
  static int FIELD;
  int fieldA;
}
class B {
  A a;
}
class C extends A {
  int fieldC;
}
void f(B b, C c) {
  b.a.;
  c.^;
}
''');
    assertResponse(r'''
suggestions
  fieldA
    kind: field
  fieldC
    kind: field
''');
  }

  Future<void> test_completion_return_withIdentifierPrefix_1() async {
    allowedIdentifiers = {'vvv'};
    await computeSuggestions('''
f() { var vvv = 42; return v^ }
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  vvv
    kind: localVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
  vvv
    kind: localVariable
''');
    }
  }

  Future<void> test_completion_return_withoutExpression_1() async {
    allowedIdentifiers = {'vvv'};
    await computeSuggestions('''
f() { var vvv = 42; return ^ }
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
  vvv
    kind: localVariable
''');
  }

  Future<void> test_completion_staticField1_1() async {
    allowedIdentifiers = {'MAX_D'};
    await computeSuggestions('''
class num{}class Sunflower {static final num MAX_D = 300;num xc, yc;Sunflower() {xc = yc = MA^ }}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  MAX_D
    kind: field
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  MAX_D
    kind: field
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_completion_staticField1_2() async {
    allowedIdentifiers = {'num'};
    await computeSuggestions('''
class num{}class Sunflower {static final n^um MAX_D = 300;num xc, yc;Sunflower() {xc = yc = MA }}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
  right: 2
suggestions
  num
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
  right: 2
suggestions
  num
    kind: class
  num
    kind: class
''');
    }
  }

  Future<void> test_completion_staticField1_3() async {
    allowedIdentifiers = {'num'};
    await computeSuggestions('''
class num{}class Sunflower {static final num MAX_D = 300;nu^m xc, yc;Sunflower() {xc = yc = MA }}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
  right: 1
suggestions
  num
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
  right: 1
suggestions
  abstract
    kind: keyword
  const
    kind: keyword
  covariant
    kind: keyword
  external
    kind: keyword
  final
    kind: keyword
  late
    kind: keyword
  num
    kind: class
  num
    kind: class
  static
    kind: keyword
  var
    kind: keyword
''');
    }
  }

  Future<void> test_completion_staticField1_4() async {
    allowedIdentifiers = {'Sunflower'};
    await computeSuggestions('''
class num{}class Sunflower {static final num MAX_D = 300;num xc, yc;Sun^flower() {xc = yc = MA }}
''');
    assertResponse(r'''
replacement
  left: 3
  right: 6
suggestions
  Sunflower
    kind: class
''');
  }

  Future<void> test_completion_staticField1_X() async {
    allowedIdentifiers = {'xc'};
    await computeSuggestions('''
class num{}class Sunflower {static final num MAX_D = 300;num xc, yc;Sunflower() {x^c = yc = MA }}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
  right: 1
suggestions
  xc
    kind: field
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
  right: 1
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
  xc
    kind: field
''');
    }
  }

  Future<void> test_completion_staticField1_Y() async {
    allowedIdentifiers = {'yc'};
    await computeSuggestions('''
class num{}class Sunflower {static final num MAX_D = 300;num xc, yc;Sunflower() {xc = y^c = MA }}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
  right: 1
suggestions
  yc
    kind: field
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
  right: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
  yc
    kind: field
''');
    }
  }

  Future<void> test_completion_staticField_withoutVarOrFinal_1() async {
    allowedIdentifiers = {'num'};
    await computeSuggestions('''
class num{}class Sunflower {static n^}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  @override
  noSuchMethod(Invocation invocation) {
    // TODO: implement noSuchMethod
    return super.noSuchMethod(invocation);
  }
    kind: override
    selection: 90 38
  num
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;
    kind: override
    selection: 62 14
  @override
  // TODO: implement runtimeType
  Type get runtimeType => super.runtimeType;
    kind: override
    selection: 69 17
  @override
  String toString() {
    // TODO: implement toString
    return super.toString();
  }
    kind: override
    selection: 68 24
  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
    kind: override
    selection: 75 22
  @override
  noSuchMethod(Invocation invocation) {
    // TODO: implement noSuchMethod
    return super.noSuchMethod(invocation);
  }
    kind: override
    selection: 90 38
  const
    kind: keyword
  dynamic
    kind: keyword
  external
    kind: keyword
  final
    kind: keyword
  num
    kind: class
  num
    kind: class
  var
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_completion_super_superType_1() async {
    allowedIdentifiers = {'fa', 'ma', 'fb', 'mb'};
    await computeSuggestions('''
class A {
  var fa;
  ma() {}
}
class B extends A {
  var fb;
  mb() {}
  void f() {
    super.^
  }
}
''');
    assertResponse(r'''
suggestions
  fa
    kind: field
  ma
    kind: methodInvocation
''');
  }

  Future<void>
      test_completion_superConstructorInvocation_noNamePrefix_1() async {
    allowedIdentifiers = {'fooA', 'fooB', 'bar'};
    await computeSuggestions('''
class A {
  A.fooA();
  A.fooB();
  A.bar();
}
class B extends A {
  B() : super.^
}
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  bar
    kind: constructorInvocation
  fooA
    kind: constructorInvocation
  fooB
    kind: constructorInvocation
''');
  }

  Future<void>
      test_completion_superConstructorInvocation_withNamePrefix_1() async {
    allowedIdentifiers = {'fooA', 'fooB', 'bar'};
    await computeSuggestions('''
class A {
  A.fooA();
  A.fooB();
  A.bar();
}
class B extends A {
  B() : super.f^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  fooA
    kind: constructorInvocation
  fooB
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  assert
    kind: keyword
  bar
    kind: constructorInvocation
  fooA
    kind: constructorInvocation
  fooB
    kind: constructorInvocation
''');
    }
  }

  @FailingTest(reason: 'instance members should not be suggested')
  Future<void> test_completion_this_bad_inConstructorInitializer_1() async {
    allowedIdentifiers = {'toString'};
    await computeSuggestions('''
class A {
  var f;
  A() : f = this.^;
}
''');
    assertResponse(r'''
suggestions
''');
  }

  @FailingTest(reason: 'instance members should not be suggested')
  Future<void> test_completion_this_bad_inFieldDeclaration_1() async {
    allowedIdentifiers = {'toString'};
    await computeSuggestions('''
class A {
  var f = this.^;
}
''');
    assertResponse(r'''
suggestions
''');
  }

  @FailingTest(reason: 'instance members should not be suggested')
  Future<void> test_completion_this_bad_inStaticMethod_1() async {
    allowedIdentifiers = {'toString'};
    await computeSuggestions('''
class A {
  static m() {
    this.^;
  }
}
''');
    assertResponse(r'''
suggestions
''');
  }

  @FailingTest(reason: 'instance members should not be suggested')
  Future<void> test_completion_this_bad_inTopLevelFunction_1() async {
    allowedIdentifiers = {'toString'};
    await computeSuggestions('''
void f() {
  this.^;
}
''');
    assertResponse(r'''
suggestions
''');
  }

  @FailingTest(reason: 'instance members should not be suggested')
  Future<void>
      test_completion_this_bad_inTopLevelVariableDeclaration_1() async {
    allowedIdentifiers = {'toString'};
    await computeSuggestions('''
var v = this.^;
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_completion_this_OK_inConstructorBody_1() async {
    allowedIdentifiers = {'f', 'm'};
    await computeSuggestions('''
class A {
  var f;
  m() {}
  A() {
    this.^;
  }
}
''');
    assertResponse(r'''
suggestions
  f
    kind: field
  m
    kind: methodInvocation
''');
  }

  Future<void> test_completion_this_OK_localAndSuper_1() async {
    allowedIdentifiers = {'fa', 'fb', 'ma', 'mb'};
    await computeSuggestions('''
class A {
  var fa;
  ma() {}
}
class B extends A {
  var fb;
  mb() {}
  void m() {
    this.^
  }
}
''');
    assertResponse(r'''
suggestions
  fa
    kind: field
  fb
    kind: field
  ma
    kind: methodInvocation
  mb
    kind: methodInvocation
''');
  }

  Future<void> test_completion_topLevelField_init2_1() async {
    allowedIdentifiers = {'DateTime', 'void'};
    await computeSuggestions('''
class DateTime{static var JUN;}final num M = Dat^eTime.JUN;
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
  right: 5
suggestions
  DateTime
    kind: class
  DateTime
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
  right: 5
suggestions
  DateTime
    kind: class
  DateTime
    kind: class
  DateTime
    kind: constructorInvocation
  DateTime.now
    kind: constructorInvocation
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_completion_while_1() async {
    allowedIdentifiers = {'boo'};
    await computeSuggestions('''
class Foo { int boo = 7; mth() { while (b^) {} }}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  boo
    kind: field
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  boo
    kind: field
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_export_ignoreIfThisLibraryExports_1() async {
    allowedIdentifiers = {'libFunction', 'cos'};
    await computeSuggestions('''
export 'dart:math';
libFunction() {};
void f() {
  ^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  cos
    kind: functionInvocation
  cos
    kind: functionInvocation
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  libFunction
    kind: functionInvocation
  null
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
    } else {
      assertResponse(r'''
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  cos
    kind: functionInvocation
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  libFunction
    kind: functionInvocation
  null
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
    }
  }

  Future<void> test_export_showIfImportLibraryWithExport_1() async {
    allowedIdentifiers = {'cos', 'libFunction', 'sin'};
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
export 'dart:math' hide sin;
libFunction() {}
''');
    await computeSuggestions('''
import 'lib.dart' as p;
void f() {
  p.^
}
''');
    assertResponse(r'''
suggestions
  cos
    kind: functionInvocation
  libFunction
    kind: functionInvocation
''');
  }

  Future<void> test_importPrefix_hideCombinator_1() async {
    allowedIdentifiers = {'ln10', 'pi'};
    await computeSuggestions('''
import 'dart:math' as math hide pi;
void f() {
  math.^
}
''');
    assertResponse(r'''
suggestions
  ln10
    kind: topLevelVariable
''');
  }

  Future<void> test_importPrefix_showCombinator_1() async {
    allowedIdentifiers = {'pi', 'ln10'};
    await computeSuggestions('''
import 'dart:math' as math show pi;
void f() {
  math.^
}
''');
    assertResponse(r'''
suggestions
  pi
    kind: topLevelVariable
''');
  }

  Future<void> test_library001_1() async {
    allowedIdentifiers = {'SerializationException'};
    newFile('$testPackageLibPath/firth.dart', '''
library firth;
class SerializationException {
  const SerializationException();
}
''');
    await computeSuggestions('''
import 'firth.dart';
void f() {
throw new Seria^lizationException();}
''');
    assertResponse(r'''
replacement
  left: 5
  right: 17
suggestions
  SerializationException
    kind: constructorInvocation
''');
  }

  Future<void> test_library002_1() async {
    allowedIdentifiers = {'length', 'isEmpty'};
    await computeSuggestions('''
t2() {var q=[0],z=q.^length;q.clear();}
''');
    assertResponse(r'''
replacement
  right: 6
suggestions
  isEmpty
    kind: getter
  length
    kind: getter
''');
  }

  Future<void> test_library002_2() async {
    allowedIdentifiers = {'clear'};
    await computeSuggestions('''
t2() {var q=[0],z=q.length;q.^clear();}
''');
    assertResponse(r'''
replacement
  right: 5
suggestions
  clear
    kind: methodInvocation
''');
  }

  Future<void> test_library003_1() async {
    allowedIdentifiers = {'end'};
    await computeSuggestions('''
class X{var q; f() {q.^a}}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
''');
  }

  Future<void> test_library003_2() async {
    allowedIdentifiers = {'abs', 'end'};
    await computeSuggestions('''
class X{var q; f() {q.a^}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void> test_library004_1() async {
    allowedIdentifiers = {'JsonDecoder', 'JsonDecoderX'};
    await computeSuggestions('''
            library foo;
            import 'dart:convert' as json;
            class JsonDecoderX{}
            f1() {var x=new json.^}
            f2() {var x=new json.JsonDe}
            f3() {var x=new json.JsonDecoder}
''');
    assertResponse(r'''
suggestions
  JsonDecoder
    kind: constructorInvocation
  dynamic
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_library004_2() async {
    allowedIdentifiers = {'JsonDecoder', 'JsonDecoderX'};
    await computeSuggestions('''
            library foo;
            import 'dart:convert' as json;
            class JsonDecoderX{}
            f1() {var x=new json.}
            f2() {var x=new json.JsonDe^}
            f3() {var x=new json.JsonDecoder}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 6
suggestions
  JsonDecoder
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 6
suggestions
  JsonDecoder
    kind: constructorInvocation
  dynamic
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_library004_3() async {
    allowedIdentifiers = {'JsonDecoder', 'JsonDecoderX'};
    await computeSuggestions('''
            library foo;
            import 'dart:convert' as json;
            class JsonDecoderX{}
            f1() {var x=new json.}
            f2() {var x=new json.JsonDe}
            f3() {var x=new json.JsonDecoder^}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 11
suggestions
  JsonDecoder
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 11
suggestions
  JsonDecoder
    kind: constructorInvocation
  dynamic
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_library005_1() async {
    allowedIdentifiers = {'abs'};
    await computeSuggestions('''
var PHI = 0;void f(){PHI=5.3;PHI.abs().^ Object x;}
''');
    assertResponse(r'''
suggestions
  abs
    kind: methodInvocation
''');
  }

  Future<void> test_library006_1() async {
    allowedIdentifiers = {'i1', 'i2', 'e1a', 'e2a', 'e1b'};
    newFile('$testPackageLibPath/imp1.dart', '''
library imp1;
export 'exp1a.dart';
i1() {}
''');
    newFile('$testPackageLibPath/imp2.dart', '''
library imp2;
export 'exp2a.dart';
i2() {}
''');
    newFile('$testPackageLibPath/exp1a.dart', '''
library exp1a;
export 'exp1b.dart';
e1a() {}
''');
    newFile('$testPackageLibPath/exp1b.dart', '''
library exp1b;
e1b() {}
''');
    newFile('$testPackageLibPath/exp2a.dart', '''
library exp2a;
e2a() {}
''');
    await computeSuggestions('''
import 'imp1.dart';
import 'imp2.dart';
void f() {^
  i1();
  i2();
  e1a();
  e1b();
  e2a();
}
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  e1a
    kind: functionInvocation
  e1b
    kind: functionInvocation
  e2a
    kind: functionInvocation
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  i1
    kind: functionInvocation
  i2
    kind: functionInvocation
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_library007_1() async {
    allowedIdentifiers = {'l1t', '_l1t'};
    newFile('$testPackageLibPath/l1.dart', '''
library l1;
var _l1t; var l1t = _l1t;
''');
    await computeSuggestions('''
import 'l1.dart';
void f() {
  var x = l^
  var y = _
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  l1t
    kind: topLevelVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  l1t
    kind: topLevelVariable
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_library007_2() async {
    allowedIdentifiers = {'_l1t'};
    newFile('$testPackageLibPath/l1.dart', '''
library l1;
var _l1t; var l1t = _l1t;
''');
    await computeSuggestions('''
import 'l1.dart';
void f() {
  var x = l
  var y = _^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_library008_1() async {
    allowedIdentifiers = {'publicMethod', 'privateMethod'};
    newFile('$testPackageLibPath/public.dart', '''
library public;
class NonPrivate {
  void publicMethod() {
  }
}
''');
    newFile('$testPackageLibPath/private.dart', '''
library _private;
import 'public.dart';
class Private extends NonPrivate {
  void privateMethod() {
  }
}
''');
    await computeSuggestions('''
import 'private.dart';
import 'public.dart';
class Test {
  void test() {
    NonPrivate x = new NonPrivate();
    x.^ //publicMethod but not privateMethod should appear
  }
}
''');
    assertResponse(r'''
suggestions
  publicMethod
    kind: methodInvocation
''');
  }

  Future<void> test_library009_1() async {
    allowedIdentifiers = {'X', 'm', 'Y'};
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
int X = 1;
void m(){}
class Y {}
''');
    await computeSuggestions('''
import 'lib.dart' as Q;
void a() {
  var x = Q.^
}
void b() {
  var x = [Q.]
}
void c() {
  var x = new List.filled([Q.], null)
}
void d() {
  new Q.
}
''');
    assertResponse(r'''
suggestions
  X
    kind: topLevelVariable
  Y
    kind: class
  m
    kind: functionInvocation
''');
  }

  Future<void> test_library009_2() async {
    allowedIdentifiers = {'X', 'm', 'Y'};
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
int X = 1;
void m(){}
class Y {}
''');
    await computeSuggestions('''
import 'lib.dart' as Q;
void a() {
  var x = Q.
}
void b() {
  var x = [Q.^]
}
void c() {
  var x = new List.filled([Q.], null)
}
void d() {
  new Q.
}
''');
    assertResponse(r'''
suggestions
  X
    kind: topLevelVariable
  Y
    kind: class
  m
    kind: functionInvocation
''');
  }

  Future<void> test_library009_3() async {
    allowedIdentifiers = {'X', 'm', 'Y'};
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
int X = 1;
void m(){}
class Y {}
''');
    await computeSuggestions('''
import 'lib.dart' as Q;
void a() {
  var x = Q.
}
void b() {
  var x = [Q.]
}
void c() {
  var x = new List.filled([Q.^], null)
}
void d() {
  new Q.
}
''');
    assertResponse(r'''
suggestions
  X
    kind: topLevelVariable
  Y
    kind: class
  m
    kind: functionInvocation
''');
  }

  Future<void> test_library009_4() async {
    allowedIdentifiers = {'Y', 'm', 'X'};
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
int X = 1;
void m(){}
class Y {}
''');
    await computeSuggestions('''
import 'lib.dart' as Q;
void a() {
  var x = Q.
}
void b() {
  var x = [Q.]
}
void c() {
  var x = new List.filled([Q.], null)
}
void d() {
  new Q.^
}
''');
    assertResponse(r'''
suggestions
  Y
    kind: constructorInvocation
''');
  }

  Future<void> test_memberOfPrivateClass_otherLibrary_1() async {
    allowedIdentifiers = {'foo'};
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
class _A {
  foo() {}
}
class A extends _A {}
''');
    await computeSuggestions('''
import 'lib.dart';
void f(A a) {
  a.^
}
''');
    assertResponse(r'''
suggestions
  foo
    kind: methodInvocation
''');
  }

  Future<void>
      test_noPrivateElement_otherLibrary_constructor_1_withImport() async {
    allowedIdentifiers = {'f', '_f'};
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
class A {
  var f;
  var _f;
  void m() {_f;}
}
''');
    await computeSuggestions('''
import 'lib.dart';
void f() {
  new A.^
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void>
      test_noPrivateElement_otherLibrary_constructor_1_withoutImport() async {
    allowedIdentifiers = {'f', '_f'};
    await computeSuggestions('''
import 'lib.dart';
void f() {
  new A.^
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_noPrivateElement_otherLibrary_member_1() async {
    allowedIdentifiers = {'f', '_f'};
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
class A {
  var f;
  var _f;
  void m() {_f;}
}
''');
    await computeSuggestions('''
import 'lib.dart';
void f(A a) {
  a.^
}
''');
    assertResponse(r'''
suggestions
  f
    kind: field
''');
  }

  Future<void> test_single_2() async {
    allowedIdentifiers = {'B'};
    await computeSuggestions('''
class A {int x; ^mth() {int y = this.x;}}class B{}
''');
    assertResponse(r'''
replacement
  right: 3
suggestions
  B
    kind: class
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }
}
