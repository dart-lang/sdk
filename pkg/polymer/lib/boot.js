// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This script dynamically prepares a set of files to run polymer.dart. It uses
// the html_import polyfill to search for all imported files, then
// it inlines all <polymer-element> definitions on the top-level page (needed by
// registerPolymerElement), and it removes script tags that appear inside
// those tags. It finally rewrites the main entrypoint to call an initialization
// function on each of the declared <polymer-elements>.
//
// This script is needed only when running polymer.dart in Dartium. It should be
// removed by the polymer deployment commands.

// As an example, given an input of this form:
//   <polymer-element name="c1">
//      <template></template>
//      <script type="application/dart" src="url0.dart"></script>
//   </polymer-element>
//   <element name="c2">
//      <template></template>
//      <script type="application/dart">main() => { print('body2'); }</script>
//   </element>
//   <c1></c1>
//   <c2></c2>
//   <script type="application/dart" src="url2.dart"></script>
//   <script src="packages/polymer/boot.js"></script>
//
// This script will simplifies the page as follows:
//   <polymer-element name="c1">
//      <template></template>
//   </polymer-element>
//   <polymer-element name="c2">
//      <template></template>
//   </polymer-element>
//   <c1></c1>
//   <c2></c2>
//   <script type="application/dart">
//     import 'url0.dart' as i0;
//     import "data:application/dart;base64,CiAgICBtYWluKCkgewogICAgICBwcmludCgnYm9keTInKTsKICAgIH0KICAgIA==" as i1;
//     import 'url2.dart' as i2;
//     ...
//     main() {
//       // code that checks which libraries have a 'main' and invokes them.
//       // practically equivalent to: i0._init(); i1._init(); i2.main();
//     }
//   </script>


(function() {
  // Only run in Dartium.
  if (!navigator.webkitStartDart) {
    // TODO(sigmund): rephrase when we split build.dart in two: analysis vs
    // deploy pieces.
    console.warn('boot.js only works in Dartium. Run the build.dart' +
      ' tool to compile a depolyable JavaScript version')
    return;
  }


  // Load HTML Imports:
  var htmlImportsSrc = 'src="packages/html_import/html_import.min.js"';
  document.write('<script ' + htmlImportsSrc + '></script>');
  var importScript = document.querySelector('script[' + htmlImportsSrc + ']');
  importScript.addEventListener('load', function() {
    // NOTE: this is from polymer/src/lib/dom.js
    window.HTMLImports.importer.preloadSelectors +=
        ', polymer-element link[rel=stylesheet]';
  });

  // TODO(jmesserly): we need this in deploy tool too.
  // NOTE: this is from polymer/src/boot.js:
  // FOUC prevention tactic
  var style = document.createElement('style');
  style.textContent = 'body {opacity: 0;}';
  var head = document.querySelector('head');
  head.insertBefore(style, head.firstChild);

  window.addEventListener('WebComponentsReady', function() {
    document.body.style.webkitTransition = 'opacity 0.3s';
    document.body.style.opacity = 1;
  });

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
    } else {
      // TODO(sigmund): investigate how to eliminate the warning in Dartium
      // (changing to text/javascript hides the warning, but seems wrong).
      return "data:application/dart;base64," + window.btoa(script.textContent);
    }
  }

  // Moves <polymer-elements> from imported documents into the top-level page.
  function inlinePolymerElements(content, ref, seen) {
    if (!seen) seen = {};
    var links = content.querySelectorAll('link[rel="import"]');
    for (var i = 0; i < links.length; i++) {
      var link = links[i];
      // TODO(jmesserly): figure out why ".import" fails in content_shell but
      // works in Dartium.
      if (link.import && link.import.href) link = link.import;

      if (seen[link.href]) continue;
      seen[link.href] = link;
      inlinePolymerElements(link.content, ref, seen);
    }

    if (content != document) { // no need to do anything for the top-level page
      var elements = content.querySelectorAll('polymer-element');
      for (var i = 0; i < elements.length; i++)  {
        document.body.insertBefore(elements[i], ref);
      }
    }
  }

  // Creates a Dart program that imports [urls] and passes them to initPolymer
  // (which in turn will invoke their main function, their methods marked with
  // @initMethod, and register any custom tag labeled with @CustomTag).
  function createMain(urls, mainUrl) {
    var imports = Array(urls.length + 1);
    for (var i = 0; i < urls.length; ++i) {
      imports[i] = 'import "' + urls[i] + '" as i' + i + ';';
    }
    imports[urls.length] = 'import "package:polymer/polymer.dart" as polymer;';
    var arg = urls.length == 0 ? '[]' :
        ('[\n      "' + urls.join('",\n      "') + '"\n     ]');
    return (imports.join('\n') +
        '\n\nmain() {\n' +
        '  polymer.initPolymer(' + arg + ');\n' +
        '}\n');
  }

  // Finds all top-level <script> tags, and <script> tags in custom elements
  // and merges them into a single entrypoint.
  function mergeScripts() {
    var scripts = document.getElementsByTagName("script");
    var length = scripts.length;

    var urls = [];
    var toRemove = [];

    // Collect the information we need to replace the script tags
    for (var i = 0; i < length; ++i) {
      var script = scripts[i];
      if (script.type == "application/dart") {
        urls.push(getScriptUrl(script));
        toRemove.push(script);
      }
    }

    toRemove.forEach(function (s) { s.parentNode.removeChild(s); });

    // Append a new script tag that initializes everything.
    var newScript = document.createElement('script');
    newScript.type = "application/dart";
    newScript.textContent = createMain(urls);
    document.body.appendChild(newScript);
  }

  var alreadyRan = false;
  window.addEventListener('HTMLImportsLoaded', function (e) {
    if (alreadyRan) {
      console.warn('HTMLImportsLoaded fired again.');
      return;
    }
    alreadyRan = true;
    var ref = document.body.children[0];
    inlinePolymerElements(document, ref);
    mergeScripts();
    if (!navigator.webkitStartDart()) {
      document.body.innerHTML = 'This build has expired. Please download a ' +
          'new Dartium at http://www.dartlang.org/dartium/index.html';
    }
  });
})();
