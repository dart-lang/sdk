// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('observable_tests');

#import('dart:html');
#import('../../../observable/observable.dart');
#import('../../../testing/unittest/unittest.dart');

#source('AbstractObservableTests.dart');
#source('ChangeEventTests.dart');
#source('EventBatchTests.dart');
#source('ObservableListTests.dart');
#source('ObservableTestSetBase.dart');
#source('ObservableValueTests.dart');

void main() {
  var tests = new UnitTestSuite();

  tests.addTestSets([
    new AbstractObservableTests(),
    new ChangeEventTests(),
    new EventBatchTests(),
    new ObservableListTests(),
    new ObservableValueTests()
  ]);

  tests.run();
}
