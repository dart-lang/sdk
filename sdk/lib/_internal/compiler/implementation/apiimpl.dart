// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library leg_apiimpl;

import 'dart:async';

import '../compiler.dart' as api;
import 'dart2jslib.dart' as leg;
import 'tree/tree.dart' as tree;
import 'elements/elements.dart' as elements;
import '../../libraries.dart';
import 'source_file.dart';


class Compiler extends leg.Compiler {
  api.CompilerInputProvider provider;
  api.DiagnosticHandler handler;
  final Uri libraryRoot;
  final Uri packageRoot;
  List<String> options;
  Map<String, dynamic> environment;
  bool mockableLibraryUsed = false;
  final Set<String> allowedLibraryCategories;

  Compiler(this.provider,
           api.CompilerOutputProvider outputProvider,
           this.handler,
           this.libraryRoot,
           this.packageRoot,
           List<String> options,
           this.environment)
      : this.options = options,
        this.allowedLibraryCategories = getAllowedLibraryCategories(options),
        super(
            outputProvider: outputProvider,
            enableTypeAssertions: hasOption(options, '--enable-checked-mode'),
            enableUserAssertions: hasOption(options, '--enable-checked-mode'),
            trustTypeAnnotations:
                hasOption(options, '--trust-type-annotations'),
            enableMinification: hasOption(options, '--minify'),
            enableNativeLiveTypeAnalysis:
                !hasOption(options, '--disable-native-live-type-analysis'),
            emitJavaScript: !hasOption(options, '--output-type=dart'),
            generateSourceMap: !hasOption(options, '--no-source-maps'),
            analyzeAllFlag: hasOption(options, '--analyze-all'),
            analyzeOnly: hasOption(options, '--analyze-only'),
            analyzeMain: hasOption(options, '--analyze-main'),
            analyzeSignaturesOnly:
                hasOption(options, '--analyze-signatures-only'),
            strips: extractCsvOption(options, '--force-strip='),
            enableConcreteTypeInference:
                hasOption(options, '--enable-concrete-type-inference'),
            disableTypeInferenceFlag:
                hasOption(options, '--disable-type-inference'),
            preserveComments: hasOption(options, '--preserve-comments'),
            verbose: hasOption(options, '--verbose'),
            sourceMapUri: extractUriOption(options, '--source-map='),
            outputUri: extractUriOption(options, '--out='),
            terseDiagnostics: hasOption(options, '--terse'),
            disableDeferredLoading:
                hasOption(options, '--disable-deferred-loading'),
                dumpInfo: hasOption(options, '--dump-info'),
            buildId: extractStringOption(
                options, '--build-id=',
                "build number could not be determined"),
            showPackageWarnings:
                hasOption(options, '--show-package-warnings'),
            useContentSecurityPolicy: hasOption(options, '--csp'),
            suppressWarnings: hasOption(options, '--suppress-warnings')) {
    if (!libraryRoot.path.endsWith("/")) {
      throw new ArgumentError("libraryRoot must end with a /");
    }
    if (packageRoot != null && !packageRoot.path.endsWith("/")) {
      throw new ArgumentError("packageRoot must end with a /");
    }
  }

  static String extractStringOption(List<String> options,
                                    String prefix,
                                    String defaultValue) {
    for (String option in options) {
      if (option.startsWith(prefix)) {
        return option.substring(prefix.length);
      }
    }
    return defaultValue;
  }

  static Uri extractUriOption(List<String> options, String prefix) {
    var option = extractStringOption(options, prefix, null);
    return (option == null) ? null : Uri.parse(option);
  }

  // CSV: Comma separated values.
  static List<String> extractCsvOption(List<String> options, String prefix) {
    for (String option in options) {
      if (option.startsWith(prefix)) {
        return option.substring(prefix.length).split(',');
      }
    }
    return const <String>[];
  }

  static Set<String> getAllowedLibraryCategories(List<String> options) {
    var result = extractCsvOption(options, '--categories=');
    if (result.isEmpty) {
      result = ['Client'];
    }
    result.add('Shared');
    result.add('Internal');
    return new Set<String>.from(result);
  }

