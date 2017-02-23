// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.summary.summary_sdk;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/file_system.dart' show ResourceProvider;
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart'
    show DartUriResolver, Source, SourceFactory;
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';

/**
 * An implementation of [DartSdk] which provides analysis results for `dart:`
 * libraries from the given summary file.  This implementation is limited and
 * suitable only for command-line tools, but not for IDEs - it does not
 * implement [sdkLibraries], [sdkVersion], [uris] and [fromFileUri].
 */
class SummaryBasedDartSdk implements DartSdk {
  final bool strongMode;
  SummaryDataStore _dataStore;
  InSummaryUriResolver _uriResolver;
  PackageBundle _bundle;
  ResourceProvider resourceProvider;

  /**
   * The [AnalysisContext] which is used for all of the sources in this sdk.
   */
  InternalAnalysisContext _analysisContext;

  SummaryBasedDartSdk(String summaryPath, this.strongMode,
      {this.resourceProvider}) {
    _dataStore = new SummaryDataStore(<String>[summaryPath],
        resourceProvider: resourceProvider);
    _uriResolver = new InSummaryUriResolver(resourceProvider, _dataStore);
    _bundle = _dataStore.bundles.single;
  }

  SummaryBasedDartSdk.fromBundle(this.strongMode, PackageBundle bundle,
      {this.resourceProvider}) {
    _dataStore = new SummaryDataStore([], resourceProvider: resourceProvider);
    _dataStore.addBundle('dart_sdk.sum', bundle);
    _uriResolver = new InSummaryUriResolver(resourceProvider, _dataStore);
    _bundle = bundle;
  }

  /**
   * Return the [PackageBundle] for this SDK, not `null`.
   */
  PackageBundle get bundle => _bundle;

  @override
  AnalysisContext get context {
    if (_analysisContext == null) {
      AnalysisOptionsImpl analysisOptions = new AnalysisOptionsImpl()
        ..strongMode = strongMode;
      _analysisContext = new SdkAnalysisContext(analysisOptions);
      SourceFactory factory = new SourceFactory(
          [new DartUriResolver(this)], null, resourceProvider);
      _analysisContext.sourceFactory = factory;
      SummaryDataStore dataStore =
          new SummaryDataStore([], resourceProvider: resourceProvider);
      dataStore.addBundle(null, _bundle);
      _analysisContext.resultProvider =
          new InputPackagesResultProvider(_analysisContext, dataStore);
    }
    return _analysisContext;
  }

  @override
  List<SdkLibrary> get sdkLibraries {
    throw new UnimplementedError();
  }

  @override
  String get sdkVersion {
    throw new UnimplementedError();
  }

  @override
  List<String> get uris {
    throw new UnimplementedError();
  }

  @override
  Source fromFileUri(Uri uri) {
    return null;
  }

  @override
  PackageBundle getLinkedBundle() => _bundle;

  @override
  SdkLibrary getSdkLibrary(String uri) {
    // This is not quite correct, but currently it's used only in
    // to report errors on importing or exporting of internal libraries.
    return null;
  }

  @override
  Source mapDartUri(String uriStr) {
    Uri uri = Uri.parse(uriStr);
    return _uriResolver.resolveAbsolute(uri);
  }
}

/**
 * Implementation of [TypeProvider] which can be initialized separately with
 * `dart:core` and `dart:async` libraries.
 */
class SummaryTypeProvider extends TypeProviderBase {
  LibraryElement _coreLibrary;
  LibraryElement _asyncLibrary;

  InterfaceType _boolType;
  InterfaceType _deprecatedType;
  InterfaceType _doubleType;
  InterfaceType _functionType;
  InterfaceType _futureDynamicType;
  InterfaceType _futureNullType;
  InterfaceType _futureOrNullType;
  InterfaceType _futureOrType;
  InterfaceType _futureType;
  InterfaceType _intType;
  InterfaceType _iterableDynamicType;
  InterfaceType _iterableType;
  InterfaceType _listType;
  InterfaceType _mapType;
  DartObjectImpl _nullObject;
  InterfaceType _nullType;
  InterfaceType _numType;
  InterfaceType _objectType;
  InterfaceType _stackTraceType;
  InterfaceType _streamDynamicType;
  InterfaceType _streamType;
  InterfaceType _stringType;
  InterfaceType _symbolType;
  InterfaceType _typeType;

  @override
  InterfaceType get boolType {
    assert(_coreLibrary != null);
    _boolType ??= _getType(_coreLibrary, "bool");
    return _boolType;
  }

  @override
  DartType get bottomType => BottomTypeImpl.instance;

  @override
  InterfaceType get deprecatedType {
    assert(_coreLibrary != null);
    _deprecatedType ??= _getType(_coreLibrary, "Deprecated");
    return _deprecatedType;
  }

  @override
  InterfaceType get doubleType {
    assert(_coreLibrary != null);
    _doubleType ??= _getType(_coreLibrary, "double");
    return _doubleType;
  }

