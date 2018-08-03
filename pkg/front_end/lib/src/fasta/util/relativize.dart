// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.util.relativize;

// TODO(ahe): Move more advanced version from dart2js here.

final Uri currentDirectory = Uri.base;

String relativizeUri(Uri uri, {Uri base}) {
  if (uri == null) return null;
  base ??= currentDirectory;
  String result = "$uri";
  final prefix = "$base";
  return result.startsWith(prefix) ? result.substring(prefix.length) : result;
}
