// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface InputElement extends Element {

  InputElementEvents get on();

  String accept;

  String align;

  String alt;

  String autocomplete;

  bool autofocus;

  bool checked;

  bool defaultChecked;

  String defaultValue;

  bool disabled;

  final FileList files;

  final FormElement form;

  String formAction;

  String formEnctype;

  String formMethod;

  bool formNoValidate;

  String formTarget;

  bool incremental;

  bool indeterminate;

  final NodeList labels;

  String max;

  int maxLength;

  String min;

  bool multiple;

  String name;

  String pattern;

  String placeholder;

  bool readOnly;

  bool required;

  String selectionDirection;

  int selectionEnd;

  int selectionStart;

  int size;

  String src;

  String step;

  String type;

  String useMap;

  final String validationMessage;

  final ValidityState validity;

  String value;

  Date valueAsDate;

  num valueAsNumber;

  bool webkitGrammar;

  bool webkitSpeech;

  bool webkitdirectory;

  final bool willValidate;

  bool checkValidity();

  void select();

  void setCustomValidity(String error);

  void setSelectionRange(int start, int end, [String direction]);

  void stepDown([int n]);

  void stepUp([int n]);
}

interface InputElementEvents extends ElementEvents {

  EventListenerList get speechChange();
}
