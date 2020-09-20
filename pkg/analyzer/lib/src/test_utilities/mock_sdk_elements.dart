// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:meta/meta.dart';

class MockSdkElements {
  final LibraryElement coreLibrary;
  final LibraryElement asyncLibrary;

  factory MockSdkElements(
    engine.AnalysisContext analysisContext,
    AnalysisSessionImpl analysisSession,
  ) {
    var builder = _MockSdkElementsBuilder(analysisContext, analysisSession);
    var coreLibrary = builder._buildCore();
    var asyncLibrary = builder._buildAsync();
    return MockSdkElements._(coreLibrary, asyncLibrary);
  }

  MockSdkElements._(this.coreLibrary, this.asyncLibrary);
}

class _MockSdkElementsBuilder {
  final engine.AnalysisContext analysisContext;
  final AnalysisSessionImpl analysisSession;

  ClassElementImpl _boolElement;
  ClassElementImpl _comparableElement;
  ClassElementImpl _completerElement;
  ClassElementImpl _deprecatedElement;
  ClassElementImpl _doubleElement;
  ClassElementImpl _functionElement;
  ClassElementImpl _futureElement;
  ClassElementImpl _futureOrElement;
  ClassElementImpl _intElement;
  ClassElementImpl _iterableElement;
  ClassElementImpl _iteratorElement;
  ClassElementImpl _listElement;
  ClassElementImpl _mapElement;
  ClassElementImpl _nullElement;
  ClassElementImpl _numElement;
  ClassElementImpl _objectElement;
  ClassElementImpl _overrideElement;
  ClassElementImpl _proxyElement;
  ClassElementImpl _setElement;
  ClassElementImpl _stackTraceElement;
  ClassElementImpl _streamElement;
  ClassElementImpl _streamSubscriptionElement;
  ClassElementImpl _stringElement;
  ClassElementImpl _symbolElement;
  ClassElementImpl _typeElement;

  InterfaceType _boolType;
  InterfaceType _doubleType;
  InterfaceType _intType;
  InterfaceType _numType;
  InterfaceType _objectType;
  InterfaceType _stringType;
  InterfaceType _typeType;

  _MockSdkElementsBuilder(
    this.analysisContext,
    this.analysisSession,
  );

  ClassElementImpl get boolElement {
    if (_boolElement != null) return _boolElement;

    _boolElement = _class(name: 'bool');
    _boolElement.supertype = objectType;

    _boolElement.constructors = [
      _constructor(
        name: 'fromEnvironment',
        isConst: true,
        isFactory: true,
        parameters: [
          _requiredParameter('name', stringType),
          _namedParameter('defaultValue', boolType),
        ],
      ),
    ];

    return _boolElement;
  }

  InterfaceType get boolType {
    return _boolType ??= _interfaceType(boolElement);
  }

  ClassElementImpl get comparableElement {
    if (_comparableElement != null) return _comparableElement;

    var tElement = _typeParameter('T');
    _comparableElement = _class(
      name: 'Comparable',
      isAbstract: true,
      typeParameters: [tElement],
    );
    _comparableElement.supertype = objectType;

    return _comparableElement;
  }

  ClassElementImpl get completerElement {
    if (_completerElement != null) return _completerElement;

    var tElement = _typeParameter('T');
    _completerElement = _class(
      name: 'Completer',
      isAbstract: true,
      typeParameters: [tElement],
    );
    _completerElement.supertype = objectType;

    return _completerElement;
  }

  ClassElementImpl get deprecatedElement {
    if (_deprecatedElement != null) return _deprecatedElement;

    _deprecatedElement = _class(name: 'Deprecated');
    _deprecatedElement.supertype = objectType;

    _deprecatedElement.fields = <FieldElement>[
      _field('message', stringType, isFinal: true),
    ];

    _deprecatedElement.accessors =
        _deprecatedElement.fields.map((f) => f.getter).toList();

    _deprecatedElement.constructors = [
      _constructor(
        isConst: true,
        parameters: [
          _requiredParameter('message', stringType),
        ],
      ),
    ];

    return _deprecatedElement;
  }

