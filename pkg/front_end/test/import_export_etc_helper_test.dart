// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/util/import_export_etc_helper.dart';

void main() {
  // Simple imports.
  expect(
      getFileInfoHelperFromString("""
import "foo.dart";
import "bar.dart";
""").getContent(),
      """
Imports:
 - foo.dart
 - bar.dart
"""
          .trim());

  // "Advanced" imports.
  expect(
      getFileInfoHelperFromString("""
import "foo"
            ".dart";
import '''
bar.dart''';
""").getContent(),
      """
Imports:
 - foo.dart
 - bar.dart
"""
          .trim());

  // Simple exports.
  expect(
      getFileInfoHelperFromString("""
export "foo.dart";
export "bar.dart";
""").getContent(),
      """
Exports:
 - foo.dart
 - bar.dart
"""
          .trim());

  // "Advanced" exports.
  expect(
      getFileInfoHelperFromString("""
export "foo"
".dart";
export '''
bar.dart''';
""").getContent(),
      """
Exports:
 - foo.dart
 - bar.dart
"""
          .trim());

  // Simple parts.
  expect(
      getFileInfoHelperFromString("""
part "foo.dart";
part "bar.dart";
""").getContent(),
      """
Parts:
 - foo.dart
 - bar.dart
"""
          .trim());

  // "Advanced" parts.
  expect(
      getFileInfoHelperFromString("""
part "foo"
".dart";
part '''
bar.dart''';
""").getContent(),
      """
Parts:
 - foo.dart
 - bar.dart
"""
          .trim());

  // Simple part of uri.
  expect(
      getFileInfoHelperFromString("""
part of "foo.dart";
""").getContent(),
      """
Part of uris:
 - foo.dart
"""
          .trim());

  // "Advanced" part of uri.
  expect(
      getFileInfoHelperFromString("""
part of "foo"
".dart";
part of '''
bar.dart''';
""").getContent(),
      """
Part of uris:
 - foo.dart
 - bar.dart
"""
          .trim());

  // Simple part of name.
  expect(
      getFileInfoHelperFromString("""
part of foo.bar.baz;
""").getContent(),
      """
Part of identifiers:
 - foo.bar.baz
"""
          .trim());

  // "Advanced" part of name.
  expect(
      getFileInfoHelperFromString("""
part of foo
.
bar
.
baz;
""").getContent(),
      """
Part of identifiers:
 - foo.bar.baz
"""
          .trim());

  // Simple library with name
  expect(
      getFileInfoHelperFromString("""
library foo.bar.baz;
""").getContent(),
      """
Library names:
 - foo.bar.baz
"""
          .trim());

  // "Advanced" library with name
  expect(
      getFileInfoHelperFromString("""
library

foo
.

bar
.baz;
""").getContent(),
      """
Library names:
 - foo.bar.baz
"""
          .trim());

  // Library without name
  expect(
      getFileInfoHelperFromString("""
library;
""").getContent(),
      """
"""
          .trim());

  // Weird combination
  expect(
      getFileInfoHelperFromString("""
import "foo.dart";
export "foo.dart";
export "bar.dart";
import "bar.dart";
import "foo"
            ".dart";
export "foo"
".dart";
export '''
bar.dart''';
import '''
bar.dart''';

part "foo.dart";
part "bar.dart";

part "foo"
".dart";
part '''
bar.dart''';

part of "foo.dart";

part of "foo"
".dart";
part of '''
bar.dart''';

part of foo;
part of foo.bar;
part of foo.bar.baz;
part of foo
.bar;
part of foo
.
bar
.
baz;

library foo.bar.baz;
library foo.bar;

library

foo
.bar    .baz;

library;
library;
library;
library;
library;

""").getContent(),
      """
Imports:
 - foo.dart
 - bar.dart
 - foo.dart
 - bar.dart
Exports:
 - foo.dart
 - bar.dart
 - foo.dart
 - bar.dart
Parts:
 - foo.dart
 - bar.dart
 - foo.dart
 - bar.dart
Part of uris:
 - foo.dart
 - foo.dart
 - bar.dart
Part of identifiers:
 - foo
 - foo.bar
 - foo.bar.baz
 - foo.bar
 - foo.bar.baz
Library names:
 - foo.bar.baz
 - foo.bar
 - foo.bar.baz
"""
          .trim());
}

void expect(Object? actual, Object? expect) {
  if (expect != actual) throw "Expected '$expect' got '$actual'";
}
