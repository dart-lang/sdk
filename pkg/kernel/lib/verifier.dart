// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.checks;

import 'ast.dart';
import 'target/targets.dart';
import 'transformations/flags.dart';
import 'type_environment.dart' show StatefulStaticTypeContext, TypeEnvironment;

/// Stages at which verification can occur.
///
/// These can be used to enforce different invariants during different stages
/// of the compilation.
enum VerificationStage {
  /// Verification after the outline compilation.
  outline,

  /// Verification after the body, aka full, compilation, but before pre-
  /// constant evaluation transformations have been performed.
  beforePreConstantEvaluationTransformations,

  /// Verification after pre- constant evaluation transformations have been
  /// performed but before constant evaluation.
  beforeConstantEvaluation,

  /// Verification after constant evaluation but before modular transformations
  /// have been performed.
  afterConstantEvaluation,

  /// Verification after modular transformations have been performed.
  ///
  /// This is final stage of a normal compilation.
  afterModularTransformations,

  /// Verification after global transformations have been performed.
  ///
  /// The global transformation is an additional step performed by some
  /// backends which is not triggered by the front end compilation itself.
  afterGlobalTransformations,
  ;

  bool operator <(VerificationStage other) => index < other.index;
  bool operator <=(VerificationStage other) => index <= other.index;
  bool operator >(VerificationStage other) => index > other.index;
  bool operator >=(VerificationStage other) => index >= other.index;
}

/// Interface that defines how the AST is verified.
class Verification {
  const Verification();

  /// Returns `true` if [node] is allowed to have no file offset.
  bool allowNoFileOffset(VerificationStage stage, TreeNode node) {
    return node is Library;
  }

  /// Returns `true` if [node] is allowed to have location with a file offset
  /// that is not in the range of the enclosing file.
  bool allowInvalidLocation(VerificationStage stage, TreeNode node) {
    return false;
  }
}

void verifyComponent(
    Target target, VerificationStage stage, Component component,
    {bool skipPlatform = false}) {
  VerifyingVisitor.check(target, stage, component, skipPlatform: skipPlatform);
}

class VerificationErrorListener {
  const VerificationErrorListener();

  void reportError(String details,
      {required TreeNode? node,
      required Uri? problemUri,
      required int? problemOffset,
      required TreeNode? context,
      required TreeNode? origin}) {
    throw new VerificationError(context, node, details);
  }
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
  final Target target;

  Uri? fileUri;

  final VerificationErrorListener listener;

  final List<TreeNode> treeNodeStack = <TreeNode>[];
  final bool skipPlatform;

  final Set<Class> classes = new Set<Class>();
  final Set<Typedef> typedefs = new Set<Typedef>();
  Set<TypeParameter> typeParametersInScope = new Set<TypeParameter>();
  Set<VariableDeclaration> variableDeclarationsInScope =
      new Set<VariableDeclaration>();
  final List<VariableDeclaration> variableStack = <VariableDeclaration>[];
  final Map<Typedef, TypedefState> typedefState = <Typedef, TypedefState>{};
  final Set<Constant> seenConstants = <Constant>{};

  Map<Reference, ExtensionMemberDescriptor>? _extensionsMembers;
  Map<Reference, ExtensionTypeMemberDescriptor>? _extensionTypeMembers;

  bool classTypeParametersAreInScope = false;

  /// The compilation stage at which this verification is performed.
  final VerificationStage stage;

  AsyncMarker currentAsyncMarker = AsyncMarker.Sync;

  bool inCatchBlock = false;

  bool inUnevaluatedConstant = false;

  bool inConstant = false;

  Library? currentLibrary;

  Member? currentMember;

  Class? currentClass;

  Extension? currentExtension;

  ExtensionTypeDeclaration? currentExtensionTypeDeclaration;

  TreeNode? currentParent;

  TreeNode? get currentClassOrExtensionOrMember =>
      currentMember ??
      currentClass ??
      currentExtension ??
      currentExtensionTypeDeclaration;

  static void check(Target target, VerificationStage stage, Component component,
      {required bool skipPlatform}) {
    component.accept(
        new VerifyingVisitor(target, stage, skipPlatform: skipPlatform));
  }

