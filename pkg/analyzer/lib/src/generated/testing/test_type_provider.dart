// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/string_source.dart';

/**
 * A type provider that can be used by tests without creating the element model
 * for the core library.
 */
class TestTypeProvider extends TypeProviderBase {
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
   * The type representing the built-in type 'FutureOr'
   */
  InterfaceType _futureOrNullType;

  /**
   * The type representing the built-in type 'FutureOr'
   */
  InterfaceType _futureOrType;

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
   * The type representing type names that can't be resolved.
   */
  DartType _undefinedType;

  /**
   * The analysis context, if any. Used to create an appropriate 'dart:async'
   * library to back `Future<T>`.
   */
  AnalysisContext _context;

  TestTypeProvider([this._context]);

  @override
  InterfaceType get boolType {
    if (_boolType == null) {
      ClassElementImpl boolElement = ElementFactory.classElement2("bool");
      _boolType = boolElement.type;
      ConstructorElementImpl fromEnvironment = ElementFactory
          .constructorElement(boolElement, "fromEnvironment", true);
      fromEnvironment.parameters = <ParameterElement>[
        ElementFactory.requiredParameter2("name", stringType),
        ElementFactory.namedParameter3("defaultValue",
            type: _boolType,
            initializer: AstTestFactory.booleanLiteral(false),
            initializerCode: 'false')
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
      FieldElementImpl expiresField = ElementFactory.fieldElement(
          'expires', false, true, false, stringType);
      deprecatedElement.fields = <FieldElement>[expiresField];
      deprecatedElement.accessors = <PropertyAccessorElement>[
        expiresField.getter
      ];
      ConstructorElementImpl constructor = ElementFactory
          .constructorElement(deprecatedElement, '', true, [stringType]);
      (constructor.parameters[0] as ParameterElementImpl).name = 'expires';
      ConstructorFieldInitializer expiresInit =
          AstTestFactory.constructorFieldInitializer(
              true, 'expires', AstTestFactory.identifier3('expires'));
      expiresInit.fieldName.staticElement = expiresField;
      (expiresInit.expression as SimpleIdentifier).staticElement =
          constructor.parameters[0];
      constructor.constantInitializers = <ConstructorInitializer>[expiresInit];
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
      ClassElementImpl functionClass = ElementFactory.classElement2("Function");
      functionClass.constructors = <ConstructorElement>[
        ElementFactory.constructorElement(functionClass, null, false)
      ];
      _functionType = functionClass.type;
    }
    return _functionType;
  }

  @override
  InterfaceType get futureDynamicType {
    if (_futureDynamicType == null) {
      _futureDynamicType = futureType.instantiate(<DartType>[dynamicType]);
    }
    return _futureDynamicType;
  }

  @override
  InterfaceType get futureNullType {
    if (_futureNullType == null) {
      _futureNullType = futureType.instantiate(<DartType>[nullType]);
    }
    return _futureNullType;
  }

  @override
  InterfaceType get futureOrNullType {
    if (_futureOrNullType == null) {
      _futureOrNullType = futureOrType.instantiate(<DartType>[nullType]);
    }
    return _futureOrNullType;
  }

  @override
  InterfaceType get futureOrType {
    if (_futureOrType == null) {
      _initDartAsync();
    }
    return _futureOrType;
  }

  @override
  InterfaceType get futureType {
    if (_futureType == null) {
      _initDartAsync();
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
      _iterableDynamicType = iterableType.instantiate(<DartType>[dynamicType]);
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
            "iterator", false, iteratorType.instantiate(<DartType>[eType])),
        ElementFactory.getterElement("last", false, eType)
      ]);
      iterableElement.constructors = <ConstructorElement>[
        ElementFactory.constructorElement(iterableElement, '', true)
          ..isCycleFree = true
      ];
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
      iteratorElement.constructors = <ConstructorElement>[
        ElementFactory.constructorElement(iteratorElement, null, false)
      ];
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
          this.iterableType.instantiate(<DartType>[eType]);
      listElement.interfaces = <InterfaceType>[iterableType];
      _setAccessors(listElement, <PropertyAccessorElement>[
        ElementFactory.getterElement("length", false, intType)
      ]);
      listElement.methods = <MethodElement>[
        ElementFactory.methodElement("[]", eType, [intType]),
        ElementFactory
            .methodElement("[]=", VoidTypeImpl.instance, [intType, eType]),
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
        ElementFactory
            .methodElement("[]=", VoidTypeImpl.instance, [kType, vType])
      ];
      mapElement.constructors = <ConstructorElement>[
        ElementFactory.constructorElement(mapElement, '', false)
          ..external = true
          ..factory = true
      ];
      _propagateTypeArguments(mapElement);
    }
    return _mapType;
  }

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
      var nullElement = ElementFactory.classElement2("Null");
      nullElement.constructors = <ConstructorElement>[
        ElementFactory.constructorElement(
            nullElement, '_uninstantiatable', false)
          ..factory = true
      ];
      // Create a library element for "dart:core"
      // This enables the "isDartCoreNull" getter.
      var library = new LibraryElementImpl.forNode(
          _context, AstTestFactory.libraryIdentifier2(["dart.core"]));
      var unit = new CompilationUnitElementImpl("core.dart");
      library.definingCompilationUnit = unit;
      unit.librarySource = unit.source = new StringSource('', null);

      nullElement.enclosingElement = library;
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
          ElementFactory.constructorElement(objectElement, '', true);
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
      ClassElementImpl stackTraceElement =
          ElementFactory.classElement2("StackTrace");
      stackTraceElement.constructors = <ConstructorElement>[
        ElementFactory.constructorElement(stackTraceElement, null, false)
      ];
      _stackTraceType = stackTraceElement.type;
    }
    return _stackTraceType;
  }

  @override
  InterfaceType get streamDynamicType {
    if (_streamDynamicType == null) {
      _streamDynamicType = streamType.instantiate(<DartType>[dynamicType]);
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
      ClassElementImpl stringElement = ElementFactory.classElement2("String");
      _stringType = stringElement.type;
      _setAccessors(stringElement, <PropertyAccessorElement>[
        ElementFactory.getterElement("isEmpty", false, boolType),
        ElementFactory.getterElement("length", false, intType),
        ElementFactory.getterElement(
            "codeUnits", false, listType.instantiate(<DartType>[intType]))
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
        ElementFactory.namedParameter3("defaultValue", type: _stringType)
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
      ConstructorElementImpl constructor = ElementFactory
          .constructorElement(symbolClass, '', true, [stringType]);
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
      ClassElementImpl typeClass = ElementFactory.classElement2("Type");
      typeClass.constructors = <ConstructorElement>[
        ElementFactory.constructorElement(typeClass, null, false)
          ..isSynthetic = true
      ];
      _typeType = typeClass.type;
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

  void _initDartAsync() {
    Source asyncSource = _context.sourceFactory.forUri(DartSdk.DART_ASYNC);
    _context.setContents(asyncSource, "");
    CompilationUnitElementImpl asyncUnit =
        new CompilationUnitElementImpl("async.dart");
    LibraryElementImpl asyncLibrary = new LibraryElementImpl.forNode(
        _context, AstTestFactory.libraryIdentifier2(["dart.async"]));
    asyncLibrary.definingCompilationUnit = asyncUnit;
    asyncUnit.librarySource = asyncUnit.source = asyncSource;

    ClassElementImpl future = ElementFactory.classElement2("Future", ["T"]);
    _futureType = future.type;
    asyncUnit.types = <ClassElement>[future];
    ClassElementImpl futureOr = ElementFactory.classElement2("FutureOr", ["T"]);
    _futureOrType = futureOr.type;
    asyncUnit.types = <ClassElement>[future, futureOr];
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
    nullType;
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
      ElementFactory.methodElement("abs", _numType),
      ElementFactory.methodElement("floor", _numType),
      ElementFactory.methodElement("ceil", _numType),
      ElementFactory.methodElement("round", _numType),
      ElementFactory.methodElement("truncate", _numType),
      ElementFactory.methodElement("toInt", _intType),
      ElementFactory.methodElement("toDouble", _doubleType),
      ElementFactory.methodElement("toStringAsFixed", _stringType, [_intType]),
      ElementFactory
          .methodElement("toStringAsExponential", _stringType, [_intType]),
      ElementFactory
          .methodElement("toStringAsPrecision", _stringType, [_intType]),
      ElementFactory.methodElement("toRadixString", _stringType, [_intType])
    ];
    numElement.accessors = [
      ElementFactory.getterElement('isInfinite', false, _boolType),
      ElementFactory.getterElement('isNaN', false, _boolType),
      ElementFactory.getterElement('isNegative', false, _boolType),
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
      ElementFactory.namedParameter3("defaultValue", type: _intType)
    ];
    fromEnvironment.factory = true;
    fromEnvironment.isCycleFree = true;
    numElement.constructors = <ConstructorElement>[
      ElementFactory.constructorElement(numElement, null, false)
        ..isSynthetic = true
    ];
    intElement.constructors = <ConstructorElement>[fromEnvironment];
    doubleElement.constructors = <ConstructorElement>[
      ElementFactory.constructorElement(doubleElement, null, false)
        ..isSynthetic = true
    ];
    ConstFieldElementImpl varINFINITY = ElementFactory.fieldElement(
        "INFINITY", true, false, true, _doubleType,
        initializer: AstTestFactory.doubleLiteral(double.infinity));
    varINFINITY.constantInitializer = AstTestFactory.binaryExpression(
        AstTestFactory.integer(1), TokenType.SLASH, AstTestFactory.integer(0));
    List<FieldElement> fields = <FieldElement>[
      ElementFactory.fieldElement("NAN", true, false, true, _doubleType,
          initializer: AstTestFactory.doubleLiteral(double.nan)),
      varINFINITY,
      ElementFactory.fieldElement(
          "NEGATIVE_INFINITY", true, false, true, _doubleType,
          initializer: AstTestFactory.doubleLiteral(double.negativeInfinity)),
      ElementFactory.fieldElement(
          "MIN_POSITIVE", true, false, true, _doubleType,
          initializer: AstTestFactory.doubleLiteral(double.minPositive)),
      ElementFactory.fieldElement("MAX_FINITE", true, false, true, _doubleType,
          initializer: AstTestFactory.doubleLiteral(double.maxFinite))
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
    for (PropertyAccessorElement accessor in classElement.accessors) {
      (accessor as ExecutableElementImpl).type = new FunctionTypeImpl(accessor);
    }
    for (MethodElement method in classElement.methods) {
      (method as ExecutableElementImpl).type = new FunctionTypeImpl(method);
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
        .cast<FieldElement>()
        .toList();
  }
}
