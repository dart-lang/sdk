// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../tool/common/src_gen_common.dart';

void main() {
  // Each entity must be decoded exactly once: '&amp;lt;' is the HTML for the
  // text '&lt;', so it must not be decoded again to '<'.
  const testCases = {
    '&#39;': "'",
    '&quot;': '"',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&amp;#39;': '&#39;',
    '&amp;quot;': '&quot;',
    '&amp;amp;': '&amp;',
    '&amp;lt;': '&lt;',
    '&amp;gt;': '&gt;',
  };

  testCases.forEach((input, expected) {
    test('replaceHTMLEntities decodes $input', () {
      expect(replaceHTMLEntities(input), expected);
    });
  });
}
