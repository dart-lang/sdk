// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'reader.dart';

abstract class DwarfContainerStringTable {
  String? operator [](int index);
}

abstract class DwarfContainerSymbol {
  int get value;
  String get name;
}

abstract class DwarfContainer {
  Reader debugInfoReader(Reader containerReader);
  Reader lineNumberInfoReader(Reader containerReader);
  Reader abbreviationsTableReader(Reader containerReader);
  DwarfContainerSymbol? staticSymbolAt(int address);

  int get vmStartAddress;
  int get isolateStartAddress;

  String? get buildId;

  DwarfContainerStringTable? get stringTable;

  void writeToStringBuffer(StringBuffer buffer);
}
