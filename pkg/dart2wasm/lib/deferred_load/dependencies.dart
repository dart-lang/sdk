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

  final Map<TreeNode, ProcedureAttributesMetadata> procedureAttributeMetadata;

  late final _checkLibraryIsLoadedFromLoadId = _coreTypes.index.getProcedure(
      'dart:_internal',
      LibraryIndex.topLevel,
      'checkLibraryIsLoadedFromLoadId');

  DependenciesCollector(this.procedureAttributeMetadata, this._coreTypes,
      this._classHierarchy, this._devirtualizionOracle, this._loadingMap);

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
        _classHierarchy,
        _devirtualizionOracle,
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

  LibraryDependency? _recognizeDeferredLoadingGuard(Let let) {
    // TODO(http://dartbug.com/61764): Find better way to do this.
    //
    // If we have
    //
    //   let
    //     _ = checkLibraryIsLoadedFromLoadId(<id>)
    //   in
    //     <body>
    //
    // Then we know that the body will only be executed once the deferred prefix
    // `D` was loaded.
    final init = let.variable.initializer;
    if (init is StaticInvocation) {
      final target = init.target;
      if (target == _checkLibraryIsLoadedFromLoadId) {
        final args = init.arguments.positional;
        final loadId = (args[0] as IntLiteral).value;
        return _loadingMap.loadIdToDeferredImport[loadId];
      }
    }
    return null;
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

  final LibraryDependency? Function(Let node) recognizeDeferredLoadingGuard;
  final DevirtualizionOracle _devirtualizionOracle;
  final ClosedWorldClassHierarchy _classHierarchy;

  final Reference reference;
  final DirectReferenceDependencies deps;
  final List<LibraryDependency> _activeLoadGuards = [];

  _ReferenceDependenciesCollector._(
      this._procedureAttributeMetadata,
      this.recognizeDeferredLoadingGuard,
      this._classHierarchy,
      this._devirtualizionOracle,
      this.reference,
      this.deps);

  @override
  void visitLet(Let node) {
    node.variable.accept(this);

    final guard = recognizeDeferredLoadingGuard(node);
    if (guard != null) {
      _activeLoadGuards.add(guard);
    }
    node.body.accept(this);
    if (guard != null) {
      final last = _activeLoadGuards.removeLast();
      assert(guard == last);
    }
  }

  // The references needed by the codegen to handle
  // {List,Map,Set,Record}Literals are all marked with
  // @pragma('wasm:entry-point') and do not have to be explicitly
  // modeled as dependencies (they land in the root unit).

  @override
  void visitSuperPropertyGet(SuperPropertyGet node) {
    // NOTE: Super calls are direct calls and as such don't need to call
    // [addSelectorUse]/[addDynamicSelectorUse].
    super.visitSuperPropertyGet(node);
    _addSuperTargetReference(node.interfaceTarget, setter: false);
  }

  @override
  void visitSuperPropertySet(SuperPropertySet node) {
    // NOTE: Super calls are direct calls and as such don't need to call
    // [addSelectorUse]/[addDynamicSelectorUse].
    super.visitSuperPropertySet(node);
    _addSuperTargetReference(node.interfaceTarget, setter: true);
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    // NOTE: Super calls are direct calls and as such don't need to call
    // [addSelectorUse]/[addDynamicSelectorUse].
    super.visitSuperMethodInvocation(node);
    _addSuperTargetReference(node.interfaceTarget, setter: false);
  }

  @override
  void visitInstanceGet(InstanceGet node) {
    super.visitInstanceGet(node);
    final target = _devirtualizionOracle.staticDispatchTargetForGet(node);
    if (target != null) {
      addReference(target);
    } else {
      addSelectorUse(node.interfaceTarget, getter: true);
    }
  }

  @override
  void visitInstanceSet(InstanceSet node) {
    super.visitInstanceSet(node);
    final target = _devirtualizionOracle.staticDispatchTargetForSet(node);
    if (target != null) {
      addReference(target);
    } else {
      addSelectorUse(node.interfaceTarget, getter: false);
    }
  }

  @override
  void visitInstanceInvocation(InstanceInvocation node) {
    super.visitInstanceInvocation(node);
    final target = _devirtualizionOracle.staticDispatchTargetForCall(node);
    if (target != null) {
      addReference(target);
    } else {
      addSelectorUse(node.interfaceTarget, getter: false);
    }
  }

  @override
  void visitInstanceTearOff(InstanceTearOff node) {
    super.visitInstanceTearOff(node);
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
    super.visitDynamicGet(node);
    addDynamicSelectorUse(node.name);
  }

  @override
  void visitDynamicSet(DynamicSet node) {
    super.visitDynamicSet(node);
    addDynamicSelectorUse(node.name);
  }

  @override
  void visitDynamicInvocation(DynamicInvocation node) {
    super.visitDynamicInvocation(node);
    addDynamicSelectorUse(node.name);
  }

  @override
  void visitFunctionInvocation(FunctionInvocation node) {
    // NOTE: [_Closure.call] is marked as `@pragma('wasm:entry-point')` and will
    // therefore be considered a selector use by the root.
    super.visitFunctionInvocation(node);
  }

  @override
  void visitStaticGet(StaticGet node) {
    super.visitStaticGet(node);
    addReference(node.targetReference);
  }

  @override
  void visitStaticSet(StaticSet node) {
    super.visitStaticSet(node);
    addReference(node.targetReference);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    super.visitStaticInvocation(node);
    addReference(node.targetReference);
  }

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    super.visitConstructorInvocation(node);
    addReference(node.targetReference);
  }

  @override
  void visitSuperInitializer(SuperInitializer node) {
    super.visitSuperInitializer(node);
    addReference(node.targetReference);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    super.visitRedirectingInitializer(node);
    addReference(node.targetReference);
  }

  @override
  void visitStaticTearOff(StaticTearOff node) {
    super.visitStaticTearOff(node);
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
