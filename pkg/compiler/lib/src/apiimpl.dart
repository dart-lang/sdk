// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library leg_apiimpl;

import 'dart:async';
import 'dart:convert';

import 'package:package_config/packages.dart';
import 'package:package_config/packages_file.dart' as pkgs;
import 'package:package_config/src/packages_impl.dart' show
    MapPackages,
    NonFilePackagesDirectoryPackages;
import 'package:package_config/src/util.dart' show
    checkValidPackageUri;
import 'package:sdk_library_metadata/libraries.dart' hide LIBRARIES;
import 'package:sdk_library_metadata/libraries.dart' as library_info show
    LIBRARIES;

import '../compiler_new.dart' as api;
import 'commandline_options.dart';
import 'common/tasks.dart' show
    GenericTask;
import 'compiler.dart' as leg;
import 'diagnostics/messages.dart';
import 'diagnostics/source_span.dart' show
    SourceSpan;
import 'diagnostics/spannable.dart' show
    NO_LOCATION_SPANNABLE,
    Spannable;
import 'elements/elements.dart' as elements;
import 'io/source_file.dart';
import 'script.dart';
import 'tree/tree.dart' as tree;

const bool forceIncrementalSupport =
    const bool.fromEnvironment('DART2JS_EXPERIMENTAL_INCREMENTAL_SUPPORT');

class Compiler extends leg.Compiler {
  api.CompilerInput provider;
  api.CompilerDiagnostics handler;
  final Uri libraryRoot;
  final Uri packageConfig;
  final Uri packageRoot;
  final api.PackagesDiscoveryProvider packagesDiscoveryProvider;
  Packages packages;
  List<String> options;
  Map<String, dynamic> environment;
  bool mockableLibraryUsed = false;
  final Set<String> allowedLibraryCategories;

  GenericTask userHandlerTask;
  GenericTask userProviderTask;
  GenericTask userPackagesDiscoveryTask;

