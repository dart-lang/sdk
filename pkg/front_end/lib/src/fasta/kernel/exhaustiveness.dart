// Copyright (c) 2022 the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

bool computeIsAlwaysExhaustiveType(DartType type, CoreTypes coreTypes) {
  return type.accept1(const ExhaustiveDartTypeVisitor(), coreTypes);
}

class ExhaustiveDartTypeVisitor implements DartTypeVisitor1<bool, CoreTypes> {
  const ExhaustiveDartTypeVisitor();

  @override
  bool defaultDartType(DartType type, CoreTypes coreTypes) {
    throw new UnsupportedError('Unsupported type $type');
  }

  @override
  bool visitDynamicType(DynamicType type, CoreTypes coreTypes) {
    return false;
  }

  @override
  bool visitExtensionType(ExtensionType type, CoreTypes coreTypes) {
    return false;
  }

  @override
  bool visitFunctionType(FunctionType type, CoreTypes coreTypes) {
    return false;
  }

  @override
  bool visitFutureOrType(FutureOrType type, CoreTypes coreTypes) {
    // TODO(johnniwinther): Why? This doesn't work if the value is a Future.
    return type.typeArgument.accept1(this, coreTypes);
  }

  @override
  bool visitInlineType(InlineType type, CoreTypes coreTypes) {
    return type.instantiatedRepresentationType.accept1(this, coreTypes);
  }

  @override
  bool visitInterfaceType(InterfaceType type, CoreTypes coreTypes) {
    if (type.classNode == coreTypes.boolClass) {
      return true;
    } else if (type.classNode.isEnum) {
      return true;
    } else if (type.classNode.isSealed) {
      return true;
    } else {
      return false;
    }
  }

  @override
  bool visitIntersectionType(IntersectionType type, CoreTypes coreTypes) {
    // TODO(johnniwinther): Why don't we use the bound?
    return false;
  }

  @override
  bool visitInvalidType(InvalidType type, CoreTypes coreTypes) {
    return false;
  }

  @override
  bool visitNeverType(NeverType type, CoreTypes coreTypes) {
    return false;
  }

  @override
  bool visitNullType(NullType type, CoreTypes coreTypes) {
    return true;
  }

  @override
  bool visitRecordType(RecordType type, CoreTypes coreTypes) {
    for (DartType positional in type.positional) {
      if (!positional.accept1(this, coreTypes)) {
        return false;
      }
    }
    for (NamedType named in type.named) {
      if (!named.type.accept1(this, coreTypes)) {
        return false;
      }
    }
    return true;
  }

  @override
  bool visitTypeParameterType(TypeParameterType type, CoreTypes coreTypes) {
    // TODO(johnniwinther): Why don't we use the bound?
    return false;
  }

  @override
  bool visitTypedefType(TypedefType type, CoreTypes coreTypes) {
    return type.unalias.accept1(this, coreTypes);
  }

  @override
  bool visitVoidType(VoidType type, CoreTypes coreTypes) {
    return false;
  }
}
