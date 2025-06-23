// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';

class MockSdkElements {
  final LibraryElementImpl coreLibrary;
  final LibraryElementImpl asyncLibrary;

  factory MockSdkElements(
    engine.AnalysisContext analysisContext,
    AnalysisSessionImpl analysisSession,
  ) {
    var builder = _MockSdkElementsBuilder(analysisContext, analysisSession);
    var coreLibrary = builder._buildCore();
    var asyncLibrary = builder._buildAsync();
    builder._populateCore();
    builder._populateAsync();
    return MockSdkElements._(coreLibrary, asyncLibrary);
  }

  MockSdkElements._(this.coreLibrary, this.asyncLibrary);
}

class _MockSdkElementsBuilder {
  final engine.AnalysisContext analysisContext;
  final AnalysisSessionImpl analysisSession;

  ClassFragmentImpl? _boolElement;
  ClassFragmentImpl? _comparableElement;
  ClassFragmentImpl? _completerElement;
  ClassFragmentImpl? _deprecatedElement;
  ClassFragmentImpl? _doubleElement;
  ClassFragmentImpl? _functionElement;
  ClassFragmentImpl? _futureElement;
  ClassFragmentImpl? _futureOrElement;
  ClassFragmentImpl? _intElement;
  ClassFragmentImpl? _iterableElement;
  ClassFragmentImpl? _iteratorElement;
  ClassFragmentImpl? _listElement;
  ClassFragmentImpl? _mapElement;
  ClassFragmentImpl? _nullElement;
  ClassFragmentImpl? _numElement;
  ClassFragmentImpl? _objectElement;
  ClassFragmentImpl? _overrideElement;
  ClassFragmentImpl? _recordElement;
  ClassFragmentImpl? _setElement;
  ClassFragmentImpl? _stackTraceElement;
  ClassFragmentImpl? _streamElement;
  ClassFragmentImpl? _streamSubscriptionElement;
  ClassFragmentImpl? _stringElement;
  ClassFragmentImpl? _symbolElement;
  ClassFragmentImpl? _typeElement;

  InterfaceTypeImpl? _boolType;
  InterfaceTypeImpl? _doubleType;
  InterfaceTypeImpl? _intType;
  InterfaceTypeImpl? _numType;
  InterfaceTypeImpl? _objectType;
  InterfaceTypeImpl? _stringType;
  InterfaceTypeImpl? _typeType;

  late LibraryElementImpl _asyncLibrary;
  late LibraryFragmentImpl _asyncUnit;

  late LibraryElementImpl _coreLibrary;
  late LibraryFragmentImpl _coreUnit;

  _MockSdkElementsBuilder(this.analysisContext, this.analysisSession);

