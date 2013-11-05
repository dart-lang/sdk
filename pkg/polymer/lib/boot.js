// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

(function() {
  console.error('"boot.js" is now deprecated. Instead, you can initialize '
    + 'your polymer application by adding the following tags: \'' +
    + '<script type="application/dart">export "package:polymer/init.dart";'
    + '</script><script src="packages/browser/dart.js"></script>\'. '
    + 'Make sure these script tags come after all HTML imports.');
})();
