// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.tree_shaker;

import '../ast.dart';
import '../class_hierarchy.dart';
import '../core_types.dart';
import '../type_environment.dart';
import '../library_index.dart';

Program transformProgram(
    CoreTypes coreTypes, ClassHierarchy hierarchy, Program program,
    {List<ProgramRoot> programRoots}) {
  new TreeShaker(coreTypes, hierarchy, program, programRoots: programRoots)
      .transform(program);
  return program;
}

enum ProgramRootKind {
  /// The root is a class which will be instantiated by
  /// external / non-Dart code.
  ExternallyInstantiatedClass,

  /// The root is a setter function or a field.
  Setter,

  /// The root is a getter function or a field.
  Getter,

  /// The root is some kind of constructor.
  Constructor,

  /// The root is a field, normal procedure or constructor.
  Other,
}

/// A program root which the vm or embedder uses and needs to be retained.
class ProgramRoot {
  /// The library the root is contained in.
  final String library;

  /// The name of the class inside the library (optional).
  final String klass;

  /// The name of the member inside the library (or class, optional).
  final String member;

  /// The kind of this program root.
  final ProgramRootKind kind;

  ProgramRoot(this.library, this.klass, this.member, this.kind);

  String toString() => "ProgramRoot($library, $klass, $member, $kind)";

  String get disambiguatedName {
    if (kind == ProgramRootKind.Getter) return 'get:$member';
    if (kind == ProgramRootKind.Setter) return 'set:$member';
    return member;
  }

  Member getMember(LibraryIndex table) {
    assert(klass != null);
    assert(member != null);
    return table.getMember(
        library, klass ?? LibraryIndex.topLevel, disambiguatedName);
  }

  Class getClass(LibraryIndex table) {
    assert(klass != null);
    return table.getClass(library, klass);
  }
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
/// If the `dart:mirrors` library is used then nothing will be tree-shaken.
//
// TODO(asgerf): Tree shake unused instance fields.
class TreeShaker {
  final CoreTypes coreTypes;
  final ClosedWorldClassHierarchy hierarchy;
  final Program program;
  final bool strongMode;
  final List<ProgramRoot> programRoots;

  /// Map from classes to set of names that have been dispatched with that class
  /// as the static receiver type (meaning any subtype of that class can be
  /// the potential concrete receiver).
  ///
  /// The map is implemented as a list, indexed by
  /// [ClassHierarchy.getClassIndex].
  final List<Set<Name>> _dispatchedNames;

  /// Map from names to the set of classes that might be the concrete receiver
  /// of a call with the given name.
  final Map<Name, ClassSet> _receiversOfName = <Name, ClassSet>{};

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
  /// The summary object is a heterogeneous list containing the [Member]s that
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

  /// Members that have been overridden by a member whose concrete body is
  /// needed.  These must be preserved in order to maintain interface targets
  /// for typed calls.
  final Set<Member> _overriddenMembers = new Set<Member>();

  final List<Expression> _typedCalls = <Expression>[];

  /// AST visitor for finding static uses and dynamic dispatches in code.
  _TreeShakerVisitor _visitor;

  /// AST visitor for analyzing type annotations on external members.
  _ExternalTypeVisitor _covariantVisitor;
  _ExternalTypeVisitor _contravariantVisitor;
  _ExternalTypeVisitor _invariantVisitor;

  Library _mirrorsLibrary;

  /// Set to true if any use of the `dart:mirrors` API is found.
  bool isUsingMirrors = false;

  /// If we have roots, we will shake, even if we encounter some elements from
  /// the mirrors library.
  bool get forceShaking => programRoots != null && programRoots.isNotEmpty;

  TreeShaker(CoreTypes coreTypes, ClassHierarchy hierarchy, Program program,
      {bool strongMode: false, List<ProgramRoot> programRoots})
      : this._internal(coreTypes, hierarchy, program, strongMode, programRoots);

  bool isMemberBodyUsed(Member member) {
    return _usedMembers.containsKey(member);
  }

  bool isMemberOverridden(Member member) {
    return _overriddenMembers.contains(member);
  }

