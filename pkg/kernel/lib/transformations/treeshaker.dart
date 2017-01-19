// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.tree_shaker;

import '../ast.dart';
import '../class_hierarchy.dart';
import '../core_types.dart';

Program transformProgram(Program program) {
  new TreeShaker(program).transform(program);
  return program;
}

/// Tree shaking based on class hierarchy analysis.
///
/// Any dynamic dispatch not on `this` is conservatively assumed to target
/// any instantiated class that implements a member matching the selector.
///
/// Member bodies are analyzed relative to a given "host class" which is the
/// concrete type of `this` (or null if in static context), so dispatches on
/// `this` can be resolved more precisely.
///
/// The tree shaker computes the following in a fixed-point iteration:
/// - a set of instantiated classes
/// - for each member, a set of potential host classes
/// - a set of names used in dynamic dispatch not on `this`
///
/// The `dart:mirrors` library is not supported.
//
// TODO(asgerf): Shake off parts of the core libraries based on the Target.
// TODO(asgerf): Tree shake unused instance fields.
class TreeShaker {
  final Program program;
  final ClassHierarchy hierarchy;
  final CoreTypes coreTypes;

  /// Names used in a dynamic dispatch invocation that could not be resolved
  /// to a concrete target (i.e. not on `this`).
  final Set<Name> _dispatchedNames = new Set<Name>();

  /// Instance members that are potential targets for dynamic dispatch, but
  /// whose name has not yet been seen in a dynamic dispatch invocation.
  ///
  /// The map is indexed by the name of the member, and value is a list of
  /// interleaved (host class, member) pairs.
  final Map<Name, List<TreeNode>> _dispatchTargetCandidates =
      <Name, List<TreeNode>>{};

  /// Map from classes to the set of members that are reachable with that
  /// class as host.
  ///
  /// The map is implemented as a list, indexed according to
  /// [ClassHierarchy.getClassIndex].
  final List<Set<Member>> _usedMembersWithHost;

  /// Map from used members (regardless of host) to a summary object describing
  /// how the member invokes other members on `this`.
  ///
  /// The summary object is a heterogenous list containing the [Member]s that
  /// are invoked using `super` and the [Name]s that are dispatched on `this`.
  ///
  /// Names that are dispatched as a setter are preceded by the
  /// [_setterSentinel] object, to distinguish them from getter/call names.
  final Map<Member, List<Node>> _usedMembers = <Member, List<Node>>{};

  /// The level to which a class must be retained after tree shaking.
  ///
  /// See [ClassRetention].
  final List<ClassRetention> _classRetention;

  /// Interleaved (host class, member) pairs that are reachable but have not yet
  /// been analyzed for more uses.
  final List<TreeNode> _worklist = new List<TreeNode>();

  /// Classes whose interface can be used by external code to invoke user code.
  final Set<Class> _escapedClasses = new Set<Class>();

  /// AST visitor for finding static uses and dynamic dispatches in code.
  _TreeShakerVisitor _visitor;

  /// AST visitor for analyzing type annotations on external members.
  _ExternalTypeVisitor _covariantVisitor;
  _ExternalTypeVisitor _contravariantVisitor;
  _ExternalTypeVisitor _bivariantVisitor;

  TreeShaker(Program program, {ClassHierarchy hierarchy, CoreTypes coreTypes})
      : this._internal(program, hierarchy ?? new ClassHierarchy(program),
            coreTypes ?? new CoreTypes(program));

  bool isMemberUsed(Member member) {
    return _usedMembers.containsKey(member);
  }

  bool isInstantiated(Class classNode) {
    return getClassRetention(classNode).index >= ClassRetention.Instance.index;
  }

  bool isHierarchyUsed(Class classNode) {
    return getClassRetention(classNode).index >= ClassRetention.Hierarchy.index;
  }

  ClassRetention getClassRetention(Class classNode) {
    int index = hierarchy.getClassIndex(classNode);
    return _classRetention[index];
  }

  /// Applies the tree shaking results to the program.
  ///
  /// This removes unused classes, members, and hierarchy data.
  void transform(Program program) {
    new _TreeShakingTransformer(this).transform(program);
  }

