// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.10

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../elements/entities.dart';
import '../environment.dart';
import '../ir/annotations.dart';
import '../ir/impact.dart';
import '../ir/modular.dart';
import '../ir/scope.dart';
import '../kernel/dart2js_target.dart';
import '../kernel/native_basic_data.dart';
import '../js_backend/annotations.dart';
import '../kernel/element_map.dart';
import '../options.dart';

class Input {
  final CompilerOptions options;
  final DiagnosticReporter reporter;
  final Environment environment;
  final ir.Component component;
  final List<Uri> libraries;
  final Set<Uri> moduleLibraries;

  Input(this.options, this.reporter, this.environment, this.component,
      this.libraries, this.moduleLibraries);
}

KernelToElementMap _createElementMap(
    CompilerOptions options,
    DiagnosticReporter reporter,
    Environment environment,
    ir.Component component,
    List<Uri> libraries) {
  final elementMap = KernelToElementMap(reporter, environment, options);
  elementMap.addComponent(component);
  IrAnnotationData irAnnotationData =
      processAnnotations(ModularCore(component, elementMap.constantEvaluator));
  final annotationProcessor = KernelAnnotationProcessor(
      elementMap, elementMap.nativeBasicDataBuilder, irAnnotationData);
  for (final uri in libraries) {
    LibraryEntity library = elementMap.elementEnvironment.lookupLibrary(uri);
    if (maybeEnableNative(library.canonicalUri)) {
      annotationProcessor.extractNativeAnnotations(library);
    }
    annotationProcessor.extractJsInteropAnnotations(library);
  }
  return elementMap;
}

ModuleData run(Input input) {
  final options = input.options;
  final reporter = input.reporter;
  final elementMap = _createElementMap(
      options, reporter, input.environment, input.component, input.libraries);
  final result = <ir.Member, ImpactBuilderData>{};
  void computeForMember(ir.Member member) {
    final scopeModel = ScopeModel.from(member, elementMap.constantEvaluator);
    final annotations = processMemberAnnotations(
        options, reporter, member, computePragmaAnnotationDataFromIr(member));
    result[member] =
        computeModularMemberData(elementMap, member, scopeModel, annotations)
            .impactBuilderData;
  }

  for (final library in input.component.libraries) {
    if (!input.moduleLibraries.contains(library.importUri)) continue;
    library.members.forEach(computeForMember);
    for (final cls in library.classes) {
      cls.members.forEach(computeForMember);
    }
  }
  return ModuleData(result);
}
