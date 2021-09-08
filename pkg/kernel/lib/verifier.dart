// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.checks;

import 'ast.dart';
import 'transformations/flags.dart';
import 'type_environment.dart' show StatefulStaticTypeContext, TypeEnvironment;

void verifyComponent(Component component,
    {bool? isOutline, bool? afterConst, bool constantsAreAlwaysInlined: true}) {
  VerifyingVisitor.check(component,
      isOutline: isOutline,
      afterConst: afterConst,
      constantsAreAlwaysInlined: constantsAreAlwaysInlined);
}

class VerificationError {
  final TreeNode? context;

  final TreeNode? node;

  final String details;

  VerificationError(this.context, this.node, this.details);

  @override
  String toString() {
    Location? location;
    try {
      location = node?.location ?? context?.location;
    } catch (_) {
      // TODO(ahe): Fix the compiler instead.
    }
    if (location != null) {
      String file = location.file.toString();
      return "$file:${location.line}:${location.column}: Verification error:"
          " $details";
    } else {
      return "Verification error: $details\n"
          "Context: '$context'.\n"
          "Node: '$node'.";
    }
  }
}

enum TypedefState { Done, BeingChecked }

/// Checks that a kernel component is well-formed.
///
/// This does not include any kind of type checking.
class VerifyingVisitor extends RecursiveResultVisitor<void> {
  final Set<Class> classes = new Set<Class>();
  final Set<Typedef> typedefs = new Set<Typedef>();
  Set<TypeParameter> typeParametersInScope = new Set<TypeParameter>();
  Set<VariableDeclaration> variableDeclarationsInScope =
      new Set<VariableDeclaration>();
  final List<VariableDeclaration> variableStack = <VariableDeclaration>[];
  final Map<Typedef, TypedefState> typedefState = <Typedef, TypedefState>{};
  final Set<Constant> seenConstants = <Constant>{};
  bool classTypeParametersAreInScope = false;

  /// If true, relax certain checks for *outline* mode. For example, don't
  /// attempt to validate constructor initializers.
  final bool isOutline;

  /// If true, assume that constant evaluation has been performed (with a
  /// target that did not opt out of any of the constant inlining) and report
  /// a verification error for anything that should have been removed by it.
  final bool afterConst;

  /// If true, constant fields and local variables are expected to be inlined.
  final bool constantsAreAlwaysInlined;

  AsyncMarker currentAsyncMarker = AsyncMarker.Sync;

  bool inCatchBlock = false;

  bool inUnevaluatedConstant = false;

  bool inConstant = false;

  Library? currentLibrary;

  Member? currentMember;

  Class? currentClass;

  Extension? currentExtension;

  TreeNode? currentParent;

  TreeNode? get currentClassOrExtensionOrMember =>
      currentMember ?? currentClass ?? currentExtension;

  static void check(Component component,
      {bool? isOutline,
      bool? afterConst,
      required bool constantsAreAlwaysInlined}) {
    component.accept(new VerifyingVisitor(
        isOutline: isOutline,
        afterConst: afterConst,
        constantsAreAlwaysInlined: constantsAreAlwaysInlined));
  }

  VerifyingVisitor(
      {bool? isOutline,
      bool? afterConst,
      required this.constantsAreAlwaysInlined})
      : isOutline = isOutline ?? false,
        afterConst = afterConst ?? !(isOutline ?? false);

  @override
  void defaultTreeNode(TreeNode node) {
    visitChildren(node);
  }

  @override
  void defaultConstantReference(Constant constant) {
    if (seenConstants.add(constant)) {
      constant.accept(this);
    }
  }

  @override
  void defaultConstant(Constant constant) {
    constant.visitChildren(this);
  }

  void problem(TreeNode? node, String details, {TreeNode? context}) {
    context ??= currentClassOrExtensionOrMember;
    throw new VerificationError(context, node, details);
  }

