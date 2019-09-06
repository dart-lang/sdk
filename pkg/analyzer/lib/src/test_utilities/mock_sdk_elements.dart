// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:meta/meta.dart';

class MockSdkElements {
  final LibraryElement coreLibrary;
  final LibraryElement asyncLibrary;

  factory MockSdkElements(
    engine.AnalysisContext analysisContext,
    NullabilitySuffix nullabilitySuffix,
  ) {
    var builder = _MockSdkElementsBuilder(analysisContext, nullabilitySuffix);
    var coreLibrary = builder._buildCore();
    var asyncLibrary = builder._buildAsync();
    return MockSdkElements._(coreLibrary, asyncLibrary);
  }

  MockSdkElements._(this.coreLibrary, this.asyncLibrary);
}

class _MockSdkElementsBuilder {
  final engine.AnalysisContext analysisContext;
  final NullabilitySuffix nullabilitySuffix;

  ClassElementImpl _boolElement;
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

  _MockSdkElementsBuilder(this.analysisContext, this.nullabilitySuffix);

  ClassElementImpl get boolElement {
    if (_boolElement != null) return _boolElement;

    _boolElement = _class(name: 'bool');
    _boolElement.supertype = objectType;

    _boolElement.constructors = [
      _constructor(
        enclosingElement: _boolElement,
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

  ClassElementImpl get completerElement {
    if (_completerElement != null) return _completerElement;

    var tElement = _typeParameter('T');
    _completerElement = _class(
      name: 'Completer',
      typeParameters: [tElement],
    );
    _completerElement.supertype = objectType;

    _completerElement.constructors = [
      _constructor(enclosingElement: _completerElement),
    ];

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
        enclosingElement: _deprecatedElement,
        parameters: [
          _requiredParameter('message', stringType),
        ],
      ),
    ];

    return _deprecatedElement;
  }

  ClassElementImpl get doubleElement {
    if (_doubleElement != null) return _doubleElement;

    _doubleElement = _class(name: 'double');
    _doubleElement.supertype = numType;

    // TODO(scheglov) clean up
    ConstFieldElementImpl varINFINITY = ElementFactory.fieldElement(
        "INFINITY", true, false, true, doubleType,
        initializer: AstTestFactory.doubleLiteral(double.infinity));
    varINFINITY.constantInitializer = AstTestFactory.binaryExpression(
        AstTestFactory.integer(1), TokenType.SLASH, AstTestFactory.integer(0));
    _doubleElement.fields = <FieldElement>[
      ElementFactory.fieldElement("NAN", true, false, true, doubleType,
          initializer: AstTestFactory.doubleLiteral(double.nan)),
      varINFINITY,
      ElementFactory.fieldElement(
          "NEGATIVE_INFINITY", true, false, true, doubleType,
          initializer: AstTestFactory.doubleLiteral(double.negativeInfinity)),
      ElementFactory.fieldElement("MIN_POSITIVE", true, false, true, doubleType,
          initializer: AstTestFactory.doubleLiteral(double.minPositive)),
      ElementFactory.fieldElement("MAX_FINITE", true, false, true, doubleType,
          initializer: AstTestFactory.doubleLiteral(double.maxFinite)),
    ];

    _doubleElement.accessors =
        _doubleElement.fields.map((field) => field.getter).toList();

    _doubleElement.constructors = [
      _constructor(enclosingElement: _doubleElement)
    ];

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

    _functionElement = _class(name: 'Function');
    _functionElement.supertype = objectType;

    _listElement.constructors = [
      _constructor(enclosingElement: _functionElement),
    ];

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
      typeParameters: [tElement],
    );
    _futureElement.supertype = objectType;

    //   factory Future.value([FutureOr<T> value])
    _futureElement.constructors = [
      _constructor(
        enclosingElement: _futureElement,
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

    _intElement = _class(name: 'int');
    _intElement.supertype = numType;

    _intElement.constructors = [
      _constructor(
        enclosingElement: _intElement,
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
      typeParameters: [eElement],
    );
    _iterableElement.supertype = objectType;

    _iterableElement.constructors = [
      _constructor(enclosingElement: _iterableElement, isConst: true),
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
      typeParameters: [eElement],
    );
    _iteratorElement.supertype = objectType;

    _iteratorElement.constructors = [
      _constructor(enclosingElement: _iteratorElement),
    ];

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
      typeParameters: [eElement],
    );
    _listElement.supertype = objectType;
    _listElement.interfaces = [
      iterableType(eType),
    ];

    _listElement.constructors = [
      _constructor(enclosingElement: _listElement),
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
      typeParameters: [kElement, vElement],
    );
    _mapElement.supertype = objectType;

    _mapElement.constructors = [
      _constructor(enclosingElement: _listElement),
    ];

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
        enclosingElement: _nullElement,
        name: '_uninstantiatable',
        isFactory: true,
      ),
    ];

    return _nullElement;
  }

  ClassElementImpl get numElement {
    if (_numElement != null) return _numElement;

    _numElement = _class(name: 'num');
    _numElement.supertype = objectType;

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
      _constructor(enclosingElement: _objectElement),
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
      _constructor(enclosingElement: _overrideElement),
    ];

