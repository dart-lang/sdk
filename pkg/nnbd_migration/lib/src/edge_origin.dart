// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';

/// Edge origin resulting from the use of a type that is always nullable.
///
/// For example, in the following code snippet:
///   void f(dynamic x) {}
///
/// this class is used for the edge connecting `always` to the type of f's `x`
/// parameter, due to the fact that the `dynamic` type is always considered
/// nullable.
class AlwaysNullableTypeOrigin extends EdgeOriginWithLocation {
  AlwaysNullableTypeOrigin(Source source, int offset) : super(source, offset);
}

/// Common interface for classes providing information about how an edge came
/// to be; that is, what was found in the source code that led the migration
/// tool to create the edge.
abstract class EdgeOrigin {}

/// Common base class for edge origins that are associated with a single
/// location in the source code.
abstract class EdgeOriginWithLocation extends EdgeOrigin {
  /// The source file containing the code construct that led to the edge.
  final Source source;

  /// The offset within the source file of the code construct that led to the
  /// edge.
  final int offset;

  EdgeOriginWithLocation(this.source, this.offset);
}

/// Edge origin resulting from the relationship between a field formal parameter
/// and the corresponding field.
class FieldFormalParameterOrigin extends EdgeOriginWithLocation {
  FieldFormalParameterOrigin(Source source, int offset) : super(source, offset);
}

/// Edge origin resulting from the presence of a `??` operator.
class IfNullOrigin extends EdgeOriginWithLocation {
  IfNullOrigin(Source source, int offset) : super(source, offset);
}

/// Edge origin resulting from the implicit call from a mixin application
/// constructor to the corresponding super constructor.
///
/// For example, in the following code snippet:
///   class C {
///     C(int i);
///   }
///   mixin M {}
///   class D = C with M;
///
/// this class is used for the edge connecting the types of the `i` parameters
/// between the implicit constructor for `D` and the explicit constructor for
/// `C`.
class ImplicitMixinSuperCallOrigin extends EdgeOriginWithLocation {
  ImplicitMixinSuperCallOrigin(Source source, int offset)
      : super(source, offset);
}

/// Edge origin resulting from an inheritance relationship between two methods.
class InheritanceOrigin extends EdgeOriginWithLocation {
  InheritanceOrigin(Source source, int offset) : super(source, offset);
}

/// Edge origin resulting from a type that is inferred from its initializer.
class InitializerInferenceOrigin extends EdgeOriginWithLocation {
  InitializerInferenceOrigin(Source source, int offset) : super(source, offset);
}

/// Edge origin resulting from a class that is instantiated to bounds.
///
/// For example, in the following code snippet:
///   class C<T extends Object> {}
///   C x;
///
/// this class is used for the edge connecting the type of x's type parameter
/// with the type bound in the declaration of C.
class InstantiateToBoundsOrigin extends EdgeOriginWithLocation {
  InstantiateToBoundsOrigin(Source source, int offset) : super(source, offset);
}

/// Edge origin resulting from a call site that does not supply a named
/// parameter.
///
/// For example, in the following code snippet:
///   void f({int i}) {}
///   main() {
///     f();
///   }
///
/// this class is used for the edge connecting `always` to the type of f's `i`
/// parameter, due to the fact that the call to `f` implicitly passes a null
/// value for `i`.
class NamedParameterNotSuppliedOrigin extends EdgeOriginWithLocation {
  NamedParameterNotSuppliedOrigin(Source source, int offset)
      : super(source, offset);
}

/// Edge origin resulting from the presence of a non-null assertion.
///
/// For example, in the following code snippet:
///   void f(int i) {
///     assert(i != null);
///   }
///
/// this class is used for the edge connecting the type of f's `i` parameter to
/// `never`, due to the assert statement proclaiming that `i` is not `null`.
class NonNullAssertionOrigin extends EdgeOriginWithLocation {
  NonNullAssertionOrigin(Source source, int offset) : super(source, offset);
}

/// Edge origin resulting from the presence of an explicit nullability hint
/// comment.
///
/// For example, in the following code snippet:
///   void f(int/*?*/ i) {}
///
/// this class is used for the edge connecting `always` to the type of f's `i`
/// parameter, due to the presence of the `/*?*/` comment.
class NullabilityCommentOrigin extends EdgeOriginWithLocation {
  NullabilityCommentOrigin(Source source, int offset) : super(source, offset);
}

/// Edge origin resulting from the presence of an optional formal parameter.
///
/// For example, in the following code snippet:
///   void f({int i}) {}
///
/// this class is used for the edge connecting `always` to the type of f's `i`
/// parameter, due to the fact that `i` is optional and has no initializer.
class OptionalFormalParameterOrigin extends EdgeOriginWithLocation {
  OptionalFormalParameterOrigin(Source source, int offset)
      : super(source, offset);
}
