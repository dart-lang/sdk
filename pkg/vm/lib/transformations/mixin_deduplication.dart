// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/type_algebra.dart';

/// De-duplication of identical mixin applications.
void transformComponent(Component component) {
  final deduplicateMixins = new DeduplicateMixinsTransformer();
  final referenceUpdater = ReferenceUpdater(deduplicateMixins);

  // Deduplicate mixins and re-resolve super initializers.
  // (this is a shallow transformation)
  component.libraries
      .forEach((library) => deduplicateMixins.visitLibrary(library, null));

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
  component.libraries.forEach(referenceUpdater.visitLibrary);
}

class _DeduplicateMixinKey {
  final Class _class;
  _DeduplicateMixinKey(this._class) {
    // Mixins applications were lowered to anonymous mixin application classes.
    assert(_class.mixedInType == null);
    assert(_class.isAnonymousMixin);
  }

  @override
  bool operator ==(Object other) {
    if (other is! _DeduplicateMixinKey) return false;

    final thisClass = _class;
    final otherClass = other._class;
    if (identical(thisClass, otherClass)) {
      return true;
    }

    // If the shape of the two mixin application classes don't match, return
    // `false` quickly.
    final thisSupertype = thisClass.supertype!;
    final otherSupertype = otherClass.supertype!;
    if (thisSupertype.classNode != otherSupertype.classNode) return false;

    final thisParameters = thisClass.typeParameters;
    final otherParameters = otherClass.typeParameters;
    if (thisParameters.length != otherParameters.length) return false;

    final thisImplemented = thisClass.implementedTypes;
    final otherImplemented = otherClass.implementedTypes;
    if (thisImplemented.length != otherImplemented.length) return false;

    // Non generic classes can use equalty compares of supertypes.
    if (thisParameters.isEmpty) {
      if (thisSupertype != otherSupertype) return false;
      if (!listEquals(thisImplemented, otherImplemented)) return false;
    }

    // Generic classes must translate type parameter usages from one class to
    // the other.
    final substitution = Substitution.fromMap({
      for (int i = 0; i < otherParameters.length; ++i)
        otherParameters[i]: TypeParameterType(
            thisParameters[i],
            otherParameters[i].bound.nullability == Nullability.nonNullable
                ? Nullability.nonNullable
                : Nullability.undetermined),
    });
    if (thisSupertype != substitution.substituteSupertype(otherSupertype)) {
      return false;
    }
    for (int i = 0; i < thisImplemented.length; ++i) {
      if (thisImplemented[i] !=
          substitution.substituteSupertype(otherImplemented[i])) {
        return false;
      }
    }
    for (int i = 0; i < thisParameters.length; ++i) {
      if (thisParameters[i].bound !=
          substitution.substituteType(otherParameters[i].bound)) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode {
    int hash = 31;
    hash = 0x3fffffff & (hash * 31 + _class.supertype!.classNode.hashCode);
    for (var i in _class.implementedTypes) {
      hash = 0x3fffffff & (hash * 31 + i.classNode.hashCode);
    }
    hash = 0x3fffffff & (hash * 31 + _class.typeParameters.length.hashCode);
    return hash;
  }
}

class DeduplicateMixinsTransformer extends RemovingTransformer {
  final _canonicalMixins = new Map<_DeduplicateMixinKey, Class>();
  final _duplicatedMixins = new Map<Class, Class>();

  @override
  TreeNode visitLibrary(Library node, TreeNode? removalSentinel) {
    transformClassList(node.classes, node);
    return node;
  }

  @override
  TreeNode visitClass(Class c, TreeNode? removalSentinel) {
    if (_duplicatedMixins.containsKey(c)) {
      // Class was de-duplicated already, just remove it.
      return removalSentinel!;
    }

    if (c.supertype != null) {
      c.supertype = _transformSupertype(c.supertype!, c, true);
    }
    if (c.mixedInType != null) {
      throw 'All mixins should be transformed already.';
    }
    transformSupertypeList(c.implementedTypes);

    if (!c.isAnonymousMixin) {
      return c;
    }

    Class canonical =
        _canonicalMixins.putIfAbsent(new _DeduplicateMixinKey(c), () => c);

    if (canonical != c) {
      // Ensure that kernel file writer will not be able to
      // write a dangling reference to the deleted class.
      c.reference.canonicalName = null;
      _duplicatedMixins[c] = canonical;
      // Remove class.
      return removalSentinel!;
    }

    return c;
  }

  @override
  Supertype visitSupertype(Supertype node, Supertype? removalSentinel) {
    return _transformSupertype(node, null, false);
  }

  Supertype _transformSupertype(
      Supertype supertype, Class? cls, bool isSuperclass) {
    Class oldSuper = supertype.classNode;
    Class newSuper = visitClass(oldSuper, dummyClass) as Class;
    if (identical(newSuper, dummyClass)) {
      Class canonicalSuper = _duplicatedMixins[oldSuper]!;
      supertype = new Supertype(canonicalSuper, supertype.typeArguments);
      if (isSuperclass) {
        _correctForwardingConstructors(cls!, oldSuper, canonicalSuper);
      }
    }
    return supertype;
  }

  @override
  TreeNode defaultTreeNode(TreeNode node, TreeNode? removalSentinel) =>
      throw 'Unexpected node ${node.runtimeType}: $node';
}

/// Rewrites references to the deduplicated mixin application
/// classes. Updates interface targets and types.
class ReferenceUpdater extends RecursiveVisitor {
  final DeduplicateMixinsTransformer transformer;

  ReferenceUpdater(this.transformer);

  @override
  void visitProcedure(Procedure node) {
    super.visitProcedure(node);
    node.stubTarget = _resolveNewInterfaceTarget(node.stubTarget);
  }

  @override
  visitInstanceGet(InstanceGet node) {
    node.interfaceTarget = _resolveNewInterfaceTarget(node.interfaceTarget)!;
    super.visitInstanceGet(node);
  }

  @override
  visitInstanceTearOff(InstanceTearOff node) {
    node.interfaceTarget =
        _resolveNewInterfaceTarget(node.interfaceTarget) as Procedure;
    super.visitInstanceTearOff(node);
  }

  @override
  visitInstanceSet(InstanceSet node) {
    node.interfaceTarget = _resolveNewInterfaceTarget(node.interfaceTarget)!;
    super.visitInstanceSet(node);
  }

  @override
  visitInstanceInvocation(InstanceInvocation node) {
    node.interfaceTarget =
        _resolveNewInterfaceTarget(node.interfaceTarget) as Procedure;
    super.visitInstanceInvocation(node);
  }

  @override
  visitEqualsCall(EqualsCall node) {
    node.interfaceTarget =
        _resolveNewInterfaceTarget(node.interfaceTarget) as Procedure;
    super.visitEqualsCall(node);
  }

  @override
  visitSuperPropertyGet(SuperPropertyGet node) {
    node.interfaceTarget = _resolveNewInterfaceTarget(node.interfaceTarget)!;
    super.visitSuperPropertyGet(node);
  }

  @override
  visitSuperPropertySet(SuperPropertySet node) {
    node.interfaceTarget = _resolveNewInterfaceTarget(node.interfaceTarget)!;
    super.visitSuperPropertySet(node);
  }

  @override
  visitSuperMethodInvocation(SuperMethodInvocation node) {
    node.interfaceTarget =
        _resolveNewInterfaceTarget(node.interfaceTarget) as Procedure;
    super.visitSuperMethodInvocation(node);
  }

  Member? _resolveNewInterfaceTarget(Member? m) {
    final Class? c = m?.enclosingClass;
    if (c != null && c.isAnonymousMixin) {
      final Class? replacement = transformer._duplicatedMixins[c];
      if (replacement != null) {
        // The class got removed, so we need to re-resolve the interface target.
        return _findMember(replacement, m!);
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
        Constructor? replacement = null;
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