    return _overrideElement;
  }

  ClassElementImpl get proxyElement {
    if (_proxyElement != null) return _proxyElement;

    _proxyElement = _class(name: '_Proxy');
    _proxyElement.supertype = objectType;

    _proxyElement.constructors = [
      _constructor(enclosingElement: _proxyElement),
    ];

    return _proxyElement;
  }

  ClassElementImpl get setElement {
    if (_setElement != null) return _setElement;

    var eElement = _typeParameter('E');
    var eType = _typeParameterType(eElement);

    _setElement = _class(
      name: 'Set',
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

    _stackTraceElement = _class(name: 'StackTrace');
    _stackTraceElement.supertype = objectType;

    _stackTraceElement.constructors = [
      _constructor(enclosingElement: _stackTraceElement),
    ];

    return _stackTraceElement;
  }

  ClassElementImpl get streamElement {
    if (_streamElement != null) return _streamElement;

    var tElement = _typeParameter('T');
    var tType = _typeParameterType(tElement);

    _streamElement = _class(
      name: 'Stream',
      typeParameters: [tElement],
    );
    _streamElement.isAbstract = true;
    _streamElement.supertype = objectType;

    _streamElement.constructors = [
      _constructor(enclosingElement: _streamElement),
    ];

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
      name: 'StreamSubscriptionElement',
      typeParameters: [tElement],
    );
    _streamSubscriptionElement.supertype = objectType;

    return _streamSubscriptionElement;
  }

  ClassElementImpl get stringElement {
    if (_stringElement != null) return _stringElement;

    _stringElement = _class(name: 'String');
    _stringElement.supertype = objectType;

    _stringElement.constructors = [
      _constructor(
        enclosingElement: _stringElement,
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

    _symbolElement = _class(name: 'Symbol');
    _symbolElement.supertype = objectType;

    _symbolElement.constructors = [
      _constructor(
        enclosingElement: _symbolElement,
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

    _typeElement = _class(name: 'Type');
    _typeElement.supertype = objectType;

    _typeElement.constructors = [
      _constructor(enclosingElement: _typeElement),
    ];

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
      null,
      'dart.async',
      0,
      0,
      nullabilitySuffix == NullabilitySuffix.none,
    );

    var asyncUnit = new CompilationUnitElementImpl();
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

    // TODO(scheglov) clean up
    coreUnit.functions = <FunctionElement>[
      ElementFactory.functionElement3("identical", boolType,
          <ClassElement>[objectElement, objectElement], null),
      ElementFactory.functionElement3(
          "print", voidType, <ClassElement>[objectElement], null)
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

    // TODO(scheglov) something better?
    {
      InstanceCreationExpression initializer =
          AstTestFactory.instanceCreationExpression2(
        Keyword.CONST,
        AstTestFactory.typeName(deprecatedElement),
        [AstTestFactory.string2('next release')],
      );
      ConstructorElement constructor = deprecatedElement.constructors.single;
      initializer.staticElement = constructor;
      initializer.constructorName.staticElement = constructor;
      (deprecatedVariable as ConstTopLevelVariableElementImpl)
          .constantInitializer = initializer;
    }

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
      null,
      'dart.core',
      0,
      0,
      nullabilitySuffix == NullabilitySuffix.none,
    );
    coreLibrary.definingCompilationUnit = coreUnit;

    return coreLibrary;
  }

  ClassElementImpl _class({
    @required String name,
    List<TypeParameterElement> typeParameters = const [],
  }) {
    var element = ClassElementImpl(name, 0);
    element.typeParameters = typeParameters;
    element.constructors = const <ConstructorElement>[];
    return element;
  }

  ConstructorElement _constructor({
    @required ClassElementImpl enclosingElement,
    String name = '',
    bool isConst = false,
    bool isFactory = false,
    List<ParameterElement> parameters = const [],
    List<DartType> optional,
    Map<String, DartType> named,
  }) {
    var constructor = ElementFactory.constructorElement(
      enclosingElement,
      name,
      isConst,
    );
    constructor.constantInitializers = <ConstructorInitializer>[];
    constructor.factory = isFactory;
    constructor.parameters = parameters;
    return constructor;
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

  FunctionType _functionType({
    @required DartType returnType,
    List<TypeParameterElement> typeFormals = const [],
    List<ParameterElement> parameters = const [],
  }) {
    return FunctionTypeImpl.synthetic(returnType, typeFormals, parameters);
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
    getter.getter = true;
    getter.isStatic = isStatic;
    getter.isSynthetic = false;
    getter.returnType = type;
    getter.type = _typeOfExecutableElement(getter);
    getter.variable = field;

    field.getter = getter;
    return getter;
  }

  InterfaceType _interfaceType(
    ClassElement element, {
    List<DartType> typeArguments = const [],
  }) {
    return InterfaceTypeImpl.explicit(
      element,
      typeArguments,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  MethodElement _method(
    String name,
    DartType returnType, {
    List<TypeParameterElement> typeFormals = const [],
    List<ParameterElement> parameters = const [],
  }) {
    var element = MethodElementImpl(name, 0)
      ..parameters = parameters
      ..returnType = returnType
      ..typeParameters = typeFormals;
    element.type = _typeOfExecutableElement(element);
    return element;
  }

  ParameterElement _namedParameter(String name, DartType type,
      {Expression initializer, String initializerCode}) {
    var parameter = DefaultParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.NAMED;
    parameter.type = type;
    parameter.constantInitializer = initializer;
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

  /// TODO(scheglov) We should do the opposite - build type in the element.
  /// But build a similar synthetic / structured type.
  FunctionType _typeOfExecutableElement(ExecutableElement element) {
    return FunctionTypeImpl.synthetic(
      element.returnType,
      element.typeParameters,
      element.parameters,
    );
  }

  TypeParameterElementImpl _typeParameter(String name) {
    return ElementFactory.typeParameterElement(name);
  }

  TypeParameterType _typeParameterType(TypeParameterElement element) {
    return TypeParameterTypeImpl(
      element,
      nullabilitySuffix: nullabilitySuffix,
    );
  }
}
