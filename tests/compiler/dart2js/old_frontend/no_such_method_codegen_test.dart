// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The mock compiler of dart2js used to make the compiler crash on
// this program.
//
// The SSA backend generates a call to a throwNoSuchMethod helper for
// the access to `foo`, and we used to not infer return types of
// helpers, so we did not know throwNoSuchMethod was not returning.
// As a consequence, all operator[] had to be compiled, and due to
// missing backend dependencies, some of them were not resolved.

import '../compiler_helper.dart';

const String TEST = '''
main() => foo[42];
''';

main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = mockCompilerFor(TEST, uri);
  compiler.run(uri);
}