  TreeShaker._internal(this.program, ClassHierarchy hierarchy, this.coreTypes)
      : this.hierarchy = hierarchy,
        this._usedMembersWithHost =
            new List<Set<Member>>(hierarchy.classes.length),
        this._classRetention = new List<ClassRetention>.filled(
            hierarchy.classes.length, ClassRetention.None) {
    _visitor = new _TreeShakerVisitor(this);
    _covariantVisitor = new _ExternalTypeVisitor(this, isCovariant: true);
    _contravariantVisitor =
        new _ExternalTypeVisitor(this, isContravariant: true);
    _bivariantVisitor = new _ExternalTypeVisitor(this,
        isCovariant: true, isContravariant: true);
    _build();
  }

  void _build() {
    if (program.mainMethod == null) {
      throw 'Cannot perform tree shaking on a program without a main method';
    }
    if (program.mainMethod.function.positionalParameters.length > 0) {
      // The main method takes a List<String> as argument.
      _addInstantiatedExternalSubclass(coreTypes.listClass);
      _addInstantiatedExternalSubclass(coreTypes.stringClass);
    }
    _addDispatchedName(new Name('noSuchMethod'));
    _addPervasiveUses();
    _addUsedMember(null, program.mainMethod);
    _iterateWorklist();
  }

  /// Registers some extremely commonly used core classes as instantiated, so
  /// we don't have to register them for every use we find.
  void _addPervasiveUses() {
    _addInstantiatedExternalSubclass(coreTypes.stringClass);
    _addInstantiatedExternalSubclass(coreTypes.intClass);
    _addInstantiatedExternalSubclass(coreTypes.boolClass);
    _addInstantiatedExternalSubclass(coreTypes.nullClass);
  }

  /// Registers the given name as seen in a dynamic dispatch, and discovers used
  /// instance members accordingly.
  void _addDispatchedName(Name name) {
    // TODO(asgerf): make use of selector arity and getter/setter kind
    if (_dispatchedNames.add(name)) {
      List<TreeNode> targets = _dispatchTargetCandidates[name];
      if (targets != null) {
        for (int i = 0; i < targets.length; i += 2) {
          _addUsedMember(targets[i], targets[i + 1]);
        }
      }
    }
  }

  /// Registers the given method as a potential target of dynamic dispatch on
  /// the given class.
  void _addDispatchTarget(Class host, Member member) {
    if (_dispatchedNames.contains(member.name)) {
      _addUsedMember(host, member);
    } else {
      _dispatchTargetCandidates.putIfAbsent(member.name, _makeTreeNodeList)
        ..add(host)
        ..add(member);
    }
  }

  static List<TreeNode> _makeTreeNodeList() => <TreeNode>[];

  /// Registers the given class as instantiated and discovers new dispatch
  /// target candidates accordingly.
  void _addInstantiatedClass(Class classNode) {
    int index = hierarchy.getClassIndex(classNode);
    ClassRetention retention = _classRetention[index];
    if (retention.index < ClassRetention.Instance.index) {
      _classRetention[index] = ClassRetention.Instance;
      _propagateClassInstanceLevel(classNode, retention);
    }
  }

  /// Register that an external subclass of the given class may be instantiated.
  void _addInstantiatedExternalSubclass(Class classNode) {
    int index = hierarchy.getClassIndex(classNode);
    ClassRetention retention = _classRetention[index];
    if (retention.index < ClassRetention.ExternalInstance.index) {
      _classRetention[index] = ClassRetention.ExternalInstance;
      _propagateClassExternalInstanceLevel(classNode, retention);
    }
  }

  void _propagateClassExternalInstanceLevel(
      Class classNode, ClassRetention oldRetention) {
    if (oldRetention.index >= ClassRetention.ExternalInstance.index) {
      return;
    }
    _propagateClassInstanceLevel(classNode, oldRetention);
    for (Member member in hierarchy.getInterfaceMembers(classNode)) {
      if (member is Field) {
        _covariantVisitor.visit(member.type);
      } else {
        _addCallToExternalProcedure(member);
      }
    }
  }

