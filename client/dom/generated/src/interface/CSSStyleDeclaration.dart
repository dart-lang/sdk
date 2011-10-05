// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSStyleDeclaration {

  String get cssText();

  void set cssText(String value);

  int get length();

  CSSRule get parentRule();

  CSSValue getPropertyCSSValue(String propertyName = null);

  String getPropertyPriority(String propertyName = null);

  String getPropertyShorthand(String propertyName = null);

  String getPropertyValue(String propertyName = null);

  bool isPropertyImplicit(String propertyName = null);

  String item(int index = null);

  String removeProperty(String propertyName = null);

  void setProperty(String propertyName = null, String value = null, String priority = null);
}
