// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.summary.summary_sdk;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/context/cache.dart' show CacheEntry;
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart'
    show DartUriResolver, Source, SourceFactory, SourceKind;
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/resynthesize.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/model.dart'
    show AnalysisTarget, ResultDescriptor, TargetedResult;

class SdkSummaryResultProvider implements SummaryResultProvider {
  final InternalAnalysisContext context;
  final PackageBundle bundle;
  final SummaryTypeProvider typeProvider = new SummaryTypeProvider();

  @override
  SummaryResynthesizer resynthesizer;

  SdkSummaryResultProvider(this.context, this.bundle) {
    resynthesizer = new SdkSummaryResynthesizer(
        context, typeProvider, context.sourceFactory, bundle);
    _buildCoreLibrary();
    _buildAsyncLibrary();
    resynthesizer.finalizeCoreAsyncLibraries();
    context.typeProvider = typeProvider;
  }

  @override
  bool compute(CacheEntry entry, ResultDescriptor result) {
    if (result == TYPE_PROVIDER) {
      entry.setValue(result, typeProvider, TargetedResult.EMPTY_LIST);
      return true;
    }
    AnalysisTarget target = entry.target;
    // Only SDK sources after this point.
    if (target.source == null || !target.source.isInSystemLibrary) {
      return false;
    }
    // Constant expressions are always resolved in summaries.
    if (result == CONSTANT_EXPRESSION_RESOLVED &&
        target is ConstantEvaluationTarget) {
      entry.setValue(result, true, TargetedResult.EMPTY_LIST);
      return true;
    }
    if (target is Source) {
      if (result == LIBRARY_ELEMENT1 ||
          result == LIBRARY_ELEMENT2 ||
          result == LIBRARY_ELEMENT3 ||
          result == LIBRARY_ELEMENT4 ||
          result == LIBRARY_ELEMENT5 ||
          result == LIBRARY_ELEMENT6 ||
          result == LIBRARY_ELEMENT7 ||
          result == LIBRARY_ELEMENT8 ||
          result == LIBRARY_ELEMENT) {
        // TODO(scheglov) try to find a way to avoid listing every result
        // e.g. "result.whenComplete == LIBRARY_ELEMENT"
        String uri = target.uri.toString();
        LibraryElement libraryElement = resynthesizer.getLibraryElement(uri);
        entry.setValue(result, libraryElement, TargetedResult.EMPTY_LIST);
        return true;
      } else if (result == READY_LIBRARY_ELEMENT2 ||
          result == READY_LIBRARY_ELEMENT5 ||
          result == READY_LIBRARY_ELEMENT6) {
        entry.setValue(result, true, TargetedResult.EMPTY_LIST);
        return true;
      } else if (result == SOURCE_KIND) {
        String uri = target.uri.toString();
        SourceKind kind = _getSourceKind(uri);
        if (kind != null) {
          entry.setValue(result, kind, TargetedResult.EMPTY_LIST);
          return true;
        }
        return false;
      } else {
//        throw new UnimplementedError('$result of $target');
      }
    }
    if (target is LibrarySpecificUnit) {
      if (target.library == null || !target.library.isInSystemLibrary) {
        return false;
      }
      if (result == COMPILATION_UNIT_ELEMENT) {
        String libraryUri = target.library.uri.toString();
        String unitUri = target.unit.uri.toString();
        CompilationUnitElement unit = resynthesizer.getElement(
            new ElementLocationImpl.con3(<String>[libraryUri, unitUri]));
        if (unit != null) {
          entry.setValue(result, unit, TargetedResult.EMPTY_LIST);
          return true;
        }
      }
    }
    return false;
  }

  void _buildAsyncLibrary() {
    LibraryElement library = resynthesizer.getLibraryElement('dart:async');
    typeProvider.initializeAsync(library);
  }

  void _buildCoreLibrary() {
    LibraryElement library = resynthesizer.getLibraryElement('dart:core');
    typeProvider.initializeCore(library);
  }

  /**
   * Return the [SourceKind] of the given [uri] or `null` if it is unknown.
   */
  SourceKind _getSourceKind(String uri) {
    if (bundle.linkedLibraryUris.contains(uri)) {
      return SourceKind.LIBRARY;
    }
    if (bundle.unlinkedUnitUris.contains(uri)) {
      return SourceKind.PART;
    }
    return null;
  }
}

/**
 * The implementation of [SummaryResynthesizer] for Dart SDK.
 */
class SdkSummaryResynthesizer extends SummaryResynthesizer {
  final PackageBundle bundle;
  final Map<String, UnlinkedUnit> unlinkedSummaries = <String, UnlinkedUnit>{};
  final Map<String, LinkedLibrary> linkedSummaries = <String, LinkedLibrary>{};

  SdkSummaryResynthesizer(AnalysisContext context, TypeProvider typeProvider,
      SourceFactory sourceFactory, this.bundle)
      : super(null, context, typeProvider, sourceFactory, false) {
    // TODO(paulberry): we always resynthesize the summary in weak mode.  Is
    // this ok?
    for (int i = 0; i < bundle.unlinkedUnitUris.length; i++) {
      unlinkedSummaries[bundle.unlinkedUnitUris[i]] = bundle.unlinkedUnits[i];
    }
    for (int i = 0; i < bundle.linkedLibraryUris.length; i++) {
      linkedSummaries[bundle.linkedLibraryUris[i]] = bundle.linkedLibraries[i];
    }
  }

