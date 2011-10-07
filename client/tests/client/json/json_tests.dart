// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('json_tests');

#import('dart:json');
#import('dart:html');
#import('../../../testing/unittest/unittest.dart');

#source('json_test.dart');
#source('web_json_test.dart');

main() {
  WebJsonTest.main();
}
