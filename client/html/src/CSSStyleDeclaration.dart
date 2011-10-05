// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface CSSStyleDeclaration {

  String get cssText();

  void set cssText(String value);

  int get length();

  CSSRule get parentRule();

  CSSValue getPropertyCSSValue(String propertyName);

  String getPropertyPriority(String propertyName);

  String getPropertyShorthand(String propertyName);

  String getPropertyValue(String propertyName);

  bool isPropertyImplicit(String propertyName);

  String item(int index);

  String removeProperty(String propertyName);

  void setProperty(String propertyName, String value, [String priority]);
}
