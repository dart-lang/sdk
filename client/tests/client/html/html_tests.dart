// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('html_tests');

#import('../../../base/base.dart');
#import('../../../html/html.dart');
#import('../../../testing/unittest/unittest.dart');
#import('../../../util/utilslib.dart');

#source('CSSStyleDeclarationTests.dart');
#source('DocumentFragmentTests.dart');
#source('ElementTests.dart');
#source('EventTests.dart');
#source('MeasurementTests.dart');

main() {
  group('CSSStyleDeclaration', testCSSStyleDeclaration);
  group('DocumentFragment', testDocumentFragment);
  group('Element', testElement);
  group('Event', testEvents);
  group('Measurement', testMeasurement);
}