  static bool hasOption(List<String> options, String option) {
    return options.indexOf(option) >= 0;
  }

  // TODO(johnniwinther): Merge better with [translateDartUri] when
  // [scanBuiltinLibrary] is removed.
  String lookupLibraryPath(String dartLibraryName) {
    LibraryInfo info = LIBRARIES[dartLibraryName];
    if (info == null) return null;
    if (!info.isDart2jsLibrary) return null;
    if (!allowedLibraryCategories.contains(info.category)) return null;
    String path = info.dart2jsPath;
    if (path == null) {
      path = info.path;
    }
    return "lib/$path";
  }

  String lookupPatchPath(String dartLibraryName) {
    LibraryInfo info = LIBRARIES[dartLibraryName];
    if (info == null) return null;
    if (!info.isDart2jsLibrary) return null;
    String path = info.dart2jsPatchPath;
    if (path == null) return null;
    return "lib/$path";
  }

  Future<elements.LibraryElement> scanBuiltinLibrary(String path) {
    Uri uri = libraryRoot.resolve(lookupLibraryPath(path));
    Uri canonicalUri = new Uri(scheme: "dart", path: path);
    return libraryLoader.loadLibrary(uri, null, canonicalUri);
  }

  void log(message) {
    handler(null, null, null, message, api.Diagnostic.VERBOSE_INFO);
  }

  /// See [leg.Compiler.translateResolvedUri].
  Uri translateResolvedUri(elements.LibraryElement importingLibrary,
                           Uri resolvedUri, tree.Node node) {
    if (resolvedUri.scheme == 'dart') {
      return translateDartUri(importingLibrary, resolvedUri, node);
    }
    return resolvedUri;
  }

  /**
   * Reads the script designated by [readableUri].
   */
  Future<leg.Script> readScript(leg.Spannable node, Uri readableUri) {
    if (!readableUri.isAbsolute) {
      if (node == null) node = leg.NO_LOCATION_SPANNABLE;
      internalError(node,
          'Relative uri $readableUri provided to readScript(Uri).');
    }

    // We need to store the current element since we are reporting read errors
    // asynchronously and therefore need to restore the current element for
    // [node] to be valid.
    elements.Element element = currentElement;
    void reportReadError(exception) {
      withCurrentElement(element, () {
        reportError(node,
                    leg.MessageKind.READ_SCRIPT_ERROR,
                    {'uri': readableUri, 'exception': exception});
      });
    }

    Uri resourceUri = translateUri(node, readableUri);
    // TODO(johnniwinther): Wrap the result from [provider] in a specialized
    // [Future] to ensure that we never execute an asynchronous action without
    // setting up the current element of the compiler.
    return new Future.sync(() => callUserProvider(resourceUri)).then((data) {
      SourceFile sourceFile;
      String resourceUriString = resourceUri.toString();
      if (data is List<int>) {
        sourceFile = new Utf8BytesSourceFile(resourceUriString, data);
      } else if (data is String) {
        sourceFile = new StringSourceFile(resourceUriString, data);
      } else {
        String message = "Expected a 'String' or a 'List<int>' from the input "
                         "provider, but got: ${Error.safeToString(data)}.";
        reportReadError(message);
      }
      // We use [readableUri] as the URI for the script since need to preserve
      // the scheme in the script because [Script.uri] is used for resolving
      // relative URIs mentioned in the script. See the comment on
      // [LibraryLoader] for more details.
      return new leg.Script(readableUri, resourceUri, sourceFile);
    }).catchError((error) {
      reportReadError(error);
      return null;
    });
  }

  /**
   * Translates a readable URI into a resource URI.
   *
   * See [LibraryLoader] for terminology on URIs.
   */
  Uri translateUri(leg.Spannable node, Uri readableUri) {
    switch (readableUri.scheme) {
      case 'package': return translatePackageUri(node, readableUri);
      default: return readableUri;
    }
  }

