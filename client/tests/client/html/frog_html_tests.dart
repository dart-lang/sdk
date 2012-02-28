// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('frog_html_tests');

#import('dart:html');
#import('dart:htmlimpl');
#import('../../../testing/unittest/unittest.dart');

#source('util.dart');
#source('frog_DocumentFragmentTests.dart');
#source('XMLDocumentTests.dart');
#source('XMLElementTests.dart');

main() {
  // These tests require a DOMParser constructor, which doesn't exist in
  // Dartium. See issue 649.
  group('DocumentFragment', testDocumentFragment);
  group('XMLDocument', testXMLDocument);
  group('XMLElement', testXMLElement);
}
