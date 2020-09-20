// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.mixin_deduplication;

import 'package:kernel/ast.dart';

/// De-duplication of identical mixin applications.
void transformComponent(Component component) {
  final deduplicateMixins = new DeduplicateMixinsTransformer();
  final referenceUpdater = ReferenceUpdater(deduplicateMixins);

  // Deduplicate mixins and re-resolve super initializers.
  // (this is a shallow transformation)
  component.libraries.forEach(deduplicateMixins.visitLibrary);

  // Do a deep transformation to update references to the removed mixin
  // application classes in the interface targets and types.
  //
  // Interface targets pointing to members of removed mixin application
  // classes are re-resolved at the remaining mixin applications.
  // This is necessary iff the component was assembled from individual modular
  // kernel compilations:
  //
  //   * if the CFE reads in the entire program as source, interface targets
  //     will point to the original mixin class
  //
  //   * if the CFE reads in dependencies as kernel, interface targets will
  //     point to the already existing mixin application classes.
  //
  // TODO(dartbug.com/39375): Remove this extra O(N) pass over the AST if the
  // CFE decides to consistently let the interface target point to the mixin
  // class (instead of mixin application).
  //
  // Types could also contain references to removed mixin applications due to
  // LUB algorithm in CFE (calculating static type of a conditional expression)
  // and type inference which can spread types and produce derived types.
  component.libraries.forEach(referenceUpdater.visitLibrary);
}

class _DeduplicateMixinKey {
  final Class _class;
  _DeduplicateMixinKey(this._class);

  @override
  bool operator ==(Object other) {
    if (other is _DeduplicateMixinKey) {
      final thisClass = _class;
      final otherClass = other._class;
      if (identical(thisClass, otherClass)) {
        return true;
      }
      // Do not deduplicate parameterized mixin applications.
      if (thisClass.typeParameters.isNotEmpty ||
          otherClass.typeParameters.isNotEmpty) {
        return false;
      }
      // Deduplicate mixin applications with matching supertype, mixed-in type,
      // implemented interfaces and NNBD mode (CFE may add extra signature
      // members depending on the NNBD mode).
      return thisClass.supertype == otherClass.supertype &&
          thisClass.mixedInType == otherClass.mixedInType &&
          listEquals(thisClass.implementedTypes, otherClass.implementedTypes) &&
          thisClass.enclosingLibrary.isNonNullableByDefault ==
              otherClass.enclosingLibrary.isNonNullableByDefault;
    }
    return false;
  }

  @override
  int get hashCode {
    if (_class.typeParameters.isNotEmpty) {
      return _class.hashCode;
    }
    int hash = 31;
    hash = 0x3fffffff & (hash * 31 + _class.supertype.hashCode);
    hash = 0x3fffffff & (hash * 31 + _class.mixedInType.hashCode);
    for (var i in _class.implementedTypes) {
      hash = 0x3fffffff & (hash * 31 + i.hashCode);
    }
    return hash;
  }
}

class DeduplicateMixinsTransformer extends Transformer {
  final _canonicalMixins = new Map<_DeduplicateMixinKey, Class>();
  final _duplicatedMixins = new Map<Class, Class>();

  @override
  TreeNode visitLibrary(Library node) {
    transformList(node.classes, this, node);
    return node;
  }

  @override
  TreeNode visitClass(Class c) {
    if (_duplicatedMixins.containsKey(c)) {
      return null; // Class was de-duplicated already, just remove it.
    }

    if (c.supertype != null) {
      c.supertype = _transformSupertype(c.supertype, c, true);
    }
    if (c.mixedInType != null) {
      throw 'All mixins should be transformed already.';
    }
    transformSupertypeList(c.implementedTypes, this);

    if (!c.isAnonymousMixin) {
      return c;
    }

    Class canonical =
        _canonicalMixins.putIfAbsent(new _DeduplicateMixinKey(c), () => c);
    assert(canonical != null);

    if (canonical != c) {
      // Ensure that kernel file writer will not be able to
      // write a dangling reference to the deleted class.
      c.reference.canonicalName = null;
      _duplicatedMixins[c] = canonical;
      return null; // Remove class.
    }

    return c;
  }

  @override
  Supertype visitSupertype(Supertype node) {
    return _transformSupertype(node, null, false);
  }

  Supertype _transformSupertype(
      Supertype supertype, Class cls, bool isSuperclass) {
    Class oldSuper = supertype.classNode;
    Class newSuper = visitClass(oldSuper);
    if (newSuper == null) {
      Class canonicalSuper = _duplicatedMixins[oldSuper];
      assert(canonicalSuper != null);
      supertype = new Supertype(canonicalSuper, supertype.typeArguments);
      if (isSuperclass) {
        _correctForwardingConstructors(cls, oldSuper, canonicalSuper);
      }
    }
    return supertype;
  }

