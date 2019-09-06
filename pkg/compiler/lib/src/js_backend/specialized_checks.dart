// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common_elements.dart' show JCommonElements;
import '../elements/entities.dart';
import '../elements/types.dart';

class SpecializedChecks {
  static MemberEntity findAsCheck(
      DartType dartType, bool isTypeError, JCommonElements commonElements) {
    if (dartType is InterfaceType) {
      if (dartType.typeArguments.isNotEmpty) return null;
      return _findAsCheck(dartType.element, commonElements,
          isTypeError: isTypeError, isNullable: true);
    }
    return null;
  }

  static MemberEntity _findAsCheck(
      ClassEntity element, JCommonElements commonElements,
      {bool isTypeError, bool isNullable}) {
    if (element == commonElements.jsStringClass ||
        element == commonElements.stringClass) {
      if (isNullable) {
        return isTypeError
            ? commonElements.specializedCheckStringNullable
            : commonElements.specializedAsStringNullable;
      }
      return null;
    }

    if (element == commonElements.jsBoolClass ||
        element == commonElements.boolClass) {
      if (isNullable) {
        return isTypeError
            ? commonElements.specializedCheckBoolNullable
            : commonElements.specializedAsBoolNullable;
      }
      return null;
    }

    if (element == commonElements.jsDoubleClass ||
        element == commonElements.doubleClass) {
      if (isNullable) {
        return isTypeError
            ? commonElements.specializedCheckDoubleNullable
            : commonElements.specializedAsDoubleNullable;
      }
      return null;
    }

    if (element == commonElements.jsNumberClass ||
        element == commonElements.numClass) {
      if (isNullable) {
        return isTypeError
            ? commonElements.specializedCheckNumNullable
            : commonElements.specializedAsNumNullable;
      }
      return null;
    }

    if (element == commonElements.jsIntClass ||
        element == commonElements.intClass ||
        element == commonElements.jsUInt32Class ||
        element == commonElements.jsUInt31Class ||
        element == commonElements.jsPositiveIntClass) {
      if (isNullable) {
        return isTypeError
            ? commonElements.specializedCheckIntNullable
            : commonElements.specializedAsIntNullable;
      }
      return null;
    }

    return null;
  }
}
