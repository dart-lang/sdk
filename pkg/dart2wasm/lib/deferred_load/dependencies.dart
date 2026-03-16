// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/library_index.dart';
import 'package:vm/metadata/procedure_attributes.dart';

import '../modules.dart';
import 'devirtualization_oracle.dart';

class DependenciesCollector {
  final CoreTypes _coreTypes;
  final ClosedWorldClassHierarchy _classHierarchy;
  final DevirtualizionOracle _devirtualizionOracle;
  final DeferredModuleLoadingMap _loadingMap;
  final bool _assertsEnabled;

  final Map<TreeNode, ProcedureAttributesMetadata> procedureAttributeMetadata;

  late final _checkLibraryIsLoadedFromLoadId = _coreTypes.index.getProcedure(
      'dart:_internal',
      LibraryIndex.topLevel,
      'checkLibraryIsLoadedFromLoadId');

  late final _loadLibraryFromLoadId = _coreTypes.index.getProcedure(
      'dart:_internal', LibraryIndex.topLevel, 'loadLibraryFromLoadId');

  late final _exportWasmFunction = _coreTypes.index
      .getTopLevelMember('dart:_internal', 'exportWasmFunction');

  DependenciesCollector(
      this.procedureAttributeMetadata,
      this._coreTypes,
      this._classHierarchy,
      this._devirtualizionOracle,
      this._loadingMap,
      this._assertsEnabled);

  /// Returns the set of constants referred to by the (possibly composed)
  /// [constant].
  DirectConstantDependencies directConstantDependencies(Constant constant) {
    Reference? extraReference;
    if (constant is InstanceConstant) {
      extraReference = constant.classReference;
    } else if (constant is TearOffConstant) {
      extraReference = constant.targetReference;
    } else {
      // The classes needed for  {List,Map,Set,Record}Constants are
      // marked as @pragma('wasm:entry-point') and do not have to be explicitly
      // modeled as dependencies (they land in the root unit).
    }

    final children = <Constant>{};
    constant.visitChildren(_ConstantDependenciesCollector._(children));
    return DirectConstantDependencies(children, extraReference);
  }

  DirectReferenceDependencies directReferenceDependencies(Reference reference) {
    final TreeNode node = reference.node!;

    final deps = DirectReferenceDependencies();
    if (node is Class) {
      _enqueueInstanceMembers(node, deps);
      return deps;
    }

    final collector = _ReferenceDependenciesCollector._(
        procedureAttributeMetadata,
        _recognizeDeferredLoadingGuard,
        _disableAllGuards,
        _classHierarchy,
        _devirtualizionOracle,
        _assertsEnabled,
        reference,
        deps);

    // We collect dependencies of [node] and therefore only have to visit
    // AST elements that represent code (such as `FunctionNode`, `Initializer`).
    if (node is Procedure) {
      node.function.accept(collector);
      return deps;
    }
    if (node is Constructor) {
      node.function.accept(collector);
      for (final init in node.initializers) {
        init.accept(collector);
      }
      for (final field in node.enclosingClass.fields) {
        if (field.isInstanceMember) {
          field.initializer?.accept(collector);
        }
      }
      collector.addReference(node.enclosingClass.reference);
      return deps;
    }
    if (node is Field) {
      if (node.isInstanceMember) {
        // Instance field getters/setters have no dependencies: The field
        // initializers are initialized at constructor invocation time not at
        // field access time. The field itself doesn't have a storage location
        // (like a static field).
        assert(node.getterReference == reference ||
            node.hasSetter && node.setterReference == reference);
      } else {
        if (node.getterReference == reference) {
          // A static getter may invoke the initializer and accesses the storage
          // location of the field.
          collector.addReference(node.fieldReference);
          node.initializer?.accept(collector);
        } else if (node.setterReference == reference) {
          // A static setter only accesses the storage location of the field.
          collector.addReference(node.fieldReference);
        } else {
          assert(node.fieldReference == reference);
          // The field storage itself has no dependencies.
        }
      }
      return deps;
    }
    throw UnsupportedError('Unexpected reference: $reference');
  }

