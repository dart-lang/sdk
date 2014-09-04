// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Final phase of the polymer transformation: removes any files that are not
/// needed for deployment.
library polymer.src.build.build_filter;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:code_transformers/messages/build_logger.dart';
import 'common.dart';

/// Removes any files not needed for deployment, such as internal build
/// artifacts and non-entry HTML files.
class BuildFilter extends Transformer with PolymerTransformer {
  final TransformOptions options;
  BuildFilter(this.options);

  isPrimary(AssetId id) {
    // nothing is filtered in debug mode
    return options.releaseMode &&
      // TODO(sigmund): remove this exclusion once we have dev_transformers
      // (dartbug.com/14187)
      !id.path.startsWith('lib/') &&
      // may filter non-entry HTML files and internal artifacts
      (id.extension == '.html' || id.extension == _DATA_EXTENSION) &&
      // keep any entry points
      !options.isHtmlEntryPoint(id);
  }

  apply(Transform transform) {
    transform.consumePrimary();
    if (transform.primaryInput.id.extension == _DATA_EXTENSION) {
      return null;
    }
    var logger = new BuildLogger(transform,
        convertErrorsToWarnings: !options.releaseMode);
    return readPrimaryAsHtml(transform, logger).then((document) {
      // Keep .html files that don't use polymer, since the app developer might
      // have non-polymer entrypoints.
      if (document.querySelectorAll('polymer-element').isEmpty) {
        transform.addOutput(transform.primaryInput);
      }
    });
  }
}

const String _DATA_EXTENSION = '._data';
