// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Bootstrap to initialize polymer applications. This library is not in use
/// yet but it will replace boot.js in the near future (see dartbug.com/18007).
///
/// This script contains logic to bootstrap polymer apps during development. It
/// internally discovers special Dart script tags through HTML imports, and
/// constructs a new entrypoint for the application that is then launched in an
/// isolate.
///
/// For each script tag found, we will load the corresponding Dart library and
/// execute all methods annotated with `@initMethod` and register all classes
/// labeled with `@CustomTag`. We keep track of the order of imports and execute
/// initializers in the same order.
///
/// All polymer applications use this bootstrap logic. It is included
/// automatically when you include the polymer.html import:
///
///    <link rel="import" href="packages/polymer/polymer.html">
///
/// There are two important changes compared to previous versions of polymer
/// (0.10.0-pre.6 and older):
///
///   * Use 'application/dart;component=1' instead of 'application/dart':
///   Dartium already limits to have a single script tag per document, but it
///   will be changing semantics soon and make them even stricter. Multiple
///   script tags are not going to be running on the same isolate after this
///   change. For polymer applications we'll use a parameter on the script tags
///   mime-type to prevent Dartium from loading them separately. Instead this
///   bootstrap script combines those special script tags and creates the
///   application Dartium needs to run.
///
//    If you had:
///
///      <polymer-element name="x-foo"> ...
///      <script type="application/dart" src="x_foo.dart'></script>
///
///   Now you need to write:
///
///      <polymer-element name="x-foo"> ...
///      <script type="application/dart;component=1" src="x_foo.dart'></script>
///
///   * `initPolymer` is gone: we used to initialize applications in two
///   possible ways: using init.dart or invoking initPolymer in your main. Any
///   of these initialization patterns can be replaced to use an `@initMethod`
///   instead. For example, If you need to run some initialization code before
///   any other code is executed, include a "application/dart;component=1"
///   script tag that contains an initializer method with the body of your old
///   main, and make sure this tag is placed above other html-imports that load
///   the rest of the application. Initialization methods are executed in the
///   order in which they are discovered in the HTML document.
library polymer.src.boot;

import 'dart:html';
import 'dart:mirrors';

main() {
  var scripts = _discoverScripts(document, window.location.href);
  var sb = new StringBuffer()..write('library bootstrap;\n\n');
  int count = 0;
  for (var s in scripts) {
    sb.writeln("import '$s' as prefix_$count;");
    count++;
  }
  sb.writeln("import 'package:polymer/src/mirror_loader.dart';");
  sb.write('\nmain() => startPolymerInDevelopment([\n');
  for (var s in scripts) {
    sb.writeln("  '$s',");
  }
  sb.write(']);\n');
  var isolateUri = _asDataUri(sb.toString());
  spawnDomUri(Uri.parse(isolateUri), [], '');
}

/// Internal state used in [_discoverScripts].
class _State {
  /// Documents that we have visited thus far.
  final Set<Document> seen = new Set();

  /// Scripts that have been discovered, in tree order.
  final List<String> scripts = [];

  /// Whether we've seen a type="application/dart" script tag, since we expect
  /// to have only one of those.
  bool scriptSeen = false;
}

/// Walks the HTML import structure to discover all script tags that are
/// implicitly loaded. This code is only used in Dartium and should only be
/// called after all HTML imports are resolved. Polymer ensures this by asking
/// users to put their Dart script tags after all HTML imports (this is checked
/// by the linter, and Dartium will otherwise show an error message).
List<String> _discoverScripts(Document doc, String baseUri, [_State state]) {
  if (state == null) state = new _State();
  if (doc == null) {
    print('warning: $baseUri not found.');
    return state.scripts;
  }
  if (!state.seen.add(doc)) return state.scripts;

  for (var node in doc.querySelectorAll('script,link[rel="import"]')) {
    if (node is LinkElement) {
      _discoverScripts(node.import, node.href, state);
    } else if (node is ScriptElement) {
      if (node.type == 'application/dart;component=1') {
        if (node.src != '' ||
            node.text != "export 'package:polymer/boot.dart';") {
          state.scripts.add(_getScriptUrl(node));
        }
      }

      if (node.type == 'application/dart') {
        if (state.scriptSeen) {
          print('Dartium currently only allows a single Dart script tag '
              'per application, and in the future it will run them in '
              'separtate isolates.  To prepare for this Dart script '
              'tags need to be updated to use the mime-type '
              '"application/dart;component=1" instead of "application/dart":');
        }
        state.scriptSeen = true;
      }
    }
  }
  return state.scripts;
}

// TODO(sigmund): explore other (cheaper) ways to resolve URIs relative to the
// root library (see dartbug.com/12612)
final _rootUri = currentMirrorSystem().isolate.rootLibrary.uri;

/// Returns a URI that can be used to load the contents of [script] in a Dart
/// import. This is either the source URI if [script] has a `src` attribute, or
/// a base64 encoded `data:` URI if the [script] contents are inlined.
String _getScriptUrl(script) {
  var uriString = script.src;
  if (uriString != '') {
    var uri = _rootUri.resolve(uriString);
    if (!_isHttpStylePackageUrl(uri)) return '$uri';
    // Use package: urls if available. This rule here is more permissive than
    // how we translate urls in polymer-build, but we expect Dartium to limit
    // the cases where there are differences. The polymer-build issues an error
    // when using packages/ inside lib without properly stepping out all the way
    // to the packages folder. If users don't create symlinks in the source
    // tree, then Dartium will also complain because it won't find the file seen
    // in an HTML import.
    var packagePath = uri.path.substring(
        uri.path.lastIndexOf('packages/') + 'packages/'.length);
    return 'package:$packagePath';
  }

  return _asDataUri(script.text);
}

/// Whether [uri] is an http URI that contains a 'packages' segment, and
/// therefore could be converted into a 'package:' URI.
bool _isHttpStylePackageUrl(Uri uri) {
  var uriPath = uri.path;
  return uri.scheme == _rootUri.scheme &&
      // Don't process cross-domain uris.
      uri.authority == _rootUri.authority &&
      uriPath.endsWith('.dart') &&
      (uriPath.contains('/packages/') || uriPath.startsWith('packages/'));
}

/// Returns a base64 `data:` uri with the contents of [s].
// TODO(sigmund): change back to application/dart: using text/javascript seems
// wrong but it hides a warning in Dartium (dartbug.com/18000).
_asDataUri(s) => 'data:text/javascript;base64,${window.btoa(s)}';
