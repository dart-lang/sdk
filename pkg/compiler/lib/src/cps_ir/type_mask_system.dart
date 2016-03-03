// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.type_mask_system;

import '../common/names.dart' show Selectors, Identifiers;
import '../compiler.dart' as dart2js show Compiler;
import '../constants/values.dart';
import '../dart_types.dart' as types;
import '../elements/elements.dart';
import '../js_backend/backend_helpers.dart' show BackendHelpers;
import '../js_backend/js_backend.dart' show JavaScriptBackend;
import '../types/abstract_value_domain.dart';
import '../types/types.dart';
import '../types/constants.dart' show computeTypeMask;
import '../universe/selector.dart' show Selector;
import '../world.dart' show World;
import '../closure.dart' show ClosureFieldElement, BoxLocal, TypeVariableLocal;

class TypeMaskSystem implements AbstractValueDomain {
  final TypesTask inferrer;
  final World classWorld;
  final JavaScriptBackend backend;

  TypeMask _numStringBoolType;
  TypeMask _fixedLengthType;
  TypeMask _interceptorType;
  TypeMask _interceptedTypes; // Does not include null.

  TypeMask __indexableTypeTest;

  // The full type of a constant (e.g. a ContainerTypeMask) is not available on
  // the constant. Type inference flows the type to some place where it is used,
  // e.g. a parameter. For constant values that are the value of static const
  // fields we need to remember the association.
  final Map<ConstantValue, TypeMask> _constantMasks =
      <ConstantValue, TypeMask>{};

  @override
  TypeMask get dynamicType => inferrer.dynamicType;

  @override
  TypeMask get typeType => inferrer.typeType;

  @override
  TypeMask get functionType => inferrer.functionType;

  @override
  TypeMask get boolType => inferrer.boolType;

  @override
  TypeMask get intType => inferrer.intType;

  @override
  TypeMask get doubleType => inferrer.doubleType;

  @override
  TypeMask get numType => inferrer.numType;

  @override
  TypeMask get stringType => inferrer.stringType;

  @override
  TypeMask get listType => inferrer.listType;

  @override
  TypeMask get mapType => inferrer.mapType;

  @override
  TypeMask get nonNullType => inferrer.nonNullType;

  @override
  TypeMask get nullType => inferrer.nullType;

  @override
  TypeMask get extendableArrayType => backend.extendableArrayType;

  @override
  TypeMask get fixedArrayType => backend.fixedArrayType;

  @override
  TypeMask get arrayType =>
      new TypeMask.nonNullSubclass(helpers.jsArrayClass, classWorld);

  @override
  TypeMask get uint31Type => inferrer.uint31Type;

  @override
  TypeMask get uint32Type => inferrer.uint32Type;

  @override
  TypeMask get uintType => inferrer.positiveIntType;

  @override
  TypeMask get numStringBoolType {
    if (_numStringBoolType == null) {
      // Build the number+string+bool type. To make containment tests more
      // inclusive, we use the num, String, bool types for this, not
      // the JSNumber, JSString, JSBool subclasses.
      TypeMask anyNum =
          new TypeMask.nonNullSubtype(classWorld.numClass, classWorld);
      TypeMask anyString =
          new TypeMask.nonNullSubtype(classWorld.stringClass, classWorld);
      TypeMask anyBool =
          new TypeMask.nonNullSubtype(classWorld.boolClass, classWorld);
      _numStringBoolType =
          new TypeMask.unionOf(<TypeMask>[anyNum, anyString, anyBool],
              classWorld);
    }
    return _numStringBoolType;
  }

  @override
  TypeMask get fixedLengthType {
    if (_fixedLengthType == null) {
      List<TypeMask> fixedLengthTypes =
          <TypeMask>[stringType, backend.fixedArrayType];
      if (classWorld.isInstantiated(helpers.typedArrayClass)) {
        fixedLengthTypes.add(nonNullSubclass(helpers.typedArrayClass));
      }
      _fixedLengthType = new TypeMask.unionOf(fixedLengthTypes, classWorld);
    }
    return _fixedLengthType;
  }

