// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library leg_apiimpl;

import 'dart:async';
import 'dart:convert' show utf8;

import 'package:front_end/src/api_unstable/dart2js.dart'
    show getSupportedLibraryNames;

import '../compiler_new.dart' as api;
import 'common/metrics.dart' show Metrics, Metric;
import 'common/tasks.dart' show GenericTask, Measurer;
import 'common.dart';
import 'compiler.dart';
import 'diagnostics/messages.dart' show Message;
import 'environment.dart';
import 'io/source_file.dart';
import 'options.dart' show CompilerOptions;

/// Implements the [Compiler] using a [api.CompilerInput] for supplying the
/// sources.
class CompilerImpl extends Compiler {
  @override
  final Measurer measurer;
  @override
  api.CompilerInput provider;
  api.CompilerDiagnostics handler;

  GenericTask userHandlerTask;
  GenericTask userProviderTask;

  CompilerImpl(this.provider, api.CompilerOutput outputProvider, this.handler,
      CompilerOptions options,
      {MakeReporterFunction makeReporter})
      // NOTE: allocating measurer is done upfront to ensure the wallclock is
      // started before other computations.
      : measurer = new Measurer(enableTaskMeasurements: options.verbose),
        super(
            options: options,
            outputProvider: outputProvider,
            environment: new _Environment(options.environment),
            makeReporter: makeReporter) {
    tasks.addAll([
      userHandlerTask = new GenericTask('Diagnostic handler', measurer),
      userProviderTask = new GenericTask('Input provider', measurer),
    ]);
  }

  void logInfo(String message) {
    callUserHandler(null, null, null, null, message, api.Diagnostic.INFO);
  }

  void logVerbose(String message) {
    callUserHandler(
        null, null, null, null, message, api.Diagnostic.VERBOSE_INFO);
  }

  Future setupSdk() {
    var future = new Future.value(null);
    _Environment env = environment;
    if (env.supportedLibraries == null) {
      future = future.then((_) {
        Uri specificationUri = options.librariesSpecificationUri;
        return provider.readFromUri(specificationUri).then((api.Input spec) {
          String json = null;
          // TODO(sigmund): simplify this, we have some API inconsistencies when
          // our internal input adds a terminating zero.
          if (spec is SourceFile) {
            json = spec.slowText();
          } else if (spec is Binary) {
            json = utf8.decode(spec.data);
          }

          // TODO(sigmund): would be nice to front-load some of the CFE option
          // processing and parse this .json file only once.
          env.supportedLibraries = getSupportedLibraryNames(specificationUri,
                  json, options.compileForServer ? "dart2js_server" : "dart2js")
              .toSet();
        });
      });
    }
    // TODO(johnniwinther): This does not apply anymore.
    // The incremental compiler sets up the sdk before run.
    // Therefore this will be called a second time.
    return future;
  }

  @override
  Future<bool> run(Uri uri) {
    Duration setupDuration = measurer.elapsedWallClock;
    return selfTask.measureSubtask("impl.run", () {
      return setupSdk().then((_) {
        return super.run(uri);
      }).then((bool success) {
        if (options.verbose) {
          StringBuffer timings = StringBuffer();
          computeTimings(setupDuration, timings);
          logVerbose('$timings');
        }
        if (options.reportPrimaryMetrics || options.reportSecondaryMetrics) {
          StringBuffer metrics = StringBuffer();
          collectMetrics(metrics);
          logInfo('$metrics');
        }
        return success;
      });
    });
  }

  String _formatMs(int ms) {
    return (ms / 1000).toStringAsFixed(3) + 's';
  }

