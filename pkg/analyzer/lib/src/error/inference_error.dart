// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/binary/binary_writer.dart';
import 'package:collection/collection.dart';

/// The top-level type inference error.
class TopLevelInferenceError {
  /// The kind of the error.
  final TopLevelInferenceErrorKind kind;

  /// The [kind] specific arguments.
  final List<String> arguments;

  TopLevelInferenceError({required this.kind, required this.arguments});

  factory TopLevelInferenceError.read(SummaryDataReader reader) {
    return TopLevelInferenceError(
      kind: reader.readEnum(TopLevelInferenceErrorKind.values),
      arguments: reader.readStringUtf8List(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TopLevelInferenceError &&
        other.kind == kind &&
        const ListEquality<String>().equals(other.arguments, arguments);
  }

  void write(BufferedSink sink) {
    sink.writeEnum(kind);
    sink.writeStringUtf8Iterable(arguments);
  }

  static TopLevelInferenceError? readOptional(SummaryDataReader reader) {
    return reader.readOptionalObject(() => TopLevelInferenceError.read(reader));
  }
}

/// Enum used to indicate the kind of the error during top-level inference.
enum TopLevelInferenceErrorKind {
  none,
  dependencyCycle,
  overrideNoCombinedSuperSignature,
}

extension TopLevelInferenceErrorExtension on TopLevelInferenceError? {
  void writeOptional(BufferedSink sink) {
    sink.writeOptionalObject(this, (it) => it.write(sink));
  }
}
