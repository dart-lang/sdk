// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.testing.test_type_provider;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';

/**
 * A type provider that can be used by tests without creating the element model
 * for the core library.
 */
class TestTypeProvider implements TypeProvider {
  /**
   * The type representing the built-in type 'bool'.
   */
  InterfaceType _boolType;

  /**
   * The type representing the type 'bottom'.
   */
  DartType _bottomType;

  /**
   * The type representing the built-in type 'double'.
   */
  InterfaceType _doubleType;

  /**
   * The type representing the built-in type 'deprecated'.
   */
  InterfaceType _deprecatedType;

  /**
   * The type representing the built-in type 'dynamic'.
   */
  DartType _dynamicType;

  /**
   * The type representing the built-in type 'Function'.
   */
  InterfaceType _functionType;

  /**
   * The type representing 'Future<dynamic>'
   */
  InterfaceType _futureDynamicType;

  /**
   * The type representing 'Future<Null>'
   */
  InterfaceType _futureNullType;

  /**
   * The type representing the built-in type 'Future'
   */
  InterfaceType _futureType;

  /**
   * The type representing the built-in type 'int'.
   */
  InterfaceType _intType;

  /**
   * The type representing 'Iterable<dynamic>'
   */
  InterfaceType _iterableDynamicType;

  /**
   * The type representing the built-in type 'Iterable'.
   */
  InterfaceType _iterableType;

  /**
   * The type representing the built-in type 'Iterator'.
   */
  InterfaceType _iteratorType;

  /**
   * The type representing the built-in type 'List'.
   */
  InterfaceType _listType;

  /**
   * The type representing the built-in type 'Map'.
   */
  InterfaceType _mapType;

  /**
   * An shared object representing the value 'null'.
   */
  DartObjectImpl _nullObject;

  /**
   * The type representing the built-in type 'Null'.
   */
  InterfaceType _nullType;

  /**
   * The type representing the built-in type 'num'.
   */
  InterfaceType _numType;

  /**
   * The type representing the built-in type 'Object'.
   */
  InterfaceType _objectType;

  /**
   * The type representing the built-in type 'StackTrace'.
   */
  InterfaceType _stackTraceType;

  /**
   * The type representing 'Stream<dynamic>'.
   */
  InterfaceType _streamDynamicType;

  /**
   * The type representing the built-in type 'Stream'.
   */
  InterfaceType _streamType;

  /**
   * The type representing the built-in type 'String'.
   */
  InterfaceType _stringType;

  /**
   * The type representing the built-in type 'Symbol'.
   */
  InterfaceType _symbolType;

  /**
   * The type representing the built-in type 'Type'.
   */
  InterfaceType _typeType;

  /**
   * The type representing typenames that can't be resolved.
   */
  DartType _undefinedType;

  @override
  InterfaceType get boolType {
    if (_boolType == null) {
      ClassElementImpl boolElement = ElementFactory.classElement2("bool");
      _boolType = boolElement.type;
      ConstructorElementImpl fromEnvironment = ElementFactory
          .constructorElement(boolElement, "fromEnvironment", true);
      fromEnvironment.parameters = <ParameterElement>[
        ElementFactory.requiredParameter2("name", stringType),
        ElementFactory.namedParameter2("defaultValue", _boolType)
      ];
      fromEnvironment.factory = true;
      fromEnvironment.isCycleFree = true;
      boolElement.constructors = <ConstructorElement>[fromEnvironment];
    }
    return _boolType;
  }

  @override
  DartType get bottomType {
    if (_bottomType == null) {
      _bottomType = BottomTypeImpl.instance;
    }
    return _bottomType;
  }

  @override
  InterfaceType get deprecatedType {
    if (_deprecatedType == null) {
      ClassElementImpl deprecatedElement =
          ElementFactory.classElement2("Deprecated");
      ConstructorElementImpl constructor = ElementFactory.constructorElement(
          deprecatedElement, null, true, [stringType]);
      constructor.constantInitializers = <ConstructorInitializer>[
        AstFactory.constructorFieldInitializer(
            true, 'expires', AstFactory.identifier3('expires'))
      ];
      deprecatedElement.constructors = <ConstructorElement>[constructor];
      _deprecatedType = deprecatedElement.type;
    }
    return _deprecatedType;
  }

