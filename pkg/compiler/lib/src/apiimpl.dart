// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library leg_apiimpl;

import 'dart:async';

import 'package:package_config/packages.dart';
import 'package:package_config/packages_file.dart' as pkgs;
import 'package:package_config/src/packages_impl.dart'
    show MapPackages, NonFilePackagesDirectoryPackages;
import 'package:package_config/src/util.dart' show checkValidPackageUri;

import '../compiler_new.dart' as api;
import 'common/tasks.dart' show GenericTask, Measurer;
import 'common.dart';
import 'compiler.dart';
import 'diagnostics/messages.dart' show Message;
import 'environment.dart';
import 'options.dart' show CompilerOptions;
import 'platform_configuration.dart' as platform_configuration;
import 'resolved_uri_translator.dart';

/// Implements the [Compiler] using a [api.CompilerInput] for supplying the
/// sources.
class CompilerImpl extends Compiler {
  final Measurer measurer;
  api.CompilerInput provider;
  api.CompilerDiagnostics handler;
  Packages packages;

  ForwardingResolvedUriTranslator resolvedUriTranslator;

  GenericTask userHandlerTask;
  GenericTask userProviderTask;
  GenericTask userPackagesDiscoveryTask;

  Uri get libraryRoot => options.platformConfigUri.resolve(".");

  CompilerImpl(this.provider, api.CompilerOutput outputProvider, this.handler,
      CompilerOptions options,
      {MakeReporterFunction makeReporter})
      // NOTE: allocating measurer is done upfront to ensure the wallclock is
      // started before other computations.
      : measurer = new Measurer(enableTaskMeasurements: options.verbose),
        resolvedUriTranslator = new ForwardingResolvedUriTranslator(),
        super(
            options: options,
            outputProvider: outputProvider,
            environment: new _Environment(options.environment),
            makeReporter: makeReporter) {
    _Environment env = environment;
    env.compiler = this;
    tasks.addAll([
      userHandlerTask = new GenericTask('Diagnostic handler', measurer),
      userProviderTask = new GenericTask('Input provider', measurer),
      userPackagesDiscoveryTask =
          new GenericTask('Package discovery', measurer),
    ]);
  }

  void log(message) {
    callUserHandler(
        null, null, null, null, message, api.Diagnostic.VERBOSE_INFO);
  }

  /**
   * Translates a readable URI into a resource URI.
   *
   * See [LibraryLoader] for terminology on URIs.
   */
  Uri translateUri(Spannable node, Uri uri) =>
      uri.scheme == 'package' ? translatePackageUri(node, uri) : uri;

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

