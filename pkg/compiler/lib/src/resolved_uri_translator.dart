// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// API used by the library loader to translate internal SDK URIs into file
/// system readable URIs.
abstract class ResolvedUriTranslator {
  factory ResolvedUriTranslator(Map<String, Uri> sdkLibraries) =
      _ResolvedUriTranslator;

  /// A mapping from dart: library names to their location.
  Map<String, Uri> get sdkLibraries;
}

/// A translator that forwards all methods to an internal
/// [ResolvedUriTranslator].
///
/// The translator to forward to may be set after the instance is constructed.
/// This is useful for the compiler because some tasks that are instantiated at
/// compiler construction time need a [ResolvedUriTranslator], but the data
/// required to instantiate it cannot be obtained at construction time. So a
/// [ForwardingResolvedUriTranslator] may be passed instead, and the translator
/// to forward to can be set once the required data has been retrieved.
class ForwardingResolvedUriTranslator implements ResolvedUriTranslator {
  ResolvedUriTranslator resolvedUriTranslator;

  /// Returns `true` if [resolvedUriTranslator] is not `null`.
  bool get isSet => resolvedUriTranslator != null;

  /// The opposite of [isSet].
  bool get isNotSet => resolvedUriTranslator == null;

  @override
  Map<String, Uri> get sdkLibraries => resolvedUriTranslator.sdkLibraries;
}

class _ResolvedUriTranslator implements ResolvedUriTranslator {
  final Map<String, Uri> _sdkLibraries;

  _ResolvedUriTranslator(this._sdkLibraries);

  Map<String, Uri> get sdkLibraries => _sdkLibraries;
}
