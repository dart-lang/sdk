// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Entity interfaces for modeling elements derived from Kernel IR.

import '../elements/entities.dart';

abstract class IndexedLibrary implements LibraryEntity {
  /// Library index used for fast lookup in [KernelToElementMapBase].
  int get libraryIndex;
}

abstract class IndexedClass implements ClassEntity {
  /// Class index used for fast lookup in [KernelToElementMapBase].
  int get classIndex;
}

abstract class IndexedMember implements MemberEntity {
  /// Member index used for fast lookup in [KernelToElementMapBase].
  int get memberIndex;
}

abstract class IndexedFunction implements IndexedMember, FunctionEntity {}

abstract class IndexedConstructor
    implements IndexedFunction, ConstructorEntity {}

abstract class IndexedField implements IndexedMember, FieldEntity {}

abstract class IndexedTypeVariable implements TypeVariableEntity {
  /// Type variable index used for fast lookup in [KernelToElementMapBase].
  int get typeVariableIndex;
}
