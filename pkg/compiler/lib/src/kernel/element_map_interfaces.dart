// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../elements/entities.dart' show ClassEntity;
import '../elements/indexed.dart' show IndexedClass;
import '../elements/types.dart' show InterfaceType;

abstract class KernelToElementMapForClassHierarchy {
  ClassEntity? getSuperClass(ClassEntity cls);
  int getHierarchyDepth(IndexedClass cls);
  Iterable<InterfaceType> getSuperTypes(ClassEntity cls);
  ClassEntity? getAppliedMixin(IndexedClass cls);
  bool implementsFunction(IndexedClass cls);
}
