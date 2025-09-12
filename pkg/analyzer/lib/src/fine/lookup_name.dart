// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/binary/binary_writer.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';

/// The base name of an element.
///
/// In contrast to [LookupName] there is no `=` at the end.
extension type BaseName(String _it) {
  factory BaseName.read(SummaryDataReader reader) {
    var str = reader.readStringUtf8();
    return BaseName(str);
  }

  /// Returns the underlying [String] value, explicitly.
  String get asString => _it;

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
    if (const {'==', '<=', '>='}.contains(_it)) {
      return _it.asBaseName;
    }

    if (_it == '[]=') {
      return '[]'.asBaseName;
    }

    var str = _it.removeSuffix('=') ?? _it;
    return str.asBaseName;
  }

  /// Returns the underlying [String] value, explicitly.
  String get asString => _it;

  bool get isIndexEq {
    return _it == '[]=';
  }

  bool get isIndexOrIndexEq {
    return const {'[]', '[]='}.contains(_it);
  }

  bool get isOperator {
    return const {
      ...{'+', '-', '*', '/', '~/', '%'},
      ...{'<<', '>>', '>>>', '&', '^', '|', '~'},
      ...{'<', '<=', '>', '>=', '=='},
      'unary-',
    }.contains(_it);
  }

  bool get isPrivate => _it.startsWith('_');

  bool get isSetter {
    return _it.endsWith('=') && !const {'==', '<=', '>=', '[]='}.contains(_it);
  }

  /// This name must be a name of a method.
  LookupName get methodToSetter {
    assert(!isSetter);
    if (isOperator || isIndexOrIndexEq) {
      return this;
    }
    return LookupName('$_it=');
  }

  List<LookupName> get relatedNames {
    if (isOperator) {
      return [this];
    }

    if (isIndexOrIndexEq) {
      return ['[]'.asLookupName, '[]='.asLookupName];
    }

    if (isSetter) {
      return [this, setterToGetter];
    }

    var setterName = '$_it=';
    return [this, setterName.asLookupName];
  }

  /// This name must be a name of a setter.
  LookupName get setterToGetter {
    assert(isSetter);
    assert(_it.endsWith('='));
    return _it.substring(0, _it.length - 1).asLookupName;
  }

  void write(BufferedSink sink) {
    sink.writeStringUtf8(_it);
  }

  static int compare(LookupName left, LookupName right) {
    return left._it.compareTo(right._it);
  }
}

extension BufferedSinkExtension on BufferedSink {
  void writeBaseNameIterable(Iterable<BaseName> names) {
    writeUint30(names.length);
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

extension LookupNameIterableExtension on Iterable<LookupName> {
  void write(BufferedSink sink) {
    sink.writeIterable(this, (name) => name.write(sink));
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
    var length = readUint30();
    var result = <BaseName>{};
    for (var i = 0; i < length; i++) {
      var baseName = BaseName.read(this);
      result.add(baseName);
    }
    return result;
  }

  List<LookupName> readLookupNameList() {
    return readTypedList(() => LookupName.read(this));
  }

  Set<LookupName> readLookupNameSet() {
    var length = readUint30();
    var result = <LookupName>{};
    for (var i = 0; i < length; i++) {
      var lookupName = LookupName.read(this);
      result.add(lookupName);
    }
    return result;
  }
}
