// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common.dart';
import '../compiler.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../common_elements.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/jumps.dart';
import '../elements/modelx.dart';
import '../elements/resolution_types.dart';
import '../elements/types.dart';
import '../js_backend/js_backend.dart';
import '../kernel/element_map.dart';
import '../kernel/element_map_mixins.dart';
import '../kernel/kernel.dart';
import '../native/native.dart' as native;
import '../resolution/tree_elements.dart';
import '../tree/tree.dart' as ast;
import '../types/masks.dart';
import '../types/types.dart';
import '../universe/selector.dart';
import '../world.dart';
import 'graph_builder.dart';
import 'jump_handler.dart' show SwitchCaseJumpHandler;
import 'locals_handler.dart';
import 'types.dart';

/// A helper class that abstracts all accesses of the AST from Kernel nodes.
///
/// The goal is to remove all need for the AST from the Kernel SSA builder.
class KernelAstAdapter extends KernelToElementMapBaseMixin
    with KernelToElementMapForBuildingMixin, KernelToElementMapForImpactMixin
    implements KernelToLocalsMap {
  final Kernel kernel;
  final JavaScriptBackend _backend;
  final Map<ir.Node, ast.Node> _nodeToAst;
  final Map<ir.Node, Element> _nodeToElement;
  final Map<ir.VariableDeclaration, SyntheticLocal> _syntheticLocals =
      <ir.VariableDeclaration, SyntheticLocal>{};
  // TODO(efortuna): In an ideal world the TreeNodes should be some common
  // interface we create for both ir.Statements and ir.SwitchCase (the
  // ContinueSwitchStatement's target is a SwitchCase) rather than general
  // TreeNode. Talking to Asger about this.
  final Map<ir.TreeNode, KernelJumpTarget> _jumpTargets =
      <ir.TreeNode, KernelJumpTarget>{};
  DartTypeConverter _typeConverter;
  ResolvedAst _resolvedAst;

  /// Sometimes for resolution the resolved AST element needs to change (for
  /// example, if we're inlining, or if we're in a constructor, but then also
  /// constructing the field values). We keep track of this with a stack.
  final List<ResolvedAst> _resolvedAstStack = <ResolvedAst>[];

  final native.BehaviorBuilder nativeBehaviorBuilder;

  KernelAstAdapter(this.kernel, this._backend, this._resolvedAst,
      this._nodeToAst, this._nodeToElement)
      : nativeBehaviorBuilder = new native.ResolverBehaviorBuilder(
            _backend.compiler, _backend.nativeBasicData) {
    KernelJumpTarget.index = 0;
    // TODO(het): Maybe just use all of the kernel maps directly?
    for (FieldElement fieldElement in kernel.fields.keys) {
      _nodeToElement[kernel.fields[fieldElement]] = fieldElement;
    }
    for (FunctionElement functionElement in kernel.functions.keys) {
      _nodeToElement[kernel.functions[functionElement]] = functionElement;
    }
    for (ClassElement classElement in kernel.classes.keys) {
      _nodeToElement[kernel.classes[classElement]] = classElement;
    }
    for (LibraryElement libraryElement in kernel.libraries.keys) {
      _nodeToElement[kernel.libraries[libraryElement]] = libraryElement;
    }
    for (LocalFunctionElement localFunction in kernel.localFunctions.keys) {
      _nodeToElement[kernel.localFunctions[localFunction]] = localFunction;
    }
    for (TypeVariableElement typeVariable in kernel.typeParameters.keys) {
      _nodeToElement[kernel.typeParameters[typeVariable]] = typeVariable;
    }
    _typeConverter = new DartTypeConverter(this);
  }

  void addProgram(ir.Program node) {
    throw new UnsupportedError('KernelAstAdapter.addProgram');
  }

  @override
  ConstantValue computeConstantValue(ConstantExpression constant,
      {bool requireConstant: true}) {
    _compiler.backend.constants.evaluate(constant);
    ConstantValue value =
        _compiler.backend.constants.getConstantValue(constant);
    if (value == null && requireConstant) {
      throw new UnsupportedError(
          'No constant value for ${constant.toStructuredText()}');
    }
    return value;
  }

  @override
  ConstantValue getFieldConstantValue(ir.Field field) {
    FieldElement element = getField(field);
    if (element.constant != null) {
      return computeConstantValue(element.constant);
    }
    return null;
  }

  /// Called to find the corresponding Kernel element for a particular Element
  /// before traversing over it with a Kernel visitor.
  ir.Node getMemberNode(MemberElement originTarget) {
    ir.Node target;
    if (originTarget.isPatch) {
      originTarget = originTarget.origin;
    }
    if (originTarget is MethodElement) {
      if (originTarget is ConstructorBodyElement) {
        ConstructorBodyElement body = originTarget;
        originTarget = body.constructor;
      }
      target = kernel.functions[originTarget];
      // Closures require a lookup one level deeper in the closure class mapper.
      if (target == null) {
        MethodElement originTargetFunction = originTarget;
        ClosureRepresentationInfo classMap = _compiler
            .backendStrategy.closureDataLookup
            .getClosureRepresentationInfo(originTargetFunction);
        if (classMap.closureEntity != null) {
          target = kernel.localFunctions[classMap.closureEntity];
        }
      }
    } else if (originTarget is FieldElement) {
      target = kernel.fields[originTarget];
    }
    assert(target != null);
    return target;
  }

  ir.Node getClassNode(ClassElement cls) {
    throw new UnsupportedError('KernelAstAdapter.getClassNode');
  }

  @override
  CommonElements get commonElements => _compiler.resolution.commonElements;

  @override
  ElementEnvironment get elementEnvironment =>
      _compiler.resolution.elementEnvironment;

  MemberElement get currentMember => _resolvedAst.element;

  /// Push the existing resolved AST on the stack and shift the current resolved
  /// AST to the AST that this kernel node points to.
  void enterInlinedMember(MemberElement member) {
    _resolvedAstStack.add(_resolvedAst);
    _resolvedAst = member.resolvedAst;
  }

  /// Pop the resolved AST stack to reset it to the previous resolved AST node.
  void leaveInlinedMember(MemberElement member) {
    assert(_resolvedAstStack.isNotEmpty);
    assert(_resolvedAst.element == member);
    _resolvedAst = _resolvedAstStack.removeLast();
  }

  Compiler get _compiler => _backend.compiler;
  TreeElements get elements => _resolvedAst.elements;
  DiagnosticReporter get reporter => _compiler.reporter;

  // TODO(johnniwinther): Use the more precise functions below.
  Element getElement(ir.Node node) {
    Element result = _nodeToElement[node];
    assert(result != null,
        failedAt(CURRENT_ELEMENT_SPANNABLE, "No element found for $node."));
    return result;
  }

  ConstructorElement getConstructor(ir.Member node) =>
      getElement(node).declaration;

  @override
  ConstructorEntity getSuperConstructor(
      ir.Constructor constructor, ir.Member target) {
    assert(target != null);
    return getConstructor(target);
  }

  @override
  MemberEntity getSuperMember(ir.Member context, ir.Name name, ir.Member target,
      {bool setter: false}) {
    assert(target != null);
    return getMember(target);
  }

  MemberElement getMember(ir.Member node) => getElement(node).declaration;

  MethodElement getMethod(ir.Procedure node) => getElement(node).declaration;

  FieldElement getField(ir.Field node) => getElement(node).declaration;

  ClassElement getClass(ir.Class node) => getElement(node).declaration;

  LibraryElement getLibrary(ir.Library node) => getElement(node).declaration;

  LocalFunctionElement getLocalFunction(ir.TreeNode node) => getElement(node);

  ast.Node getNode(ir.Node node) {
    ast.Node result = _nodeToAst[node];
    assert(result != null,
        failedAt(CURRENT_ELEMENT_SPANNABLE, "No node found for $node"));
    return result;
  }

  ast.Node getNodeOrNull(ir.Node node) {
    return _nodeToAst[node];
  }

  void assertNodeIsSynthetic(ir.Node node) {
    assert(
        kernel.syntheticNodes.contains(node),
        failedAt(
            CURRENT_ELEMENT_SPANNABLE, "No synthetic marker found for $node"));
  }

  @override
  Local getLocal(ir.VariableDeclaration variable) {
    // If this is a synthetic local, return the synthetic local
    if (variable.name == null) {
      return _syntheticLocals.putIfAbsent(
          variable, () => new SyntheticLocal("x", null, null));
    }
    return getElement(variable) as LocalElement;
  }

  @override
  JumpTarget getJumpTargetForBreak(ir.BreakStatement node) {
    return getJumpTarget(node.target);
  }

  @override
  bool generateContinueForBreak(ir.BreakStatement node) => false;

  @override
  JumpTarget getJumpTargetForLabel(ir.LabeledStatement node) {
    return getJumpTarget(node);
  }

  @override
  JumpTarget getJumpTargetForSwitch(ir.SwitchStatement node) {
    return getJumpTarget(node);
  }

  @override
  JumpTarget getJumpTargetForContinueSwitch(ir.ContinueSwitchStatement node) {
    return getJumpTarget(node.target);
  }

  @override
  JumpTarget getJumpTargetForSwitchCase(ir.SwitchCase node) {
    return getJumpTarget(node, isContinueTarget: true);
  }

  @override
  JumpTarget getJumpTargetForDo(ir.DoStatement node) {
    return getJumpTarget(node);
  }

  @override
  JumpTarget getJumpTargetForFor(ir.ForStatement node) {
    return getJumpTarget(node);
  }

  @override
  JumpTarget getJumpTargetForForIn(ir.ForInStatement node) {
    return getJumpTarget(node);
  }

  @override
  JumpTarget getJumpTargetForWhile(ir.WhileStatement node) {
    return getJumpTarget(node);
  }

  KernelJumpTarget getJumpTarget(ir.TreeNode node,
      {bool isContinueTarget: false}) {
    return _jumpTargets.putIfAbsent(node, () {
      if (node is ir.LabeledStatement && _jumpTargets.containsKey(node.body)) {
        return _jumpTargets[node.body];
      }
      return new KernelJumpTarget(node, this,
          makeContinueLabel: isContinueTarget);
    });
  }

  DartType getDartType(ir.DartType type) {
    return _typeConverter.convert(type);
  }

  List<DartType> getDartTypes(List<ir.DartType> types) {
    return types.map(getDartType).toList();
  }

  /// Computes the function type corresponding the signature of [node].
  FunctionType getFunctionType(ir.FunctionNode node) {
    ResolutionDartType returnType = getDartType(node.returnType);
    List<ResolutionDartType> parameterTypes = <ResolutionDartType>[];
    List<ResolutionDartType> optionalParameterTypes = <ResolutionDartType>[];
    for (ir.VariableDeclaration variable in node.positionalParameters) {
      if (parameterTypes.length == node.requiredParameterCount) {
        optionalParameterTypes.add(getDartType(variable.type));
      } else {
        parameterTypes.add(getDartType(variable.type));
      }
    }
    List<String> namedParameters = <String>[];
    List<ResolutionDartType> namedParameterTypes = <ResolutionDartType>[];
    List<ir.VariableDeclaration> sortedNamedParameters =
        node.namedParameters.toList()..sort((a, b) => a.name.compareTo(b.name));
    for (ir.VariableDeclaration variable in sortedNamedParameters) {
      namedParameters.add(variable.name);
      namedParameterTypes.add(getDartType(variable.type));
    }
    return new ResolutionFunctionType.synthesized(returnType, parameterTypes,
        optionalParameterTypes, namedParameters, namedParameterTypes);
  }

  InterfaceType getInterfaceType(ir.InterfaceType type) => getDartType(type);

  InterfaceType getThisType(ClassElement cls) => cls.thisType;

  InterfaceType createInterfaceType(
      ir.Class cls, List<ir.DartType> typeArguments) {
    return new ResolutionInterfaceType(
        getClass(cls), getDartTypes(typeArguments));
  }

  MemberEntity getConstructorBodyEntity(ir.Constructor constructor) {
    AstElement element = getElement(constructor);
    MemberEntity constructorBody =
        ConstructorBodyElementX.createFromResolvedAst(element.resolvedAst);
    assert(constructorBody != null);
    return constructorBody;
  }

  @override
  Spannable getSpannable(MemberEntity member, ir.Node node) {
    return getNode(node);
  }

  @override
  LoopClosureScope getLoopClosureScope(
      ClosureDataLookup closureLookup, ir.TreeNode node) {
    return closureLookup.getLoopClosureScope(getNode(node));
  }
}

