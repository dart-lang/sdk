// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.kernel.element_map;

/// Support for subtype checks of kernel based [DartType]s.
class _KernelDartTypes extends DartTypes {
  final KernelToElementMapBase elementMap;
  final SubtypeVisitor<DartType> subtypeVisitor;
  final PotentialSubtypeVisitor<DartType> potentialSubtypeVisitor;

  _KernelDartTypes(this.elementMap)
      : this.subtypeVisitor = new _KernelSubtypeVisitor(elementMap),
        this.potentialSubtypeVisitor =
            new _KernelPotentialSubtypeVisitor(elementMap);

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
  InterfaceType getThisType(ClassEntity cls) {
    return elementMap._getThisType(cls);
  }

  @override
  InterfaceType getSupertype(ClassEntity cls) {
    return elementMap._getSuperType(cls);
  }

  @override
  Iterable<InterfaceType> getSupertypes(ClassEntity cls) {
    return elementMap._getOrderedTypeSet(cls).supertypes;
  }

  @override
  Iterable<InterfaceType> getInterfaces(ClassEntity cls) {
    return elementMap._getInterfaces(cls);
  }

  @override
  InterfaceType asInstanceOf(InterfaceType type, ClassEntity cls) {
    return elementMap._asInstanceOf(type, cls);
  }

  @override
  DartType substByContext(DartType base, InterfaceType context) {
    return elementMap._substByContext(base, context);
  }

  @override
  FunctionType getCallType(InterfaceType type) {
    DartType callType = elementMap._getCallType(type);
    return callType is FunctionType ? callType : null;
  }

  @override
  void checkTypeVariableBounds(
      InterfaceType type,
      void checkTypeVariableBound(InterfaceType type, DartType typeArgument,
          TypeVariableType typeVariable, DartType bound)) {
    throw new UnimplementedError('_KernelDartTypes.checkTypeVariableBounds');
  }

  @override
  CommonElements get commonElements => elementMap.commonElements;
}

class _KernelOrderedTypeSetBuilder extends OrderedTypeSetBuilderBase {
  final KernelToElementMapBase elementMap;

  _KernelOrderedTypeSetBuilder(this.elementMap, ClassEntity cls)
      : super(cls,
            reporter: elementMap.reporter,
            objectType: elementMap.commonElements.objectType);

  InterfaceType getThisType(ClassEntity cls) {
    return elementMap._getThisType(cls);
  }

  InterfaceType substByContext(InterfaceType type, InterfaceType context) {
    return elementMap._substByContext(type, context);
  }

  int getHierarchyDepth(ClassEntity cls) {
    return elementMap._getHierarchyDepth(cls);
  }

  OrderedTypeSet getOrderedTypeSet(ClassEntity cls) {
    return elementMap._getOrderedTypeSet(cls);
  }
}

abstract class _AbstractTypeRelationMixin
    implements AbstractTypeRelation<DartType> {
  KernelToElementMapBase get elementMap;

  @override
  CommonElements get commonElements => elementMap.commonElements;

  @override
  DartType getTypeVariableBound(TypeVariableEntity element) {
    // TODO(redemption): Compute the bound.
    return commonElements.objectType;
  }

  @override
  FunctionType getCallType(InterfaceType type) {
    // TODO(redemption): Compute the call type.
    return elementMap._getCallType(type);
  }

  @override
  InterfaceType asInstanceOf(InterfaceType type, ClassEntity cls) {
    return elementMap._asInstanceOf(type, cls);
  }
}

class _KernelSubtypeVisitor extends SubtypeVisitor<DartType>
    with _AbstractTypeRelationMixin {
  final KernelToElementMapBase elementMap;

  _KernelSubtypeVisitor(this.elementMap);
}

class _KernelPotentialSubtypeVisitor extends PotentialSubtypeVisitor<DartType>
    with _AbstractTypeRelationMixin {
  final KernelToElementMapBase elementMap;

  _KernelPotentialSubtypeVisitor(this.elementMap);
}
