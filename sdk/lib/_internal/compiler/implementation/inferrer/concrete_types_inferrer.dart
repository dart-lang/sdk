// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library concrete_types_inferrer;

import 'dart:collection' show Queue, IterableBase;
import '../native_handler.dart' as native;
import '../dart2jslib.dart' hide Selector, TypedSelector;
import '../dart_types.dart' show DartType, TypeKind;
import '../elements/elements.dart';
import '../tree/tree.dart';
import '../universe/universe.dart';
import '../util/util.dart';

import 'inferrer_visitor.dart';
import '../types/types.dart' show TypeMask, FlatTypeMask, UnionTypeMask,
                                  TypesInferrer;
import 'simple_types_inferrer.dart';

/**
 * A singleton concrete type. More precisely, a [BaseType] is one of the
 * following:
 *
 *   - a non-asbtract class like [:int:] or [:Uri:] (but not [:List:])
 *   - the null base type
 *   - the unknown base type
 */
abstract class BaseType {
  bool isClass();
  bool isUnknown();
  bool isNull();
}

/**
 * A non-asbtract class like [:int:] or [:Uri:] (but not [:List:]).
 */
class ClassBaseType implements BaseType {
  final ClassElement element;

  ClassBaseType(this.element);

  bool operator ==(var other) {
    if (identical(this, other)) return true;
    if (other is! ClassBaseType) return false;
    return element == other.element;
  }
  int get hashCode => element.hashCode;
  String toString() {
    return element == null ? 'toplevel' : element.name;
  }
  bool isClass() => true;
  bool isUnknown() => false;
  bool isNull() => false;
}

/**
 * The unknown base type.
 */
class UnknownBaseType implements BaseType {
  const UnknownBaseType();
  bool operator ==(BaseType other) => other is UnknownBaseType;
  int get hashCode => 0;
  bool isClass() => false;
  bool isUnknown() => true;
  bool isNull() => false;
  toString() => "unknown";
}

/**
 * The null base type.
 */
class NullBaseType implements BaseType {
  const NullBaseType();
  bool operator ==(BaseType other) => identical(other, this);
  int get hashCode => 1;
  bool isClass() => false;
  bool isUnknown() => false;
  bool isNull() => true;
  toString() => "null";
}

/**
 * An immutable set of base types like [:{int, bool}:], or the unknown concrete
 * type.
 */
abstract class ConcreteType {
  ConcreteType();

  factory ConcreteType.empty(int maxConcreteTypeSize,
                             BaseTypes classBaseTypes) {
    return new UnionType(maxConcreteTypeSize, classBaseTypes,
                         new Set<BaseType>());
  }

  /**
   * The singleton constituted of the unknown base type is the unknown concrete
   * type.
   */
  factory ConcreteType.singleton(int maxConcreteTypeSize,
                                 BaseTypes classBaseTypes,
                                 BaseType baseType) {
    if (baseType.isUnknown() || maxConcreteTypeSize < 1) {
      return const UnknownConcreteType();
    }
    Set<BaseType> singletonSet = new Set<BaseType>();
    singletonSet.add(baseType);
    return new UnionType(maxConcreteTypeSize, classBaseTypes, singletonSet);
  }

  factory ConcreteType.unknown() {
    return const UnknownConcreteType();
  }

  ConcreteType union(ConcreteType other);
  ConcreteType intersection(ConcreteType other);
  ConcreteType refine(Selector selector, Compiler compiler);
  bool isUnknown();
  bool isEmpty();
  Set<BaseType> get baseTypes;

  /**
   * Returns the unique element of [:this:] if [:this:] is a singleton, null
   * otherwise.
   */
  ClassElement getUniqueType();
}

/**
 * The unkown concrete type: it is absorbing for the union.
 */
class UnknownConcreteType implements ConcreteType {
  const UnknownConcreteType();
  bool isUnknown() => true;
  bool isEmpty() => false;
  bool operator ==(ConcreteType other) => identical(this, other);
  Set<BaseType> get baseTypes =>
      new Set<BaseType>.from([const UnknownBaseType()]);
  int get hashCode => 0;
  ConcreteType union(ConcreteType other) => this;
  ConcreteType intersection(ConcreteType other) => other;
  ConcreteType refine(Selector selector, Compiler compiler) => this;
  ClassElement getUniqueType() => null;
  toString() => "unknown";
}

/**
 * An immutable set of base types, like [: {int, bool} :].
 */
class UnionType implements ConcreteType {
  final int maxConcreteTypeSize;
  final BaseTypes classBaseTypes;

  final Set<BaseType> baseTypes;

  /**
   * The argument should NOT be mutated later. Do not call directly, use
   * ConcreteType.singleton instead.
   */
  UnionType(this.maxConcreteTypeSize, this.classBaseTypes, this.baseTypes);

  bool isUnknown() => false;
  bool isEmpty() => baseTypes.isEmpty;

  bool operator ==(ConcreteType other) {
    if (other is! UnionType) return false;
    if (baseTypes.length != other.baseTypes.length) return false;
    return baseTypes.containsAll(other.baseTypes);
  }

  int get hashCode {
    int result = 1;
    for (final baseType in baseTypes) {
      result = 31 * result + baseType.hashCode;
    }
    return result;
  }

  ConcreteType _simplify(Set<BaseType> baseTypes) {
    // normalize all flavors of ints to int
    // TODO(polux): handle different ints better
    if (baseTypes.contains(classBaseTypes.uint31Type)) {
      baseTypes.remove(classBaseTypes.uint31Type);
      baseTypes.add(classBaseTypes.intBaseType);
    }
    if (baseTypes.contains(classBaseTypes.uint32Type)) {
      baseTypes.remove(classBaseTypes.uint32Type);
      baseTypes.add(classBaseTypes.intBaseType);
    }
    if (baseTypes.contains(classBaseTypes.positiveIntType)) {
      baseTypes.remove(classBaseTypes.positiveIntType);
      baseTypes.add(classBaseTypes.intBaseType);
    }
    // normalize {int, float}, {int, num} or {float, num} into num
    // TODO(polux): generalize this to all types when we extend the concept of
    //     "concrete type" to other abstract classes than num
    if (baseTypes.contains(classBaseTypes.numBaseType) ||
        (baseTypes.contains(classBaseTypes.intBaseType)
            && baseTypes.contains(classBaseTypes.doubleBaseType))) {
      baseTypes.remove(classBaseTypes.intBaseType);
      baseTypes.remove(classBaseTypes.doubleBaseType);
      baseTypes.add(classBaseTypes.numBaseType);
    }

    // widen big types to dynamic
    return baseTypes.length > maxConcreteTypeSize
        ? const UnknownConcreteType()
        : new UnionType(maxConcreteTypeSize, classBaseTypes, baseTypes);
  }

  ConcreteType union(ConcreteType other) {
    if (other.isUnknown()) {
      return const UnknownConcreteType();
    }
    UnionType otherUnion = other;  // cast
    Set<BaseType> newBaseTypes = new Set<BaseType>.from(baseTypes);
    newBaseTypes.addAll(otherUnion.baseTypes);
    return _simplify(newBaseTypes);
  }

  ConcreteType intersection(ConcreteType other) {
    if (other.isUnknown()) {
      return this;
    }
    Set<BaseType> thisBaseTypes = new Set<BaseType>.from(baseTypes);
    Set<BaseType> otherBaseTypes = new Set<BaseType>.from(other.baseTypes);
    return _simplify(thisBaseTypes.intersection(otherBaseTypes));
  }

  ConcreteType refine(Selector selector, Compiler compiler) {
    Set<BaseType> newBaseTypes = new Set<BaseType>();
    for (BaseType baseType in baseTypes) {
      if (baseType.isClass()) {
        ClassBaseType classBaseType = baseType;
        if (classBaseType.element.lookupSelector(selector) != null) {
          newBaseTypes.add(baseType);
        }
      } else {
        newBaseTypes.add(baseType);
      }
    }
    return _simplify(newBaseTypes);
  }

  ClassElement getUniqueType() {
    if (baseTypes.length == 1) {
      var iterator = baseTypes.iterator;
      iterator.moveNext();
      BaseType uniqueBaseType = iterator.current;
      if (uniqueBaseType.isClass()) {
        ClassBaseType uniqueClassType = uniqueBaseType;
        return uniqueClassType.element;
      }
    }
    return null;
  }

  String toString() => baseTypes.toString();
}

class ConcreteTypeSystem extends TypeSystem<ConcreteType> {
  final Compiler compiler;
  final ConcreteTypesInferrer inferrer;
  final BaseTypes baseTypes;

  final ConcreteType nullType;
  final ConcreteType _intType;
  final ConcreteType _uint31Type;
  final ConcreteType _uint32Type;
  final ConcreteType _positiveIntType;
  final ConcreteType _doubleType;
  final ConcreteType _numType;
  final ConcreteType _boolType;
  final ConcreteType _functionType;
  final ConcreteType _listType;
  final ConcreteType _constListType;
  final ConcreteType _fixedListType;
  final ConcreteType _growableListType;
  final ConcreteType _mapType;
  final ConcreteType _constMapType;
  final ConcreteType _stringType;

  final ConcreteType dynamicType;
  final ConcreteType typeType;
  final ConcreteType nonNullEmptyType;

