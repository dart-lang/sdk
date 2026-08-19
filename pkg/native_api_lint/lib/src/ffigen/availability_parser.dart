// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Demonstrates how FFIgen's header_parser would extract availability
/// information from libclang AST cursors.
///
/// In the real ffigen code-base (dart-lang/native/pkgs/ffigen), this logic
/// would be integrated into:
///   - `lib/src/header_parser/sub_parsers/objcinterfacedecl_parser.dart`
///   - `lib/src/header_parser/sub_parsers/functiondecl_parser.dart`
///
/// The key libclang APIs used are:
///   - `clang_getCursorAvailability()`       — overall availability status
///   - `clang_getCursorPlatformAvailability()` — per-platform details
///   - `clang_disposeCXPlatformAvailability()` — cleanup
///
/// These are already accessible through the existing dart:ffi libclang bindings
/// in `lib/src/header_parser/clang_bindings/`.
///
/// ---
/// This file is a **documented reference implementation** showing the exact
/// Dart FFI code that would be added. It is not meant to be run standalone.
library;

import 'availability_data.dart';

// ---------------------------------------------------------------------------
// The following `clang_types` and `clang` references mirror the existing
// auto-generated libclang bindings in ffigen's own codebase. In the real
// implementation they are imported as:
//   import '../clang_bindings/clang_types.dart';
//   import '../clang_bindings/clang_bindings.dart';
// ---------------------------------------------------------------------------

/// Extracts OS-level availability info from a libclang AST cursor.
///
/// Call this after visiting any `CXCursor_ObjCInstanceMethodDecl`,
/// `CXCursor_ObjCClassMethodDecl`, `CXCursor_ObjCInterfaceDecl`,
/// `CXCursor_FunctionDecl`, or `CXCursor_StructDecl`.
///
/// Returns `null` if the cursor has no availability attributes.
///
/// ```dart
/// // In objcinterfacedecl_parser.dart visitObjCMethodDecl:
/// final avail = extractAvailability(cursor);
/// objcMethod.availability = avail;  // new nullable field on ObjCMethod
/// ```
// ignore: unused_element
AvailabilityInfo? _extractAvailability(dynamic cursor) {
  // Step 1: Quick check — does this cursor have any availability attribute?
  // clang_getCursorAvailability returns one of:
  //   CXAvailability_Available (0), CXAvailability_Deprecated (1),
  //   CXAvailability_NotAvailable (2), CXAvailability_NotAccessible (3)
  //
  // If it's CXAvailability_Available with no platform restrictions, we can
  // skip the expensive per-platform call.
  //
  // final availability = clang.clang_getCursorAvailability(cursor);
  // if (availability == CXAvailabilityKind.CXAvailability_Available) {
  //   // Could still have platform-specific attributes — check count.
  // }

  // Step 2: Count platform availability entries.
  //
  // Signature:
  //   int clang_getCursorPlatformAvailability(
  //     CXCursor cursor,
  //     Pointer<Int32> always_deprecated,
  //     Pointer<CXString> deprecated_message,
  //     Pointer<Int32> always_unavailable,
  //     Pointer<CXString> unavailable_message,
  //     Pointer<CXPlatformAvailability> availability,
  //     int availability_size,
  //   );
  //
  // Calling with availability_size=0 returns the total count without filling.
  //
  // final count = clang.clang_getCursorPlatformAvailability(
  //   cursor,
  //   nullptr, nullptr, nullptr, nullptr,
  //   nullptr, 0,
  // );
  // if (count == 0) return null;

  // Step 3: Allocate and fill platform availability structs.
  //
  // final infos = calloc<clang_types.CXPlatformAvailability>(count);
  // clang.clang_getCursorPlatformAvailability(
  //   cursor,
  //   nullptr, nullptr, nullptr, nullptr,
  //   infos, count,
  // );

  // Step 4: Convert each CXPlatformAvailability to PlatformAvailabilityData.
  //
  // final result = <String, PlatformAvailabilityData>{};
  // for (var i = 0; i < count; i++) {
  //   final info = infos[i];
  //   final platform = info.Platform.string.toLowerCase();
  //   result[platform] = PlatformAvailabilityData(
  //     platform: platform,
  //     min: _versionString(info.Introduced),   // CXVersion {Major, Minor, Subminor}
  //     max: _versionString(info.Obsoleted),
  //     deprecationMessage: info.Message.string.isEmpty
  //         ? null : info.Message.string,
  //     isUnavailable: info.Unavailable != 0,
  //   );
  //   clang.clang_disposeCXPlatformAvailability(infos + i);
  // }
  // calloc.free(infos);
  // return result.isEmpty ? null : AvailabilityInfo(result);

  return null; // placeholder — real impl uses FFI above
}

/// Converts a libclang `CXVersion` struct to a human-readable version string.
///
/// Returns `null` if the version is the sentinel `{-1, -1, -1}` (absent).
// ignore: unused_element
String? _versionString(dynamic version) {
  // CXVersion has fields: Major (int), Minor (int), Subminor (int).
  // All fields are -1 when the version component is absent.
  //
  // final major = version.Major;
  // if (major < 0) return null;
  // final minor = version.Minor;
  // if (minor < 0) return '$major';
  // final sub = version.Subminor;
  // if (sub <= 0) return '$major.$minor';
  // return '$major.$minor.$sub';
  return null;
}
