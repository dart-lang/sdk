// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart' show ResourceProvider;
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/generated/engine.dart';
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
  SummaryDataStore _dataStore;
  InSummaryUriResolver _uriResolver;
  PackageBundle _bundle;
  ResourceProvider resourceProvider;

  /**
   * The [AnalysisContext] which is used for all of the sources in this sdk.
   */
  InternalAnalysisContext _analysisContext;

  SummaryBasedDartSdk(String summaryPath, bool _, {this.resourceProvider}) {
    _dataStore = new SummaryDataStore(<String>[summaryPath],
        resourceProvider: resourceProvider);
    _uriResolver = new InSummaryUriResolver(resourceProvider, _dataStore);
    _bundle = _dataStore.bundles.single;
  }

  SummaryBasedDartSdk.fromBundle(bool _, PackageBundle bundle,
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
      AnalysisOptionsImpl analysisOptions = new AnalysisOptionsImpl();
      _analysisContext = new SdkAnalysisContext(analysisOptions);
      SourceFactory factory = new SourceFactory(
          [new DartUriResolver(this)], null, resourceProvider);
      _analysisContext.sourceFactory = factory;
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

  bool get strongMode => true;

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
