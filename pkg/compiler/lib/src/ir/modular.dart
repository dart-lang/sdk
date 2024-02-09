// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import '../ir/impact_data.dart';
import '../ir/static_type.dart';
import '../js_backend/annotations.dart';
import '../kernel/element_map.dart';
import '../serialization/serialization.dart';
import '../util/enumset.dart';
import 'annotations.dart';
import 'impact.dart';
import 'scope.dart';

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

/// [ModuleData] is the data computed modularly, i.e. modularly computed impact
/// data. Currently, we aggregate this data when computing the closed world, so it
/// reflects all of the modularly computed data across the entire program.
class ModuleData {
  static const String tag = 'ModuleData';

  // TODO(joshualitt) Support serializing ModularMemberData;
  final Map<Uri, Map<ir.Member, ImpactBuilderData>> impactData;

  ModuleData([Map<Uri, Map<ir.Member, ImpactBuilderData>>? impactData])
      : this.impactData = impactData ?? {};

  factory ModuleData.fromImpactData(
          Map<Uri, Map<ir.Member, ImpactBuilderData>> impactData) =>
      ModuleData(impactData);

  ModuleData readMoreFromDataSource(DataSourceReader source) {
    source.begin(tag);
    int uriCount = source.readInt();
    for (int i = 0; i < uriCount; i++) {
      Uri uri = source.readUri();
      impactData[uri] = source
          .readMemberNodeMap(() => ImpactBuilderData.fromDataSource(source));
    }
    source.end(tag);
    return this;
  }

  factory ModuleData.fromDataSource(DataSourceReader source) =>
      ModuleData().readMoreFromDataSource(source);

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeInt(impactData.keys.length);
    impactData.forEach((uri, data) {
      sink.writeUri(uri);
      sink.writeMemberNodeMap<ImpactBuilderData>(
          data, (e) => e.toDataSink(sink));
    });
    sink.end(tag);
  }
}

/// Compute [ModularMemberData] from the IR.
ModularMemberData computeModularMemberData(
    KernelToElementMap elementMap,
    ir.Member node,
    ScopeModel scopeModel,
    EnumSet<PragmaAnnotation> annotations) {
  var staticTypeCache = StaticTypeCacheImpl();
  var impactBuilderData = ImpactBuilder(
          elementMap,
          ir.StaticTypeContext(node, elementMap.typeEnvironment,
              cache: staticTypeCache),
          staticTypeCache,
          elementMap.classHierarchy,
          scopeModel.variableScopeModel,
          useAsserts: elementMap.options.enableUserAssertions,
          inferEffectivelyFinalVariableTypes:
              !annotations.contains(PragmaAnnotation.disableFinal))
      .computeImpact(node);
  return ModularMemberData(scopeModel, impactBuilderData);
}

class ModularCore {
  final ir.Component component;
  final ir.TypeEnvironment typeEnvironment;

  ModularCore(this.component, this.typeEnvironment);
}
