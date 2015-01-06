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
    IncrementalCompiler, OutputProvider;

import 'package:compiler/compiler.dart' show
    Diagnostic;

const String WEB_SCHEME = 'org.trydart.web';

/// A CompilerTestCase which runs in a browser.
class WebCompilerTestCase extends CompilerTestCase {
  final IncrementalCompiler incrementalCompiler;

  WebCompilerTestCase.init(/* Map or String */ source, Uri uri)
      : this.incrementalCompiler = makeCompiler(source, uri),
        super.init(null, uri, null);

  WebCompilerTestCase(/* Map or String */ source, [String path])
      : this.init(source, customUri(path == null ? 'main.dart' : path));

  Future run() {
    return incrementalCompiler.compile(scriptUri).then((success) {
      if (!success) throw 'Compilation failed';
      OutputProvider outputProvider = incrementalCompiler.outputProvider;
      return outputProvider['.js'];
    });
  }

  static IncrementalCompiler makeCompiler(
      /* Map or String */ source,
      Uri mainUri) {
    Uri libraryRoot = new Uri(scheme: WEB_SCHEME, path: '/sdk/');
    Uri packageRoot = new Uri(scheme: WEB_SCHEME, path: '/packages/');

    Map<Uri, String> sources = <Uri, String>{};
    if (source is String) {
      sources[mainUri] = source;
    } else if (source is Map) {
      source.forEach((String name, String code) {
        sources[mainUri.resolve(name)] = code;
      });
    } else {
      throw new ArgumentError("[source] should be a String or a Map");
    }

    WebInputProvider inputProvider =
        new WebInputProvider(sources, libraryRoot, packageRoot);

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
  final Map<Uri, String> sources;

  final Uri libraryRoot;

  final Uri packageRoot;

  final Map<Uri, Future> cachedSources = new Map<Uri, Future>();

  static final Map<String, Future> cachedRequests = new Map<String, Future>();

  WebInputProvider(this.sources, this.libraryRoot, this.packageRoot);

  Future call(Uri uri) {
    return cachedSources.putIfAbsent(uri, () {
      if (sources.containsKey(uri)) return new Future.value(sources[uri]);
      if (uri.scheme == WEB_SCHEME) {
        return cachedHttpRequest('/root_dart${uri.path}');
      } else {
        return cachedHttpRequest('$uri');
      }
    });
  }

  static Future cachedHttpRequest(String uri) {
    return cachedRequests.putIfAbsent(uri, () => HttpRequest.getString(uri));
  }
}