  LibraryDependency? _recognizeDeferredLoadingGuard(StaticInvocation node) {
    final target = node.target;
    if (target == _checkLibraryIsLoadedFromLoadId ||
        target == _loadLibraryFromLoadId) {
      final args = node.arguments.positional;
      final loadId = (args[0] as IntLiteral).value;
      return _loadingMap.loadIdToDeferredImport[loadId];
    }
    return null;
  }

  bool _disableAllGuards(StaticInvocation node) {
    return node.target == _exportWasmFunction;
  }

  void _enqueueInstanceMembers(Class klass, DirectReferenceDependencies deps) {
    final superReference = klass.superclass?.reference;
    if (superReference != null) {
      deps.references.add(superReference);
    }
    for (final m in klass.members) {
      if (m.isInstanceMember && !m.isAbstract) {
        if (m is Field) {
          if (!_devirtualizionOracle
              .isAlwaysStaticallyDispatchedTo(m.getterReference)) {
            deps.references.add(m.getterReference);
          }
          if (m.hasSetter) {
            if (!_devirtualizionOracle
                .isAlwaysStaticallyDispatchedTo(m.setterReference!)) {
              deps.references.add(m.setterReference!);
            }
          }
          continue;
        }
        assert(m is Procedure);
        if (!_devirtualizionOracle
            .isAlwaysStaticallyDispatchedTo(m.reference)) {
          deps.references.add(m.reference);
        }
      }
    }
  }
}

class _ConstantDependenciesCollector extends RecursiveVisitor {
  final Set<Constant> _directChildren;
  _ConstantDependenciesCollector._(this._directChildren);

  @override
  void defaultConstantReference(Constant node) {
    _directChildren.add(node);
  }
}

class _ReferenceDependenciesCollector extends RecursiveVisitor {
  late final Map<TreeNode, ProcedureAttributesMetadata>
      _procedureAttributeMetadata;

  final LibraryDependency? Function(StaticInvocation node)
      _recognizeDeferredLoadingGuard;
  final bool Function(StaticInvocation node) _disableAllGuards;
  final DevirtualizionOracle _devirtualizionOracle;
  final ClosedWorldClassHierarchy _classHierarchy;
  final bool _assertsEnabled;

  final Reference reference;
  final DirectReferenceDependencies deps;
  final List<LibraryDependency> _activeLoadGuards = [];

  _ReferenceDependenciesCollector._(
      this._procedureAttributeMetadata,
      this._recognizeDeferredLoadingGuard,
      this._disableAllGuards,
      this._classHierarchy,
      this._devirtualizionOracle,
      this._assertsEnabled,
      this.reference,
      this.deps);

  // ---------------------------------------------------------------------------
  // Ensure all AST nodes are handled - in case future AST nodes are added, they
  // may affect control flow or dependency collection, so we want to know about
  // them by throwing here.
  // ---------------------------------------------------------------------------

  @override
  void defaultExpression(Expression node) => throw UnimplementedError();

  @override
  void defaultStatement(Statement node) => throw UnimplementedError();

  // ---------------------------------------------------------------------------
  // Only node that needs dependency collection & load active load guard
  // handling.
  // ---------------------------------------------------------------------------

  @override
  void visitStaticInvocation(StaticInvocation node) {
    if (_disableAllGuards(node)) {
      // If a function looks like this:
      // ```
      //   void foo() {
      //     ...
      //     D.baz();
      //     ...
      //     _exportWasmFunction(baz);
      //     ...
      //   }
      //
      //   @pragma('wasm:weak-export')
      //   external ... baz(...);
      // ```
      // Then the intrinsifier will recognize `_exportWasmFunction(baz)`
      // specially and export the `baz` function from the same module as
      // `foo`. We therefore do not want `baz` to land in another module.
      final saved = _activeLoadGuards.toList();
      _activeLoadGuards.clear();
      node.visitChildren(this);
      addReference(node.targetReference);
      _activeLoadGuards.addAll(saved);
      return;
    }
    node.visitChildren(this);
    addReference(node.targetReference);
    if (_recognizeDeferredLoadingGuard(node) case var guard?) {
      _activeLoadGuards.add(guard);
    }
  }