  @override
  TypeMask get interceptorType {
    if (_interceptorType == null) {
      _interceptorType =
        new TypeMask.nonNullSubtype(helpers.jsInterceptorClass, classWorld);
    }
    return _interceptorType;
  }

  @override
  TypeMask get interceptedTypes { // Does not include null.
    if (_interceptedTypes == null) {
      // We redundantly include subtypes of num/string/bool as intercepted
      // types, because the type system does not infer that their
      // implementations are all subclasses of Interceptor.
      _interceptedTypes = new TypeMask.unionOf(
          <TypeMask>[interceptorType, numStringBoolType], classWorld);
    }
    return _interceptedTypes;
  }

  TypeMask get _indexableTypeTest {
    if (__indexableTypeTest == null) {
      // Make a TypeMask containing Indexable and (redundantly) subtypes of
      // string because the type inference does not infer that all strings are
      // indexables.
      TypeMask indexable =
          new TypeMask.nonNullSubtype(helpers.jsIndexableClass, classWorld);
      TypeMask anyString =
          new TypeMask.nonNullSubtype(classWorld.stringClass, classWorld);
      __indexableTypeTest = new TypeMask.unionOf(
          <TypeMask>[indexable, anyString],
          classWorld);
    }
    return __indexableTypeTest;
  }

  ClassElement get jsNullClass => helpers.jsNullClass;

  BackendHelpers get helpers => backend.helpers;

  // TODO(karlklose): remove compiler here.
  TypeMaskSystem(dart2js.Compiler compiler)
      : inferrer = compiler.typesTask,
        classWorld = compiler.world,
        backend = compiler.backend {
  }

  @override
  bool methodIgnoresReceiverArgument(FunctionElement function) {
    assert(backend.isInterceptedMethod(function));
    ClassElement clazz = function.enclosingClass.declaration;
    return !clazz.isSubclassOf(helpers.jsInterceptorClass) &&
           !classWorld.isUsedAsMixin(clazz);
  }

  @override
  bool targetIgnoresReceiverArgument(TypeMask type, Selector selector) {
    // Check if any of the possible targets depend on the extra receiver
    // argument. Mixins do this, and tear-offs always needs the extra receiver
    // argument because BoundClosure uses it for equality and hash code.
    // TODO(15933): Make automatically generated property extraction
    // closures work with the dummy receiver optimization.
    bool needsReceiver(Element target) {
      if (target is! FunctionElement) return false;
      FunctionElement function = target;
      return selector.isGetter && !function.isGetter ||
             !methodIgnoresReceiverArgument(function);
    }
    return !classWorld.allFunctions.filter(selector, type).any(needsReceiver);
  }

  @override
  Element locateSingleElement(TypeMask mask, Selector selector) {
    return mask.locateSingleElement(selector, mask, classWorld.compiler);
  }

  @override
  ClassElement singleClass(TypeMask mask) {
    return mask.singleClass(classWorld);
  }

  @override
  bool needsNoSuchMethodHandling(TypeMask mask, Selector selector) {
    return mask.needsNoSuchMethodHandling(selector, classWorld);
  }

  @override
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

  @override
  TypeMask getParameterType(ParameterElement parameter) {
    return inferrer.getGuaranteedTypeOfElement(parameter);
  }

  @override
  TypeMask getReturnType(FunctionElement function) {
    return inferrer.getGuaranteedReturnTypeOfElement(function);
  }

  @override
  TypeMask getInvokeReturnType(Selector selector, TypeMask mask) {
    TypeMask result = inferrer.getGuaranteedTypeOfSelector(selector, mask);
    // Tearing off .call from a function returns the function itself.
    if (selector.isGetter &&
        selector.name == Identifiers.call &&
        !areDisjoint(functionType, mask)) {
      result = join(result, functionType);
    }
    return result;
  }

  @override
  TypeMask getFieldType(FieldElement field) {
    if (field is ClosureFieldElement) {
      // The type inference does not report types for all closure fields.
      // Box fields are never null.
      if (field.local is BoxLocal) return nonNullType;
      // Closure fields for type variables contain the internal representation
      // of the type (which can be null), not the Type object.
      if (field.local is TypeVariableLocal) return dynamicType;
    }
    return inferrer.getGuaranteedTypeOfElement(field);
  }