  /// Called when the retention level for [classNode] has been raised from
  /// [oldRetention] to instance level.
  ///
  /// Ensures that the relevant members are put in the worklist, and super types
  /// and raised to hierarchy level.
  void _propagateClassInstanceLevel(
      Class classNode, ClassRetention oldRetention) {
    if (oldRetention.index >= ClassRetention.Instance.index) {
      return;
    }
    _propagateClassHierarchyLevel(classNode, oldRetention);
    for (Member member in hierarchy.getDispatchTargets(classNode)) {
      _addDispatchTarget(classNode, member);
    }
    for (Member member
        in hierarchy.getDispatchTargets(classNode, setters: true)) {
      _addDispatchTarget(classNode, member);
    }
    // TODO(asgerf): Shake off unused instance fields.
    // For now, just register them all inherited fields as used to ensure the
    // effects of their initializers are taken into account.  To shake a field,
    // we still need to preserve the side effects of the initializer.
    for (Class node = classNode; node != null; node = node.superclass) {
      for (Field field in node.mixin.fields) {
        if (!field.isStatic) {
          _addUsedMember(classNode, field);
        }
      }
    }
  }

  /// Called when the retention level for [classNode] has been raised from
  /// [oldRetention] to hierarchy level or higher.
  ///
  /// Ensure that all super types and type parameter bounds are also raised
  /// to hierarchy level.
  void _propagateClassHierarchyLevel(
      Class classNode, ClassRetention oldRetention) {
    if (oldRetention.index >= ClassRetention.Hierarchy.index) {
      return;
    }
    _propagateClassNamespaceLevel(classNode, oldRetention);
    var visitor = _visitor;
    classNode.supertype?.accept(visitor);
    classNode.mixedInType?.accept(visitor);
    visitList(classNode.implementedTypes, visitor);
    visitList(classNode.typeParameters, visitor);
  }

  /// Called when the retention level for [classNode] has been raised from
  /// [oldRetention] to namespace level or higher.
  ///
  /// Ensures that all annotations on the class are analyzed.
  void _propagateClassNamespaceLevel(
      Class classNode, ClassRetention oldRetention) {
    if (oldRetention.index >= ClassRetention.Namespace.index) {
      return;
    }
    visitList(classNode.annotations, _visitor);
  }

  /// Registers the given class as being used in a type annotation.
  void _addClassUsedInType(Class classNode) {
    int index = hierarchy.getClassIndex(classNode);
    ClassRetention retention = _classRetention[index];
    if (retention.index < ClassRetention.Hierarchy.index) {
      _classRetention[index] = ClassRetention.Hierarchy;
      _propagateClassHierarchyLevel(classNode, retention);
    }
  }

  /// Registers the given class or library as containing static members.
  void _addStaticNamespace(TreeNode container) {
    assert(container is Class || container is Library);
    if (container is Class) {
      int index = hierarchy.getClassIndex(container);
      var oldRetention = _classRetention[index];
      if (oldRetention == ClassRetention.None) {
        _classRetention[index] = ClassRetention.Namespace;
        _propagateClassNamespaceLevel(container, oldRetention);
      }
    }
  }

  /// Registers the given member as being used, in the following sense:
  /// - Fields are used if they can be read or written or their initializer is
  ///   evaluated.
  /// - Constructors are used if they can be invoked, either directly or through
  ///   the initializer list of another constructor.
  /// - Procedures are used if they can be invoked or torn off.
  void _addUsedMember(Class host, Member member) {
    if (host != null) {
      // Check if the member has been seen with this host before.
      int index = hierarchy.getClassIndex(host);
      Set<Member> members = _usedMembersWithHost[index] ??= new Set<Member>();
      if (!members.add(member)) return;
      _usedMembers.putIfAbsent(member, _makeIncompleteSummary);
    } else {
      // Check if the member has been seen before.
      if (_usedMembers.containsKey(member)) return;
      _usedMembers[member] = _makeIncompleteSummary();
      if (member is! Constructor) {
        _addStaticNamespace(member.parent);
      }
    }
    _worklist..add(host)..add(member);
    if (member is Procedure && member.isExternal) {
      _addCallToExternalProcedure(member);
    }
  }

  /// Models the impact of a call from user code to an external implementation
  /// of [member] based on its type annotations.
  ///
  /// Types in covariant position are assumed to be instantiated externally,
  /// and types in contravariant position are assumed to have their methods
  /// invoked by the external code.
  void _addCallToExternalProcedure(Procedure member) {
    FunctionNode function = member.function;
    _covariantVisitor.visit(function.returnType);
    for (int i = 0; i < function.positionalParameters.length; ++i) {
      _contravariantVisitor.visit(function.positionalParameters[i].type);
    }
    for (int i = 0; i < function.namedParameters.length; ++i) {
      _contravariantVisitor.visit(function.namedParameters[i].type);
    }
  }

