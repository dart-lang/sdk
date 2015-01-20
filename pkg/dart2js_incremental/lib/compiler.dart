// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'dart:async' show
    StreamSubscription,
    EventSink,
    Future;

import 'package:dart2js_incremental/dart2js_incremental.dart' show
    IncrementalCompilationFailed,
    IncrementalCompiler;

import 'package:compiler/src/source_file_provider.dart' show
    FormattingDiagnosticHandler;

import 'watcher.dart';

main(List<String> arguments) async {
  Uri originalInput = Uri.base.resolve(arguments.first);
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
      watcher.watchFile(uri);
    }
    return diagnosticHandler.provider(uri);
  }

  while (true) {
    IncrementalCompiler compiler = new IncrementalCompiler(
        libraryRoot: libraryRoot,
        packageRoot: packageRoot,
        inputProvider: inputProvider,
        diagnosticHandler: resilientDiagnosticHandler,
        outputProvider: outputProvider);

    if (!await compiler.compile(originalInput)) {
      print("Compilation failed");
    } else {
      print('// Compiled JavaScript:');
      print(outputProvider['.js']);
    }

    int updateCount = 0;
    while (await watcher.hasChanges()) {
      try {
        Map<Uri, Uri> changes = watcher.readChanges();

        Stopwatch sw = new Stopwatch()..start();
        await compiler.compileUpdates(changes);

        String updates = '${compiler.allUpdates()}';

        sw.stop();
        print('// Patch after ${++updateCount} updates,');
        print('// computed in ${sw.elapsedMicroseconds/1000000} seconds:');
        print(updates);
      } on IncrementalCompilationFailed catch (error) {
        print("Incremental compilation failed due to:\n${error.reason}");
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
