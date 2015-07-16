// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Feature test for harmony support, alert if not present.
(function () {
  try {
    var f = new Function(
      '"use strict";'+
      'class C {' +
        'constructor(x) { this.x = x; };' +
        '["foo"]() { return x => this.x + x; };' +
	'bar(args) { return this.foo()(...args); };' +
      '};' +
      'return new C(42).bar([100]);');
    if (f() == 142) return; // supported!
  } catch (e) {
  }

  var message = 'This script needs EcmaScript 6 features ' +
      'like `class` and `=>`. Please run in a browser with support, ' +
      'for example: chrome --js-flags="--harmony"';
  console.error(message);
  alert(message);

})();
