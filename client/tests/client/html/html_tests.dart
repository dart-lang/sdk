// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('layout_tests');

#import('../../../base/base.dart');
#import('../../../html/html.dart');
#import('../../../testing/unittest/unittest.dart');
#import('../../../util/utilslib.dart');

// Ugly, temporary hack: this import disables implicit
// import of dart:dom by Dartium.
#import('dart:html', prefix: 'no_use');

#source('CSSStyleDeclarationTests.dart');
#source('DocumentFragmentTests.dart');
#source('EventTests.dart');

main() {
  group('CSSStyleDeclaration', testCSSStyleDeclaration);
  group('DocumentFragment', testDocumentFragment);
  group('Event', testEvents);
}
