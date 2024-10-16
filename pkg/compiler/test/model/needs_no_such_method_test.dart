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
    foo = Selector.call(const PublicName('foo'), CallStructure.NO_ARGS);
    bar = Selector.call(const PublicName('bar'), CallStructure.NO_ARGS);
    baz = Selector.call(const PublicName('baz'), CallStructure.NO_ARGS);

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

  check(superclass, ClassQuery.EXACT, foo, false);
  check(superclass, ClassQuery.EXACT, bar, false);
  check(superclass, ClassQuery.EXACT, baz, false);
  check(superclass, ClassQuery.SUBCLASS, foo, false);
  check(superclass, ClassQuery.SUBCLASS, bar, false);
  check(superclass, ClassQuery.SUBCLASS, baz, false);
  check(superclass, ClassQuery.SUBTYPE, foo, false);
  check(superclass, ClassQuery.SUBTYPE, bar, false);
  check(superclass, ClassQuery.SUBTYPE, baz, false);

  check(subclass, ClassQuery.EXACT, foo, false);
  check(subclass, ClassQuery.EXACT, bar, false);
  check(subclass, ClassQuery.EXACT, baz, false);
  check(subclass, ClassQuery.SUBCLASS, foo, false);
  check(subclass, ClassQuery.SUBCLASS, bar, false);
  check(subclass, ClassQuery.SUBCLASS, baz, false);
  check(subclass, ClassQuery.SUBTYPE, foo, false);
  check(subclass, ClassQuery.SUBTYPE, bar, false);
  check(subclass, ClassQuery.SUBTYPE, baz, false);

  check(subtype, ClassQuery.EXACT, foo, false);
  check(subtype, ClassQuery.EXACT, bar, false);
  check(subtype, ClassQuery.EXACT, baz, false);
  check(subtype, ClassQuery.SUBCLASS, foo, false);
  check(subtype, ClassQuery.SUBCLASS, bar, false);
  check(subtype, ClassQuery.SUBCLASS, baz, false);
  check(subtype, ClassQuery.SUBTYPE, foo, false);
  check(subtype, ClassQuery.SUBTYPE, bar, false);
  check(subtype, ClassQuery.SUBTYPE, baz, false);

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

  check(superclass, ClassQuery.EXACT, foo, false);
  check(superclass, ClassQuery.EXACT, bar, true);
  check(superclass, ClassQuery.EXACT, baz, true);
  check(superclass, ClassQuery.SUBCLASS, foo, false);
  check(superclass, ClassQuery.SUBCLASS, bar, true);
  check(superclass, ClassQuery.SUBCLASS, baz, true);
  check(superclass, ClassQuery.SUBTYPE, foo, false);
  check(superclass, ClassQuery.SUBTYPE, bar, true);
  check(superclass, ClassQuery.SUBTYPE, baz, true);

  check(subclass, ClassQuery.EXACT, foo, false);
  check(subclass, ClassQuery.EXACT, bar, false);
  check(subclass, ClassQuery.EXACT, baz, false);
  check(subclass, ClassQuery.SUBCLASS, foo, false);
  check(subclass, ClassQuery.SUBCLASS, bar, false);
  check(subclass, ClassQuery.SUBCLASS, baz, false);
  check(subclass, ClassQuery.SUBTYPE, foo, false);
  check(subclass, ClassQuery.SUBTYPE, bar, false);
  check(subclass, ClassQuery.SUBTYPE, baz, false);

  check(subtype, ClassQuery.EXACT, foo, false);
  check(subtype, ClassQuery.EXACT, bar, false);
  check(subtype, ClassQuery.EXACT, baz, false);
  check(subtype, ClassQuery.SUBCLASS, foo, false);
  check(subtype, ClassQuery.SUBCLASS, bar, false);
  check(subtype, ClassQuery.SUBCLASS, baz, false);
  check(subtype, ClassQuery.SUBTYPE, foo, false);
  check(subtype, ClassQuery.SUBTYPE, bar, false);
  check(subtype, ClassQuery.SUBTYPE, baz, false);

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

  check(superclass, ClassQuery.EXACT, foo, false);
  check(superclass, ClassQuery.EXACT, bar, false);
  check(superclass, ClassQuery.EXACT, baz, false);
  check(superclass, ClassQuery.SUBCLASS, foo, false);
  check(superclass, ClassQuery.SUBCLASS, bar, false);
  check(superclass, ClassQuery.SUBCLASS, baz, true);
  check(superclass, ClassQuery.SUBTYPE, foo, false);
  check(superclass, ClassQuery.SUBTYPE, bar, false);
  check(superclass, ClassQuery.SUBTYPE, baz, true);

  check(subclass, ClassQuery.EXACT, foo, false);
  check(subclass, ClassQuery.EXACT, bar, false);
  check(subclass, ClassQuery.EXACT, baz, true);
  check(subclass, ClassQuery.SUBCLASS, foo, false);
  check(subclass, ClassQuery.SUBCLASS, bar, false);
  check(subclass, ClassQuery.SUBCLASS, baz, true);
  check(subclass, ClassQuery.SUBTYPE, foo, false);
  check(subclass, ClassQuery.SUBTYPE, bar, false);
  check(subclass, ClassQuery.SUBTYPE, baz, true);

  check(subtype, ClassQuery.EXACT, foo, false);
  check(subtype, ClassQuery.EXACT, bar, false);
  check(subtype, ClassQuery.EXACT, baz, false);
  check(subtype, ClassQuery.SUBCLASS, foo, false);
  check(subtype, ClassQuery.SUBCLASS, bar, false);
  check(subtype, ClassQuery.SUBCLASS, baz, false);
  check(subtype, ClassQuery.SUBTYPE, foo, false);
  check(subtype, ClassQuery.SUBTYPE, bar, false);
  check(subtype, ClassQuery.SUBTYPE, baz, false);

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

  check(superclass, ClassQuery.EXACT, foo, false);
  check(superclass, ClassQuery.EXACT, bar, false);
  check(superclass, ClassQuery.EXACT, baz, false);
  check(superclass, ClassQuery.SUBCLASS, foo, false);
  check(superclass, ClassQuery.SUBCLASS, bar, false);
  check(superclass, ClassQuery.SUBCLASS, baz, false);
  check(superclass, ClassQuery.SUBTYPE, foo, false);
  check(superclass, ClassQuery.SUBTYPE, bar, false);
  check(superclass, ClassQuery.SUBTYPE, baz, true);

  check(subclass, ClassQuery.EXACT, foo, false);
  check(subclass, ClassQuery.EXACT, bar, false);
  check(subclass, ClassQuery.EXACT, baz, false);
  check(subclass, ClassQuery.SUBCLASS, foo, false);
  check(subclass, ClassQuery.SUBCLASS, bar, false);
  check(subclass, ClassQuery.SUBCLASS, baz, false);
  check(subclass, ClassQuery.SUBTYPE, foo, false);
  check(subclass, ClassQuery.SUBTYPE, bar, false);
  check(subclass, ClassQuery.SUBTYPE, baz, false);

  check(subtype, ClassQuery.EXACT, foo, false);
  check(subtype, ClassQuery.EXACT, bar, false);
  check(subtype, ClassQuery.EXACT, baz, true);
  check(subtype, ClassQuery.SUBCLASS, foo, false);
  check(subtype, ClassQuery.SUBCLASS, bar, false);
  check(subtype, ClassQuery.SUBCLASS, baz, true);
  check(subtype, ClassQuery.SUBTYPE, foo, false);
  check(subtype, ClassQuery.SUBTYPE, bar, false);
  check(subtype, ClassQuery.SUBTYPE, baz, true);

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

  check(superclass, ClassQuery.EXACT, foo, false);
  check(superclass, ClassQuery.EXACT, bar, false);
  check(superclass, ClassQuery.EXACT, baz, false);
  check(superclass, ClassQuery.SUBCLASS, foo, false);
  check(superclass, ClassQuery.SUBCLASS, bar, false);
  check(superclass, ClassQuery.SUBCLASS, baz, true);
  check(superclass, ClassQuery.SUBTYPE, foo, false);
  check(superclass, ClassQuery.SUBTYPE, bar, false);
  check(superclass, ClassQuery.SUBTYPE, baz, true);

  check(subclass, ClassQuery.EXACT, foo, false);
  check(subclass, ClassQuery.EXACT, bar, false);
  check(subclass, ClassQuery.EXACT, baz, true);
  check(subclass, ClassQuery.SUBCLASS, foo, false);
  check(subclass, ClassQuery.SUBCLASS, bar, false);
  check(subclass, ClassQuery.SUBCLASS, baz, true);
  check(subclass, ClassQuery.SUBTYPE, foo, false);
  check(subclass, ClassQuery.SUBTYPE, bar, false);
  check(subclass, ClassQuery.SUBTYPE, baz, true);

  check(subtype, ClassQuery.EXACT, foo, false);
  check(subtype, ClassQuery.EXACT, bar, false);
  check(subtype, ClassQuery.EXACT, baz, true);
  check(subtype, ClassQuery.SUBCLASS, foo, false);
  check(subtype, ClassQuery.SUBCLASS, bar, false);
  check(subtype, ClassQuery.SUBCLASS, baz, true);
  check(subtype, ClassQuery.SUBTYPE, foo, false);
  check(subtype, ClassQuery.SUBTYPE, bar, false);
  check(subtype, ClassQuery.SUBTYPE, baz, true);
}
