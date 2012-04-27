// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that newlines cannot be escaped in import tags.

#library('StringEscape3NegativeTest');
#import('string_escape3_negative_test_helper.dart', prefix: 'foo\
');

main() {
}