  ConcreteTypeSystem.internal(ConcreteTypesInferrer inferrer,
                              BaseTypes baseTypes,
                              ConcreteType singleton(BaseType baseType))
      : this.compiler = inferrer.compiler
      , this.inferrer = inferrer
      , this.baseTypes = baseTypes
      , this._constListType = singleton(baseTypes.constMapBaseType)
      , this._constMapType = singleton(baseTypes.constMapBaseType)
      , this._doubleType = singleton(baseTypes.doubleBaseType)
      , this._fixedListType = singleton(baseTypes.fixedListBaseType)
      , this._functionType = singleton(baseTypes.functionBaseType)
      , this._growableListType = singleton(baseTypes.growableListBaseType)
      , this._intType = singleton(baseTypes.intBaseType)
      , this._listType = singleton(baseTypes.listBaseType)
      , this._mapType = singleton(baseTypes.mapBaseType)
      , this._numType = singleton(baseTypes.numBaseType)
      , this._boolType = singleton(baseTypes.boolBaseType)
      , this._stringType = singleton(baseTypes.stringBaseType)
      , this.typeType = singleton(baseTypes.typeBaseType)
      , this.dynamicType = const UnknownConcreteType()
      , this.nullType = singleton(const NullBaseType())
      , this.nonNullEmptyType = new ConcreteType.empty(
          inferrer.compiler.maxConcreteTypeSize, baseTypes)
      // TODO(polux): have better types here
      , this._uint31Type = singleton(baseTypes.intBaseType)
      , this._uint32Type = singleton(baseTypes.intBaseType)
      , this._positiveIntType = singleton(baseTypes.intBaseType);

  factory ConcreteTypeSystem(ConcreteTypesInferrer inferrer) {
    Compiler compiler = inferrer.compiler;
    BaseTypes baseTypes = new BaseTypes(compiler);
    return new ConcreteTypeSystem.internal(
        inferrer,
        baseTypes,
        (BaseType baseType) => new ConcreteType.singleton(
            compiler.maxConcreteTypeSize, baseTypes, baseType));
  }

  @override
  ConcreteType get intType {
    inferrer.augmentSeenClasses(compiler.backend.intImplementation);
    return _intType;
  }

  @override
  ConcreteType get uint31Type {
    inferrer.augmentSeenClasses(compiler.backend.uint31Implementation);
    return _uint31Type;
  }

  @override
  ConcreteType get uint32Type {
    inferrer.augmentSeenClasses(compiler.backend.uint32Implementation);
    return _uint32Type;
  }

  @override
  ConcreteType get positiveIntType {
    inferrer.augmentSeenClasses(compiler.backend.positiveIntImplementation);
    return _positiveIntType;
  }

  @override
  ConcreteType get doubleType {
    inferrer.augmentSeenClasses(compiler.backend.doubleImplementation);
    return _doubleType;
  }

  @override
  ConcreteType get numType {
    inferrer.augmentSeenClasses(compiler.backend.numImplementation);
    return _numType;
  }

  @override
  ConcreteType get boolType {
    inferrer.augmentSeenClasses(compiler.backend.boolImplementation);
    return _boolType;
  }

  @override
  ConcreteType get functionType {
    inferrer.augmentSeenClasses(compiler.backend.functionImplementation);
    return _functionType;
  }

  @override
  ConcreteType get listType {
    inferrer.augmentSeenClasses(compiler.backend.listImplementation);
    return _listType;
  }

  @override
  ConcreteType get constListType {
    inferrer.augmentSeenClasses(compiler.backend.constListImplementation);
    return _constListType;
  }

  @override
  ConcreteType get fixedListType {
    inferrer.augmentSeenClasses(compiler.backend.fixedListImplementation);
    return _fixedListType;
  }

  @override
  ConcreteType get growableListType {
    inferrer.augmentSeenClasses(compiler.backend.growableListImplementation);
    return _growableListType;
  }

  @override
  ConcreteType get mapType {
    inferrer.augmentSeenClasses(compiler.backend.mapImplementation);
    return _mapType;
  }

  @override
  ConcreteType get constMapType {
    inferrer.augmentSeenClasses(compiler.backend.constMapImplementation);
    return _constMapType;
  }

  @override
  ConcreteType get stringType {
    inferrer.augmentSeenClasses(compiler.backend.stringImplementation);
    return _stringType;
  }

  @override
  ConcreteType stringLiteralType(_) {
    inferrer.augmentSeenClasses(compiler.backend.stringImplementation);
    return _stringType;
  }

  /**
   * Returns the [TypeMask] representation of [baseType].
   */
  TypeMask baseTypeToTypeMask(BaseType baseType) {
    if (baseType.isUnknown()) {
      return const DynamicTypeMask();
    } else if (baseType.isNull()) {
      return new TypeMask.empty();
    } else {
      ClassBaseType classBaseType = baseType;
      final element = classBaseType.element;
      assert(element != null);
      if (element == compiler.backend.numImplementation) {
        return new TypeMask.nonNullSubclass(compiler.backend.numImplementation,
                                            compiler.world);
      } else if (element == compiler.backend.intImplementation) {
        return new TypeMask.nonNullSubclass(compiler.backend.intImplementation,
                                            compiler.world);
      } else {
        return new TypeMask.nonNullExact(element.declaration, compiler.world);
      }
    }
  }

  /**
   * Returns the [TypeMask] representation of [concreteType].
   */
  TypeMask concreteTypeToTypeMask(ConcreteType concreteType) {
    if (concreteType == null) return null;
    TypeMask typeMask = new TypeMask.nonNullEmpty();
    for (BaseType baseType in concreteType.baseTypes) {
      TypeMask baseMask = baseTypeToTypeMask(baseType);
      if (baseMask == const DynamicTypeMask()) return baseMask;
      typeMask = typeMask.union(baseMask, compiler.world);
    }
    return typeMask;
  }

  @override
  ConcreteType addPhiInput(Local variable,
                           ConcreteType phiType,
                           ConcreteType newType) {
    return computeLUB(phiType, newType);
  }

  @override
  ConcreteType allocateDiamondPhi(ConcreteType firstInput,
                                  ConcreteType secondInput) {
    return computeLUB(firstInput, secondInput);
  }

  @override
  ConcreteType allocatePhi(Node node, Local variable, ConcreteType inputType) {
    return inputType;
  }

  @override
  ConcreteType computeLUB(ConcreteType firstType, ConcreteType secondType) {
    if (firstType == null) {
      return secondType;
    } else if (secondType == null) {
      return firstType;
    } else {
      return firstType.union(secondType);
    }
  }

  // Implementation Inspired by
  // type_graph_inferrer.TypeInformationSystem.narrowType
  @override
  ConcreteType narrowType(ConcreteType type,
                          DartType annotation,
                          {bool isNullable: true}) {
    if (annotation.treatAsDynamic) return type;
    if (annotation.isVoid) return nullType;
    if (annotation.element == compiler.objectClass) return type;
    ConcreteType otherType;
    if (annotation.isTypedef || annotation.isFunctionType) {
      otherType = functionType;
    } else if (annotation.isTypeVariable) {
      // TODO(polux): Narrow to bound.
      return type;
    } else {
      assert(annotation.isInterfaceType);
      otherType = nonNullSubtype(annotation.element);
    }
    if (isNullable) otherType = otherType.union(nullType);
    if (type == null) return otherType;
    return type.intersection(otherType);
  }

  @override
  Selector newTypedSelector(ConcreteType receiver, Selector selector) {
    return new TypedSelector(concreteTypeToTypeMask(receiver), selector,
        compiler.world);
  }

  @override
  ConcreteType nonNullEmpty() {
    return nonNullEmptyType;
  }

  @override
  ConcreteType nonNullExact(ClassElement cls) {
    return nonNullSubtype(cls);
  }

  /**
   * Helper method for [nonNullSubtype] and [nonNullSubclass].
   */
  ConcreteType nonNullSubX(ClassElement cls,
                           Iterable<ClassElement> extractor(ClassElement cls)) {
    if (cls == compiler.objectClass) {
      return dynamicType;
    }
    ConcreteType result = nonNullEmptyType;
    void registerClass(ClassElement element) {
      if (!element.isAbstract) {
        result = result.union(
            new ConcreteType.singleton(compiler.maxConcreteTypeSize,
                                       baseTypes,
                                       new ClassBaseType(element)));
        inferrer.augmentSeenClasses(element);
      }
    }
    registerClass(cls);
    Iterable<ClassElement> subtypes = extractor(cls);
    subtypes.forEach(registerClass);
    return result;
  }

  @override
  ConcreteType nonNullSubclass(ClassElement cls) {
    return nonNullSubX(cls, compiler.world.subclassesOf);
  }

  @override
  ConcreteType nonNullSubtype(ClassElement cls) {
    return nonNullSubX(cls, compiler.world.subtypesOf);
  }

  @override
  ConcreteType simplifyPhi(Node node,
                           Local variable,
                           ConcreteType phiType) {
    return phiType;
  }

  @override
  bool selectorNeedsUpdate(ConcreteType type, Selector selector) {
    return concreteTypeToTypeMask(type) != selector.mask;
  }

  @override
  ConcreteType refineReceiver(Selector selector, ConcreteType receiverType) {
    return receiverType.refine(selector, compiler);
  }

  @override
  bool isNull(ConcreteType type) {
    return (type.baseTypes.length == 1) && (type.baseTypes.first.isNull());
  }

  @override
  ConcreteType allocateClosure(Node node, Element element) {
    // TODO(polux): register closure here instead of in visitor?
    return functionType;
  }

  @override
  ConcreteType allocateList(ConcreteType type,
                            Node node,
                            Element enclosing,
                            [ConcreteType elementType, int length]) {
    if (elementType != null) {
      inferrer.augmentListElementType(elementType);
    }
    return type;
  }

