// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Interface handling [DataSourceReader] low-level data deserialization.
///
/// Each implementation of [DataSource] should have a corresponding
/// [DataSink] for which it deserializes data.
abstract class DataSource {
  /// Deserialization of a section begin tag.
  void begin(String tag);

  /// Deserialization of a section end tag.
  void end(String tag);

  /// Deserialization of a string value.
  String readString();

  /// Deserialization of a non-negative integer value.
  int readInt();

  /// Deserialization of an enum value in [values].
  E readEnum<E>(List<E> values);

  /// Returns a string representation of the current state of the data source
  /// useful for debugging in consistencies between serialization and
  /// deserialization.
  String get errorContext;
}
