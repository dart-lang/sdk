// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.translate_uri;

import 'dart:async' show
    Future;

import 'dart:io' show
    File;

import 'package:package_config/packages_file.dart' as packages_file show
    parse;

import 'errors.dart' show
    internalError;

class TranslateUri {
  final Map<String, Uri> packages;

  TranslateUri(this.packages);

  Uri translate(Uri uri) {
    if (uri.scheme == "dart") return translateDartUri(uri);
    if (uri.scheme == "package") return translatePackageUri(uri);
    return null;
  }

  Uri translateDartUri(Uri uri) {
    throw internalError("dart: URIs not implemented yet.");
  }

  Uri translatePackageUri(Uri uri) {
    int index = uri.path.indexOf("/");
    if (index == -1) return null;
    String name = uri.path.substring(0, index);
    String path = uri.path.substring(index + 1);
    Uri root = packages[name];
    if (root == null) return null;
    return root.resolve(path);
  }

  static Future<TranslateUri> parse([Uri uri]) async {
    uri ??= Uri.base.resolve(".packages");
    File file = new File.fromUri(uri);
    List<int> bytes = await file.readAsBytes();
    Map<String, Uri> packages = packages_file.parse(bytes, uri);
    return new TranslateUri(packages);
  }
}