  Compiler(this.provider,
           api.CompilerOutput outputProvider,
           this.handler,
           this.libraryRoot,
           this.packageRoot,
           List<String> options,
           this.environment,
           [this.packageConfig,
            this.packagesDiscoveryProvider])
      : this.options = options,
        this.allowedLibraryCategories = getAllowedLibraryCategories(options),
        super(
            outputProvider: outputProvider,
            enableTypeAssertions: hasOption(options, Flags.enableCheckedMode),
            enableUserAssertions: hasOption(options, Flags.enableCheckedMode),
            trustTypeAnnotations:
                hasOption(options, Flags.trustTypeAnnotations),
            trustPrimitives:
                hasOption(options, Flags.trustPrimitives),
            enableMinification: hasOption(options, Flags.minify),
            useFrequencyNamer:
                !hasOption(options, Flags.noFrequencyBasedMinification),
            preserveUris: hasOption(options, Flags.preserveUris),
            enableNativeLiveTypeAnalysis:
                !hasOption(options, Flags.disableNativeLiveTypeAnalysis),
            emitJavaScript: !(hasOption(options, '--output-type=dart') ||
                              hasOption(options, '--output-type=dart-multi')),
            dart2dartMultiFile: hasOption(options, '--output-type=dart-multi'),
            generateSourceMap: !hasOption(options, Flags.noSourceMaps),
            analyzeAllFlag: hasOption(options, Flags.analyzeAll),
            analyzeOnly: hasOption(options, Flags.analyzeOnly),
            analyzeMain: hasOption(options, Flags.analyzeMain),
            analyzeSignaturesOnly:
                hasOption(options, Flags.analyzeSignaturesOnly),
            strips: extractCsvOption(options, '--force-strip='),
            enableConcreteTypeInference:
                hasOption(options, Flags.enableConcreteTypeInference),
            disableTypeInferenceFlag:
                hasOption(options, Flags.disableTypeInference),
            preserveComments: hasOption(options, Flags.preserveComments),
            useCpsIr: hasOption(options, Flags.useCpsIr),
            verbose: hasOption(options, Flags.verbose),
            sourceMapUri: extractUriOption(options, '--source-map='),
            outputUri: extractUriOption(options, '--out='),
            terseDiagnostics: hasOption(options, Flags.terse),
            deferredMapUri: extractUriOption(options, '--deferred-map='),
            dumpInfo: hasOption(options, Flags.dumpInfo),
            buildId: extractStringOption(
                options, '--build-id=',
                "build number could not be determined"),
            showPackageWarnings:
                hasOption(options, Flags.showPackageWarnings),
            useContentSecurityPolicy:
              hasOption(options, Flags.useContentSecurityPolicy),
            useStartupEmitter: hasOption(options, Flags.fastStartup),
            hasIncrementalSupport:
                forceIncrementalSupport ||
                hasOption(options, Flags.incrementalSupport),
            suppressWarnings: hasOption(options, Flags.suppressWarnings),
            fatalWarnings: hasOption(options, Flags.fatalWarnings),
            enableExperimentalMirrors:
                hasOption(options, Flags.enableExperimentalMirrors),
            generateCodeWithCompileTimeErrors:
                hasOption(options, Flags.generateCodeWithCompileTimeErrors),
            testMode: hasOption(options, Flags.testMode),
            allowNativeExtensions:
                hasOption(options, Flags.allowNativeExtensions)) {
    tasks.addAll([
        userHandlerTask = new GenericTask('Diagnostic handler', this),
        userProviderTask = new GenericTask('Input provider', this),
        userPackagesDiscoveryTask =
            new GenericTask('Package discovery', this),
    ]);
    if (libraryRoot == null) {
      throw new ArgumentError("[libraryRoot] is null.");
    }
    if (!libraryRoot.path.endsWith("/")) {
      throw new ArgumentError("[libraryRoot] must end with a /.");
    }
    if (packageRoot != null && packageConfig != null) {
      throw new ArgumentError("Only one of [packageRoot] or [packageConfig] "
                              "may be given.");
    }
    if (packageRoot != null && !packageRoot.path.endsWith("/")) {
      throw new ArgumentError("[packageRoot] must end with a /.");
    }
    if (!analyzeOnly) {
      if (allowNativeExtensions) {
        throw new ArgumentError(
            "${Flags.allowNativeExtensions} is only supported in combination "
            "with ${Flags.analyzeOnly}");
      }
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
  String lookupLibraryPath(Uri uri, LibraryInfo info) {
    if (info == null) return null;
    if (!info.isDart2jsLibrary) return null;
    if (!allowedLibraryCategories.contains(info.category)) {
      registerDisallowedLibraryUse(uri);
      return null;
    }
    String path = info.dart2jsPath;
    if (path == null) {
      path = info.path;
    }
    return "lib/$path";
  }

  String lookupPatchPath(String dartLibraryName) {
    LibraryInfo info = lookupLibraryInfo(dartLibraryName);
    if (info == null) return null;
    if (!info.isDart2jsLibrary) return null;
    String path = info.dart2jsPatchPath;
    if (path == null) return null;
    return "lib/$path";
  }

  void log(message) {
    callUserHandler(
        null, null, null, null, message, api.Diagnostic.VERBOSE_INFO);
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
  Future<Script> readScript(Spannable node, Uri readableUri) {
    if (!readableUri.isAbsolute) {
      if (node == null) node = NO_LOCATION_SPANNABLE;
      internalError(node,
          'Relative uri $readableUri provided to readScript(Uri).');
    }

    // We need to store the current element since we are reporting read errors
    // asynchronously and therefore need to restore the current element for
    // [node] to be valid.
    elements.Element element = currentElement;
    void reportReadError(exception) {
      if (element == null || node == null) {
        reportError(
            new SourceSpan(readableUri, 0, 0),
            MessageKind.READ_SELF_ERROR,
            {'uri': readableUri, 'exception': exception});
      } else {
        withCurrentElement(element, () {
          reportError(
              node,
              MessageKind.READ_SCRIPT_ERROR,
              {'uri': readableUri, 'exception': exception});
        });
      }
    }

    Uri resourceUri = translateUri(node, readableUri);
    if (resourceUri == null) return synthesizeScript(node, readableUri);
    if (resourceUri.scheme == 'dart-ext') {
      if (!allowNativeExtensions) {
        withCurrentElement(element, () {
          reportError(node, MessageKind.DART_EXT_NOT_SUPPORTED);
        });
      }
      return synthesizeScript(node, readableUri);
    }

    // TODO(johnniwinther): Wrap the result from [provider] in a specialized
    // [Future] to ensure that we never execute an asynchronous action without
    // setting up the current element of the compiler.
    return new Future.sync(() => callUserProvider(resourceUri)).then((data) {
      SourceFile sourceFile;
      if (data is List<int>) {
        sourceFile = new Utf8BytesSourceFile(resourceUri, data);
      } else if (data is String) {
        sourceFile = new StringSourceFile.fromUri(resourceUri, data);
      } else {
        String message = "Expected a 'String' or a 'List<int>' from the input "
                         "provider, but got: ${Error.safeToString(data)}.";
        reportReadError(message);
      }
      // We use [readableUri] as the URI for the script since need to preserve
      // the scheme in the script because [Script.uri] is used for resolving
      // relative URIs mentioned in the script. See the comment on
      // [LibraryLoader] for more details.
      return new Script(readableUri, resourceUri, sourceFile);
    }).catchError((error) {
      reportReadError(error);
      return synthesizeScript(node, readableUri);
    });
  }

  Future<Script> synthesizeScript(Spannable node, Uri readableUri) {
    return new Future.value(
        new Script(
            readableUri, readableUri,
            new StringSourceFile.fromUri(
                readableUri,
                "// Synthetic source file generated for '$readableUri'."),
            isSynthesized: true));
  }

  /**
   * Translates a readable URI into a resource URI.
   *
   * See [LibraryLoader] for terminology on URIs.
   */
  Uri translateUri(Spannable node, Uri readableUri) {
    switch (readableUri.scheme) {
      case 'package': return translatePackageUri(node, readableUri);
      default: return readableUri;
    }
  }

  Uri translateDartUri(elements.LibraryElement importingLibrary,
                       Uri resolvedUri, tree.Node node) {
    LibraryInfo libraryInfo = lookupLibraryInfo(resolvedUri.path);
    String path = lookupLibraryPath(resolvedUri, libraryInfo);
    if (libraryInfo != null &&
        libraryInfo.category == "Internal") {
      bool allowInternalLibraryAccess = false;
      if (importingLibrary != null) {
        if (importingLibrary.isPlatformLibrary || importingLibrary.isPatch) {
          allowInternalLibraryAccess = true;
        } else if (importingLibrary.canonicalUri.path.contains(
                       'sdk/tests/compiler/dart2js_native')) {
          allowInternalLibraryAccess = true;
        }
      }
      if (!allowInternalLibraryAccess) {
        if (importingLibrary != null) {
          reportError(
              node,
              MessageKind.INTERNAL_LIBRARY_FROM,
              {'resolvedUri': resolvedUri,
               'importingUri': importingLibrary.canonicalUri});
        } else {
          reportError(
              node,
              MessageKind.INTERNAL_LIBRARY,
              {'resolvedUri': resolvedUri});
        }
      }
    }
    if (path == null) {
      if (libraryInfo == null) {
        reportError(node, MessageKind.LIBRARY_NOT_FOUND,
                    {'resolvedUri': resolvedUri});
      } else {
        reportError(node, MessageKind.LIBRARY_NOT_SUPPORTED,
                    {'resolvedUri': resolvedUri});
      }
      // TODO(johnniwinther): Support signaling the error through the returned
      // value.
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

  Uri translatePackageUri(Spannable node, Uri uri) {
    try {
      checkValidPackageUri(uri);
    } on ArgumentError catch (e) {
      reportError(
          node,
          MessageKind.INVALID_PACKAGE_URI,
          {'uri': uri, 'exception': e.message});
      return null;
    }
    return packages.resolve(uri,
        notFound: (Uri notFound) {
          reportError(
              node,
              MessageKind.LIBRARY_NOT_FOUND,
              {'resolvedUri': uri}
          );
          return null;
        });
  }

  Future<elements.LibraryElement> analyzeUri(
      Uri uri,
      {bool skipLibraryWithPartOfTag: true}) {
    if (packages == null) {
      return setupPackages(uri).then((_) => super.analyzeUri(uri));
    }
    return super.analyzeUri(
        uri, skipLibraryWithPartOfTag: skipLibraryWithPartOfTag);
  }

  Future setupPackages(Uri uri) {
    if (packageRoot != null) {
      // Use "non-file" packages because the file version requires a [Directory]
      // and we can't depend on 'dart:io' classes.
      packages = new NonFilePackagesDirectoryPackages(packageRoot);
    } else if (packageConfig != null) {
      return callUserProvider(packageConfig).then((packageConfigContents) {
        if (packageConfigContents is String) {
          packageConfigContents = UTF8.encode(packageConfigContents);
        }
        // The input provider may put a trailing 0 byte when it reads a source
        // file, which confuses the package config parser.
        if (packageConfigContents.length > 0 &&
            packageConfigContents.last == 0) {
          packageConfigContents = packageConfigContents.sublist(
              0, packageConfigContents.length - 1);
        }
        packages =
            new MapPackages(pkgs.parse(packageConfigContents, packageConfig));
      }).catchError((error) {
        reportError(NO_LOCATION_SPANNABLE, MessageKind.INVALID_PACKAGE_CONFIG,
            {'uri': packageConfig, 'exception': error});
        packages = Packages.noPackages;
      });
    } else {
      if (packagesDiscoveryProvider == null) {
        packages = Packages.noPackages;
      } else {
        return callUserPackagesDiscovery(uri).then((p) {
          packages = p;
        });
      }
    }
    return new Future.value();
  }

  Future<bool> run(Uri uri) {
    log('Allowed library categories: $allowedLibraryCategories');

    return setupPackages(uri).then((_) {
      assert(packages != null);

      return super.run(uri).then((bool success) {
        int cumulated = 0;
        for (final task in tasks) {
          int elapsed = task.timing;
          if (elapsed != 0) {
            cumulated += elapsed;
            log('${task.name} took ${elapsed}msec');
          }
        }
        int total = totalCompileTime.elapsedMilliseconds;
        log('Total compile-time ${total}msec;'
            ' unaccounted ${total - cumulated}msec');
        return success;
      });
    });
  }

  void reportDiagnostic(Spannable node,
                        Message message,
                        api.Diagnostic kind) {
    SourceSpan span = spanFromSpannable(node);
    if (identical(kind, api.Diagnostic.ERROR)
        || identical(kind, api.Diagnostic.CRASH)
        || (fatalWarnings && identical(kind, api.Diagnostic.WARNING))) {
      compilationFailed = true;
    }
    // [:span.uri:] might be [:null:] in case of a [Script] with no [uri]. For
    // instance in the [Types] constructor in typechecker.dart.
    if (span == null || span.uri == null) {
      callUserHandler(message, null, null, null, '$message', kind);
    } else {
      callUserHandler(
          message, span.uri, span.begin, span.end, '$message', kind);
    }
  }

  bool get isMockCompilation {
    return mockableLibraryUsed
      && (options.indexOf(Flags.allowMockCompilation) != -1);
  }

  void callUserHandler(Message message, Uri uri, int begin, int end,
                       String text, api.Diagnostic kind) {
    try {
      userHandlerTask.measure(() {
        handler.report(message, uri, begin, end, text, kind);
      });
    } catch (ex, s) {
      diagnoseCrashInUserCode(
          'Uncaught exception in diagnostic handler', ex, s);
      rethrow;
    }
  }

  Future callUserProvider(Uri uri) {
    try {
      return userProviderTask.measure(() => provider.readFromUri(uri));
    } catch (ex, s) {
      diagnoseCrashInUserCode('Uncaught exception in input provider', ex, s);
      rethrow;
    }
  }

  Future<Packages> callUserPackagesDiscovery(Uri uri) {
    try {
      return userPackagesDiscoveryTask.measure(
                 () => packagesDiscoveryProvider(uri));
    } catch (ex, s) {
      diagnoseCrashInUserCode('Uncaught exception in package discovery', ex, s);
      rethrow;
    }
  }

  void diagnoseCrashInUserCode(String message, exception, stackTrace) {
    hasCrashed = true;
    print('$message: ${tryToString(exception)}');
    print(tryToString(stackTrace));
  }

  fromEnvironment(String name) => environment[name];

  LibraryInfo lookupLibraryInfo(String libraryName) {
    return library_info.LIBRARIES[libraryName];
  }
}
