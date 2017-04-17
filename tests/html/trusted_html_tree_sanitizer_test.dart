// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This tests HTML validation and sanitization, which is very important
/// for prevent XSS or other attacks. If you suppress this, or parts of it
/// please make it a critical bug and bring it to the attention of the
/// dart:html maintainers.
library trusted_html_tree_sanitizer_test;

import 'dart:html';
import 'dart:svg' as svg;
import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'utils.dart';
import 'dart:js' as js;

var oldAdoptNode;
var jsDocument;

/// We want to verify that with the trusted sanitizer we are not
/// creating a document fragment. So make DocumentFragment operation
/// throw.
makeDocumentFragmentAdoptionThrow() {
  var document = js.context['document'];
  jsDocument = new js.JsObject.fromBrowserObject(document);
  oldAdoptNode = jsDocument['adoptNode'];
  jsDocument['adoptNode'] = null;
}

restoreOldAdoptNode() {
  jsDocument['adoptNode'] = oldAdoptNode;
}

main() {
  useHtmlIndividualConfiguration();

  group('not_create_document_fragment', () {
    setUp(makeDocumentFragmentAdoptionThrow);
    tearDown(restoreOldAdoptNode);

    test('setInnerHtml', () {
      document.body.setInnerHtml('<div foo="baz">something</div>',
          treeSanitizer: NodeTreeSanitizer.trusted);
      expect(document.body.innerHtml, '<div foo="baz">something</div>');
    });

    test("appendHtml", () {
      var oldStuff = document.body.innerHtml;
      var newStuff = '<div rumplestiltskin="value">content</div>';
      document.body
          .appendHtml(newStuff, treeSanitizer: NodeTreeSanitizer.trusted);
      expect(document.body.innerHtml, oldStuff + newStuff);
    });
  });

  group('untrusted', () {
    setUp(makeDocumentFragmentAdoptionThrow);
    tearDown(restoreOldAdoptNode);
    test('untrusted', () {
      expect(() => document.body.innerHtml = "<p>anything</p>", throws);
    });
  });
}