  bool isMemberUsed(Member member) {
    return isMemberBodyUsed(member) || isMemberOverridden(member);
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
    if (isUsingMirrors) return; // Give up if using mirrors.
    new _TreeShakingTransformer(this).transform(program);
  }

  TreeShaker._internal(this.coreTypes, this.hierarchy, this.program,
      this.strongMode, this.programRoots)
      : this._dispatchedNames = new List<Set<Name>>(hierarchy.classes.length),
        this._usedMembersWithHost =
            new List<Set<Member>>(hierarchy.classes.length),
        this._classRetention = new List<ClassRetention>.filled(
            hierarchy.classes.length, ClassRetention.None) {
    _visitor = new _TreeShakerVisitor(this);
    _covariantVisitor = new _ExternalTypeVisitor(this, isCovariant: true);
    _contravariantVisitor =
        new _ExternalTypeVisitor(this, isContravariant: true);
    _invariantVisitor = new _ExternalTypeVisitor(this,
        isCovariant: true, isContravariant: true);
    _mirrorsLibrary = coreTypes.mirrorsLibrary;
    try {
      _build();
    } on _UsingMirrorsException {
      isUsingMirrors = true;
    }
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
    _addDispatchedName(coreTypes.objectClass, new Name('noSuchMethod'));
    _addPervasiveUses();
    _addUsedMember(null, program.mainMethod);
    if (programRoots != null) {
      var table = new LibraryIndex(program, programRoots.map((r) => r.library));
      for (var root in programRoots) {
        _addUsedRoot(root, table);
      }
    }

    _iterateWorklist();

    // Mark overridden members in order to preserve abstract members as
    // necessary.
    if (strongMode) {
      for (int i = hierarchy.classes.length - 1; i >= 0; --i) {
        Class class_ = hierarchy.classes[i];
        if (isHierarchyUsed(class_)) {
          hierarchy.forEachOverridePair(class_,
              (Member ownMember, Member superMember, bool isSetter) {
            if (isMemberBodyUsed(ownMember) ||
                _overriddenMembers.contains(ownMember)) {
              _overriddenMembers.add(superMember);
              // Ensure the types mentioned in the member can be preserved.
              _visitor.visitMemberInterface(superMember);
            }
          });
        }
      }
      // Marking members as overridden should not cause new code to become
      // reachable.
      assert(_worklist.isEmpty);
    }
  }

  /// Registers some extremely commonly used core classes as instantiated, so
  /// we don't have to register them for every use we find.
  void _addPervasiveUses() {
    _addInstantiatedExternalSubclass(coreTypes.stringClass);
    _addInstantiatedExternalSubclass(coreTypes.intClass);
    _addInstantiatedExternalSubclass(coreTypes.boolClass);
    _addInstantiatedExternalSubclass(coreTypes.nullClass);
    _addInstantiatedExternalSubclass(coreTypes.functionClass);
    _addInstantiatedExternalSubclass(coreTypes.invocationClass);
  }

  /// Registers the given name as seen in a dynamic dispatch, and discovers used
  /// instance members accordingly.
  void _addDispatchedName(Class receiver, Name name) {
    int index = hierarchy.getClassIndex(receiver);
    Set<Name> receiverNames = _dispatchedNames[index] ??= new Set<Name>();
    // TODO(asgerf): make use of selector arity and getter/setter kind
    if (receiverNames.add(name)) {
      List<TreeNode> candidates = _dispatchTargetCandidates[name];
      if (candidates != null) {
        for (int i = 0; i < candidates.length; i += 2) {
          Class host = candidates[i];
          if (hierarchy.isSubtypeOf(host, receiver)) {
            // This (host, member) pair is a potential target of the dispatch.
            Member member = candidates[i + 1];

            // Remove the (host,member) pair from the candidate list.
            // Move the last pair into the current index and shrink the list.
            int lastPair = candidates.length - 2;
            candidates[i] = candidates[lastPair];
            candidates[i + 1] = candidates[lastPair + 1];
            candidates.length -= 2;
            i -= 2; // Revisit the same index now that it has been updated.

            // Mark the pair as used.  This should be done after removing it
            // from the candidate list, since this call may recursively scan
            // for more used members.
            _addUsedMember(host, member);
          }
        }
      }
      var subtypes = hierarchy.getSubtypesOf(receiver);
      var receiverSet = _receiversOfName[name];
      _receiversOfName[name] = receiverSet == null
          ? subtypes
          : _receiversOfName[name].union(subtypes);
    }
  }

