// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:async_helper/async_helper.dart" show asyncTest;

import "package:expect/expect.dart" show Expect;

import "package:kernel/ast.dart" show Class, Component, Library;

import "package:kernel/core_types.dart" show CoreTypes;

import "package:kernel/target/targets.dart" show NoneTarget, TargetFlags;

import 'package:kernel/testing/type_parser_environment.dart' show parseComponent;

import "package:front_end/src/api_prototype/compiler_options.dart"
    show CompilerOptions;

import "package:front_end/src/base/processed_options.dart"
    show ProcessedOptions;

import "package:front_end/src/fasta/builder/class_builder.dart";

import "package:front_end/src/fasta/compiler_context.dart" show CompilerContext;

import "package:front_end/src/fasta/dill/dill_loader.dart" show DillLoader;

import "package:front_end/src/fasta/dill/dill_target.dart" show DillTarget;

import "package:front_end/src/fasta/kernel/kernel_builder.dart"
    show ClassHierarchyBuilder;

import "package:front_end/src/fasta/ticker.dart" show Ticker;

const String expectedHierarchy = """
Object:
  superclasses:
  interfaces:
  classMembers:
  classSetters:

A:
  superclasses:
    Object
  interfaces:
  classMembers:
  classSetters:

B:
  Longest path to Object: 2
  superclasses:
    Object
  interfaces: A
  classMembers:
  classSetters:
  interfaceMembers:
  interfaceSetters:

C:
  Longest path to Object: 2
  superclasses:
    Object
  interfaces: A
  classMembers:
  classSetters:
  interfaceMembers:
  interfaceSetters:

D:
  Longest path to Object: 3
  superclasses:
    Object
  interfaces: B<T>, A, C<U>
  classMembers:
  classSetters:
  interfaceMembers:
  interfaceSetters:

E:
  Longest path to Object: 4
  superclasses:
    Object
  interfaces: D<int,double>, B<int>, A, C<double>
  classMembers:
  classSetters:
  interfaceMembers:
  interfaceSetters:

F:
  Longest path to Object: 4
  superclasses:
    Object
  interfaces: D<int,bool>, B<int>, A, C<bool>
  classMembers:
  classSetters:
  interfaceMembers:
  interfaceSetters:
""";

main() {
  final Ticker ticker = new Ticker(isVerbose: false);
  final Component component = parseComponent("""
class A;
class B<T> implements A;
class C<U> implements A;
class D<T, U> implements B<T>, C<U>;
class E implements D<int, double>;
class F implements D<int, bool>;""",
      Uri.parse("org-dartlang-test:///library.dart"));

  final CompilerContext context = new CompilerContext(new ProcessedOptions(
      options: new CompilerOptions()
        ..packagesFileUri = Uri.base.resolve(".packages")));

  asyncTest(() => context.runInContext<void>((_) async {
        DillTarget target = new DillTarget(
            ticker,
            await context.options.getUriTranslator(),
            new NoneTarget(new TargetFlags()));
        final DillLoader loader = target.loader;
        loader.appendLibraries(component);
        await target.buildOutlines();
        ClassBuilder objectClass =
            loader.coreLibrary.lookupLocalMember("Object", required: true);
        ClassHierarchyBuilder hierarchy = new ClassHierarchyBuilder(
            objectClass, loader, new CoreTypes(component));
        Library library = component.libraries.last;
        for (Class cls in library.classes) {
          hierarchy.getNodeFromClass(cls);
        }
        Expect.stringEquals(
            expectedHierarchy, hierarchy.nodes.values.join("\n"));
      }));
}
