// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyze_api;

import "package:expect/expect.dart";
import '../../../sdk/lib/_internal/compiler/implementation/filenames.dart';
import 'analyze_helper.dart';

/**
 * Map of white-listed warnings and errors.
 *
 * Only add a white-listing together with a bug report to dartbug.com and add
 * the bug issue number as a comment on the white-listing.
 *
 * Use an identifiable suffix of the file uri as key. Use a fixed substring of
 * the error/warning message in the list of white-listings for each file.
 */
// TODO(johnniwinther): Support canonical URIs as keys and message kinds as
// values.
const Map<String,List<String>> WHITE_LIST = const {
};

void main() {
  var uri = currentDirectory.resolve(
      'sdk/lib/_internal/compiler/implementation/dart2js.dart');
  analyze([uri], WHITE_LIST);
}
