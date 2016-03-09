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

import '../compiler_new.dart' as api;
import 'commandline_options.dart';
import 'common.dart';
import 'common/tasks.dart' show
    GenericTask;
import 'compiler.dart';
import 'diagnostics/diagnostic_listener.dart' show
    DiagnosticOptions;
import 'diagnostics/messages.dart' show
    Message;
import 'elements/elements.dart' as elements;
import 'io/source_file.dart';
import 'platform_configuration.dart' as platform_configuration;
import 'script.dart';

const bool forceIncrementalSupport =
    const bool.fromEnvironment('DART2JS_EXPERIMENTAL_INCREMENTAL_SUPPORT');

/// For every 'dart:' library, a corresponding environment variable is set
/// to "true". The environment variable's name is the concatenation of
/// this prefix and the name (without the 'dart:'.
///
/// For example 'dart:html' has the environment variable 'dart.library.html' set
/// to "true".
const String dartLibraryEnvironmentPrefix = 'dart.library.';

/// Locations of the platform descriptor files relative to the library root.
const String _clientPlatform = "lib/dart_client.platform";
const String _serverPlatform = "lib/dart_server.platform";
const String _sharedPlatform = "lib/dart_shared.platform";
const String _dart2dartPlatform = "lib/dart2dart.platform";

/// Implements the [Compiler] using a [api.CompilerInput] for supplying the
/// sources.
class CompilerImpl extends Compiler {
  api.CompilerInput provider;
  api.CompilerDiagnostics handler;
  final Uri platformConfigUri;
  final Uri packageConfig;
  final Uri packageRoot;
  final api.PackagesDiscoveryProvider packagesDiscoveryProvider;
  Packages packages;
  List<String> options;
  Map<String, dynamic> environment;
  bool mockableLibraryUsed = false;

  /// A mapping of the dart: library-names to their location.
  ///
  /// Initialized in [setupSdk].
  Map<String, Uri> sdkLibraries;

  GenericTask userHandlerTask;
  GenericTask userProviderTask;
  GenericTask userPackagesDiscoveryTask;

  Uri get libraryRoot => platformConfigUri.resolve(".");

