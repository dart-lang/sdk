// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common_elements.dart';
import '../elements/elements.dart' show ClassElement, MixinApplicationElement;
import '../elements/entities.dart';
import '../elements/types.dart' show InterfaceType;
import 'class_set.dart';

class ClassHierarchyBuilder {
  // We keep track of subtype and subclass relationships in four
  // distinct sets to make class hierarchy analysis faster.
  final Map<ClassEntity, ClassHierarchyNode> classHierarchyNodes =
      <ClassEntity, ClassHierarchyNode>{};
  final Map<ClassEntity, ClassSet> classSets = <ClassEntity, ClassSet>{};
  final Map<ClassEntity, Set<ClassEntity>> mixinUses =
      new Map<ClassEntity, Set<ClassEntity>>();

  final CommonElements _commonElements;
  final ClassQueries _classQueries;

  ClassHierarchyBuilder(this._commonElements, this._classQueries);

  void registerClass(ClassEntity cls) {
    _ensureClassSet(_classQueries.getDeclaration(cls));
  }

  ClassHierarchyNode _ensureClassHierarchyNode(ClassEntity cls) {
    assert(_classQueries.checkClass(cls));
    return classHierarchyNodes.putIfAbsent(cls, () {
      ClassHierarchyNode parentNode;
      ClassEntity superclass = _classQueries.getSuperClass(cls);
      if (superclass != null) {
        parentNode = _ensureClassHierarchyNode(superclass);
      }
      return new ClassHierarchyNode(
          parentNode, cls, _classQueries.getHierarchyDepth(cls));
    });
  }

  ClassSet _ensureClassSet(ClassEntity cls) {
    assert(_classQueries.checkClass(cls));
    return classSets.putIfAbsent(cls, () {
      ClassHierarchyNode node = _ensureClassHierarchyNode(cls);
      ClassSet classSet = new ClassSet(node);

      for (InterfaceType type in _classQueries.getSupertypes(cls)) {
        // TODO(johnniwinther): Optimization: Avoid adding [cls] to
        // superclasses.
        ClassSet subtypeSet = _ensureClassSet(type.element);
        subtypeSet.addSubtype(node);
      }

      ClassEntity appliedMixin = _classQueries.getAppliedMixin(cls);
      if (appliedMixin != null) {
        // TODO(johnniwinther): Store this in the [ClassSet].
        registerMixinUse(cls, appliedMixin);
      }

      return classSet;
    });
  }

  void _updateSuperClassHierarchyNodeForClass(ClassHierarchyNode node) {
    // Ensure that classes implicitly implementing `Function` are in its
    // subtype set.
    ClassEntity cls = node.cls;
    if (cls != _commonElements.functionClass &&
        _classQueries.implementsFunction(cls)) {
      ClassSet subtypeSet = _ensureClassSet(_commonElements.functionClass);
      subtypeSet.addSubtype(node);
    }
    if (!node.isInstantiated && node.parentNode != null) {
      _updateSuperClassHierarchyNodeForClass(node.parentNode);
    }
  }

  void updateClassHierarchyNodeForClass(ClassEntity cls,
      {bool directlyInstantiated: false, bool abstractlyInstantiated: false}) {
    ClassHierarchyNode node = _ensureClassHierarchyNode(cls);
    _updateSuperClassHierarchyNodeForClass(node);
    if (directlyInstantiated) {
      node.isDirectlyInstantiated = true;
    }
    if (abstractlyInstantiated) {
      node.isAbstractlyInstantiated = true;
    }
  }

  void registerMixinUse(ClassEntity mixinApplication, ClassEntity mixin) {
    // TODO(johnniwinther): Add map restricted to live classes.
    // We don't support patch classes as mixin.
    Set<ClassEntity> users =
        mixinUses.putIfAbsent(mixin, () => new Set<ClassEntity>());
    users.add(mixinApplication);
  }
}

abstract class ClassQueries {
  bool checkClass(covariant ClassEntity cls);
  bool validateClass(covariant ClassEntity cls);

  /// Returns the declaration of [cls].
  ClassEntity getDeclaration(covariant ClassEntity cls);

  /// Returns the class mixed into [cls] if any.
  ClassEntity getAppliedMixin(covariant ClassEntity cls);

  /// Returns the hierarchy depth of [cls].
  int getHierarchyDepth(covariant ClassEntity cls);

  /// Returns `true` if [cls] implements `Function` either explicitly or through
  /// a `call` method.
  bool implementsFunction(covariant ClassEntity cls);

  /// Returns the superclass of [cls] if any.
  ClassEntity getSuperClass(covariant ClassEntity cls);

  /// Returns all supertypes of [cls].
  Iterable<InterfaceType> getSupertypes(covariant ClassEntity cls);
}

class ElementClassQueries extends ClassQueries {
  final CommonElements commonElements;

  ElementClassQueries(this.commonElements);

  @override
  ClassEntity getDeclaration(ClassElement cls) {
    return cls.declaration;
  }

  @override
  ClassEntity getAppliedMixin(ClassElement cls) {
    if (cls.isMixinApplication) {
      MixinApplicationElement mixinApplication = cls;
      // Note: If [mixinApplication] is malformed [mixin] is `null`.
      return mixinApplication.mixin;
    }
    return null;
  }

  @override
  int getHierarchyDepth(ClassElement cls) => cls.hierarchyDepth;

  @override
  bool checkClass(ClassElement cls) => cls.isDeclaration;

  @override
  bool validateClass(ClassElement cls) => cls.isResolved;

  @override
  bool implementsFunction(ClassElement cls) =>
      cls.implementsFunction(commonElements);

  @override
  ClassEntity getSuperClass(ClassElement cls) => cls.superclass;

  @override
  Iterable<InterfaceType> getSupertypes(ClassElement cls) => cls.allSupertypes;
}
