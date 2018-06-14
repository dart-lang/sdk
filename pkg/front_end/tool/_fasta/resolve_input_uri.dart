// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Resolve [string] as a [Uri].  If the input [string] starts with a supported
/// scheme, it is resolved as a Uri of that scheme, otherwise the [string]
/// is treated as a file system (possibly relative) path.
///
/// Three schemes are always supported by default: `dart`, `package`, and
/// `data`. Additional supported schemes can be specified via [extraSchemes].
Uri resolveInputUri(String string, {List<String> extraSchemes: const []}) {
  if (string.startsWith('dart:')) return Uri.parse(string);
  if (string.startsWith('data:')) return Uri.parse(string);
  if (string.startsWith('package:')) return Uri.parse(string);
  for (var scheme in extraSchemes) {
    if (string.startsWith('$scheme:')) return Uri.parse(string);
  }
  return Uri.base.resolveUri(new Uri.file(string));
}
