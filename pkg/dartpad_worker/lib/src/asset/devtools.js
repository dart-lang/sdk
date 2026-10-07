// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

(function () {
  // Rewrite the URL from `.../devtools.html` to `.../devtools/` to match
  // `<base href="devtools/">`, as required by Flutter Web's path URL strategy.
  const currentUrl = new URL('./' + window.location.search, document.baseURI);
  currentUrl.searchParams.set('uri', 'messageport:*');
  if (!currentUrl.searchParams.has('embedMode')) {
    currentUrl.searchParams.set('embedMode', 'many');
  }
  if (!currentUrl.searchParams.has('hide')) {
    currentUrl.searchParams.set('hide', 'home');
  }
  if (!currentUrl.searchParams.has('compiler')) {
    currentUrl.searchParams.set('compiler', 'wasm');
  }
  window.history.replaceState({}, '', currentUrl.toString());
})();
