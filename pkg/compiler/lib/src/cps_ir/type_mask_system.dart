// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.type_mask_system;

import '../closure.dart' show ClosureClassElement, Identifiers;
import '../common/names.dart' show Selectors, Identifiers;
import '../compiler.dart' as dart2js show Compiler;
import '../constants/constant_system.dart';
import '../constants/values.dart';
import '../dart_types.dart' as types;
import '../elements/elements.dart';
import '../io/source_information.dart' show SourceInformation;
import '../js_backend/js_backend.dart' show JavaScriptBackend;
import '../types/types.dart';
import '../types/constants.dart' show computeTypeMask;
import '../universe/universe.dart';
import '../world.dart' show World;

enum AbstractBool {
  True, False, Maybe, Nothing
}

class TypeMaskSystem {
  final TypesTask inferrer;
  final World classWorld;
  final JavaScriptBackend backend;

  TypeMask get dynamicType => inferrer.dynamicType;
  TypeMask get typeType => inferrer.typeType;
  TypeMask get functionType => inferrer.functionType;
  TypeMask get boolType => inferrer.boolType;
  TypeMask get intType => inferrer.intType;
  TypeMask get doubleType => inferrer.doubleType;
  TypeMask get numType => inferrer.numType;
  TypeMask get stringType => inferrer.stringType;
  TypeMask get listType => inferrer.listType;
  TypeMask get mapType => inferrer.mapType;
  TypeMask get nonNullType => inferrer.nonNullType;
  TypeMask get nullType => inferrer.nullType;
  TypeMask get extendableNativeListType => backend.extendableArrayType;

  TypeMask numStringBoolType;

  ClassElement get jsNullClass => backend.jsNullClass;

  // TODO(karlklose): remove compiler here.
  TypeMaskSystem(dart2js.Compiler compiler)
      : inferrer = compiler.typesTask,
        classWorld = compiler.world,
        backend = compiler.backend {

    // Build the number+string+bool type. To make containment tests more
    // inclusive, we use the num, String, bool types for this, not
    // the JSNumber, JSString, JSBool subclasses.
    TypeMask anyNum =
        new TypeMask.nonNullSubtype(classWorld.numClass, classWorld);
    TypeMask anyString =
        new TypeMask.nonNullSubtype(classWorld.stringClass, classWorld);
    TypeMask anyBool =
        new TypeMask.nonNullSubtype(classWorld.boolClass, classWorld);
    numStringBoolType =
        new TypeMask.unionOf(<TypeMask>[anyNum, anyString, anyBool],
            classWorld);
  }

  bool methodUsesReceiverArgument(FunctionElement function) {
    assert(backend.isInterceptedMethod(function));
    ClassElement clazz = function.enclosingClass.declaration;
    return clazz.isSubclassOf(backend.jsInterceptorClass) ||
           classWorld.isUsedAsMixin(clazz);
  }

  Element locateSingleElement(TypeMask mask, Selector selector) {
    return mask.locateSingleElement(selector, mask, classWorld.compiler);
  }

  ClassElement singleClass(TypeMask mask) {
    return mask.singleClass(classWorld);
  }

  bool needsNoSuchMethodHandling(TypeMask mask, Selector selector) {
    return mask.needsNoSuchMethodHandling(selector, classWorld);
  }

  TypeMask getReceiverType(MethodElement method) {
    assert(method.isInstanceMember);
    if (classWorld.isUsedAsMixin(method.enclosingClass.declaration)) {
      // If used as a mixin, the receiver could be any of the classes that mix
      // in the class, and these are not considered subclasses.
      // TODO(asgerf): Exclude the subtypes that only `implement` the class.
      return nonNullSubtype(method.enclosingClass);
    } else {
      return nonNullSubclass(method.enclosingClass);
    }
  }

  TypeMask getParameterType(ParameterElement parameter) {
    return inferrer.getGuaranteedTypeOfElement(parameter);
  }

  TypeMask getReturnType(FunctionElement function) {
    return inferrer.getGuaranteedReturnTypeOfElement(function);
  }

  TypeMask getInvokeReturnType(Selector selector, TypeMask mask) {
    return inferrer.getGuaranteedTypeOfSelector(selector, mask);
  }

  TypeMask getFieldType(FieldElement field) {
    return inferrer.getGuaranteedTypeOfElement(field);
  }

  TypeMask join(TypeMask a, TypeMask b) {
    return a.union(b, classWorld);
  }

  TypeMask getTypeOf(ConstantValue constant) {
    return computeTypeMask(inferrer.compiler, constant);
  }

  TypeMask nonNullExact(ClassElement element) {
    // The class world does not know about classes created by
    // closure conversion, so just treat those as a subtypes of Function.
    // TODO(asgerf): Maybe closure conversion should create a new ClassWorld?
    if (element.isClosure) return functionType;
    return new TypeMask.nonNullExact(element.declaration, classWorld);
  }

  TypeMask nonNullSubclass(ClassElement element) {
    if (element.isClosure) return functionType;
    return new TypeMask.nonNullSubclass(element.declaration, classWorld);
  }

