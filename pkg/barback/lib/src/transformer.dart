// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transformer;

import 'dart:async';

import 'asset_id.dart';
import 'transform.dart';
import 'utils.dart';

/// A [Transformer] represents a processor that takes in one or more input
/// assets and uses them to generate one or more output assets.
///
/// Dart2js, a SASS->CSS processor, a CSS spriter, and a tool to concatenate
/// files are all examples of transformers. To define your own transformation
/// step, extend (or implement) this class.
///
/// If possible, transformers should implement [DeclaringTransformer] as well to
/// help barback optimize the package graph.
abstract class Transformer {
  /// Override this to return a space-separated list of file extensions that are
  /// allowed for the primary inputs to this transformer.
  ///
  /// Each extension must begin with a leading `.`.
  ///
  /// If you don't override [isPrimary] yourself, it defaults to allowing any
  /// asset whose extension matches one of the ones returned by this. If you
  /// don't override [isPrimary] *or* this, it allows all files.
  String get allowedExtensions => null;

  Transformer() {
    if (allowedExtensions == null) return;

    var invalidExtensions = allowedExtensions.split(" ")
        .where((extension) => !extension.startsWith("."))
        .map((extension) => '"$extension"');
    if (invalidExtensions.isEmpty) return;

    throw new FormatException('Each extension in $this.allowedExtensions '
        'must begin with a ".", but ${toSentence(invalidExtensions)} '
        '${pluralize("doesn't", invalidExtensions.length, plural: "don't")}.');
  }

  /// Returns `true` if [id] can be a primary input for this transformer.
  ///
  /// While a transformer can read from multiple input files, one must be the
  /// "primary" input. This asset determines whether the transformation should
  /// be run at all. If the primary input is removed, the transformer will no
  /// longer be run.
  ///
  /// A concrete example is dart2js. When you run dart2js, it will traverse
  /// all of the imports in your Dart source files and use the contents of all
  /// of those to generate the final JS. However you still run dart2js "on" a
  /// single file: the entrypoint Dart file that has your `main()` method.
  /// This entrypoint file would be the primary input.
  ///
  /// If this is not overridden, defaults to allow any asset whose extension
  /// matches one of the ones returned by [allowedExtensions]. If *that* is
  /// not overridden, allows all assets.
  Future<bool> isPrimary(AssetId id) {
    // Allow all files if [primaryExtensions] is not overridden.
    if (allowedExtensions == null) return new Future.value(true);

    for (var extension in allowedExtensions.split(" ")) {
      if (id.path.endsWith(extension)) return new Future.value(true);
    }

    return new Future.value(false);
  }

  /// Run this transformer on on the primary input specified by [transform].
  ///
  /// The [transform] is used by the [Transformer] for two purposes (in
  /// addition to accessing the primary input). It can call `getInput()` to
  /// request additional input assets. It also calls `addOutput()` to provide
  /// generated assets back to the system. Either can be called multiple times,
  /// in any order.
  ///
  /// In other words, a Transformer's job is to find all inputs for a
  /// transform, starting at the primary input, then generate all output assets
  /// and yield them back to the transform.
  Future apply(Transform transform);

  String toString() => runtimeType.toString().replaceAll("Transformer", "");
}
