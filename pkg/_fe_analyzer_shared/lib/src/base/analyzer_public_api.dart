// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Annotation for top level elements within a library that are part of the
/// analyzer's public API, even though they might not appear to be (e.g., due to
/// being implemented inside a `src` directory but re-exported in `lib`, or due
/// to being a supertype of a public type).
///
/// This annotation is intended to be used inside the `src` subdirectories of
/// the `_fe_analyzer_shared` and `analyzer` packages.
///
/// Applying this annotation to an element lets developers know that
/// modifications to the element should be carefully reviewed for backward
/// compatibility, and to make sure they don't unduly expose private
/// implementation details.
///
/// The `analyzer_public_api` lint rules use this annotation to tell:
/// - Which elements are safe to export in the analyzer's `lib` directory
/// - Which classes and mixins are safe to use as supertypes of a public type
class AnalyzerPublicApi {
  /// Explanation of why this element is part of the public API, in spite of not
  /// being in the analyzer's `lib` folder.
  final String message;

  const AnalyzerPublicApi({required this.message});
}
