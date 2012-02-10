// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('html_tests');

#import('dart:html');
#import('dart:htmlimpl');
#import('../../../testing/unittest/unittest.dart');

#source('CSSStyleDeclarationTests.dart');
#source('DocumentFragmentTests.dart');
#source('ElementTests.dart');
#source('EventTests.dart');
#source('ListsTests.dart');
#source('LocalStorageTests.dart');
#source('MeasurementTests.dart');
#source('NodeTests.dart');
#source('SVGElementTests.dart');
#source('XHRTests.dart');

main() {
  group('CSSStyleDeclaration', testCSSStyleDeclaration);
  group('DocumentFragment', testDocumentFragment);
  group('Element', testElement);
  group('Event', testEvents);
  group('Lists', testLists);
  group('LocalStorage', testLocalStorage);
  group('Measurement', testMeasurement);
  group('Node', testNode);
  group('SVGElement', testSVGElement);
  group('XHR', testXHR);
}
