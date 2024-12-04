// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/common/elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/names.dart';
import 'package:compiler/src/js_model/js_world.dart' show JClosedWorld;
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/util/memory_compiler.dart';

const String source = '''

mixin Mixin<T> {
  void method(T t) {}
}
class Super {}
class Class extends Super with Mixin<int> {}

main() {
  Class().method(0);
}
''';

main() {
  asyncTest(() async {
    CompilationResult result =
        await (runCompiler(memorySourceFiles: {'main.dart': source}));
    Expect.isTrue(result.isSuccess);
    Compiler compiler = result.compiler!;
    JClosedWorld closedWorld = compiler.backendClosedWorldForTesting!;
    ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
    ClassEntity cls = elementEnvironment.lookupClass(
        elementEnvironment.mainLibrary!, 'Class')!;
    ClassEntity mixin = elementEnvironment.lookupClass(
        elementEnvironment.mainLibrary!, 'Mixin')!;
    final method =
        elementEnvironment.lookupClassMember(cls, PublicName('method'));
    Expect.isNotNull(method);
    Expect.equals(mixin, method!.enclosingClass);
    Expect.isFalse(method.isAbstract);
  });
}
