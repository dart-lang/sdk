// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Experimental bootstrap to initialize polymer applications. This library is
/// not used by default, and may be replaced by Dart code in the near future.
///
/// This script contains logic to bootstrap polymer apps during development. It
/// internally discovers Dart script tags through HTML imports, and constructs
/// a new entrypoint for the application that is then launched in an isolate.
///
/// For each script tag found, we will load the corresponding Dart library and
/// execute all methods annotated with `@initMethod` and register all classes
/// labeled with `@CustomTag`. We keep track of the order of imports and execute
/// initializers in the same order.
///
/// You can this experimental bootstrap logic by including the
/// polymer_experimental.html import, instead of polymer.html:
///
///    <link rel="import" href="packages/polymer/polymer_experimental.html">
///
/// This bootstrap replaces `initPolymer` so Dart code might need to be changed
/// too. If you loaded init.dart directly, you can remove it. But if you invoke
/// initPolymer in your main, you should remove that call and change to use
/// `@initMethod` instead. The current bootstrap doesn't support having Dart
/// script tags in the main page, so you may need to move some code into an HTML
/// import. For example, If you need to run some initialization code before any
/// other code is executed, include an HTML import to an html file with a
/// "application/dart" script tag that contains an initializer
/// method with the body of your old main, and make sure this tag is placed
/// above other html-imports that load the rest of the application.
/// Initialization methods are executed in the order in which they are
/// discovered in the HTML document.
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

  function discoverScripts(content, state, importedDoc) {
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
        discoverScripts(node.import, state, true);
      } else if (node instanceof HTMLScriptElement) {
        if (node.type != 'application/dart') continue;
        if (importedDoc) {
          state.scripts.push(getScriptUrl(node));
        } else {
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
      console.warn('The experimental polymer boostrap does not support '
        + 'having script tags in the main document. You can move the script '
        + 'tag to an HTML import instead. Also make sure your script tag '
        + 'doesn\'t have a main, but a top-level method marked with '
        + '@initMethod instead');
      for (var i = 0; i < results.badTags.length; i++) {
        console.warn(results.badTags[i]);
      }
    }
    newScript.textContent = createMain(results.scripts);
    document.body.appendChild(newScript);
  });
})();
