// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/names.dart';
import 'package:compiler/src/universe/call_structure.dart';
import 'package:compiler/src/universe/class_hierarchy.dart';
import 'package:compiler/src/universe/selector.dart';
import 'package:compiler/src/js_model/js_world.dart' show JClosedWorld;
import '../helpers/type_test_helper.dart';

void main() {
  asyncTest(() async {
    await testClassSets();
  });
}

const String CLASSES = r"""
class Superclass {
  foo() {}
}
class Subclass extends Superclass {
  bar() {}
}
class Subtype implements Superclass {
  bar() {}
  noSuchMethod(_) {}
}
""";

testClassSets() async {
  late Selector foo, bar, baz;
  late JClosedWorld closedWorld;
  late ClassEntity superclass, subclass, subtype;
  late String testMode;

  Future run(List<String> instantiated) async {
    print('---- testing $instantiated ---------------------------------------');
    StringBuffer main = StringBuffer();
    main.writeln(CLASSES);
    main.writeln('main() {');
    main.writeln('  dynamic d;');
    main.writeln('  d.foo(); d.bar(); d.baz();');
    for (String cls in instantiated) {
      main.writeln('  $cls();');
    }
    main.writeln('}');
    testMode = '$instantiated';

    var env =
        await TypeEnvironment.create(main.toString(), testBackendWorld: true);
    foo = Selector.call(const PublicName('foo'), CallStructure.noArgs);
    bar = Selector.call(const PublicName('bar'), CallStructure.noArgs);
    baz = Selector.call(const PublicName('baz'), CallStructure.noArgs);

    closedWorld = env.jClosedWorld;
    superclass = env.getElement('Superclass') as ClassEntity;
    subclass = env.getElement('Subclass') as ClassEntity;
    subtype = env.getElement('Subtype') as ClassEntity;
  }

  void check(ClassEntity cls, ClassQuery query, Selector selector,
      bool expectedResult) {
    bool result = closedWorld.needsNoSuchMethod(cls, selector, query);
    Expect.equals(
        expectedResult,
        result,
        'Unexpected result for $selector in $cls ($query) '
        'for instantiations $testMode');
  }

  await run([]);

  Expect.isFalse(closedWorld.classHierarchy.isDirectlyInstantiated(superclass));
  Expect.isFalse(
      closedWorld.classHierarchy.isIndirectlyInstantiated(superclass));
  Expect.isFalse(closedWorld.isImplemented(superclass));

  Expect.isFalse(closedWorld.classHierarchy.isDirectlyInstantiated(subclass));
  Expect.isFalse(closedWorld.classHierarchy.isIndirectlyInstantiated(subclass));
  Expect.isFalse(closedWorld.isImplemented(subclass));

  Expect.isFalse(closedWorld.classHierarchy.isDirectlyInstantiated(subtype));
  Expect.isFalse(closedWorld.classHierarchy.isIndirectlyInstantiated(subtype));
  Expect.isFalse(closedWorld.isImplemented(subtype));

  check(superclass, ClassQuery.exact, foo, false);
  check(superclass, ClassQuery.exact, bar, false);
  check(superclass, ClassQuery.exact, baz, false);
  check(superclass, ClassQuery.subclass, foo, false);
  check(superclass, ClassQuery.subclass, bar, false);
  check(superclass, ClassQuery.subclass, baz, false);
  check(superclass, ClassQuery.subtype, foo, false);
  check(superclass, ClassQuery.subtype, bar, false);
  check(superclass, ClassQuery.subtype, baz, false);

  check(subclass, ClassQuery.exact, foo, false);
  check(subclass, ClassQuery.exact, bar, false);
  check(subclass, ClassQuery.exact, baz, false);
  check(subclass, ClassQuery.subclass, foo, false);
  check(subclass, ClassQuery.subclass, bar, false);
  check(subclass, ClassQuery.subclass, baz, false);
  check(subclass, ClassQuery.subtype, foo, false);
  check(subclass, ClassQuery.subtype, bar, false);
  check(subclass, ClassQuery.subtype, baz, false);

  check(subtype, ClassQuery.exact, foo, false);
  check(subtype, ClassQuery.exact, bar, false);
  check(subtype, ClassQuery.exact, baz, false);
  check(subtype, ClassQuery.subclass, foo, false);
  check(subtype, ClassQuery.subclass, bar, false);
  check(subtype, ClassQuery.subclass, baz, false);
  check(subtype, ClassQuery.subtype, foo, false);
  check(subtype, ClassQuery.subtype, bar, false);
  check(subtype, ClassQuery.subtype, baz, false);

  await run(['Superclass']);

  Expect.isTrue(closedWorld.classHierarchy.isDirectlyInstantiated(superclass));
  Expect.isFalse(
      closedWorld.classHierarchy.isIndirectlyInstantiated(superclass));
  Expect.isTrue(closedWorld.isImplemented(superclass));

  Expect.isFalse(closedWorld.classHierarchy.isDirectlyInstantiated(subclass));
  Expect.isFalse(closedWorld.classHierarchy.isIndirectlyInstantiated(subclass));
  Expect.isFalse(closedWorld.isImplemented(subclass));

  Expect.isFalse(closedWorld.classHierarchy.isDirectlyInstantiated(subtype));
  Expect.isFalse(closedWorld.classHierarchy.isIndirectlyInstantiated(subtype));
  Expect.isFalse(closedWorld.isImplemented(subtype));

  check(superclass, ClassQuery.exact, foo, false);
  check(superclass, ClassQuery.exact, bar, true);
  check(superclass, ClassQuery.exact, baz, true);
  check(superclass, ClassQuery.subclass, foo, false);
  check(superclass, ClassQuery.subclass, bar, true);
  check(superclass, ClassQuery.subclass, baz, true);
  check(superclass, ClassQuery.subtype, foo, false);
  check(superclass, ClassQuery.subtype, bar, true);
  check(superclass, ClassQuery.subtype, baz, true);

  check(subclass, ClassQuery.exact, foo, false);
  check(subclass, ClassQuery.exact, bar, false);
  check(subclass, ClassQuery.exact, baz, false);
  check(subclass, ClassQuery.subclass, foo, false);
  check(subclass, ClassQuery.subclass, bar, false);
  check(subclass, ClassQuery.subclass, baz, false);
  check(subclass, ClassQuery.subtype, foo, false);
  check(subclass, ClassQuery.subtype, bar, false);
  check(subclass, ClassQuery.subtype, baz, false);

  check(subtype, ClassQuery.exact, foo, false);
  check(subtype, ClassQuery.exact, bar, false);
  check(subtype, ClassQuery.exact, baz, false);
  check(subtype, ClassQuery.subclass, foo, false);
  check(subtype, ClassQuery.subclass, bar, false);
  check(subtype, ClassQuery.subclass, baz, false);
  check(subtype, ClassQuery.subtype, foo, false);
  check(subtype, ClassQuery.subtype, bar, false);
  check(subtype, ClassQuery.subtype, baz, false);

  await run(['Subclass']);

  Expect.isFalse(closedWorld.classHierarchy.isDirectlyInstantiated(superclass));
  Expect.isTrue(
      closedWorld.classHierarchy.isIndirectlyInstantiated(superclass));
  Expect.isTrue(closedWorld.isImplemented(superclass));

  Expect.isTrue(closedWorld.classHierarchy.isDirectlyInstantiated(subclass));
  Expect.isFalse(closedWorld.classHierarchy.isIndirectlyInstantiated(subclass));
  Expect.isTrue(closedWorld.isImplemented(subclass));

  Expect.isFalse(closedWorld.classHierarchy.isDirectlyInstantiated(subtype));
  Expect.isFalse(closedWorld.classHierarchy.isIndirectlyInstantiated(subtype));
  Expect.isFalse(closedWorld.isImplemented(subtype));

  check(superclass, ClassQuery.exact, foo, false);
  check(superclass, ClassQuery.exact, bar, false);
  check(superclass, ClassQuery.exact, baz, false);
  check(superclass, ClassQuery.subclass, foo, false);
  check(superclass, ClassQuery.subclass, bar, false);
  check(superclass, ClassQuery.subclass, baz, true);
  check(superclass, ClassQuery.subtype, foo, false);
  check(superclass, ClassQuery.subtype, bar, false);
  check(superclass, ClassQuery.subtype, baz, true);

  check(subclass, ClassQuery.exact, foo, false);
  check(subclass, ClassQuery.exact, bar, false);
  check(subclass, ClassQuery.exact, baz, true);
  check(subclass, ClassQuery.subclass, foo, false);
  check(subclass, ClassQuery.subclass, bar, false);
  check(subclass, ClassQuery.subclass, baz, true);
  check(subclass, ClassQuery.subtype, foo, false);
  check(subclass, ClassQuery.subtype, bar, false);
  check(subclass, ClassQuery.subtype, baz, true);

  check(subtype, ClassQuery.exact, foo, false);
  check(subtype, ClassQuery.exact, bar, false);
  check(subtype, ClassQuery.exact, baz, false);
  check(subtype, ClassQuery.subclass, foo, false);
  check(subtype, ClassQuery.subclass, bar, false);
  check(subtype, ClassQuery.subclass, baz, false);
  check(subtype, ClassQuery.subtype, foo, false);
  check(subtype, ClassQuery.subtype, bar, false);
  check(subtype, ClassQuery.subtype, baz, false);

  await run(['Subtype']);

  Expect.isFalse(closedWorld.classHierarchy.isDirectlyInstantiated(superclass));
  Expect.isFalse(
      closedWorld.classHierarchy.isIndirectlyInstantiated(superclass));
  Expect.isTrue(closedWorld.isImplemented(superclass));

  Expect.isFalse(closedWorld.classHierarchy.isDirectlyInstantiated(subclass));
  Expect.isFalse(closedWorld.classHierarchy.isIndirectlyInstantiated(subclass));
  Expect.isFalse(closedWorld.isImplemented(subclass));

  Expect.isTrue(closedWorld.classHierarchy.isDirectlyInstantiated(subtype));
  Expect.isFalse(closedWorld.classHierarchy.isIndirectlyInstantiated(subtype));
  Expect.isTrue(closedWorld.isImplemented(subtype));

  check(superclass, ClassQuery.exact, foo, false);
  check(superclass, ClassQuery.exact, bar, false);
  check(superclass, ClassQuery.exact, baz, false);
  check(superclass, ClassQuery.subclass, foo, false);
  check(superclass, ClassQuery.subclass, bar, false);
  check(superclass, ClassQuery.subclass, baz, false);
  check(superclass, ClassQuery.subtype, foo, false);
  check(superclass, ClassQuery.subtype, bar, false);
  check(superclass, ClassQuery.subtype, baz, true);

  check(subclass, ClassQuery.exact, foo, false);
  check(subclass, ClassQuery.exact, bar, false);
  check(subclass, ClassQuery.exact, baz, false);
  check(subclass, ClassQuery.subclass, foo, false);
  check(subclass, ClassQuery.subclass, bar, false);
  check(subclass, ClassQuery.subclass, baz, false);
  check(subclass, ClassQuery.subtype, foo, false);
  check(subclass, ClassQuery.subtype, bar, false);
  check(subclass, ClassQuery.subtype, baz, false);

  check(subtype, ClassQuery.exact, foo, false);
  check(subtype, ClassQuery.exact, bar, false);
  check(subtype, ClassQuery.exact, baz, true);
  check(subtype, ClassQuery.subclass, foo, false);
  check(subtype, ClassQuery.subclass, bar, false);
  check(subtype, ClassQuery.subclass, baz, true);
  check(subtype, ClassQuery.subtype, foo, false);
  check(subtype, ClassQuery.subtype, bar, false);
  check(subtype, ClassQuery.subtype, baz, true);

  await run(['Subclass', 'Subtype']);

  Expect.isFalse(closedWorld.classHierarchy.isDirectlyInstantiated(superclass));
  Expect.isTrue(
      closedWorld.classHierarchy.isIndirectlyInstantiated(superclass));
  Expect.isTrue(closedWorld.isImplemented(superclass));

  Expect.isTrue(closedWorld.classHierarchy.isDirectlyInstantiated(subclass));
  Expect.isFalse(closedWorld.classHierarchy.isIndirectlyInstantiated(subclass));
  Expect.isTrue(closedWorld.isImplemented(subclass));

  Expect.isTrue(closedWorld.classHierarchy.isDirectlyInstantiated(subtype));
  Expect.isFalse(closedWorld.classHierarchy.isIndirectlyInstantiated(subtype));
  Expect.isTrue(closedWorld.isImplemented(subtype));

  check(superclass, ClassQuery.exact, foo, false);
  check(superclass, ClassQuery.exact, bar, false);
  check(superclass, ClassQuery.exact, baz, false);
  check(superclass, ClassQuery.subclass, foo, false);
  check(superclass, ClassQuery.subclass, bar, false);
  check(superclass, ClassQuery.subclass, baz, true);
  check(superclass, ClassQuery.subtype, foo, false);
  check(superclass, ClassQuery.subtype, bar, false);
  check(superclass, ClassQuery.subtype, baz, true);

  check(subclass, ClassQuery.exact, foo, false);
  check(subclass, ClassQuery.exact, bar, false);
  check(subclass, ClassQuery.exact, baz, true);
  check(subclass, ClassQuery.subclass, foo, false);
  check(subclass, ClassQuery.subclass, bar, false);
  check(subclass, ClassQuery.subclass, baz, true);
  check(subclass, ClassQuery.subtype, foo, false);
  check(subclass, ClassQuery.subtype, bar, false);
  check(subclass, ClassQuery.subtype, baz, true);

  check(subtype, ClassQuery.exact, foo, false);
  check(subtype, ClassQuery.exact, bar, false);
  check(subtype, ClassQuery.exact, baz, true);
  check(subtype, ClassQuery.subclass, foo, false);
  check(subtype, ClassQuery.subclass, bar, false);
  check(subtype, ClassQuery.subclass, baz, true);
  check(subtype, ClassQuery.subtype, foo, false);
  check(subtype, ClassQuery.subtype, bar, false);
  check(subtype, ClassQuery.subtype, baz, true);
}
