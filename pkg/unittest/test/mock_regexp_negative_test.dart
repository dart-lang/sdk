// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock_regexp_negative_test;
import '../../../pkg/unittest/lib/unittest.dart';
import '../../../pkg/unittest/lib/mock.dart';

main() {
  test('Mocking: RegExp CallMatcher bad', () {
    var m = new Mock();           
    m.when(callsTo(matches('^[A-Z]'))).          
           alwaysThrow('Method names must start with lower case.');      
    m.Test();         
  });
}
