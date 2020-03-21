// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that the additional runtime type support is output to the right
// Files when using deferred loading.

import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/constants/values.dart';
import 'package:compiler/src/deferred_load.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/js_emitter/model.dart';
import 'package:compiler/src/util/util.dart';
import 'package:expect/expect.dart';
import '../helpers/memory_compiler.dart';
import '../helpers/output_collector.dart';
import '../helpers/program_lookup.dart';

class OutputUnitDescriptor {
  final String uri;
  final String member;
  final String name;

  const OutputUnitDescriptor(this.uri, this.member, this.name);
}

run(Map<String, String> sourceFiles, List<OutputUnitDescriptor> outputUnits,
    Map<String, Set<String>> expectedOutputUnits) async {
  OutputCollector collector = new OutputCollector();
  CompilationResult result = await runCompiler(
      memorySourceFiles: sourceFiles, outputProvider: collector);
  Compiler compiler = result.compiler;
  DartTypes dartTypes = compiler.frontendStrategy.commonElements.dartTypes;
  ProgramLookup lookup = new ProgramLookup(compiler.backendStrategy);
  var closedWorld = compiler.backendClosedWorldForTesting;
  var elementEnvironment = closedWorld.elementEnvironment;

  LibraryEntity lookupLibrary(name) {
    return elementEnvironment.lookupLibrary(Uri.parse(name));
  }

  OutputUnit Function(MemberEntity) outputUnitForMember =
      closedWorld.outputUnitData.outputUnitForMember;

  Map<String, Fragment> fragments = {};
  fragments['main'] = lookup.program.mainFragment;

  for (OutputUnitDescriptor descriptor in outputUnits) {
    LibraryEntity library = lookupLibrary(descriptor.uri);
    MemberEntity member =
        elementEnvironment.lookupLibraryMember(library, descriptor.member);
    OutputUnit outputUnit = outputUnitForMember(member);
    fragments[descriptor.name] = lookup.getFragment(outputUnit);
  }

  Map<String, Set<String>> actualOutputUnits = {};

  bool errorsFound = false;

  void processFragment(String fragmentName, Fragment fragment) {
    for (Constant constant in fragment.constants) {
      String text = constant.value.toStructuredText(dartTypes);
      Set<String> expectedConstantUnit = expectedOutputUnits[text];
      if (expectedConstantUnit == null) {
        if (constant.value is DeferredGlobalConstantValue) {
          print('ERROR: No expectancy for $constant found in $fragmentName');
          errorsFound = true;
        }
      } else {
        (actualOutputUnits[text] ??= <String>{}).add(fragmentName);
      }
    }
  }

  fragments.forEach(processFragment);

  expectedOutputUnits.forEach((String constant, Set<String> expectedSet) {
    Set<String> actualSet = actualOutputUnits[constant] ?? const <String>{};
    if (!equalSets(expectedSet, actualSet)) {
      print("ERROR: Constant $constant found in $actualSet, expected "
          "$expectedSet");
      errorsFound = true;
    }
  });

  Expect.isFalse(errorsFound, "Errors found.");
}
