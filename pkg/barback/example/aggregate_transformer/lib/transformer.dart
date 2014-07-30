// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:barback/barback.dart';
import 'package:path/path.dart' as p;

import 'dart:async';

class MakeBook extends AggregateTransformer {
  // All transformers need to implement "asPlugin" to let Pub know that they
  // are transformers.
  MakeBook.asPlugin();

  // Implement the classifyPrimary method to claim any assets that you want
  // to handle. Return a value for the assets you want to handle,
  // or null for those that you do not want to handle.
  classifyPrimary(AssetId id) {
    // Only process assets where the filename ends with "recipe.html".
    if (!id.path.endsWith('recipe.html')) return null;

    // Return the path string, minus the recipe itself.
    // This is where the output asset will be written.
    return p.url.dirname(id.path);
  }

  // Implement the apply method to process the assets and create the
  // output asset.
  Future apply(AggregateTransform transform) {
    var buffer = new StringBuffer()..write('<html><body>');
 
    return transform.primaryInputs.toList().then((assets) {
      // The order of [transform.primaryInputs] is not guaranteed
      // to be stable across multiple runs of the transformer.
      // Therefore, we alphabetically sort the assets by ID string.
      assets.sort((x, y) => x.id.compareTo(y.id));
      return Future.wait(assets.map((asset) {
        return asset.readAsString().then((content) {
          buffer.write(content);
          buffer.write('<hr>');
        });
      }));
    }).then((_) {
      buffer.write('</body></html>');
      // Write the output back to the same directory,
      // in a file named recipes.html.
      var id = new AssetId(transform.package,
                           p.url.join(transform.key, ".recipes.html"));
      transform.addOutput(new Asset.fromString(id, buffer.toString()));
    });
  }
}

