// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Shows how FFIgen's code generator would emit `@ExternalVersions` annotations
/// into the generated Dart output.
///
/// In the real ffigen code-base (dart-lang/native/pkgs/ffigen), this logic
/// would be added to:
///   - `lib/src/code_generator/objc_interface.dart`   (ObjC methods/classes)
///   - `lib/src/code_generator/func.dart`             (C functions)
///   - `lib/src/code_generator/struct.dart`           (C structs)
///
/// The generator already uses a `StringBuffer`-based writer that emits Dart
/// source. The changes are minimal — just check for a non-null `availability`
/// field and prepend the annotation.
library;

import 'availability_data.dart';

/// Emits a `@ExternalVersions({...})` annotation string for inclusion in
/// ffigen's Dart code output.
///
/// Returns an empty string if [info] is null or empty.
///
/// Example output for `API_AVAILABLE(ios(14.0)) API_DEPRECATED("use bar", macos(10.14, 12.0))`:
///
/// ```dart
/// @ExternalVersions({
///   'ios': ExternalVersion(min: '14.0'),
///   'macos': ExternalVersion(min: '10.14', max: '12.0', deprecationMessage: 'use bar'),
/// })
/// ```
///
/// In the real ffigen generator the call site would be:
/// ```dart
/// // In ObjcInterface.generateMethodBindings() / Func.generate():
/// if (method.availability case final avail? when !avail.isEmpty) {
///   writer.write(emitAvailabilityAnnotation(avail));
/// }
/// ```
String emitAvailabilityAnnotation(AvailabilityInfo? info) {
  if (info == null || info.isEmpty) return '';

  final buf = StringBuffer();
  buf.writeln('@ExternalVersions({');

  final sorted = info.platforms.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  for (final entry in sorted) {
    final platform = entry.key;
    final v = entry.value;

    final args = <String>[];
    if (v.min != null) args.add("min: '${v.min}'");
    if (v.max != null) args.add("max: '${v.max}'");
    if (v.deprecationMessage != null) {
      // Escape single quotes in the deprecation message.
      final escaped = v.deprecationMessage!.replaceAll("'", r"\'");
      args.add("deprecationMessage: '$escaped'");
    }

    buf.write("  '$platform': ExternalVersion(");
    buf.write(args.join(', '));
    buf.writeln('),');
  }

  buf.writeln('})');
  return buf.toString();
}