  TreeNode? enterParent(TreeNode node) {
    if (!identical(node.parent, currentParent)) {
      problem(
          node,
          "Incorrect parent pointer on ${node.runtimeType}:"
          " expected '${currentParent.runtimeType}',"
          " but found: '${node.parent.runtimeType}'.",
          context: currentParent);
    }
    TreeNode? oldParent = currentParent;
    currentParent = node;
    return oldParent;
  }

  void exitParent(TreeNode? oldParent) {
    currentParent = oldParent;
  }

  int enterLocalScope() => variableStack.length;

  void exitLocalScope(int stackHeight) {
    for (int i = stackHeight; i < variableStack.length; ++i) {
      undeclareVariable(variableStack[i]);
    }
    variableStack.length = stackHeight;
  }

  void visitChildren(TreeNode node) {
    TreeNode? oldParent = enterParent(node);
    node.visitChildren(this);
    exitParent(oldParent);
  }

  void visitWithLocalScope(TreeNode node) {
    int stackHeight = enterLocalScope();
    visitChildren(node);
    exitLocalScope(stackHeight);
  }

  void declareMember(Member member) {
    if (member.transformerFlags & TransformerFlag.seenByVerifier != 0) {
      problem(member.function,
          "Member '$member' has been declared more than once.");
    }
    member.transformerFlags |= TransformerFlag.seenByVerifier;
  }

  void undeclareMember(Member member) {
    member.transformerFlags &= ~TransformerFlag.seenByVerifier;
  }

  void declareVariable(VariableDeclaration variable) {
    if (variableDeclarationsInScope.contains(variable)) {
      problem(variable, "Variable '$variable' declared more than once.");
    }
    variableDeclarationsInScope.add(variable);
    variableStack.add(variable);
  }

  void undeclareVariable(VariableDeclaration variable) {
    variableDeclarationsInScope.remove(variable);
  }

  void declareTypeParameters(List<TypeParameter> parameters) {
    for (int i = 0; i < parameters.length; ++i) {
      TypeParameter parameter = parameters[i];
      if (identical(parameter.bound, TypeParameter.unsetBoundSentinel)) {
        problem(
            currentParent, "Missing bound for type parameter '$parameter'.");
      }
      if (identical(
          parameter.defaultType, TypeParameter.unsetDefaultTypeSentinel)) {
        problem(currentParent,
            "Missing default type for type parameter '$parameter'.");
      }
      if (!typeParametersInScope.add(parameter)) {
        problem(parameter, "Type parameter '$parameter' redeclared.");
      }
    }
  }

  void undeclareTypeParameters(List<TypeParameter> parameters) {
    typeParametersInScope.removeAll(parameters);
  }

  void checkVariableInScope(VariableDeclaration variable, TreeNode where) {
    if (!variableDeclarationsInScope.contains(variable)) {
      problem(where, "Variable '$variable' used out of scope.");
    }
  }

  @override
  void visitComponent(Component component) {
    try {
      for (Library library in component.libraries) {
        for (Class class_ in library.classes) {
          if (!classes.add(class_)) {
            problem(class_, "Class '$class_' declared more than once.");
          }
        }
        for (Typedef typedef_ in library.typedefs) {
          if (!typedefs.add(typedef_)) {
            problem(typedef_, "Typedef '$typedef_' declared more than once.");
          }
        }
        library.members.forEach(declareMember);
        for (Class class_ in library.classes) {
          class_.members.forEach(declareMember);
        }
      }
      visitChildren(component);
    } finally {
      for (Library library in component.libraries) {
        library.members.forEach(undeclareMember);
        for (Class class_ in library.classes) {
          class_.members.forEach(undeclareMember);
        }
      }
      variableStack.forEach(undeclareVariable);
    }
  }

  @override
  void visitLibrary(Library node) {
    currentLibrary = node;
    super.visitLibrary(node);
    currentLibrary = null;
  }

