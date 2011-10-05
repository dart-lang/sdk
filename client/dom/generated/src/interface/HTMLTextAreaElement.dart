// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLTextAreaElement extends HTMLElement {

  String get accessKey();

  void set accessKey(String value);

  bool get autofocus();

  void set autofocus(bool value);

  int get cols();

  void set cols(int value);

  String get defaultValue();

  void set defaultValue(String value);

  bool get disabled();

  void set disabled(bool value);

  HTMLFormElement get form();

  NodeList get labels();

  int get maxLength();

  void set maxLength(int value);

  String get name();

  void set name(String value);

  String get placeholder();

  void set placeholder(String value);

  bool get readOnly();

  void set readOnly(bool value);

  bool get required();

  void set required(bool value);

  int get rows();

  void set rows(int value);

  String get selectionDirection();

  void set selectionDirection(String value);

  int get selectionEnd();

  void set selectionEnd(int value);

  int get selectionStart();

  void set selectionStart(int value);

  int get textLength();

  String get type();

  String get validationMessage();

  ValidityState get validity();

  String get value();

  void set value(String value);

  bool get willValidate();

  String get wrap();

  void set wrap(String value);

  bool checkValidity();

  void select();

  void setCustomValidity(String error);

  void setSelectionRange(int start = null, int end = null, String direction = null);
}
