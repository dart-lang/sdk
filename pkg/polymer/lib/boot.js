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
  document.write(
    '<script src="packages/html_import/html_import.min.js"></script>');

  // Whether [node] is under `<body>` or `<head>` and not nested in an
  // `<element>` or `<polymer-element>` tag.
  function isTopLevel(node) {
    var parent = node.parentNode;
    if (parent == null || parent == document.body || parent == document.head) {
      return true;
    }
    if (parent.localName && (
        parent.localName == 'element' ||
        parent.localName == 'polymer-element')) {
      return false;
    }
    return isTopLevel(parent);
  }

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

      // TODO(sigmund): remove the timestamp. We added this to work around
      // a caching bug in dartium (see http://dartbug.com/12074). Note this
      // doesn't fix caching problems with other libraries imported further in,
      // and it can also introduce canonicalization problems if the files under
      // these urls are being imported from other libraries.
      var time = new Date().getTime();
      return url + '?' + time;
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
      var link = links[i].import;
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

  // Creates a Dart program that imports [urls] and [mainUrl] and invokes the
  // _init methods of each library in urls (if present) followed by the main
  // method of [mainUrl].
  function createMain(urls, mainUrl) {
    var imports = Array(urls.length + 2);
    for (var i = 0; i < urls.length; ++i) {
      imports[i] = 'import "' + urls[i] + '" as i' + i + ';';
    }
    imports[urls.length] = 'import "package:polymer/polymer.dart" as polymer;';
    imports[urls.length + 1 ] = 'import "' + mainUrl + '" as userMain;';
    var firstArg = urls.length == 0 ? '[]' :
        ('[\n      "' + urls.join('",\n      "') + '"\n     ]');
    return (imports.join('\n') +
        '\n\nmain() {\n' +
        '  polymer.initPolymer(' + firstArg + ', userMain.main);\n' +
        '}\n');
  }

  // Finds all top-level <script> tags, and <script> tags in custom elements
  // and merges them into a single entrypoint.
  function mergeScripts() {
    var scripts = document.getElementsByTagName("script");
    var length = scripts.length;

    var dartScripts = []
    var urls = [];

    // Collect the information we need to replace the script tags
    for (var i = 0; i < length; ++i) {
      var script = scripts[i];
      if (script.type == "application/dart") {
        dartScripts.push(script);
        if (isTopLevel(script)) continue;
        urls.push(getScriptUrl(script));
      }
    }

    // Removes all the original script tags under elements, and replace
    // top-level script tags so we first call each element's _init.
    for (var i = 0; i < dartScripts.length; ++i) {
      var script = dartScripts[i];
      if (isTopLevel(script)) {
        var newScript = document.createElement('script');
        newScript.type = "application/dart";
        newScript.textContent = createMain(urls, getScriptUrl(script));
        script.parentNode.replaceChild(newScript, script);
      } else {
        script.parentNode.removeChild(script);
      }
    }
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
