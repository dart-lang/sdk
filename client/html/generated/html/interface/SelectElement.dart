// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SelectElement extends Element {

  bool autofocus;

  bool disabled;

  final FormElement form;

  final NodeList labels;

  int length;

  bool multiple;

  String name;

  final HTMLOptionsCollection options;

  bool required;

  int selectedIndex;

  int size;

  final String type;

  final String validationMessage;

  final ValidityState validity;

  String value;

  final bool willValidate;

  void add(Element element, Element before);

  bool checkValidity();

  Node item(int index);

  Node namedItem(String name);

  void setCustomValidity(String error);
}
