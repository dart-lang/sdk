// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.kernel.world_builder;

/// Support for subtype checks of kernel based [DartType]s.
class _KernelDartTypes implements DartTypes {
  final KernelWorldBuilder worldBuilder;
  final SubtypeVisitor subtypeVisitor;
  final PotentialSubtypeVisitor potentialSubtypeVisitor;

  _KernelDartTypes(this.worldBuilder)
      : this.subtypeVisitor = new _KernelSubtypeVisitor(worldBuilder),
        this.potentialSubtypeVisitor =
            new _KernelPotentialSubtypeVisitor(worldBuilder);

  @override
  bool isPotentialSubtype(DartType t, DartType s) {
    return potentialSubtypeVisitor.isSubtype(t, s);
  }

  @override
  bool isAssignable(DartType t, DartType s) {
    return isSubtype(t, s) || isSubtype(s, t);
  }

  @override
  bool isSubtype(DartType t, DartType s) {
    return subtypeVisitor.isSubtype(t, s);
  }

  @override
  CommonElements get commonElements => worldBuilder.commonElements;
}

class _KernelOrderedTypeSetBuilder extends OrderedTypeSetBuilderBase {
  final KernelWorldBuilder worldBuilder;

  _KernelOrderedTypeSetBuilder(this.worldBuilder, ClassEntity cls)
      : super(cls,
            reporter: worldBuilder.reporter,
            objectType: worldBuilder.commonElements.objectType);

  InterfaceType getThisType(ClassEntity cls) {
    return worldBuilder._getThisType(cls);
  }

  InterfaceType substByContext(InterfaceType type, InterfaceType context) {
    return worldBuilder._substByContext(type, context);
  }

  int getHierarchyDepth(ClassEntity cls) {
    return worldBuilder._getHierarchyDepth(cls);
  }

  OrderedTypeSet getOrderedTypeSet(ClassEntity cls) {
    return worldBuilder._getOrderedTypeSet(cls);
  }
}

abstract class _AbstractTypeRelationMixin implements AbstractTypeRelation {
  KernelWorldBuilder get worldBuilder;

  @override
  CommonElements get commonElements => worldBuilder.commonElements;

  @override
  DartType getTypeVariableBound(TypeVariableEntity element) {
    // TODO(johnniwinther): Compute the bound.
    return commonElements.objectType;
  }

  @override
  FunctionType getCallType(InterfaceType type) {
    // TODO(johnniwinther): Compute the call type.
    return null;
  }

  @override
  InterfaceType asInstanceOf(InterfaceType type, ClassEntity cls) {
    OrderedTypeSet orderedTypeSet =
        worldBuilder._getOrderedTypeSet(type.element);
    InterfaceType supertype =
        orderedTypeSet.asInstanceOf(cls, worldBuilder._getHierarchyDepth(cls));
    if (supertype != null) {
      supertype = worldBuilder._substByContext(supertype, type);
    }
    return supertype;
  }
}

class _KernelSubtypeVisitor extends SubtypeVisitor
    with _AbstractTypeRelationMixin {
  final KernelWorldBuilder worldBuilder;

  _KernelSubtypeVisitor(this.worldBuilder);
}

class _KernelPotentialSubtypeVisitor extends PotentialSubtypeVisitor
    with _AbstractTypeRelationMixin {
  final KernelWorldBuilder worldBuilder;

  _KernelPotentialSubtypeVisitor(this.worldBuilder);
}
