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
import '../util/util.dart';
import '../world.dart';
import 'builder.dart';
import 'builder_kernel.dart';
import 'inferrer_engine.dart';
import 'type_graph_nodes.dart';
import 'type_system.dart';

class AstInferrerEngine extends InferrerEngineImpl<ast.Node> {
  AstInferrerEngine(Compiler compiler, ClosedWorld closedWorld,
      ClosedWorldRefiner closedWorldRefiner, FunctionEntity mainElement)
      : super(compiler, closedWorld, closedWorldRefiner, mainElement,
            const TypeSystemStrategyImpl());

  GlobalTypeInferenceElementData<ast.Node> createElementData() =>
      new AstGlobalTypeInferenceElementData();

  void analyzeAllElements() {
    sortResolvedAsts().forEach((ResolvedAst resolvedAst) {
      if (compiler.shouldPrintProgress) {
        reporter.log('Added $addedInGraph elements in inferencing graph.');
        compiler.progress.reset();
      }
      // This also forces the creation of the [ElementTypeInformation] to ensure
      // it is in the graph.
      MemberElement member = resolvedAst.element;
      ast.Node body;
      if (resolvedAst.kind == ResolvedAstKind.PARSED) {
        body = resolvedAst.body;
      }
      types.withMember(member, () => analyze(member, body, null));
    });
    reporter.log('Added $addedInGraph elements in inferencing graph.');
  }

  void forEachParameter(
      covariant MethodElement method, void f(Local parameter)) {
    MethodElement implementation = method.implementation;
    implementation.functionSignature
        .forEachParameter((FormalElement _parameter) {
      ParameterElement parameter = _parameter;
      f(parameter);
    });
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
    dynamic visitor = compiler.options.kernelGlobalInference
        ? new KernelTypeGraphBuilder(member, compiler, this)
        : new ElementGraphBuilder(member, compiler, this);
    // ignore: UNDEFINED_METHOD
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

  // Sorts the resolved elements by size. We do this for this inferrer
  // to get the same results for [ListTracer] compared to the
  // [SimpleTypesInferrer].
  Iterable<ResolvedAst> sortResolvedAsts() {
    int max = 0;
    Map<int, Setlet<ResolvedAst>> methodSizes = <int, Setlet<ResolvedAst>>{};
    compiler.enqueuer.resolution.processedEntities.forEach((_element) {
      MemberElement element = _element;
      ResolvedAst resolvedAst = element.resolvedAst;
      element = element.implementation;
      if (element.impliesType) return;
      assert(
          element.isField ||
              element.isFunction ||
              element.isConstructor ||
              element.isGetter ||
              element.isSetter,
          failedAt(element, 'Unexpected element kind: ${element.kind}'));
      if (element.isAbstract) return;
      // Put the other operators in buckets by length, later to be added in
      // length order.
      int length = 0;
      if (resolvedAst.kind == ResolvedAstKind.PARSED) {
        TreeElementMapping mapping = resolvedAst.elements;
        length = mapping.getSelectorCount();
      }
      max = length > max ? length : max;
      Setlet<ResolvedAst> set =
          methodSizes.putIfAbsent(length, () => new Setlet<ResolvedAst>());
      set.add(resolvedAst);
    });

    List<ResolvedAst> result = <ResolvedAst>[];
    for (int i = 0; i <= max; i++) {
      Setlet<ResolvedAst> set = methodSizes[i];
      if (set != null) result.addAll(set);
    }
    return result;
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
