// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Interface handling [DataSinkWriter] low-level data serialization.
///
/// Each implementation of [DataSink] should have a corresponding
/// [DataSource] that deserializes data serialized by that implementation.
// TODO(48820): Move this interface back to 'sink.dart'.
abstract class DataSink {
  int get length;

  /// Serialization of a non-negative integer value.
  void writeInt(int value);

  /// Serialization of an enum value.
  void writeEnum(dynamic value);

  /// Serialization of a String value.
  void writeString(String value);

  /// Serialization of a section begin tag. May be omitted by some writers.
  void beginTag(String tag);

  /// Serialization of a section end tag. May be omitted by some writers.
  void endTag(String tag);

  /// Closes any underlying data sinks.
  void close();
}
