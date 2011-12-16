// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('total_tests');

#import('dart:html');
#import('../../../../base/base.dart');
#import('../../../../samples/total/src/TotalLib.dart');
#import('../../../../testing/unittest/unittest.dart');
#import('../../../../view/view.dart');
#source('../../../../../samples/total/src/SYLKProducer.dart');
#source('total_test_lib.dart');

main() {
  totalTests();
}
