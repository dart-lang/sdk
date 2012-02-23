// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLOutputElement extends HTMLElement {

  String defaultValue;

  final HTMLFormElement form;

  DOMSettableTokenList htmlFor;

  final NodeList labels;

  String name;

  final String type;

  final String validationMessage;

  final ValidityState validity;

  String value;

  final bool willValidate;

  bool checkValidity();

  void setCustomValidity(String error);
}