  @override
  ConcreteType allocateMap(ConcreteType type,
                           Node node,
                           Element element,
                           [List<ConcreteType> keyTypes,
                            List<ConcreteType> valueTypes]) {
    // TODO(polux): treat maps the same way we treat lists
    return type;
  }

  @override
  ConcreteType getConcreteTypeFor(TypeMask mask) {
    if (mask.isUnion) {
      UnionTypeMask union = mask;
      return union.disjointMasks.fold(
          nonNullEmptyType,
          (type1, type2) => type1.union(getConcreteTypeFor(type2)));
    } else {
      FlatTypeMask flat = mask;
      ConcreteType result;
      if (flat.isEmpty) {
        result = nonNullEmptyType;
      } else if (flat.isExact) {
        result = nonNullExact(flat.base);
      } else if (flat.isSubclass) {
        result = nonNullSubclass(flat.base);
      } else if (flat.isSubtype) {
        result = nonNullSubtype(flat.base);
      } else {
        throw new ArgumentError("unexpected mask");
      }
      return flat.isNullable ? result.union(nullType) : result;
    }
  }
}

/**
 * The cartesian product of concrete types: an iterable of
 * [ConcreteTypesEnvironment]s.
 */
class ConcreteTypeCartesianProduct
    extends IterableBase<ConcreteTypesEnvironment> {
  final ConcreteTypesInferrer inferrer;
  final ClassElement typeOfThis;
  final Map<Element, ConcreteType> concreteTypes;
  ConcreteTypeCartesianProduct(this.inferrer, this.typeOfThis,
                               this.concreteTypes);
  Iterator get iterator => concreteTypes.isEmpty
      ? [new ConcreteTypesEnvironment(typeOfThis)].iterator
      : new ConcreteTypeCartesianProductIterator(inferrer, typeOfThis,
                                                 concreteTypes);
  String toString() => this.toList().toString();
}

/**
 * An helper class for [ConcreteTypeCartesianProduct].
 */
class ConcreteTypeCartesianProductIterator
    implements Iterator<ConcreteTypesEnvironment> {
  final ConcreteTypesInferrer inferrer;
  final ClassElement classOfThis;
  final Map<Element, ConcreteType> concreteTypes;
  final Map<Element, BaseType> nextValues;
  final Map<Element, Iterator> state;
  int size = 1;
  int counter = 0;
  ConcreteTypesEnvironment _current;

  ConcreteTypeCartesianProductIterator(this.inferrer, this.classOfThis,
      Map<Element, ConcreteType> concreteTypes)
      : this.concreteTypes = concreteTypes,
        nextValues = new Map<Element, BaseType>(),
        state = new Map<Element, Iterator>() {
    if (concreteTypes.isEmpty) {
      size = 0;
      return;
    }
    for (final e in concreteTypes.keys) {
      final baseTypes = concreteTypes[e].baseTypes;
      size *= baseTypes.length;
    }
  }

  ConcreteTypesEnvironment get current => _current;

  ConcreteTypesEnvironment takeSnapshot() {
    Map<Element, ConcreteType> result = new Map<Element, ConcreteType>();
    nextValues.forEach((k, v) {
      result[k] = inferrer.singletonConcreteType(v);
    });
    return new ConcreteTypesEnvironment.of(result, classOfThis);
  }

  bool moveNext() {
    if (counter >= size) {
      _current = null;
      return false;
    }
    Element keyToIncrement = null;
    for (final key in concreteTypes.keys) {
      final iterator = state[key];
      if (iterator != null && iterator.moveNext()) {
        nextValues[key] = state[key].current;
        break;
      }
      Iterator newIterator = concreteTypes[key].baseTypes.iterator;
      state[key] = newIterator;
      newIterator.moveNext();
      nextValues[key] = newIterator.current;
    }
    counter++;
    _current = takeSnapshot();
    return true;
  }
}

/**
 * [BaseType] Constants.
 */
class BaseTypes {
  final ClassBaseType intBaseType;
  final ClassBaseType doubleBaseType;
  final ClassBaseType numBaseType;
  final ClassBaseType boolBaseType;
  final ClassBaseType stringBaseType;
  final ClassBaseType listBaseType;
  final ClassBaseType growableListBaseType;
  final ClassBaseType fixedListBaseType;
  final ClassBaseType constListBaseType;
  final ClassBaseType mapBaseType;
  final ClassBaseType constMapBaseType;
  final ClassBaseType objectBaseType;
  final ClassBaseType typeBaseType;
  final ClassBaseType functionBaseType;
  final ClassBaseType uint31Type;
  final ClassBaseType uint32Type;
  final ClassBaseType positiveIntType;

  BaseTypes(Compiler compiler) :
    intBaseType = new ClassBaseType(compiler.backend.intImplementation),
    doubleBaseType = new ClassBaseType(compiler.backend.doubleImplementation),
    numBaseType = new ClassBaseType(compiler.backend.numImplementation),
    boolBaseType = new ClassBaseType(compiler.backend.boolImplementation),
    stringBaseType = new ClassBaseType(compiler.backend.stringImplementation),
    listBaseType = new ClassBaseType(compiler.backend.listImplementation),
    growableListBaseType =
        new ClassBaseType(compiler.backend.growableListImplementation),
    fixedListBaseType =
        new ClassBaseType(compiler.backend.fixedListImplementation),
    constListBaseType =
        new ClassBaseType(compiler.backend.constListImplementation),
    mapBaseType = new ClassBaseType(compiler.backend.mapImplementation),
    constMapBaseType =
        new ClassBaseType(compiler.backend.constMapImplementation),
    objectBaseType = new ClassBaseType(compiler.objectClass),
    typeBaseType = new ClassBaseType(compiler.backend.typeImplementation),
    functionBaseType =
        new ClassBaseType(compiler.backend.functionImplementation),
    uint31Type = new ClassBaseType(compiler.backend.uint31Implementation),
    uint32Type = new ClassBaseType(compiler.backend.uint32Implementation),
    positiveIntType =
        new ClassBaseType(compiler.backend.positiveIntImplementation);
}

/**
 * An immutable mapping from method arguments to [ConcreteTypes].
 */
class ConcreteTypesEnvironment {
  final Map<Element, ConcreteType> environment;
  final ClassElement classOfThis;

  ConcreteTypesEnvironment([this.classOfThis]) :
      environment = new Map<Element, ConcreteType>();
  ConcreteTypesEnvironment.of(this.environment, this.classOfThis);

  ConcreteType lookupType(Element element) => environment[element];

  bool operator ==(ConcreteTypesEnvironment other) {
    if (other is! ConcreteTypesEnvironment) return false;
    if (classOfThis != other.classOfThis) return false;
    if (environment.length != other.environment.length) return false;
    for (Element key in environment.keys) {
      if (!other.environment.containsKey(key)
          || (environment[key] != other.environment[key])) {
        return false;
      }
    }
    return true;
  }

  int get hashCode {
    int result = (classOfThis != null) ? classOfThis.hashCode : 1;
    environment.forEach((element, concreteType) {
      result = 31 * (31 * result + element.hashCode) + concreteType.hashCode;
    });
    return result;
  }

  String toString() => "{ this: $classOfThis, env: $environment }";
}

class ClosureEnvironment {
  ConcreteType thisType;
  final LocalsHandler locals;

  ClosureEnvironment(this.thisType, this.locals);

  bool mergeLocals(LocalsHandler newLocals) {
    assert((locals == null) == (newLocals == null));
    return (locals != null) ? locals.mergeAll([newLocals]) : false;
  }

  /// Returns true if changed.
  bool merge(ConcreteType thisType, LocalsHandler locals) {
    ConcreteType oldThisType = this.thisType;
    if (this.thisType == null) {
      this.thisType = thisType;
    } else if (thisType != null) {
      this.thisType = this.thisType.union(thisType);
    }
    return mergeLocals(locals) || (this.thisType != oldThisType);
  }

  toString() => "ClosureEnvironment { thisType = $thisType, locals = ... }";
}

/**
 * A set of encoutered closures.
 */
class Closures {
  final Compiler compiler;
  final Map<FunctionElement, ClosureEnvironment> closures =
      new Map<FunctionElement, ClosureEnvironment>();

  Closures(this.compiler);

  /// Returns true if the environment of the closure has changed.
  bool put(FunctionElement closure,
           ConcreteType typeOfThis,
           LocalsHandler locals) {
    ClosureEnvironment oldEnvironent = closures[closure];
    if (oldEnvironent == null) {
      closures[closure] = new ClosureEnvironment(typeOfThis, locals);
      return true;
    } else {
      return oldEnvironent.merge(typeOfThis, locals);
    }
  }

  ClosureEnvironment getEnvironmentOrNull(FunctionElement function) {
    return closures[function];
  }

  Iterable<FunctionElement> get functionElements => closures.keys;

  bool contains(FunctionElement function) => closures.containsKey(function);

  String toString() => closures.toString();
}

/**
 * A work item for the type inference queue.
 */
class InferenceWorkItem {
  Element method;
  ConcreteTypesEnvironment environment;
  InferenceWorkItem(this.method, this.environment);

  toString() => "{ method = $method, environment = $environment }";

  bool operator ==(other) {
    return (other is InferenceWorkItem)
        && method == other.method
        && environment == other.environment;
  }

  int get hashCode => 31 * method.hashCode + environment.hashCode;
}

/**
 * A sentinel type mask class representing the dynamicType. It is absorbing
 * for [:ConcreteTypesEnvironment.typeMaskUnion:].
 */
class DynamicTypeMask implements TypeMask {
  const DynamicTypeMask();

  String toString() => 'sentinel type mask';

