// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TableElement extends Element {

  String get align();

  void set align(String value);

  String get bgColor();

  void set bgColor(String value);

  String get border();

  void set border(String value);

  TableCaptionElement get caption();

  void set caption(TableCaptionElement value);

  String get cellPadding();

  void set cellPadding(String value);

  String get cellSpacing();

  void set cellSpacing(String value);

  String get frame();

  void set frame(String value);

  ElementList get rows();

  String get rules();

  void set rules(String value);

  String get summary();

  void set summary(String value);

  ElementList get tBodies();

  TableSectionElement get tFoot();

  void set tFoot(TableSectionElement value);

  TableSectionElement get tHead();

  void set tHead(TableSectionElement value);

  String get width();

  void set width(String value);

  Element createCaption();

  Element createTFoot();

  Element createTHead();

  void deleteCaption();

  void deleteRow(int index);

  void deleteTFoot();

  void deleteTHead();

  Element insertRow(int index);
}
