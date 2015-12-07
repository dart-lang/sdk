// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart;

import 'package:unittest/unittest.dart';

import '../../../utils.dart';
import 'combinator_contributor_test.dart' as combinator_test;
import 'arglist_contributor_test.dart' as arglist_test;
import 'common_usage_sorter_test.dart' as common_usage_test;
import 'field_formal_contributor_test.dart' as field_formal_contributor_test;
import 'inherited_contributor_test.dart' as inherited_contributor_test;
import 'keyword_contributor_test.dart' as keyword_test;
import 'uri_contributor_test.dart' as uri_contributor_test;

/// Utility for manually running all tests.
main() {
  initializeTestEnvironment();
  group('dart/completion', () {
    arglist_test.main();
    combinator_test.main();
    common_usage_test.main();
    field_formal_contributor_test.main();
    inherited_contributor_test.main();
    keyword_test.main();
    uri_contributor_test.main();
  });
}