  @override
  void visitExtension(Extension node) {
    currentExtension = node;
    declareTypeParameters(node.typeParameters);
    final TreeNode? oldParent = enterParent(node);
    node.visitChildren(this);
    exitParent(oldParent);
    undeclareTypeParameters(node.typeParameters);
    currentExtension = null;
  }

  void checkTypedef(Typedef node) {
    TypedefState? state = typedefState[node];
    if (state == TypedefState.Done) return;
    if (state == TypedefState.BeingChecked) {
      problem(node, "The typedef '$node' refers to itself", context: node);
    }
    assert(state == null);
    typedefState[node] = TypedefState.BeingChecked;
    Set<TypeParameter> savedTypeParameters = typeParametersInScope;
    typeParametersInScope = node.typeParameters.toSet()
      ..addAll(node.typeParametersOfFunctionType);
    TreeNode? savedParent = currentParent;
    currentParent = node;
    // Visit children without checking the parent pointer on the typedef itself
    // since this can be called from a context other than its true parent.
    node.visitChildren(this);
    currentParent = savedParent;
    typeParametersInScope = savedTypeParameters;
    typedefState[node] = TypedefState.Done;
  }

  @override
  void visitTypedef(Typedef node) {
    checkTypedef(node);
    // Enter and exit the node to check the parent pointer on the typedef node.
    exitParent(enterParent(node));
  }

  @override
  void visitField(Field node) {
    currentMember = node;
    TreeNode? oldParent = enterParent(node);
    bool isTopLevel = node.parent == currentLibrary;
    if (isTopLevel && !node.isStatic) {
      problem(node, "The top-level field '${node.name.text}' should be static",
          context: node);
    }
    if (node.isConst && !node.isStatic) {
      problem(node, "The const field '${node.name.text}' should be static",
          context: node);
    }
    bool isImmutable = node.isLate
        ? (node.isFinal && node.initializer != null)
        : (node.isFinal || node.isConst);
    if (isImmutable == node.hasSetter) {
      if (node.hasSetter) {
        problem(node,
            "The immutable field '${node.name.text}' has a setter reference",
            context: node);
      } else {
        if (isOutline && node.isLate) {
          // TODO(johnniwinther): Should we add a flag on Field for having
          // a declared initializer?
          // The initializer is not included in the outline so we can't tell
          // whether it has an initializer or not.
        } else {
          problem(node,
              "The mutable field '${node.name.text}' has no setter reference",
              context: node);
        }
      }
    }
    classTypeParametersAreInScope = !node.isStatic;
    node.initializer?.accept(this);
    node.type.accept(this);
    classTypeParametersAreInScope = false;
    visitList(node.annotations, this);
    exitParent(oldParent);
    currentMember = null;
  }

  @override
  void visitProcedure(Procedure node) {
    currentMember = node;
    TreeNode? oldParent = enterParent(node);
    classTypeParametersAreInScope = !node.isStatic;
    if (node.isAbstract && node.isExternal) {
      problem(node, "Procedure cannot be both abstract and external.");
    }
    if (node.isMemberSignature && node.isForwardingStub) {
      problem(
          node,
          "Procedure cannot be both a member signature and a forwarding stub: "
          "$node.");
    }
    if (node.isMemberSignature && node.isForwardingSemiStub) {
      problem(
          node,
          "Procedure cannot be both a member signature and a forwarding semi "
          "stub $node.");
    }
    if (node.isMemberSignature && node.isNoSuchMethodForwarder) {
      problem(
          node,
          "Procedure cannot be both a member signature and a noSuchMethod "
          "forwarder $node.");
    }
    if (node.isMemberSignature && node.memberSignatureOrigin == null) {
      problem(
          node, "Member signature must have a member signature origin $node.");
    }
    if (node.abstractForwardingStubTarget != null &&
        !(node.isForwardingStub || node.isForwardingSemiStub)) {
      problem(
          node,
          "Only forwarding stubs can have a forwarding stub interface target "
          "$node.");
    }
    if (node.concreteForwardingStubTarget != null &&
        !(node.isForwardingStub || node.isForwardingSemiStub)) {
      problem(
          node,
          "Only forwarding stubs can have a forwarding stub super target "
          "$node.");
    }
    node.function.accept(this);
    classTypeParametersAreInScope = false;
    visitList(node.annotations, this);
    exitParent(oldParent);
    currentMember = null;
  }

