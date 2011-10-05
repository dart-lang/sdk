// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLSelectElement extends HTMLElement {

  bool get autofocus();

  void set autofocus(bool value);

  bool get disabled();

  void set disabled(bool value);

  HTMLFormElement get form();

  NodeList get labels();

  int get length();

  void set length(int value);

  bool get multiple();

  void set multiple(bool value);

  String get name();

  void set name(String value);

  HTMLOptionsCollection get options();

  bool get required();

  void set required(bool value);

  int get selectedIndex();

  void set selectedIndex(int value);

  int get size();

  void set size(int value);

  String get type();

  String get validationMessage();

  ValidityState get validity();

  String get value();

  void set value(String value);

  bool get willValidate();

  void add([HTMLElement element, HTMLElement before]);

  bool checkValidity();

  Node item([int index]);

  Node namedItem([String name]);

  void remove(int index);

  void setCustomValidity(String error);
}
