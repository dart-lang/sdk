// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Code shared between the different client-side libraries.

/**
 * Finds all code blocks and makes them toggleable. Syntax highlights each
 * code block the first time it's shown.
 */
enableCodeBlocks() {
  for (var elem in document.queryAll('.method, .field')) {
    var showCode = elem.query('.show-code');

    // Skip it if we don't have a code link. Will happen if source code is
    // disabled.
    if (showCode == null) continue;

    var pre = elem.query('pre.source');

    showCode.on.click.add((e) {
      if (pre.classes.contains('expanded')) {
        pre.classes.remove('expanded');
      } else {
        // Syntax highlight.
        if (!pre.classes.contains('formatted')) {
          pre.innerHTML = classifySource(pre.text);
          pre.classes.add('formatted');
        };
        pre.classes.add('expanded');
      }
    });

  }
}