  VerifyingVisitor(this.target, this.stage,
      {required this.skipPlatform,
      VerificationErrorListener this.listener =
          const VerificationErrorListener()});

  /// If true, relax certain checks for *outline* mode. For example, don't
  /// attempt to validate constructor initializers.
  bool get isOutline => stage == VerificationStage.outline;

  /// If true, assume that constant evaluation has been performed (with a
  /// target that did not opt out of any of the constant inlining) and report
  /// a verification error for anything that should have been removed by it.
  bool get afterConst => stage >= VerificationStage.afterConstantEvaluation;

  /// If true, constant fields and local variables are expected to be inlined.
  bool get constantsAreAlwaysInlined =>
      target.constantsBackend.alwaysInlineConstants;

  @override
  void defaultTreeNode(TreeNode node) {
    enterTreeNode(node);
    visitChildren(node);
    exitTreeNode(node);
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

  void problem(TreeNode? node, String details,
      {TreeNode? context, TreeNode? origin}) {
    TreeNode? problemNode = node ?? context ?? currentClassOrExtensionOrMember;
    int offset = problemNode?.fileOffset ?? -1;
    Location? location = problemNode != null
        ? _getLocation(problemNode, allowInvalidLocation: true)
        : null;
    Uri? file = location?.file ?? fileUri;
    Uri? uri = file == null ? null : file;
    String verifierState = 'Target=${target.name}, $stage: ';
    listener.reportError('$verifierState$details',
        problemUri: uri,
        problemOffset: offset,
        node: node,
        context: context ?? currentClassOrExtensionOrMember,
        origin: origin);
  }

  TreeNode? enterParent(TreeNode node) {
    if (!identical(node.parent, currentParent)) {
      problem(
          node,
          "Incorrect parent pointer on ${node}:"
          " expected ${currentParent},"
          " but found: ${node.parent}.",
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
    enterTreeNode(node);
    int stackHeight = enterLocalScope();
    visitChildren(node);
    exitLocalScope(stackHeight);
    exitTreeNode(node);
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
    if (skipPlatform &&
        node.importUri.isScheme('dart') &&
        // 'dart:test' is used in the unit tests and isn't an actual part of the
        // platform so we don't skip its verification.
        node.importUri.path != 'test') {
      return;
    }

    enterTreeNode(node);
    fileUri = checkLocation(node, node.name, node.fileUri);
    currentLibrary = node;
    super.visitLibrary(node);
    currentLibrary = null;
    exitTreeNode(node);
    _extensionsMembers = null;
    _extensionTypeMembers = null;
  }

  Map<Reference, ExtensionMemberDescriptor> _computeExtensionMembers(
      Library library) {
    if (_extensionsMembers == null) {
      Map<Reference, ExtensionMemberDescriptor> map = _extensionsMembers = {};
      for (Extension extension in library.extensions) {
        for (ExtensionMemberDescriptor descriptor in extension.members) {
          map[descriptor.member] = descriptor;
          Member member = descriptor.member.asMember;
          if (!member.isExtensionMember) {
            problem(
                member,
                "Member $member (${descriptor}) from $extension is not marked "
                "as an extension member.");
          }
        }
      }
    }
    return _extensionsMembers!;
  }

  Map<Reference, ExtensionTypeMemberDescriptor> _computeExtensionTypeMembers(
      Library library) {
    if (_extensionTypeMembers == null) {
      Map<Reference, ExtensionTypeMemberDescriptor> map =
          _extensionTypeMembers = {};
      for (ExtensionTypeDeclaration extensionTypeDeclaration
          in library.extensionTypeDeclarations) {
        for (ExtensionTypeMemberDescriptor descriptor
            in extensionTypeDeclaration.members) {
          map[descriptor.member] = descriptor;
          Member member = descriptor.member.asMember;
          if (!member.isExtensionTypeMember) {
            problem(
                member,
                "Member $member (${descriptor}) from $extensionTypeDeclaration "
                "is not marked as an extension type member.");
          }
        }
      }
    }
    return _extensionTypeMembers!;
  }

  @override
  void visitExtension(Extension node) {
    enterTreeNode(node);
    fileUri = checkLocation(node, node.name, node.fileUri);
    currentExtension = node;
    _computeExtensionMembers(node.enclosingLibrary);
    declareTypeParameters(node.typeParameters);
    final TreeNode? oldParent = enterParent(node);
    node.visitChildren(this);
    exitParent(oldParent);
    undeclareTypeParameters(node.typeParameters);
    currentExtension = null;
    exitTreeNode(node);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    enterTreeNode(node);
    fileUri = checkLocation(node, node.name, node.fileUri);
    currentExtensionTypeDeclaration = node;
    _computeExtensionTypeMembers(node.enclosingLibrary);
    declareTypeParameters(node.typeParameters);
    final TreeNode? oldParent = enterParent(node);
    for (DartType type in node.implements) {
      if (!(type is ExtensionType || type is InterfaceType)) {
        problem(
            node,
            "Extension type can only implement extension types and interface "
            "types. Found $type.");
      } else if (type.isPotentiallyNullable) {
        problem(
            node,
            "Extension type can only implement non-nullable types. "
            "Found $type.");
      }
    }
    node.visitChildren(this);
    exitParent(oldParent);
    undeclareTypeParameters(node.typeParameters);
    currentExtensionTypeDeclaration = null;
    exitTreeNode(node);
  }

  void checkTypedef(Typedef node) {
    TypedefState? state = typedefState[node];
    if (state == TypedefState.Done) return;
    if (state == TypedefState.BeingChecked) {
      problem(node, "The typedef '$node' refers to itself", context: node);
    }
    assert(state == null);
    enterTreeNode(node);
    typedefState[node] = TypedefState.BeingChecked;
    Set<TypeParameter> savedTypeParameters = typeParametersInScope;
    typeParametersInScope = node.typeParameters.toSet();
    TreeNode? savedParent = currentParent;
    currentParent = node;
    // Visit children without checking the parent pointer on the typedef itself
    // since this can be called from a context other than its true parent.
    node.visitChildren(this);
    currentParent = savedParent;
    typeParametersInScope = savedTypeParameters;
    typedefState[node] = TypedefState.Done;
    exitTreeNode(node);
  }

  @override
  void visitTypedef(Typedef node) {
    enterTreeNode(node);
    fileUri = checkLocation(node, node.name, node.fileUri);
    checkTypedef(node);
    // Enter and exit the node to check the parent pointer on the typedef node.
    exitParent(enterParent(node));
    exitTreeNode(node);
  }

  void _findExtensionMember(Member node) {
    assert(node.isExtensionMember);
    Map<Reference, ExtensionMemberDescriptor> extensionMembers =
        _computeExtensionMembers(node.enclosingLibrary);
    if (!extensionMembers.containsKey(node.reference)) {
      problem(
          node,
          "Extension member $node is not found in any extension of the "
          "enclosing library.");
    }
  }

  void _findExtensionTypeMember(Member node) {
    assert(node.isExtensionTypeMember);
    Map<Reference, ExtensionTypeMemberDescriptor> extensionTypeMembers =
        _computeExtensionTypeMembers(node.enclosingLibrary);
    if (!extensionTypeMembers.containsKey(node.reference)) {
      problem(
          node,
          "Extension type member $node is not found in any extension type "
          "declaration of the enclosing library.");
    }
  }

  @override
  void visitField(Field node) {
    enterTreeNode(node);
    fileUri = checkLocation(node, node.name.text, node.fileUri);
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
    if (node.isExtensionMember) {
      _findExtensionMember(node);
    }
    if (node.isExtensionTypeMember) {
      _findExtensionTypeMember(node);
    }
    classTypeParametersAreInScope = !node.isStatic;
    node.initializer?.accept(this);
    node.type.accept(this);
    classTypeParametersAreInScope = false;
    visitList(node.annotations, this);
    exitParent(oldParent);
    currentMember = null;
    exitTreeNode(node);
  }

  @override
  void visitProcedure(Procedure node) {
    enterTreeNode(node);
    fileUri = checkLocation(node, node.name.text, node.fileUri);
    if (node.isExtensionMember) {
      _findExtensionMember(node);
    }
    if (node.isExtensionTypeMember) {
      _findExtensionTypeMember(node);
    }

    if (node.isRedirectingFactory &&
        node.function.redirectingFactoryTarget == null) {
      problem(
          node,
          "Procedure '${node.name}' doesn't have a redirecting "
          "factory target, but has the 'isRedirectingFactory' bit set.");
    } else if (!node.isRedirectingFactory &&
        node.function.redirectingFactoryTarget != null) {
      problem(
          node,
          "Procedure '${node.name}' has redirecting factory target, but "
          "doesn't have the 'isRedirectingFactory' bit set.");
    }

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
    // TODO(johnniwinther): Enable this invariant. Possibly by removing bodies
    // from external procedures declared with a body or by removing the external
    // flag from such procedures.
    /*if (node.isExternal) {
      if (node.function.body != null) {
        problem(node, "External procedure has non-null body.");
      }
    } else if (node.isAbstract) {
      if (node.function.body != null) {
        problem(node, "Abstract procedure has non-null body.");
      }
    } else {
      if (node.function.body == null) {
        problem(node, "Non-external/abstract procedure has no body.");
      }
    }*/
    currentMember = null;
    exitTreeNode(node);
  }

  @override
  void visitConstructor(Constructor node) {
    enterTreeNode(node);
    fileUri = checkLocation(node, node.name.text, node.fileUri);
    currentMember = node;
    classTypeParametersAreInScope = true;
    if (node.isExtensionMember) {
      _findExtensionMember(node);
    }
    if (node.isExtensionTypeMember) {
      _findExtensionTypeMember(node);
    }

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
    // TODO(johnniwinther): Enable this invariant. Possibly by removing bodies
    // from external constructors declared with a body or by removing the
    // external flag from such constructors.
    /*if (node.isExternal) {
      if (node.function.body != null) {
        problem(node, "External constructor has non-null body.");
      }
    } else {
      if (node.function.body == null) {
        problem(node, "Non-external constructor has no body.");
      }
    }*/
    classTypeParametersAreInScope = false;
    currentMember = null;
    exitTreeNode(node);
  }

  @override
  void visitClass(Class node) {
    enterTreeNode(node);
    fileUri = checkLocation(node, node.name, node.fileUri);
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
    exitTreeNode(node);
  }

  @override
  void visitFunctionNode(FunctionNode node) {
    enterTreeNode(node);
    declareTypeParameters(node.typeParameters);
    bool savedInCatchBlock = inCatchBlock;
    AsyncMarker savedAsyncMarker = currentAsyncMarker;
    currentAsyncMarker = node.asyncMarker;
    if (!isOutline &&
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
    exitTreeNode(node);
  }

  @override
  void visitFunctionType(FunctionType node) {
    if (node.typeParameters.isNotEmpty) {
      for (TypeParameter typeParameter in node.typeParameters) {
        if (typeParameter.parent != null) {
          problem(
              localContext,
              "Type parameters of function types shouldn't have parents: "
              "$node.");
        }
      }
    }
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
    enterTreeNode(node);
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
    exitTreeNode(node);
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
        // ok
        break;
      case AsyncMarker.SyncStar:
      case AsyncMarker.AsyncStar:
        if (node.expression != null) {
          problem(
              node,
              "Return statement in function with async marker: "
              "$currentAsyncMarker");
        }
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
    enterTreeNode(node);
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
    exitTreeNode(node);
  }

  @override
  void visitVariableGet(VariableGet node) {
    enterTreeNode(node);
    checkVariableInScope(node.variable, node);
    visitChildren(node);
    if (constantsAreAlwaysInlined &&
        afterConst &&
        node.variable.isConst &&
        !inUnevaluatedConstant) {
      problem(node, "VariableGet of const variable '${node.variable}'.");
    }
    exitTreeNode(node);
  }

  @override
  void visitVariableSet(VariableSet node) {
    enterTreeNode(node);
    checkVariableInScope(node.variable, node);
    visitChildren(node);
    exitTreeNode(node);
  }

  @override
  void visitStaticGet(StaticGet node) {
    enterTreeNode(node);
    visitChildren(node);
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
    exitTreeNode(node);
  }

  @override
  void visitStaticSet(StaticSet node) {
    enterTreeNode(node);
    visitChildren(node);
    if (!node.target.hasSetter) {
      problem(node, "StaticSet to '${node.target}' without setter.");
    }
    if (node.target.isInstanceMember) {
      problem(node, "StaticSet to '${node.target}' that's an instance member.");
    }
    exitTreeNode(node);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    enterTreeNode(node);
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
    exitTreeNode(node);
  }

  @override
  void visitTypedefTearOff(TypedefTearOff node) {
    _checkTypedefTearOff(node);
    declareTypeParameters(node.typeParameters);
    super.visitTypedefTearOff(node);
    undeclareTypeParameters(node.typeParameters);
  }

  void checkTargetedInvocation(Member target, InvocationExpression node) {
    visitChildren(node);
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
    enterTreeNode(node);
    checkTargetedInvocation(node.target, node);
    if (node.target.enclosingClass.isAbstract) {
      problem(node, "$node of abstract class ${node.target.enclosingClass}.");
    }
    if (node.isConst && !node.target.isConst) {
      problem(
          node,
          "Constant ConstructorInvocation fo '${node.target}' that"
          " isn't const.");
    }
    if (afterConst && node.isConst && !inUnevaluatedConstant) {
      problem(node, "Invocation of const constructor '${node.target}'.");
    }
    exitTreeNode(node);
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
    enterTreeNode(node);
    visitChildren(node);
    if (afterConst && node.isConst && !inUnevaluatedConstant) {
      problem(node, "Constant list literal.");
    }
    exitTreeNode(node);
  }

  @override
  void visitSetLiteral(SetLiteral node) {
    enterTreeNode(node);
    visitChildren(node);
    if (afterConst && node.isConst && !inUnevaluatedConstant) {
      problem(node, "Constant set literal.");
    }
    exitTreeNode(node);
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    enterTreeNode(node);
    visitChildren(node);
    if (afterConst && node.isConst && !inUnevaluatedConstant) {
      problem(node, "Constant map literal.");
    }
    exitTreeNode(node);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    enterTreeNode(node);
    if (afterConst && !inUnevaluatedConstant) {
      problem(node, "Symbol literal.");
    }
    exitTreeNode(node);
  }

  @override
  void visitContinueSwitchStatement(ContinueSwitchStatement node) {
    enterTreeNode(node);
    if (node.target.parent == null) {
      problem(node, "Target has no parent.");
    } else {
      SwitchStatement statement = node.target.parent as SwitchStatement;
      for (SwitchCase switchCase in statement.cases) {
        if (switchCase == node.target) {
          exitTreeNode(node);
          return;
        }
      }
      problem(node, "Switch case isn't child of parent.");
    }
    exitTreeNode(node);
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
    if (isNullType(node) && node.nullability != Nullability.nullable) {
      problem(localContext, "Found a not nullable Null type: ${node}");
    }
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
    enterTreeNode(node);
    bool oldInConstant = inConstant;
    inConstant = true;
    visitChildren(node);
    inConstant = oldInConstant;
    exitTreeNode(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    if (identical(node.bound, TypeParameter.unsetBoundSentinel)) {
      problem(node, "Unset bound on type parameter $node");
    }
    if (identical(node.defaultType, TypeParameter.unsetDefaultTypeSentinel)) {
      problem(node, "Unset default type on type parameter $node");
    }
    if (inConstant) {
      // Don't expect the type parameters to have the current parent as parent.
      node.visitChildren(this);
    } else {
      visitChildren(node);
    }
  }

  @override
  void visitTypedefTearOffConstant(TypedefTearOffConstant node) {
    _checkTypedefTearOff(node);
    declareTypeParameters(node.parameters);
    super.visitTypedefTearOffConstant(node);
    undeclareTypeParameters(node.parameters);
  }

  @override
  void visitInstanceInvocation(InstanceInvocation node) {
    if (node.name != node.interfaceTarget.name) {
      problem(
          node,
          "Instance invocation with name '${node.name}' has a "
          "target with name '${node.interfaceTarget.name}'.");
    }
    super.visitInstanceInvocation(node);
  }

  @override
  void visitInstanceGet(InstanceGet node) {
    if (node.name != node.interfaceTarget.name) {
      problem(
          node,
          "Instance get with name '${node.name}' has a "
          "target with name '${node.interfaceTarget.name}'.");
    }
    super.visitInstanceGet(node);
  }

  @override
  void visitInstanceTearOff(InstanceTearOff node) {
    if (node.name != node.interfaceTarget.name) {
      problem(
          node,
          "Instance tear-off with name '${node.name}' has a "
          "target with name '${node.interfaceTarget.name}'.");
    }
    super.visitInstanceTearOff(node);
  }

  @override
  void visitInstanceSet(InstanceSet node) {
    if (node.name != node.interfaceTarget.name) {
      problem(
          node,
          "Instance set with name '${node.name}' has a "
          "target with name '${node.interfaceTarget.name}'.");
    }
    super.visitInstanceSet(node);
  }

  /// Invoked by all visit methods if the visited node is a [TreeNode].
  // TODO(johnniwinther): Merge this with enter/exitParent.
  void enterTreeNode(TreeNode node) {
    treeNodeStack.add(node);
  }

  /// Invoked by all visit methods if the visited node is a [TreeNode].
  void exitTreeNode(TreeNode node) {
    if (treeNodeStack.isEmpty) {
      throw new StateError("Attempting to exit tree node '${node}' "
          "when the tree node stack is empty.");
    }
    if (!identical(treeNodeStack.last, node)) {
      throw new StateError("Attempting to exit tree node '${node}' "
          "when another node '${treeNodeStack.last}' is active.");
    }
    treeNodeStack.removeLast();
  }

  TreeNode? getLastSeenTreeNode({bool withLocation = false}) {
    assert(treeNodeStack.isNotEmpty);
    for (int i = treeNodeStack.length - 1; i >= 0; --i) {
      TreeNode node = treeNodeStack[i];
      if (withLocation && !_hasLocation(node)) continue;
      return node;
    }
    return null;
  }

  TreeNode? getSameLibraryLastSeenTreeNode({bool withLocation = false}) {
    if (treeNodeStack.isEmpty) return null;
    if (currentLibrary == null) return null;

    for (int i = treeNodeStack.length - 1; i >= 0; --i) {
      TreeNode node = treeNodeStack[i];
      if (withLocation && !_hasLocation(node)) continue;
      Location? location = _getLocation(node);
      if (location != null && location.file == currentLibrary!.fileUri) {
        return node;
      }
    }
    return null;
  }

  /// Returns the `TreeNode.location` while handling [RangeError]s caused by
  /// file offsets not within the range of the enclosing file.
  Location? _getLocation(TreeNode node, {bool allowInvalidLocation = false}) {
    try {
      return node.location;
    } on RangeError catch (e) {
      if (allowInvalidLocation ||
          target.verification.allowInvalidLocation(stage, node)) {
        return null;
      }
      problem(
          node,
          "Invalid location with target '${target.name}' on "
          "${node} (${node.runtimeType}): $e");
    }
    return null;
  }

  bool _hasLocation(TreeNode node) {
    Location? location = _getLocation(node);
    return location != null && node.fileOffset != TreeNode.noOffset;
  }

  bool _isInSameLibrary(Library? library, TreeNode node) {
    if (library == null) return false;
    Location? location = _getLocation(node);
    if (location == null) return false;
    return library.fileUri == location.file;
  }

  TreeNode? get localContext {
    TreeNode? result = getSameLibraryLastSeenTreeNode(withLocation: true);
    if (result == null &&
        currentClassOrExtensionOrMember != null &&
        _isInSameLibrary(currentLibrary, currentClassOrExtensionOrMember!)) {
      result = currentClassOrExtensionOrMember;
    }
    return result;
  }

  TreeNode? get remoteContext {
    TreeNode? result = getLastSeenTreeNode(withLocation: true);
    if (result != null && _isInSameLibrary(currentLibrary, result)) {
      result = null;
    }
    return result;
  }

  Uri checkLocation(TreeNode node, String? name, Uri fileUri) {
    if (name == null || name.contains("#")) {
      // TODO(ahe): Investigate if these checks can be enabled:
      // if (node.fileUri != null && node is! Library) {
      //   problem(node, "A synthetic node shouldn't have a fileUri",
      //       context: node);
      // }
      // if (node.fileOffset != -1) {
      //   problem(node, "A synthetic node shouldn't have a fileOffset",
      //       context: node);
      // }
      return fileUri;
    } else {
      if (node.fileOffset == TreeNode.noOffset &&
          !target.verification.allowNoFileOffset(stage, node)) {
        problem(node, "'$name' has no fileOffset", context: node);
      }
      return fileUri;
    }
  }

  void checkSuperInvocation(TreeNode node) {
    Member? containingMember = getContainingMember(node);
    if (containingMember == null) {
      problem(node, 'Super call outside of any member');
    } else {
      if (!containingMember.containsSuperCalls) {
        problem(
            node, 'Super call in a member lacking TransformerFlag.superCalls');
      }
    }
  }

  Member? getContainingMember(TreeNode? node) {
    while (node != null) {
      if (node is Member) return node;
      node = node.parent;
    }
    return null;
  }

  @override
  void visitAsExpression(AsExpression node) {
    enterTreeNode(node);
    super.visitAsExpression(node);
    if (node.fileOffset == TreeNode.noOffset &&
        !node.isUnchecked &&
        !target.verification.allowNoFileOffset(stage, node)) {
      TreeNode? parent = node.parent;
      while (parent != null) {
        if (parent.fileOffset != TreeNode.noOffset) break;
        parent = parent.parent;
      }
      problem(parent, "No offset for $node", context: node);
    }
    exitTreeNode(node);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    // Bypass verification of the [StaticGet] in [RedirectingFactoryBody] as
    // this is a static get without a getter.
    enterTreeNode(node);
    super.visitExpressionStatement(node);
    exitTreeNode(node);
  }

  bool isNullType(DartType node) => node is NullType;

  bool isObjectClass(Class c) {
    return c.name == "Object" &&
        c.enclosingLibrary.importUri.isScheme("dart") &&
        c.enclosingLibrary.importUri.path == "core";
  }

  bool isTopType(DartType node) {
    return node is DynamicType ||
        node is VoidType ||
        node is InterfaceType &&
            isObjectClass(node.classNode) &&
            (node.nullability == Nullability.nullable ||
                node.nullability == Nullability.legacy) ||
        node is FutureOrType && isTopType(node.typeArgument);
  }

  bool isFutureOrNull(DartType node) {
    return isNullType(node) ||
        node is FutureOrType && isFutureOrNull(node.typeArgument);
  }

  @override
  void defaultDartType(DartType node) {
    final TreeNode? localContext = this.localContext;
    final TreeNode? remoteContext = this.remoteContext;

    if (!KnownTypes.isKnown(node)) {
      problem(localContext, "Unexpected appearance of the unknown type.",
          origin: remoteContext);
    }

    // TODO(johnniwinther): This check wasn't called from InterfaceType and
    // is currently very broken. Disabling for now.
    /*bool isTypeCast = localContext != null &&
        localContext is AsExpression &&
        localContext.isTypeError;
    // Don't check cases like foo(x as{TypeError} T).  In cases where foo comes
    // from a library with a different opt-in status than the current library,
    // the check may not be necessary.  For now, just skip all type-error casts.
    // TODO(cstefantsova): Implement a more precise analysis.
    bool isFromAnotherLibrary = remoteContext != null || isTypeCast;

    // Checking for non-legacy types in opt-out libraries.
    {
      bool neverLegacy = isNullType(node) ||
          isFutureOrNull(node) ||
          isTopType(node) ||
          node is InvalidType ||
          node is NeverType ||
          node is BottomType;
      // TODO(cstefantsova): Consider checking types coming from other
      // libraries.
      bool expectedLegacy = !isFromAnotherLibrary &&
          !currentLibrary.isNonNullableByDefault &&
          !neverLegacy;
      if (expectedLegacy && node.nullability != Nullability.legacy) {
        problem(localContext,
            "Found a non-legacy type '${node}' in an opted-out library.",
            origin: remoteContext);
      }
    }

    // Checking for legacy types in opt-in libraries.
    {
      Nullability nodeNullability =
          node is InvalidType ? Nullability.undetermined : node.nullability;
      // TODO(cstefantsova): Consider checking types coming from other
      // libraries.
      if (!isFromAnotherLibrary &&
          currentLibrary.isNonNullableByDefault &&
          nodeNullability == Nullability.legacy) {
        problem(localContext,
            "Found a legacy type '${node}' in an opted-in library.",
            origin: remoteContext);
      }
    }*/

    super.defaultDartType(node);
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    enterTreeNode(node);
    checkSuperInvocation(node);
    super.visitSuperMethodInvocation(node);
    exitTreeNode(node);
  }

  @override
  void visitSuperPropertyGet(SuperPropertyGet node) {
    enterTreeNode(node);
    checkSuperInvocation(node);
    super.visitSuperPropertyGet(node);
    exitTreeNode(node);
  }

  @override
  void visitSuperPropertySet(SuperPropertySet node) {
    enterTreeNode(node);
    checkSuperInvocation(node);
    super.visitSuperPropertySet(node);
    exitTreeNode(node);
  }

  void _checkConstructorTearOff(Node node, Member tearOffTarget) {
    if (tearOffTarget.enclosingLibrary.importUri.isScheme('dart')) {
      // Platform libraries are not compilation with test flags and might
      // contain tear-offs not expected when testing lowerings.
      return;
    }
    if (tearOffTarget is Constructor &&
        target.isConstructorTearOffLoweringEnabled) {
      problem(
          node is TreeNode ? node : getLastSeenTreeNode(),
          '${node.runtimeType} nodes for generative constructors should be '
          'lowered for target "${target.name}".');
    }
    if (tearOffTarget is Procedure &&
        tearOffTarget.isFactory &&
        target.isFactoryTearOffLoweringEnabled) {
      problem(
          node is TreeNode ? node : getLastSeenTreeNode(),
          '${node.runtimeType} nodes for factory constructors should be '
          'lowered for target "${target.name}".');
    }
  }

  @override
  void visitConstructorTearOff(ConstructorTearOff node) {
    _checkConstructorTearOff(node, node.target);
    super.visitConstructorTearOff(node);
  }

  @override
  void visitConstructorTearOffConstant(ConstructorTearOffConstant node) {
    _checkConstructorTearOff(node, node.target);
    super.visitConstructorTearOffConstant(node);
  }

  void _checkTypedefTearOff(Node node) {
    if (target.isTypedefTearOffLoweringEnabled) {
      problem(
          node is TreeNode ? node : getLastSeenTreeNode(),
          '${node.runtimeType} nodes for typedefs should be '
          'lowered for target "${target.name}".');
    }
  }

  void _checkRedirectingFactoryTearOff(Node node) {
    if (target.isRedirectingFactoryTearOffLoweringEnabled) {
      problem(
          node is TreeNode ? node : getLastSeenTreeNode(),
          'ConstructorTearOff nodes for redirecting factories should be '
          'lowered for target "${target.name}".');
    }
  }

  @override
  void visitRedirectingFactoryTearOff(RedirectingFactoryTearOff node) {
    _checkRedirectingFactoryTearOff(node);
    super.visitRedirectingFactoryTearOff(node);
  }

  @override
  void visitRedirectingFactoryTearOffConstant(
      RedirectingFactoryTearOffConstant node) {
    _checkRedirectingFactoryTearOff(node);
    super.visitRedirectingFactoryTearOffConstant(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    if (node.expressionTypeInternal == null) {
      problem(node, 'SwitchStatement.expressionType has not been set.');
    }
    super.visitSwitchStatement(node);
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

class KnownTypes implements DartTypeVisitor<bool> {
  static bool isKnown(DartType type) {
    return type.accept(const KnownTypes());
  }

  const KnownTypes();

  @override
  bool defaultDartType(DartType node) => false;

  @override
  bool visitDynamicType(DynamicType node) => true;

  @override
  bool visitFunctionType(FunctionType node) => true;

  @override
  bool visitFutureOrType(FutureOrType node) => true;

  @override
  bool visitExtensionType(ExtensionType node) => true;

  @override
  bool visitInterfaceType(InterfaceType node) => true;

  @override
  bool visitIntersectionType(IntersectionType node) => true;

  @override
  bool visitInvalidType(InvalidType node) => true;

  @override
  bool visitNeverType(NeverType node) => true;

  @override
  bool visitNullType(NullType node) => true;

  @override
  bool visitRecordType(RecordType node) => true;

  @override
  bool visitTypeParameterType(TypeParameterType node) => true;

  @override
  bool visitTypedefType(TypedefType node) => true;

  @override
  bool visitVoidType(VoidType node) => true;
}
