// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/class_hierarchy.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/source.dart'
    show SourceFactory, UriResolver;
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/test_utilities/mock_sdk_elements.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';

class TestAnalysisContext implements AnalysisContext {
  final RootReference rootReference = RootReference();

  @override
  final SourceFactory sourceFactory;

  final _MockAnalysisSession _analysisSession = _MockAnalysisSession();
  final AnalysisOptions analysisOptions = AnalysisOptionsImpl();

  late final LibraryElementImpl coreLibrary;
  late final LibraryElementImpl asyncLibrary;
  late TypeProviderImpl _typeProvider;
  late TypeSystemImpl _typeSystem;

  TestAnalysisContext(ResourceProviderMixin resources)
    : sourceFactory = SourceFactory([_TestUriResolver(resources)]) {
    var sdkElements = MockSdkElements(this, rootReference, _analysisSession);
    coreLibrary = sdkElements.coreLibrary;
    asyncLibrary = sdkElements.asyncLibrary;

    _typeProvider = TypeProviderImpl(
      coreLibrary: coreLibrary,
      asyncLibrary: asyncLibrary,
    );

    _typeSystem = TypeSystemImpl(typeProvider: _typeProvider);

    _setLibraryTypeSystem(coreLibrary);
    _setLibraryTypeSystem(asyncLibrary);
  }

  AnalysisSessionImpl get analysisSession => _analysisSession;

  TypeProviderImpl get typeProvider {
    return _typeProvider;
  }

  TypeSystemImpl get typeSystem {
    return _typeSystem;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  void _setLibraryTypeSystem(LibraryElementImpl libraryElement) {
    libraryElement.typeProvider = _typeProvider;
    libraryElement.typeSystem = _typeSystem;
  }
}

class _MockAnalysisSession implements AnalysisSessionImpl {
  @override
  final ClassHierarchy classHierarchy = ClassHierarchy();

  @override
  final InheritanceManager3 inheritanceManager = InheritanceManager3();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestUriResolver implements UriResolver {
  final ResourceProviderMixin resources;

  _TestUriResolver(this.resources);

  @override
  Uri? pathToUri(String path) => null;

  @override
  Source? resolveAbsolute(Uri uri) {
    var pathSegments = uri.pathSegments;
    if (uri.isScheme('dart')) {
      if (pathSegments case [var name]) {
        var path = '/sdk/$name/$name.dart';
        var file = resources.getFile(path);
        return FileSource(file, uri);
      } else {
        var path = '/sdk/${pathSegments.join('/')}';
        var file = resources.getFile(path);
        return FileSource(file, uri);
      }
    } else if (uri.isScheme('package')) {
      if (pathSegments.length >= 2) {
        var packageName = pathSegments[0];
        var rest = pathSegments.sublist(1).join('/');
        var path = '/home/$packageName/lib/$rest';
        var file = resources.getFile(path);
        return FileSource(file, uri);
      }
    }
    throw UnimplementedError('Unsupported URI: $uri');
  }
}