  Future setupPackages(Uri uri) {
    if (options.packageRoot != null) {
      // Use "non-file" packages because the file version requires a [Directory]
      // and we can't depend on 'dart:io' classes.
      packages = new NonFilePackagesDirectoryPackages(options.packageRoot);
    } else if (options.packageConfig != null) {
      Future<api.Input<List<int>>> future =
          callUserProvider(options.packageConfig, api.InputKind.binary);
      return future.then((api.Input<List<int>> binary) {
        packages =
            new MapPackages(pkgs.parse(binary.data, options.packageConfig));
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

  Future setupSdk() {
    var future = new Future.value(null);
    if (resolvedUriTranslator.isNotSet) {
      future = future.then((_) {
        return platform_configuration
            .load(options.platformConfigUri, provider)
            .then((Map<String, Uri> mapping) {
          resolvedUriTranslator.resolvedUriTranslator =
              new ResolvedUriTranslator(mapping);
        });
      });
    }
    // TODO(johnniwinther): This does not apply anymore.
    // The incremental compiler sets up the sdk before run.
    // Therefore this will be called a second time.
    return future;
  }

  Future<bool> run(Uri uri) {
    Duration setupDuration = measurer.wallClock.elapsed;
    return selfTask.measureSubtask("CompilerImpl.run", () {
      log('Using platform configuration at ${options.platformConfigUri}');

      return setupSdk().then((_) => setupPackages(uri)).then((_) {
        assert(resolvedUriTranslator.isSet);
        assert(packages != null);

        return super.run(uri);
      }).then((bool success) {
        if (options.verbose) {
          StringBuffer timings = new StringBuffer();
          computeTimings(setupDuration, timings);
          log("$timings");
        }
        return success;
      });
    });
  }

  void computeTimings(Duration setupDuration, StringBuffer timings) {
    timings.writeln("Timings:");
    Duration totalDuration = measurer.wallClock.elapsed;
    Duration asyncDuration = measurer.asyncWallClock.elapsed;
    Duration cumulatedDuration = Duration.zero;
    for (final task in tasks) {
      String running = task.isRunning ? "*" : "";
      Duration duration = task.duration;
      if (duration != Duration.zero) {
        cumulatedDuration += duration;
        timings.writeln('    $running${task.name} took'
            ' ${duration.inMilliseconds}msec');
        for (String subtask in task.subtasks) {
          int subtime = task.getSubtaskTime(subtask);
          String running = task.getSubtaskIsRunning(subtask) ? "*" : "";
          timings.writeln(
              '    $running${task.name} > $subtask took ${subtime}msec');
        }
      }
    }
    Duration unaccountedDuration =
        totalDuration - cumulatedDuration - setupDuration - asyncDuration;
    double percent =
        unaccountedDuration.inMilliseconds * 100 / totalDuration.inMilliseconds;
    timings.write('    Total compile-time ${totalDuration.inMilliseconds}msec;'
        ' setup ${setupDuration.inMilliseconds}msec;'
        ' async ${asyncDuration.inMilliseconds}msec;'
        ' unaccounted ${unaccountedDuration.inMilliseconds}msec'
        ' (${percent.toStringAsFixed(2)}%)');
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

  void callUserHandler(Message message, Uri uri, int begin, int end,
      String text, api.Diagnostic kind) {
    try {
      userHandlerTask.measure(() {
        handler.report(message, uri, begin, end, text, kind);
      });
    } catch (ex, s) {
      reportCrashInUserCode('Uncaught exception in diagnostic handler', ex, s);
      rethrow;
    }
  }

  Future<api.Input> callUserProvider(Uri uri, api.InputKind inputKind) {
    try {
      return userProviderTask
          .measureIo(() => provider.readFromUri(uri, inputKind: inputKind));
    } catch (ex, s) {
      reportCrashInUserCode('Uncaught exception in input provider', ex, s);
      rethrow;
    }
  }

  Future<Packages> callUserPackagesDiscovery(Uri uri) {
    try {
      return userPackagesDiscoveryTask
          .measureIo(() => options.packagesDiscoveryProvider(uri));
    } catch (ex, s) {
      reportCrashInUserCode('Uncaught exception in package discovery', ex, s);
      rethrow;
    }
  }
}

class _Environment implements Environment {
  final Map<String, String> definitions;

  // TODO(sigmund): break the circularity here: Compiler needs an environment to
  // initialize the library loader, but the environment here needs to know about
  // how the sdk is set up and about whether the backend supports mirrors.
  CompilerImpl compiler;

  _Environment(this.definitions);

  String valueOf(String name) {
    assert(compiler.resolvedUriTranslator != null,
        failedAt(NO_LOCATION_SPANNABLE, "setupSdk() has not been run"));

    var result = definitions[name];
    if (result != null || definitions.containsKey(name)) return result;
    if (!name.startsWith(_dartLibraryEnvironmentPrefix)) return null;

    String libraryName = name.substring(_dartLibraryEnvironmentPrefix.length);

    // Private libraries are not exposed to the users.
    if (libraryName.startsWith("_")) return null;

    Uri libraryUri = compiler.resolvedUriTranslator.sdkLibraries[libraryName];
    // TODO(sigmund): use libraries.json instead of .platform files, then simply
    // use the `supported` bit.
    if (libraryUri != null && libraryUri.scheme != "unsupported") {
      if (libraryName == 'mirrors') return null;
      if (libraryName == 'isolate') return null;
      return "true";
    }

    // Note: we return null on `dart:io` here, even if we allow users to
    // unconditionally import it.
    //
    // In the past it was invalid to import `dart:io` for client apps. We just
    // made it valid to import it as a stopgap measure to support packages like
    // `http`. This is temporary until we support config-imports in the
    // language.
    //
    // Because it is meant to be temporary and because the returned `dart:io`
    // implementation will throw on most APIs, we still preserve that
    // when compiling client apps the `dart:io` library is technically not
    // supported, and so `const bool.fromEnvironment(dart.library.io)` is false.
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