  @override
  InterfaceType get doubleType {
    if (_doubleType == null) {
      _initializeNumericTypes();
    }
    return _doubleType;
  }

  @override
  DartType get dynamicType {
    if (_dynamicType == null) {
      _dynamicType = DynamicTypeImpl.instance;
    }
    return _dynamicType;
  }

  @override
  InterfaceType get functionType {
    if (_functionType == null) {
      _functionType = ElementFactory.classElement2("Function").type;
    }
    return _functionType;
  }

  @override
  InterfaceType get futureDynamicType {
    if (_futureDynamicType == null) {
      _futureDynamicType = futureType.substitute4(<DartType>[dynamicType]);
    }
    return _futureDynamicType;
  }

  @override
  InterfaceType get futureNullType {
    if (_futureNullType == null) {
      _futureNullType = futureType.substitute4(<DartType>[nullType]);
    }
    return _futureNullType;
  }

  @override
  InterfaceType get futureType {
    if (_futureType == null) {
      _futureType = ElementFactory.classElement2("Future", ["T"]).type;
    }
    return _futureType;
  }

  @override
  InterfaceType get intType {
    if (_intType == null) {
      _initializeNumericTypes();
    }
    return _intType;
  }

  @override
  InterfaceType get iterableDynamicType {
    if (_iterableDynamicType == null) {
      _iterableDynamicType = iterableType.substitute4(<DartType>[dynamicType]);
    }
    return _iterableDynamicType;
  }

  @override
  InterfaceType get iterableType {
    if (_iterableType == null) {
      ClassElementImpl iterableElement =
          ElementFactory.classElement2("Iterable", ["E"]);
      _iterableType = iterableElement.type;
      DartType eType = iterableElement.typeParameters[0].type;
      _setAccessors(iterableElement, <PropertyAccessorElement>[
        ElementFactory.getterElement(
            "iterator", false, iteratorType.substitute4(<DartType>[eType])),
        ElementFactory.getterElement("last", false, eType)
      ]);
      iterableElement.constructors = ConstructorElement.EMPTY_LIST;
      _propagateTypeArguments(iterableElement);
    }
    return _iterableType;
  }

  InterfaceType get iteratorType {
    if (_iteratorType == null) {
      ClassElementImpl iteratorElement =
          ElementFactory.classElement2("Iterator", ["E"]);
      _iteratorType = iteratorElement.type;
      DartType eType = iteratorElement.typeParameters[0].type;
      _setAccessors(iteratorElement, <PropertyAccessorElement>[
        ElementFactory.getterElement("current", false, eType)
      ]);
      iteratorElement.constructors = ConstructorElement.EMPTY_LIST;
      _propagateTypeArguments(iteratorElement);
    }
    return _iteratorType;
  }

  @override
  InterfaceType get listType {
    if (_listType == null) {
      ClassElementImpl listElement =
          ElementFactory.classElement2("List", ["E"]);
      listElement.constructors = <ConstructorElement>[
        ElementFactory.constructorElement2(listElement, null)
      ];
      _listType = listElement.type;
      DartType eType = listElement.typeParameters[0].type;
      InterfaceType iterableType =
          this.iterableType.substitute4(<DartType>[eType]);
      listElement.interfaces = <InterfaceType>[iterableType];
      _setAccessors(listElement, <PropertyAccessorElement>[
        ElementFactory.getterElement("length", false, intType)
      ]);
      listElement.methods = <MethodElement>[
        ElementFactory.methodElement("[]", eType, [intType]),
        ElementFactory.methodElement(
            "[]=", VoidTypeImpl.instance, [intType, eType]),
        ElementFactory.methodElement("add", VoidTypeImpl.instance, [eType])
      ];
      _propagateTypeArguments(listElement);
    }
    return _listType;
  }

