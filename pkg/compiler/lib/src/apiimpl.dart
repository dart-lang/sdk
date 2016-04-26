// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library leg_apiimpl;

import 'dart:async';
import 'dart:convert';

import 'package:package_config/packages.dart';
import 'package:package_config/packages_file.dart' as pkgs;
import 'package:package_config/src/packages_impl.dart'
    show MapPackages, NonFilePackagesDirectoryPackages;
import 'package:package_config/src/util.dart' show checkValidPackageUri;

import '../compiler_new.dart' as api;
import 'common.dart';
import 'common/tasks.dart' show GenericTask;
import 'compiler.dart';
import 'diagnostics/messages.dart' show Message;
import 'elements/elements.dart' as elements;
import 'environment.dart';
import 'io/source_file.dart';
import 'options.dart' show CompilerOptions;
import 'platform_configuration.dart' as platform_configuration;
import 'script.dart';

/// Implements the [Compiler] using a [api.CompilerInput] for supplying the
/// sources.
class CompilerImpl extends Compiler {
  api.CompilerInput provider;
  api.CompilerDiagnostics handler;
  Packages packages;
  bool mockableLibraryUsed = false;

  /// A mapping of the dart: library-names to their location.
  ///
  /// Initialized in [setupSdk].
  Map<String, Uri> sdkLibraries;

  GenericTask userHandlerTask;
  GenericTask userProviderTask;
  GenericTask userPackagesDiscoveryTask;

  Uri get libraryRoot => options.platformConfigUri.resolve(".");