  Uri translateDartUri(elements.LibraryElement importingLibrary,
                       Uri resolvedUri, tree.Node node) {
    LibraryInfo libraryInfo = LIBRARIES[resolvedUri.path];
    String path = lookupLibraryPath(resolvedUri.path);
    if (libraryInfo != null &&
        libraryInfo.category == "Internal") {
      bool allowInternalLibraryAccess = false;
      if (importingLibrary != null) {
        if (importingLibrary.isPlatformLibrary || importingLibrary.isPatch) {
          allowInternalLibraryAccess = true;
        } else if (importingLibrary.canonicalUri.path.contains(
                       'dart/tests/compiler/dart2js_native')) {
          allowInternalLibraryAccess = true;
        }
      }
      if (!allowInternalLibraryAccess) {
        if (importingLibrary != null) {
          reportError(
              node,
              leg.MessageKind.INTERNAL_LIBRARY_FROM,
              {'resolvedUri': resolvedUri,
               'importingUri': importingLibrary.canonicalUri});
        } else {
          reportError(
              node,
              leg.MessageKind.INTERNAL_LIBRARY,
              {'resolvedUri': resolvedUri});
        }
      }
    }
    if (path == null) {
      reportError(node, leg.MessageKind.LIBRARY_NOT_FOUND,
                  {'resolvedUri': resolvedUri});
      return null;
    }
    if (resolvedUri.path == 'html' ||
        resolvedUri.path == 'io') {
      // TODO(ahe): Get rid of mockableLibraryUsed when test.dart
      // supports this use case better.
      mockableLibraryUsed = true;
    }
    return libraryRoot.resolve(path);
  }

  Uri resolvePatchUri(String dartLibraryPath) {
    String patchPath = lookupPatchPath(dartLibraryPath);
    if (patchPath == null) return null;
    return libraryRoot.resolve(patchPath);
  }

  Uri translatePackageUri(leg.Spannable node, Uri uri) {
    if (packageRoot == null) {
      reportFatalError(
          node, leg.MessageKind.PACKAGE_ROOT_NOT_SET, {'uri': uri});
    }
    return packageRoot.resolve(uri.path);
  }

  Future<bool> run(Uri uri) {
    log('Allowed library categories: $allowedLibraryCategories');
    return super.run(uri).then((bool success) {
      int cumulated = 0;
      for (final task in tasks) {
        cumulated += task.timing;
        log('${task.name} took ${task.timing}msec');
      }
      int total = totalCompileTime.elapsedMilliseconds;
      log('Total compile-time ${total}msec;'
          ' unaccounted ${total - cumulated}msec');
      return success;
    });
  }

  void reportDiagnostic(leg.Spannable node,
                        leg.Message message,
                        api.Diagnostic kind) {
    leg.SourceSpan span = spanFromSpannable(node);
    if (identical(kind, api.Diagnostic.ERROR)
        || identical(kind, api.Diagnostic.CRASH)) {
      compilationFailed = true;
    }
    // [:span.uri:] might be [:null:] in case of a [Script] with no [uri]. For
    // instance in the [Types] constructor in typechecker.dart.
    if (span == null || span.uri == null) {
      callUserHandler(null, null, null, '$message', kind);
    } else {
      callUserHandler(
          translateUri(null, span.uri), span.begin, span.end, '$message', kind);
    }
  }

  bool get isMockCompilation {
    return mockableLibraryUsed
      && (options.indexOf('--allow-mock-compilation') != -1);
  }

  void callUserHandler(Uri uri, int begin, int end,
                       String message, api.Diagnostic kind) {
    try {
      handler(uri, begin, end, message, kind);
    } catch (ex, s) {
      diagnoseCrashInUserCode(
          'Uncaught exception in diagnostic handler', ex, s);
      rethrow;
    }
  }

  Future callUserProvider(Uri uri) {
    try {
      return provider(uri);
    } catch (ex, s) {
      diagnoseCrashInUserCode('Uncaught exception in input provider', ex, s);
      rethrow;
    }
  }

  void diagnoseCrashInUserCode(String message, exception, stackTrace) {
    hasCrashed = true;
    print('$message: ${tryToString(exception)}');
    print(tryToString(stackTrace));
  }

  fromEnvironment(String name) => environment[name];
}
