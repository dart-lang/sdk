// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';
import 'package:linter/src/util/unrelated_types_visitor.dart';

const _desc = r'Invocation of `remove` with references of unrelated types.';

const _details = r'''

**DON'T** invoke `remove` on `List` with an instance of different type than
the parameter type.

Doing this will invoke `==` on its elements and most likely will
return `false`.

**BAD:**
```
void someFunction() {
  var list = <int>[];
  if (list.remove('1')) print('someFunction'); // LINT
}
```

**BAD:**
```
void someFunction3() {
  List<int> list = <int>[];
  if (list.remove('1')) print('someFunction3'); // LINT
}
```

**BAD:**
```
void someFunction8() {
  List<DerivedClass2> list = <DerivedClass2>[];
  DerivedClass3 instance;
  if (list.remove(instance)) print('someFunction8'); // LINT
}
```

**BAD:**
```
abstract class SomeList<E> implements List<E> {}

abstract class MyClass implements SomeList<int> {
  bool badMethod(String thing) => this.remove(thing); // LINT
}
```

**GOOD:**
```
void someFunction10() {
  var list = [];
  if (list.remove(1)) print('someFunction10'); // OK
}
```

**GOOD:**
```
void someFunction1() {
  var list = <int>[];
  if (list.remove(1)) print('someFunction1'); // OK
}
```

**GOOD:**
```
void someFunction4() {
  List<int> list = <int>[];
  if (list.remove(1)) print('someFunction4'); // OK
}
```

**GOOD:**
```
void someFunction5() {
  List<ClassBase> list = <ClassBase>[];
  DerivedClass1 instance;
  if (list.remove(instance)) print('someFunction5'); // OK
}

abstract class ClassBase {}

class DerivedClass1 extends ClassBase {}
```

**GOOD:**
```
void someFunction6() {
  List<Mixin> list = <Mixin>[];
  DerivedClass2 instance;
  if (list.remove(instance)) print('someFunction6'); // OK
}

abstract class ClassBase {}

abstract class Mixin {}

class DerivedClass2 extends ClassBase with Mixin {}
```

**GOOD:**
```
void someFunction7() {
  List<Mixin> list = <Mixin>[];
  DerivedClass3 instance;
  if (list.remove(instance)) print('someFunction7'); // OK
}

abstract class ClassBase {}

abstract class Mixin {}

class DerivedClass3 extends ClassBase implements Mixin {}
```

''';

class ListRemoveUnrelatedType extends LintRule {
  _Visitor _visitor;

  ListRemoveUnrelatedType()
      : super(
            name: 'list_remove_unrelated_type',
            description: _desc,
            details: _details,
            group: Group.errors) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends UnrelatedTypesVisitor {
  static final _DEFINITION = new InterfaceTypeDefinition('List', 'dart.core');

  _Visitor(LintRule rule) : super(rule);

  @override
  InterfaceTypeDefinition get definition => _DEFINITION;

  @override
  String get methodName => 'remove';
}
