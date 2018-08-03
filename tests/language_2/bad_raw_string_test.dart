// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  // Raw String may not contain newline (may not be multi-line).
  String x = ''
    r' // //# 01: syntax error
' //      //# 01: continued
    r" // //# 02: syntax error
" //      //# 02: continued
      // Test that a raw string containing just one character, a \n char, fails.
      // Enclose the test string in a bigger multiline string, except in case 03:
    ''' // //# 03: syntax error
      """
    ''' // //# 03: continued
    r'
'
    ''' // //# 03: continued
    """
    ''' // //# 03: continued
      ;
}
