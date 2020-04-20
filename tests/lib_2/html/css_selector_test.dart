// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/expect.dart';
import 'utils.dart';

main() {
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
  Expect.equals('<p class=""><span>Test #1</span></p>', para.outerHtml);

  para = document.body.querySelector('p') as ParagraphElement;
  para.classes.addAll(['c']);

  para = document.body.querySelector('p') as ParagraphElement;
  Expect.equals('<p class="c"><span>Test #1</span></p>', para.outerHtml);

  var allPara = document.body.querySelectorAll('p');
  allPara.classes.removeAll(['b', 'c']);

  var checkAllPara = document.body.querySelectorAll('p');
  Expect.equals(
      '<p class=""><span>Test #1</span></p>', checkAllPara[0].outerHtml);
  Expect.equals(
      '<p class=""><span>Test #2</span></p>', checkAllPara[1].outerHtml);
}