  /// Called when external code may invoke the interface of the given class.
  void _addEscapedClass(Class node) {
    if (!_escapedClasses.add(node)) return;
    for (Member member in hierarchy.getInterfaceMembers(node)) {
      if (member is Procedure) {
        _addDispatchedName(member.name);
      }
    }
  }

  /// Creates a incomplete summary object, indicating that a member has not
  /// yet been analyzed.
  static List<Node> _makeIncompleteSummary() => <Node>[null];

  bool isIncompleteSummary(List<Node> summary) {
    return summary.isNotEmpty && summary[0] == null;
  }

  void _iterateWorklist() {
    while (_worklist.isNotEmpty) {
      // Get the host and member.
      Member member = _worklist.removeLast();
      Class host = _worklist.removeLast();

      // Analyze the method body if we have not done so before.
      List<Node> summary = _usedMembers[member];
      if (isIncompleteSummary(summary)) {
        summary.clear();
        _visitor.analyzeAndBuildSummary(member, summary);
      }

      // Apply the summary in the context of this host.
      for (int i = 0; i < summary.length; ++i) {
        Node summaryNode = summary[i];
        if (summaryNode is Member) {
          _addUsedMember(host, summaryNode);
        } else if (summaryNode is Name) {
          Member target = hierarchy.getDispatchTarget(host, summaryNode);
          if (target != null) {
            _addUsedMember(host, target);
          }
        } else if (identical(summaryNode, _setterSentinel)) {
          Name name = summary[++i];
          Member target = hierarchy.getDispatchTarget(host, name, setter: true);
          if (target != null) {
            _addUsedMember(host, target);
          }
        } else {
          throw 'Unexpected summary node: $summaryNode';
        }
      }
    }
  }

  String getDiagnosticString() {
    return """
dispatchNames: ${_dispatchedNames.length}
dispatchTargetCandidates.keys: ${_dispatchTargetCandidates.length}
usedMembersWithHost: ${_usedMembersWithHost.length}
usedMembers: ${_usedMembers.length}
classRetention: ${_classRetention.length}
escapedClasses: ${_escapedClasses.length}
""";
  }
}

/// Sentinel that occurs in method summaries in front of each name that should
/// be interpreted as a setter.
final Node _setterSentinel = const InvalidType();

/// Searches the AST for static references and dynamically dispatched names.
class _TreeShakerVisitor extends RecursiveVisitor {
  final TreeShaker shaker;
  final CoreTypes coreTypes;
  List<Node> summary;

  _TreeShakerVisitor(TreeShaker shaker)
      : this.shaker = shaker,
        this.coreTypes = shaker.coreTypes;

  void analyzeAndBuildSummary(Node node, List<Node> summary) {
    this.summary = summary;
    node.accept(this);
  }

  @override
  visitFunctionNode(FunctionNode node) {
    switch (node.asyncMarker) {
      case AsyncMarker.Sync:
        break;
      case AsyncMarker.SyncStar:
        shaker._addInstantiatedExternalSubclass(coreTypes.iterableClass);
        break;
      case AsyncMarker.Async:
        shaker._addInstantiatedExternalSubclass(coreTypes.futureClass);
        break;
      case AsyncMarker.AsyncStar:
        shaker._addInstantiatedExternalSubclass(coreTypes.streamClass);
        break;
      case AsyncMarker.SyncYielding:
        break;
    }
    node.visitChildren(this);
  }

  void addUseFrom(Member target, Class from) {
    shaker._addUsedMember(from, target);
  }

  void addUseFromCurrentHost(Member target) {
    summary.add(target);
  }

  void addStaticUse(Member target) {
    shaker._addUsedMember(null, target);
  }

  void addSelfDispatch(Name name, {bool setter: false}) {
    if (setter) {
      summary..add(_setterSentinel)..add(name);
    } else {
      summary.add(name);
    }
  }

  @override
  visitSuperInitializer(SuperInitializer node) {
    addUseFromCurrentHost(node.target);
    node.visitChildren(this);
  }

  @override
  visitRedirectingInitializer(RedirectingInitializer node) {
    addUseFromCurrentHost(node.target);
    node.visitChildren(this);
  }

