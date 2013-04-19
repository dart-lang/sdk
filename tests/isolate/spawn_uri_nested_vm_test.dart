// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Example of nested spawning of isolates from a URI
// Note: the following comment is used by test.dart to additionally compile the
// other isolate's code.
// OtherScripts=spawn_uri_nested_child1_vm_isolate.dart spawn_uri_nested_child2_vm_isolate.dart
library NestedSpawnUriLibrary;
import 'dart:isolate';
import '../../pkg/unittest/lib/unittest.dart';

main() {
  test('isolate fromUri - nested send and reply', () {
    var port = spawnUri('spawn_uri_nested_child1_vm_isolate.dart');

    port.call([1, 2]).then((result) => print(result));
  });
}