  TypeMask nullable() {
    throw new UnsupportedError("");
  }

  TypeMask nonNullable() {
    throw new UnsupportedError("");
  }

  bool get isEmpty {
    throw new UnsupportedError("");
  }

  bool get isNullable {
    throw new UnsupportedError("");
  }

  bool get isExact {
    throw new UnsupportedError("");
  }

  bool get isUnion {
    throw new UnsupportedError("");
  }

  bool get isContainer {
    throw new UnsupportedError("");
  }

  bool get isMap {
    throw new UnsupportedError("");
  }

  bool get isDictionary {
    throw new UnsupportedError("");
  }

  bool get isForwarding {
    throw new UnsupportedError("");
  }

  bool get isValue {
    throw new UnsupportedError("");
  }

  bool containsOnlyInt(ClassWorld classWorld) {
    throw new UnsupportedError("");
  }

  bool containsOnlyDouble(ClassWorld classWorld) {
    throw new UnsupportedError("");
  }

  bool containsOnlyNum(ClassWorld classWorld) {
    throw new UnsupportedError("");
  }

  bool containsOnlyBool(ClassWorld classWorld) {
    throw new UnsupportedError("");
  }

  bool containsOnlyString(ClassWorld classWorld) {
    throw new UnsupportedError("");
  }

  bool containsOnly(ClassElement element) {
    throw new UnsupportedError("");
  }

  bool satisfies(ClassElement cls, ClassWorld classWorld) {
    throw new UnsupportedError("");
  }

  bool contains(ClassElement type, ClassWorld classWorld) {
    throw new UnsupportedError("");
  }

  bool containsAll(ClassWorld classWorld) {
    throw new UnsupportedError("");
  }

  ClassElement singleClass(ClassWorld classWorld) {
    throw new UnsupportedError("");
  }

  TypeMask union(TypeMask other, ClassWorld classWorld) {
    throw new UnsupportedError("");
  }

  TypeMask intersection(TypeMask other, ClassWorld classWorld) {
    throw new UnsupportedError("");
  }

  bool canHit(Element element, Selector selector, ClassWorld classWorld) {
    throw new UnsupportedError("");
  }

  Element locateSingleElement(Selector selector, Compiler compiler) {
    throw new UnsupportedError("");
  }

  bool needsNoSuchMethodHandling(Selector selector, ClassWorld classWorld) {
    throw new UnsupportedError("");
  }

  bool isInMask(TypeMask other, ClassWorld classWorld) {
    throw new UnsupportedError("");
  }

  bool containsMask(TypeMask other, ClassWorld classWorld) {
    throw new UnsupportedError("");
  }
}

class WorkQueue {
  final Queue<InferenceWorkItem> queue = new Queue<InferenceWorkItem>();

  void add(InferenceWorkItem workItem) {
    if (!queue.contains(workItem)) {
      queue.addLast(workItem);
    }
  }

  InferenceWorkItem remove() {
    return queue.removeFirst();
  }

  bool get isEmpty => queue.isEmpty;
}

/**
 * A task which conservatively infers a [ConcreteType] for each sub expression
 * of the program. The entry point is [analyzeMain].
 */
