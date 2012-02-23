// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLTableElement extends HTMLElement {

  String align;

  String bgColor;

  String border;

  HTMLTableCaptionElement caption;

  String cellPadding;

  String cellSpacing;

  String frame;

  final HTMLCollection rows;

  String rules;

  String summary;

  final HTMLCollection tBodies;

  HTMLTableSectionElement tFoot;

  HTMLTableSectionElement tHead;

  String width;

  HTMLElement createCaption();

  HTMLElement createTFoot();

  HTMLElement createTHead();

  void deleteCaption();

  void deleteRow(int index);

  void deleteTFoot();

  void deleteTHead();

  HTMLElement insertRow(int index);
}
