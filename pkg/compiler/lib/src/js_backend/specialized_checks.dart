// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/elements.dart' show ElementEnvironment, JCommonElements;
import '../deferred_load/output_unit.dart' show OutputUnitData;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js_backend/interceptor_data.dart' show InterceptorData;
import '../js_model/js_world.dart' show JClosedWorld;
import '../universe/class_hierarchy.dart' show ClassHierarchy;

enum _Kind {
  isNull,
  isNotNull,
  isString,
  isBool,
  isNum,
  isInt,
  isArrayTop,
  isInstanceof,
}

class IsTestSpecialization {
  static const isNull = IsTestSpecialization._(_Kind.isNull);
  static const isNotNull = IsTestSpecialization._(_Kind.isNotNull);
  static const isString = IsTestSpecialization._(_Kind.isString);
  static const isBool = IsTestSpecialization._(_Kind.isBool);
  static const isNum = IsTestSpecialization._(_Kind.isNum);
  static const isInt = IsTestSpecialization._(_Kind.isInt);
  static const isArrayTop = IsTestSpecialization._(_Kind.isArrayTop);

  final _Kind _kind;
  final InterfaceType? _type;

  const IsTestSpecialization._(this._kind) : _type = null;

  const IsTestSpecialization._instanceof(InterfaceType type)
      : _kind = _Kind.isInstanceof,
        _type = type;

  bool get isInstanceof => _kind == _Kind.isInstanceof;

  InterfaceType get interfaceType {
    assert(_kind == _Kind.isInstanceof);
    return _type!;
  }
}

class SpecializedChecks {
  static IsTestSpecialization? findIsTestSpecialization(
      DartType dartType, MemberEntity compiland, JClosedWorld closedWorld) {
    if (dartType is LegacyType) {
      DartType base = dartType.baseType;
      // `Never*` accepts only `null`.
      if (base is NeverType) return IsTestSpecialization.isNull;
      // `Object*` is top and should be handled by constant folding.
      if (base.isObject) return null;
      return _findIsTestSpecialization(base, compiland, closedWorld);
    }
    return _findIsTestSpecialization(dartType, compiland, closedWorld);
  }

  static IsTestSpecialization? _findIsTestSpecialization(
      DartType dartType, MemberEntity compiland, JClosedWorld closedWorld) {
    if (dartType is InterfaceType) {
      ClassEntity element = dartType.element;
      JCommonElements commonElements = closedWorld.commonElements;

      if (element == commonElements.nullClass ||
          element == commonElements.jsNullClass) {
        return IsTestSpecialization.isNull;
      }

      if (element == commonElements.jsStringClass ||
          element == commonElements.stringClass) {
        return IsTestSpecialization.isString;
      }

      if (element == commonElements.jsBoolClass ||
          element == commonElements.boolClass) {
        return IsTestSpecialization.isBool;
      }

      if (element == commonElements.doubleClass ||
          element == commonElements.jsNumberClass ||
          element == commonElements.numClass) {
        return IsTestSpecialization.isNum;
      }

      if (element == commonElements.jsIntClass ||
          element == commonElements.intClass ||
          element == commonElements.jsUInt32Class ||
          element == commonElements.jsUInt31Class ||
          element == commonElements.jsPositiveIntClass) {
        return IsTestSpecialization.isInt;
      }

      DartTypes dartTypes = closedWorld.dartTypes;
      // Top types should be constant folded outside the specializer. This test
      // protects logic below.
      if (dartTypes.isTopType(dartType)) return null;

      ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
      if (!dartTypes.isSubtype(
          elementEnvironment.getClassInstantiationToBounds(element),
          dartType)) {
        return null;
      }

      if (element == commonElements.jsArrayClass) {
        return IsTestSpecialization.isArrayTop;
      }

      if (dartType.isObject) {
        assert(!dartTypes.isTopType(dartType)); // Checked above.
        return IsTestSpecialization.isNotNull;
      }

      ClassHierarchy classHierarchy = closedWorld.classHierarchy;
      InterceptorData interceptorData = closedWorld.interceptorData;
      OutputUnitData outputUnitData = closedWorld.outputUnitData;

      final topmost = closedWorld.getLubOfInstantiatedSubtypes(element);

      // No LUB means the test is always false, and should be constant folded
      // outside of this specializer.
      if (topmost == null) return null;

      if (classHierarchy.hasOnlySubclasses(topmost) &&
          !interceptorData.isInterceptedClass(topmost) &&
          outputUnitData.hasOnlyNonDeferredImportPathsToClass(
              compiland, topmost)) {
        assert(!dartType.isObject); // Checked above.
        return IsTestSpecialization._instanceof(
            elementEnvironment.getClassInstantiationToBounds(topmost));
      }

      // Two ideas for further consideration:
      //
      // 1. It might be profitable to know the type of the tested value - for
      // example, `Pattern` and `Comparable` are both interfaces that are
      // impemented by many classes and cannot be handled by any of the tricks
      // above. However, if we know the tested value is a `Pattern` then `is
      // Comparable` can be compiled as `is String`.
      //
      // 2. We could re-introduce type testing using the `$isFoo` property. The
      // Rti `_is` stubs use this property, but in a polymorphic manner.
      // Specialized stubs would be monomorphic in the property symbol, but they
      // still need to use `getInterceptor` (although this can be specialized
      // too).  Using the `$isFoo` property directly in the code would be most
      // beneficial when the interceptor is needed for other reasons (including
      // additional checks), otherwise it is just a more verbose version of
      // calling the specialized Rti stub.
    }

    return null;
  }

