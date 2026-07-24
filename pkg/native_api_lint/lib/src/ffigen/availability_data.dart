// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Dart model classes representing OS availability info extracted from
/// Objective-C/C header parsing (via libclang).
///
/// This library is part of the proposed FFIgen changes for issue #63618.
/// In the real ffigen code-base (dart-lang/native/pkgs/ffigen), these classes
/// would live in `lib/src/header_parser/data.dart` alongside the existing
/// `ObjCMethod`, `Func`, and related model types.
library;

/// Availability information for a single OS platform, parsed from a libclang
/// `CXPlatformAvailability` struct.
///
/// Corresponds to one entry in the `API_AVAILABLE(...)` / `API_DEPRECATED(...)`
/// macro arguments, e.g. `ios(14.0)` or `macos(10.14, 12.0)`.
class PlatformAvailabilityData {
  /// Lowercase platform identifier, e.g. `'ios'`, `'macos'`, `'tvos'`.
  final String platform;

  /// Inclusive minimum OS version where the API is available.
  /// Formatted as `'MAJOR.MINOR'` (e.g. `'14.0'`).
  /// `null` if not specified.
  final String? min;

  /// Exclusive maximum (obsoleted) OS version — the API was removed at this
  /// version. Formatted as `'MAJOR.MINOR'`. `null` if still available.
  final String? max;

  /// Human-readable deprecation message from `API_DEPRECATED("msg", ...)`.
  /// `null` if the API is not deprecated, only introduced/removed.
  final String? deprecationMessage;

  /// Whether this platform is explicitly listed as unavailable via
  /// `API_UNAVAILABLE(ios)`, etc.
  final bool isUnavailable;

  const PlatformAvailabilityData({
    required this.platform,
    this.min,
    this.max,
    this.deprecationMessage,
    this.isUnavailable = false,
  });
}

/// Aggregated availability info for an ObjC/C declaration, covering all
/// platforms present in the header's availability macros.
///
/// This would be added as a nullable field `availability` on `ObjCMethod`,
/// `ObjCInterface`, `Func`, and `Struct` in ffigen's model classes.
class AvailabilityInfo {
  /// Platform-keyed availability data.
  /// Keys are lowercase platform identifiers: `'ios'`, `'macos'`, etc.
  final Map<String, PlatformAvailabilityData> platforms;

  const AvailabilityInfo(this.platforms);

  bool get isEmpty => platforms.isEmpty;
}