  @override
  TypeMask join(TypeMask a, TypeMask b) {
    return a.union(b, classWorld);
  }

  @override
  TypeMask intersection(TypeMask a, TypeMask b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.intersection(b, classWorld);
  }

  void associateConstantValueWithElement(ConstantValue constant,
                                         Element element) {
    // TODO(25093): Replace this code with an approach that works for anonymous
    // constants and non-constant literals.
    if (constant is ListConstantValue || constant is MapConstantValue) {
      // Inferred type is usually better (e.g. a ContainerTypeMask) but is
      // occasionally less general.
      TypeMask computed = computeTypeMask(inferrer.compiler, constant);
      TypeMask inferred = inferrer.getGuaranteedTypeOfElement(element);
      TypeMask best = intersection(inferred, computed);
      assert(!best.isEmptyOrNull);
      _constantMasks[constant] = best;
    }
  }

  @override
  TypeMask getTypeOf(ConstantValue constant) {
    return _constantMasks[constant] ??
           computeTypeMask(inferrer.compiler, constant);
  }

  @override
  ConstantValue getConstantOf(TypeMask mask) {
    if (!mask.isValue) return null;
    if (mask.isNullable) return null;  // e.g. 'true or null'.
    ValueTypeMask valueMask = mask;
    if (valueMask.value.isBool) return valueMask.value;
    // TODO(sra): Consider other values. Be careful with large strings.
    return null;
  }

  @override
  TypeMask nonNullExact(ClassElement element) {
    // TODO(johnniwinther): I don't think the follow is valid anymore.
    // The class world does not know about classes created by
    // closure conversion, so just treat those as a subtypes of Function.
    // TODO(asgerf): Maybe closure conversion should create a new ClassWorld?
    if (element.isClosure) return functionType;
    return new TypeMask.nonNullExact(element.declaration, classWorld);
  }

  @override
  TypeMask nonNullSubclass(ClassElement element) {
    if (element.isClosure) return functionType;
    return new TypeMask.nonNullSubclass(element.declaration, classWorld);
  }

  @override
  TypeMask nonNullSubtype(ClassElement element) {
    if (element.isClosure) return functionType;
    return new TypeMask.nonNullSubtype(element.declaration, classWorld);
  }

  @override
  bool isDefinitelyBool(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.nonNullable().containsOnlyBool(classWorld);
  }

  @override
  bool isDefinitelyNum(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.nonNullable().containsOnlyNum(classWorld);
  }

  @override
  bool isDefinitelyString(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.nonNullable().containsOnlyString(classWorld);
  }

  @override
  bool isDefinitelyNumStringBool(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return numStringBoolType.containsMask(t.nonNullable(), classWorld);
  }

  @override
  bool isDefinitelyNotNumStringBool(TypeMask t) {
    return areDisjoint(t, numStringBoolType);
  }

  /// True if all values of [t] are either integers or not numbers at all.
  ///
  /// This does not imply that the value is an integer, since most other values
  /// such as null are also not a non-integer double.
  @override
  bool isDefinitelyNotNonIntegerDouble(TypeMask t) {
    // Even though int is a subclass of double in the JS type system, we can
    // still check this with disjointness, because [doubleType] is the *exact*
    // double class, so this excludes things that are known to be instances of a
    // more specific class.
    // We currently exploit that there are no subclasses of double that are
    // not integers (e.g. there is no UnsignedDouble class or whatever).
    return areDisjoint(t, doubleType);
  }

  @override
  bool isDefinitelyNonNegativeInt(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    // The JSPositiveInt class includes zero, despite the name.
    return t.satisfies(helpers.jsPositiveIntClass, classWorld);
  }

  @override
  bool isDefinitelyInt(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.nonNullable().containsOnlyInt(classWorld);
  }

  @override
  bool isDefinitelyUint31(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.satisfies(helpers.jsUInt31Class, classWorld);
  }

  @override
  bool isDefinitelyUint32(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.satisfies(helpers.jsUInt32Class, classWorld);
  }

  @override
  bool isDefinitelyUint(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.satisfies(helpers.jsPositiveIntClass, classWorld);
  }

  @override
  bool isDefinitelyArray(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.nonNullable().satisfies(helpers.jsArrayClass, classWorld);
  }