  @override
  void visitConstructor(Constructor node) {
    currentMember = node;
    classTypeParametersAreInScope = true;
    // The constructor member needs special treatment due to parameters being
    // in scope in the initializer list.
    TreeNode? oldParent = enterParent(node);
    int stackHeight = enterLocalScope();
    visitChildren(node.function);
    visitList(node.initializers, this);
    if (!isOutline) {
      checkInitializers(node);
    }
    exitLocalScope(stackHeight);
    classTypeParametersAreInScope = false;
    visitList(node.annotations, this);
    exitParent(oldParent);
    classTypeParametersAreInScope = false;
    currentMember = null;
  }

  @override
  void visitClass(Class node) {
    currentClass = node;
    declareTypeParameters(node.typeParameters);
    TreeNode? oldParent = enterParent(node);
    classTypeParametersAreInScope = false;
    visitList(node.annotations, this);
    classTypeParametersAreInScope = true;
    visitList(node.typeParameters, this);
    visitList(node.fields, this);
    visitList(node.constructors, this);
    visitList(node.procedures, this);
    exitParent(oldParent);
    undeclareTypeParameters(node.typeParameters);
    currentClass = null;
  }

  @override
  void visitFunctionNode(FunctionNode node) {
    declareTypeParameters(node.typeParameters);
    bool savedInCatchBlock = inCatchBlock;
    AsyncMarker savedAsyncMarker = currentAsyncMarker;
    currentAsyncMarker = node.asyncMarker;
    if (!isOutline &&
        currentMember!.isNonNullableByDefault &&
        node.asyncMarker == AsyncMarker.Async &&
        node.futureValueType == null) {
      problem(node,
          "No future value type set for async function in opt-in library.");
    }
    inCatchBlock = false;
    visitWithLocalScope(node);
    inCatchBlock = savedInCatchBlock;
    currentAsyncMarker = savedAsyncMarker;
    undeclareTypeParameters(node.typeParameters);
  }

  @override
  void visitFunctionType(FunctionType node) {
    for (int i = 1; i < node.namedParameters.length; ++i) {
      if (node.namedParameters[i - 1].compareTo(node.namedParameters[i]) >= 0) {
        problem(currentParent,
            "Named parameters are not sorted on function type ($node).");
      }
    }
    declareTypeParameters(node.typeParameters);
    for (TypeParameter typeParameter in node.typeParameters) {
      typeParameter.bound.accept(this);
      if (typeParameter.annotations.isNotEmpty) {
        problem(
            typeParameter, "Annotation on type parameter in function type.");
      }
    }
    visitList(node.positionalParameters, this);
    visitList(node.namedParameters, this);
    node.returnType.accept(this);
    undeclareTypeParameters(node.typeParameters);
  }