  ClassFragmentImpl get boolElement {
    var boolElement = _boolElement;
    if (boolElement != null) return boolElement;

    _boolElement = boolElement = _class(name: 'bool', unit: _coreUnit);
    boolElement.supertype = objectType;

    boolElement.constructors = [
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

    _buildClassElement(boolElement);
    return boolElement;
  }

  InterfaceTypeImpl get boolType {
    return _boolType ??= _interfaceType(boolElement);
  }

  ClassFragmentImpl get comparableElement {
    var comparableElement = _comparableElement;
    if (comparableElement != null) return comparableElement;

    var tElement = _typeParameter('T');
    _comparableElement =
        comparableElement = _class(
          name: 'Comparable',
          isAbstract: true,
          typeParameters: [tElement],
          unit: _coreUnit,
        );
    comparableElement.supertype = objectType;

    _buildClassElement(comparableElement);
    return comparableElement;
  }

  ClassFragmentImpl get completerElement {
    var completerElement = _completerElement;
    if (completerElement != null) return completerElement;

    var tElement = _typeParameter('T');
    _completerElement =
        completerElement = _class(
          name: 'Completer',
          isAbstract: true,
          typeParameters: [tElement],
          unit: _asyncUnit,
        );
    completerElement.supertype = objectType;

    _buildClassElement(completerElement);
    return completerElement;
  }

  ClassFragmentImpl get deprecatedElement {
    var deprecatedElement = _deprecatedElement;
    if (deprecatedElement != null) return deprecatedElement;

    _deprecatedElement =
        deprecatedElement = _class(name: 'Deprecated', unit: _coreUnit);
    deprecatedElement.supertype = objectType;

    deprecatedElement.fields = [_field('message', stringType, isFinal: true)];

    deprecatedElement.getters =
        deprecatedElement.fields.map((f) => f.getter!).toList();

    deprecatedElement.constructors = [
      _constructor(
        isConst: true,
        parameters: [_requiredParameter('message', stringType)],
      ),
    ];

    _buildClassElement(deprecatedElement);
    return deprecatedElement;
  }

  ClassFragmentImpl get doubleElement {
    var doubleElement = _doubleElement;
    if (doubleElement != null) return doubleElement;

    _doubleElement =
        doubleElement = _class(
          name: 'double',
          isAbstract: true,
          unit: _coreUnit,
        );
    doubleElement.supertype = numType;

    FieldFragmentImpl staticConstDoubleField(String name) {
      return _field(name, doubleType, isStatic: true, isConst: true);
    }

    doubleElement.fields = <FieldFragmentImpl>[
      staticConstDoubleField('nan'),
      staticConstDoubleField('infinity'),
      staticConstDoubleField('negativeInfinity'),
      staticConstDoubleField('minPositive'),
      staticConstDoubleField('maxFinite'),
    ];

    doubleElement.getters =
        doubleElement.fields.map((field) => field.getter!).toList();

    doubleElement.methods = [
      _method(
        '+',
        doubleType,
        parameters: [_requiredParameter('other', numType)],
      ),
      _method(
        '*',
        doubleType,
        parameters: [_requiredParameter('other', numType)],
      ),
      _method(
        '-',
        doubleType,
        parameters: [_requiredParameter('other', numType)],
      ),
      _method(
        '%',
        doubleType,
        parameters: [_requiredParameter('other', numType)],
      ),
      _method(
        '/',
        doubleType,
        parameters: [_requiredParameter('other', numType)],
      ),
      _method(
        '~/',
        intType,
        parameters: [_requiredParameter('other', numType)],
      ),
      _method(
        '-',
        doubleType,
        parameters: [_requiredParameter('other', numType)],
      ),
      _method('abs', doubleType),
      _method('ceil', doubleType),
      _method('floor', doubleType),
      _method(
        'remainder',
        doubleType,
        parameters: [_requiredParameter('other', numType)],
      ),
      _method('round', doubleType),
      _method('toString', stringType),
      _method('truncate', doubleType),
    ];

    _buildClassElement(doubleElement);
    return doubleElement;
  }

  InterfaceTypeImpl get doubleType {
    return _doubleType ??= _interfaceType(doubleElement);
  }

  DynamicTypeImpl get dynamicType => DynamicTypeImpl.instance;

  ClassFragmentImpl get functionElement {
    var functionElement = _functionElement;
    if (functionElement != null) return functionElement;

    _functionElement =
        functionElement = _class(
          name: 'Function',
          isAbstract: true,
          unit: _coreUnit,
        );
    functionElement.supertype = objectType;

    _buildClassElement(functionElement);
    return functionElement;
  }

  InterfaceTypeImpl get functionType {
    return _interfaceType(functionElement);
  }

  ClassFragmentImpl get futureElement {
    var futureElement = _futureElement;
    if (futureElement != null) return futureElement;

    var tElement = _typeParameter('T');
    var tType = _typeParameterType(tElement);

    _futureElement =
        futureElement = _class(
          name: 'Future',
          isAbstract: true,
          typeParameters: [tElement],
          unit: _asyncUnit,
        );
    futureElement.supertype = objectType;

    //   factory Future.value([FutureOr<T> value])
    futureElement.constructors = [
      _constructor(
        isFactory: true,
        parameters: [_positionalParameter('value', futureOrType(tType))],
      ),
    ];

    //   Future<R> then<R>(FutureOr<R> onValue(T value), {Function onError})
    var rElement = _typeParameter('R');
    var rType = _typeParameterType(rElement);
    futureElement.methods = [
      _method(
        'then',
        futureType(rType),
        parameters: [
          _requiredParameter(
            'onValue',
            _functionType(
              returnType: futureOrType(rType),
              parameters: [_requiredParameter('value', tType)],
            ),
          ),
          _positionalParameter('onError', functionType),
        ],
      ),
    ];

    _buildClassElement(futureElement);
    return futureElement;
  }

  ClassFragmentImpl get futureOrElement {
    var futureOrElement = _futureOrElement;
    if (futureOrElement != null) return futureOrElement;

    var tElement = _typeParameter('T');
    _futureOrElement =
        futureOrElement = _class(
          name: 'FutureOr',
          typeParameters: [tElement],
          unit: _asyncUnit,
        );
    futureOrElement.supertype = objectType;

    _buildClassElement(futureOrElement);
    return futureOrElement;
  }

  ClassFragmentImpl get intElement {
    var intElement = _intElement;
    if (intElement != null) return intElement;

    _intElement =
        intElement = _class(name: 'int', isAbstract: true, unit: _coreUnit);
    intElement.supertype = numType;

    intElement.constructors = [
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

    intElement.methods = [
      _method('&', intType, parameters: [_requiredParameter('other', intType)]),
      _method('|', intType, parameters: [_requiredParameter('other', intType)]),
      _method('^', intType, parameters: [_requiredParameter('other', intType)]),
      _method('~', intType),
      _method(
        '<<',
        intType,
        parameters: [_requiredParameter('shiftAmount', intType)],
      ),
      _method(
        '>>',
        intType,
        parameters: [_requiredParameter('shiftAmount', intType)],
      ),
      _method('-', intType),
      _method('abs', intType),
      _method('round', intType),
      _method('floor', intType),
      _method('ceil', intType),
      _method('truncate', intType),
      _method('toString', stringType),
    ];

    _buildClassElement(intElement);
    return intElement;
  }

  InterfaceTypeImpl get intType {
    return _intType ??= _interfaceType(intElement);
  }

  ClassFragmentImpl get iterableElement {
    var iterableElement = _iterableElement;
    if (iterableElement != null) return iterableElement;

    var eElement = _typeParameter('E');
    var eType = _typeParameterType(eElement);

    _iterableElement =
        iterableElement = _class(
          name: 'Iterable',
          isAbstract: true,
          typeParameters: [eElement],
          unit: _coreUnit,
        );
    iterableElement.supertype = objectType;

    iterableElement.constructors = [_constructor(isConst: true)];

    _setGetters(iterableElement, [
      _getter('iterator', iteratorType(eType)),
      _getter('last', eType),
    ]);

    _buildClassElement(iterableElement);
    return iterableElement;
  }

  ClassFragmentImpl get iteratorElement {
    var iteratorElement = _iteratorElement;
    if (iteratorElement != null) return iteratorElement;

    var eElement = _typeParameter('E');
    var eType = _typeParameterType(eElement);

    _iteratorElement =
        iteratorElement = _class(
          name: 'Iterator',
          isAbstract: true,
          typeParameters: [eElement],
          unit: _coreUnit,
        );
    iteratorElement.supertype = objectType;

    _setGetters(iterableElement, [_getter('current', eType)]);

    _buildClassElement(iteratorElement);
    return iteratorElement;
  }

  ClassFragmentImpl get listElement {
    var listElement = _listElement;
    if (listElement != null) return listElement;

    var eElement = _typeParameter('E');
    var eType = _typeParameterType(eElement);

    _listElement =
        listElement = _class(
          name: 'List',
          isAbstract: true,
          typeParameters: [eElement],
          unit: _coreUnit,
        );
    listElement.supertype = objectType;
    listElement.interfaces = [iterableType(eType)];

    listElement.constructors = [
      _constructor(
        isFactory: true,
        parameters: [_positionalParameter('length', intType)],
      ),
    ];

    _setGetters(listElement, [_getter('length', intType)]);

    listElement.methods = [
      _method('[]', eType, parameters: [_requiredParameter('index', intType)]),
      _method(
        '[]=',
        voidType,
        parameters: [
          _requiredParameter('index', intType),
          _requiredParameter('value', eType),
        ],
      ),
      _method(
        'add',
        voidType,
        parameters: [_requiredParameter('value', eType)],
      ),
    ];

    _buildClassElement(listElement);
    return listElement;
  }

  ClassFragmentImpl get mapElement {
    var mapElement = _mapElement;
    if (mapElement != null) return mapElement;

    var kElement = _typeParameter('K');
    var vElement = _typeParameter('V');
    var kType = _typeParameterType(kElement);
    var vType = _typeParameterType(vElement);

    _mapElement =
        mapElement = _class(
          name: 'Map',
          isAbstract: true,
          typeParameters: [kElement, vElement],
          unit: _coreUnit,
        );
    mapElement.supertype = objectType;

    _setGetters(mapElement, [_getter('length', intType)]);

    mapElement.methods = [
      _method('[]', vType, parameters: [_requiredParameter('key', objectType)]),
      _method(
        '[]=',
        voidType,
        parameters: [
          _requiredParameter('key', kType),
          _requiredParameter('value', vType),
        ],
      ),
    ];

    _buildClassElement(mapElement);
    return mapElement;
  }

  ClassFragmentImpl get nullElement {
    var nullElement = _nullElement;
    if (nullElement != null) return nullElement;

    _nullElement = nullElement = _class(name: 'Null', unit: _coreUnit);
    nullElement.supertype = objectType;

    nullElement.constructors = [
      _constructor(name: '_uninstantiatable', isFactory: true),
    ];

    _buildClassElement(nullElement);
    return nullElement;
  }

  ClassFragmentImpl get numElement {
    var numElement = _numElement;
    if (numElement != null) return numElement;

    _numElement =
        numElement = _class(name: 'num', isAbstract: true, unit: _coreUnit);
    numElement.supertype = objectType;
    numElement.interfaces = [
      _interfaceType(comparableElement, typeArguments: [numType]),
    ];

    numElement.methods = [
      _method('+', numType, parameters: [_requiredParameter('other', numType)]),
      _method('-', numType, parameters: [_requiredParameter('other', numType)]),
      _method('*', numType, parameters: [_requiredParameter('other', numType)]),
      _method('%', numType, parameters: [_requiredParameter('other', numType)]),
      _method(
        '/',
        doubleType,
        parameters: [_requiredParameter('other', numType)],
      ),
      _method(
        '~/',
        intType,
        parameters: [_requiredParameter('other', numType)],
      ),
      _method('-', numType, parameters: [_requiredParameter('other', numType)]),
      _method(
        'remainder',
        numType,
        parameters: [_requiredParameter('other', numType)],
      ),
      _method(
        '<',
        boolType,
        parameters: [_requiredParameter('other', numType)],
      ),
      _method(
        '<=',
        boolType,
        parameters: [_requiredParameter('other', numType)],
      ),
      _method(
        '>',
        boolType,
        parameters: [_requiredParameter('other', numType)],
      ),
      _method(
        '>=',
        boolType,
        parameters: [_requiredParameter('other', numType)],
      ),
      _method(
        '==',
        boolType,
        parameters: [_requiredParameter('other', objectType)],
      ),
      _method('abs', numType),
      _method('floor', numType),
      _method('ceil', numType),
      _method('round', numType),
      _method('truncate', numType),
      _method('toInt', intType),
      _method('toDouble', doubleType),
      _method(
        'toStringAsFixed',
        stringType,
        parameters: [_requiredParameter('fractionDigits', intType)],
      ),
      _method(
        'toStringAsExponential',
        stringType,
        parameters: [_requiredParameter('fractionDigits', intType)],
      ),
      _method(
        'toStringAsPrecision',
        stringType,
        parameters: [_requiredParameter('precision', intType)],
      ),
    ];

    _setGetters(numElement, [
      _getter('isInfinite', boolType),
      _getter('isNaN', boolType),
      _getter('isNegative', boolType),
    ]);

    _buildClassElement(numElement);
    return numElement;
  }

  InterfaceTypeImpl get numType {
    return _numType ??= _interfaceType(numElement);
  }

  ClassFragmentImpl get objectElement {
    var objectElement = _objectElement;
    if (objectElement != null) return objectElement;

    _objectElement = objectElement = _class(name: 'Object', unit: _coreUnit);
    _coreUnit.encloseElement(objectElement);
    objectElement.interfaces = const <InterfaceType>[];
    objectElement.mixins = const <InterfaceType>[];
    objectElement.typeParameters = const <TypeParameterFragmentImpl>[];
    objectElement.constructors = [_constructor(isConst: true)];

    objectElement.methods = [
      _method('toString', stringType),
      _method(
        '==',
        boolType,
        parameters: [_requiredParameter('other', objectType)],
      ),
      _method(
        'noSuchMethod',
        dynamicType,
        parameters: [_requiredParameter('other', dynamicType)],
      ),
    ];

    _setGetters(objectElement, [
      _getter('hashCode', intType),
      _getter('runtimeType', typeType),
    ]);

    _buildClassElement(objectElement);
    return objectElement;
  }

  InterfaceTypeImpl get objectType {
    return _objectType ??= _interfaceType(objectElement);
  }

  ClassFragmentImpl get overrideElement {
    var overrideElement = _overrideElement;
    if (overrideElement != null) return overrideElement;

    _overrideElement =
        overrideElement = _class(name: '_Override', unit: _coreUnit);
    overrideElement.supertype = objectType;

    overrideElement.constructors = [_constructor(isConst: true)];

    _buildClassElement(overrideElement);
    return overrideElement;
  }

  ClassFragmentImpl get recordElement {
    var recordElement = _recordElement;
    if (recordElement != null) return recordElement;

    _recordElement =
        recordElement = _class(
          name: 'Record',
          isAbstract: true,
          unit: _coreUnit,
        );
    recordElement.supertype = objectType;

    _buildClassElement(recordElement);
    return recordElement;
  }

  InterfaceTypeImpl get recordType {
    return _interfaceType(recordElement);
  }

  ClassFragmentImpl get setElement {
    var setElement = _setElement;
    if (setElement != null) return setElement;

    var eElement = _typeParameter('E');
    var eType = _typeParameterType(eElement);

    _setElement =
        setElement = _class(
          name: 'Set',
          isAbstract: true,
          typeParameters: [eElement],
          unit: _coreUnit,
        );
    setElement.supertype = objectType;
    setElement.interfaces = [iterableType(eType)];

    _buildClassElement(setElement);
    return setElement;
  }

  ClassFragmentImpl get stackTraceElement {
    var stackTraceElement = _stackTraceElement;
    if (stackTraceElement != null) return stackTraceElement;

    _stackTraceElement =
        stackTraceElement = _class(
          name: 'StackTrace',
          isAbstract: true,
          unit: _coreUnit,
        );
    stackTraceElement.supertype = objectType;

    _buildClassElement(stackTraceElement);
    return stackTraceElement;
  }

  ClassFragmentImpl get streamElement {
    var streamElement = _streamElement;
    if (streamElement != null) return streamElement;

    var tElement = _typeParameter('T');
    var tType = _typeParameterType(tElement);

    _streamElement =
        streamElement = _class(
          name: 'Stream',
          isAbstract: true,
          typeParameters: [tElement],
          unit: _asyncUnit,
        );
    streamElement.isAbstract = true;
    streamElement.supertype = objectType;

    //    StreamSubscription<T> listen(void onData(T event),
    //        {Function onError, void onDone(), bool cancelOnError});
    streamElement.methods = [
      _method(
        'listen',
        streamSubscriptionType(tType),
        parameters: [
          _requiredParameter(
            'onData',
            _functionType(
              returnType: voidType,
              parameters: [_requiredParameter('event', tType)],
            ),
          ),
          _namedParameter('onError', functionType),
          _namedParameter('onDone', _functionType(returnType: voidType)),
          _namedParameter('cancelOnError', boolType),
        ],
      ),
    ];

    _buildClassElement(streamElement);
    return streamElement;
  }

  ClassFragmentImpl get streamSubscriptionElement {
    var streamSubscriptionElement = _streamSubscriptionElement;
    if (streamSubscriptionElement != null) return streamSubscriptionElement;

    var tElement = _typeParameter('T');
    _streamSubscriptionElement =
        streamSubscriptionElement = _class(
          name: 'StreamSubscription',
          isAbstract: true,
          typeParameters: [tElement],
          unit: _asyncUnit,
        );
    streamSubscriptionElement.supertype = objectType;

    _buildClassElement(streamSubscriptionElement);
    return streamSubscriptionElement;
  }

  ClassFragmentImpl get stringElement {
    var stringElement = _stringElement;
    if (stringElement != null) return stringElement;

    _stringElement =
        stringElement = _class(
          name: 'String',
          isAbstract: true,
          unit: _coreUnit,
        );
    stringElement.supertype = objectType;

    stringElement.constructors = [
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

    _setGetters(stringElement, [
      _getter('isEmpty', boolType),
      _getter('length', intType),
      _getter('codeUnits', listType(intType)),
    ]);

    stringElement.methods = [
      _method(
        '+',
        stringType,
        parameters: [_requiredParameter('other', stringType)],
      ),
      _method('toLowerCase', stringType),
      _method('toUpperCase', stringType),
    ];

    _buildClassElement(stringElement);
    return stringElement;
  }

  InterfaceTypeImpl get stringType {
    return _stringType ??= _interfaceType(stringElement);
  }

  ClassFragmentImpl get symbolElement {
    var symbolElement = _symbolElement;
    if (symbolElement != null) return symbolElement;

    _symbolElement =
        symbolElement = _class(
          name: 'Symbol',
          isAbstract: true,
          unit: _coreUnit,
        );
    symbolElement.supertype = objectType;

    symbolElement.constructors = [
      _constructor(
        isConst: true,
        isFactory: true,
        parameters: [_requiredParameter('name', stringType)],
      ),
    ];

    _buildClassElement(symbolElement);
    return symbolElement;
  }

  ClassFragmentImpl get typeElement {
    var typeElement = _typeElement;
    if (typeElement != null) return typeElement;

    _typeElement =
        typeElement = _class(name: 'Type', isAbstract: true, unit: _coreUnit);
    typeElement.supertype = objectType;

    _buildClassElement(typeElement);
    return typeElement;
  }

  InterfaceTypeImpl get typeType {
    return _typeType ??= _interfaceType(typeElement);
  }

  VoidTypeImpl get voidType => VoidTypeImpl.instance;

  InterfaceTypeImpl futureOrType(TypeImpl elementType) {
    return _interfaceType(futureOrElement, typeArguments: [elementType]);
  }

  InterfaceTypeImpl futureType(TypeImpl elementType) {
    return _interfaceType(futureElement, typeArguments: [elementType]);
  }

  InterfaceTypeImpl iterableType(TypeImpl elementType) {
    return _interfaceType(iterableElement, typeArguments: [elementType]);
  }

  InterfaceTypeImpl iteratorType(TypeImpl elementType) {
    return _interfaceType(iteratorElement, typeArguments: [elementType]);
  }

  InterfaceTypeImpl listType(TypeImpl elementType) {
    return _interfaceType(listElement, typeArguments: [elementType]);
  }

  InterfaceTypeImpl streamSubscriptionType(TypeImpl valueType) {
    return _interfaceType(
      streamSubscriptionElement,
      typeArguments: [valueType],
    );
  }

  LibraryElementImpl _buildAsync() {
    var asyncSource = analysisContext.sourceFactory.forUri('dart:async')!;
    _asyncLibrary = LibraryElementImpl(
      analysisContext,
      analysisSession,
      'dart.async',
      0,
      0,
      FeatureSet.latestLanguageVersion(),
    );

    _asyncUnit = LibraryFragmentImpl(
      library: _asyncLibrary,
      source: asyncSource,
      lineInfo: LineInfo([0]),
    );

    _asyncLibrary.definingCompilationUnit = _asyncUnit;
    return _asyncLibrary;
  }

  void _buildClassElement(ClassFragmentImpl classFragment) {
    var classElement = classFragment.element;
    classElement.methods = classFragment.methods.map((f) => f.element).toList();
    classElement.constructors =
        classFragment.constructors.map((f) => f.element).toList();
    // TODO(scheglov): other members
    // classElement.fields = classFragment.fields.map((f) => f.element).toList();
    // classElement.getters = classFragment.getters.map((f) => f.element).toList();
    // classElement.setters = classFragment.setters.map((f) => f.element).toList();
  }

  LibraryElementImpl _buildCore() {
    var coreSource = analysisContext.sourceFactory.forUri('dart:core')!;
    _coreLibrary = LibraryElementImpl(
      analysisContext,
      analysisSession,
      'dart.core',
      0,
      0,
      FeatureSet.latestLanguageVersion(),
    );

    _coreUnit = LibraryFragmentImpl(
      library: _coreLibrary,
      source: coreSource,
      lineInfo: LineInfo([0]),
    );

    _coreLibrary.definingCompilationUnit = _coreUnit;
    return _coreLibrary;
  }

  ClassFragmentImpl _class({
    required String name,
    bool isAbstract = false,
    List<TypeParameterElementImpl> typeParameters = const [],
    required LibraryFragmentImpl unit,
  }) {
    var fragment = ClassFragmentImpl(name2: name, nameOffset: 0);
    ClassElementImpl(Reference.root(), fragment);
    fragment.typeParameters =
        typeParameters.map((tp) => tp.firstFragment).toList();
    fragment.constructors = <ConstructorFragmentImpl>[_constructor()];
    unit.encloseElement(fragment);
    return fragment;
  }

  ConstructorFragmentImpl _constructor({
    String name = 'new',
    bool isConst = false,
    bool isFactory = false,
    List<FormalParameterElement> parameters = const [],
  }) {
    var fragment = ConstructorFragmentImpl(name2: name, nameOffset: 0);
    fragment.isFactory = isFactory;
    fragment.isConst = isConst;
    fragment.parameters =
        parameters
            .map((p) => p.firstFragment as FormalParameterFragmentImpl)
            .toList();

    ConstructorElementImpl(
      name3: fragment.name2,
      reference: Reference.root(),
      firstFragment: fragment,
    );

    return fragment;
  }

  FieldFragmentImpl _field(
    String name,
    TypeImpl type, {
    bool isConst = false,
    bool isFinal = false,
    bool isStatic = false,
  }) {
    var fragment = FieldFragmentImpl(name2: name, nameOffset: 0);
    var element = FieldElementImpl(
      reference: Reference.root(),
      firstFragment: fragment,
    );
    fragment.isConst = isConst;
    fragment.isFinal = isFinal;
    fragment.isStatic = isStatic;

    var getterFragment = GetterFragmentImpl(name2: name, nameOffset: -1)
      ..isSynthetic = true;
    var getterElement = GetterElementImpl(Reference.root(), getterFragment);
    element.getter2 = getterElement;

    if (!isConst && !isFinal) {
      var valueFragment = FormalParameterFragmentImpl(
        nameOffset: -1,
        name2: null,
        nameOffset2: null,
        parameterKind: ParameterKind.REQUIRED,
      );
      var setterFragment =
          SetterFragmentImpl(name2: name, nameOffset: -1)
            ..isSynthetic = true
            ..parameters = [valueFragment];
      var setterElement = SetterElementImpl(Reference.root(), setterFragment);
      element.setter2 = setterElement;
    }

    fragment.type = type;
    return fragment;
  }

  TopLevelFunctionFragmentImpl _function(
    String name,
    DartType returnType, {
    List<TypeParameterFragmentImpl> typeFormals = const [],
    List<FormalParameterElement> parameters = const [],
  }) {
    var fragment =
        TopLevelFunctionFragmentImpl(name2: name, nameOffset: 0)
          ..parameters =
              parameters
                  .map((p) => p.firstFragment as FormalParameterFragmentImpl)
                  .toList()
          ..returnType = returnType
          ..typeParameters = typeFormals;
    TopLevelFunctionElementImpl(Reference.root(), fragment);
    return fragment;
  }

  FunctionTypeImpl _functionType({
    required TypeImpl returnType,
    List<TypeParameterElementImpl> typeFormals = const [],
    List<FormalParameterElement> parameters = const [],
  }) {
    return FunctionTypeImpl.v2(
      typeParameters: typeFormals,
      formalParameters: parameters.cast(),
      returnType: returnType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  GetterFragmentImpl _getter(
    String name,
    TypeImpl type, {
    bool isStatic = false,
  }) {
    var fieldFragment = FieldFragmentImpl(name2: name, nameOffset: -1);
    var fieldElement = FieldElementImpl(
      reference: Reference.root(),
      firstFragment: fieldFragment,
    );
    fieldFragment.isStatic = isStatic;
    fieldFragment.isSynthetic = true;
    fieldFragment.type = type;

    var getterFragment = GetterFragmentImpl(name2: name, nameOffset: 0);
    var getterElement = GetterElementImpl(Reference.root(), getterFragment);
    fieldElement.getter2 = getterElement;
    getterElement.variable3 = fieldElement;
    getterFragment.isStatic = isStatic;
    getterFragment.isSynthetic = false;
    getterFragment.returnType = type;

    return getterFragment;
  }

  InterfaceTypeImpl _interfaceType(
    InterfaceFragmentImpl element, {
    List<TypeImpl> typeArguments = const [],
  }) {
    return InterfaceTypeImpl(
      element: element.element,
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  MethodFragmentImpl _method(
    String name,
    DartType returnType, {
    List<TypeParameterFragmentImpl> typeFormals = const [],
    List<FormalParameterElement> parameters = const [],
  }) {
    var fragment =
        MethodFragmentImpl(name2: name, nameOffset: 0)
          ..parameters =
              parameters
                  .map((p) => p.firstFragment as FormalParameterFragmentImpl)
                  .toList()
          ..returnType = returnType
          ..typeParameters = typeFormals;
    MethodElementImpl(
      name3: name,
      reference: Reference.root(),
      firstFragment: fragment,
    );
    return fragment;
  }

  FormalParameterElement _namedParameter(
    String name,
    TypeImpl type, {
    String? initializerCode,
  }) {
    var fragment = DefaultParameterFragmentImpl(
      nameOffset: 0,
      name2: name,
      nameOffset2: 0,
      parameterKind: ParameterKind.NAMED,
    );
    fragment.type = type;
    fragment.defaultValueCode = initializerCode;
    return FormalParameterElementImpl(fragment);
  }

  void _populateAsync() {
    _asyncUnit.classes = <ClassFragmentImpl>[
      completerElement,
      futureElement,
      futureOrElement,
      streamElement,
      streamSubscriptionElement,
    ];

    _fillLibraryFromFragment(_asyncLibrary, _asyncUnit);
  }

  void _populateCore() {
    _coreUnit.classes = <ClassFragmentImpl>[
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
      recordElement,
      setElement,
      stackTraceElement,
      stringElement,
      symbolElement,
      typeElement,
    ];

    _coreUnit.functions = <TopLevelFunctionFragmentImpl>[
      _function(
        'identical',
        boolType,
        parameters: [
          _requiredParameter('a', objectType),
          _requiredParameter('b', objectType),
        ],
      ),
      _function(
        'print',
        voidType,
        parameters: [_requiredParameter('object', objectType)],
      ),
    ];

    var deprecatedVariable = _topLevelVariableConst(
      'deprecated',
      _interfaceType(deprecatedElement),
    );

    var overrideVariable = _topLevelVariableConst(
      'override',
      _interfaceType(overrideElement),
    );

    _coreUnit.getters = <GetterFragmentImpl>[
      deprecatedVariable.getter!,
      overrideVariable.getter!,
    ];

    _coreUnit.topLevelVariables = <TopLevelVariableFragmentImpl>[
      deprecatedVariable,
      overrideVariable,
    ];

    _fillLibraryFromFragment(_coreLibrary, _coreUnit);
  }

  FormalParameterElement _positionalParameter(String name, TypeImpl type) {
    var fragment = FormalParameterFragmentImpl(
      nameOffset: 0,
      name2: name,
      nameOffset2: 0,
      parameterKind: ParameterKind.POSITIONAL,
    );
    fragment.type = type;
    return FormalParameterElementImpl(fragment);
  }

  FormalParameterElement _requiredParameter(String name, TypeImpl type) {
    var fragment = FormalParameterFragmentImpl(
      nameOffset: 0,
      name2: name,
      nameOffset2: 0,
      parameterKind: ParameterKind.REQUIRED,
    );
    fragment.type = type;
    return FormalParameterElementImpl(fragment);
  }

  /// Set the [getters] and the corresponding fields for the [classElement].
  void _setGetters(
    ClassFragmentImpl classElement,
    List<GetterFragmentImpl> getters,
  ) {
    classElement.getters = getters;
    classElement.fields =
        getters
            .map((accessor) => accessor.variable2)
            .cast<FieldFragmentImpl>()
            .toList();
  }

  TopLevelVariableFragmentImpl _topLevelVariableConst(
    String name,
    TypeImpl type,
  ) {
    var fragment = TopLevelVariableFragmentImpl(name2: name, nameOffset: -1)
      ..isConst = true;
    var element = TopLevelVariableElementImpl(Reference.root(), fragment);
    var getterFragment = GetterFragmentImpl(name2: name, nameOffset: -1)
      ..isSynthetic = true;
    var getterElement = GetterElementImpl(Reference.root(), getterFragment);
    element.getter2 = getterElement;
    fragment.type = type;
    return fragment;
  }

  TypeParameterElementImpl _typeParameter(String name) {
    return TypeParameterElementImpl(
      firstFragment: TypeParameterFragmentImpl(name2: name, nameOffset: 0),
      name3: name.nullIfEmpty,
    );
  }

  TypeParameterTypeImpl _typeParameterType(TypeParameterElementImpl element) {
    return TypeParameterTypeImpl(
      element3: element,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  static void _fillLibraryFromFragment(
    LibraryElementImpl library,
    LibraryFragmentImpl fragment,
  ) {
    library.classes = fragment.classes.map((f) => f.element).toList();

    library.topLevelFunctions =
        fragment.functions.map((f) => f.element).toList();

    library.topLevelVariables =
        fragment.topLevelVariables.map((f) => f.element).toList();
  }
}
