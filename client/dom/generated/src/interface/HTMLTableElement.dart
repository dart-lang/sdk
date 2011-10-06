// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLTableElement extends HTMLElement {

  String get align();

  void set align(String value);

  String get bgColor();

  void set bgColor(String value);

  String get border();

  void set border(String value);

  HTMLTableCaptionElement get caption();

  void set caption(HTMLTableCaptionElement value);

  String get cellPadding();

  void set cellPadding(String value);

  String get cellSpacing();

  void set cellSpacing(String value);

  String get frame();

  void set frame(String value);

  HTMLCollection get rows();

  String get rules();

  void set rules(String value);

  String get summary();

  void set summary(String value);

  HTMLCollection get tBodies();

  HTMLTableSectionElement get tFoot();

  void set tFoot(HTMLTableSectionElement value);

  HTMLTableSectionElement get tHead();

  void set tHead(HTMLTableSectionElement value);

  String get width();

  void set width(String value);

  HTMLElement createCaption();

  HTMLElement createTFoot();

  HTMLElement createTHead();

  void deleteCaption();

  void deleteRow(int index);

  void deleteTFoot();

  void deleteTHead();

  HTMLElement insertRow(int index);
}
