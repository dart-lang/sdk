// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:analyzer/src/test_utilities/mock_sdk_elements.dart';
import 'package:test/test.dart';

/**
 * The class `AnalysisContextFactory` defines utility methods used to create analysis contexts
 * for testing purposes.
 */
class AnalysisContextFactory {
  static String _DART_MATH = "dart:math";

  static String _DART_INTERCEPTORS = "dart:_interceptors";

  static String _DART_JS_HELPER = "dart:_js_helper";

  /**
   * Create and return an analysis context that has a fake core library already
   * resolved. The given [resourceProvider] will be used when accessing the file
   * system.
   */
  static InternalAnalysisContext contextWithCore(
      {UriResolver contributedResolver,
      MemoryResourceProvider resourceProvider}) {
    AnalysisContextForTests context = new AnalysisContextForTests();
    return initContextWithCore(context, FeatureSet.forTesting(),
        contributedResolver, resourceProvider);
  }

  /**
   * Create and return an analysis context that uses the given [options] and has
   * a fake core library already resolved. The given [resourceProvider] will be
   * used when accessing the file system.
   */
  static InternalAnalysisContext contextWithCoreAndOptions(
      AnalysisOptions options,
      {MemoryResourceProvider resourceProvider}) {
    AnalysisContextForTests context = new AnalysisContextForTests();
    context._internalSetAnalysisOptions(options);
    return initContextWithCore(
        context, options.contextFeatures, null, resourceProvider);
  }

  /**
   * Create and return an analysis context that has a fake core library already
   * resolved. If not `null`, the given [packages] map will be used to create a
   * package URI resolver. The given [resourceProvider] will be used when
   * accessing the file system.
   */
  static InternalAnalysisContext contextWithCoreAndPackages(
      Map<String, String> packages,
      {MemoryResourceProvider resourceProvider}) {
    AnalysisContextForTests context = new AnalysisContextForTests();
    return initContextWithCore(context, FeatureSet.forTesting(),
        new TestPackageUriResolver(packages), resourceProvider);
  }

  /**
   * Initialize the given analysis [context] with a fake core library that has
   * already been resolved. If not `null`, the given [contributedResolver] will
   * be added to the context's source factory. The given [resourceProvider] will
   * be used when accessing the file system.
   */
  static InternalAnalysisContext initContextWithCore(
      InternalAnalysisContext context, FeatureSet featureSet,
      [UriResolver contributedResolver,
      MemoryResourceProvider resourceProvider]) {
    DartSdk sdk = new _AnalysisContextFactory_initContextWithCore(
        resourceProvider, resourceProvider.convertPath('/fake/sdk'));
    List<UriResolver> resolvers = <UriResolver>[
      new DartUriResolver(sdk),
      new ResourceUriResolver(resourceProvider)
    ];
    if (contributedResolver != null) {
      resolvers.add(contributedResolver);
    }
    SourceFactory sourceFactory = new SourceFactory(resolvers);
    context.sourceFactory = sourceFactory;

    var sdkElements = MockSdkElements(
      context,
      featureSet.isEnabled(Feature.non_nullable)
          ? NullabilitySuffix.none
          : NullabilitySuffix.star,
    );

    context.typeProvider = TypeProviderImpl(
      sdkElements.coreLibrary,
      sdkElements.asyncLibrary,
    );

    return context;
  }
}

/**
 * An analysis context that has a fake SDK that is much smaller and faster for
 * testing purposes.
 */
class AnalysisContextForTests extends AnalysisContextImpl {
  @override
  void set analysisOptions(AnalysisOptions options) {
    AnalysisOptions currentOptions = analysisOptions;
    bool needsRecompute = currentOptions.analyzeFunctionBodiesPredicate !=
            options.analyzeFunctionBodiesPredicate ||
        currentOptions.generateImplicitErrors !=
            options.generateImplicitErrors ||
        currentOptions.generateSdkErrors != options.generateSdkErrors ||
        currentOptions.dart2jsHint != options.dart2jsHint ||
        (currentOptions.hint && !options.hint) ||
        currentOptions.preserveComments != options.preserveComments;
    if (needsRecompute) {
      fail(
          "Cannot set options that cause the sources to be reanalyzed in a test context");
    }
    super.analysisOptions = options;
  }

  @override
  bool exists(Source source) =>
      super.exists(source) || sourceFactory.dartSdk.context.exists(source);

  @override
  TimestampedData<String> getContents(Source source) {
    if (source.isInSystemLibrary) {
      return sourceFactory.dartSdk.context.getContents(source);
    }
    return super.getContents(source);
  }

  @override
  int getModificationStamp(Source source) {
    if (source.isInSystemLibrary) {
      return sourceFactory.dartSdk.context.getModificationStamp(source);
    }
    return super.getModificationStamp(source);
  }

  /**
   * Set the analysis options, even if they would force re-analysis. This method should only be
   * invoked before the fake SDK is initialized.
   *
   * @param options the analysis options to be set
   */
  void _internalSetAnalysisOptions(AnalysisOptions options) {
    super.analysisOptions = options;
  }
}

class TestPackageUriResolver extends UriResolver {
  Map<String, Source> sourceMap = new HashMap<String, Source>();

  TestPackageUriResolver(Map<String, String> map) {
    map.forEach((String name, String contents) {
      sourceMap['package:$name/$name.dart'] =
          new StringSource(contents, '/$name/lib/$name.dart');
    });
  }

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    String uriString = uri.toString();
    return sourceMap[uriString];
  }

  @override
  Uri restoreAbsolute(Source source) => throw new UnimplementedError();
}

class _AnalysisContextFactory_initContextWithCore extends FolderBasedDartSdk {
  _AnalysisContextFactory_initContextWithCore(
      ResourceProvider resourceProvider, String sdkPath)
      : super(resourceProvider, resourceProvider.getFolder(sdkPath));

  @override
  LibraryMap initialLibraryMap(bool useDart2jsPaths) {
    LibraryMap map = new LibraryMap();
    _addLibrary(map, DartSdk.DART_ASYNC, false, "async.dart");
    _addLibrary(map, DartSdk.DART_CORE, false, "core.dart");
    _addLibrary(map, DartSdk.DART_HTML, false, "html_dartium.dart");
    _addLibrary(map, AnalysisContextFactory._DART_MATH, false, "math.dart");
    _addLibrary(map, AnalysisContextFactory._DART_INTERCEPTORS, true,
        "_interceptors.dart");
    _addLibrary(
        map, AnalysisContextFactory._DART_JS_HELPER, true, "_js_helper.dart");
    return map;
  }

  void _addLibrary(LibraryMap map, String uri, bool isInternal, String path) {
    SdkLibraryImpl library = new SdkLibraryImpl(uri);
    if (isInternal) {
      library.category = "Internal";
    }
    library.path = path;
    map.setLibrary(uri, library);
  }
}
