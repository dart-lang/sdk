// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSStyleSheet extends StyleSheet {

  CSSRuleList get cssRules();

  CSSRule get ownerRule();

  CSSRuleList get rules();

  int addRule(String selector, String style, int index);

  void deleteRule(int index);

  int insertRule(String rule, int index);

  void removeRule(int index);
}
