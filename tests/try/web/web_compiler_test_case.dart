// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Helpers for writing compiler tests running in browser.
library trydart.web_compiler_test_case;

import 'dart:async' show
    EventSink,
    Future;

import 'dart:html' show
    HttpRequest;

import '../poi/compiler_test_case.dart' show
    customUri,
    CompilerTestCase;

import 'package:dart2js_incremental/dart2js_incremental.dart' show
    IncrementalCompiler;

import 'package:compiler/compiler.dart' show
    Diagnostic;

const String WEB_SCHEME = 'org.trydart.web';

/// A CompilerTestCase which runs in a browser.
class WebCompilerTestCase extends CompilerTestCase {
  final IncrementalCompiler incrementalCompiler;

  WebCompilerTestCase.init(String source, Uri uri)
      : this.incrementalCompiler = makeCompiler(source, uri),
        super.init(source, uri, null);

  WebCompilerTestCase(String source, [String path])
      : this.init(source, customUri(path == null ? 'main.dart' : path));

  Future run() {
    return incrementalCompiler.compile(scriptUri).then((success) {
      if (!success) throw 'Compilation failed';
      OutputProvider outputProvider = incrementalCompiler.outputProvider;
      return outputProvider['.js'];
    });
  }

  static IncrementalCompiler makeCompiler(String source, Uri mainUri) {
    Uri libraryRoot = new Uri(scheme: WEB_SCHEME, path: '/sdk/');
    Uri packageRoot = new Uri(scheme: WEB_SCHEME, path: '/packages/');
    WebInputProvider inputProvider =
        new WebInputProvider(source, mainUri, libraryRoot, packageRoot);

    void diagnosticHandler(
        Uri uri, int begin, int end, String message, Diagnostic kind) {
      if (uri == null) {
        print('[$kind] $message');
      } else {
        print('$uri@$begin+${end - begin}: [$kind] $message');
      }
    }

    return new IncrementalCompiler(
        libraryRoot: libraryRoot,
        packageRoot: packageRoot,
        inputProvider: inputProvider,
        diagnosticHandler: diagnosticHandler,
        outputProvider: new OutputProvider());
  }
}

/// An input provider which provides input via [HttpRequest].
/// Includes one in-memory compilation unit [source] which is returned when
/// [mainUri] is requested.
class WebInputProvider {
  final String source;

  final Uri mainUri;

  final Uri libraryRoot;

  final Uri packageRoot;

  final Map<Uri, Future> cachedSources = new Map<Uri, Future>();

  WebInputProvider(
      this.source, this.mainUri, this.libraryRoot, this.packageRoot);

  Future call(Uri uri) {
    return cachedSources.putIfAbsent(uri, () {
      if (uri == mainUri) return new Future.value(source);
      if (uri.scheme == WEB_SCHEME) {
        return HttpRequest.getString('/root_dart${uri.path}');
      } else {
        return HttpRequest.getString('$uri');
      }
    });
  }
}

/// Output provider which collect output in [output].
class OutputProvider {
  final Map<String, String> output = new Map<String, String>();

  EventSink<String> call(String name, String extension) {
    return new StringEventSink((String data) {
      output['$name.$extension'] = data;
    });
  }

  String operator[] (String key) => output[key];
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
