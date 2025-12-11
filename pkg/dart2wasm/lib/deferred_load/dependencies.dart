// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/library_index.dart';

import '../modules.dart';

class DependenciesCollector {
  final CoreTypes _coreTypes;
  final DeferredModuleLoadingMap _loadingMap;

  late final _checkLibraryIsLoadedFromLoadId = _coreTypes.index.getProcedure(
      'dart:_internal',
      LibraryIndex.topLevel,
      'checkLibraryIsLoadedFromLoadId');

  DependenciesCollector(this._coreTypes, this._loadingMap);

  /// Returns the set of constants referred to by the (possibly composed)
  /// [constant].
  DirectConstantDependencies directConstantDependencies(Constant constant) {
    final children = <Constant>{};
    constant.visitChildren(_ConstantDependenciesCollector._(children));
    return DirectConstantDependencies(children);
  }

  DirectReferenceDependencies directReferenceDependencies(Reference reference) {
    final TreeNode node = reference.node!;

    final deps = DirectReferenceDependencies({}, {}, {}, {});

    if (node is Class) {
      _enqueueInstanceMembers(node, deps);
      return deps;
    }

    final collector = _ReferenceDependenciesCollector._(
        _recognizeDeferredLoadingGuard, reference, deps);
    if (node is Procedure) {
      node.accept(collector);
      return deps;
    }
    if (node is Constructor) {
      node.accept(collector);
      collector.addReference(node.enclosingClass.reference);
      return deps;
    }
    if (node is Field) {
      node.accept(collector);
      if (node.fieldReference != reference) {
        collector.addReference(node.fieldReference);
      }
      if (node.getterReference != reference) {
        collector.addReference(node.getterReference);
      }
      if (node.setterReference case final setterReference?) {
        if (setterReference != reference) {
          collector.addReference(setterReference);
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

  static void _enqueueInstanceMembers(
      Class klass, DirectReferenceDependencies deps) {
    final superReference = klass.superclass?.reference;
    if (superReference != null) {
      deps.references.add(superReference);
    }
    for (final m in klass.members) {
      if (m.isInstanceMember) {
        if (m is Field) {
          deps.references.add(m.fieldReference);
          continue;
        }
        deps.references.add(m.reference);
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
  final LibraryDependency? Function(Let node) recognizeDeferredLoadingGuard;

  final Reference reference;
  final DirectReferenceDependencies deps;
  final List<LibraryDependency> _activeLoadGuards = [];

  _ReferenceDependenciesCollector._(
      this.recognizeDeferredLoadingGuard, this.reference, this.deps);

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
}

class DirectReferenceDependencies {
  final Set<Reference> references;
  final Map<Reference, Set<LibraryDependency>> deferredReferences;
  final Set<Constant> constants;
  final Map<Constant, Set<LibraryDependency>> deferredConstants;

  DirectReferenceDependencies(this.references, this.deferredReferences,
      this.constants, this.deferredConstants);
}

class DirectConstantDependencies {
  final Set<Constant> constants;

  DirectConstantDependencies(this.constants);
}