  @override
  LinkedLibrary getLinkedSummary(String uri) {
    return linkedSummaries[uri];
  }

  @override
  UnlinkedUnit getUnlinkedSummary(String uri) {
    return unlinkedSummaries[uri];
  }

  @override
  bool hasLibrarySummary(String uri) {
    return uri.startsWith('dart:');
  }
}

/**
 * Provider for analysis results.
 */
abstract class SummaryResultProvider extends ResultProvider {
  /**
   * The [SummaryResynthesizer] of this context, maybe `null`.
   */
  SummaryResynthesizer get resynthesizer;
}

/**
 * Implementation of [TypeProvider] which can be initialized separately with
 * `dart:core` and `dart:async` libraries.
 */
class SummaryTypeProvider implements TypeProvider {
  bool _isCoreInitialized = false;
  bool _isAsyncInitialized = false;

  InterfaceType _boolType;
  InterfaceType _deprecatedType;
  InterfaceType _doubleType;
  InterfaceType _functionType;
  InterfaceType _futureDynamicType;
  InterfaceType _futureNullType;
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
    assert(_isCoreInitialized);
    return _boolType;
  }

  @override
  DartType get bottomType => BottomTypeImpl.instance;

  @override
  InterfaceType get deprecatedType {
    assert(_isCoreInitialized);
    return _deprecatedType;
  }

  @override
  InterfaceType get doubleType {
    assert(_isCoreInitialized);
    return _doubleType;
  }

  @override
  DartType get dynamicType => DynamicTypeImpl.instance;

  @override
  InterfaceType get functionType {
    assert(_isCoreInitialized);
    return _functionType;
  }

  @override
  InterfaceType get futureDynamicType {
    assert(_isAsyncInitialized);
    return _futureDynamicType;
  }

  @override
  InterfaceType get futureNullType {
    assert(_isAsyncInitialized);
    return _futureNullType;
  }

  @override
  InterfaceType get futureType {
    assert(_isAsyncInitialized);
    return _futureType;
  }

  @override
  InterfaceType get intType {
    assert(_isCoreInitialized);
    return _intType;
  }

  @override
  InterfaceType get iterableDynamicType {
    assert(_isCoreInitialized);
    return _iterableDynamicType;
  }

  @override
  InterfaceType get iterableType {
    assert(_isCoreInitialized);
    return _iterableType;
  }

  @override
  InterfaceType get listType {
    assert(_isCoreInitialized);
    return _listType;
  }

  @override
  InterfaceType get mapType {
    assert(_isCoreInitialized);
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
    assert(_isCoreInitialized);
    return _nullType;
  }

  @override
  InterfaceType get numType {
    assert(_isCoreInitialized);
    return _numType;
  }

  @override
  InterfaceType get objectType {
    assert(_isCoreInitialized);
    return _objectType;
  }

  @override
  InterfaceType get stackTraceType {
    assert(_isCoreInitialized);
    return _stackTraceType;
  }

  @override
  InterfaceType get streamDynamicType {
    assert(_isAsyncInitialized);
    return _streamDynamicType;
  }

  @override
  InterfaceType get streamType {
    assert(_isAsyncInitialized);
    return _streamType;
  }

  @override
  InterfaceType get stringType {
    assert(_isCoreInitialized);
    return _stringType;
  }

  @override
  InterfaceType get symbolType {
    assert(_isCoreInitialized);
    return _symbolType;
  }

  @override
  InterfaceType get typeType {
    assert(_isCoreInitialized);
    return _typeType;
  }

  @override
  DartType get undefinedType => UndefinedTypeImpl.instance;

  /**
   * Initialize the `dart:async` types provided by this type provider.
   */
  void initializeAsync(LibraryElement library) {
    assert(_isCoreInitialized);
    assert(!_isAsyncInitialized);
    _isAsyncInitialized = true;
    _futureType = _getType(library, "Future");
    _streamType = _getType(library, "Stream");
    _futureDynamicType = _futureType.instantiate(<DartType>[dynamicType]);
    _futureNullType = _futureType.instantiate(<DartType>[_nullType]);
    _streamDynamicType = _streamType.instantiate(<DartType>[dynamicType]);
  }

  /**
   * Initialize the `dart:core` types provided by this type provider.
   */
  void initializeCore(LibraryElement library) {
    assert(!_isCoreInitialized);
    assert(!_isAsyncInitialized);
    _isCoreInitialized = true;
    _boolType = _getType(library, "bool");
    _deprecatedType = _getType(library, "Deprecated");
    _doubleType = _getType(library, "double");
    _functionType = _getType(library, "Function");
    _intType = _getType(library, "int");
    _iterableType = _getType(library, "Iterable");
    _listType = _getType(library, "List");
    _mapType = _getType(library, "Map");
    _nullType = _getType(library, "Null");
    _numType = _getType(library, "num");
    _objectType = _getType(library, "Object");
    _stackTraceType = _getType(library, "StackTrace");
    _stringType = _getType(library, "String");
    _symbolType = _getType(library, "Symbol");
    _typeType = _getType(library, "Type");
    _iterableDynamicType = _iterableType.instantiate(<DartType>[dynamicType]);
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
