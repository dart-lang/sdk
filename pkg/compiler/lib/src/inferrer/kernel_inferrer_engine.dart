// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../compiler.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../types/types.dart';
import '../world.dart';
import 'inferrer_engine.dart';
import 'type_graph_inferrer.dart';
import 'type_graph_nodes.dart';
import 'type_system.dart';

class KernelTypeGraphInferrer extends TypeGraphInferrer<ir.Node> {
  final Compiler _compiler;

  KernelTypeGraphInferrer(this._compiler, ClosedWorld closedWorld,
      ClosedWorldRefiner closedWorldRefiner, {bool disableTypeInference: false})
      : super(closedWorld, closedWorldRefiner,
            disableTypeInference: disableTypeInference);

  @override
  InferrerEngine<ir.Node> createInferrerEngineFor(FunctionEntity main) {
    return new KernelInferrerEngine(
        _compiler, closedWorld, closedWorldRefiner, main);
  }

  @override
  GlobalTypeInferenceResults createResults() {
    return new KernelGlobalTypeInferenceResults(this, closedWorld);
  }
}

class KernelGlobalTypeInferenceResults
    extends GlobalTypeInferenceResults<ir.Node> {
  KernelGlobalTypeInferenceResults(
      TypesInferrer<ir.Node> inferrer, ClosedWorld closedWorld)
      : super(inferrer, closedWorld);

  GlobalTypeInferenceMemberResult<ir.Node> createMemberResult(
      TypeGraphInferrer<ir.Node> inferrer, MemberEntity member,
      {bool isJsInterop: false}) {
    return new GlobalTypeInferenceMemberResultImpl<ir.Node>(
        member,
        // We store data in the context of the enclosing method, even
        // for closure elements.
        inferrer.inferrer.lookupDataOfMember(member),
        inferrer,
        isJsInterop,
        dynamicType);
  }

  GlobalTypeInferenceParameterResult<ir.Node> createParameterResult(
      TypeGraphInferrer<ir.Node> inferrer, Local parameter) {
    return new GlobalTypeInferenceParameterResultImpl<ir.Node>(
        parameter, inferrer, dynamicType);
  }
}

class KernelInferrerEngine extends InferrerEngineImpl<ir.Node> {
  KernelInferrerEngine(Compiler compiler, ClosedWorld closedWorld,
      ClosedWorldRefiner closedWorldRefiner, FunctionEntity mainElement)
      : super(compiler, closedWorld, closedWorldRefiner, mainElement,
            const KernelTypeSystemStrategy());

  @override
  ConstantValue getFieldConstant(FieldEntity field) {
    throw new UnimplementedError('KernelInferrerEngine.getFieldConstant');
  }

  @override
  bool isFieldInitializerPotentiallyNull(
      FieldEntity field, ir.Node initializer) {
    throw new UnimplementedError(
        'KernelInferrerEngine.isFieldInitializerPotentiallyNull');
  }

  @override
  TypeInformation computeMemberTypeInformation(
      MemberEntity member, ir.Node body) {
    throw new UnimplementedError(
        'KernelInferrerEngine.computeMemberTypeInformation');
  }

  @override
  FunctionEntity lookupCallMethod(ClassEntity cls) {
    throw new UnimplementedError('KernelInferrerEngine.lookupCallMethod');
  }

  @override
  void forEachParameter(FunctionEntity method, void f(Local parameter)) {
    throw new UnimplementedError('KernelInferrerEngine.forEachParameter');
  }

  @override
  ir.Node computeMemberBody(MemberEntity member) {
    throw new UnimplementedError('KernelInferrerEngine.computeMemberBody');
  }

  @override
  int computeMemberSize(MemberEntity member) {
    throw new UnimplementedError('KernelInferrerEngine.computeMemberSize');
  }

  @override
  GlobalTypeInferenceElementData<ir.Node> createElementData() {
    throw new UnimplementedError('KernelInferrerEngine.createElementData');
  }
}

class KernelTypeSystemStrategy implements TypeSystemStrategy<ir.Node> {
  const KernelTypeSystemStrategy();

  @override
  bool checkClassEntity(ClassEntity cls) => true;

  @override
  bool checkMapNode(ir.Node node) => true;

  @override
  bool checkListNode(ir.Node node) => true;

  @override
  bool checkLoopPhiNode(ir.Node node) => true;

  @override
  bool checkPhiNode(ir.Node node) => true;

  @override
  void forEachParameter(FunctionEntity function, void f(Local parameter)) {
    throw new UnimplementedError('KernelTypeSystemStrategy.forEachParameter');
  }

  @override
  ParameterTypeInformation createParameterTypeInformation(
      Local parameter, TypeSystem<ir.Node> types) {
    throw new UnimplementedError(
        'KernelTypeSystemStrategy.createParameterTypeInformation');
  }

  @override
  MemberTypeInformation createMemberTypeInformation(MemberEntity member) {
    throw new UnimplementedError(
        'KernelTypeSystemStrategy.createParameterTypeInformation');
  }
}
