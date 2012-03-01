// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TableElement extends Element {

  String align;

  String bgColor;

  String border;

  TableCaptionElement caption;

  String cellPadding;

  String cellSpacing;

  String frame;

  final HTMLCollection rows;

  String rules;

  String summary;

  final HTMLCollection tBodies;

  TableSectionElement tFoot;

  TableSectionElement tHead;

  String width;

  Element createCaption();

  Element createTFoot();

  Element createTHead();

  void deleteCaption();

  void deleteRow(int index);

  void deleteTFoot();

  void deleteTHead();

  Element insertRow(int index);
}