  @override
  InterfaceType get mapType {
    if (_mapType == null) {
      ClassElementImpl mapElement =
          ElementFactory.classElement2("Map", ["K", "V"]);
      _mapType = mapElement.type;
      DartType kType = mapElement.typeParameters[0].type;
      DartType vType = mapElement.typeParameters[1].type;
      _setAccessors(mapElement, <PropertyAccessorElement>[
        ElementFactory.getterElement("length", false, intType)
      ]);
      mapElement.methods = <MethodElement>[
        ElementFactory.methodElement("[]", vType, [objectType]),
        ElementFactory.methodElement(
            "[]=", VoidTypeImpl.instance, [kType, vType])
      ];
      mapElement.constructors = ConstructorElement.EMPTY_LIST;
      _propagateTypeArguments(mapElement);
    }
    return _mapType;
  }

  @override
  List<InterfaceType> get nonSubtypableTypes => <InterfaceType>[
        nullType,
        numType,
        intType,
        doubleType,
        boolType,
        stringType
      ];

  @override
  DartObjectImpl get nullObject {
    if (_nullObject == null) {
      _nullObject = new DartObjectImpl(nullType, NullState.NULL_STATE);
    }
    return _nullObject;
  }

  @override
  InterfaceType get nullType {
    if (_nullType == null) {
      ClassElementImpl nullElement = ElementFactory.classElement2("Null");
      nullElement.constructors = ConstructorElement.EMPTY_LIST;
      _nullType = nullElement.type;
    }
    return _nullType;
  }

  @override
  InterfaceType get numType {
    if (_numType == null) {
      _initializeNumericTypes();
    }
    return _numType;
  }

  @override
  InterfaceType get objectType {
    if (_objectType == null) {
      ClassElementImpl objectElement = ElementFactory.object;
      _objectType = objectElement.type;
      ConstructorElementImpl constructor =
          ElementFactory.constructorElement(objectElement, null, true);
      constructor.constantInitializers = <ConstructorInitializer>[];
      objectElement.constructors = <ConstructorElement>[constructor];
      objectElement.methods = <MethodElement>[
        ElementFactory.methodElement("toString", stringType),
        ElementFactory.methodElement("==", boolType, [_objectType]),
        ElementFactory.methodElement("noSuchMethod", dynamicType, [dynamicType])
      ];
      _setAccessors(objectElement, <PropertyAccessorElement>[
        ElementFactory.getterElement("hashCode", false, intType),
        ElementFactory.getterElement("runtimeType", false, typeType)
      ]);
    }
    return _objectType;
  }

  @override
  InterfaceType get stackTraceType {
    if (_stackTraceType == null) {
      _stackTraceType = ElementFactory.classElement2("StackTrace").type;
    }
    return _stackTraceType;
  }

  @override
  InterfaceType get streamDynamicType {
    if (_streamDynamicType == null) {
      _streamDynamicType = streamType.substitute4(<DartType>[dynamicType]);
    }
    return _streamDynamicType;
  }

  @override
  InterfaceType get streamType {
    if (_streamType == null) {
      _streamType = ElementFactory.classElement2("Stream", ["T"]).type;
    }
    return _streamType;
  }

  @override
  InterfaceType get stringType {
    if (_stringType == null) {
      _stringType = ElementFactory.classElement2("String").type;
      ClassElementImpl stringElement = _stringType.element as ClassElementImpl;
      _setAccessors(stringElement, <PropertyAccessorElement>[
        ElementFactory.getterElement("isEmpty", false, boolType),
        ElementFactory.getterElement("length", false, intType),
        ElementFactory.getterElement(
            "codeUnits", false, listType.substitute4(<DartType>[intType]))
      ]);
      stringElement.methods = <MethodElement>[
        ElementFactory.methodElement("+", _stringType, [_stringType]),
        ElementFactory.methodElement("toLowerCase", _stringType),
        ElementFactory.methodElement("toUpperCase", _stringType)
      ];
      ConstructorElementImpl fromEnvironment = ElementFactory
          .constructorElement(stringElement, "fromEnvironment", true);
      fromEnvironment.parameters = <ParameterElement>[
        ElementFactory.requiredParameter2("name", stringType),
        ElementFactory.namedParameter2("defaultValue", _stringType)
      ];
      fromEnvironment.factory = true;
      fromEnvironment.isCycleFree = true;
      stringElement.constructors = <ConstructorElement>[fromEnvironment];
    }
    return _stringType;
  }