/// Visitor that converts kernel dart types into [ResolutionDartType].
class DartTypeConverter extends ir.DartTypeVisitor<ResolutionDartType> {
  final KernelAstAdapter astAdapter;
  bool topLevel = true;

  DartTypeConverter(this.astAdapter);

  ResolutionDartType convert(ir.DartType type) {
    topLevel = true;
    return type.accept(this);
  }

  /// Visit a inner type.
  ResolutionDartType visitType(ir.DartType type) {
    topLevel = false;
    return type.accept(this);
  }

  List<ResolutionDartType> visitTypes(List<ir.DartType> types) {
    topLevel = false;
    return new List.generate(
        types.length, (int index) => types[index].accept(this));
  }

  @override
  ResolutionDartType visitTypeParameterType(ir.TypeParameterType node) {
    if (node.parameter.parent is ir.Class) {
      ir.Class cls = node.parameter.parent;
      int index = cls.typeParameters.indexOf(node.parameter);
      ClassElement classElement = astAdapter.getElement(cls);
      return classElement.typeVariables[index];
    } else if (node.parameter.parent is ir.FunctionNode) {
      ir.FunctionNode func = node.parameter.parent;
      int index = func.typeParameters.indexOf(node.parameter);
      Element element = astAdapter.getElement(func);
      if (element.isConstructor) {
        ClassElement classElement = element.enclosingClass;
        return classElement.typeVariables[index];
      } else {
        GenericElement genericElement = element;
        return genericElement.typeVariables[index];
      }
    }
    throw new UnsupportedError('Unsupported type parameter type node $node.');
  }

