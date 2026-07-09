// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/binary/binary_writer.dart';
import 'package:collection/collection.dart';

/// The top-level type inference error.
sealed class TopLevelInferenceError {
  factory TopLevelInferenceError.read(BinaryReader reader) {
    switch (TopLevelInferenceErrorKind.values[reader.readByte()]) {
      case TopLevelInferenceErrorKind.dependencyCycle:
        return TopLevelInferenceErrorDependencyCycle(
          cycle: reader.readStringUtf8List(),
        );
      case TopLevelInferenceErrorKind.overrideNoCombinedSuperSignature:
        return TopLevelInferenceErrorNoCombinedSuperSignature(
          candidateSignatures: reader.readStringUtf8(),
        );
    }
  }

  void write(BinaryWriter writer);

  static TopLevelInferenceError? readOptional(BinaryReader reader) {
    return reader.readOptionalObject(() => TopLevelInferenceError.read(reader));
  }
}

class TopLevelInferenceErrorDependencyCycle implements TopLevelInferenceError {
  /// The names of the elements in the cycle (sorted).
  final List<String> cycle;

  TopLevelInferenceErrorDependencyCycle({required this.cycle});

  @override
  bool operator ==(Object other) =>
      other is TopLevelInferenceErrorDependencyCycle &&
      const ListEquality<String>().equals(other.cycle, cycle);

  @override
  void write(BinaryWriter writer) {
    writer.writeEnum(TopLevelInferenceErrorKind.dependencyCycle);
    writer.writeStringUtf8Iterable(cycle);
  }
}

/// Enum used to indicate the kind of the error during top-level inference.
enum TopLevelInferenceErrorKind {
  dependencyCycle,
  overrideNoCombinedSuperSignature,
}

class TopLevelInferenceErrorNoCombinedSuperSignature
    implements TopLevelInferenceError {
  /// The list of candidate signatures which cannot be combined.
  final String candidateSignatures;

  TopLevelInferenceErrorNoCombinedSuperSignature({
    required this.candidateSignatures,
  });

  @override
  bool operator ==(Object other) =>
      other is TopLevelInferenceErrorNoCombinedSuperSignature &&
      other.candidateSignatures == candidateSignatures;

  @override
  void write(BinaryWriter writer) {
    writer.writeEnum(
      TopLevelInferenceErrorKind.overrideNoCombinedSuperSignature,
    );
    writer.writeStringUtf8(candidateSignatures);
  }
}

extension TopLevelInferenceErrorExtension on TopLevelInferenceError? {
  void writeOptional(BinaryWriter writer) {
    writer.writeOptionalObject(this, (it) => it.write(writer));
  }
}
