// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library leg_apiimpl;

import 'dart:uri';
import 'dart:async';

import '../compiler.dart' as api;
import 'dart2jslib.dart' as leg;
import 'tree/tree.dart' as tree;
import 'elements/elements.dart' as elements;
import 'ssa/tracer.dart' as ssa;
import '../../libraries.dart';
import 'source_file.dart';

class Compiler extends leg.Compiler {
  api.ReadStringFromUri provider;
  api.DiagnosticHandler handler;
  final Uri libraryRoot;
  final Uri packageRoot;
  List<String> options;
  bool mockableLibraryUsed = false;
  final Set<String> allowedLibraryCategories;

  Compiler(this.provider,
           api.CompilerOutputProvider outputProvider,
           this.handler,
           this.libraryRoot,
           this.packageRoot,
           List<String> options)
      : this.options = options,
        this.allowedLibraryCategories = getAllowedLibraryCategories(options),
        super(
            tracer: new ssa.HTracer(
                ssa.GENERATE_SSA_TRACE ? outputProvider('dart', 'cfg') : null),
            outputProvider: outputProvider,
            enableTypeAssertions: hasOption(options, '--enable-checked-mode'),
            enableUserAssertions: hasOption(options, '--enable-checked-mode'),
            enableMinification: hasOption(options, '--minify'),
            enableNativeLiveTypeAnalysis:
                !hasOption(options, '--disable-native-live-type-analysis'),
            emitJavaScript: !hasOption(options, '--output-type=dart'),
            disallowUnsafeEval: hasOption(options, '--disallow-unsafe-eval'),
            analyzeAll: hasOption(options, '--analyze-all'),
            analyzeOnly: hasOption(options, '--analyze-only'),
            analyzeSignaturesOnly:
                hasOption(options, '--analyze-signatures-only'),
            rejectDeprecatedFeatures:
                hasOption(options, '--reject-deprecated-language-features'),
            checkDeprecationInSdk:
                hasOption(options,
                          '--report-sdk-use-of-deprecated-language-features'),
            strips: getStrips(options),
            enableConcreteTypeInference:
                hasOption(options, '--enable-concrete-type-inference'),
            preserveComments: hasOption(options, '--preserve-comments'),
            verbose: hasOption(options, '--verbose'),
            buildId: getBuildId(options)) {
    if (!libraryRoot.path.endsWith("/")) {
      throw new ArgumentError("libraryRoot must end with a /");
    }
    if (packageRoot != null && !packageRoot.path.endsWith("/")) {
      throw new ArgumentError("packageRoot must end with a /");
    }
  }

  static String getBuildId(List<String> options) {
    for (String option in options) {
      if (option.startsWith('--build-id=')) {
        return option.substring('--build-id='.length);
      }
    }
    return "build number could not be determined";
  }

  static List<String> getStrips(List<String> options) {
    for (String option in options) {
      if (option.startsWith('--force-strip=')) {
        return option.substring('--force-strip='.length).split(',');
      }
    }
    return const <String>[];
  }

  static Set<String> getAllowedLibraryCategories(List<String> options) {
    for (String option in options) {
      if (option.startsWith('--categories=')) {
        var result = option.substring('--categories='.length).split(',');
        result.add('Shared');
        result.add('Internal');
        return new Set<String>.from(result);
      }
    }
    return new Set<String>.from(['Client', 'Shared', 'Internal']);
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

  elements.LibraryElement scanBuiltinLibrary(String path) {
    Uri uri = libraryRoot.resolve(lookupLibraryPath(path));
    Uri canonicalUri = new Uri.fromComponents(scheme: "dart", path: path);
    elements.LibraryElement library =
        libraryLoader.loadLibrary(uri, null, canonicalUri);
    return library;
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
  leg.Script readScript(Uri readableUri, [tree.Node node]) {
    if (!readableUri.isAbsolute) {
      internalError('Relative uri $readableUri provided to readScript(Uri)',
                    node: node);
    }
    return fileReadingTask.measure(() {
      Uri resourceUri = translateUri(readableUri, node);
      String text = "";
      try {
        // TODO(ahe): We expect the future to be complete and call value
        // directly. In effect, we don't support truly asynchronous API.
        text = deprecatedFutureValue(provider(resourceUri));
      } catch (exception) {
        if (node != null) {
          cancel("$exception", node: node);
        } else {
          reportDiagnostic(null, "$exception", api.Diagnostic.ERROR);
          throw new leg.CompilerCancelledException("$exception");
        }
      }
      SourceFile sourceFile = new SourceFile(resourceUri.toString(), text);
      // We use [readableUri] as the URI for the script since need to preserve
      // the scheme in the script because [Script.uri] is used for resolving
      // relative URIs mentioned in the script. See the comment on
      // [LibraryLoader] for more details.
      return new leg.Script(readableUri, sourceFile);
    });
  }

  /**
   * Translates a readable URI into a resource URI.
   *
   * See [LibraryLoader] for terminology on URIs.
   */
  Uri translateUri(Uri readableUri, tree.Node node) {
    switch (readableUri.scheme) {
      case 'package': return translatePackageUri(readableUri, node);
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
        if (node != null && importingLibrary != null) {
          reportDiagnostic(spanFromNode(node),
              'Error: Internal library $resolvedUri is not accessible from '
              '${importingLibrary.canonicalUri}.',
              api.Diagnostic.ERROR);
        } else {
          reportDiagnostic(null,
              'Error: Internal library $resolvedUri is not accessible.',
              api.Diagnostic.ERROR);
        }
        //path = null;
      }
    }
    if (path == null) {
      if (node != null) {
        reportError(node, 'library not found ${resolvedUri}');
      } else {
        reportDiagnostic(null, 'library not found ${resolvedUri}',
                         api.Diagnostic.ERROR);
      }
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

  translatePackageUri(Uri uri, tree.Node node) => packageRoot.resolve(uri.path);

  bool run(Uri uri) {
    log('Allowed library categories: $allowedLibraryCategories');
    bool success = super.run(uri);
    int cumulated = 0;
    for (final task in tasks) {
      cumulated += task.timing;
      log('${task.name} took ${task.timing}msec');
    }
    int total = totalCompileTime.elapsedMilliseconds;
    log('Total compile-time ${total}msec;'
        ' unaccounted ${total - cumulated}msec');
    return success;
  }

  void reportDiagnostic(leg.SourceSpan span, String message,
                        api.Diagnostic kind) {
    if (identical(kind, api.Diagnostic.ERROR)
        || identical(kind, api.Diagnostic.CRASH)) {
      compilationFailed = true;
    }
    // [:span.uri:] might be [:null:] in case of a [Script] with no [uri]. For
    // instance in the [Types] constructor in typechecker.dart.
    if (span == null || span.uri == null) {
      handler(null, null, null, message, kind);
    } else {
      handler(translateUri(span.uri, null), span.begin, span.end,
              message, kind);
    }
  }

  bool get isMockCompilation {
    return mockableLibraryUsed
      && (options.indexOf('--allow-mock-compilation') != -1);
  }
}
