// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.all;

//import 'domain_context_test.dart' as domain_context_test;
import 'domain_server_test.dart' as domain_server_test;
import 'protocol_test.dart' as protocol_test;

main() {
  // domain_context_test.main();
  domain_server_test.main();
  protocol_test.main();
}
