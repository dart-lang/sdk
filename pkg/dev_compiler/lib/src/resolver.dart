library ddc.src.resolver;

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_io.dart' show JavaFile;
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/source.dart' show DartUriResolver;
import 'package:analyzer/src/generated/source_io.dart';
import 'package:logging/logging.dart' as logger;

import 'dart_sdk.dart';
import 'utils.dart';

final _log = new logger.Logger('ddc.src.resolver');

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

  /// Log any errors encountered when resolving [source] and return whether any
  /// errors were found.
  bool logErrors(Source source) {
    List<AnalysisError> errors = context.getErrors(source).errors;
    bool failure = false;
    if (errors.isNotEmpty) {
      _log.info('analyzer found a total of ${errors.length} errors:');
      for (var error in errors) {
        var offset = error.offset;
        var span = spanFor(error.source, offset, offset + error.length);
        var severity = error.errorCode.errorSeverity;
        var isError = severity == ErrorSeverity.ERROR;
        if (isError) failure = true;
        var level = isError ? logger.Level.SEVERE : logger.Level.WARNING;
        _log.log(level,
            span.message(error.message, color: colorOf(severity.name)));
      }
    }
    return failure;
  }
}