  // ---------------------------------------------------------------------------
  // AST Expressions & Statements that have merge points in them which need to
  // save & restore active load guards.
  // ---------------------------------------------------------------------------

  @override
  void visitAssertBlock(AssertBlock node) {
    if (_assertsEnabled) {
      node.visitChildren(this);
      // Either the assert throws (in which case code after the assert is
      // unreachable) or the load guards produced in the assert evaluation still
      // hold.
    }
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    if (_assertsEnabled) {
      node.visitChildren(this);
      // Either the assert throws (in which case code after the assert is
      // unreachable) or the load guards produced in the assert evaluation still
      // hold.
    }
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    final saved = _activeLoadGuards.length;
    node.body.accept(this);
    _activeLoadGuards.length = saved;
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    // We execute the condition at least once.
    node.condition.accept(this);
    final saved = _activeLoadGuards.length;
    node.body.accept(this);
    _activeLoadGuards.length = saved;
  }

  @override
  void visitDoStatement(DoStatement node) {
    // We execute the body & condition at least once.
    //
    // NOTE: If the body contains a `break` it will target a separate
    // [LabeledStatement] which already handles re-setting guards.
    node.body.accept(this);
    node.condition.accept(this);
  }

  @override
  void visitForStatement(ForStatement node) {
    // We initialize the variables always.
    for (final variable in node.variableInitializations) {
      variable.accept(this);
    }
    // We alway execute the condition at least once.
    node.condition?.accept(this);
    final saved = _activeLoadGuards.length;
    node.body.accept(this);
    // If we perform updates then the body must have successfully been
    // executed.
    // (NOTE: break/continue are handled in kernel via lowering to
    // [LabeledStatement]s which will save&restore guards)
    for (final update in node.updates) {
      update.accept(this);
    }
    _activeLoadGuards.length = saved;
  }

  @override
  void visitForInStatement(ForInStatement node) {
    node.iterable.accept(this);

    final saved = _activeLoadGuards.length;
    node.body.accept(this);
    _activeLoadGuards.length = saved;
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    node.expression.accept(this);
    final saved = _activeLoadGuards.length;
    for (final c in node.cases) {
      for (final expression in c.expressions) {
        expression.accept(this);
        _activeLoadGuards.length = saved;
      }
      c.body.accept(this);
      _activeLoadGuards.length = saved;
    }
    assert(_activeLoadGuards.length == saved);
  }

  @override
  void visitIfStatement(IfStatement node) {
    node.condition.accept(this);

    final saved = _activeLoadGuards.length;
    node.then.accept(this);
    _activeLoadGuards.length = saved;
    node.otherwise?.accept(this);
    _activeLoadGuards.length = saved;
  }

  @override
  void visitTryCatch(TryCatch node) {
    final saved = _activeLoadGuards.length;
    node.body.accept(this);
    _activeLoadGuards.length = saved;
    for (final c in node.catches) {
      c.body.accept(this);
      _activeLoadGuards.length = saved;
    }
  }

  @override
  void visitTryFinally(TryFinally node) {
    final saved = _activeLoadGuards.length;
    node.body.accept(this);
    _activeLoadGuards.length = saved;
    node.finalizer.accept(this);
    // NOTE: Finalizer will always be executed and as such any load guard in it
    // will continue to hold after the finally block.
  }

  @override
  void visitLogicalExpression(LogicalExpression node) {
    node.left.accept(this);
    final saved = _activeLoadGuards.length;
    node.right.accept(this);
    _activeLoadGuards.length = saved;
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    node.condition.accept(this);

    final saved = _activeLoadGuards.length;
    node.then.accept(this);
    _activeLoadGuards.length = saved;
    node.otherwise.accept(this);
    _activeLoadGuards.length = saved;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    final saved = _activeLoadGuards.length;
    node.visitChildren(this);
    _activeLoadGuards.length = saved;
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final saved = _activeLoadGuards.length;
    node.visitChildren(this);
    _activeLoadGuards.length = saved;
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    // Unreachable after [node].
  }
  @override
  void visitContinueSwitchStatement(ContinueSwitchStatement node) {
    // Unreachable after [node].
  }
  @override
  void visitRethrow(Rethrow node) {
    // Unreachable after [node].
  }
  @override
  void visitThrow(Throw node) {
    node.expression.accept(this);
    // Unreachable after [node].
  }

