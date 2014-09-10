// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:barback/barback.dart';

import 'dart:async';

class CodedMessageConverter extends Transformer 
                            implements LazyTransformer {

  // A constructor named "asPlugin" is required. It can be empty, but
  // it must be present.
  CodedMessageConverter.asPlugin();

  Future<bool> isPrimary(AssetId id) {
    return new Future.value(id.extension == '.txt');
  }

  Future declareOutputs(DeclaringTransform transform) {
    return new Future.value(transform.primaryId.changeExtension('.shhhhh'));
  }

  Future apply(Transform transform) {
    return transform.primaryInput.readAsString().then((content) {

      // The output file is created with the '.shhhhh' extension.
      var id = transform.primaryInput.id.changeExtension('.shhhhh');

      StringBuffer newContent = new StringBuffer();
      for (int i = 0; i < content.length; i++ ) {
        newContent.write(rot13(content[i]));
      }
      transform.addOutput(new Asset.fromString(id, newContent.toString()));
    });
  }

  rot13(var ch) {
    var c = ch.codeUnitAt(0);
    if      (c >= 'a'.codeUnitAt(0) && c <= 'm'.codeUnitAt(0)) c += 13;
    else if (c >= 'A'.codeUnitAt(0) && c <= 'M'.codeUnitAt(0)) c += 13;
    else if (c >= 'n'.codeUnitAt(0) && c <= 'z'.codeUnitAt(0)) c -= 13;
    else if (c >= 'N'.codeUnitAt(0) && c <= 'Z'.codeUnitAt(0)) c -= 13;
    return new String.fromCharCode(c);
  }
}
