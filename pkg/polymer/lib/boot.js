// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Bootstrap to initialize polymer applications. This library is will be
/// replaced by boot.dart in the near future (see dartbug.com/18007).
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
///   possible ways: using `init.dart` or invoking initPolymer in your main. Any
///   of these initialization patterns can be replaced to use an `@initMethod`
///   instead. For example, If you need to run some initialization code before
///   any other code is executed, include a "application/dart;component=1"
///   script tag that contains an initializer method with the body of your old
///   main, and make sure this tag is placed above other html-imports that load
///   the rest of the application. Initialization methods are executed in the
///   order in which they are discovered in the HTML document.
(function() {
  // Only run in Dartium.
  if (navigator.userAgent.indexOf('(Dart)') === -1) return;

  // Extract a Dart import URL from a script tag, which is the 'src' attribute
  // of the script tag, or a data-url with the script contents for inlined code.
  function getScriptUrl(script) {
    var url = script.src;
    if (url) {
      // Normalize package: urls
      var index = url.indexOf('packages/');
      if (index == 0 || (index > 0 && url[index - 1] == '/')) {
        url = "package:" + url.slice(index + 9);
      }
      return url;
    }

    // TODO(sigmund): change back to application/dart: using application/json is
    // wrong but it hides a warning in Dartium (dartbug.com/18000).
    return "data:application/json;base64," + window.btoa(script.textContent);
  }

  // Creates a Dart program that imports [urls] and passes them to
  // startPolymerInDevelopment, which in turn will invoke methods marked with
  // @initMethod, and register any custom tag labeled with @CustomTag in those
  // libraries.
  function createMain(urls, mainUrl) {
    var imports = Array(urls.length + 1);
    for (var i = 0; i < urls.length; ++i) {
      imports[i] = 'import "' + urls[i] + '" as i' + i + ';';
    }
    imports[urls.length] = 'import "package:polymer/src/mirror_loader.dart";';
    var arg = urls.length == 0 ? '[]' :
        ('[\n      "' + urls.join('",\n      "') + '"\n     ]');
    return (imports.join('\n') +
        '\n\nmain() {\n' +
        '  startPolymerInDevelopment(' + arg + ');\n' +
        '}\n');
  }

  function discoverScripts(content, state) {
    if (!state) {
      // internal state tracking documents we've visited, the resulting list of
      // scripts, and any tags with the incorrect mime-type.
      state = {seen: {}, scripts: [], badTags: []};
    }
    if (!content) return state;

    // Note: we visit both script and link-imports together to ensure we
    // preserve the order of the script tags as they are discovered.
    var nodes = content.querySelectorAll('script,link[rel="import"]');
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      if (node instanceof HTMLLinkElement) {
        // TODO(jmesserly): figure out why ".import" fails in content_shell but
        // works in Dartium.
        if (node.import && node.import.href) node = node.import;

        if (state.seen[node.href]) continue;
        state.seen[node.href] = node;
        discoverScripts(node.import, state);
      } else if (node instanceof HTMLScriptElement) {
        if (node.type == 'application/dart;component=1') {
          state.scripts.push(getScriptUrl(node));
        }
        if (node.type == 'application/dart') {
          state.badTags.push(node);
        }
      }
    }
    return state;
  }

  // TODO(jmesserly): we're using this function because DOMContentLoaded can
  // be fired too soon: https://www.w3.org/Bugs/Public/show_bug.cgi?id=23526
  HTMLImports.whenImportsReady(function() {
    // Append a new script tag that initializes everything.
    var newScript = document.createElement('script');
    newScript.type = "application/dart";

    var results = discoverScripts(document);
    if (results.badTags.length > 0) {
      console.warn('Dartium currently only allows a single Dart script tag '
        + 'per application, and in the future it will run them in '
        + 'separtate isolates.  To prepare for this all the following '
        + 'script tags need to be updated to use the mime-type '
        + '"application/dart;component=1" instead of "application/dart":');
      for (var i = 0; i < results.badTags.length; i++) {
        console.warn(results.badTags[i]);
      }
    }
    newScript.textContent = createMain(results.scripts);
    document.body.appendChild(newScript);
  });
})();
