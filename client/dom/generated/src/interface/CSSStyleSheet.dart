// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSStyleSheet extends StyleSheet {

  CSSRuleList get cssRules();

  CSSRule get ownerRule();

  CSSRuleList get rules();

  int addRule(String selector = null, String style = null, int index = null);

  void deleteRule(int index = null);

  int insertRule(String rule = null, int index = null);

  void removeRule(int index = null);
}