  @override
  ResolutionDartType visitFunctionType(ir.FunctionType node) {
    return new ResolutionFunctionType.synthesized(
        visitType(node.returnType),
        visitTypes(node.positionalParameters
            .take(node.requiredParameterCount)
            .toList()),
        visitTypes(node.positionalParameters
            .skip(node.requiredParameterCount)
            .toList()),
        node.namedParameters.map((n) => n.name).toList(),
        node.namedParameters.map((n) => visitType(n.type)).toList());
  }

  @override
  ResolutionDartType visitInterfaceType(ir.InterfaceType node) {
    ClassElement cls = astAdapter.getClass(node.classNode);
    return new ResolutionInterfaceType(cls, visitTypes(node.typeArguments));
  }

  @override
  ResolutionDartType visitVoidType(ir.VoidType node) {
    return const ResolutionVoidType();
  }

  @override
  ResolutionDartType visitDynamicType(ir.DynamicType node) {
    return const ResolutionDynamicType();
  }

  @override
  ResolutionDartType visitInvalidType(ir.InvalidType node) {
    // Root uses such a `o is Unresolved` and `o as Unresolved` must be special
    // cased in the builder, nested invalid types are treated as `dynamic`.
    return const ResolutionDynamicType();
  }
}

class KernelJumpTarget implements JumpTargetX {
  static int index = 0;