  @override
  void visitLoadLibrary(LoadLibrary node) =>
      throw StateError('Should have been lowered by now');

  @override
  void visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) =>
      throw StateError('Should have been lowered by now');

  // ---------------------------------------------------------------------------
  // Expressions that need to collect dependencies, but do not have control flow
  // in them and therefore don't need load guard handling.
  // ---------------------------------------------------------------------------

  @override
  void visitSuperPropertyGet(SuperPropertyGet node) {
    // NOTE: Super calls are direct calls and as such don't need to call
    // [addSelectorUse]/[addDynamicSelectorUse].
    node.visitChildren(this);
    _addSuperTargetReference(node.interfaceTarget, setter: false);
  }

  @override
  void visitSuperPropertySet(SuperPropertySet node) {
    // NOTE: Super calls are direct calls and as such don't need to call
    // [addSelectorUse]/[addDynamicSelectorUse].
    node.visitChildren(this);
    _addSuperTargetReference(node.interfaceTarget, setter: true);
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    // NOTE: Super calls are direct calls and as such don't need to call
    // [addSelectorUse]/[addDynamicSelectorUse].
    node.visitChildren(this);
    _addSuperTargetReference(node.interfaceTarget, setter: false);
  }

  @override
  void visitInstanceGet(InstanceGet node) {
    node.visitChildren(this);
    final target = _devirtualizionOracle.staticDispatchTargetForGet(node);
    if (target != null) {
      addReference(target);
    } else {
      addSelectorUse(node.interfaceTarget, getter: true);
    }
  }

  @override
  void visitInstanceSet(InstanceSet node) {
    node.visitChildren(this);
    final target = _devirtualizionOracle.staticDispatchTargetForSet(node);
    if (target != null) {
      addReference(target);
    } else {
      addSelectorUse(node.interfaceTarget, getter: false);
    }
  }

  @override
  void visitInstanceInvocation(InstanceInvocation node) {
    node.visitChildren(this);
    final target = _devirtualizionOracle.staticDispatchTargetForCall(node);
    if (target != null) {
      addReference(target);
    } else {
      addSelectorUse(node.interfaceTarget, getter: false);
    }
  }

  @override
  void visitInstanceTearOff(InstanceTearOff node) {
    node.visitChildren(this);
    // There's no [Reference] in pure Kernel AST to represent the tear-off of a
    // method (**). So for the purpose of this code that works on pure Kernel
    // AST and collects dependencies, the method and it's tear-off are one
    // entity. We treat it as such by making any use of the method be a use of
    // tear-off as well - and vice versa.
    //
    // (**) The dart2wasm backend code does use multiple [Reference]s to
    // represent the same method, constructor etc - including tear-offs. Though
    // this is in the backend.
    addSelectorUse(node.interfaceTarget, getter: true);
    addSelectorUse(node.interfaceTarget, getter: false);
  }

  @override
  void visitDynamicGet(DynamicGet node) {
    node.visitChildren(this);
    addDynamicSelectorUse(node.name);
  }

  @override
  void visitDynamicSet(DynamicSet node) {
    node.visitChildren(this);
    addDynamicSelectorUse(node.name);
  }

  @override
  void visitDynamicInvocation(DynamicInvocation node) {
    node.visitChildren(this);
    addDynamicSelectorUse(node.name);
  }

  @override
  void visitFunctionInvocation(FunctionInvocation node) {
    // NOTE: [_Closure.call] is marked as `@pragma('wasm:entry-point')` and will
    // therefore be considered a selector use by the root.
    node.visitChildren(this);
  }

  @override
  void visitStaticGet(StaticGet node) {
    node.visitChildren(this);
    addReference(node.targetReference);
  }

  @override
  void visitStaticSet(StaticSet node) {
    node.visitChildren(this);
    addReference(node.targetReference);
  }

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    node.visitChildren(this);
    addReference(node.targetReference);
  }

  @override
  void visitSuperInitializer(SuperInitializer node) {
    node.visitChildren(this);
    addReference(node.targetReference);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    node.visitChildren(this);
    addReference(node.targetReference);
  }

  @override
  void visitStaticTearOff(StaticTearOff node) {
    node.visitChildren(this);
    addReference(node.targetReference);
  }

  @override
  void defaultDartType(DartType node) {
    // Ignore: Dart2wasm doesn't defer RTI information atm.
  }

  @override
  void visitSupertype(Supertype node) {
    // Ignore: Dart2wasm doesn't defer RTI information atm.
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    addConstant(NullConstant());
  }

  @override
  void visitStringLiteral(StringLiteral node) {
    addConstant(StringConstant(node.value));
  }

  @override
  void visitBoolLiteral(BoolLiteral node) {
    addConstant(BoolConstant(node.value));
  }

  @override
  void visitIntLiteral(IntLiteral node) {
    addConstant(IntConstant(node.value));
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    addConstant(DoubleConstant(node.value));
  }

  // The references needed by the codegen to handle
  // {List,Map,Set,Record}Literals are all marked with
  // @pragma('wasm:entry-point') and do not have to be explicitly
  // modeled as dependencies (they land in the root unit).

  @override
  void visitConstantExpression(ConstantExpression node) {
    addConstant(node.constant);
  }

  void addReference(Reference used) {
    if (_activeLoadGuards.isEmpty) {
      if (deps.references.add(used)) {
        deps.deferredReferences.remove(used);
      }
      return;
    }
    if (!deps.references.contains(used)) {
      if (deps.deferredReferences[used] case final existingGuards?) {
        existingGuards.add(_activeLoadGuards.last);
        return;
      }
      deps.deferredReferences[used] = {_activeLoadGuards.last};
    }
  }

  void addConstant(Constant used) {
    if (_activeLoadGuards.isEmpty) {
      if (deps.constants.add(used)) {
        deps.deferredConstants.remove(used);
      }
      return;
    }
    if (!deps.constants.contains(used)) {
      if (deps.deferredConstants[used] case final existingGuards?) {
        existingGuards.add(_activeLoadGuards.last);
        return;
      }
      deps.deferredConstants[used] = {_activeLoadGuards.last};
    }
  }

  void _addSuperTargetReference(Member interfaceTarget,
      {required bool setter}) {
    final member = _classHierarchy.getDispatchTarget(
        (reference.asMember).enclosingClass!.superclass!, interfaceTarget.name,
        setter: setter)!;
    if (setter) {
      addReference(
          member is Field ? member.setterReference! : member.reference);
    } else {
      addReference(member is Field ? member.getterReference : member.reference);
    }
  }

  void addDynamicSelectorUse(Name used) {
    if (_activeLoadGuards.isEmpty) {
      if (deps.dynamicSelectors.add(used)) {
        deps.deferredDynamicSelectors.remove(used);
      }
      return;
    }
    if (!deps.dynamicSelectors.contains(used)) {
      (deps.deferredDynamicSelectors[used] ??= {}).add(_activeLoadGuards.last);
    }
  }

  void addSelectorUse(Member member, {required bool getter}) {
    final metadata = _procedureAttributeMetadata[member]!;
    final selectorId =
        getter ? metadata.getterSelectorId : metadata.methodOrSetterSelectorId;
    if (_activeLoadGuards.isEmpty) {
      if (deps.selectorIds.add(selectorId)) {
        deps.deferredSelectorIds.remove(selectorId);
      }
      return;
    }
    if (!deps.selectorIds.contains(selectorId)) {
      (deps.deferredSelectorIds[selectorId] ??= {}).add(_activeLoadGuards.last);
    }
  }

  // ---------------------------------------------------------------------------
  // Expressions & Statements that do not need special handling:
  //
  //   * they don't introduce reference/constant/selector depencencies
  //   * they don't introduce control flow and as such: any load guard valid
  //     before the node is still valid after the node, any load guard activated
  //     in the children stays active after the node
  // ---------------------------------------------------------------------------

  @override
  void visitExpressionStatement(ExpressionStatement node) =>
      node.visitChildren(this);
  @override
  void visitBlock(Block node) => node.visitChildren(this);
  @override
  void visitEmptyStatement(EmptyStatement node) => node.visitChildren(this);
  @override
  void visitVariableDeclaration(VariableDeclaration node) =>
      node.visitChildren(this);
  @override
  void visitReturnStatement(ReturnStatement node) => node.visitChildren(this);
  @override
  void visitYieldStatement(YieldStatement node) => node.visitChildren(this);

  @override
  void visitLet(Let node) => node.visitChildren(this);
  @override
  void visitAuxiliaryExpression(AuxiliaryExpression node) =>
      throw UnimplementedError();
  @override
  void visitInvalidExpression(InvalidExpression node) =>
      throw UnimplementedError();
  @override
  void visitVariableGet(VariableGet node) => node.visitChildren(this);
  @override
  void visitVariableSet(VariableSet node) => node.visitChildren(this);
  @override
  void visitFunctionTearOff(FunctionTearOff node) => node.visitChildren(this);
  @override
  void visitAbstractSuperPropertyGet(AbstractSuperPropertyGet node) =>
      node.visitChildren(this);
  @override
  void visitAbstractSuperPropertySet(AbstractSuperPropertySet node) =>
      node.visitChildren(this);

  @override
  void visitLocalFunctionInvocation(LocalFunctionInvocation node) =>
      node.visitChildren(this);
  @override
  void visitInstanceGetterInvocation(InstanceGetterInvocation node) =>
      node.visitChildren(this);
  @override
  void visitEqualsNull(EqualsNull node) => node.visitChildren(this);
  @override
  void visitEqualsCall(EqualsCall node) => node.visitChildren(this);
  @override
  void visitAbstractSuperMethodInvocation(AbstractSuperMethodInvocation node) =>
      node.visitChildren(this);
  @override
  void visitRedirectingFactoryInvocation(RedirectingFactoryInvocation node) =>
      node.visitChildren(this);
  @override
  void visitNot(Not node) => node.visitChildren(this);
  @override
  void visitNullCheck(NullCheck node) => node.visitChildren(this);
  @override
  void visitStringConcatenation(StringConcatenation node) =>
      node.visitChildren(this);
  @override
  void visitListConcatenation(ListConcatenation node) =>
      node.visitChildren(this);
  @override
  void visitSetConcatenation(SetConcatenation node) => node.visitChildren(this);
  @override
  void visitMapConcatenation(MapConcatenation node) => node.visitChildren(this);
  @override
  void visitInstanceCreation(InstanceCreation node) => node.visitChildren(this);
  @override
  void visitFileUriExpression(FileUriExpression node) =>
      node.visitChildren(this);
  @override
  void visitIsExpression(IsExpression node) => node.visitChildren(this);
  @override
  void visitAsExpression(AsExpression node) => node.visitChildren(this);
  @override
  void visitSymbolLiteral(SymbolLiteral node) => node.visitChildren(this);
  @override
  void visitTypeLiteral(TypeLiteral node) => node.visitChildren(this);
  @override
  void visitThisExpression(ThisExpression node) => node.visitChildren(this);
  @override
  void visitListLiteral(ListLiteral node) => node.visitChildren(this);
  @override
  void visitSetLiteral(SetLiteral node) => node.visitChildren(this);
  @override
  void visitMapLiteral(MapLiteral node) => node.visitChildren(this);
  @override
  void visitRecordLiteral(RecordLiteral node) => node.visitChildren(this);
  @override
  void visitAwaitExpression(AwaitExpression node) => node.visitChildren(this);
  @override
  void visitBlockExpression(BlockExpression node) => node.visitChildren(this);
  @override
  void visitInstantiation(Instantiation node) => node.visitChildren(this);
  @override
  void visitTypedefTearOff(TypedefTearOff node) => node.visitChildren(this);
  @override
  void visitRecordIndexGet(RecordIndexGet node) => node.visitChildren(this);
  @override
  void visitRecordNameGet(RecordNameGet node) => node.visitChildren(this);
  @override
  void visitConstructorTearOff(ConstructorTearOff node) =>
      node.visitChildren(this);
}

