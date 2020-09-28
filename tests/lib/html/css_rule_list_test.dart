// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  var isCssRuleList =
      predicate((x) => x is List<CssRule>, 'is a List<CssRule>');

  test("ClientRectList test", () {
    var sheet = document.styleSheets![0] as CssStyleSheet;
    List<CssRule> rulesList = sheet.cssRules;
    expect(rulesList, isCssRuleList);
  });
}
