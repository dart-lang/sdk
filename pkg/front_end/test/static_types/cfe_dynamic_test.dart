// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'analysis_helper.dart';

/// Filter function used to only analysis cfe source code.
bool cfeOnly(Uri uri) {
  String text = '$uri';
  for (String path in [
    'package:_fe_analyzer_shared/',
    'package:kernel/',
    'package:front_end/',
  ]) {
    if (text.startsWith(path)) {
      return true;
    }
  }
  return false;
}

main(List<String> args) async {
  await run(Uri.base.resolve('pkg/front_end/tool/_fasta/compile.dart'),
      'pkg/front_end/test/static_types/cfe_allowed.json',
      analyzedUrisFilter: cfeOnly,
      verbose: args.contains('-v'),
      generate: args.contains('-g'));
}
