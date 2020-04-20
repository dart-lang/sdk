// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.mixin_deduplication;

import 'package:kernel/ast.dart';

/// De-duplication of identical mixin applications.
void transformComponent(Component component) {
  final deduplicateMixins = new DeduplicateMixinsTransformer();
  final interfaceTargetResolver = InterfaceTargetResolver(deduplicateMixins);

  // Deduplicate mixins and re-resolve super initializers.
  // (this is a shallow transformation)
  component.libraries.forEach(deduplicateMixins.visitLibrary);

  // Do a deep transformation to re-resolve all interface targets that point to
  // members of removed mixin application classes.

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
  component.libraries.forEach(interfaceTargetResolver.visitLibrary);
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
      // Deduplicate mixin applications with matching supertype, mixed-in type
      // and implemented interfaces.
      return thisClass.supertype == otherClass.supertype &&
          thisClass.mixedInType == otherClass.mixedInType &&
          listEquals(thisClass.implementedTypes, otherClass.implementedTypes);
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
      c.canonicalName?.unbind();
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

/// Rewrites interface targets to point to the deduplicated mixin application
/// class.
class InterfaceTargetResolver extends RecursiveVisitor<TreeNode> {
  final DeduplicateMixinsTransformer transformer;

  InterfaceTargetResolver(this.transformer);

  defaultTreeNode(TreeNode node) {
    node.visitChildren(this);
    return node;
  }

  visitPropertyGet(PropertyGet node) {
    node.interfaceTarget = _resolveNewInterfaceTarget(node.interfaceTarget);
    return super.visitPropertyGet(node);
  }

  visitPropertySet(PropertySet node) {
    node.interfaceTarget = _resolveNewInterfaceTarget(node.interfaceTarget);
    return super.visitPropertySet(node);
  }

  visitMethodInvocation(MethodInvocation node) {
    node.interfaceTarget = _resolveNewInterfaceTarget(node.interfaceTarget);
    return super.visitMethodInvocation(node);
  }

  visitSuperPropertyGet(SuperPropertyGet node) {
    node.interfaceTarget = _resolveNewInterfaceTarget(node.interfaceTarget);
    return super.visitSuperPropertyGet(node);
  }

  visitSuperPropertySet(SuperPropertySet node) {
    node.interfaceTarget = _resolveNewInterfaceTarget(node.interfaceTarget);
    return super.visitSuperPropertySet(node);
  }

  visitSuperMethodInvocation(SuperMethodInvocation node) {
    node.interfaceTarget = _resolveNewInterfaceTarget(node.interfaceTarget);
    return super.visitSuperMethodInvocation(node);
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
