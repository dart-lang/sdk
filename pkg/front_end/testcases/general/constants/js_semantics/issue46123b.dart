// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:js/js.dart';

@JS()
@anonymous
class ParallaxOptions {
  external const ParallaxOptions();
}

test() => const ParallaxOptions();

main() {}
