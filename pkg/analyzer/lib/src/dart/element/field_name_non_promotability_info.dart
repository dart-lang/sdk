// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';

/// Information about why a single private name in a library is non-promotable.
///
/// This data structure is used as the value type for the map
/// [LibraryElementImpl.fieldNameNonPromotabilityInfo], for which the key is the
/// non-promotable private name. See the documentation for that getter for more
/// information.
class FieldNameNonPromotabilityInfo {
  /// The set of fields in the library with the given private name that are
  /// inherently non-promotable. These fields conflict with promotability of the
  /// given private name.
  final List<FieldElement> conflictingFields;

  /// The set of getters in the library with the given private name that are
  /// concrete. These getters conflict with promotability of the given private
  /// name.
  final List<PropertyAccessorElement> conflictingGetters;

  /// The set of concrete classes in the library that contain a getter with the
  /// given private name in their interface but not explicitly in their
  /// implementation (and hence implicitly contain a `noSuchMethod` forwarder
  /// for the getter). These implicit `noSuchMethod` forwarders conflict with
  /// promotability of the given private name.
  final List<InterfaceElement> conflictingNsmClasses;

  FieldNameNonPromotabilityInfo(
      {required this.conflictingFields,
      required this.conflictingGetters,
      required this.conflictingNsmClasses});
}