  /// Pointer to the actual executable statements that a jump target refers to.
  /// If this jump target was not initially constructed with a LabeledStatement,
  /// this value is identical to originalStatement. This Node is actually of
  /// type either ir.Statement or ir.SwitchCase.
  ir.Node targetStatement;

  /// The original statement used to construct this jump target.
  /// If this jump target was not initially constructed with a LabeledStatement,
  /// this value is identical to targetStatement. This Node is actually of
  /// type either ir.Statement or ir.SwitchCase.
  ir.Node originalStatement;

  /// Used to provide unique numbers to labels that would otherwise be duplicate
  /// if one JumpTarget is inside another.
  int nestingLevel;

  @override
  bool isBreakTarget = false;

  @override
  bool isContinueTarget = false;

  KernelJumpTarget(this.targetStatement, KernelAstAdapter adapter,
      {bool makeContinueLabel = false}) {
    originalStatement = targetStatement;
    this.labels = <LabelDefinition<ast.Node>>[];
    if (targetStatement is ir.WhileStatement ||
        targetStatement is ir.DoStatement ||
        targetStatement is ir.ForStatement ||
        targetStatement is ir.ForInStatement) {
      // Currently these labels are set at resolution on the element itself.
      // Once that gets updated, this logic can change downstream.
      JumpTarget<ast.Node> target = adapter.elements
          .getTargetDefinition(adapter.getNode(targetStatement));
      if (target != null) {
        labels.addAll(target.labels);
        isBreakTarget = target.isBreakTarget;
        isContinueTarget = target.isContinueTarget;
      }
    } else if (targetStatement is ir.LabeledStatement) {
      targetStatement = (targetStatement as ir.LabeledStatement).body;
      labels.add(
          new LabelDefinitionX(null, 'L${index++}', this)..setBreakTarget());
      isBreakTarget = true;
    }
    var originalNode = adapter.getNode(originalStatement);
    var originalTarget = adapter.elements.getTargetDefinition(originalNode);
    if (originalTarget != null) {
      nestingLevel = originalTarget.nestingLevel;
    } else {
      nestingLevel = 0;
    }

    if (makeContinueLabel) {
      labels.add(
          new LabelDefinitionX(null, 'L${index++}', this)..setContinueTarget());
      isContinueTarget = true;
    }
  }

