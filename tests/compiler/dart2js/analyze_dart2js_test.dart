// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyze_api;

import "package:expect/expect.dart";
import '../../../sdk/lib/_internal/compiler/implementation/filenames.dart';
import 'analyze_helper.dart';
import "package:async_helper/async_helper.dart";

/**
 * Map of whitelisted warnings and errors.
 *
 * Only add a whitelisting together with a bug report to dartbug.com and add
 * the bug issue number as a comment on the whitelisting.
 *
 * Use an identifiable suffix of the file uri as key. Use a fixed substring of
 * the error/warning message in the list of whitelistings for each file.
 */
// TODO(johnniwinther): Support canonical URIs as keys and message kinds as
// values.
const Map<String,List<String>> WHITE_LIST = const {
  '/list.dart':
      const ["Warning: 'typedef' not allowed here"],  // dartbug.com/13907
  '/stream_controller.dart':
      const ["Warning: 'typedef' not allowed here"],  // dartbug.com/13907
};

void main() {
  var uri = currentDirectory.resolve(
      'sdk/lib/_internal/compiler/implementation/dart2js.dart');
  asyncTest(() => analyze([uri], WHITE_LIST));
}
