// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'canonical_status_file.dart';

RegExp _underscoreTestEnd = RegExp(r"(^.*_test$)");
RegExp _underscoreTestDotDart = RegExp(r"(^.*_test.dart)");
RegExp _underscoreTestSlash = RegExp(r"(^.*_test)/");

bool isNonExistingEntry(Uri statusFileUri, StatusEntry entry) {
  if (entry.path.contains("*")) return false;

  var thirdPartyBase = Uri.base.resolve("third_party/");
  // skip "third_part/" --- e.g.
  // "third_party/pkg/native_toolchain_c.status" doesn't point as things
  // otherwise normally does.
  if (statusFileUri.path.startsWith(thirdPartyBase.path)) {
    return false;
  }

  String? path;
  for (var regexp in [
    _underscoreTestEnd,
    _underscoreTestDotDart,
    _underscoreTestSlash
  ]) {
    var matches = regexp.allMatches(entry.path);
    if (matches.length == 1) {
      path = matches.single[1]!;
      break;
    }
  }

  if (path == null) return false;
  var testPath = statusFileUri.resolveUri(Uri.file("$path.dart"));
  if (!File.fromUri(testPath).existsSync()) {
    return true;
  }
  return false;
}