  @override
  bool isDefinitelyMutableArray(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.nonNullable().satisfies(helpers.jsMutableArrayClass, classWorld);
  }

  @override
  bool isDefinitelyFixedArray(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.nonNullable().satisfies(helpers.jsFixedArrayClass, classWorld);
  }

  @override
  bool isDefinitelyExtendableArray(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.nonNullable().satisfies(helpers.jsExtendableArrayClass,
                                     classWorld);
  }

  @override
  bool isDefinitelyIndexable(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return _indexableTypeTest.containsMask(t.nonNullable(), classWorld);
  }

  @override
  bool isDefinitelyMutableIndexable(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.nonNullable().satisfies(helpers.jsMutableIndexableClass,
        classWorld);
  }

  @override
  bool isDefinitelyFixedLengthIndexable(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return fixedLengthType.containsMask(t.nonNullable(), classWorld);
  }

  @override
  bool isDefinitelyIntercepted(TypeMask t, {bool allowNull}) {
    assert(allowNull != null);
    if (!allowNull && t.isNullable) return false;
    return interceptedTypes.containsMask(t.nonNullable(), classWorld);
  }

  @override
  bool isDefinitelySelfInterceptor(TypeMask t, {bool allowNull: false}) {
    assert(allowNull != null);
    if (!allowNull && t.isNullable) return false;
    return areDisjoint(t, interceptorType);
  }

  /// Given a class from the interceptor hierarchy, returns a [TypeMask]
  /// matching all values with that interceptor (or a subtype thereof).
  @override
  TypeMask getInterceptorSubtypes(ClassElement class_) {
    if (class_ == helpers.jsInterceptorClass) {
      return interceptorType.nullable();
    } else if (class_ == helpers.jsNullClass) {
      return nullType;
    } else {
      return nonNullSubclass(class_);
    }
  }

  @override
  bool areDisjoint(TypeMask leftType, TypeMask rightType) =>
      leftType.isDisjoint(rightType, classWorld);

  @override
  bool isMorePreciseOrEqual(TypeMask t1, TypeMask t2) {
    return t2.containsMask(t1, classWorld);
  }

  @override
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
  @override
  AbstractBool boolify(TypeMask type) {
    if (isDefinitelyNotNumStringBool(type) && !type.isNullable) {
      return AbstractBool.True;
    }
    return AbstractBool.Maybe;
  }

  @override
  AbstractBool strictBoolify(TypeMask type) {
    if (areDisjoint(type, boolType)) return AbstractBool.False;
    return AbstractBool.Maybe;
  }

  /// Create a type mask containing at least all subtypes of [type].
  @override
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
  @override
  TypeMask receiverTypeFor(Selector selector, TypeMask mask) {
    return classWorld.allFunctions.receiverType(selector, mask);
  }

  /// The result of an index operation on something of [type], or the dynamic
  /// type if unknown.
  @override
  TypeMask elementTypeOfIndexable(TypeMask type) {
    if (type is UnionTypeMask) {
      return new TypeMask.unionOf(
          type.disjointMasks.map(elementTypeOfIndexable), classWorld);
    }
    if (type is ContainerTypeMask) {
      return type.elementType;
    }
    if (isDefinitelyString(type)) {
      return stringType;
    }
    if (type.satisfies(helpers.jsIndexingBehaviorInterface, classWorld)) {
      return getInvokeReturnType(new Selector.index(), type);
    }
    return dynamicType;
  }

  /// The length of something of [type], or `null` if unknown.
  @override
  int getContainerLength(TypeMask type) {
    if (type is ContainerTypeMask) {
      return type.length;
    } else {
      return null;
    }
  }

  /// Returns the type of the entry at a given index, `null` if unknown.
  TypeMask indexWithConstant(TypeMask container, ConstantValue indexValue) {
    if (container is DictionaryTypeMask) {
      if (indexValue is StringConstantValue) {
        String key = indexValue.primitiveValue.slowToString();
        TypeMask result = container.typeMap[key];
        if (result != null) return result;
      }
    }
    if (container is ContainerTypeMask) {
      return container.elementType;
    }
    return null;
  }
}
