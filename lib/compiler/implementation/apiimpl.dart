// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('leg_apiimpl');

#import('leg.dart', prefix: 'leg');
#import('elements/elements.dart', prefix: 'leg');
#import('tree/tree.dart', prefix: 'leg');
#import('ssa/tracer.dart', prefix: 'ssa');
// TODO(ahe): Remove dependency on frog.
#import('../../../frog/lang.dart', prefix: 'frog');
#import('../compiler.dart');
#import('../../uri/uri.dart');
#import('library_map.dart');


class Compiler extends leg.Compiler {
  ReadUriFromString provider;
  DiagnosticHandler handler;
  Uri libraryRoot;
  Uri packageRoot;
  List<String> options;
  bool mockableLibraryUsed = false;

  Compiler(this.provider, this.handler, this.libraryRoot, this.options)
    : super(tracer: new ssa.HTracer());

  leg.LibraryElement scanBuiltinLibrary(String path) {
    Uri uri = libraryRoot.resolve(DART2JS_LIBRARY_MAP[path]);
    leg.LibraryElement library = scanner.loadLibrary(uri, null);
    return library;
  }

  void log(message) {
    handler(null, null, null, message, false);
  }

  leg.Script readScript(Uri uri, [leg.ScriptTag node]) {
    if (uri.scheme == 'dart') {
      uri = translateDartUri(uri, node);
    } else if (uri.scheme == 'package') {
      uri = translatePackageUri(uri, node);
    }
    String text = "";
    try {
      // TODO(ahe): We expect the future to be complete and call value
      // directly. In effect, we don't support truly asynchronous API.
      text = provider(uri).value;
    } catch (var exception) {
      cancel("${uri}: $exception", node: node);
    }
    frog.SourceFile sourceFile = new frog.SourceFile(uri.toString(), text);
    return new leg.Script(uri, sourceFile);
  }

  translateDartUri(Uri uri, leg.ScriptTag node) {
    String path = DART2JS_LIBRARY_MAP[uri.path];
    if (path === null || uri.path.startsWith('_')) {
      reportError(node, 'library not found ${uri}');
      return null;
    }
    if (uri.path == 'dom' || uri.path == 'html' || uri.path == 'io') {
      // TODO(ahe): Get rid of mockableLibraryUsed when test.dart
      // supports this use case better.
      mockableLibraryUsed = true;
    }
    return libraryRoot.resolve(path);
  }

  translatePackageUri(Uri uri, leg.ScriptTag node) =>
    packageRoot.resolve(uri.path);

  bool run(Uri uri) {
    try {
      packageRoot = uri.resolve('packages/');
      bool success = super.run(uri);
      for (final task in tasks) {
        log('${task.name} took ${task.timing}msec');
      }
      return success;
    } finally {
      packageRoot = null;
    }
  }

  void reportDiagnostic(leg.SourceSpan span, String message, bool fatal) {
    if (span === null) {
      handler(null, null, null, message, fatal);
    } else {
      handler(span.uri, span.begin, span.end, message, fatal);
    }
  }

  bool get isMockCompilation() {
    return mockableLibraryUsed
      && (options.indexOf('--allow-mock-compilation') !== -1);
  }
}