class DirectReferenceDependencies {
  // The static dependencies.
  final Set<Reference> references = {};
  final Map<Reference, Set<LibraryDependency>> deferredReferences = {};
  final Set<Constant> constants = {};
  final Map<Constant, Set<LibraryDependency>> deferredConstants = {};

  // The selectors used during calls.
  final Set<int> selectorIds = {};
  final Map<int, Set<LibraryDependency>> deferredSelectorIds = {};
  final Set<Name> dynamicSelectors = {};
  final Map<Name, Set<LibraryDependency>> deferredDynamicSelectors = {};

  DirectReferenceDependencies();

  bool get isEmpty =>
      references.isEmpty &&
      deferredReferences.isEmpty &&
      constants.isEmpty &&
      deferredConstants.isEmpty &&
      selectorIds.isEmpty &&
      deferredSelectorIds.isEmpty &&
      dynamicSelectors.isEmpty &&
      deferredDynamicSelectors.isEmpty;
}

class DirectConstantDependencies {
  final Set<Constant> constants;
  final Reference? reference;

  DirectConstantDependencies(this.constants, this.reference);

  bool get isEmpty => constants.isEmpty && reference == null;
}

/// Computes the roots for each deferred import.
ProgramPrefixUsages computePrefixRoots(
  LibraryDependency programRootPrefix,
  Set<Reference> programRoots,
  Set<int> programSelectorRoots,
  Map<Reference, DirectReferenceDependencies> directReferenceDependencies,
  Map<Constant, DirectConstantDependencies> directConstantDependencies,
) {
  final rootUsages = PrefixUsages(programRootPrefix);
  rootUsages.references.addAll(programRoots);
  rootUsages.selectorIds.addAll(programSelectorRoots);

  final prefixRoots = <LibraryDependency, PrefixUsages>{
    programRootPrefix: rootUsages,
  };

  directReferenceDependencies.forEach((_, deps) {
    deps.deferredReferences.forEach((reference, imports) {
      for (final import in imports) {
        (prefixRoots[import] ??= PrefixUsages(import))
            .references
            .add(reference);
      }
    });
    deps.deferredConstants.forEach((constant, imports) {
      for (final import in imports) {
        (prefixRoots[import] ??= PrefixUsages(import)).constants.add(constant);
      }
    });
    deps.deferredSelectorIds.forEach((selectorId, imports) {
      for (final import in imports) {
        (prefixRoots[import] ??= PrefixUsages(import))
            .selectorIds
            .add(selectorId);
      }
    });
    deps.deferredDynamicSelectors.forEach((name, imports) {
      for (final import in imports) {
        (prefixRoots[import] ??= PrefixUsages(import)).selectorNames.add(name);
      }
    });
  });
  return ProgramPrefixUsages(prefixRoots);
}

/// Maps each deferred library import to [PrefixUsages].
///
/// Depending on the usage, the [PrefixUsages] may only be the roots (i.e. the
/// ones accessed directly via `D.*` accesses) or it may be the transitive
/// closure of them or the transitive closure minus that of dominators.
class ProgramPrefixUsages {
  final Map<LibraryDependency, PrefixUsages> usages;
  ProgramPrefixUsages(this.usages);
}

class PrefixUsages {
  final LibraryDependency prefix;

  final Set<Reference> references = {};
  final Set<Constant> constants = {};

  final Set<int> selectorIds = {};
  final Set<Name> selectorNames = {};

  PrefixUsages(this.prefix);
}