  @override
  void visitBlock(Block node) {
    visitWithLocalScope(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    visitWithLocalScope(node);
  }

  @override
  void visitForInStatement(ForInStatement node) {
    visitWithLocalScope(node);
  }

  @override
  void visitLet(Let node) {
    if (_isCompileTimeErrorEncoding(node)) return;
    visitWithLocalScope(node);
  }

  @override
  void visitInvalidExpression(InvalidExpression node) {
    return;
  }

  @override
  void visitBlockExpression(BlockExpression node) {
    int stackHeight = enterLocalScope();
    // Do not visit the block directly because the value expression needs to
    // be in its scope.
    TreeNode? oldParent = enterParent(node);
    enterParent(node.body);
    for (int i = 0; i < node.body.statements.length; ++i) {
      node.body.statements[i].accept(this);
    }
    exitParent(node);
    node.value.accept(this);
    exitParent(oldParent);
    exitLocalScope(stackHeight);
  }

  @override
  void visitCatch(Catch node) {
    bool savedInCatchBlock = inCatchBlock;
    inCatchBlock = true;
    visitWithLocalScope(node);
    inCatchBlock = savedInCatchBlock;
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    switch (currentAsyncMarker) {
      case AsyncMarker.Sync:
      case AsyncMarker.Async:
      case AsyncMarker.SyncYielding:
        // ok
        break;
      case AsyncMarker.SyncStar:
      case AsyncMarker.AsyncStar:
        problem(
            node,
            "Return statement in function with async marker: "
            "$currentAsyncMarker");
        break;
    }
    super.visitReturnStatement(node);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    switch (currentAsyncMarker) {
      case AsyncMarker.Sync:
      case AsyncMarker.Async:
        problem(
            node,
            "Yield statement in function with async marker: "
            "$currentAsyncMarker");
        break;
      case AsyncMarker.SyncStar:
      case AsyncMarker.AsyncStar:
      case AsyncMarker.SyncYielding:
        // ok
        break;
    }
    super.visitYieldStatement(node);
  }

  @override
  void visitRethrow(Rethrow node) {
    if (!inCatchBlock) {
      problem(node, "Rethrow must be inside a Catch block.");
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    TreeNode? parent = node.parent;
    if (parent is! Block &&
        !(parent is Catch && parent.body != node) &&
        !(parent is FunctionNode && parent.body != node) &&
        parent is! FunctionDeclaration &&
        !(parent is ForStatement && parent.body != node) &&
        !(parent is ForInStatement && parent.body != node) &&
        parent is! Let &&
        parent is! LocalInitializer &&
        parent is! Typedef) {
      problem(
          node,
          "VariableDeclaration must be a direct child of a Block, "
          "not ${parent.runtimeType}.");
    }
    visitChildren(node);
    declareVariable(node);
    if (afterConst && node.isConst) {
      Expression? initializer = node.initializer;
      if (constantsAreAlwaysInlined) {
        if (!(initializer is InvalidExpression ||
            initializer is ConstantExpression &&
                initializer.constant is UnevaluatedConstant)) {
          problem(node, "Constant VariableDeclaration");
        }
      }
    }
  }

  @override
  void visitVariableGet(VariableGet node) {
    checkVariableInScope(node.variable, node);
    visitChildren(node);
    if (constantsAreAlwaysInlined && afterConst && node.variable.isConst) {
      problem(node, "VariableGet of const variable '${node.variable}'.");
    }
  }

  @override
  void visitVariableSet(VariableSet node) {
    checkVariableInScope(node.variable, node);
    visitChildren(node);
  }

  @override
  void visitStaticGet(StaticGet node) {
    visitChildren(node);
    // ignore: unnecessary_null_comparison
    if (node.target == null) {
      problem(node, "StaticGet without target.");
    }
    // Currently Constructor.hasGetter returns `false` even though fasta uses it
    // as a getter for internal purposes:
    //
    // Fasta is letting all call site of a redirecting constructor be resolved
    // to the real target.  In order to resolve it, it seems to add a body into
    // the redirecting-factory constructor which caches the target constructor.
    // That cache is via a `StaticGet(real-constructor)` node, which we make
    // here pass the verifier.
    if (!node.target.hasGetter && node.target is! Constructor) {
      problem(node, "StaticGet of '${node.target}' without getter.");
    }
    if (node.target.isInstanceMember) {
      problem(node, "StaticGet of '${node.target}' that's an instance member.");
    }
    if (constantsAreAlwaysInlined &&
        afterConst &&
        node.target is Field &&
        node.target.isConst) {
      problem(node, "StaticGet of const field '${node.target}'.");
    }
  }

  @override
  void visitStaticSet(StaticSet node) {
    visitChildren(node);
    // ignore: unnecessary_null_comparison
    if (node.target == null) {
      problem(node, "StaticSet without target.");
    }
    if (!node.target.hasSetter) {
      problem(node, "StaticSet to '${node.target}' without setter.");
    }
    if (node.target.isInstanceMember) {
      problem(node, "StaticSet to '${node.target}' that's an instance member.");
    }
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    checkTargetedInvocation(node.target, node);
    if (node.target.isInstanceMember) {
      problem(node,
          "StaticInvocation of '${node.target}' that's an instance member.");
    }
    if (node.isConst &&
        (!node.target.isConst ||
            !node.target.isExternal ||
            node.target.kind != ProcedureKind.Factory)) {
      problem(
          node,
          "Constant StaticInvocation of '${node.target}' that isn't"
          " a const external factory.");
    }
    if (afterConst && node.isConst && !inUnevaluatedConstant) {
      problem(node, "Constant StaticInvocation.");
    }
  }

  @override
  void visitTypedefTearOff(TypedefTearOff node) {
    declareTypeParameters(node.typeParameters);
    super.visitTypedefTearOff(node);
    undeclareTypeParameters(node.typeParameters);
  }

  void checkTargetedInvocation(Member target, InvocationExpression node) {
    visitChildren(node);
    // ignore: unnecessary_null_comparison
    if (target == null) {
      problem(node, "${node.runtimeType} without target.");
    }
    if (target.function == null) {
      problem(node, "${node.runtimeType} without function.");
    }
    if (!areArgumentsCompatible(node.arguments, target.function!)) {
      problem(node,
          "${node.runtimeType} with incompatible arguments for '${target}'.");
    }
    int expectedTypeParameters = target is Constructor
        ? target.enclosingClass.typeParameters.length
        : target.function!.typeParameters.length;
    if (node.arguments.types.length != expectedTypeParameters) {
      problem(
          node,
          "${node.runtimeType} with wrong number of type arguments"
          " for '${target}'.");
    }
  }

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    checkTargetedInvocation(node.target, node);
    if (node.target.enclosingClass.isAbstract) {
      problem(node, "ConstructorInvocation of abstract class.");
    }
    if (node.isConst && !node.target.isConst) {
      problem(
          node,
          "Constant ConstructorInvocation fo '${node.target}' that"
          " isn't const.");
    }
    if (afterConst && node.isConst) {
      problem(node, "Invocation of const constructor '${node.target}'.");
    }
  }

  bool areArgumentsCompatible(Arguments arguments, FunctionNode function) {
    if (arguments.positional.length < function.requiredParameterCount) {
      return false;
    }
    if (arguments.positional.length > function.positionalParameters.length) {
      return false;
    }
    namedLoop:
    for (int i = 0; i < arguments.named.length; ++i) {
      NamedExpression argument = arguments.named[i];
      String name = argument.name;
      for (int j = 0; j < function.namedParameters.length; ++j) {
        if (function.namedParameters[j].name == name) continue namedLoop;
      }
      return false;
    }
    return true;
  }

  @override
  void visitListLiteral(ListLiteral node) {
    visitChildren(node);
    if (afterConst && node.isConst) {
      problem(node, "Constant list literal.");
    }
  }

  @override
  void visitSetLiteral(SetLiteral node) {
    visitChildren(node);
    if (afterConst && node.isConst) {
      problem(node, "Constant set literal.");
    }
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    visitChildren(node);
    if (afterConst && node.isConst) {
      problem(node, "Constant map literal.");
    }
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    if (afterConst) {
      problem(node, "Symbol literal.");
    }
  }

  @override
  void visitContinueSwitchStatement(ContinueSwitchStatement node) {
    // ignore: unnecessary_null_comparison
    if (node.target == null) {
      problem(node, "No target.");
    } else if (node.target.parent == null) {
      problem(node, "Target has no parent.");
    } else {
      SwitchStatement statement = node.target.parent as SwitchStatement;
      for (SwitchCase switchCase in statement.cases) {
        if (switchCase == node.target) return;
      }
      problem(node, "Switch case isn't child of parent.");
    }
  }

  @override
  void visitInstanceConstant(InstanceConstant constant) {
    constant.visitChildren(this);
    if (constant.typeArguments.length !=
        constant.classNode.typeParameters.length) {
      problem(
          currentParent,
          "Constant $constant provides ${constant.typeArguments.length}"
          " type arguments, but the class declares"
          " ${constant.classNode.typeParameters.length} parameters.");
    }
    Set<Class> superClasses = <Class>{};
    int fieldCount = 0;
    for (Class? cls = constant.classNode; cls != null; cls = cls.superclass) {
      superClasses.add(cls);
      for (Field f in cls.fields) {
        if (!f.isStatic && !f.isConst) fieldCount++;
      }
    }
    if (constant.fieldValues.length != fieldCount) {
      problem(
          currentParent,
          "Constant $constant provides ${constant.fieldValues.length}"
          " field values, but the class declares"
          " $fieldCount fields.");
    }
    constant.fieldValues.forEach((Reference fieldRef, Constant value) {
      Field field = fieldRef.asField;
      if (!superClasses.contains(field.enclosingClass)) {
        problem(
            currentParent,
            "Constant $constant refers to field $field,"
            " which does not belong to the right class.");
      }
    });
  }

  @override
  void visitUnevaluatedConstant(UnevaluatedConstant constant) {
    if (inUnevaluatedConstant) {
      problem(currentParent, "UnevaluatedConstant in UnevaluatedConstant.");
    }
    bool savedInUnevaluatedConstant = inUnevaluatedConstant;
    inUnevaluatedConstant = true;
    TreeNode? oldParent = currentParent;
    currentParent = null;
    constant.expression.accept(this);
    currentParent = oldParent;
    inUnevaluatedConstant = savedInUnevaluatedConstant;
  }

  @override
  void defaultMemberReference(Member node) {
    if (node.transformerFlags & TransformerFlag.seenByVerifier == 0) {
      problem(
          node, "Dangling reference to '$node', parent is: '${node.parent}'.");
    }
  }

  @override
  void visitClassReference(Class node) {
    if (!classes.contains(node)) {
      problem(
          node, "Dangling reference to '$node', parent is: '${node.parent}'.");
    }
  }

  @override
  void visitTypedefReference(Typedef node) {
    if (!typedefs.contains(node)) {
      problem(
          node, "Dangling reference to '$node', parent is: '${node.parent}'");
    }
  }

  @override
  void visitTypeParameterType(TypeParameterType node) {
    TypeParameter parameter = node.parameter;
    if (!typeParametersInScope.contains(parameter)) {
      TreeNode? owner = parameter.parent is FunctionNode
          ? parameter.parent!.parent
          : parameter.parent;
      problem(
          currentParent,
          "Type parameter '$parameter' referenced out of"
          " scope, owner is: '${owner}'.");
    }
    if (parameter.parent is Class && !classTypeParametersAreInScope) {
      problem(
          currentParent,
          "Type parameter '$parameter' referenced from"
          " static context, parent is: '${parameter.parent}'.");
    }
  }

  @override
  void visitInterfaceType(InterfaceType node) {
    node.visitChildren(this);
    if (node.typeArguments.length != node.classNode.typeParameters.length) {
      problem(
          currentParent,
          "Type $node provides ${node.typeArguments.length}"
          " type arguments, but the class declares"
          " ${node.classNode.typeParameters.length} parameters.");
    }
    if (node.classNode.isAnonymousMixin) {
      bool isOk = false;
      if (currentParent is FunctionNode) {
        TreeNode? functionNodeParent = currentParent!.parent;
        if (functionNodeParent is Constructor) {
          if (functionNodeParent.parent == node.classNode) {
            // We only allow references to anonymous mixins in types as the
            // return type of its own constructor.
            isOk = true;
          }
        }
      }
      if (!isOk) {
        problem(
            currentParent, "Type $node references an anonymous mixin class.");
      }
    }
    defaultDartType(node);
  }

  @override
  void visitTypedefType(TypedefType node) {
    checkTypedef(node.typedefNode);
    node.visitChildren(this);
    if (node.typeArguments.length != node.typedefNode.typeParameters.length) {
      problem(
          currentParent,
          "The typedef type $node provides ${node.typeArguments.length}"
          " type arguments, but the typedef declares"
          " ${node.typedefNode.typeParameters.length} parameters.");
    }
  }

  @override
  void visitConstantExpression(ConstantExpression node) {
    bool oldInConstant = inConstant;
    inConstant = true;
    visitChildren(node);
    inConstant = oldInConstant;
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    if (inConstant) {
      // Don't expect the type parameters to have the current parent as parent.
      node.visitChildren(this);
    } else {
      visitChildren(node);
    }
  }

  @override
  void visitTypedefTearOffConstant(TypedefTearOffConstant node) {
    declareTypeParameters(node.parameters);
    super.visitTypedefTearOffConstant(node);
    undeclareTypeParameters(node.parameters);
  }
}

void verifyGetStaticType(TypeEnvironment env, Component component) {
  component.accept(new VerifyGetStaticType(env));
}

class VerifyGetStaticType extends RecursiveVisitor {
  final TypeEnvironment env;
  Member? currentMember;
  final StatefulStaticTypeContext _staticTypeContext;

