// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';

/// The base name of an element.
///
/// In contrast to [LookupName] there is no `=` at the end.
extension type BaseName(String _it) {
  factory BaseName.read(SummaryDataReader reader) {
    var str = reader.readStringUtf8();
    return BaseName(str);
  }

  void write(BufferedSink sink) {
    sink.writeStringUtf8(_it);
  }

  static int compare(BaseName left, BaseName right) {
    return left._it.compareTo(right._it);
  }
}

/// The lookup name of an element.
///
/// Specifically, for setters there is `=` at the end.
extension type LookupName(String _it) {
  factory LookupName.read(SummaryDataReader reader) {
    var str = reader.readStringUtf8();
    return LookupName(str);
  }

  BaseName get asBaseName {
    var str = _it.removeSuffix('=') ?? _it;
    return str.asBaseName;
  }

  /// Returns the underlying [String] value, explicitly.
  String get asString => _it;

  bool get isPrivate => _it.startsWith('_');

  void write(BufferedSink sink) {
    sink.writeStringUtf8(_it);
  }

  static int compare(LookupName left, LookupName right) {
    return left._it.compareTo(right._it);
  }
}

extension BufferedSinkExtension on BufferedSink {
  void writeBaseNameIterable(Iterable<BaseName> names) {
    writeUInt30(names.length);
    for (var baseName in names) {
      baseName.write(this);
    }
  }
}

extension IterableOfBaseNameExtension on Iterable<BaseName> {
  List<BaseName> sorted() => [...this]..sort(BaseName.compare);
}

extension IterableOfStringExtension on Iterable<String> {
  Set<BaseName> toBaseNameSet() {
    return map((str) => str.asBaseName).toSet();
  }
}

extension StringExtension on String {
  BaseName get asBaseName {
    return BaseName(this);
  }

  LookupName get asLookupName {
    return LookupName(this);
  }
}

extension SummaryDataReaderExtension on SummaryDataReader {
  Set<BaseName> readBaseNameSet() {
    var length = readUInt30();
    var result = <BaseName>{};
    for (var i = 0; i < length; i++) {
      var baseName = BaseName.read(this);
      result.add(baseName);
    }
    return result;
  }
}
