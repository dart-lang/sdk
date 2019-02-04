// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.types;

import 'package:kernel/ast.dart'
    show
        BottomType,
        DartType,
        DynamicType,
        FunctionType,
        InterfaceType,
        InvalidType,
        TypeParameterType,
        TypedefType,
        VoidType;

import 'class_hierarchy_builder.dart' show ClassHierarchyBuilder;

class Types {
  final ClassHierarchyBuilder hierarchy;

  const Types(this.hierarchy);

  /// Returns true if [s] is a subtype of [t].
  bool isSubtypeOfKernel(DartType s, DartType t) {
    if (s is BottomType) {
      return true;
    }
    if (s is InvalidType) {
      // InvalidType is also a bottom type.
      return true;
    }
    if (t is InvalidType) {
      return false;
    }
    if (t is DynamicType) {
      // A top type.
      return true;
    }
    if (t is VoidType) {
      // A top type.
      return true;
    }
    if (t is BottomType) {
      return false;
    }
    if (t is InterfaceType) {
      const IsInterfaceSubtypeOf relation = const IsInterfaceSubtypeOf();
      if (s is DynamicType) {
        return relation.isDynamicRelated(s, t, this);
      } else if (s is VoidType) {
        return relation.isVoidRelated(s, t, this);
      } else if (s is InterfaceType) {
        return relation.isInterfaceRelated(s, t, this);
      } else if (s is FunctionType) {
        return relation.isFunctionRelated(s, t, this);
      } else if (s is TypeParameterType) {
        return relation.isTypeParameterRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
      }
    } else if (t is FunctionType) {
      const IsFunctionSubtypeOf relation = const IsFunctionSubtypeOf();
      if (s is DynamicType) {
        return relation.isDynamicRelated(s, t, this);
      } else if (s is VoidType) {
        return relation.isVoidRelated(s, t, this);
      } else if (s is InterfaceType) {
        return relation.isInterfaceRelated(s, t, this);
      } else if (s is FunctionType) {
        return relation.isFunctionRelated(s, t, this);
      } else if (s is TypeParameterType) {
        return relation.isTypeParameterRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
      }
    } else if (t is TypeParameterType) {
      const IsTypeParameterSubtypeOf relation =
          const IsTypeParameterSubtypeOf();
      if (s is DynamicType) {
        return relation.isDynamicRelated(s, t, this);
      } else if (s is VoidType) {
        return relation.isVoidRelated(s, t, this);
      } else if (s is InterfaceType) {
        return relation.isInterfaceRelated(s, t, this);
      } else if (s is FunctionType) {
        return relation.isFunctionRelated(s, t, this);
      } else if (s is TypeParameterType) {
        return relation.isTypeParameterRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
      }
    } else if (t is TypedefType) {
      const IsTypedefSubtypeOf relation = const IsTypedefSubtypeOf();
      if (s is DynamicType) {
        return relation.isDynamicRelated(s, t, this);
      } else if (s is VoidType) {
        return relation.isVoidRelated(s, t, this);
      } else if (s is InterfaceType) {
        return relation.isInterfaceRelated(s, t, this);
      } else if (s is FunctionType) {
        return relation.isFunctionRelated(s, t, this);
      } else if (s is TypeParameterType) {
        return relation.isTypeParameterRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
      }
    } else {
      throw "Unhandled type: ${t.runtimeType}";
    }
    throw "Unhandled type combination: ${t.runtimeType} ${s.runtimeType}";
  }
}

abstract class TypeRelation<T extends DartType> {
  const TypeRelation();

  bool isDynamicRelated(DynamicType s, T t, Types types);

  bool isVoidRelated(VoidType s, T t, Types types);

  bool isInterfaceRelated(InterfaceType s, T t, Types types);

  bool isFunctionRelated(FunctionType s, T t, Types types);

  bool isTypeParameterRelated(TypeParameterType s, T t, Types types);

  bool isTypedefRelated(TypedefType s, T t, Types types);
}

class IsInterfaceSubtypeOf extends TypeRelation<InterfaceType> {
  const IsInterfaceSubtypeOf();

  // TODO(ahe): Remove this method.
  noSuchMethod(invocation) => super.noSuchMethod(invocation);
}

class IsFunctionSubtypeOf extends TypeRelation<FunctionType> {
  const IsFunctionSubtypeOf();

  // TODO(ahe): Remove this method.
  noSuchMethod(invocation) => super.noSuchMethod(invocation);
}

class IsTypeParameterSubtypeOf extends TypeRelation<TypeParameterType> {
  const IsTypeParameterSubtypeOf();

  // TODO(ahe): Remove this method.
  noSuchMethod(invocation) => super.noSuchMethod(invocation);
}

class IsTypedefSubtypeOf extends TypeRelation<TypedefType> {
  const IsTypedefSubtypeOf();

  // TODO(ahe): Remove this method.
  noSuchMethod(invocation) => super.noSuchMethod(invocation);
}
