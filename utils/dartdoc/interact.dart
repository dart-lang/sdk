// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Provides client-side behavior for generated docs. */
#library('interact');

#import('dart:html');

main() {
  window.on.contentLoaded.add((e) {
    for (var elem in document.queryAll('.method, .field')) {
      var showCode = elem.query('.show-code');
      var pre = elem.query('pre.source');
      showCode.on.click.add((e) {
        if (pre.classes.contains('expanded')) {
          pre.classes.remove('expanded');
        } else {
          pre.classes.add('expanded');
        }
      });
    }
  });
}