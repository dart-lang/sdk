// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that the dart2js copy of [KernelVisitor] generates the expected class
/// hierarchy.

import 'package:compiler/src/commandline_options.dart' show Flags;
import 'package:compiler/src/compiler.dart' show Compiler;
import 'package:compiler/src/js_backend/backend.dart' show JavaScriptBackend;
import 'package:compiler/src/library_loader.dart' show LoadedLibraries;
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart';
import 'package:test/test.dart';

import '../memory_compiler.dart';

main(List<String> arguments) {
  Compiler compiler = compilerFor(memorySourceFiles: {
    'main.dart': '''
      class S {
        sMethod() {}
      }
      class M {
        mMethod() {}
      }
      class C extends S with M {
        cMethod() {}
      }
      main() {}
      '''
  }, options: [
    Flags.analyzeOnly,
    Flags.analyzeAll,
    Flags.useKernel
  ]);
  test('mixin', () async {
    Uri mainUri = Uri.parse('memory:main.dart');
    await compiler.run(mainUri);
    LoadedLibraries libraries =
        await compiler.libraryLoader.loadLibrary(mainUri);
    compiler.processLoadedLibraries(libraries);
    JavaScriptBackend backend = compiler.backend;
    ir.Program program = backend.kernelTask.buildProgram(libraries.rootLibrary);
    ClosedWorldClassHierarchy hierarchy =
        new ClosedWorldClassHierarchy(program);

    ir.Class getClass(String name) {
      for (ir.Class cls in hierarchy.classes) {
        if (cls.enclosingLibrary.importUri == mainUri && cls.name == name) {
          if (arguments.contains('-v')) {
            print('$cls');
            print(' dispatch targets:');
            hierarchy
                .getDispatchTargets(cls)
                .forEach((member) => print('  $member'));
          }
          return cls;
        }
      }
      fail('Class $name not found.');
      throw "Not reachable.";
    }

    ir.Class classS = getClass('S');
    ir.Class classM = getClass('M');
    ir.Class classC = getClass('C');

    void checkInheritance(ir.Class superClass, ir.Class subClass) {
      for (ir.Member member in hierarchy.getDispatchTargets(superClass)) {
        expect(
            hierarchy.getDispatchTarget(subClass, member.name), equals(member),
            reason: 'Unexpected dispatch target for ${member.name} '
                'in $subClass');
      }
    }

    checkInheritance(classS, classC);
    checkInheritance(classM, classC);
  });
}
