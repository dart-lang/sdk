// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.asset.serialize.get_input_transform;

import 'dart:async';
import 'dart:convert';

import 'package:barback/barback.dart';

import '../utils.dart';

/// A mixin for transforms that support [getInput] and the associated suite of
/// methods.
abstract class GetInputTransform {
  Future<Asset> getInput(AssetId id);

  Future<String> readInputAsString(AssetId id, {Encoding encoding}) {
    if (encoding == null) encoding = UTF8;
    return getInput(id).then((input) =>
        input.readAsString(encoding: encoding));
  }

  Stream<List<int>> readInput(AssetId id) =>
      futureStream(getInput(id).then((input) => input.read()));

  Future<bool> hasInput(AssetId id) {
    return getInput(id).then((_) => true).catchError((error) {
      if (error is AssetNotFoundException && error.id == id) return false;
      throw error;
    });
  }
}
