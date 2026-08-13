// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/commandline_options.dart';

import 'deferred_load_id_map_helper.dart';

main(List<String> args) {
  mainHelper('simple_ids', 0, const [Flags.useSimpleLoadIds], args);
}