  ClassElementImpl get doubleElement {
    if (_doubleElement != null) return _doubleElement;

    _doubleElement = _class(name: 'double', isAbstract: true);
    _doubleElement.supertype = numType;

    FieldElement staticConstDoubleField(String name) {
      return _field(name, doubleType, isStatic: true, isConst: true);
    }

    _doubleElement.fields = <FieldElement>[
      staticConstDoubleField('nan'),
      staticConstDoubleField('infinity'),
      staticConstDoubleField('negativeInfinity'),
      staticConstDoubleField('minPositive'),
      staticConstDoubleField('maxFinite'),
    ];

    _doubleElement.accessors =
        _doubleElement.fields.map((field) => field.getter).toList();

    _doubleElement.methods = [
      _method('+', doubleType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('*', doubleType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('-', doubleType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('%', doubleType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('/', doubleType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('~/', intType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('-', doubleType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('abs', doubleType),
      _method('ceil', doubleType),
      _method('floor', doubleType),
      _method('remainder', doubleType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('round', doubleType),
      _method('toString', stringType),
      _method('truncate', doubleType),
    ];

    return _doubleElement;
  }

  InterfaceType get doubleType {
    return _doubleType ??= _interfaceType(doubleElement);
  }

  DynamicTypeImpl get dynamicType => DynamicTypeImpl.instance;

  ClassElementImpl get functionElement {
    if (_functionElement != null) return _functionElement;

    _functionElement = _class(name: 'Function', isAbstract: true);
    _functionElement.supertype = objectType;

    return _functionElement;
  }

  InterfaceType get functionType {
    return _interfaceType(functionElement);
  }

  ClassElementImpl get futureElement {
    if (_futureElement != null) return _futureElement;

    var tElement = _typeParameter('T');
    var tType = _typeParameterType(tElement);

    _futureElement = _class(
      name: 'Future',
      isAbstract: true,
      typeParameters: [tElement],
    );
    _futureElement.supertype = objectType;

    //   factory Future.value([FutureOr<T> value])
    _futureElement.constructors = [
      _constructor(
        isFactory: true,
        parameters: [
          _positionalParameter('value', futureOrType(tType)),
        ],
      ),
    ];

    //   Future<R> then<R>(FutureOr<R> onValue(T value), {Function onError})
    var rElement = _typeParameter('R');
    var rType = _typeParameterType(rElement);
    _futureElement.methods = [
      _method(
        'then',
        futureType(rType),
        parameters: [
          _requiredParameter(
            'onValue',
            _functionType(
              returnType: futureOrType(rType),
              parameters: [
                _requiredParameter('value', tType),
              ],
            ),
          ),
          _positionalParameter('onError', functionType),
        ],
      ),
    ];

    return _futureElement;
  }

  ClassElementImpl get futureOrElement {
    if (_futureOrElement != null) return _futureOrElement;

    var tElement = _typeParameter('T');
    _futureOrElement = _class(
      name: 'FutureOr',
      typeParameters: [tElement],
    );
    _futureOrElement.supertype = objectType;

    return _futureOrElement;
  }

  ClassElementImpl get intElement {
    if (_intElement != null) return _intElement;

    _intElement = _class(name: 'int', isAbstract: true);
    _intElement.supertype = numType;

    _intElement.constructors = [
      _constructor(
        name: 'fromEnvironment',
        isConst: true,
        isFactory: true,
        parameters: [
          _requiredParameter('name', stringType),
          _namedParameter('defaultValue', intType),
        ],
      ),
    ];

    _intElement.methods = [
      _method('&', intType, parameters: [
        _requiredParameter('other', intType),
      ]),
      _method('|', intType, parameters: [
        _requiredParameter('other', intType),
      ]),
      _method('^', intType, parameters: [
        _requiredParameter('other', intType),
      ]),
      _method('~', intType),
      _method('<<', intType, parameters: [
        _requiredParameter('shiftAmount', intType),
      ]),
      _method('>>', intType, parameters: [
        _requiredParameter('shiftAmount', intType),
      ]),
      _method('-', intType),
      _method('abs', intType),
      _method('round', intType),
      _method('floor', intType),
      _method('ceil', intType),
      _method('truncate', intType),
      _method('toString', stringType),
    ];

    return _intElement;
  }

  InterfaceType get intType {
    return _intType ??= _interfaceType(intElement);
  }

  ClassElementImpl get iterableElement {
    if (_iterableElement != null) return _iterableElement;

    var eElement = _typeParameter('E');
    var eType = _typeParameterType(eElement);

    _iterableElement = _class(
      name: 'Iterable',
      isAbstract: true,
      typeParameters: [eElement],
    );
    _iterableElement.supertype = objectType;

    _iterableElement.constructors = [
      _constructor(isConst: true),
    ];

    _setAccessors(_iterableElement, [
      _getter('iterator', iteratorType(eType)),
      _getter('last', eType),
    ]);

    return _iterableElement;
  }

  ClassElementImpl get iteratorElement {
    if (_iteratorElement != null) return _iteratorElement;

    var eElement = _typeParameter('E');
    var eType = _typeParameterType(eElement);

    _iteratorElement = _class(
      name: 'Iterator',
      isAbstract: true,
      typeParameters: [eElement],
    );
    _iteratorElement.supertype = objectType;

    _setAccessors(_iterableElement, [
      _getter('current', eType),
    ]);

    return _iteratorElement;
  }

  ClassElementImpl get listElement {
    if (_listElement != null) return _listElement;

    var eElement = _typeParameter('E');
    var eType = _typeParameterType(eElement);

    _listElement = _class(
      name: 'List',
      isAbstract: true,
      typeParameters: [eElement],
    );
    _listElement.supertype = objectType;
    _listElement.interfaces = [
      iterableType(eType),
    ];

    _listElement.constructors = [
      _constructor(isFactory: true, parameters: [
        _positionalParameter('length', intType),
      ]),
    ];

    _setAccessors(_listElement, [
      _getter('length', intType),
    ]);

    _listElement.methods = [
      _method('[]', eType, parameters: [
        _requiredParameter('index', intType),
      ]),
      _method('[]=', voidType, parameters: [
        _requiredParameter('index', intType),
        _requiredParameter('value', eType),
      ]),
      _method('add', voidType, parameters: [
        _requiredParameter('value', eType),
      ]),
    ];

    return _listElement;
  }

  ClassElementImpl get mapElement {
    if (_mapElement != null) return _mapElement;

    var kElement = _typeParameter('K');
    var vElement = _typeParameter('V');
    var kType = _typeParameterType(kElement);
    var vType = _typeParameterType(vElement);

    _mapElement = _class(
      name: 'Map',
      isAbstract: true,
      typeParameters: [kElement, vElement],
    );
    _mapElement.supertype = objectType;

    _setAccessors(_mapElement, [
      _getter('length', intType),
    ]);

    _mapElement.methods = [
      _method('[]', vType, parameters: [
        _requiredParameter('key', objectType),
      ]),
      _method('[]=', voidType, parameters: [
        _requiredParameter('key', kType),
        _requiredParameter('value', vType),
      ]),
    ];

    return _mapElement;
  }

  ClassElementImpl get nullElement {
    if (_nullElement != null) return _nullElement;

    _nullElement = _class(name: 'Null');
    _nullElement.supertype = objectType;

    _nullElement.constructors = [
      _constructor(
        name: '_uninstantiatable',
        isFactory: true,
      ),
    ];

    return _nullElement;
  }

  ClassElementImpl get numElement {
    if (_numElement != null) return _numElement;

    _numElement = _class(name: 'num', isAbstract: true);
    _numElement.supertype = objectType;
    _numElement.interfaces = [
      _interfaceType(
        comparableElement,
        typeArguments: [numType],
      ),
    ];

    _numElement.methods = [
      _method('+', numType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('-', numType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('*', numType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('%', numType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('/', doubleType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('~/', intType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('-', numType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('remainder', numType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('<', boolType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('<=', boolType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('>', boolType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('>=', boolType, parameters: [
        _requiredParameter('other', numType),
      ]),
      _method('==', boolType, parameters: [
        _requiredParameter('other', objectType),
      ]),
      _method('abs', numType),
      _method('floor', numType),
      _method('ceil', numType),
      _method('round', numType),
      _method('truncate', numType),
      _method('toInt', intType),
      _method('toDouble', doubleType),
      _method('toStringAsFixed', stringType, parameters: [
        _requiredParameter('fractionDigits', intType),
      ]),
      _method('toStringAsExponential', stringType, parameters: [
        _requiredParameter('fractionDigits', intType),
      ]),
      _method('toStringAsPrecision', stringType, parameters: [
        _requiredParameter('precision', intType),
      ]),
    ];

    _setAccessors(_numElement, [
      _getter('isInfinite', boolType),
      _getter('isNaN', boolType),
      _getter('isNegative', boolType),
    ]);

    return _numElement;
  }

  InterfaceType get numType {
    return _numType ??= _interfaceType(numElement);
  }

  ClassElementImpl get objectElement {
    if (_objectElement != null) return _objectElement;

    _objectElement = ElementFactory.object;
    _objectElement.interfaces = const <InterfaceType>[];
    _objectElement.mixins = const <InterfaceType>[];
    _objectElement.typeParameters = const <TypeParameterElement>[];
    _objectElement.constructors = [
      _constructor(isConst: true),
    ];

    _objectElement.methods = [
      _method('toString', stringType),
      _method('==', boolType, parameters: [
        _requiredParameter('other', objectType),
      ]),
      _method('noSuchMethod', dynamicType, parameters: [
        _requiredParameter('other', dynamicType),
      ]),
    ];

    _setAccessors(_objectElement, [
      _getter('hashCode', intType),
      _getter('runtimeType', typeType),
    ]);

    return _objectElement;
  }

  InterfaceType get objectType {
    return _objectType ??= _interfaceType(objectElement);
  }

  ClassElementImpl get overrideElement {
    if (_overrideElement != null) return _overrideElement;

    _overrideElement = _class(name: '_Override');
    _overrideElement.supertype = objectType;

    _overrideElement.constructors = [
      _constructor(isConst: true),
    ];

    return _overrideElement;
  }

  ClassElementImpl get proxyElement {
    if (_proxyElement != null) return _proxyElement;

    _proxyElement = _class(name: '_Proxy');
    _proxyElement.supertype = objectType;

    _proxyElement.constructors = [
      _constructor(isConst: true),
    ];

    return _proxyElement;
  }

  ClassElementImpl get setElement {
    if (_setElement != null) return _setElement;

    var eElement = _typeParameter('E');
    var eType = _typeParameterType(eElement);

    _setElement = _class(
      name: 'Set',
      isAbstract: true,
      typeParameters: [eElement],
    );
    _setElement.supertype = objectType;
    _setElement.interfaces = [
      iterableType(eType),
    ];

    return _setElement;
  }

  ClassElementImpl get stackTraceElement {
    if (_stackTraceElement != null) return _stackTraceElement;

    _stackTraceElement = _class(name: 'StackTrace', isAbstract: true);
    _stackTraceElement.supertype = objectType;

    return _stackTraceElement;
  }

  ClassElementImpl get streamElement {
    if (_streamElement != null) return _streamElement;

    var tElement = _typeParameter('T');
    var tType = _typeParameterType(tElement);

    _streamElement = _class(
      name: 'Stream',
      isAbstract: true,
      typeParameters: [tElement],
    );
    _streamElement.isAbstract = true;
    _streamElement.supertype = objectType;

    //    StreamSubscription<T> listen(void onData(T event),
    //        {Function onError, void onDone(), bool cancelOnError});
    _streamElement.methods = [
      _method(
        'listen',
        streamSubscriptionType(tType),
        parameters: [
          _requiredParameter(
            'onData',
            _functionType(
              returnType: voidType,
              parameters: [
                _requiredParameter('event', tType),
              ],
            ),
          ),
          _namedParameter('onError', functionType),
          _namedParameter(
            'onDone',
            _functionType(returnType: voidType),
          ),
          _namedParameter('cancelOnError', boolType),
        ],
      ),
    ];

    return _streamElement;
  }

  ClassElementImpl get streamSubscriptionElement {
    if (_streamSubscriptionElement != null) return _streamSubscriptionElement;

    var tElement = _typeParameter('T');
    _streamSubscriptionElement = _class(
      name: 'StreamSubscription',
      isAbstract: true,
      typeParameters: [tElement],
    );
    _streamSubscriptionElement.supertype = objectType;

    return _streamSubscriptionElement;
  }

  ClassElementImpl get stringElement {
    if (_stringElement != null) return _stringElement;

    _stringElement = _class(name: 'String', isAbstract: true);
    _stringElement.supertype = objectType;

    _stringElement.constructors = [
      _constructor(
        name: 'fromEnvironment',
        isConst: true,
        isFactory: true,
        parameters: [
          _requiredParameter('name', stringType),
          _namedParameter('defaultValue', stringType),
        ],
      ),
    ];

    _setAccessors(_stringElement, [
      _getter('isEmpty', boolType),
      _getter('length', intType),
      _getter('codeUnits', listType(intType)),
    ]);

    _stringElement.methods = [
      _method('+', _stringType, parameters: [
        _requiredParameter('other', _stringType),
      ]),
      _method('toLowerCase', _stringType),
      _method('toUpperCase', _stringType),
    ];

    return _stringElement;
  }

  InterfaceType get stringType {
    return _stringType ??= _interfaceType(stringElement);
  }

  ClassElementImpl get symbolElement {
    if (_symbolElement != null) return _symbolElement;

    _symbolElement = _class(name: 'Symbol', isAbstract: true);
    _symbolElement.supertype = objectType;

    _symbolElement.constructors = [
      _constructor(
        isConst: true,
        isFactory: true,
        parameters: [
          _requiredParameter('name', stringType),
        ],
      ),
    ];

    return _symbolElement;
  }

  ClassElementImpl get typeElement {
    if (_typeElement != null) return _typeElement;

    _typeElement = _class(name: 'Type', isAbstract: true);
    _typeElement.supertype = objectType;

    return _typeElement;
  }

  InterfaceType get typeType {
    return _typeType ??= _interfaceType(typeElement);
  }

  VoidTypeImpl get voidType => VoidTypeImpl.instance;

  InterfaceType futureOrType(DartType elementType) {
    return _interfaceType(
      futureOrElement,
      typeArguments: [elementType],
    );
  }

  InterfaceType futureType(DartType elementType) {
    return _interfaceType(
      futureElement,
      typeArguments: [elementType],
    );
  }

  InterfaceType iterableType(DartType elementType) {
    return _interfaceType(
      iterableElement,
      typeArguments: [elementType],
    );
  }

  InterfaceType iteratorType(DartType elementType) {
    return _interfaceType(
      iteratorElement,
      typeArguments: [elementType],
    );
  }

  InterfaceType listType(DartType elementType) {
    return _interfaceType(
      listElement,
      typeArguments: [elementType],
    );
  }

  InterfaceType streamSubscriptionType(DartType valueType) {
    return _interfaceType(
      streamSubscriptionElement,
      typeArguments: [valueType],
    );
  }

  LibraryElementImpl _buildAsync() {
    var asyncLibrary = LibraryElementImpl(
      analysisContext,
      analysisSession,
      'dart.async',
      0,
      0,
      ExperimentStatus.latestWithNullSafety,
    );

    var asyncUnit = CompilationUnitElementImpl();
    var asyncSource = analysisContext.sourceFactory.forUri('dart:async');
    asyncUnit.librarySource = asyncUnit.source = asyncSource;
    asyncLibrary.definingCompilationUnit = asyncUnit;

    asyncUnit.types = <ClassElement>[
      completerElement,
      futureElement,
      futureOrElement,
      streamElement,
      streamSubscriptionElement
    ];

    return asyncLibrary;
  }

  LibraryElementImpl _buildCore() {
    var coreUnit = CompilationUnitElementImpl();

    var coreSource = analysisContext.sourceFactory.forUri('dart:core');
    coreUnit.librarySource = coreUnit.source = coreSource;

    coreUnit.types = <ClassElement>[
      boolElement,
      comparableElement,
      deprecatedElement,
      doubleElement,
      functionElement,
      intElement,
      iterableElement,
      iteratorElement,
      listElement,
      mapElement,
      nullElement,
      numElement,
      objectElement,
      overrideElement,
      proxyElement,
      setElement,
      stackTraceElement,
      stringElement,
      symbolElement,
      typeElement,
    ];

    coreUnit.functions = <FunctionElement>[
      _function('identical', boolType, parameters: [
        _requiredParameter('a', objectType),
        _requiredParameter('b', objectType),
      ]),
      _function('print', voidType, parameters: [
        _requiredParameter('object', objectType),
      ]),
    ];

    var deprecatedVariable = _topLevelVariable(
      'deprecated',
      _interfaceType(deprecatedElement),
      isConst: true,
    );

    var overrideVariable = _topLevelVariable(
      'override',
      _interfaceType(overrideElement),
      isConst: true,
    );

    var proxyVariable = _topLevelVariable(
      'proxy',
      _interfaceType(proxyElement),
      isConst: true,
    );

    coreUnit.accessors = <PropertyAccessorElement>[
      deprecatedVariable.getter,
      overrideVariable.getter,
      proxyVariable.getter,
    ];
    coreUnit.topLevelVariables = <TopLevelVariableElement>[
      deprecatedVariable,
      overrideVariable,
      proxyVariable,
    ];

    var coreLibrary = LibraryElementImpl(
      analysisContext,
      analysisSession,
      'dart.core',
      0,
      0,
      ExperimentStatus.latestWithNullSafety,
    );
    coreLibrary.definingCompilationUnit = coreUnit;

    return coreLibrary;
  }

  ClassElementImpl _class({
    @required String name,
    bool isAbstract = false,
    List<TypeParameterElement> typeParameters = const [],
  }) {
    var element = ClassElementImpl(name, 0);
    element.typeParameters = typeParameters;
    element.constructors = <ConstructorElement>[
      _constructor(),
    ];
    return element;
  }

  ConstructorElement _constructor({
    String name = '',
    bool isConst = false,
    bool isFactory = false,
    List<ParameterElement> parameters = const [],
  }) {
    var element = ConstructorElementImpl(name, 0);
    element.isFactory = isFactory;
    element.isConst = isConst;
    element.parameters = parameters;
    return element;
  }

  FieldElement _field(
    String name,
    DartType type, {
    bool isConst = false,
    bool isFinal = false,
    bool isStatic = false,
  }) {
    return ElementFactory.fieldElement(name, isStatic, isFinal, isConst, type);
  }

  FunctionElement _function(
    String name,
    DartType returnType, {
    List<TypeParameterElement> typeFormals = const [],
    List<ParameterElement> parameters = const [],
  }) {
    return FunctionElementImpl(name, 0)
      ..parameters = parameters
      ..returnType = returnType
      ..typeParameters = typeFormals;
  }

  FunctionType _functionType({
    @required DartType returnType,
    List<TypeParameterElement> typeFormals = const [],
    List<ParameterElement> parameters = const [],
  }) {
    return FunctionTypeImpl(
      typeFormals: typeFormals,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  PropertyAccessorElement _getter(
    String name,
    DartType type, {
    bool isStatic = false,
  }) {
    var field = FieldElementImpl(name, -1);
    field.isFinal = true;
    field.isStatic = isStatic;
    field.isSynthetic = true;
    field.type = type;

    var getter = PropertyAccessorElementImpl(name, 0);
    getter.isGetter = true;
    getter.isStatic = isStatic;
    getter.isSynthetic = false;
    getter.returnType = type;
    getter.variable = field;

    field.getter = getter;
    return getter;
  }

  InterfaceType _interfaceType(
    ClassElement element, {
    List<DartType> typeArguments = const [],
  }) {
    return InterfaceTypeImpl(
      element: element,
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  MethodElement _method(
    String name,
    DartType returnType, {
    List<TypeParameterElement> typeFormals = const [],
    List<ParameterElement> parameters = const [],
  }) {
    return MethodElementImpl(name, 0)
      ..parameters = parameters
      ..returnType = returnType
      ..typeParameters = typeFormals;
  }

  ParameterElement _namedParameter(String name, DartType type,
      {String initializerCode}) {
    var parameter = DefaultParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.NAMED;
    parameter.type = type;
    parameter.defaultValueCode = initializerCode;
    return parameter;
  }

  ParameterElement _positionalParameter(String name, DartType type) {
    var parameter = ParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.POSITIONAL;
    parameter.type = type;
    return parameter;
  }

  ParameterElement _requiredParameter(String name, DartType type) {
    var parameter = ParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.REQUIRED;
    parameter.type = type;
    return parameter;
  }

  /// Set the [accessors] and the corresponding fields for the [classElement].
  void _setAccessors(
    ClassElementImpl classElement,
    List<PropertyAccessorElement> accessors,
  ) {
    classElement.accessors = accessors;
    classElement.fields = accessors
        .map((accessor) => accessor.variable)
        .cast<FieldElement>()
        .toList();
  }

  TopLevelVariableElement _topLevelVariable(
    String name,
    DartType type, {
    bool isConst = false,
    bool isFinal = false,
  }) {
    return ElementFactory.topLevelVariableElement3(
        name, isConst, isFinal, type);
  }

  TypeParameterElementImpl _typeParameter(String name) {
    return TypeParameterElementImpl(name, 0);
  }

  TypeParameterType _typeParameterType(TypeParameterElement element) {
    return TypeParameterTypeImpl(
      element: element,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }
}