  static FunctionEntity? findAsCheck(DartType dartType,
      JCommonElements commonElements, bool useLegacySubtyping) {
    if (dartType is InterfaceType) {
      if (dartType.typeArguments.isNotEmpty) return null;
      return _findAsCheck(dartType.element, commonElements,
          nullable: false, legacy: useLegacySubtyping);
    }
    if (dartType is LegacyType) {
      DartType baseType = dartType.baseType;
      if (baseType is InterfaceType && baseType.typeArguments.isEmpty) {
        return _findAsCheck(baseType.element, commonElements,
            nullable: false, legacy: true);
      }
      return null;
    }
    if (dartType is NullableType) {
      DartType baseType = dartType.baseType;
      if (baseType is InterfaceType && baseType.typeArguments.isEmpty) {
        return _findAsCheck(baseType.element, commonElements,
            nullable: true, legacy: false);
      }
      return null;
    }
    return null;
  }

  /// Finds the method that implements the specialized check for a simple type.
  /// The specialized method will report a TypeError that includes a reported
  /// type.
  ///
  /// [nullable]: Find specialization for `element?`.
  /// [legacy]: Find specialization for non-nullable `element?` but with legacy
  /// semantics (accepting null).
  ///
  ///     element   options                           reported  accepts
  ///                                                 type      null
  ///
  ///     String    nullable: true   legacy: ---      String?   yes
  ///     String    nullable: false  legacy: true     String    yes
  ///     String    nullable: false  legacy: false    String    no
  ///
  static FunctionEntity? _findAsCheck(
      ClassEntity element, JCommonElements commonElements,
      {required bool nullable, required bool legacy}) {
    if (element == commonElements.jsStringClass ||
        element == commonElements.stringClass) {
      if (legacy) return commonElements.specializedAsStringLegacy;
      if (nullable) return commonElements.specializedAsStringNullable;
      return commonElements.specializedAsString;
    }

    if (element == commonElements.jsBoolClass ||
        element == commonElements.boolClass) {
      if (legacy) return commonElements.specializedAsBoolLegacy;
      if (nullable) return commonElements.specializedAsBoolNullable;
      return commonElements.specializedAsBool;
    }

    if (element == commonElements.doubleClass) {
      if (legacy) return commonElements.specializedAsDoubleLegacy;
      if (nullable) return commonElements.specializedAsDoubleNullable;
      return commonElements.specializedAsDouble;
    }

    if (element == commonElements.jsNumberClass ||
        element == commonElements.numClass) {
      if (legacy) return commonElements.specializedAsNumLegacy;
      if (nullable) return commonElements.specializedAsNumNullable;
      return commonElements.specializedAsNum;
    }

    if (element == commonElements.jsIntClass ||
        element == commonElements.intClass ||
        element == commonElements.jsUInt32Class ||
        element == commonElements.jsUInt31Class ||
        element == commonElements.jsPositiveIntClass) {
      if (legacy) return commonElements.specializedAsIntLegacy;
      if (nullable) return commonElements.specializedAsIntNullable;
      return commonElements.specializedAsInt;
    }

    return null;
  }
}
