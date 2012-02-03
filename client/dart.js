// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Bootstrap support for Dart scripts on the page as this script.

if (navigator.webkitStartDart) {
  navigator.webkitStartDart();
} else {
  window.addEventListener("DOMContentLoaded", function (e) {
      // Fall back to compiled JS.
      var scripts = document.getElementsByTagName("script");
      var length = scripts.length;
      for (var i = 0; i < length; ++i) {
        if (scripts[i].type == "application/dart") {
          // Remap foo.dart to foo.js.
          // TODO:
          // - Support in-browser compilation.
          // - Handle inline Dart scripts.
          if (scripts[i].src && scripts[i].src != '') {
            var script = document.createElement('script');
            script.src = scripts[i].src + '.js';
            var parent = scripts[i].parentNode;
            parent.replaceChild(script, scripts[i]);
          }
        }
      }
    }, false);
}
