// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common/elements.dart';
import 'package:compiler/src/common/names.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/inferrer/abstract_value_domain.dart';
import 'package:compiler/src/inferrer/typemasks/masks.dart';
import 'package:compiler/src/js_model/element_map.dart';
import 'package:compiler/src/js_model/js_world.dart';
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:compiler/src/util/memory_compiler.dart';

const String source = '''
import 'package:expect/expect.dart' deferred as expect;

main() {
  callLoadLibrary();
}

callLoadLibrary() => expect.loadLibrary();
''';

main() async {
  asyncTest(() async {
    print('--test ----------------------------------------------------');
    await runTest([], trust: false);
    print('--test --omit-implicit-checks -----------------------------');
    await runTest([Flags.omitImplicitChecks]);
  });
}

runTest(List<String> options, {bool trust = true}) async {
  CompilationResult result = await runCompiler(
      memorySourceFiles: {'main.dart': source}, options: options);
  Expect.isTrue(result.isSuccess);
  Compiler compiler = result.compiler!;
  JClosedWorld closedWorld = compiler.backendClosedWorldForTesting!;
  AbstractValueDomain abstractValueDomain = closedWorld.abstractValueDomain;
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
  LibraryEntity helperLibrary =
      elementEnvironment.lookupLibrary(Uris.dart__js_helper)!;
  final loadDeferredLibrary = elementEnvironment.lookupLibraryMember(
      helperLibrary, 'loadDeferredLibrary') as FunctionEntity;
  TypeMask typeMask;

  KernelToLocalsMap localsMap = compiler
      .globalInference.resultsForTesting!.globalLocalsMap
      .getLocalsMap(loadDeferredLibrary);
  MemberDefinition definition =
      closedWorld.elementMap.getMemberDefinition(loadDeferredLibrary);
  final procedure = definition.node as ir.Procedure;
  typeMask = compiler.globalInference.resultsForTesting!.resultOfParameter(
      localsMap.getLocalVariable(
          procedure.function.positionalParameters.first)) as TypeMask;

  Expect.equals(
      trust ? abstractValueDomain.stringType : abstractValueDomain.dynamicType,
      typeMask);
}
