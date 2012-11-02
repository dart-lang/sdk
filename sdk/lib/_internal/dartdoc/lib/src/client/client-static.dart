// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Provides client-side behavior for generated docs using the static mode. */
library client_static;

import 'dart:html';
import 'dart:json';
import '../../../../compiler/implementation/source_file.dart';
// TODO(rnystrom): Use "package:" URL (#4968).
import '../../classify.dart';

// TODO(rnystrom): Use "package:" URL (#4968).
part 'dropdown.dart';
part 'search.dart';
part '../dartdoc/nav.dart';
part 'client-shared.dart';
part '../../../tmp/nav.dart';

main() {
  setup();
  setupSearch(json);
}