  @override
  DartType get dynamicType => DynamicTypeImpl.instance;

  @override
  InterfaceType get functionType {
    assert(_coreLibrary != null);
    _functionType ??= _getType(_coreLibrary, "Function");
    return _functionType;
  }

  @override
  InterfaceType get futureDynamicType {
    assert(_asyncLibrary != null);
    _futureDynamicType ??= futureType.instantiate(<DartType>[dynamicType]);
    return _futureDynamicType;
  }

  @override
  InterfaceType get futureNullType {
    assert(_asyncLibrary != null);
    _futureNullType ??= futureType.instantiate(<DartType>[nullType]);
    return _futureNullType;
  }

  @override
  InterfaceType get futureOrNullType {
    assert(_asyncLibrary != null);
    _futureOrNullType ??= futureOrType.instantiate(<DartType>[nullType]);
    return _futureOrNullType;
  }

  @override
  InterfaceType get futureOrType {
    assert(_asyncLibrary != null);
    try {
      _futureOrType ??= _getType(_asyncLibrary, "FutureOr");
    } on StateError {
      // FutureOr<T> is still fairly new, so if we're analyzing an SDK that
      // doesn't have it yet, create an element for it.
      _futureOrType =
          TypeProviderImpl.createPlaceholderFutureOr(futureType, objectType);
    }
    return _futureOrType;
  }

  @override
  InterfaceType get futureType {
    assert(_asyncLibrary != null);
    _futureType ??= _getType(_asyncLibrary, "Future");
    return _futureType;
  }

  @override
  InterfaceType get intType {
    assert(_coreLibrary != null);
    _intType ??= _getType(_coreLibrary, "int");
    return _intType;
  }

  @override
  InterfaceType get iterableDynamicType {
    assert(_coreLibrary != null);
    _iterableDynamicType ??= iterableType.instantiate(<DartType>[dynamicType]);
    return _iterableDynamicType;
  }

  @override
  InterfaceType get iterableType {
    assert(_coreLibrary != null);
    _iterableType ??= _getType(_coreLibrary, "Iterable");
    return _iterableType;
  }

  @override
  InterfaceType get listType {
    assert(_coreLibrary != null);
    _listType ??= _getType(_coreLibrary, "List");
    return _listType;
  }

  @override
  InterfaceType get mapType {
    assert(_coreLibrary != null);
    _mapType ??= _getType(_coreLibrary, "Map");
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
    assert(_coreLibrary != null);
    _nullType ??= _getType(_coreLibrary, "Null");
    return _nullType;
  }

  @override
  InterfaceType get numType {
    assert(_coreLibrary != null);
    _numType ??= _getType(_coreLibrary, "num");
    return _numType;
  }

  @override
  InterfaceType get objectType {
    assert(_coreLibrary != null);
    _objectType ??= _getType(_coreLibrary, "Object");
    return _objectType;
  }

  @override
  InterfaceType get stackTraceType {
    assert(_coreLibrary != null);
    _stackTraceType ??= _getType(_coreLibrary, "StackTrace");
    return _stackTraceType;
  }

  @override
  InterfaceType get streamDynamicType {
    assert(_asyncLibrary != null);
    _streamDynamicType ??= streamType.instantiate(<DartType>[dynamicType]);
    return _streamDynamicType;
  }

  @override
  InterfaceType get streamType {
    assert(_asyncLibrary != null);
    _streamType ??= _getType(_asyncLibrary, "Stream");
    return _streamType;
  }

  @override
  InterfaceType get stringType {
    assert(_coreLibrary != null);
    _stringType ??= _getType(_coreLibrary, "String");
    return _stringType;
  }

  @override
  InterfaceType get symbolType {
    assert(_coreLibrary != null);
    _symbolType ??= _getType(_coreLibrary, "Symbol");
    return _symbolType;
  }

  @override
  InterfaceType get typeType {
    assert(_coreLibrary != null);
    _typeType ??= _getType(_coreLibrary, "Type");
    return _typeType;
  }

  @override
  DartType get undefinedType => UndefinedTypeImpl.instance;

  /**
   * Initialize the `dart:async` types provided by this type provider.
   */
  void initializeAsync(LibraryElement library) {
    assert(_coreLibrary != null);
    assert(_asyncLibrary == null);
    _asyncLibrary = library;
  }

  /**
   * Initialize the `dart:core` types provided by this type provider.
   */
  void initializeCore(LibraryElement library) {
    assert(_coreLibrary == null);
    assert(_asyncLibrary == null);
    _coreLibrary = library;
  }

  /**
   * Return the type with the given [name] from the given [library], or
   * throw a [StateError] if there is no class with the given name.
   */
  InterfaceType _getType(LibraryElement library, String name) {
    Element element = library.getType(name);
    if (element == null) {
      throw new StateError("No definition of type $name");
    }
    return (element as ClassElement).type;
  }
}