  TypeMask nonNullSubtype(ClassElement element) {
    if (element.isClosure) return functionType;
    return new TypeMask.nonNullSubtype(element.declaration, classWorld);
  }

  bool isDefinitelyBool(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.nonNullable().containsOnlyBool(classWorld);
  }

  bool isDefinitelyNum(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.nonNullable().containsOnlyNum(classWorld);
  }

  bool isDefinitelyString(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.nonNullable().containsOnlyString(classWorld);
  }

  bool isDefinitelyNumStringBool(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return numStringBoolType.containsMask(t.nonNullable(), classWorld);
  }

  bool isDefinitelyNotNumStringBool(TypeMask t) {
    return areDisjoint(t, numStringBoolType);
  }

  /// True if all values of [t] are either integers or not numbers at all.
  ///
  /// This does not imply that the value is an integer, since most other values
  /// such as null are also not a non-integer double.
  bool isDefinitelyNotNonIntegerDouble(TypeMask t) {
    // Even though int is a subclass of double in the JS type system, we can
    // still check this with disjointness, because [doubleType] is the *exact*
    // double class, so this excludes things that are known to be instances of a
    // more specific class.
    // We currently exploit that there are no subclasses of double that are
    // not integers (e.g. there is no UnsignedDouble class or whatever).
    return areDisjoint(t, doubleType);
  }

  bool isDefinitelyInt(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.satisfies(backend.jsIntClass, classWorld);
  }

  bool isDefinitelyNativeList(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.nonNullable().satisfies(backend.jsArrayClass, classWorld);
  }

  bool isDefinitelyMutableNativeList(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.nonNullable().satisfies(backend.jsMutableArrayClass, classWorld);
  }

  bool isDefinitelyFixedNativeList(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.nonNullable().satisfies(backend.jsFixedArrayClass, classWorld);
  }

  bool isDefinitelyExtendableNativeList(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.nonNullable().satisfies(backend.jsExtendableArrayClass,
                                     classWorld);
  }

  bool isDefinitelyIndexable(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.nonNullable().satisfies(backend.jsIndexableClass, classWorld);
  }

  bool areDisjoint(TypeMask leftType, TypeMask rightType) {
    TypeMask intersection = leftType.intersection(rightType, classWorld);
    return intersection.isEmpty && !intersection.isNullable;
  }

  AbstractBool isSubtypeOf(TypeMask value,
                           types.DartType type,
                           {bool allowNull}) {
    assert(allowNull != null);
    if (type is types.DynamicType) {
      return AbstractBool.True;
    }
    if (type is types.InterfaceType) {
      TypeMask typeAsMask = allowNull
      ? new TypeMask.subtype(type.element, classWorld)
      : new TypeMask.nonNullSubtype(type.element, classWorld);
      if (areDisjoint(value, typeAsMask)) {
        // Disprove the subtype relation based on the class alone.
        return AbstractBool.False;
      }
      if (!type.treatAsRaw) {
        // If there are type arguments, we cannot prove the subtype relation,
        // because the type arguments are unknown on both the value and type.
        return AbstractBool.Maybe;
      }
      if (typeAsMask.containsMask(value, classWorld)) {
        // All possible values are contained in the set of allowed values.
        // Note that we exploit the fact that [typeAsMask] is an exact
        // representation of [type], not an approximation.
        return AbstractBool.True;
      }
      // The value is neither contained in the type, nor disjoint from the type.
      return AbstractBool.Maybe;
    }
    // TODO(asgerf): Support function types, and what else might be missing.
    return AbstractBool.Maybe;
  }

  /// Returns whether [type] is one of the falsy values: false, 0, -0, NaN,
  /// the empty string, or null.
  AbstractBool boolify(TypeMask type) {
    if (isDefinitelyNotNumStringBool(type) && !type.isNullable) {
      return AbstractBool.True;
    }
    return AbstractBool.Maybe;
  }

  AbstractBool strictBoolify(TypeMask type) {
    if (areDisjoint(type, boolType)) return AbstractBool.False;
    return AbstractBool.Maybe;
  }

  /// Create a type mask containing at least all subtypes of [type].
  TypeMask subtypesOf(types.DartType type) {
    if (type is types.InterfaceType) {
      ClassElement element = type.element;
      if (element.isObject) {
        return dynamicType;
      }
      if (element == classWorld.nullClass) {
        return nullType;
      }
      if (element == classWorld.stringClass) {
        return stringType;
      }
      if (element == classWorld.numClass ||
          element == classWorld.doubleClass) {
        return numType;
      }
      if (element == classWorld.intClass) {
        return intType;
      }
      if (element == classWorld.boolClass) {
        return boolType;
      }
      return new TypeMask.nonNullSubtype(element, classWorld);
    }
    if (type is types.FunctionType) {
      return functionType;
    }
    return dynamicType;
  }

  /// Returns a subset of [mask] containing at least the types
  /// that can respond to [selector] without throwing.
  TypeMask receiverTypeFor(Selector selector, TypeMask mask) {
    return classWorld.allFunctions.receiverType(selector, mask);
  }
}
