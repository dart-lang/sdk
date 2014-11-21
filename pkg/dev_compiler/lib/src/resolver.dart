library ddc.src.resolver;

import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_io.dart' show JavaFile;
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/source.dart' show DartUriResolver;
import 'package:analyzer/src/generated/source_io.dart';

import 'dart_sdk.dart';

/// Encapsulates a resolver from the analyzer package.
class TypeResolver {
  // TODO(sigmund): add a uri-resolver that can read files from memory instead
  // of disk (for unittests).

  final InternalAnalysisContext context =
      AnalysisEngine.instance.createAnalysisContext();
  final Map<Uri, Source> _sources = <Uri, Source>{};

  /// Creates a resolver that uses an SDK located at the given [sdkPath].
  factory TypeResolver.fromDir(String sdkPath) {
    var sdk = new DirectoryBasedDartSdk(new JavaFile(sdkPath));
    var sdkResolver = new DartUriResolver(sdk);
    return new TypeResolver._(sdkResolver);
  }

  /// Creates a resolver using a mock contents for each `dart:` library.
  factory TypeResolver.fromMock(Map<String, String> mockSdkSources) {
    var sdk = new MockDartSdk(mockSdkSources, reportMissing: true);
    return new TypeResolver._(sdk.resolver);
  }

  TypeResolver._(DartUriResolver sdkResolver) {
    context.sourceFactory = new SourceFactory([
      sdkResolver,
      new FileUriResolver(),
      new PackageUriResolver([new JavaFile('packages/')]),
    ]);
  }

  /// Find the corresponding [Source] for [uri].
  Source findSource(Uri uri) {
    var source = _sources[uri];
    if (source != null) return source;
    return _sources[uri] = context.sourceFactory.forUri('$uri');
  }

  /// Get any analyzer errors found when resolving [uri]'s source.
  List<AnalysisError> getErrors(Uri uri) =>
      context.getErrors(findSource(uri)).errors;

  /// Resolve the source at the given [uri] and return the corresponding library
  /// element.
  LibraryElement resolve(Uri uri) =>
      context.computeLibraryElement(findSource(uri));
}
