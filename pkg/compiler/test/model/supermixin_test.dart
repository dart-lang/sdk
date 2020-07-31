// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:expect/expect.dart';
import '../helpers/program_lookup.dart';
import '../helpers/memory_compiler.dart';

const String source = r'''
import 'package:expect/expect.dart';

class SuperA {
  method1(a) => 'A$a';
}

class SuperB extends SuperA {
  method1(a) => 'B$a';
}

class Mixin extends SuperA {
  method1(a) => super.method1('M$a');
  method2(a) => 'M$a';
}

class Class extends SuperB with Mixin {}

main() {
  var c = new Class();
  Expect.equals("BMC", c.method1('C'));
  Expect.equals("MC", c.method2('C'));
}
''';

main() {
  asyncTest(() async {
    CompilationResult result = await runCompiler(
        memorySourceFiles: {'main.dart': source},
        options: <String>[Flags.disableInlining]);
    Expect.isTrue(result.isSuccess);

    JElementEnvironment elementEnvironment =
        result.compiler.backendClosedWorldForTesting.elementEnvironment;

    ClassEntity cls = lookupClass(elementEnvironment, 'Class');
    ClassEntity mixin = lookupClass(elementEnvironment, 'Mixin');
    ClassEntity superA = lookupClass(elementEnvironment, 'SuperA');
    ClassEntity superB = lookupClass(elementEnvironment, 'SuperB');
    ClassEntity superClass = elementEnvironment.getSuperClass(cls);

    Expect.isTrue(elementEnvironment.isSuperMixinApplication(superClass));
    Expect.equals(mixin, elementEnvironment.getEffectiveMixinClass(superClass));
    Expect.equals(superA, elementEnvironment.getSuperClass(mixin));
    Expect.equals(superB, elementEnvironment.getSuperClass(superClass));

    MemberEntity method1 = lookupMember(elementEnvironment, 'Class.method1');
    Expect.equals(superClass, method1.enclosingClass);
    MemberEntity method2 = lookupMember(elementEnvironment, 'Class.method2');
    Expect.equals(mixin, method2.enclosingClass);

    ProgramLookup lookup = new ProgramLookup(result.compiler.backendStrategy);
    ClassData data = lookup.getClassData(superClass);
    Expect.isNotNull(data.getMethod(method1));
    Expect.isNull(data.getMethod(method2));
  });
}