class ConcreteTypesInferrer
    extends InferrerEngine<ConcreteType, ConcreteTypeSystem>
    implements TypesInferrer {

  final String name = "Type inferrer";

  /**
   * When true, the string literal [:"__dynamic_for_test":] is inferred to
   * have the unknown type.
   */
  // TODO(polux): get rid of this hack once we have a natural way of inferring
  // the unknown type.
  bool testMode = false;

  // --- constants ---

  /**
   * Constants representing builtin base types. Initialized by [initialize]
   * and not by the constructor because the compiler elements are not yet
   * populated.
   */
  BaseTypes baseTypes;

  /** The associated type system */
  ConcreteTypeSystem types;

  /**
   * Constant representing [:ConcreteList#[]:] where [:ConcreteList:] is the
   * concrete implementation of lists for the selected backend.
   */
  FunctionElement listIndex;

  /**
   * Constant representing [:ConcreteList#[]=:] where [:ConcreteList:] is the
   * concrete implementation of lists for the selected backend.
   */
  FunctionElement listIndexSet;

  /**
   * Constant representing [:ConcreteList#add:] where [:ConcreteList:] is the
   * concrete implementation of lists for the selected backend.
   */
  FunctionElement listAdd;

  /**
   * Constant representing [:ConcreteList#removeAt:] where [:ConcreteList:] is
   * the concrete implementation of lists for the selected backend.
   */
  FunctionElement listRemoveAt;

  /**
   * Constant representing [:ConcreteList#insert:] where [:ConcreteList:] is
   * the concrete implementation of lists for the selected backend.
   */
  FunctionElement listInsert;

  /**
   * Constant representing [:ConcreteList#removeLast:] where [:ConcreteList:] is
   * the concrete implementation of lists for the selected backend.
   */
  FunctionElement listRemoveLast;

  /** Constant representing [:List():]. */
  FunctionElement listConstructor;

  /** The unknown concrete type */
  final ConcreteType unknownConcreteType;

  /** The empty concrete type */
  ConcreteType emptyConcreteType;

  /** The null concrete type */
  ConcreteType nullConcreteType;

  // --- state updated by the inference ---

  /**
   * A map from (function x argument base types) to their inferred concrete
   * type. Another way of seeing [methodToTemplates] is as a map from
   * [FunctionElement]s to "templates" in the sense of "The Cartesian Product
   * Algorithm - Simple and Precise Type Inference of Parametric Polymorphism"
   * by Ole Agesen.
   */
  // TODO(polux): build a better abstraction, like Closures
  final Map<FunctionElement, Map<ConcreteTypesEnvironment, ConcreteType>>
      methodToTemplates;

  /** The set of encountered closures. */
  final Closures closures;

  /** A map from expressions to their inferred concrete types. */
  final Map<Node, ConcreteType> inferredTypes;

  /** A map from fields to their inferred concrete types. */
  final Map<Element, ConcreteType> inferredFieldTypes;

  /**
   * [:callers[f]:] is the list of [:f:]'s possible callers or fields
   * whose initialization is a call to [:f:].
   */
  final Map<FunctionElement, Set<Element>> callers;

  /**
   * [:readers[field]:] is the list of [:field:]'s possible readers or fields
   * whose initialization is a read of [:field:].
   */
  final Map<Element, Set<Element>> fieldReaders;

  /**
   * [:readers[local]:] is the list of [:local:]'s possible readers.
   */
  final Map<Local, Set<FunctionElement>> capturedLocalsReaders;

  /// The set of classes encountered so far.
  final Set<ClassElement> seenClasses;

  /**
   * A map from selector names to callers of methods with this name on objects
   * of unknown inferred type.
   */
  final Map<String, Set<FunctionElement>> dynamicCallers;

  /** The inferred type of elements stored in Lists. */
  ConcreteType listElementType;

  /**
   * A map from parameters to their inferred concrete types. It plays no role
   * in the analysis, it is write only.
   */
  final Map<VariableElement, ConcreteType> inferredParameterTypes;

  /**
   * A map from selectors to their inferred type masks, indexed by the mask
   * of the receiver. It plays no role in the analysis, it is write only.
   */
  final Map<Selector, Map<TypeMask, TypeMask>> inferredSelectorTypes;

  /** The work queue consumed by [analyzeMain]. */
  final WorkQueue workQueue;

  /** The item being worked on. */
  InferenceWorkItem currentWorkItem;

  ConcreteTypesInferrer(Compiler compiler)
      : methodToTemplates = new Map<FunctionElement,
            Map<ConcreteTypesEnvironment, ConcreteType>>(),
        closures = new Closures(compiler),
        inferredTypes = new Map<Node, ConcreteType>(),
        inferredFieldTypes = new Map<Element, ConcreteType>(),
        inferredParameterTypes = new Map<VariableElement, ConcreteType>(),
        workQueue = new WorkQueue(),
        callers = new Map<FunctionElement, Set<Element>>(),
        fieldReaders = new Map<Element, Set<Element>>(),
        capturedLocalsReaders = new Map<Local, Set<FunctionElement>>(),
        seenClasses = new Set<ClassElement>(),
        dynamicCallers = new Map<String, Set<FunctionElement>>(),
        inferredSelectorTypes = new Map<Selector, Map<TypeMask, TypeMask>>(),
        unknownConcreteType = new ConcreteType.unknown(),
        super(compiler, null);

  /* Initialization code that cannot be run in the constructor because it
   * requires the compiler's elements to be populated.
   */
  void initialize() {
    baseTypes = new BaseTypes(compiler);
    types = new ConcreteTypeSystem(this);
    ClassElement jsArrayClass = baseTypes.listBaseType.element;
    listIndex = jsArrayClass.lookupMember('[]');
    listIndexSet = jsArrayClass.lookupMember('[]=');
    listAdd = jsArrayClass.lookupMember('add');
    listRemoveAt = jsArrayClass.lookupMember('removeAt');
    listInsert = jsArrayClass.lookupMember('insert');
    listRemoveLast =
        jsArrayClass.lookupMember('removeLast');
    List<String> typePreservingOps = const ['+', '-', '*'];
    listConstructor =
        compiler.listClass.lookupConstructor(
            new Selector.callConstructor(
                '',
                compiler.listClass.library)).implementation;
    emptyConcreteType = new ConcreteType.empty(compiler.maxConcreteTypeSize,
                                               baseTypes);
    nullConcreteType = singletonConcreteType(const NullBaseType());
    listElementType = emptyConcreteType;
  }

  // --- utility methods ---

  /** Creates a singleton concrete type containing [baseType]. */
  ConcreteType singletonConcreteType(BaseType baseType) {
    return new ConcreteType.singleton(compiler.maxConcreteTypeSize, baseTypes,
                                      baseType);
  }

  /**
   * Computes the union of [mask1] and [mask2] where [mask1] and [mask2] are
   * possibly equal to [: DynamicTypeMask.instance :].
   */
  TypeMask typeMaskUnion(TypeMask mask1, TypeMask mask2) {
    if (mask1 == const DynamicTypeMask() || mask2 == const DynamicTypeMask()) {
      return const DynamicTypeMask();
    }
    return mask1.union(mask2, compiler.world);
  }

  /**
   * Returns all the members matching [selector].
   */
  Set<Element> getMembersBySelector(Selector selector) {
    // TODO(polux): memoize?
    Set<Element> result = new Set<Element>();
    for (ClassElement cls in seenClasses) {
      Element elem = cls.lookupSelector(selector);
      if (elem != null) {
        result.add(elem.implementation);
      }
    }
    return result;
  }

  /**
   * Returns all the subtypes of [cls], [cls] included.
   */
  Set<ClassElement> getReflexiveSubtypesOf(ClassElement cls) {
    // TODO(polux): memoize?
    Set<ClassElement> result = new Set<ClassElement>()..add(cls);
    for (ClassElement candidate in seenClasses) {
      if (compiler.world.isSubtypeOf(candidate, cls)) {
        result.add(candidate);
      }
    }
    return result;
  }

  /**
   * Sets the concrete type associated to [node] to the union of the inferred
   * concrete type so far and of [type].
   */
  void augmentInferredType(Node node, ConcreteType type) {
    ConcreteType currentType = inferredTypes[node];
    inferredTypes[node] =
        (currentType == null) ? type : currentType.union(type);
  }

  /**
   * Sets the concrete type associated to [selector] to the union of the
   * inferred concrete type so far and of [returnType].
   *
   * Precondition: [:(typeOfThis != null) && (returnType != null):]
   */
  void augmentInferredSelectorType(Selector selector, TypeMask typeOfThis,
                                   TypeMask returnType) {
    assert(returnType != null);
    assert(typeOfThis != null);

    selector = selector.asUntyped;
    Map<TypeMask, TypeMask> currentMap = inferredSelectorTypes.putIfAbsent(
        selector, () => new Map<TypeMask, TypeMask>());
    TypeMask currentReturnType = currentMap[typeOfThis];
    currentMap[typeOfThis] = (currentReturnType == null)
        ? returnType
        : typeMaskUnion(currentReturnType, returnType);
  }

  /**
   * Returns the current inferred concrete type of [field].
   */
  ConcreteType getFieldType(Selector selector, Element field) {
    ensureFieldInitialized(field);
    ConcreteType result = inferredFieldTypes[field];
    result = (result == null) ? emptyConcreteType : result;
    if (selector != null) {
      Element enclosing = field.enclosingElement;
      if (enclosing.isClass) {
        ClassElement cls = enclosing;
        TypeMask receiverMask = new TypeMask.exact(cls.declaration, classWorld);
        TypeMask resultMask = types.concreteTypeToTypeMask(result);
        augmentInferredSelectorType(selector, receiverMask, resultMask);
      }
    }
    return result;
  }

  /**
   * Sets the concrete type associated to [field] to the union of the inferred
   * concrete type so far and of [type].
   */
  void augmentFieldType(Element field, ConcreteType type) {
    ensureFieldInitialized(field);
    ConcreteType oldType = inferredFieldTypes[field];
    ConcreteType newType = (oldType != null) ? oldType.union(type) : type;
    if (oldType != newType) {
      inferredFieldTypes[field] = newType;
      invalidateReaders(field);
    }
  }

  /** Augment the inferred type of elements stored in Lists. */
  void augmentListElementType(ConcreteType type) {
    ConcreteType newType = listElementType.union(type);
    if (newType != listElementType) {
      invalidateCallers(listIndex);
      listElementType = newType;
    }
  }

  /**
   * Sets the concrete type associated to [parameter] to the union of the
   * inferred concrete type so far and of [type].
   */
  void augmentParameterType(VariableElement parameter, ConcreteType type) {
    ConcreteType oldType = inferredParameterTypes[parameter];
    inferredParameterTypes[parameter] =
        (oldType == null) ? type : oldType.union(type);
  }

  /** Augments the set of classes encountered so far. */
  void augmentSeenClasses(ClassElement cls) {
    if (!seenClasses.contains(cls)) {
      seenClasses.add(cls);
      cls.forEachMember((_, Element member) {
        Set<FunctionElement> functions = dynamicCallers[member.name];
        if (functions != null) {
          functions.forEach(invalidate);
        }
      }, includeSuperAndInjectedMembers: true);
    }
  }

  /**
   * Add [caller] to the set of [callee]'s callers.
   */
  void addCaller(FunctionElement callee, Element caller) {
    callers.putIfAbsent(callee, () => new Set<Element>())
           .add(caller);
  }

  /**
   * Add [caller] to the set of [callee]'s dynamic callers.
   */
  void addDynamicCaller(Selector callee, FunctionElement caller) {
      dynamicCallers
          .putIfAbsent(callee.name, () => new Set<FunctionElement>())
          .add(caller);
  }

  /**
   * Add [reader] to the set of [field]'s readers.
   */
  void addFieldReader(Element field, Element reader) {
    fieldReaders.putIfAbsent(field, () => new Set<Element>())
                .add(reader);
  }

  /**
   * Add [reader] to the set of [local]'s readers.
   */
  void addCapturedLocalReader(Local local, FunctionElement reader) {
    capturedLocalsReaders.putIfAbsent(local, () => new Set<FunctionElement>())
                         .add(reader);
  }

  /**
   * Add a closure to the set of seen closures. Invalidate callers if
   * the set of locals has changed.
   */
  void addClosure(FunctionElement closure,
                  ConcreteType typeOfThis,
                  LocalsHandler locals) {
    if (closures.put(closure, typeOfThis, locals)) {
      invalidateCallers(closure);
    }
  }

  /**
   * Invalidate all callers of [function].
   */
  void invalidateCallers(FunctionElement function) {
    Set<Element> methodCallers = callers[function];
    if (methodCallers != null) {
      methodCallers.forEach(invalidate);
    }
  }

  /**
   * Invalidate all reader of [field].
   */
  void invalidateReaders(Element field) {
    Set<Element> readers = fieldReaders[field];
    if (readers != null) {
      readers.forEach(invalidate);
    }
  }

  /**
   * Add all templates of [methodOrField] to the workqueue.
   */
  void invalidate(Element methodOrField) {
    if (methodOrField.isField) {
      workQueue.add(new InferenceWorkItem(
          methodOrField, new ConcreteTypesEnvironment()));
    } else {
      Map<ConcreteTypesEnvironment, ConcreteType> templates =
          methodToTemplates[methodOrField];
      if (templates != null) {
        templates.forEach((environment, _) {
          workQueue.add(
              new InferenceWorkItem(methodOrField, environment));
        });
      }
    }
  }

  /**
   * Returns the template associated to [function] or create an empty template
   * for [function] return it.
   */
  // TODO(polux): encapsulate this in an abstraction for templates
  Map<ConcreteTypesEnvironment, ConcreteType>
      getTemplatesOrEmpty(FunctionElement function) {
    return methodToTemplates.putIfAbsent(
        function,
        () => new Map<ConcreteTypesEnvironment, ConcreteType>());
  }

  // -- methods of types.TypesInferrer (interface with the backend) --

  /** Get the inferred concrete type of [node]. */
  @override
  TypeMask getTypeOfNode(Element owner, Node node) {
    TypeMask result = types.concreteTypeToTypeMask(inferredTypes[node]);
    return (result == const DynamicTypeMask()) ? null : result;
  }

  /** Get the inferred concrete type of [element]. */
  @override
  TypeMask getTypeOfElement(Element element) {
    final result = types.concreteTypeToTypeMask(typeOfElement(element));
    return (result == const DynamicTypeMask()) ? null : result;
  }

  /**
   * Get the inferred concrete return type of [element]. A null return value
   * means "I don't know".
   */
  @override
  TypeMask getReturnTypeOfElement(Element element) {
    assert(element is FunctionElement);
    Map<ConcreteTypesEnvironment, ConcreteType> templates =
        methodToTemplates[element];
    if (templates == null) return null;
    ConcreteType returnType = emptyConcreteType;
    templates.forEach((_, concreteType) {
      returnType = returnType.union(concreteType);
    });
    TypeMask result = types.concreteTypeToTypeMask(returnType);
    return (result == const DynamicTypeMask()) ? null : result;
  }

  /**
   * Get the inferred concrete type of [selector]. A null return value means
   * "I don't know".
   */
  @override
  TypeMask getTypeOfSelector(Selector selector) {
    Map<TypeMask, TypeMask> candidates =
        inferredSelectorTypes[selector.asUntyped];
    if (candidates == null) {
      return null;
    }
    TypeMask result = new TypeMask.nonNullEmpty();
    if (selector.mask == null) {
      candidates.forEach((TypeMask receiverType, TypeMask returnType) {
        result = typeMaskUnion(result, returnType);
      });
    } else {
      candidates.forEach((TypeMask receiverType, TypeMask returnType) {
        TypeMask intersection =
            receiverType.intersection(selector.mask, compiler.world);
        if (!intersection.isEmpty || intersection.isNullable) {
          result = typeMaskUnion(result, returnType);
        }
      });
    }
    return result == const DynamicTypeMask() ? null : result;
  }

  @override
  void clear() {
    throw new UnsupportedError("clearing is not yet implemented");
  }

  @override
  bool isCalledOnce(Element element) {
    // Never called by SimpleTypeInferrer.
    throw new UnsupportedError("");
  }

  @override
  bool isFixedArrayCheckedForGrowable(Node node) {
    // Never called by SimpleTypeInferrer.
    throw new UnsupportedError("");
  }

  // --- analysis ---

  /**
   * Returns the concrete type returned by [function] given arguments of
   * concrete types [argumentsTypes]. If [function] is static then
   * [receiverType] must be null, else [function] must be a member of
   * [receiverType].
   */
  ConcreteType getSendReturnType(Selector selector,
                                 FunctionElement function,
                                 ClassElement receiverType,
                                 ArgumentsTypes<ConcreteType> argumentsTypes) {
    assert(function != null);

    ConcreteType result = emptyConcreteType;
    Map<Element, ConcreteType> argumentMap =
        associateArguments(function, argumentsTypes);
    // if the association failed, this send will never occur or will fail
    if (argumentMap == null) {
      return emptyConcreteType;
    }

    argumentMap.forEach(augmentParameterType);
    ConcreteTypeCartesianProduct product =
        new ConcreteTypeCartesianProduct(this, receiverType, argumentMap);
    for (ConcreteTypesEnvironment environment in product) {
      result = result.union(
          getMonomorphicSendReturnType(function, environment));
    }

    if (selector != null && receiverType != null) {
      // TODO(polux): generalize to any abstract class if we ever handle other
      // abstract classes than num.
      TypeMask receiverMask =
          (receiverType == compiler.backend.numImplementation
          || receiverType == compiler.backend.intImplementation)
              ? new TypeMask.nonNullSubclass(receiverType.declaration,
                  compiler.world)
              : new TypeMask.nonNullExact(receiverType.declaration,
                  compiler.world);
      TypeMask resultMask = types.concreteTypeToTypeMask(result);
      augmentInferredSelectorType(selector, receiverMask, resultMask);
    }

    return result;
  }

  /**
   * Given a method signature and a list of concrete types, builds a map from
   * formals to their corresponding concrete types. Returns null if the
   * association is impossible (for instance: too many arguments).
   */
  Map<Element, ConcreteType> associateArguments(
      FunctionElement function,
      ArgumentsTypes<ConcreteType> argumentsTypes) {
    final Map<Element, ConcreteType> result = new Map<Element, ConcreteType>();
    final FunctionSignature signature = function.functionSignature;

    // guard 1: too many arguments
    if (argumentsTypes.length > signature.parameterCount) {
      return null;
    }
    // guard 2: not enough arguments
    if (argumentsTypes.positional.length < signature.requiredParameterCount) {
      return null;
    }
    // guard 3: too many positional arguments
    if (signature.optionalParametersAreNamed &&
        argumentsTypes.positional.length > signature.requiredParameterCount) {
      return null;
    }

    handleLeftoverOptionalParameter(ParameterElement parameter) {
      Expression initializer = parameter.initializer;
      result[parameter] = (initializer == null)
          ? nullConcreteType
          : analyzeDefaultValue(function, initializer);
    }

    final Iterator<ConcreteType> remainingPositionalArguments =
        argumentsTypes.positional.iterator;
    // we attach each positional parameter to its corresponding positional
    // argument
    for (Link<Element> requiredParameters = signature.requiredParameters;
        !requiredParameters.isEmpty;
        requiredParameters = requiredParameters.tail) {
      final Element requiredParameter = requiredParameters.head;
      // we know moveNext() succeeds because of guard 2
      remainingPositionalArguments.moveNext();
      result[requiredParameter] = remainingPositionalArguments.current;
    }
    if (signature.optionalParametersAreNamed) {
      // we build a map out of the remaining named parameters
      Link<Element> remainingOptionalParameters = signature.optionalParameters;
      final Map<String, Element> leftOverNamedParameters =
          new Map<String, Element>();
      for (;
           !remainingOptionalParameters.isEmpty;
           remainingOptionalParameters = remainingOptionalParameters.tail) {
        final Element namedParameter = remainingOptionalParameters.head;
        leftOverNamedParameters[namedParameter.name] = namedParameter;
      }
      // we attach the named arguments to their corresponding optional
      // parameters
      for (String source in argumentsTypes.named.keys) {
        final ConcreteType concreteType = argumentsTypes.named[source];
        final Element namedParameter = leftOverNamedParameters[source];
        // unexisting or already used named parameter
        if (namedParameter == null) return null;
        result[namedParameter] = concreteType;
        leftOverNamedParameters.remove(source);
      }
      leftOverNamedParameters.forEach((_, Element parameter) {
        handleLeftoverOptionalParameter(parameter);
      });
    } else { // optional parameters are positional
      // we attach the remaining positional arguments to their corresponding
      // optional parameters
      Link<Element> remainingOptionalParameters = signature.optionalParameters;
      while (remainingPositionalArguments.moveNext()) {
        final Element optionalParameter = remainingOptionalParameters.head;
        result[optionalParameter] = remainingPositionalArguments.current;
        // we know tail is defined because of guard 1
        remainingOptionalParameters = remainingOptionalParameters.tail;
      }
      for (;
           !remainingOptionalParameters.isEmpty;
           remainingOptionalParameters = remainingOptionalParameters.tail) {
        handleLeftoverOptionalParameter(remainingOptionalParameters.head);
      }
    }
    return result;
  }

  ConcreteType getMonomorphicSendReturnType(
      FunctionElement function,
      ConcreteTypesEnvironment environment) {
    Map<ConcreteTypesEnvironment, ConcreteType> template =
        getTemplatesOrEmpty(function);
    ConcreteType type = template[environment];
    ConcreteType specialType = getSpecialCaseReturnType(function, environment);
    if (type != null) {
      return specialType != null ? specialType : type;
    } else {
      workQueue.add(new InferenceWorkItem(function, environment));
      return specialType != null ? specialType : emptyConcreteType;
    }
  }

  /**
   * Handles external methods that cannot be cached because they depend on some
   * other state of [ConcreteTypesInferrer] like [:List#[]:] and
   * [:List#[]=:]. Returns null if [function] and [environment] don't form a
   * special case
   */
  ConcreteType getSpecialCaseReturnType(FunctionElement function,
                                        ConcreteTypesEnvironment environment) {
    // Handles int + int, double + double, int - int, ...
    // We cannot compare function to int#+, int#-, etc. because int and double
    // don't override these methods. So for 1+2, getSpecialCaseReturnType will
    // be invoked with function = num#+. We use environment.typeOfThis instead.
    ClassElement cls = environment.classOfThis;
    if (cls != null) {
      String name = function.name;
      if ((cls == baseTypes.intBaseType.element
          || cls == baseTypes.doubleBaseType.element)
          && (name == '+' || name == '-' || name == '*')) {
        Link<Element> parameters =
            function.functionSignature.requiredParameters;
        ConcreteType argumentType = environment.lookupType(parameters.head);
        if (argumentType.getUniqueType() == cls) {
          return singletonConcreteType(new ClassBaseType(cls));
        }
      }
    }

    if (function == listIndex || function == listRemoveAt) {
      Link<Element> parameters = function.functionSignature.requiredParameters;
      ConcreteType indexType = environment.lookupType(parameters.head);
      if (!indexType.baseTypes.contains(baseTypes.intBaseType)) {
        return emptyConcreteType;
      }
      return listElementType;
    } else if (function == listIndexSet || function == listInsert) {
      Link<Element> parameters = function.functionSignature.requiredParameters;
      ConcreteType indexType = environment.lookupType(parameters.head);
      if (!indexType.baseTypes.contains(baseTypes.intBaseType)) {
        return emptyConcreteType;
      }
      ConcreteType elementType = environment.lookupType(parameters.tail.head);
      augmentListElementType(elementType);
      return emptyConcreteType;
    } else if (function == listAdd) {
      Link<Element> parameters = function.functionSignature.requiredParameters;
      ConcreteType elementType = environment.lookupType(parameters.head);
      augmentListElementType(elementType);
      return emptyConcreteType;
    } else if (function == listRemoveLast) {
      return listElementType;
    }
    return null;
  }

  ConcreteType analyzeMethodOrClosure(Element element,
      ConcreteTypesEnvironment environment) {
    ConcreteType specialResult = handleSpecialMethod(element, environment);
    if (specialResult != null) return specialResult;
    ClosureEnvironment closureEnv = closures.getEnvironmentOrNull(element);
    return (closureEnv == null)
        ? analyzeMethod(element, environment)
        : analyzeClosure(element, closureEnv, environment);
  }

  ConcreteType analyzeMethod(Element element,
                             ConcreteTypesEnvironment environment) {
    TypeInferrerVisitor visitor = new TypeInferrerVisitor(
        element,
        this,
        singletonConcreteType(new ClassBaseType(environment.classOfThis)),
        environment.environment);
    visitor.run();
    return visitor.returnType;
  }

  ConcreteType analyzeClosure(Element element,
                              ClosureEnvironment closureEnv,
                              ConcreteTypesEnvironment environment) {
    assert(environment.classOfThis == null);
    LocalsHandler locals = (closureEnv.locals != null)
        ? new LocalsHandler.deepCopyOf(closureEnv.locals)
        : null;
    TypeInferrerVisitor visitor = new TypeInferrerVisitor(element, this,
        closureEnv.thisType, environment.environment, locals);
    visitor.run();
    return visitor.returnType;
  }

  /**
   * Analyze the initializer of a field if it has not yet been done and update
   * [inferredFieldTypes] accordingly. Invalidate the readers of the field if
   * needed.
   */
  void ensureFieldInitialized(Element field) {
    // This is test is needed for fitering out BoxFieldElements.
    if (field is FieldElement && inferredFieldTypes[field] == null) {
      analyzeFieldInitialization(field);
    }
  }

  /**
   * Analyze the initializer of a field and update [inferredFieldTypes]
   * accordingly. Invalidate the readers of the field if needed.
   */
  ConcreteType analyzeFieldInitialization(VariableElement field) {
    Visitor visitor = new TypeInferrerVisitor(field, this, null, new Map());
    ConcreteType type;
    if (field.initializer != null) {
      type = field.initializer.accept(visitor);
      inferredFieldTypes[field] = type;
      invalidateReaders(field);
    }
    return type;
  }

  /**
   * Analyze a default value.
   */
  ConcreteType analyzeDefaultValue(Element function, Node expression) {
    assert((function != null) && (expression != null));
    Visitor visitor = new TypeInferrerVisitor(function, this, null, {});
    return expression.accept(visitor);
  }

  /**
   * Hook that performs side effects on some special method calls (like
   * [:List(length):]) and possibly returns a concrete type.
   */
  ConcreteType handleSpecialMethod(FunctionElement element,
                                   ConcreteTypesEnvironment environment) {
    // We trust the return type of native elements
    if (isNativeElement(element)) {
      var elementType = element.type;
      assert(elementType.isFunctionType);
      return typeOfNativeBehavior(
          native.NativeBehavior.ofMethod(element, compiler));
    }
    // When List([length]) is called with some length, we must augment
    // listElementType with {null}.
    if (element == listConstructor) {
      Link<Element> parameters =
          listConstructor.functionSignature.optionalParameters;
      ConcreteType lengthType = environment.lookupType(parameters.head);
      if (lengthType.baseTypes.contains(baseTypes.intBaseType)) {
        augmentListElementType(nullConcreteType);
      }
    }
    return null;
  }

  /**
   * Performs concrete type inference of the code reachable from [element].
   */
  @override
  bool analyzeMain(Element element) {
    initialize();
    workQueue.add(
        new InferenceWorkItem(element, new ConcreteTypesEnvironment()));
    while (!workQueue.isEmpty) {
      currentWorkItem = workQueue.remove();
      if (currentWorkItem.method.isField) {
        analyzeFieldInitialization(currentWorkItem.method);
      } else {
        Map<ConcreteTypesEnvironment, ConcreteType> template =
            getTemplatesOrEmpty(currentWorkItem.method);
        template.putIfAbsent(
            currentWorkItem.environment, () => emptyConcreteType);
        recordReturnType(
            currentWorkItem.method,
            analyzeMethodOrClosure(currentWorkItem.method,
                                   currentWorkItem.environment));
      }
    }
    return true;
  }

  /**
   * Dumps debugging information on the standard output.
   */
  void debug() {
    print("queue:");
    for (InferenceWorkItem workItem in workQueue.queue) {
      print("  $workItem");
    }
    print("seen classes:");
    for (ClassElement cls in seenClasses) {
      print("  ${cls.name}");
    }
    print("callers:");
    callers.forEach((k,v) {
      print("  $k: $v");
    });
    print("dynamic callers:");
    dynamicCallers.forEach((k,v) {
      print("  $k: $v");
    });
    print("readers:");
    fieldReaders.forEach((k,v) {
      print("  $k: $v");
    });
    print("readers of captured locals:");
    capturedLocalsReaders.forEach((k,v) {
      print("  $k: $v");
    });
    print("inferredFieldTypes:");
    inferredFieldTypes.forEach((k,v) {
      print("  $k: $v");
    });
    print("listElementType:");
    print("  $listElementType");
    print("inferredParameterTypes:");
    inferredParameterTypes.forEach((k,v) {
      print("  $k: $v");
    });
    print("inferred selector types:");
    inferredSelectorTypes.forEach((selector, map) {
      print("  $selector:");
      map.forEach((k, v) {
        print("    $k: $v");
      });
    });
    print("cache:");
    methodToTemplates.forEach((k,v) {
      print("  $k: $v");
    });
    print("closures:");
    closures.closures.forEach((k, ClosureEnvironment v) {
      print("  $k");
      print("    this: ${v.thisType}");
      if (v.locals != null) {
        v.locals.locals.forEachLocal((local, type) {
          print("    $local: $type");
        });
      }
    });
    print("inferred expression types:");
    inferredTypes.forEach((k,v) {
      print("  $k: $v");
    });
  }

  @override
  ConcreteType addReturnTypeFor(Element analyzedElement,
                                ConcreteType currentType,
                                ConcreteType newType) {
    return (currentType == null) ? newType : currentType.union(newType);
  }

  @override
  void forEachElementMatching(Selector selector, bool f(Element element)) {
    getMembersBySelector(selector).forEach(f);
  }

  @override
  void recordReturnType(Element element, ConcreteType type) {
    assert((type != null) && (element == currentWorkItem.method));
    Map<ConcreteTypesEnvironment, ConcreteType> template =
        getTemplatesOrEmpty(element);
    if (template[currentWorkItem.environment] != type) {
      template[currentWorkItem.environment] = type;
      invalidateCallers(element);
    }
  }

  @override
  void recordType(Element element, ConcreteType type) {
    assert(element is FieldElement);
    augmentFieldType(element, type);
  }

  @override
  void recordTypeOfFinalField(Node node,
                              Element nodeHolder,
                              Element field,
                              ConcreteType type) {
    augmentFieldType(field, type);
  }

  @override
  void recordTypeOfNonFinalField(Spannable node, Element field,
                                 ConcreteType type) {
    augmentFieldType(field, type);
  }

  @override
  void recordCapturedLocalRead(Local local) {
    addCapturedLocalReader(local, currentWorkItem.method);
  }

  @override
  void recordLocalUpdate(Local local, ConcreteType type) {
    Set<FunctionElement> localReaders = capturedLocalsReaders[local];
    if (localReaders != null) {
      localReaders.forEach(invalidate);
    }
  }

  /**
   * Returns the caller of the current analyzed element, given the alleged
   * caller provided by SimpleTypeInferrer.
   *
   * SimpleTypeInferrer lies about the caller when it's a closure.
   * Unfortunately we cannot always trust currentWorkItem.method either because
   * it is wrong for fields initializers.
   */
  Element getRealCaller(Element allegedCaller) {
    Element currentMethod = currentWorkItem.method;
    if ((currentMethod != allegedCaller)
        && currentMethod.isFunction
        && closures.contains(currentMethod)) {
      return currentMethod;
    } else {
      return allegedCaller;
    }
  }

  @override
  ConcreteType registerCalledElement(Spannable node,
                                     Selector selector,
                                     Element caller,
                                     Element callee,
                                     ArgumentsTypes<ConcreteType> arguments,
                                     SideEffects sideEffects,
                                     bool inLoop) {
    caller = getRealCaller(caller);
    if ((selector == null) || (selector.kind == SelectorKind.CALL)) {
      callee = callee.implementation;
      if (selector != null && selector.name == 'JS') {
        return null;
      }
      if (callee.isField) {  // toplevel closure call
        getFieldType(selector, callee);  // trigger toplevel field analysis
        addFieldReader(callee, caller);
        ConcreteType result = emptyConcreteType;
        for (FunctionElement function in closures.functionElements) {
          addCaller(function, caller);
          result = result.union(
              getSendReturnType(selector, function, null, arguments));
        }
        return result;
      } else {  // method or constructor call
        addCaller(callee, caller);
        ClassElement receiverClass = null;
        if (callee.isGenerativeConstructor) {
          receiverClass = callee.enclosingClass;
        } else if (node is Send) {
          Send send = node;
          if (send.receiver != null) {
            if (send.receiver.isSuper()) {
              receiverClass =
                  currentWorkItem.environment.classOfThis.superclass;
            } else {
              receiverClass = currentWorkItem.environment.classOfThis;
            }
          }
        }
        return getSendReturnType(selector, callee, receiverClass, arguments);
      }
    } else if (selector.kind == SelectorKind.GETTER) {
      if (callee.isField) {
        addFieldReader(callee, caller);
        return getFieldType(selector, callee);
      } else if (callee.isGetter) {
        Element enclosing = callee.enclosingElement.isCompilationUnit
            ? null : callee.enclosingElement;
        addCaller(callee, caller);
        ArgumentsTypes noArguments = new ArgumentsTypes([], new Map());
        return getSendReturnType(selector, callee, enclosing, noArguments);
      } else if (callee.isFunction) {
        addClosure(callee, null, null);
        return singletonConcreteType(baseTypes.functionBaseType);
      }
    } else if (selector.kind == SelectorKind.SETTER) {
      ConcreteType argumentType = arguments.positional.first;
      if (callee.isField) {
        augmentFieldType(callee, argumentType);
      } else if (callee.isSetter) {
        FunctionElement setter = callee;
        // TODO(polux): A setter always returns void so there's no need to
        // invalidate its callers even if it is called with new arguments.
        // However, if we start to record more than returned types, like
        // exceptions for instance, we need to do it by uncommenting the
        // following line.
        // inferrer.addCaller(setter, currentMethod);
        Element enclosing = callee.enclosingElement.isCompilationUnit
            ? null : callee.enclosingElement;
        return getSendReturnType(selector, setter, enclosing,
            new ArgumentsTypes([argumentType], new Map()));
      }
    } else {
      throw new ArgumentError("unexpected selector kind");
    }
    return null;
  }

  @override
  ConcreteType registerCalledSelector(Node node,
                                      Selector selector,
                                      ConcreteType receiverType,
                                      Element caller,
                                      ArgumentsTypes<ConcreteType> arguments,
                                      SideEffects sideEffects,
                                      bool inLoop) {
    caller = getRealCaller(caller);
    switch (selector.kind) {
      case SelectorKind.GETTER:
        return registerDynamicGetterSend(selector, receiverType, caller);
      case SelectorKind.SETTER:
        return registerDynamicSetterSend(
            selector, receiverType, caller, arguments);
      default:
        return registerDynamicSend(selector, receiverType, caller, arguments);
    }
  }

  ConcreteType registerDynamicGetterSend(Selector selector,
                                         ConcreteType receiverType,
                                         Element caller) {
    caller = getRealCaller(caller);
    ConcreteType result = emptyConcreteType;

    void augmentResult(ClassElement baseReceiverType, Element member) {
      if (member.isField) {
        addFieldReader(member, caller);
        result = result.union(getFieldType(selector, member));
      } else if (member.isGetter) {
        addCaller(member, caller);
        ArgumentsTypes noArguments = new ArgumentsTypes([], new Map());
        result = result.union(
            getSendReturnType(selector, member, baseReceiverType, noArguments));
      } else if (member.isFunction) {
        addClosure(member, receiverType, null);
        result = result.union(
            singletonConcreteType(baseTypes.functionBaseType));
      } else {
        throw new ArgumentError("unexpected element type");
      }
    }

    if (receiverType.isUnknown()) {
      addDynamicCaller(selector, caller);
      Set<Element> members = getMembersBySelector(selector);
      for (Element member in members) {
        if (!(member.isField || member.isGetter)) continue;
        for (ClassElement cls in
            getReflexiveSubtypesOf(member.enclosingElement)) {
          augmentResult(cls, member);
        }
      }
    } else {
      for (BaseType baseReceiverType in receiverType.baseTypes) {
        if (!baseReceiverType.isNull()) {
          ClassBaseType classBaseType = baseReceiverType;
          ClassElement cls = classBaseType.element;
          Element getterOrField = cls.lookupSelector(selector);
          if (getterOrField != null) {
            augmentResult(cls, getterOrField.implementation);
          }
        }
      }
    }
    return result;
  }

  ConcreteType registerDynamicSetterSend(
      Selector selector,
      ConcreteType receiverType,
      Element caller,
      ArgumentsTypes<ConcreteType> arguments) {
    caller = getRealCaller(caller);
    ConcreteType argumentType = arguments.positional.first;

    void augmentField(ClassElement receiverType, Element setterOrField) {
      if (setterOrField.isField) {
        augmentFieldType(setterOrField, argumentType);
      } else if (setterOrField.isSetter) {
        // A setter always returns void so there's no need to invalidate its
        // callers even if it is called with new arguments. However, if we
        // start to record more than returned types, like exceptions for
        // instance, we need to do it by uncommenting the following line.
        // inferrer.addCaller(setter, currentMethod);
        getSendReturnType(selector, setterOrField, receiverType,
            new ArgumentsTypes([argumentType], new Map()));
      } else {
        throw new ArgumentError("unexpected element type");
      }
    }

    if (receiverType.isUnknown()) {
      // Same remark as above
      // addDynamicCaller(selector, caller);
      for (Element member in getMembersBySelector(selector)) {
        if (!(member.isField || member.isSetter)) continue;
        Element cls = member.enclosingClass;
        augmentField(cls, member);
      }
    } else {
      for (BaseType baseReceiverType in receiverType.baseTypes) {
        if (!baseReceiverType.isNull()) {
          ClassBaseType classBaseType = baseReceiverType;
          ClassElement cls = classBaseType.element;
          Element setterOrField = cls.lookupSelector(selector);
          if (setterOrField != null) {
            augmentField(cls, setterOrField.implementation);
          }
        }
      }
    }
    return argumentType;
  }

  ConcreteType registerDynamicSend(Selector selector,
                                   ConcreteType receiverType,
                                   Element caller,
                                   ArgumentsTypes<ConcreteType> arguments) {
    caller = getRealCaller(caller);
    ConcreteType result = emptyConcreteType;
    if (receiverType.isUnknown()) {
      addDynamicCaller(selector, caller);
      Set<Element> elements = getMembersBySelector(selector);
      for (Element element in elements) {
        if (element.isFunction) {
          FunctionElement method = element;
          addCaller(method, caller);
          for (ClassElement cls in
              getReflexiveSubtypesOf(method.enclosingElement)) {
            result = result.union(
                getSendReturnType(selector, method, cls, arguments));
          }
        } else { // closure call
          assert(element.isField);
          for (FunctionElement function in closures.functionElements) {
            addCaller(function, caller);
            result = result.union(
                getSendReturnType(selector, function, null, arguments));
          }
        }
      }
    } else {
      for (BaseType baseReceiverType in receiverType.baseTypes) {
        if (!baseReceiverType.isNull()) {
          ClassBaseType classBaseReceiverType = baseReceiverType;
          ClassElement cls = classBaseReceiverType.element;
          Element method = cls.lookupSelector(selector);
          if (method != null) {
            if (method.isFunction) {
              assert(method is FunctionElement);
              method = method.implementation;
              addCaller(method, caller);
              result = result.union(
                  getSendReturnType(selector, method, cls, arguments));
            } else { // closure call
              for (FunctionElement function in closures.functionElements) {
                addCaller(function, caller);
                result = result.union(
                    getSendReturnType(selector, function, null, arguments));
              }
            }
          }
        }
      }
    }
    return result;
  }

  @override
  void setDefaultTypeOfParameter(ParameterElement parameter,
                                 ConcreteType type) {
    // We handle default parameters our own way in associateArguments
  }

  /**
   * TODO(johnniwinther): Remove once synthetic parameters get their own default
   * values.
   */
  bool hasAlreadyComputedTypeOfParameterDefault(Element parameter) => false;

  @override
  ConcreteType registerCalledClosure(Node node,
                                     Selector selector,
                                     ConcreteType closure,
                                     Element caller,
                                     ArgumentsTypes<ConcreteType> arguments,
                                     SideEffects sideEffects,
                                     bool inLoop) {
    caller = getRealCaller(caller);
    ConcreteType result = emptyConcreteType;
    for (FunctionElement function in closures.functionElements) {
      addCaller(function, caller);
      result = result.union(
          getSendReturnType(selector, function, null, arguments));
    }
    return result;
  }

  @override
  ConcreteType returnTypeOfElement(Element element) {
    // Never called by SimpleTypeInferrer.
    throw new UnsupportedError("");
  }

  @override
  ConcreteType typeOfElement(Element element) {
    if (currentWorkItem != null) {
      final result = currentWorkItem.environment.lookupType(element);
      if (result != null) return result;
    }
    if (element.isParameter || element.isInitializingFormal) {
      return inferredParameterTypes[element];
    } else if (element.isField) {
      return inferredFieldTypes[element];
    }
    throw new ArgumentError("unexpected element type");
  }

  @override
  void analyze(Element element, ArgumentsTypes arguments) {
    FunctionElement function = element;
    getSendReturnType(
        null, function, currentWorkItem.environment.classOfThis, arguments);
  }
}

