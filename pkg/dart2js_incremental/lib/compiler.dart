// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'dart:async' show
    EventSink,
    Future,
    Stream,
    StreamController,
    StreamSubscription;

import 'package:dart2js_incremental/dart2js_incremental.dart' show
    IncrementalCompilationFailed,
    IncrementalCompiler;

import 'package:compiler/src/source_file_provider.dart' show
    FormattingDiagnosticHandler;

import 'watcher.dart';

main(List<String> arguments) {
  int updateCount = 0;
  StreamSubscription<CompilerEvent> subscription =
      compile(Uri.base.resolve(arguments.first)).listen(null);
  subscription.onData((CompilerEvent event) {
    switch (event.kind) {
      case IncrementalKind.FULL:
        updateCount = 0;
        print('// Compiled JavaScript:');
        print(event['.js']);
        break;

      case IncrementalKind.INCREMENTAL:
        Stopwatch sw = event.stopwatch..start();
        String updates = '${event.compiler.allUpdates()}';
        sw.stop();

        print('// Patch after ${++updateCount} updates,');
        print('// computed in ${sw.elapsedMicroseconds/1000000} seconds:');
        print(updates);
        break;

      case IncrementalKind.ERROR:
        updateCount = 0;
        print("Compilation failed");
        break;

      default:
        throw "Unknown kind: ${event.kind}";
    }
  });
  subscription.onError((error, StackTrace trace) {
    if (error is IncrementalCompilationFailed) {
      print("Incremental compilation failed due to:\n${error.reason}");
    } else {
      throw error;
    }
  });
}

Stream<CompilerEvent> compile(Uri originalInput) {
  StreamController<CompilerEvent> controller =
      new StreamController<CompilerEvent>();
  compileToStream(originalInput, controller);
  return controller.stream;
}

compileToStream(
    Uri originalInput,
    StreamController<CompilerEvent> controller) async {
  var watcher = new Watcher();

  Uri libraryRoot = Uri.base.resolve('sdk/');
  Uri packageRoot = Uri.base.resolve('packages/');

  FormattingDiagnosticHandler diagnosticHandler =
      new FormattingDiagnosticHandler();

  OutputProvider outputProvider = new OutputProvider();

  void resilientDiagnosticHandler(
      Uri uri, int begin, int end, String message, kind) {
    try {
      diagnosticHandler(uri, begin, end, message, kind);
    } catch (e) {
      String name = diagnosticHandler.provider.relativizeUri(uri);
      print('$name@$begin+${end - begin}: [$kind] $message}');
    }
  }

  Future inputProvider(Uri uri) {
    if (uri.scheme == "file") {
      if (!'$uri'.startsWith('$libraryRoot')) {
        watcher.watchFile(uri);
      }
    }
    return diagnosticHandler.provider(uri);
  }

  while (true) {
    Stopwatch sw = new Stopwatch()..start();
    IncrementalCompiler compiler = new IncrementalCompiler(
        libraryRoot: libraryRoot,
        packageRoot: packageRoot,
        inputProvider: inputProvider,
        diagnosticHandler: resilientDiagnosticHandler,
        outputProvider: outputProvider);

    bool success = await compiler.compile(originalInput);
    sw.stop();
    if (success) {
      controller.add(
          new CompilerEvent(
              IncrementalKind.FULL, compiler, outputProvider.output, sw));
    } else {
      controller.add(
          new CompilerEvent(
              IncrementalKind.ERROR, compiler, outputProvider.output, sw));
    }

    while (await watcher.hasChanges()) {
      try {
        Map<Uri, Uri> changes = watcher.readChanges();

        sw = new Stopwatch()..start();
        String updates = await compiler.compileUpdates(changes);
        sw.stop();

        controller.add(
            new CompilerEvent(
                IncrementalKind.INCREMENTAL, compiler, outputProvider.output,
                sw, updates: updates));

      } on IncrementalCompilationFailed catch (error, trace) {
        controller.addError(error, trace);
        break;
      }
    }
  }
}

/// Output provider which collects output in [output].
class OutputProvider {
  final Map<String, String> output = new Map<String, String>();

  EventSink<String> call(String name, String extension) {
    return new StringEventSink((String data) {
      output['$name.$extension'] = data;
    });
  }

  String operator[](String key) => output[key];
}

/// Helper class to collect sources.
class StringEventSink implements EventSink<String> {
  List<String> data = <String>[];

  final Function onClose;

  StringEventSink(this.onClose);

  void add(String event) {
    if (data == null) throw 'StringEventSink is closed.';
    data.add(event);
  }

  void addError(errorEvent, [StackTrace stackTrace]) {
    throw 'addError($errorEvent, $stackTrace)';
  }

  void close() {
    if (data != null) {
      onClose(data.join());
      data = null;
    }
  }
}

enum IncrementalKind {
  FULL,
  INCREMENTAL,
  ERROR,
}

class CompilerEvent {
  final IncrementalKind kind;

  final IncrementalCompiler compiler;

  final Map<String, String> _output;

  final Stopwatch stopwatch;

  final String updates;

  CompilerEvent(
      this.kind, this.compiler, this._output, this.stopwatch, {this.updates});

  String operator[](String key) => _output[key];
}
