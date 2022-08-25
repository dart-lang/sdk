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
  /// Returns the architecture of the container as reported by Dart (e.g.,
  /// 'x64' or 'arm'). Returns null if the architecture of the container does
  /// not match any expected Dart architecture.
  String? get architecture;

  Reader debugInfoReader(Reader containerReader);
  Reader lineNumberInfoReader(Reader containerReader);
  Reader abbreviationsTableReader(Reader containerReader);
  DwarfContainerSymbol? staticSymbolAt(int address);

  int? get vmStartAddress;
  int? get isolateStartAddress;

  String? get buildId;

  DwarfContainerStringTable? get debugStringTable;
  DwarfContainerStringTable? get debugLineStringTable;

  void writeToStringBuffer(StringBuffer buffer);

  @override
  String toString() {
    final buffer = StringBuffer();
    writeToStringBuffer(buffer);
    return buffer.toString();
  }
}