class TypeInferrerVisitor extends SimpleTypeInferrerVisitor<ConcreteType> {
  final ConcreteType thisType;
  ConcreteTypesInferrer get inferrer => super.inferrer;

  TypeInferrerVisitor(Element element,
                      ConcreteTypesInferrer inferrer,
                      this.thisType,
                      Map<Element, ConcreteType> environment,
                      [LocalsHandler<ConcreteType> handler])
      : super(element, inferrer.compiler, inferrer, handler);

  @override
  ConcreteType visitFunctionExpression(FunctionExpression node) {
    Element element = elements[node];
    // visitFunctionExpression should be only called for closures
    assert(element != analyzedElement);
    inferrer.addClosure(
        element, thisType, new LocalsHandler.deepCopyOf(locals));
    return types.functionType;
  }

  @override
  ConcreteType visitLiteralString(LiteralString node) {
    // TODO(polux): get rid of this hack once we have a natural way of inferring
    // the unknown type.
    if (inferrer.testMode
        && (node.dartString.slowToString() == "__dynamic_for_test")) {
      return inferrer.unknownConcreteType;
    }
    return super.visitLiteralString(node);
  }

  /**
   * Same as super.visitLiteralList except it doesn't cache anything.
   */
  @override
  ConcreteType visitLiteralList(LiteralList node) {
    ConcreteType elementType;
    int length = 0;
    for (Node element in node.elements.nodes) {
      ConcreteType type = visit(element);
      elementType = elementType == null
          ? types.allocatePhi(null, null, type)
          : types.addPhiInput(null, elementType, type);
      length++;
    }
    elementType = elementType == null
        ? types.nonNullEmpty()
        : types.simplifyPhi(null, null, elementType);
    ConcreteType containerType = node.isConst
        ? types.constListType
        : types.growableListType;
    return types.allocateList(
        containerType,
        node,
        outermostElement,
        elementType,
        length);
  }

  /**
   * Same as super.visitGetterSend except it records the type of nodes in test
   * mode.
   */
  @override
  ConcreteType visitGetterSend(Send node) {
    if (inferrer.testMode) {
      var element = elements[node];
      if (element is Local) {
        ConcreteType type = locals.use(element);
        if (type != null) {
          inferrer.augmentInferredType(node, type);
        }
      }
    }
    return super.visitGetterSend(node);
  }
}
