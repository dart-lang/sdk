// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('dom_tests');

#import('../../../testing/unittest/unittest.dart');
#import('dart:dom');

#import('IsolateLight.dart', prefix: 'IsolateLight');

main() {
  group('IsolateLight', IsolateLight.main);
}
