// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final _dartdocCodeBlockSections = RegExp(r'(```\w+) +\w+');
final _dartdocDirectives =
    RegExp(r'(\n *{@.*?}$)|(^{@.*?}\n)', multiLine: true);

String cleanDartdoc(String doc) {
  if (doc == null) {
    return null;
  }
  // Remove any dartdoc directives like {@template xxx}
  doc = doc.replaceAll(_dartdocDirectives, '');

  // Remove any code block section names like ```dart preamble that Flutter
  // docs contain.
  doc = doc.replaceAllMapped(
    _dartdocCodeBlockSections,
    (match) => match.group(1),
  );

  return doc;
}
