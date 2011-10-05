// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLTableRowElement extends HTMLElement {

  String get align();

  void set align(String value);

  String get bgColor();

  void set bgColor(String value);

  HTMLCollection get cells();

  String get ch();

  void set ch(String value);

  String get chOff();

  void set chOff(String value);

  int get rowIndex();

  int get sectionRowIndex();

  String get vAlign();

  void set vAlign(String value);

  void deleteCell(int index = null);

  HTMLElement insertCell(int index = null);
}