  CompilerImpl(this.provider, api.CompilerOutput outputProvider, this.handler,
      CompilerOptions options)
      : super(
            options: options,
            outputProvider: outputProvider,
            environment: new _Environment(options.environment)) {
    _Environment env = environment;
    env.compiler = this;
    tasks.addAll([
      userHandlerTask = new GenericTask('Diagnostic handler', this),
      userProviderTask = new GenericTask('Input provider', this),
      userPackagesDiscoveryTask = new GenericTask('Package discovery', this),
    ]);
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
  Future<Script> readScript(Uri readableUri, [Spannable node]) {
    if (!readableUri.isAbsolute) {
      if (node == null) node = NO_LOCATION_SPANNABLE;
      reporter.internalError(
          node, 'Relative uri $readableUri provided to readScript(Uri).');
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
          reporter.reportErrorMessage(node, MessageKind.READ_SCRIPT_ERROR,
              {'uri': readableUri, 'exception': exception});
        });
      }
    }

    Uri resourceUri = translateUri(node, readableUri);
    if (resourceUri == null) return _synthesizeScript(readableUri);
    if (resourceUri.scheme == 'dart-ext') {
      if (!options.allowNativeExtensions) {
        reporter.withCurrentElement(element, () {
          reporter.reportErrorMessage(node, MessageKind.DART_EXT_NOT_SUPPORTED);
        });
      }
      return _synthesizeScript(readableUri);
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
      return _synthesizeScript(readableUri);
    });
  }

  Future<Script> _synthesizeScript(Uri readableUri) {
    return new Future.value(new Script.synthetic(readableUri));
  }

  /**
   * Translates a readable URI into a resource URI.
   *
   * See [LibraryLoader] for terminology on URIs.
   */
  Uri translateUri(Spannable node, Uri uri) =>
      uri.scheme == 'package' ? translatePackageUri(node, uri) : uri;

  /// Translates "resolvedUri" with scheme "dart" to a [uri] resolved relative
  /// to `options.platformConfigUri` according to the information in the file at
  /// `options.platformConfigUri`.
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
      reporter.reportErrorMessage(spannable, MessageKind.LIBRARY_NOT_FOUND,
          {'resolvedUri': resolvedUri});
      return null;
    }

    if (resolvedUri.path.startsWith('_')) {
      bool allowInternalLibraryAccess = importingLibrary != null &&
          (importingLibrary.isPlatformLibrary ||
              importingLibrary.isPatch ||
              importingLibrary.canonicalUri.path
                  .contains('sdk/tests/compiler/dart2js_native'));

      if (!allowInternalLibraryAccess) {
        if (importingLibrary != null) {
          reporter.reportErrorMessage(
              spannable, MessageKind.INTERNAL_LIBRARY_FROM, {
            'resolvedUri': resolvedUri,
            'importingUri': importingLibrary.canonicalUri
          });
        } else {
          reporter.reportErrorMessage(spannable, MessageKind.INTERNAL_LIBRARY,
              {'resolvedUri': resolvedUri});
          registerDisallowedLibraryUse(resolvedUri);
        }
        return null;
      }
    }

    if (location.scheme == "unsupported") {
      reporter.reportErrorMessage(spannable, MessageKind.LIBRARY_NOT_SUPPORTED,
          {'resolvedUri': resolvedUri});
      registerDisallowedLibraryUse(resolvedUri);
      return null;
    }

    if (resolvedUri.path == 'html' || resolvedUri.path == 'io') {
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
      reporter.reportErrorMessage(node, MessageKind.INVALID_PACKAGE_URI,
          {'uri': uri, 'exception': e.message});
      return null;
    }
    return packages.resolve(uri, notFound: (Uri notFound) {
      reporter.reportErrorMessage(
          node, MessageKind.LIBRARY_NOT_FOUND, {'resolvedUri': uri});
      return null;
    });
  }

  Future<elements.LibraryElement> analyzeUri(Uri uri,
      {bool skipLibraryWithPartOfTag: true}) {
    List<Future> setupFutures = new List<Future>();
    if (sdkLibraries == null) {
      setupFutures.add(setupSdk());
    }
    if (packages == null) {
      setupFutures.add(setupPackages(uri));
    }
    return Future.wait(setupFutures).then((_) {
      return super
          .analyzeUri(uri, skipLibraryWithPartOfTag: skipLibraryWithPartOfTag);
    });
  }

  Future setupPackages(Uri uri) {
    if (options.packageRoot != null) {
      // Use "non-file" packages because the file version requires a [Directory]
      // and we can't depend on 'dart:io' classes.
      packages = new NonFilePackagesDirectoryPackages(options.packageRoot);
    } else if (options.packageConfig != null) {
      return callUserProvider(options.packageConfig).then((configContents) {
        if (configContents is String) {
          configContents = UTF8.encode(configContents);
        }
        // The input provider may put a trailing 0 byte when it reads a source
        // file, which confuses the package config parser.
        if (configContents.length > 0 && configContents.last == 0) {
          configContents = configContents.sublist(0, configContents.length - 1);
        }
        packages =
            new MapPackages(pkgs.parse(configContents, options.packageConfig));
      }).catchError((error) {
        reporter.reportErrorMessage(
            NO_LOCATION_SPANNABLE,
            MessageKind.INVALID_PACKAGE_CONFIG,
            {'uri': options.packageConfig, 'exception': error});
        packages = Packages.noPackages;
      });
    } else {
      if (options.packagesDiscoveryProvider == null) {
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
      return platform_configuration
          .load(options.platformConfigUri, provider)
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
    log('Using platform configuration at ${options.platformConfigUri}');

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
      List<DiagnosticMessage> infos, api.Diagnostic kind) {
    _reportDiagnosticMessage(message, kind);
    for (DiagnosticMessage info in infos) {
      _reportDiagnosticMessage(info, api.Diagnostic.INFO);
    }
  }

  void _reportDiagnosticMessage(
      DiagnosticMessage diagnosticMessage, api.Diagnostic kind) {
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

  bool get isMockCompilation =>
      mockableLibraryUsed && options.allowMockCompilation;

  void callUserHandler(Message message, Uri uri, int begin, int end,
      String text, api.Diagnostic kind) {
    userHandlerTask.measure(() {
      handler.report(message, uri, begin, end, text, kind);
    });
  }

  Future callUserProvider(Uri uri) {
    return userProviderTask.measure(() => provider.readFromUri(uri));
  }

  Future<Packages> callUserPackagesDiscovery(Uri uri) {
    return userPackagesDiscoveryTask
        .measure(() => options.packagesDiscoveryProvider(uri));
  }

  Uri lookupLibraryUri(String libraryName) {
    assert(invariant(NO_LOCATION_SPANNABLE, sdkLibraries != null,
        message: "setupSdk() has not been run"));
    return sdkLibraries[libraryName];
  }

  Uri resolvePatchUri(String libraryName) {
    return backend.resolvePatchUri(libraryName, options.platformConfigUri);
  }
}

class _Environment implements Environment {
  final Map<String, String> definitions;

  // TODO(sigmund): break the circularity here: Compiler needs an environment to
  // intialize the library loader, but the environment here needs to know about
  // how the sdk is set up and about whether the backend supports mirrors.
  CompilerImpl compiler;

  _Environment(this.definitions);

  String valueOf(String name) {
    assert(invariant(NO_LOCATION_SPANNABLE, compiler.sdkLibraries != null,
        message: "setupSdk() has not been run"));

    var result = definitions[name];
    if (result != null || definitions.containsKey(name)) return result;
    if (!name.startsWith(_dartLibraryEnvironmentPrefix)) return null;

    String libraryName = name.substring(_dartLibraryEnvironmentPrefix.length);

    // Private libraries are not exposed to the users.
    if (libraryName.startsWith("_")) return null;

    if (compiler.sdkLibraries.containsKey(libraryName)) {
      // Dart2js always "supports" importing 'dart:mirrors' but will abort
      // the compilation at a later point if the backend doesn't support
      // mirrors. In this case 'mirrors' should not be in the environment.
      if (libraryName == 'mirrors') {
        return compiler.backend.supportsReflection ? "true" : null;
      }
      return "true";
    }
    return null;
  }
}

/// For every 'dart:' library, a corresponding environment variable is set
/// to "true". The environment variable's name is the concatenation of
/// this prefix and the name (without the 'dart:'.
///
/// For example 'dart:html' has the environment variable 'dart.library.html' set
/// to "true".
const String _dartLibraryEnvironmentPrefix = 'dart.library.';