  @override
  LabelDefinition<ast.Node> addLabel(ast.Label label, String labelName,
      {bool isBreakTarget: false}) {
    LabelDefinitionX result = new LabelDefinitionX(label, labelName, this);
    labels.add(result);
    if (isBreakTarget) {
      result.setBreakTarget();
    }
    return result;
  }

  @override
  ExecutableElement get executableContext => null;

  @override
  MemberElement get memberContext => null;

  @override
  bool get isSwitch => targetStatement is ir.SwitchStatement;

  @override
  bool get isTarget => isBreakTarget || isContinueTarget;

  @override
  List<LabelDefinition<ast.Node>> labels;

  @override
  String get name => 'target';

  @override
  ast.Label get statement => null;

  String toString() => 'Target:$targetStatement';
}

/// Special [JumpHandler] implementation used to handle continue statements
/// targeting switch cases.
class KernelSwitchCaseJumpHandler extends SwitchCaseJumpHandler {
  KernelSwitchCaseJumpHandler(GraphBuilder builder, JumpTarget target,
      ir.SwitchStatement switchStatement, KernelToLocalsMap localsMap)
      : super(builder, target) {
    // The switch case indices must match those computed in
    // [KernelSsaBuilder.buildSwitchCaseConstants].
    // Switch indices are 1-based so we can bypass the synthetic loop when no
    // cases match simply by branching on the index (which defaults to null).
    // TODO
    int switchIndex = 1;
    for (ir.SwitchCase switchCase in switchStatement.cases) {
      JumpTarget continueTarget =
          localsMap.getJumpTargetForSwitchCase(switchCase);
      assert(continueTarget is KernelJumpTarget);
      targetIndexMap[continueTarget] = switchIndex;
      assert(builder.jumpTargets[continueTarget] == null);
      builder.jumpTargets[continueTarget] = this;
      switchIndex++;
    }
  }
}

class KernelAstTypeInferenceMap implements KernelToTypeInferenceMap {
  final KernelAstAdapter _astAdapter;

  KernelAstTypeInferenceMap(this._astAdapter);

  MemberElement get _target => _astAdapter._resolvedAst.element;

  GlobalTypeInferenceResults get _globalInferenceResults =>
      _astAdapter._compiler.globalInference.results;

  GlobalTypeInferenceElementResult _resultOf(MemberElement e) =>
      _globalInferenceResults
          .resultOfMember(e is ConstructorBodyElementX ? e.constructor : e);

  TypeMask getReturnTypeOf(FunctionEntity function) {
    return TypeMaskFactory.inferredReturnTypeForElement(
        function, _globalInferenceResults);
  }