  @override
  InterfaceType get symbolType {
    if (_symbolType == null) {
      ClassElementImpl symbolClass = ElementFactory.classElement2("Symbol");
      ConstructorElementImpl constructor = ElementFactory.constructorElement(
          symbolClass, null, true, [stringType]);
      constructor.factory = true;
      constructor.isCycleFree = true;
      symbolClass.constructors = <ConstructorElement>[constructor];
      _symbolType = symbolClass.type;
    }
    return _symbolType;
  }

  @override
  InterfaceType get typeType {
    if (_typeType == null) {
      _typeType = ElementFactory.classElement2("Type").type;
    }
    return _typeType;
  }

  @override
  DartType get undefinedType {
    if (_undefinedType == null) {
      _undefinedType = UndefinedTypeImpl.instance;
    }
    return _undefinedType;
  }

  /**
   * Initialize the numeric types. They are created as a group so that we can
   * (a) create the right hierarchy and (b) add members to them.
   */
  void _initializeNumericTypes() {
    //
    // Create the type hierarchy.
    //
    ClassElementImpl numElement = ElementFactory.classElement2("num");
    _numType = numElement.type;
    ClassElementImpl intElement = ElementFactory.classElement("int", _numType);
    _intType = intElement.type;
    ClassElementImpl doubleElement =
        ElementFactory.classElement("double", _numType);
    _doubleType = doubleElement.type;
    //
    // Force the referenced types to be cached.
    //
    objectType;
    boolType;
    stringType;
    //
    // Add the methods.
    //
    numElement.methods = <MethodElement>[
      ElementFactory.methodElement("+", _numType, [_numType]),
      ElementFactory.methodElement("-", _numType, [_numType]),
      ElementFactory.methodElement("*", _numType, [_numType]),
      ElementFactory.methodElement("%", _numType, [_numType]),
      ElementFactory.methodElement("/", _doubleType, [_numType]),
      ElementFactory.methodElement("~/", _numType, [_numType]),
      ElementFactory.methodElement("-", _numType),
      ElementFactory.methodElement("remainder", _numType, [_numType]),
      ElementFactory.methodElement("<", _boolType, [_numType]),
      ElementFactory.methodElement("<=", _boolType, [_numType]),
      ElementFactory.methodElement(">", _boolType, [_numType]),
      ElementFactory.methodElement(">=", _boolType, [_numType]),
      ElementFactory.methodElement("==", _boolType, [_objectType]),
      ElementFactory.methodElement("isNaN", _boolType),
      ElementFactory.methodElement("isNegative", _boolType),
      ElementFactory.methodElement("isInfinite", _boolType),
      ElementFactory.methodElement("abs", _numType),
      ElementFactory.methodElement("floor", _numType),
      ElementFactory.methodElement("ceil", _numType),
      ElementFactory.methodElement("round", _numType),
      ElementFactory.methodElement("truncate", _numType),
      ElementFactory.methodElement("toInt", _intType),
      ElementFactory.methodElement("toDouble", _doubleType),
      ElementFactory.methodElement("toStringAsFixed", _stringType, [_intType]),
      ElementFactory.methodElement(
          "toStringAsExponential", _stringType, [_intType]),
      ElementFactory.methodElement(
          "toStringAsPrecision", _stringType, [_intType]),
      ElementFactory.methodElement("toRadixString", _stringType, [_intType])
    ];
    intElement.methods = <MethodElement>[
      ElementFactory.methodElement("&", _intType, [_intType]),
      ElementFactory.methodElement("|", _intType, [_intType]),
      ElementFactory.methodElement("^", _intType, [_intType]),
      ElementFactory.methodElement("~", _intType),
      ElementFactory.methodElement("<<", _intType, [_intType]),
      ElementFactory.methodElement(">>", _intType, [_intType]),
      ElementFactory.methodElement("-", _intType),
      ElementFactory.methodElement("abs", _intType),
      ElementFactory.methodElement("round", _intType),
      ElementFactory.methodElement("floor", _intType),
      ElementFactory.methodElement("ceil", _intType),
      ElementFactory.methodElement("truncate", _intType),
      ElementFactory.methodElement("toString", _stringType)
    ];
    ConstructorElementImpl fromEnvironment =
        ElementFactory.constructorElement(intElement, "fromEnvironment", true);
    fromEnvironment.parameters = <ParameterElement>[
      ElementFactory.requiredParameter2("name", stringType),
      ElementFactory.namedParameter2("defaultValue", _intType)
    ];
    fromEnvironment.factory = true;
    fromEnvironment.isCycleFree = true;
    numElement.constructors = ConstructorElement.EMPTY_LIST;
    intElement.constructors = <ConstructorElement>[fromEnvironment];
    doubleElement.constructors = ConstructorElement.EMPTY_LIST;
    List<FieldElement> fields = <FieldElement>[
      ElementFactory.fieldElement("NAN", true, false, true, _doubleType),
      ElementFactory.fieldElement("INFINITY", true, false, true, _doubleType),
      ElementFactory.fieldElement(
          "NEGATIVE_INFINITY", true, false, true, _doubleType),
      ElementFactory.fieldElement(
          "MIN_POSITIVE", true, false, true, _doubleType),
      ElementFactory.fieldElement("MAX_FINITE", true, false, true, _doubleType)
    ];
    doubleElement.fields = fields;
    int fieldCount = fields.length;
    List<PropertyAccessorElement> accessors =
        new List<PropertyAccessorElement>(fieldCount);
    for (int i = 0; i < fieldCount; i++) {
      accessors[i] = fields[i].getter;
    }
    doubleElement.accessors = accessors;
    doubleElement.methods = <MethodElement>[
      ElementFactory.methodElement("remainder", _doubleType, [_numType]),
      ElementFactory.methodElement("+", _doubleType, [_numType]),
      ElementFactory.methodElement("-", _doubleType, [_numType]),
      ElementFactory.methodElement("*", _doubleType, [_numType]),
      ElementFactory.methodElement("%", _doubleType, [_numType]),
      ElementFactory.methodElement("/", _doubleType, [_numType]),
      ElementFactory.methodElement("~/", _doubleType, [_numType]),
      ElementFactory.methodElement("-", _doubleType),
      ElementFactory.methodElement("abs", _doubleType),
      ElementFactory.methodElement("round", _doubleType),
      ElementFactory.methodElement("floor", _doubleType),
      ElementFactory.methodElement("ceil", _doubleType),
      ElementFactory.methodElement("truncate", _doubleType),
      ElementFactory.methodElement("toString", _stringType)
    ];
  }

