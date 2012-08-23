// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('leg_apiimpl');

#import('dart:uri');

#import('../compiler.dart', prefix: 'api');
#import('leg.dart', prefix: 'leg');
#import('tree/tree.dart', prefix: 'tree');
#import('elements/elements.dart', prefix: 'elements');
#import('ssa/tracer.dart', prefix: 'ssa');
#import('library_map.dart');
#import('source_file.dart');

class Compiler extends leg.Compiler {
  api.ReadStringFromUri provider;
  api.DiagnosticHandler handler;
  final Uri libraryRoot;
  final Uri packageRoot;
  List<String> options;
  bool mockableLibraryUsed = false;

  Compiler(this.provider, this.handler, this.libraryRoot, this.packageRoot,
           List<String> options)
    : this.options = options,
      super(
          tracer: new ssa.HTracer(),
          enableTypeAssertions: options.indexOf('--enable-checked-mode') != -1,
          enableUserAssertions: options.indexOf('--enable-checked-mode') != -1,
          emitJavascript: options.indexOf('--output-type=dart') == -1);

  elements.LibraryElement scanBuiltinLibrary(String path) {
    Uri uri = libraryRoot.resolve(DART2JS_LIBRARY_MAP[path].libraryPath);
    Uri canonicalUri;
    if (path.startsWith("_")) {
      canonicalUri = uri;
    } else {
      canonicalUri = new Uri.fromComponents(scheme: "dart", path: path);
    }
    elements.LibraryElement library =
        scanner.loadLibrary(uri, null, canonicalUri);
    return library;
  }

  void log(message) {
    handler(null, null, null, message, api.Diagnostic.VERBOSE_INFO);
  }

  leg.Script readScript(Uri uri, [tree.Node node]) {
    if (uri.scheme == 'dart') uri = translateDartUri(uri, node);
    var translated = translateUri(uri, node);
    String text = "";
    try {
      // TODO(ahe): We expect the future to be complete and call value
      // directly. In effect, we don't support truly asynchronous API.
      text = provider(translated).value;
    } catch (var exception) {
      if (node !== null) {
        cancel("$exception", node: node);
      } else {
        reportDiagnostic(null, "$exception", api.Diagnostic.ERROR);
        throw new leg.CompilerCancelledException("$exception");
      }
    }
    SourceFile sourceFile = new SourceFile(uri.toString(), text);
    return new leg.Script(uri, sourceFile);
  }

  Uri translateUri(Uri uri, tree.Node node) {
    switch (uri.scheme) {
      case 'package': return translatePackageUri(uri, node);
      default: return uri;
    }
  }

  Uri translateDartUri(Uri uri, tree.Node node) {
    String path = DART2JS_LIBRARY_MAP[uri.path].libraryPath;
    if (path === null || uri.path.startsWith('_')) {
      reportError(node, 'library not found ${uri}');
      return null;
    }
    if (uri.path == 'dom_deprecated'
        || uri.path == 'html' || uri.path == 'io') {
      // TODO(ahe): Get rid of mockableLibraryUsed when test.dart
      // supports this use case better.
      mockableLibraryUsed = true;
    }
    return libraryRoot.resolve(path);
  }

  Uri resolvePatchUri(String dartLibraryPath) {
    String patchPath = DART2JS_LIBRARY_MAP[dartLibraryPath].patchPath;
    if (patchPath === null) return null;
    return libraryRoot.resolve(patchPath);
  }

  translatePackageUri(Uri uri, tree.Node node) => packageRoot.resolve(uri.path);

  bool run(Uri uri) {
    bool success = super.run(uri);
    for (final task in tasks) {
      log('${task.name} took ${task.timing}msec');
    }
    return success;
  }

  void reportDiagnostic(leg.SourceSpan span, String message,
                        api.Diagnostic kind) {
    if (kind === api.Diagnostic.ERROR || kind === api.Diagnostic.CRASH) {
      compilationFailed = true;
    }
    // [:span.uri:] might be [:null:] in case of a [Script] with no [uri]. For
    // instance in the [Types] constructor in typechecker.dart.
    if (span === null || span.uri === null) {
      handler(null, null, null, message, kind);
    } else {
      handler(translateUri(span.uri, null), span.begin, span.end,
              message, kind);
    }
  }

  bool get isMockCompilation {
    return mockableLibraryUsed
      && (options.indexOf('--allow-mock-compilation') !== -1);
  }
}
