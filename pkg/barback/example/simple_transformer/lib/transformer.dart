// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:barback/barback.dart';

import 'dart:async';

class InsertCopyright extends Transformer {
  String copyright = "Copyright (c) 2014, the Example project authors.\n";

  // A constructor named "asPlugin" is required. It can be empty, but
  // it must be present. It is how pub determines that you want this
  // class to be publicly available as a loadable transformer plugin.
  InsertCopyright.asPlugin();

  Future<bool> isPrimary(AssetId id) {
    return new Future.value(id.extension == '.txt');
  }

  Future apply(Transform transform) {
    return transform.primaryInput.readAsString().then((content) {
      var id = transform.primaryInput.id;
      String newContent = copyright + content;
      transform.addOutput(new Asset.fromString(id, newContent));
    });
  }
}
