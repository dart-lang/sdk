// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common.dart';
import '../common_elements.dart';
import '../compiler.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../kernel/element_map.dart';
import '../js_model/locals.dart';
import '../types/types.dart';
import '../world.dart';
import 'builder_kernel.dart';
import 'inferrer_engine.dart';
import 'type_graph_inferrer.dart';
import 'type_graph_nodes.dart';
import 'type_system.dart';

class KernelTypeGraphInferrer extends TypeGraphInferrer<ir.Node> {
  final Compiler _compiler;
  final KernelToElementMapForBuilding _elementMap;
  final GlobalLocalsMap _globalLocalsMap;
  final ClosureDataLookup<ir.Node> _closureDataLookup;

  KernelTypeGraphInferrer(
      this._compiler,
      this._elementMap,
      this._globalLocalsMap,
      this._closureDataLookup,
      ClosedWorld closedWorld,
      ClosedWorldRefiner closedWorldRefiner,
      {bool disableTypeInference: false})
      : super(closedWorld, closedWorldRefiner,
            disableTypeInference: disableTypeInference);

  @override
  InferrerEngine<ir.Node> createInferrerEngineFor(FunctionEntity main) {
    return new KernelInferrerEngine(_compiler, _elementMap, _globalLocalsMap,
        _closureDataLookup, closedWorld, closedWorldRefiner, main);
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
  final KernelToElementMapForBuilding _elementMap;
  final GlobalLocalsMap _globalLocalsMap;
  final ClosureDataLookup<ir.Node> _closureDataLookup;

  KernelInferrerEngine(
      Compiler compiler,
      this._elementMap,
      this._globalLocalsMap,
      this._closureDataLookup,
      ClosedWorld closedWorld,
      ClosedWorldRefiner closedWorldRefiner,
      FunctionEntity mainElement)
      : super(
            compiler,
            closedWorld,
            closedWorldRefiner,
            mainElement,
            new KernelTypeSystemStrategy(
                _elementMap, _globalLocalsMap, _closureDataLookup));

  ElementEnvironment get _elementEnvironment => _elementMap.elementEnvironment;

  @override
  ConstantValue getFieldConstant(FieldEntity field) {
    return _elementMap.getFieldConstantValue(field);
  }

  @override
  bool isFieldInitializerPotentiallyNull(
      FieldEntity field, ir.Node initializer) {
    // TODO(johnniwinther): Implement the ad-hoc check in ast inferrer?
    return true;
  }

  @override
  TypeInformation computeMemberTypeInformation(
      MemberEntity member, ir.Node body) {
    KernelTypeGraphBuilder visitor =
        new KernelTypeGraphBuilder(member, compiler, _elementMap, this, body);
    return visitor.run();
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
    MemberDefinition definition = _elementMap.getMemberDefinition(member);
    switch (definition.kind) {
      case MemberKind.regular:
        ir.Member node = definition.node;
        if (node is ir.Field) {
          return node.initializer;
        } else if (node is ir.Procedure) {
          return node.function;
        }
        break;
      case MemberKind.constructor:
      case MemberKind.constructorBody:
        ir.Member node = definition.node;
        if (node is ir.Constructor) {
          return node.function;
        } else if (node is ir.Procedure) {
          return node.function;
        }
        break;
      case MemberKind.closureCall:
        ir.Member node = definition.node;
        if (node is ir.FunctionDeclaration) {
          return node.function;
        } else if (node is ir.FunctionExpression) {
          return node.function;
        }
        break;
      case MemberKind.closureField:
        break;
    }
    failedAt(member, 'Unexpected member definition: $definition.');
    return null;
  }

  @override
  int computeMemberSize(MemberEntity member) {
    // TODO(johnniwinther): Find an ordering that can be shared between the
    // front ends.
    return 0;
  }

  @override
  GlobalTypeInferenceElementData<ir.Node> createElementData() {
    throw new UnimplementedError('KernelInferrerEngine.createElementData');
  }
}

class KernelTypeSystemStrategy implements TypeSystemStrategy<ir.Node> {
  KernelToElementMapForBuilding _elementMap;
  GlobalLocalsMap _globalLocalsMap;
  ClosureDataLookup<ir.Node> _closureDataLookup;

  KernelTypeSystemStrategy(
      this._elementMap, this._globalLocalsMap, this._closureDataLookup);

  ElementEnvironment get _elementEnvironment => _elementMap.elementEnvironment;

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
    MemberEntity context = parameter.memberContext;
    KernelToLocalsMap localsMap = _globalLocalsMap.getLocalsMap(context);
    ir.FunctionNode functionNode =
        localsMap.getFunctionNodeForParameter(parameter);
    DartType type =
        _elementMap.getDartType(localsMap.getParameterType(parameter));
    MemberEntity member;
    bool isClosure = false;
    if (functionNode.parent is ir.Member) {
      member = _elementMap.getMember(functionNode.parent);
    } else if (functionNode.parent is ir.FunctionExpression ||
        functionNode.parent is ir.FunctionDeclaration) {
      ClosureRepresentationInfo info =
          _closureDataLookup.getClosureInfo(functionNode.parent);
      member = info.callMethod;
      isClosure = true;
    }
    MemberTypeInformation memberTypeInformation =
        types.getInferredTypeOfMember(member);
    if (isClosure) {
      return new ParameterTypeInformation.localFunction(
          memberTypeInformation, parameter, type, member);
    } else if (member.isInstanceMember) {
      return new ParameterTypeInformation.instanceMember(memberTypeInformation,
          parameter, type, member, new ParameterAssignments());
    } else {
      return new ParameterTypeInformation.static(
          memberTypeInformation, parameter, type, member);
    }
  }

  @override
  MemberTypeInformation createMemberTypeInformation(MemberEntity member) {
    if (member.isField) {
      FieldEntity field = member;
      DartType type = _elementEnvironment.getFieldType(field);
      return new FieldTypeInformation(field, type);
    } else if (member.isGetter) {
      FunctionEntity getter = member;
      DartType type = _elementEnvironment.getFunctionType(getter);
      return new GetterTypeInformation(getter, type);
    } else if (member.isSetter) {
      FunctionEntity setter = member;
      return new SetterTypeInformation(setter);
    } else if (member.isFunction) {
      FunctionEntity method = member;
      DartType type = _elementEnvironment.getFunctionType(method);
      return new MethodTypeInformation(method, type);
    } else {
      ConstructorEntity constructor = member;
      if (constructor.isFactoryConstructor) {
        DartType type = _elementEnvironment.getFunctionType(constructor);
        return new FactoryConstructorTypeInformation(constructor, type);
      } else {
        return new GenerativeConstructorTypeInformation(constructor);
      }
    }
  }
}
