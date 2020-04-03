// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/relativize.dart';
import 'package:expect/expect.dart' show Expect;
import 'package:front_end/src/fasta/resolve_input_uri.dart';

test() {
  // data URI scheme is supported by default'.
  Expect.stringEquals('data', resolveInputUri('data:,foo').scheme);

  // Custom Dart schemes are recognized by default.
  Expect.stringEquals('dart', resolveInputUri('dart:foo').scheme);
  Expect.stringEquals('package', resolveInputUri('package:foo').scheme);

  // Unknown schemes are recognized by default.
  Expect.stringEquals(
      isWindows ? 'file' : 'c', resolveInputUri('c:/foo').scheme);
  Expect.stringEquals('test', resolveInputUri('test:foo').scheme);
  Expect.stringEquals(
      'org-dartlang-foo', resolveInputUri('org-dartlang-foo:bar').scheme);
  Expect.stringEquals('test', resolveInputUri('test:/foo').scheme);
  Expect.stringEquals(
      'org-dartlang-foo', resolveInputUri('org-dartlang-foo:/bar').scheme);
  Expect.stringEquals(
      "${Uri.base.resolve('file.txt')}", "${resolveInputUri('file:file.txt')}");
}

main() {
  // Test platform default.
  test();
  // Test non-Windows behavior.
  isWindows = false;
  test();
  // Test Windows behavior.
  isWindows = true;
  test();
}