  @override
  visitConstructorInvocation(ConstructorInvocation node) {
    shaker._addInstantiatedClass(node.target.enclosingClass);
    addUseFrom(node.target, node.target.enclosingClass);
    node.visitChildren(this);
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    addStaticUse(node.target);
    node.visitChildren(this);
  }

  @override
  visitDirectMethodInvocation(DirectMethodInvocation node) {
    if (node.receiver is! ThisExpression) {
      // TODO(asgerf): Support arbitrary direct calls.
      throw 'Direct calls are only supported on "this"';
    }
    addUseFromCurrentHost(node.target);
    node.visitChildren(this);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    if (node.receiver is ThisExpression) {
      addSelfDispatch(node.name);
    } else {
      shaker._addDispatchedName(node.name);
    }
    node.visitChildren(this);
  }

  @override
  visitStaticGet(StaticGet node) {
    addStaticUse(node.target);
    node.visitChildren(this);
  }

  @override
  visitStaticSet(StaticSet node) {
    addStaticUse(node.target);
    node.visitChildren(this);
  }

  @override
  visitDirectPropertyGet(DirectPropertyGet node) {
    if (node.receiver is! ThisExpression) {
      // TODO(asgerf): Support arbitrary direct calls.
      throw 'Direct calls are only supported on "this"';
    }
    addUseFromCurrentHost(node.target);
    node.visitChildren(this);
  }

  @override
  visitDirectPropertySet(DirectPropertySet node) {
    if (node.receiver is! ThisExpression) {
      // TODO(asgerf): Support arbitrary direct calls.
      throw 'Direct calls are only supported on "this"';
    }
    addUseFromCurrentHost(node.target);
    node.visitChildren(this);
  }

  @override
  visitPropertyGet(PropertyGet node) {
    if (node.receiver is ThisExpression) {
      addSelfDispatch(node.name);
    } else {
      shaker._addDispatchedName(node.name);
    }
    node.visitChildren(this);
  }

  @override
  visitPropertySet(PropertySet node) {
    if (node.receiver is ThisExpression) {
      addSelfDispatch(node.name, setter: true);
    } else {
      shaker._addDispatchedName(node.name);
    }
    node.visitChildren(this);
  }

  @override
  visitListLiteral(ListLiteral node) {
    shaker._addInstantiatedExternalSubclass(coreTypes.listClass);
    node.visitChildren(this);
  }

  @override
  visitMapLiteral(MapLiteral node) {
    shaker._addInstantiatedExternalSubclass(coreTypes.mapClass);
    node.visitChildren(this);
  }

  static final Name _toStringName = new Name('toString');

  @override
  visitStringConcatenation(StringConcatenation node) {
    shaker._addDispatchedName(_toStringName);
    node.visitChildren(this);
  }

  @override
  visitInterfaceType(InterfaceType node) {
    shaker._addClassUsedInType(node.classNode);
    node.visitChildren(this);
  }

  @override
  visitDoubleLiteral(DoubleLiteral node) {
    shaker._addInstantiatedExternalSubclass(coreTypes.doubleClass);
  }

  @override
  visitSymbolLiteral(SymbolLiteral node) {
    shaker._addInstantiatedExternalSubclass(coreTypes.symbolClass);
    // Note: we do not support 'dart:mirrors' right now, so nothing else needs
    // to be done for symbols.
  }

  @override
  visitTypeLiteral(TypeLiteral node) {
    shaker._addInstantiatedExternalSubclass(coreTypes.typeClass);
    node.visitChildren(this);
  }
}

/// The degree to which a class is needed in a program.
///
/// Each level implies those before it.
enum ClassRetention {
  /// The class can be removed.
  None,

  /// The class contains used static members but is otherwise unused.
  Namespace,

  /// The class is used in a type or has an instantiated subtype, or for some
  /// other reason must have its hierarchy information preserved.
  Hierarchy,

  /// The class is instantiated.
  Instance,

  /// The class has an instantiated external subclass.
  ExternalInstance,
}

/// Removes classes and members that are not needed.
///
/// There must not be any dangling references in the program afterwards.
class _TreeShakingTransformer extends Transformer {
  final TreeShaker shaker;

  _TreeShakingTransformer(this.shaker);

