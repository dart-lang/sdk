// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/element_usage_detector.dart';
import 'package:analyzer/src/error/listener.dart';

/// Normalizes a deprecation message in preparation for presenting it to the
/// user.
///
/// The following normalizations are performed:
/// - If the message is the empty string, or the single character `.`, `null` is
///   returned. This represents no message at all.
/// - If the message doesn't end with `.`, `?`, or `!`, a `.` is appended.
String? normalizeDeprecationMessage(String message) {
  message = message.trim();
  if (message.isEmpty || message == '.') {
    return null;
  } else if (message.endsWith('.') ||
      message.endsWith('?') ||
      message.endsWith('!')) {
    return message;
  } else {
    return '$message.';
  }
}

/// Instance of [ElementUsageReporter] for reporting uses of deprecated
/// elements.
class DeprecatedElementUsageReporter implements ElementUsageReporter<String> {
  final DiagnosticReporter _diagnosticReporter;

  DeprecatedElementUsageReporter({
    required DiagnosticReporter diagnosticReporter,
  }) : _diagnosticReporter = diagnosticReporter;

  @override
  void report(
    SyntacticEntity usageSite,
    String displayName,
    String tagInfo, {
    required bool isInSamePackage,
  }) {
    if (isInSamePackage) return;
    if (normalizeDeprecationMessage(tagInfo) case var message?) {
      _diagnosticReporter.report(
        diag.deprecatedMemberUseWithMessage
            .withArguments(name: displayName, details: message)
            .at(usageSite),
      );
    } else {
      _diagnosticReporter.report(
        diag.deprecatedMemberUse.withArguments(name: displayName).at(usageSite),
      );
    }
  }
}

/// Instance of [ElementUsageSet] for deprecated elements.
class DeprecatedElementUsageSet implements ElementUsageSet<String> {
  const DeprecatedElementUsageSet();

  /// The message in the deprecated annotation on the given [element], or
  /// the empty string if the annotation does not have a message, or `null` if
  /// the element doesn't have a deprecated annotation.
  @override
  String? getTagInfo(Element element) {
    for (var annotation in element.metadata.annotations) {
      if (!annotation.isDeprecated) continue;
      var value = annotation.computeConstantValue();
      if (value == null) continue;
      var kindValue = value.getField('_kind');
      if (kindValue != null) {
        var kind = kindValue.getField('_name')?.toStringValue();
        if (kind != 'use') continue;
      }
      if (annotation.element is PropertyAccessorElement) {
        // `@deprecated` is treated as though it had no message, even though the
        // message is `next release`.
        // TODO(paulberry): consider whether it be better to just treat the
        // string `next release` as equivalent to the empty message.
        return '';
      }
      return value.getField('message')?.toStringValue() ??
          value.getField('expires')?.toStringValue() ??
          '';
    }
    return null;
  }
}
