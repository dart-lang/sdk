// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.check_content_and_rename;

import 'dart:async';

import 'package:barback/barback.dart';

import 'mock.dart';

/// A transformer that checks the extension and content of an asset, then
/// produces a new asset with a new extension and new content.
class CheckContentAndRenameTransformer extends MockTransformer {
  final String oldExtension;
  final String oldContent;
  final String newExtension;
  final String newContent;

  CheckContentAndRenameTransformer(this.oldExtension, this.oldContent,
      this.newExtension, this.newContent);

  Future<bool> doIsPrimary(Asset asset) {
    if (asset.id.extension != '.$oldExtension') return new Future.value(false);
    return asset.readAsString().then((value) => value == oldContent);
  }

  Future doApply(Transform transform) {
    return getPrimary(transform).then((input) {
      transform.addOutput(new Asset.fromString(
          input.id.changeExtension('.$newExtension'), newContent));
    });
  }
}
