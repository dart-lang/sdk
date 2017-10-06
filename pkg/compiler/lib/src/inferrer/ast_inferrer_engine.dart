// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../common/names.dart';
import '../compiler.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../resolution/tree_elements.dart';
import '../tree/nodes.dart' as ast;
import '../types/types.dart';
import '../world.dart';
import 'builder.dart';
import 'inferrer_engine.dart';
import 'type_graph_nodes.dart';
import 'type_system.dart';

class AstInferrerEngine extends InferrerEngineImpl<ast.Node> {
  final Compiler compiler;

  AstInferrerEngine(this.compiler, ClosedWorld closedWorld,
      ClosedWorldRefiner closedWorldRefiner, FunctionEntity mainElement)
      : super(
            compiler.options,
            compiler.progress,
            compiler.reporter,
            compiler.outputProvider,
            closedWorld,
            closedWorldRefiner,
            compiler.backend.mirrorsData,
            compiler.backend.noSuchMethodRegistry,
            mainElement,
            const TypeSystemStrategyImpl());

  GlobalTypeInferenceElementData<ast.Node> createElementData() =>
      new AstGlobalTypeInferenceElementData();

  int computeMemberSize(MemberEntity member) => resolveAstApproxSize(member);

  ast.Node computeMemberBody(covariant MemberElement member) {
    ResolvedAst resolvedAst = member.resolvedAst;
    ast.Node body;
    if (resolvedAst.kind == ResolvedAstKind.PARSED) {
      body = resolvedAst.body;
      if (member.isField &&
          member.isInstanceMember &&
          !member.isFinal &&
          body is ast.LiteralNull) {
        return null;
      }
    }
    return body;
  }

  FunctionEntity lookupCallMethod(covariant ClassElement cls) {
    MethodElement callMethod = cls.lookupMember(Identifiers.call);
    if (callMethod == null) {
      callMethod = cls.lookupMember(Identifiers.noSuchMethod_);
    }
    return callMethod;
  }

  TypeInformation computeMemberTypeInformation(
      MemberEntity member, ast.Node body) {
    ElementGraphBuilder visitor =
        new ElementGraphBuilder(member, compiler, this);
    return visitor.run();
  }

  bool isFieldInitializerPotentiallyNull(
      FieldEntity field, ast.Node initializer) {
    dynamic argument = initializer;
    // TODO(13429): We could do better here by using the
    // constant handler to figure out if it's a lazy field or not.
    return argument.asSend() != null ||
        (argument.asNewExpression() != null && !argument.isConst);
  }

  ConstantValue getFieldConstant(covariant FieldElement field) {
    ConstantExpression constant = field.constant;
    if (constant != null) {
      ConstantValue value =
          compiler.backend.constants.getConstantValue(constant);
      if (value == null) {
        assert(
            field.isInstanceMember ||
                constant.isImplicit ||
                constant.isPotential,
            failedAt(
                field,
                "Constant expression without value: "
                "${constant.toStructuredText()}."));
      }
      return value;
    }
    return null;
  }

  @override
  bool hasCallType(covariant ClassElement cls) {
    return cls.callType != null;
  }

  /// Computes a 'size' of [_element] based on the number of selectors in the
  /// associated [TreeElements]. This is used for sorting member for the type
  /// inference work-queue.
  // TODO(johnniwinther): This is brittle and cannot be translated in the
  // kernel based inference. Find a more stable a reproducable size measure.
  static int resolveAstApproxSize(_element) {
    MemberElement element = _element;
    ResolvedAst resolvedAst = element.resolvedAst;
    element = element.implementation;
    if (resolvedAst.kind == ResolvedAstKind.PARSED) {
      TreeElementMapping mapping = resolvedAst.elements;
      return mapping.getSelectorCount();
    }
    return 0;
  }
}

class TypeSystemStrategyImpl implements TypeSystemStrategy<ast.Node> {
  const TypeSystemStrategyImpl();

  @override
  MemberTypeInformation createMemberTypeInformation(
      covariant MemberElement member) {
    assert(member.isDeclaration, failedAt(member));
    if (member.isField) {
      FieldElement field = member;
      return new FieldTypeInformation(field, field.type);
    } else if (member.isGetter) {
      GetterElement getter = member;
      return new GetterTypeInformation(getter, getter.type);
    } else if (member.isSetter) {
      SetterElement setter = member;
      return new SetterTypeInformation(setter);
    } else if (member.isFunction) {
      MethodElement method = member;
      return new MethodTypeInformation(method, method.type);
    } else {
      ConstructorElement constructor = member;
      if (constructor.isFactoryConstructor) {
        return new FactoryConstructorTypeInformation(
            constructor, constructor.type);
      } else {
        return new GenerativeConstructorTypeInformation(constructor);
      }
    }
  }

  @override
  ParameterTypeInformation createParameterTypeInformation(
      covariant ParameterElement parameter, TypeSystem<ast.Node> types) {
    assert(parameter.isImplementation, failedAt(parameter));
    FunctionTypedElement function = parameter.functionDeclaration.declaration;
    if (function.isLocal) {
      LocalFunctionElement localFunction = function;
      MethodElement callMethod = localFunction.callMethod;
      return new ParameterTypeInformation.localFunction(
          types.getInferredTypeOfMember(callMethod),
          parameter,
          parameter.type,
          callMethod);
    } else if (function.isInstanceMember) {
      MethodElement method = function;
      return new ParameterTypeInformation.instanceMember(
          types.getInferredTypeOfMember(method),
          parameter,
          parameter.type,
          method,
          new ParameterAssignments());
    } else {
      MethodElement method = function;
      return new ParameterTypeInformation.static(
          types.getInferredTypeOfMember(method),
          parameter,
          parameter.type,
          method,
          // TODO(johnniwinther): Is this still valid now that initializing
          // formals also introduce locals?
          isInitializingFormal: parameter.isInitializingFormal);
    }
  }

  @override
  void forEachParameter(
      covariant MethodElement function, void f(Local parameter)) {
    MethodElement impl = function.implementation;
    FunctionSignature signature = impl.functionSignature;
    signature.forEachParameter((FormalElement _parameter) {
      ParameterElement parameter = _parameter;
      f(parameter);
    });
  }

  @override
  bool checkMapNode(ast.Node node) {
    return node is ast.LiteralMap;
  }

  @override
  bool checkListNode(ast.Node node) {
    return node is ast.LiteralList || node is ast.Send;
  }

  @override
  bool checkLoopPhiNode(ast.Node node) {
    return node is ast.Loop || node is ast.SwitchStatement;
  }

  @override
  bool checkPhiNode(ast.Node node) {
    return true;
  }

  @override
  bool checkClassEntity(covariant ClassElement cls) {
    return cls.isDeclaration;
  }
}
