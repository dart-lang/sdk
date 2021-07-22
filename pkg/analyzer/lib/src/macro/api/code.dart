// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Combines [parts] into a [String].
/// Must only contain [Code] or [String] instances.
String _combineParts(List<Object> parts) {
  var buffer = StringBuffer();
  for (var part in parts) {
    if (part is String) {
      buffer.write(part);
    } else if (part is Code) {
      buffer.write(part.code);
    } else if (part is List<Code>) {
      buffer.write(part.map((p) => p.code).join());
    } else {
      throw UnsupportedError(
        'Only String, Code, and List<Code> are allowed but got $part',
      );
    }
  }
  return buffer.toString();
}

/// The representation of a piece of code.
abstract class Code {
  String get code;

  @override
  String toString() => code;
}

/// A piece of code representing a syntactically valid declaration.
class Declaration extends Code {
  @override
  final String code;

  Declaration(this.code);

  /// Creates a [Declaration] from [parts], which must be of type [Code],
  /// `List<Code>`, or [String].
  factory Declaration.fromParts(List<Object> parts) =>
      Declaration(_combineParts(parts));
}

/// A piece of code that can't be parsed into a valid language construct in its
/// current form. No validation or parsing is performed.
class Fragment extends Code {
  @override
  final String code;

  Fragment(this.code);

  /// Creates a [Fragment] from [parts], which must be of type [Code],
  /// `List<Code>`, or [String].
  factory Fragment.fromParts(List<Object> parts) =>
      Fragment(_combineParts(parts));
}
