// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLOutputElement extends HTMLElement {

  String get defaultValue();

  void set defaultValue(String value);

  HTMLFormElement get form();

  DOMSettableTokenList get htmlFor();

  void set htmlFor(DOMSettableTokenList value);

  NodeList get labels();

  String get name();

  void set name(String value);

  String get type();

  String get validationMessage();

  ValidityState get validity();

  String get value();

  void set value(String value);

  bool get willValidate();

  bool checkValidity();

  void setCustomValidity(String error);
}
