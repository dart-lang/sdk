// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common_elements.dart' show ElementEnvironment, JCommonElements;
import '../deferred_load.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js_backend/interceptor_data.dart' show InterceptorData;
import '../ssa/nodes.dart' show HGraph;
import '../universe/class_hierarchy.dart' show ClassHierarchy;
import '../world.dart' show JClosedWorld;

enum IsTestSpecialization {
  isNull,
  notNull,
  string,
  bool,
  num,
  int,
  arrayTop,
  instanceof,
}

class SpecializedChecks {
  static IsTestSpecialization findIsTestSpecialization(
      DartType dartType, HGraph graph, JClosedWorld closedWorld) {
    if (dartType is LegacyType) {
      DartType base = dartType.baseType;
      // `Never*` accepts only `null`.
      if (base is NeverType) return IsTestSpecialization.isNull;
      // `Object*` is top and should be handled by constant folding.
      if (base.isObject) return null;
      return _findIsTestSpecialization(base, graph, closedWorld);
    }
    return _findIsTestSpecialization(dartType, graph, closedWorld);
  }

  static IsTestSpecialization _findIsTestSpecialization(
      DartType dartType, HGraph graph, JClosedWorld closedWorld) {
    if (dartType is InterfaceType) {
      ClassEntity element = dartType.element;
      JCommonElements commonElements = closedWorld.commonElements;

      if (element == commonElements.nullClass ||
          element == commonElements.jsNullClass) {
        return IsTestSpecialization.isNull;
      }

      if (element == commonElements.jsStringClass ||
          element == commonElements.stringClass) {
        return IsTestSpecialization.string;
      }

      if (element == commonElements.jsBoolClass ||
          element == commonElements.boolClass) {
        return IsTestSpecialization.bool;
      }

      if (element == commonElements.jsDoubleClass ||
          element == commonElements.doubleClass ||
          element == commonElements.jsNumberClass ||
          element == commonElements.numClass) {
        return IsTestSpecialization.num;
      }

      if (element == commonElements.jsIntClass ||
          element == commonElements.intClass ||
          element == commonElements.jsUInt32Class ||
          element == commonElements.jsUInt31Class ||
          element == commonElements.jsPositiveIntClass) {
        return IsTestSpecialization.int;
      }

      DartTypes dartTypes = closedWorld.dartTypes;
      // Top types (here it could be Object in non-NNBD mode) should be constant
      // folded outside the specializer. This test protects logic below.
      if (dartTypes.isTopType(dartType)) return null;
      ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
      if (!dartTypes.isSubtype(
          elementEnvironment.getClassInstantiationToBounds(element),
          dartType)) {
        return null;
      }

      if (element == commonElements.jsArrayClass) {
        return IsTestSpecialization.arrayTop;
      }

      if (dartType.isObject) {
        assert(!dartTypes.isTopType(dartType)); // Checked above.
        return IsTestSpecialization.notNull;
      }

      ClassHierarchy classHierarchy = closedWorld.classHierarchy;
      InterceptorData interceptorData = closedWorld.interceptorData;
      OutputUnitData outputUnitData = closedWorld.outputUnitData;

      if (classHierarchy.hasOnlySubclasses(element) &&
          classHierarchy.isInstantiated(element) &&
          !interceptorData.isInterceptedClass(element) &&
          outputUnitData.hasOnlyNonDeferredImportPathsToClass(
              graph.element, element)) {
        assert(!dartType.isObject); // Checked above.
        return IsTestSpecialization.instanceof;
      }
    }
    return null;
  }

  static MemberEntity findAsCheck(DartType dartType,
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
  static MemberEntity _findAsCheck(
      ClassEntity element, JCommonElements commonElements,
      {bool nullable, bool legacy}) {
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

    if (element == commonElements.jsDoubleClass ||
        element == commonElements.doubleClass) {
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