  /**
   * Given a [classElement] representing a class with type parameters, propagate
   * those type parameters to all of the accessors, methods and constructors
   * defined for the class.
   */
  void _propagateTypeArguments(ClassElementImpl classElement) {
    List<DartType> typeArguments =
        TypeParameterTypeImpl.getTypes(classElement.typeParameters);
    for (PropertyAccessorElement accessor in classElement.accessors) {
      FunctionTypeImpl functionType = accessor.type as FunctionTypeImpl;
      functionType.typeArguments = typeArguments;
    }
    for (MethodElement method in classElement.methods) {
      FunctionTypeImpl functionType = method.type as FunctionTypeImpl;
      functionType.typeArguments = typeArguments;
    }
    for (ConstructorElement constructor in classElement.constructors) {
      FunctionTypeImpl functionType = constructor.type as FunctionTypeImpl;
      functionType.typeArguments = typeArguments;
    }
  }

  /**
   * Set the accessors for the given class [element] to the given [accessors]
   * and also set the fields to those that correspond to the accessors.
   */
  void _setAccessors(
      ClassElementImpl element, List<PropertyAccessorElement> accessors) {
    element.accessors = accessors;
    element.fields = accessors
        .map((PropertyAccessorElement accessor) => accessor.variable)
        .toList();
  }
}