  void transform(Program program) {
    for (var library in program.libraries) {
      if (library.importUri.scheme == 'dart') {
        // As long as patching happens in the backend, we cannot shake off
        // anything in the core libraries.
        continue;
      }
      library.transformChildren(this);
      // Note: we can't shake off empty libraries yet since we don't check if
      // there are private names that use the library.
    }
  }

  Class visitClass(Class node) {
    switch (shaker.getClassRetention(node)) {
      case ClassRetention.None:
        return null; // Remove the class.

      case ClassRetention.Namespace:
        // The class is only a namespace for static members.  Remove its
        // hierarchy information.   This is mandatory, since these references
        // might otherwise become dangling.
        node.supertype = shaker.coreTypes.objectClass.asRawSupertype;
        node.implementedTypes.clear();
        node.typeParameters.clear();
        // Mixin applications cannot have static members.
        assert(node.mixedInType == null);
        // Unused members will be removed below.
        break;

      case ClassRetention.Hierarchy:
      case ClassRetention.Instance:
      case ClassRetention.ExternalInstance:
        break;
    }
    node.transformChildren(this);
    if (node.constructors.isEmpty && node.procedures.isEmpty) {
      // The VM does not like classes without any members, so ensure there is
      // always a constructor left.
      node.addMember(new Constructor(new FunctionNode(new EmptyStatement())));
    }
    return node;
  }

  Member defaultMember(Member node) {
    if (!shaker.isMemberUsed(node)) {
      return null; // Remove unused member.
    }
    return node;
  }

  TreeNode defaultTreeNode(TreeNode node) {
    return node; // Do not traverse into other nodes.
  }
}

class _ExternalTypeVisitor extends DartTypeVisitor {
  final TreeShaker shaker;
  final bool isCovariant;
  final bool isContravariant;
  ClassHierarchy get hierarchy => shaker.hierarchy;

  _ExternalTypeVisitor(this.shaker,
      {this.isCovariant: false, this.isContravariant: false});

  void visit(DartType type) => type?.accept(this);

  /// Analyze [type] with the opposite variance.
  void visitContravariant(DartType type) {
    if (isCovariant && isContravariant) {
      type?.accept(this);
    } else if (isContravariant) {
      type?.accept(shaker._covariantVisitor);
    } else {
      type?.accept(shaker._contravariantVisitor);
    }
  }

  visitCovariant(DartType type) => type?.accept(this);

  visitBivariant(DartType type) => shaker._bivariantVisitor.visit(type);

  visitInvalidType(InvalidType node) {}

  visitDynamicType(DynamicType node) {
    // TODO(asgerf): Find a suitable model for untyped externals, e.g. track
    // them to the first type boundary.
  }

  visitVoidType(VoidType node) {}

  visitInterfaceType(InterfaceType node) {
    if (isCovariant) {
      shaker._addInstantiatedExternalSubclass(node.classNode);
    }
    if (isContravariant) {
      shaker._addEscapedClass(node.classNode);
    }
    for (int i = 0; i < node.typeArguments.length; ++i) {
      DartType typeArgument = node.typeArguments[i];
      // In practice we don't get much out of analyzing variance here, so
      // just use a whitelist of classes that can be seen as covariant
      // for external purposes.
      // TODO(asgerf): Variance analysis might pay off for other external APIs.
      if (isWhitelistedCovariant(node.classNode)) {
        visitCovariant(typeArgument);
      } else {
        visitBivariant(typeArgument);
      }
    }
  }

  visitFunctionType(FunctionType node) {
    visit(node.returnType);
    for (int i = 0; i < node.positionalParameters.length; ++i) {
      visitContravariant(node.positionalParameters[i]);
    }
    for (int i = 0; i < node.namedParameters.length; ++i) {
      visitContravariant(node.namedParameters[i].type);
    }
  }

  visitTypeParameterType(TypeParameterType node) {}

  /// Just treat a couple of whitelisted classes as having covariant type
  /// parameters.
  bool isWhitelistedCovariant(Class classNode) {
    if (classNode.typeParameters.isEmpty) return false;
    CoreTypes coreTypes = shaker.coreTypes;
    return classNode == coreTypes.iteratorClass ||
        classNode == coreTypes.iterableClass ||
        classNode == coreTypes.futureClass ||
        classNode == coreTypes.streamClass ||
        classNode == coreTypes.listClass ||
        classNode == coreTypes.mapClass;
  }
}
