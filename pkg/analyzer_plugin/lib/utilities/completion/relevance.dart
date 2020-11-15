// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

//
// Constant values used for relevance values when creating completion
// suggestions in Dart code.
//
const int DART_RELEVANCE_DEFAULT = 1000;
const int DART_RELEVANCE_HIGH = 2000;
const int DART_RELEVANCE_LOW = 500;

/// A name scope for constants that are related to the relevance of completion
/// suggestions. The values are required to be in the range [0, 1000].
abstract class Relevance {
  /// The relevance used when suggesting a `call` method that is implied by a
  /// type but isn't explicitly implemented in the type hierarchy.
  static const int callFunction = 200;

  /// The relevance used when suggesting a closure corresponding to a
  /// function-typed parameter in an argument list.
  static const int closure = 900;

  /// The relevance used when suggesting a constructor.
  static const int constructor = 900;

  /// The relevance used when suggesting a field as a field formal parameter.
  static const int fieldFormalParameter = 1000;

  /// The relevance used when suggesting an import of a library other than
  /// `dart:core`.
  static const int import = 900;

  /// The relevance used when suggesting an import of `dart:core`.
  static const int importDartCore = 100;

  /// The relevance used when suggesting a label.
  static const int label = 1000;

  /// The relevance used when suggesting the `loadLibrary` function from a
  /// deferred imported library.
  static const int loadLibrary = 200;

  /// The relevance used when suggesting a member of a class or extension and
  /// there are no features that can be used to provide a relevance score.
  static const int member = 500;

  /// The relevance used when suggesting a named argument corresponding to a
  /// named parameter that is not required.
  static const int namedArgument = 900;

  /// The relevance used when suggesting a named constructor.
  static const int namedConstructor = 1000;

  /// The relevance used when suggesting an override of an inherited member.
  static const int override = 750;

  /// The relevance used when suggesting a prefix from an import directive.
  static const int prefix = 50;

  /// The relevance used when suggesting a named argument corresponding to a
  /// named parameter that is required.
  static const int requiredNamedArgument = 950;

  /// The relevance used when suggesting a type parameter.
  static const int typeParameter = 500;
}

/// A name scope for constants that are related to the relevance of completion
/// suggestions. The values are required to be in the range [0, 1000].
abstract class RelevanceBoost {
  /// The relevance boost used when suggesting anything other than an enum
  /// constant from an available declaration set.
  static const int availableDeclaration = 10;

  /// The relevance boost used when suggesting an enum constant from an
  /// available declaration set.
  static const int availableEnumConstant = 250;
}