  void computeTimings(Duration setupDuration, StringBuffer timings) {
    timings.writeln("Timings:");
    Duration totalDuration = measurer.elapsedWallClock;
    Duration asyncDuration = measurer.elapsedAsyncWallClock;
    Duration cumulatedDuration = Duration.zero;
    List<_TimingData> timingData = [];
    for (final task in tasks) {
      String running = task.isRunning ? "*" : " ";
      Duration duration = task.duration;
      if (duration != Duration.zero) {
        cumulatedDuration += duration;
        int milliseconds = duration.inMilliseconds;
        timingData.add(_TimingData('   $running${task.name}:', milliseconds,
            milliseconds * 100 / totalDuration.inMilliseconds));
        for (String subtask in task.subtasks) {
          int subtime = task.getSubtaskTime(subtask);
          String running = task.getSubtaskIsRunning(subtask) ? "*" : " ";
          timingData.add(_TimingData('   $running${task.name} > $subtask:',
              subtime, subtime * 100 / totalDuration.inMilliseconds));
        }
      }
    }
    int longestDescription = timingData
        .map((d) => d.description.length)
        .fold(0, (a, b) => a < b ? b : a);
    for (var data in timingData) {
      var ms = _formatMs(data.milliseconds);
      var padding =
          " " * (longestDescription + 10 - data.description.length - ms.length);
      var percentPadding = data.percent < 10 ? " " : "";
      timings.writeln('${data.description}$padding $ms '
          '$percentPadding(${data.percent.toStringAsFixed(1)}%)');
    }
    Duration unaccountedDuration =
        totalDuration - cumulatedDuration - setupDuration - asyncDuration;
    double percent =
        unaccountedDuration.inMilliseconds * 100 / totalDuration.inMilliseconds;
    timings.write(
        '    Total compile-time ${_formatMs(totalDuration.inMilliseconds)};'
        ' setup ${_formatMs(setupDuration.inMilliseconds)};'
        ' async ${_formatMs(asyncDuration.inMilliseconds)};'
        ' unaccounted ${_formatMs(unaccountedDuration.inMilliseconds)}'
        ' (${percent.toStringAsFixed(2)}%)');
  }

  void collectMetrics(StringBuffer buffer) {
    buffer.writeln('Metrics:');
    for (final task in tasks) {
      Metrics metrics = task.metrics;
      String namespace = metrics.namespace;
      if (namespace == '') {
        namespace =
            task.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
      }
      void report(Metric metric) {
        buffer
            .writeln('  ${namespace}.${metric.name}: ${metric.formatValue()}');
      }

      for (final metric in metrics.primary) {
        report(metric);
      }
      if (options.reportSecondaryMetrics) {
        for (final metric in metrics.secondary) {
          report(metric);
        }
      }
    }
  }

  @override
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
}

class _Environment implements Environment {
  final Map<String, String> definitions;
  Map<String, String> _completeMap;
  Set<String> supportedLibraries;

  _Environment(this.definitions);

  @override
  String valueOf(String name) {
    if (_completeMap != null) return _completeMap[name];
    var result = definitions[name];
    if (result != null || definitions.containsKey(name)) return result;
    if (!name.startsWith(_dartLibraryEnvironmentPrefix)) return null;

    String libraryName = name.substring(_dartLibraryEnvironmentPrefix.length);

    // Private libraries are not exposed to the users.
    if (libraryName.startsWith("_")) return null;
    if (supportedLibraries.contains(libraryName)) return "true";
    return null;
  }

  @override
  Map<String, String> toMap() {
    if (_completeMap == null) {
      _completeMap = new Map<String, String>.from(definitions);
      for (String libraryName in supportedLibraries) {
        if (!libraryName.startsWith("_")) {
          String key = '${_dartLibraryEnvironmentPrefix}${libraryName}';
          if (!definitions.containsKey(key)) {
            _completeMap[key] = "true";
          }
        }
      }
    }
    return _completeMap;
  }
}

/// For every 'dart:' library, a corresponding environment variable is set
/// to "true". The environment variable's name is the concatenation of
/// this prefix and the name (without the 'dart:'.
///
/// For example 'dart:html' has the environment variable 'dart.library.html' set
/// to "true".
const String _dartLibraryEnvironmentPrefix = 'dart.library.';

class _TimingData {
  final String description;
  final int milliseconds;
  final double percent;

  _TimingData(this.description, this.milliseconds, this.percent);
}