  /// Registers the given method as a potential target of dynamic dispatch on
  /// the given class.
  void _addDispatchTarget(Class host, Member member) {
    ClassSet receivers = _receiversOfName[member.name];
    if (receivers != null && receivers.contains(host)) {
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
      _addDispatchTarget(classNode, member);
    }
    for (Member member
        in hierarchy.getInterfaceMembers(classNode, setters: true)) {
      _addDispatchTarget(classNode, member);
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

  /// Registers the given root as being used.
  void _addUsedRoot(ProgramRoot root, LibraryIndex table) {
    if (root.kind == ProgramRootKind.ExternallyInstantiatedClass) {
      Class class_ = root.getClass(table);

      // This is a class which will be instantiated by non-Dart code (whether it
      // has a valid generative constructor or not).
      _addInstantiatedClass(class_);

      // We keep all the constructors of externally instantiated classes.
      // Sometimes the runtime might do a constructor call and sometimes it
      // might just allocate the class without invoking the constructor.
      // So we try to be on the safe side here!
      for (var constructor in class_.constructors) {
        _addUsedMember(class_, constructor);
      }

      // We keep all factory constructors as well for the same reason.
      for (var member in class_.procedures) {
        if (member.isStatic && member.kind == ProcedureKind.Factory) {
          _addUsedMember(class_, member);
        }
      }
    } else {
      var member = root.getMember(table);
      _addUsedMember(member.enclosingClass, member);
      if (member is Constructor) {
        _addInstantiatedClass(member.enclosingClass);
      }
    }
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
    if (!forceShaking && member.enclosingLibrary == _mirrorsLibrary) {
      throw new _UsingMirrorsException();
    }
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
        _addDispatchedName(node, member.name);
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
  final TypeEnvironment types;
  final bool strongMode;
  List<Node> summary;

  _TreeShakerVisitor(TreeShaker shaker)
      : this.shaker = shaker,
        this.coreTypes = shaker.coreTypes,
        this.strongMode = shaker.strongMode,
        this.types = new TypeEnvironment(shaker.coreTypes, shaker.hierarchy) {
    types.errorHandler = handleError;
  }

  void handleError(TreeNode node, String message) {
    print('[error] $message (${node.location})');
  }

  void analyzeAndBuildSummary(Member member, List<Node> summary) {
    this.summary = summary;
    types.thisType = member.enclosingClass?.thisType;
    member.accept(this);
  }

  void visitMemberInterface(Member node) {
    if (node is Field) {
      node.type.accept(this);
    } else if (node is Procedure) {
      visitFunctionInterface(node.function);
    }
  }

  visitFunctionInterface(FunctionNode node) {
    for (var parameter in node.typeParameters) {
      parameter.bound.accept(this);
    }
    for (var parameter in node.positionalParameters) {
      parameter.type.accept(this);
    }
    for (var parameter in node.namedParameters) {
      parameter.type.accept(this);
    }
    node.returnType.accept(this);
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

  Class getKnownSupertype(DartType type) {
    if (type is InterfaceType) {
      return type.classNode;
    } else if (type is TypeParameterType) {
      return getKnownSupertype(type.parameter.bound);
    } else if (type is FunctionType) {
      return coreTypes.functionClass;
    } else if (type is BottomType) {
      return coreTypes.nullClass;
    } else {
      return coreTypes.objectClass;
    }
  }

  Class getStaticType(Expression node) {
    if (!strongMode) return coreTypes.objectClass;
    return getKnownSupertype(node.getStaticType(types));
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    if (node.receiver is ThisExpression) {
      addSelfDispatch(node.name);
    } else {
      shaker._addDispatchedName(getStaticType(node.receiver), node.name);
      if (node.interfaceTarget != null) {
        shaker._typedCalls.add(node);
      }
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
      shaker._addDispatchedName(getStaticType(node.receiver), node.name);
      if (node.interfaceTarget != null) {
        shaker._typedCalls.add(node);
      }
    }
    node.visitChildren(this);
  }

  @override
  visitPropertySet(PropertySet node) {
    if (node.receiver is ThisExpression) {
      addSelfDispatch(node.name, setter: true);
    } else {
      shaker._addDispatchedName(getStaticType(node.receiver), node.name);
      if (node.interfaceTarget != null) {
        shaker._typedCalls.add(node);
      }
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
    for (var expression in node.expressions) {
      shaker._addDispatchedName(getStaticType(expression), _toStringName);
    }
    node.visitChildren(this);
  }

  @override
  visitInterfaceType(InterfaceType node) {
    shaker._addClassUsedInType(node.classNode);
    node.visitChildren(this);
  }

  @override
  visitSupertype(Supertype node) {
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

  Member _translateInterfaceTarget(Member target) {
    return target != null && shaker.isMemberUsed(target) ? target : null;
  }

  void transform(Program program) {
    for (Expression node in shaker._typedCalls) {
      // We should not leave dangling references, so if the target of a typed
      // call has been removed, we must remove the reference.  The receiver of
      // such a call can only be null.
      // TODO(asgerf): Rewrite to a NSM call instead of adding dynamic calls.
      if (node is MethodInvocation) {
        node.interfaceTarget = _translateInterfaceTarget(node.interfaceTarget);
      } else if (node is PropertyGet) {
        node.interfaceTarget = _translateInterfaceTarget(node.interfaceTarget);
      } else if (node is PropertySet) {
        node.interfaceTarget = _translateInterfaceTarget(node.interfaceTarget);
      }
    }
    for (var library in program.libraries) {
      if (!shaker.forceShaking && library.importUri.scheme == 'dart') {
        // The backend expects certain things to be present in the core
        // libraries, so we currently don't shake off anything there.
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
        node.canonicalName?.unbind();
        return null; // Remove the class.

      case ClassRetention.Namespace:
        // The class is only a namespace for static members.  Remove its
        // hierarchy information.   This is mandatory, since these references
        // might otherwise become dangling.
        node.supertype = shaker.coreTypes.objectClass.asRawSupertype;
        node.implementedTypes.clear();
        node.typeParameters.clear();
        node.isAbstract = true;
        // Mixin applications cannot have static members.
        assert(node.mixedInType == null);
        // Unused members will be removed below.
        break;

      case ClassRetention.Hierarchy:
        node.isAbstract = true;
        break;

      case ClassRetention.Instance:
      case ClassRetention.ExternalInstance:
        break;
    }
    node.transformChildren(this);
    return node;
  }

  Member defaultMember(Member node) {
    if (!shaker.isMemberBodyUsed(node)) {
      if (!shaker.isMemberOverridden(node)) {
        node.canonicalName?.unbind();
        return null;
      }
      if (node is Procedure) {
        // Remove body of unused member.
        if (node.enclosingClass.isAbstract) {
          node.isAbstract = true;
          node.function.body = null;
        } else {
          // If the enclosing class is not abstract, the method should still
          // have a body even if it can never be called.
          if (node.function.body != null) {
            node.function.body = new ExpressionStatement(
                new Throw(new StringLiteral('Method removed by tree-shaking')))
              ..parent = node.function;
          }
        }
        node.function.asyncMarker = AsyncMarker.Sync;
      } else if (node is Field) {
        node.initializer = null;
      }
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

  visitInvariant(DartType type) => shaker._invariantVisitor.visit(type);

  visitInvalidType(InvalidType node) {}

  visitDynamicType(DynamicType node) {
    // TODO(asgerf): Find a suitable model for untyped externals, e.g. track
    // them to the first type boundary.
  }

  visitVoidType(VoidType node) {}

  visitVectorType(VectorType node) {}

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
        visitInvariant(typeArgument);
      }
    }
  }

  visitTypedefType(TypedefType node) {
    throw 'TypedefType is not implemented in tree shaker';
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

/// Exception that is thrown to stop the tree shaking analysis when a use
/// of `dart:mirrors` is found.
class _UsingMirrorsException {}
