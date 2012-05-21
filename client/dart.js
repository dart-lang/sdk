// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Bootstrap support for Dart scripts on the page as this script.
if (navigator.webkitStartDart) {
  if (!navigator.webkitStartDart()) {
    document.body.innerHTML = 'This build has expired.  Please download a new Dartium at http://www.dartlang.org/dartium/index.html';
  }
} else {
  // TODO:
  // - Support in-browser compilation.
  // - Handle inline Dart scripts.
  window.addEventListener("DOMContentLoaded", function (e) {
    // Fall back to compiled JS. Run through all the scripts and
    // replace them if they have a type that indicate that they source
    // in Dart code.
    //
    //   <script type="application/dart" src="<file>.dart"></script>
    //
    // If the script tag has a 'data-compiler' attribute set to
    // dart2js then we use the dart2js generated file rather than the
    // one produced by frog:
    //
    //    <script ... data-compiler="dart2js"></script>
    //
    var scripts = document.getElementsByTagName("script");
    var length = scripts.length;
    for (var i = 0; i < length; ++i) {
      if (scripts[i].type == "application/dart") {
        // Remap foo.dart to foo.js or foo.js_ depending
        // on the chosen compiler (frog or dart2js).
        if (scripts[i].src && scripts[i].src != '') {
          var script = document.createElement('script');
          var compiler = scripts[i].getAttribute('data-compiler');
          if (compiler == "dart2js") {
            script.src = scripts[i].src + '.js_';
          } else {
            script.src = scripts[i].src + '.js';
          }
          var parent = scripts[i].parentNode;
          parent.replaceChild(script, scripts[i]);
        }
      }
    }
  }, false);
}
