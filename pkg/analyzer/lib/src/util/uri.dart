// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart';

String fileUriToNormalizedPath(Context context, Uri fileUri) {
  assert(fileUri.isScheme('file'));
  var path = context.fromUri(fileUri);
  path = context.normalize(path);
  return path;
}