  @override
  TreeNode defaultTreeNode(TreeNode node) =>
      throw 'Unexpected node ${node.runtimeType}: $node';
}

/// Rewrites references to the deduplicated mixin application
/// classes. Updates interface targets and types.
class ReferenceUpdater extends RecursiveVisitor<void> {
  final DeduplicateMixinsTransformer transformer;
  final _visitedConstants = new Set<Constant>.identity();

  ReferenceUpdater(this.transformer);

  @override
  visitLibrary(Library node) {
    super.visitLibrary(node);
    // Avoid accumulating too many constants in case of huge programs.
    _visitedConstants.clear();
  }

  @override
  visitPropertyGet(PropertyGet node) {
    node.interfaceTarget = _resolveNewInterfaceTarget(node.interfaceTarget);
    super.visitPropertyGet(node);
  }

  @override
  visitPropertySet(PropertySet node) {
    node.interfaceTarget = _resolveNewInterfaceTarget(node.interfaceTarget);
    super.visitPropertySet(node);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    node.interfaceTarget = _resolveNewInterfaceTarget(node.interfaceTarget);
    super.visitMethodInvocation(node);
  }

  @override
  visitSuperPropertyGet(SuperPropertyGet node) {
    node.interfaceTarget = _resolveNewInterfaceTarget(node.interfaceTarget);
    super.visitSuperPropertyGet(node);
  }

  @override
  visitSuperPropertySet(SuperPropertySet node) {
    node.interfaceTarget = _resolveNewInterfaceTarget(node.interfaceTarget);
    super.visitSuperPropertySet(node);
  }

  @override
  visitSuperMethodInvocation(SuperMethodInvocation node) {
    node.interfaceTarget = _resolveNewInterfaceTarget(node.interfaceTarget);
    super.visitSuperMethodInvocation(node);
  }

  Member _resolveNewInterfaceTarget(Member m) {
    final Class c = m?.enclosingClass;
    if (c != null && c.isAnonymousMixin) {
      final Class replacement = transformer._duplicatedMixins[c];
      if (replacement != null) {
        // The class got removed, so we need to re-resolve the interface target.
        return _findMember(replacement, m);
      }
    }
    return m;
  }

  Member _findMember(Class klass, Member m) {
    if (m is Field) {
      return klass.members.where((other) => other.name == m.name).single;
    } else if (m is Procedure) {
      return klass.procedures
          .where((other) => other.kind == m.kind && other.name == m.name)
          .single;
    } else {
      throw 'Hit unexpected interface target which is not a Field/Procedure';
    }
  }

  @override
  visitInterfaceType(InterfaceType node) {
    node.className = _updateClassReference(node.className);
    super.visitInterfaceType(node);
  }

  Reference _updateClassReference(Reference classRef) {
    final Class c = classRef.asClass;
    if (c != null && c.isAnonymousMixin) {
      final Class replacement = transformer._duplicatedMixins[c];
      if (replacement != null) {
        return replacement.reference;
      }
    }
    return classRef;
  }

  @override
  defaultConstantReference(Constant node) {
    // By default, RecursiveVisitor stops at constants. We need to go deeper
    // into constants in order to update types which are only referenced from
    // constants. However, constants are DAGs and not trees, so visiting
    // the same constant multiple times should be avoided to prevent
    // exponential running time.
    if (_visitedConstants.add(node)) {
      node.accept(this);
    }
  }

  @override
  visitClassReference(Class node) {
    // Safeguard against any possible leaked uses of anonymous mixin
    // applications which are not updated.
    if (node.isAnonymousMixin && transformer._duplicatedMixins[node] != null) {
      throw 'Unexpected reference to removed mixin application $node';
    }
    super.visitClassReference(node);
  }
}

/// Corrects forwarding constructors inserted by mixin resolution after
/// replacing superclass.
void _correctForwardingConstructors(Class c, Class oldSuper, Class newSuper) {
  for (var constructor in c.constructors) {
    for (var initializer in constructor.initializers) {
      if ((initializer is SuperInitializer) &&
          initializer.target.enclosingClass == oldSuper) {
        Constructor replacement = null;
        for (var c in newSuper.constructors) {
          if (c.name == initializer.target.name) {
            replacement = c;
            break;
          }
        }
        if (replacement == null) {
          throw 'Unable to find a replacement for $c in $newSuper';
        }
        initializer.target = replacement;
      }
    }
  }
}
