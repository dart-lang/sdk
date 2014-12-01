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

  TypeResolver(DartUriResolver sdkResolver, [List otherResolvers]) {
    var resolvers = [sdkResolver];
    if (otherResolvers == null)  {
      resolvers.add(new FileUriResolver());
      resolvers.add(new PackageUriResolver([new JavaFile('packages/')]));
    } else {
      resolvers.addAll(otherResolvers);
    }
    context.sourceFactory = new SourceFactory(resolvers);
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

  /// Creates a [DartUriResolver] that uses the SDK at the given [sdkPath].
  static DartUriResolver sdkResolverFromDir(String sdkPath) =>
      new DartUriResolver(new DirectoryBasedDartSdk(new JavaFile(sdkPath)));

  /// Creates a [DartUriResolver] that uses a mock 'dart:' library contents.
  static DartUriResolver sdkResolverFromMock(
      Map<String, String> mockSdkSources) {
    return new MockDartSdk(mockSdkSources, reportMissing: true).resolver;
  }
}