  TypeMask typeOfInvocation(ir.MethodInvocation send, ClosedWorld closedWorld) {
    ast.Node operatorNode = _astAdapter.kernel.nodeToAstOperator[send];
    if (operatorNode != null) {
      return _resultOf(_target).typeOfOperator(operatorNode);
    }
    if (send.name.name == '[]=') {
      return closedWorld.commonMasks.dynamicType;
    }
    ast.Node node = _astAdapter.getNodeOrNull(send);
    if (node == null) {
      assert(send.name.name == '==');
      return closedWorld.commonMasks.dynamicType;
    }
    return _resultOf(_target).typeOfSend(node);
  }

  TypeMask typeOfGet(ir.PropertyGet getter) {
    return _resultOf(_target).typeOfSend(_astAdapter.getNode(getter));
  }

  TypeMask typeOfSet(ir.PropertySet setter, ClosedWorld closedWorld) {
    return closedWorld.commonMasks.dynamicType;
  }

  TypeMask typeOfListLiteral(MemberElement owner, ir.ListLiteral listLiteral,
      ClosedWorld closedWorld) {
    ast.Node node = _astAdapter.getNodeOrNull(listLiteral);
    if (node == null) {
      _astAdapter.assertNodeIsSynthetic(listLiteral);
      return closedWorld.commonMasks.growableListType;
    }
    return _resultOf(owner)
            .typeOfListLiteral(_astAdapter.getNode(listLiteral)) ??
        closedWorld.commonMasks.dynamicType;
  }

  TypeMask typeOfIterator(ir.ForInStatement forInStatement) {
    return _resultOf(_target)
        .typeOfIterator(_astAdapter.getNode(forInStatement));
  }

  TypeMask typeOfIteratorCurrent(ir.ForInStatement forInStatement) {
    return _resultOf(_target)
        .typeOfIteratorCurrent(_astAdapter.getNode(forInStatement));
  }

  TypeMask typeOfIteratorMoveNext(ir.ForInStatement forInStatement) {
    return _resultOf(_target)
        .typeOfIteratorMoveNext(_astAdapter.getNode(forInStatement));
  }

  bool isJsIndexableIterator(
      ir.ForInStatement forInStatement, ClosedWorld closedWorld) {
    TypeMask mask = typeOfIterator(forInStatement);
    return mask != null &&
        mask.satisfies(
            closedWorld.commonElements.jsIndexableClass, closedWorld) &&
        // String is indexable but not iterable.
        !mask.satisfies(closedWorld.commonElements.jsStringClass, closedWorld);
  }

  bool isFixedLength(TypeMask mask, ClosedWorld closedWorld) {
    if (mask.isContainer && (mask as ContainerTypeMask).length != null) {
      // A container on which we have inferred the length.
      return true;
    }
    // TODO(sra): Recognize any combination of fixed length indexables.
    if (mask.containsOnly(closedWorld.commonElements.jsFixedArrayClass) ||
        mask.containsOnly(
            closedWorld.commonElements.jsUnmodifiableArrayClass) ||
        mask.containsOnlyString(closedWorld) ||
        closedWorld.commonMasks.isTypedArray(mask)) {
      return true;
    }
    return false;
  }

  TypeMask inferredIndexType(ir.ForInStatement forInStatement) {
    return TypeMaskFactory.inferredTypeForSelector(new Selector.index(),
        typeOfIterator(forInStatement), _globalInferenceResults);
  }

  TypeMask getInferredTypeOf(MemberEntity member) {
    return TypeMaskFactory.inferredTypeForMember(
        member, _globalInferenceResults);
  }

  TypeMask getInferredTypeOfParameter(Local parameter) {
    return TypeMaskFactory.inferredTypeForParameter(
        parameter, _globalInferenceResults);
  }

  TypeMask selectorTypeOf(Selector selector, TypeMask mask) {
    return TypeMaskFactory.inferredTypeForSelector(
        selector, mask, _globalInferenceResults);
  }

  TypeMask typeFromNativeBehavior(
      native.NativeBehavior nativeBehavior, ClosedWorld closedWorld) {
    return TypeMaskFactory.fromNativeBehavior(nativeBehavior, closedWorld);
  }
}