  CompilerImpl(this.provider,
           api.CompilerOutput outputProvider,
           this.handler,
           Uri libraryRoot,
           this.packageRoot,
           List<String> options,
           this.environment,
           [this.packageConfig,
            this.packagesDiscoveryProvider])
      : this.options = options,
        this.platformConfigUri = resolvePlatformConfig(libraryRoot, options),
        super(
            outputProvider: outputProvider,
            enableTypeAssertions: hasOption(options, Flags.enableCheckedMode),
            enableUserAssertions: hasOption(options, Flags.enableCheckedMode),
            trustTypeAnnotations:
                hasOption(options, Flags.trustTypeAnnotations),
            trustPrimitives:
                hasOption(options, Flags.trustPrimitives),
            trustJSInteropTypeAnnotations:
                hasOption(options, Flags.trustJSInteropTypeAnnotations),
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
            disableTypeInferenceFlag:
                hasOption(options, Flags.disableTypeInference),
            preserveComments: hasOption(options, Flags.preserveComments),
            useCpsIr: hasOption(options, Flags.useCpsIr),
            verbose: hasOption(options, Flags.verbose),
            sourceMapUri: extractUriOption(options, '--source-map='),
            outputUri: extractUriOption(options, '--out='),
            deferredMapUri: extractUriOption(options, '--deferred-map='),
            dumpInfo: hasOption(options, Flags.dumpInfo),
            buildId: extractStringOption(
                options, '--build-id=',
                "build number could not be determined"),
            useContentSecurityPolicy:
              hasOption(options, Flags.useContentSecurityPolicy),
            useStartupEmitter: hasOption(options, Flags.fastStartup),
            enableConditionalDirectives:
                hasOption(options, Flags.conditionalDirectives),
            hasIncrementalSupport:
                forceIncrementalSupport ||
                hasOption(options, Flags.incrementalSupport),
            diagnosticOptions: new DiagnosticOptions(
                suppressWarnings: hasOption(options, Flags.suppressWarnings),
                fatalWarnings: hasOption(options, Flags.fatalWarnings),
                suppressHints: hasOption(options, Flags.suppressHints),
                terseDiagnostics: hasOption(options, Flags.terse),
                shownPackageWarnings: extractOptionalCsvOption(
                      options, Flags.showPackageWarnings)),
            enableExperimentalMirrors:
                hasOption(options, Flags.enableExperimentalMirrors),
            enableAssertMessage:
                hasOption(options, Flags.enableAssertMessage),
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

  /// Extract list of comma separated values provided for [flag]. Returns an
  /// empty list if [option] contain [flag] without arguments. Returns `null` if
  /// [option] doesn't contain [flag] with or without arguments.
  static List<String> extractOptionalCsvOption(
      List<String> options, String flag) {
    String prefix = '$flag=';
    for (String option in options) {
      if (option == flag) {
        return const <String>[];
      }
      if (option.startsWith(flag)) {
        return option.substring(prefix.length).split(',');
      }
    }
    return null;
  }

  static Uri resolvePlatformConfig(Uri libraryRoot,
                                   List<String> options) {
    String platformConfigPath =
        extractStringOption(options, "--platform-config=", null);
    if (platformConfigPath != null) {
      return libraryRoot.resolve(platformConfigPath);
    } else if (hasOption(options, '--output-type=dart')) {
      return libraryRoot.resolve(_dart2dartPlatform);
    } else {
      Iterable<String> categories = extractCsvOption(options, '--categories=');
      if (categories.length == 0) {
        return libraryRoot.resolve(_clientPlatform);
      }
      assert(categories.length <= 2);
      if (categories.contains("Client")) {
        if (categories.contains("Server")) {
          return libraryRoot.resolve(_sharedPlatform);
        }
        return libraryRoot.resolve(_clientPlatform);
      }
      assert(categories.contains("Server"));
      return libraryRoot.resolve(_serverPlatform);
    }
  }

  static bool hasOption(List<String> options, String option) {
    return options.indexOf(option) >= 0;
  }

  void log(message) {
    callUserHandler(
        null, null, null, null, message, api.Diagnostic.VERBOSE_INFO);
  }

  /// See [Compiler.translateResolvedUri].
  Uri translateResolvedUri(elements.LibraryElement importingLibrary,
                           Uri resolvedUri, Spannable spannable) {
    if (resolvedUri.scheme == 'dart') {
      return translateDartUri(importingLibrary, resolvedUri, spannable);
    }
    return resolvedUri;
  }

  /**
   * Reads the script designated by [readableUri].
   */
  Future<Script> readScript(Spannable node, Uri readableUri) {
    if (!readableUri.isAbsolute) {
      if (node == null) node = NO_LOCATION_SPANNABLE;
      reporter.internalError(node,
          'Relative uri $readableUri provided to readScript(Uri).');
    }

    // We need to store the current element since we are reporting read errors
    // asynchronously and therefore need to restore the current element for
    // [node] to be valid.
    elements.Element element = currentElement;
    void reportReadError(exception) {
      if (element == null || node == null) {
        reporter.reportErrorMessage(
            new SourceSpan(readableUri, 0, 0),
            MessageKind.READ_SELF_ERROR,
            {'uri': readableUri, 'exception': exception});
      } else {
        reporter.withCurrentElement(element, () {
          reporter.reportErrorMessage(
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
        reporter.withCurrentElement(element, () {
          reporter.reportErrorMessage(
              node, MessageKind.DART_EXT_NOT_SUPPORTED);
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

  /// Translates "resolvedUri" with scheme "dart" to a [uri] resolved relative
  /// to [platformConfigUri] according to the information in the file at
  /// [platformConfigUri].
  ///
  /// Returns null and emits an error if the library could not be found or
  /// imported into [importingLibrary].
  ///
  /// Internal libraries (whose name starts with '_') can be only resolved if
  /// [importingLibrary] is a platform or patch library.
  Uri translateDartUri(elements.LibraryElement importingLibrary,
                       Uri resolvedUri, Spannable spannable) {

    Uri location = lookupLibraryUri(resolvedUri.path);

    if (location == null) {
      reporter.reportErrorMessage(
          spannable,
          MessageKind.LIBRARY_NOT_FOUND,
          {'resolvedUri': resolvedUri});
      return null;
    }

    if (resolvedUri.path.startsWith('_')  ) {
      bool allowInternalLibraryAccess = importingLibrary != null &&
          (importingLibrary.isPlatformLibrary ||
              importingLibrary.isPatch ||
              importingLibrary.canonicalUri.path
                  .contains('sdk/tests/compiler/dart2js_native'));

      if (!allowInternalLibraryAccess) {
        if (importingLibrary != null) {
          reporter.reportErrorMessage(
              spannable,
              MessageKind.INTERNAL_LIBRARY_FROM,
              {'resolvedUri': resolvedUri,
                'importingUri': importingLibrary.canonicalUri});
        } else {
          reporter.reportErrorMessage(
              spannable,
              MessageKind.INTERNAL_LIBRARY,
              {'resolvedUri': resolvedUri});
          registerDisallowedLibraryUse(resolvedUri);
        }
        return null;
      }
    }

    if (location.scheme == "unsupported") {
      reporter.reportErrorMessage(
          spannable,
          MessageKind.LIBRARY_NOT_SUPPORTED,
          {'resolvedUri': resolvedUri});
      registerDisallowedLibraryUse(resolvedUri);
      return null;
    }

    if (resolvedUri.path == 'html' ||
        resolvedUri.path == 'io') {
      // TODO(ahe): Get rid of mockableLibraryUsed when test.dart
      // supports this use case better.
      mockableLibraryUsed = true;
    }
    return location;
  }

  Uri translatePackageUri(Spannable node, Uri uri) {
    try {
      checkValidPackageUri(uri);
    } on ArgumentError catch (e) {
      reporter.reportErrorMessage(
          node,
          MessageKind.INVALID_PACKAGE_URI,
          {'uri': uri, 'exception': e.message});
      return null;
    }
    return packages.resolve(uri,
        notFound: (Uri notFound) {
          reporter.reportErrorMessage(
              node,
              MessageKind.LIBRARY_NOT_FOUND,
              {'resolvedUri': uri});
          return null;
        });
  }

  Future<elements.LibraryElement> analyzeUri(
      Uri uri,
      {bool skipLibraryWithPartOfTag: true}) {
    List<Future> setupFutures = new List<Future>();
    if (sdkLibraries == null) {
      setupFutures.add(setupSdk());
    }
    if (packages == null) {
      setupFutures.add(setupPackages(uri));
    }
    return Future.wait(setupFutures).then((_) {
      return super.analyzeUri(uri,
          skipLibraryWithPartOfTag: skipLibraryWithPartOfTag);
    });
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
        reporter.reportErrorMessage(
            NO_LOCATION_SPANNABLE,
            MessageKind.INVALID_PACKAGE_CONFIG,
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

  Future<Null> setupSdk() {
    if (sdkLibraries == null) {
      return platform_configuration.load(platformConfigUri, provider)
          .then((Map<String, Uri> mapping) {
        sdkLibraries = mapping;
      });
    } else {
      // The incremental compiler sets up the sdk before run.
      // Therefore this will be called a second time.
      return new Future.value(null);
    }
  }

  Future<bool> run(Uri uri) {
    log('Using platform configuration at ${platformConfigUri}');

    return Future.wait([setupSdk(), setupPackages(uri)]).then((_) {
      assert(sdkLibraries != null);
      assert(packages != null);

      return super.run(uri).then((bool success) {
        int cumulated = 0;
        for (final task in tasks) {
          int elapsed = task.timing;
          if (elapsed != 0) {
            cumulated += elapsed;
            log('${task.name} took ${elapsed}msec');
            for (String subtask in task.subtasks) {
              int subtime = task.getSubtaskTime(subtask);
              log('${task.name} > $subtask took ${subtime}msec');
            }
          }
        }
        int total = totalCompileTime.elapsedMilliseconds;
        log('Total compile-time ${total}msec;'
            ' unaccounted ${total - cumulated}msec');
        return success;
      });
    });
  }

  void reportDiagnostic(DiagnosticMessage message,
                        List<DiagnosticMessage> infos,
                        api.Diagnostic kind) {
    _reportDiagnosticMessage(message, kind);
    for (DiagnosticMessage info in infos) {
      _reportDiagnosticMessage(info, api.Diagnostic.INFO);
    }
  }

  void _reportDiagnosticMessage(DiagnosticMessage diagnosticMessage,
                                api.Diagnostic kind) {
    // [:span.uri:] might be [:null:] in case of a [Script] with no [uri]. For
    // instance in the [Types] constructor in typechecker.dart.
    SourceSpan span = diagnosticMessage.sourceSpan;
    Message message = diagnosticMessage.message;
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

  fromEnvironment(String name) {
    assert(invariant(NO_LOCATION_SPANNABLE,
        sdkLibraries != null, message: "setupSdk() has not been run"));

    var result = environment[name];
    if (result != null || environment.containsKey(name)) return result;
    if (!name.startsWith(dartLibraryEnvironmentPrefix)) return null;

    String libraryName = name.substring(dartLibraryEnvironmentPrefix.length);

    // Private libraries are not exposed to the users.
    if (libraryName.startsWith("_")) return null;

    if (sdkLibraries.containsKey(libraryName)) {
      // Dart2js always "supports" importing 'dart:mirrors' but will abort
      // the compilation at a later point if the backend doesn't support
      // mirrors. In this case 'mirrors' should not be in the environment.
      if (libraryName == 'mirrors') {
        return backend.supportsReflection ? "true" : null;
      }
      return "true";
    }
    return null;
  }

  Uri lookupLibraryUri(String libraryName) {
    assert(invariant(NO_LOCATION_SPANNABLE,
        sdkLibraries != null, message: "setupSdk() has not been run"));
    return sdkLibraries[libraryName];
  }

  Uri resolvePatchUri(String libraryName) {
    return backend.resolvePatchUri(libraryName, platformConfigUri);
  }
}
