// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import 'package:front_end/src/api_unstable/dart2js.dart' as ir
    show LocatedMessage;

import '../diagnostics/diagnostic_listener.dart';
import '../diagnostics/messages.dart';
import '../diagnostics/source_span.dart';
import '../kernel/element_map_impl.dart';
import '../environment.dart';
import '../ir/static_type.dart';
import '../js_backend/annotations.dart';
import '../options.dart';
import '../serialization/serialization.dart';
import '../util/enumset.dart';
import 'annotations.dart';
import 'constants.dart';
import 'impact.dart';
import 'scope.dart';

class ModularCore {
  final ir.Component component;
  final Dart2jsConstantEvaluator constantEvaluator;

  ModularCore(this.component, this.constantEvaluator);
}

class ModularMemberData {
  final ScopeModel scopeModel;
  final ImpactBuilderData impactBuilderData;

  ModularMemberData(this.scopeModel, this.impactBuilderData);
}

abstract class ModularStrategy {
  List<PragmaAnnotationData> getPragmaAnnotationData(ir.Member node);

  // TODO(johnniwinther): Avoid the need for passing [pragmaAnnotations].
  ModularMemberData getModularMemberData(
      ir.Member node, EnumSet<PragmaAnnotation> pragmaAnnotations);
}

/// Data computed for an entire compilation module.
class ModuleData {
  static const String tag = 'ModuleData';

  // TODO(joshualitt) Support serializing ModularMemberData;
  final Map<ir.Member, ImpactBuilderData> impactData;

  ModuleData(this.impactData);

  factory ModuleData.fromDataSource(DataSource source) {
    source.begin(tag);
    var impactData = source
        .readMemberNodeMap(() => ImpactBuilderData.fromDataSource(source));
    source.end(tag);
    return ModuleData(impactData);
  }

  void toDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeMemberNodeMap<ImpactBuilderData>(
        impactData, (e) => e.toDataSink(sink));
    sink.end(tag);
  }
}

/// Compute [ModularMemberData] from the IR.
ModularMemberData computeModularMemberData(ir.Member node,
    {CompilerOptions options,
    ir.TypeEnvironment typeEnvironment,
    ir.ClassHierarchy classHierarchy,
    ScopeModel scopeModel,
    EnumSet<PragmaAnnotation> annotations}) {
  var staticTypeCache = StaticTypeCacheImpl();
  var impactBuilderData = ImpactBuilder(
          ir.StaticTypeContext(node, typeEnvironment, cache: staticTypeCache),
          staticTypeCache,
          classHierarchy,
          scopeModel.variableScopeModel,
          useAsserts: options.enableUserAssertions,
          inferEffectivelyFinalVariableTypes:
              !annotations.contains(PragmaAnnotation.disableFinal))
      .computeImpact(node);
  return ModularMemberData(scopeModel, impactBuilderData);
}

ModuleData computeModuleData(
    ir.Component component,
    Set<Uri> includedLibraries,
    CompilerOptions options,
    DiagnosticReporter reporter,
    Environment environment,
    KernelToElementMapImpl elementMap) {
  var classHierarchy = elementMap.classHierarchy;
  var typeEnvironment = elementMap.typeEnvironment;
  var constantEvaluator = elementMap.constantEvaluator;
  var result = <ir.Member, ImpactBuilderData>{};
  void computeForMember(ir.Member member) {
    var scopeModel = ScopeModel.from(member, constantEvaluator);
    var annotations = processMemberAnnotations(
        options, reporter, member, computePragmaAnnotationDataFromIr(member));
    result[member] = computeModularMemberData(member,
            options: options,
            typeEnvironment: typeEnvironment,
            classHierarchy: classHierarchy,
            scopeModel: scopeModel,
            annotations: annotations)
        .impactBuilderData;
  }

  for (var library in component.libraries) {
    if (!includedLibraries.contains(library.importUri)) continue;
    library.members.forEach(computeForMember);
    for (var cls in library.classes) {
      cls.members.forEach(computeForMember);
    }
  }
  return ModuleData(result);
}

void reportLocatedMessage(DiagnosticReporter reporter,
    ir.LocatedMessage message, List<ir.LocatedMessage> context) {
  DiagnosticMessage diagnosticMessage =
      _createDiagnosticMessage(reporter, message);
  var infos = <DiagnosticMessage>[];
  for (ir.LocatedMessage message in context) {
    infos.add(_createDiagnosticMessage(reporter, message));
  }
  reporter.reportError(diagnosticMessage, infos);
}

DiagnosticMessage _createDiagnosticMessage(
    DiagnosticReporter reporter, ir.LocatedMessage message) {
  var sourceSpan = SourceSpan(
      message.uri, message.charOffset, message.charOffset + message.length);
  return reporter.createMessage(
      sourceSpan, MessageKind.GENERIC, {'text': message.problemMessage});
}