  VerifyGetStaticType(this.env)
      : _staticTypeContext = new StatefulStaticTypeContext.stacked(env);

  @override
  void visitLibrary(Library node) {
    _staticTypeContext.enterLibrary(node);
    super.visitLibrary(node);
    _staticTypeContext.leaveLibrary(node);
  }

  @override
  void visitField(Field node) {
    currentMember = node;
    _staticTypeContext.enterMember(node);
    super.visitField(node);
    _staticTypeContext.leaveMember(node);
    currentMember = node;
  }

  @override
  void visitProcedure(Procedure node) {
    currentMember = node;
    _staticTypeContext.enterMember(node);
    super.visitProcedure(node);
    _staticTypeContext.leaveMember(node);
    currentMember = node;
  }

  @override
  void visitConstructor(Constructor node) {
    currentMember = node;
    _staticTypeContext.enterMember(node);
    super.visitConstructor(node);
    _staticTypeContext.leaveMember(node);
    currentMember = null;
  }

  @override
  void visitLet(Let node) {
    if (_isCompileTimeErrorEncoding(node)) return;
    super.visitLet(node);
  }

  @override
  void visitInvalidExpression(InvalidExpression node) {
    return;
  }

  @override
  void defaultExpression(Expression node) {
    try {
      node.getStaticType(_staticTypeContext);
    } catch (_) {
      print('Error in $currentMember in ${currentMember?.fileUri}: '
          '$node (${node.runtimeType})');
      rethrow;
    }
    super.defaultExpression(node);
  }
}

class CheckParentPointers extends Visitor<void> with VisitorVoidMixin {
  static void check(TreeNode node) {
    node.accept(new CheckParentPointers(node.parent));
  }

  TreeNode? parent;

  CheckParentPointers([this.parent]);

  @override
  void defaultTreeNode(TreeNode node) {
    if (node.parent != parent) {
      throw new VerificationError(
          parent,
          node,
          "Parent pointer on '${node.runtimeType}' "
          "is '${node.parent.runtimeType}' "
          "but should be '${parent.runtimeType}'.");
    }
    TreeNode? oldParent = parent;
    parent = node;
    node.visitChildren(this);
    parent = oldParent;
  }
}

void checkInitializers(Constructor constructor) {
  // TODO(ahe): I'll add more here in other CLs.
}

bool _isCompileTimeErrorEncoding(TreeNode? node) {
  return node is Let && node.variable.initializer is InvalidExpression;
}
