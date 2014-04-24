// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.has_input;

import 'dart:async';

import 'package:barback/barback.dart';

import 'mock.dart';

/// Overwrites its primary inputs with descriptions of whether various secondary
/// inputs exist.
class HasInputTransformer extends MockTransformer {
  /// The inputs whose existence will be checked.
  final List<AssetId> inputs;

  HasInputTransformer(Iterable<String> inputs)
      : inputs = inputs.map((input) => new AssetId.parse(input)).toList();

  bool doIsPrimary(AssetId id) => true;

  Future doApply(Transform transform) {
    return Future.wait(inputs.map((input) {
      return transform.hasInput(input).then((hasInput) => "$input: $hasInput");
    })).then((results) {
      transform.addOutput(new Asset.fromString(
          transform.primaryInput.id, results.join(', ')));
    });
  }

  String toString() => "has inputs $inputs";
}
