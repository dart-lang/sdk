// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'utils.dart';

main() {
  useHtmlIndividualConfiguration();

  final String htmlPayload = "<div>"
      "<div>"
      "<p class='a'>"
      "<span>Test #1</span>"
      "</p>"
      "</div>"
      "<div>"
      "<p class='b'>"
      "<span>Test #2</span>"
      "</p>"
      "</div>"
      "</div>";

  final elements =
      new Element.html(htmlPayload, treeSanitizer: new NullTreeSanitizer());
  document.body.nodes.add(elements);

  var para = document.body.querySelector('p') as ParagraphElement;
  para.classes.removeAll(['a', 'b']);

  para = document.body.querySelector('p') as ParagraphElement;
  expect(para.outerHtml, '<p class=""><span>Test #1</span></p>');

  para = document.body.querySelector('p') as ParagraphElement;
  para.classes.addAll(['c']);

  para = document.body.querySelector('p') as ParagraphElement;
  expect(para.outerHtml, '<p class="c"><span>Test #1</span></p>');

  var allPara = document.body.querySelectorAll('p');
  allPara.classes.removeAll(['b', 'c']);

  var checkAllPara = document.body.querySelectorAll('p');
  expect(checkAllPara[0].outerHtml, '<p class=""><span>Test #1</span></p>');
  expect(checkAllPara[1].outerHtml, '<p class=""><span>Test #2</span></p>');
}
