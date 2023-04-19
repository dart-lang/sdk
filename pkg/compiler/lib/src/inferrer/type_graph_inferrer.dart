// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_graph_inferrer;

import 'package:kernel/ast.dart' as ir;
import '../closure.dart';
import '../common/metrics.dart' show Metrics;
import '../compiler.dart';
import '../elements/entities.dart';
import '../js_backend/inferred_data.dart';
import '../js_model/elements.dart' show JClosureCallMethod;
import '../js_model/js_world.dart';
import '../js_model/locals.dart';
import 'abstract_value_domain.dart';
import 'engine.dart';
import 'engine.dart' as engine;
import 'type_graph_nodes.dart';
import 'types.dart';

class TypeGraphInferrer implements TypesInferrer {
  late InferrerEngine inferrer;
  final JClosedWorld closedWorld;

  final Compiler _compiler;
  final GlobalLocalsMap _globalLocalsMap;
  final InferredDataBuilder _inferredDataBuilder;
  Metrics _metrics = Metrics.none();

  TypeGraphInferrer(this._compiler, this.closedWorld, this._globalLocalsMap,
      this._inferredDataBuilder);

  String get name => 'Graph inferrer';

  @override
  Metrics get metrics => _metrics;

  AbstractValueDomain get abstractValueDomain =>
      closedWorld.abstractValueDomain;

  @override
  GlobalTypeInferenceResults analyzeMain(FunctionEntity main) {
    inferrer = createInferrerEngineFor(main);
    inferrer.runOverAllElements();
    _metrics = inferrer.metrics;
    closedWorld.abstractValueDomain.finalizeMetrics();
    return buildResults();
  }

  InferrerEngine createInferrerEngineFor(FunctionEntity main) {
    return engine.InferrerEngine(
        _compiler.options,
        _compiler.progress,
        _compiler.reporter,
        _compiler.outputProvider,
        closedWorld,
        main,
        _globalLocalsMap,
        _inferredDataBuilder);
  }

  Iterable<MemberEntity>? getCallersOfForTesting(MemberEntity element) {
    return inferrer.getCallersOfForTesting(element);
  }

  GlobalTypeInferenceResults buildResults() {
    Map<MemberEntity, GlobalTypeInferenceMemberResult> memberResults =
        <MemberEntity, GlobalTypeInferenceMemberResult>{};
    Map<Local, AbstractValue> parameterResults = <Local, AbstractValue>{};

    void createMemberResults(
        MemberEntity member, MemberTypeInformation typeInformation) {
      final data = inferrer.dataOfMember(member).compress();
      bool isJsInterop = closedWorld.nativeData.isJsInteropMember(member);

      late AbstractValue returnType;
      AbstractValue? type;

      if (isJsInterop) {
        returnType = type = abstractValueDomain.dynamicType;
      } else if (member is FunctionEntity) {
        returnType = typeInformation.type;
        type = abstractValueDomain.functionType;
      } else {
        returnType = abstractValueDomain.dynamicType;
        type = typeInformation.type;
      }

      bool throwsAlways =
          // Always throws if the return type was inferred to be non-null empty.
          abstractValueDomain.isEmpty(returnType).isDefinitelyTrue;

      bool isCalledOnce = typeInformation.isCalledExactlyOnce;

      memberResults[member] = GlobalTypeInferenceMemberResultImpl(
          data, returnType, type,
          throwsAlways: throwsAlways, isCalledOnce: isCalledOnce);
    }

    Set<FieldEntity> freeVariables = Set<FieldEntity>();
    inferrer.types.forEachMemberType(
        (MemberEntity member, MemberTypeInformation typeInformation) {
      createMemberResults(member, typeInformation);
      if (member is JClosureCallMethod) {
        final info = closedWorld.closureDataLookup.getScopeInfo(member)
            as ClosureRepresentationInfo;
        info.forEachFreeVariable(_globalLocalsMap.getLocalsMap(member),
            (Local from, FieldEntity to) {
          freeVariables.add(to);
        });
      }
    });
    for (FieldEntity field in freeVariables) {
      if (!memberResults.containsKey(field)) {
        MemberTypeInformation typeInformation =
            inferrer.types.getInferredTypeOfMember(field);
        createMemberResults(field, typeInformation);
      }
    }

    inferrer.types.forEachParameterType(
        (Local parameter, ParameterTypeInformation typeInformation) {
      AbstractValue type = typeInformation.type;
      parameterResults[parameter] = type;
    });

    Map<ir.TreeNode, AbstractValue> allocatedLists = {};
    Map<ir.TreeNode, AbstractValue> allocatedRecords = {};
    inferrer.types.allocatedLists
        .forEach((ir.TreeNode node, ListTypeInformation typeInformation) {
      allocatedLists[node] = typeInformation.type;
    });
    inferrer.types.allocatedRecords
        .forEach((ir.TreeNode node, RecordTypeInformation typeInformation) {
      allocatedRecords[node] = typeInformation.type;
    });

    GlobalTypeInferenceResults results = GlobalTypeInferenceResultsImpl(
        closedWorld,
        _globalLocalsMap,
        _inferredDataBuilder.close(closedWorld),
        memberResults,
        parameterResults,
        inferrer.returnsListElementTypeSet,
        allocatedLists,
        allocatedRecords);

    inferrer.clear();

    return results;
  }
}
