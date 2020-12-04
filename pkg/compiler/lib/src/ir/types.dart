// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common_elements.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../options.dart';
import '../ordered_typeset.dart';
import 'element_map.dart';

/// Support for subtype checks of kernel based [DartType]s.
class KernelDartTypes extends DartTypes {
  final IrToElementMap elementMap;
  final CompilerOptions _options;

  KernelDartTypes(this.elementMap, this._options);

  @override
  bool get useLegacySubtyping => _options.useLegacySubtyping;

  @override
  InterfaceType getThisType(ClassEntity cls) {
    return elementMap.getThisType(cls);
  }

  @override
  InterfaceType getSupertype(ClassEntity cls) {
    return elementMap.getSuperType(cls);
  }

  @override
  Iterable<InterfaceType> getSupertypes(ClassEntity cls) {
    return elementMap.getOrderedTypeSet(cls).supertypes;
  }

  @override
  Iterable<InterfaceType> getInterfaces(ClassEntity cls) {
    return elementMap.getInterfaces(cls);
  }

  @override
  InterfaceType asInstanceOf(InterfaceType type, ClassEntity cls) {
    return elementMap.asInstanceOf(type, cls);
  }

  @override
  DartType substByContext(DartType base, InterfaceType context) {
    return elementMap.substByContext(base, context);
  }

  @override
  FunctionType getCallType(InterfaceType type) {
    DartType callType = elementMap.getCallType(type);
    return callType is FunctionType ? callType : null;
  }

  @override
  void checkTypeVariableBounds<T>(
      T context,
      List<DartType> typeArguments,
      List<DartType> typeVariables,
      void checkTypeVariableBound(T context, DartType typeArgument,
          TypeVariableType typeVariable, DartType bound)) {
    assert(typeVariables.length == typeArguments.length);
    for (int index = 0; index < typeArguments.length; index++) {
      DartType typeArgument = typeArguments[index];
      TypeVariableType typeVariable = typeVariables[index];
      DartType bound = subst(typeArguments, typeVariables,
          elementMap.getTypeVariableBound(typeVariable.element));
      checkTypeVariableBound(context, typeArgument, typeVariable, bound);
    }
  }

  @override
  CommonElements get commonElements => elementMap.commonElements;

  @override
  DartType getTypeVariableBound(TypeVariableEntity element) {
    return elementMap.getTypeVariableBound(element);
  }

  @override
  List<Variance> getTypeVariableVariances(ClassEntity cls) =>
      elementMap.getTypeVariableVariances(cls);
}

class KernelOrderedTypeSetBuilder extends OrderedTypeSetBuilderBase {
  final IrToElementMap elementMap;

  KernelOrderedTypeSetBuilder(this.elementMap, ClassEntity cls) : super(cls);

  @override
  InterfaceType getThisType(ClassEntity cls) {
    return elementMap.getThisType(cls);
  }

  @override
  InterfaceType substByContext(InterfaceType type, InterfaceType context) {
    return elementMap.substByContext(type, context);
  }

  @override
  int getHierarchyDepth(ClassEntity cls) {
    return elementMap.getHierarchyDepth(cls);
  }

  @override
  OrderedTypeSet getOrderedTypeSet(ClassEntity cls) {
    return elementMap.getOrderedTypeSet(cls);
  }
}
