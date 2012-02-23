// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLTextAreaElement extends HTMLElement {

  bool autofocus;

  int cols;

  String defaultValue;

  String dirName;

  bool disabled;

  final HTMLFormElement form;

  final NodeList labels;

  int maxLength;

  String name;

  String placeholder;

  bool readOnly;

  bool required;

  int rows;

  String selectionDirection;

  int selectionEnd;

  int selectionStart;

  final int textLength;

  final String type;

  final String validationMessage;

  final ValidityState validity;

  String value;

  final bool willValidate;

  String wrap;

  bool checkValidity();

  void select();

  void setCustomValidity(String error);

  void setSelectionRange(int start, int end, [String direction]);
}
