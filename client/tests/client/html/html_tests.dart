// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('html_tests');

#import('dart:html');
#import('../../../../lib/unittest/unittest.dart');
#import('../../../../lib/unittest/html_config.dart');

#source('util.dart');
#source('CSSStyleDeclarationTests.dart');
#source('DocumentFragmentTests.dart');
#source('ElementTests.dart');
// #source('EventTests.dart');
#source('LocalStorageTests.dart');
#source('MeasurementTests.dart');
#source('NodeTests.dart');
#source('SVGElementTests.dart');
#source('XHRTests.dart');

// TODO(nweiz): enable these once the XML document work is ported over.
// #source('XMLDocumentTests.dart');
// #source('XMLElementTests.dart');

main() {
  useHtmlConfiguration();
  group('CSSStyleDeclaration', testCSSStyleDeclaration);
  group('DocumentFragment', testDocumentFragment);
  group('Element', testElement);
  // TODO(nweiz): enable once event constructors are ported -- Dart issue 1996.
  // group('Event', testEvents);
  group('LocalStorage', testLocalStorage);
  group('Measurement', testMeasurement);
  group('Node', testNode);
  group('SVGElement', testSVGElement);
  group('XHR', testXHR);

  // group('DocumentFragment', testDocumentFragment);
  // group('XMLDocument', testXMLDocument);
  // group('XMLElement', testXMLElement);
}
