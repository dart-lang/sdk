// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.mixin_deduplication;

import 'package:kernel/ast.dart';

/// De-duplication of identical mixin applications.
void transformComponent(Component component) {
  final deduplicateMixins = new DeduplicateMixinsTransformer();
  component.libraries.forEach(deduplicateMixins.visitLibrary);
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
    if (!node.isExternal) {
      transformList(node.classes, this, node);
    }
    return node;
  }

  @override
  TreeNode visitClass(Class c) {
    if (c.enclosingLibrary.isExternal) {
      return c;
    }

    if (_duplicatedMixins.containsKey(c)) {
      return null; // Class was de-duplicated already, just remove it.
    }

    if (c.supertype != null) {
      _transformSupertype(c);
    }

    if (!c.isSyntheticMixinImplementation) {
      return c;
    }

    Class canonical =
        _canonicalMixins.putIfAbsent(new _DeduplicateMixinKey(c), () => c);
    assert(canonical != null);

    if (canonical != c) {
      c.canonicalName?.unbind();
      _duplicatedMixins[c] = canonical;
      // print('Replacing $c with $canonical');
      return null; // Remove class.
    }

    return c;
  }

  void _transformSupertype(Class c) {
    Class oldSuper = c.superclass;
    if (oldSuper == null) {
      return;
    }
    Class newSuper = visitClass(oldSuper);
    if (newSuper == null) {
      Class canonicalSuper = _duplicatedMixins[oldSuper];
      assert(canonicalSuper != null);
      c.supertype = new Supertype(canonicalSuper, c.supertype.typeArguments);
      _correctForwardingConstructors(c, oldSuper, canonicalSuper);
    }
  }

  @override
  TreeNode defaultTreeNode(TreeNode node) =>
      throw 'Unexpected node ${node.runtimeType}: $node';
}

/// Corrects synthetic forwarding constructors inserted by mixin resolution
/// after replacing superclass.
void _correctForwardingConstructors(Class c, Class oldSuper, Class newSuper) {
  for (var constructor in c.constructors) {
    if (constructor.isSynthetic) {
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
}
