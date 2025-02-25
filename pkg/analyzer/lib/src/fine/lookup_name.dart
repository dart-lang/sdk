// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';

typedef BaseName = String;

extension type LookupName(String _it) {
  factory LookupName.read(SummaryDataReader reader) {
    var str = reader.readStringUtf8();
    return LookupName(str);
  }

  BaseName get asBaseName {
    return _it.removeSuffix('=') ?? _it;
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

extension StringExtension on String {
  LookupName get asLookupName {
    return LookupName(this);
  }
}
