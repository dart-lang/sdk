// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Builds an index.html file in each folder containing entry points, if none
/// already exists. This file simply lists all the entry point files.
library polymer.src.build.index_page_builder;

import 'dart:async';
import 'dart:math';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

import 'common.dart';

/// Builds an index.html file in each folder containing entry points, if none
/// already exists. This file simply lists all the entry point files.
class IndexPageBuilder extends AggregateTransformer {
  final TransformOptions options;

  IndexPageBuilder(this.options);

  classifyPrimary(AssetId id) {
    if (!options.isHtmlEntryPoint(id)) return null;
    // Group all entry points together.
    return 'all_entry_points';
  }

  Future apply(AggregateTransform transform) {
    Map<String, List<String>> dirFilesMap = {};

    return transform.primaryInputs.toList().then((assets) {
      // Add the asset to its directory, and make sure its directory is included
      // in all its parents.
      for (var asset in assets) {
        var dir = path.url.dirname(asset.id.path);
        while (dir != '.') {
          dirFilesMap.putIfAbsent(dir, () => []);

          var relativePath = path.url.relative(asset.id.path, from: dir);
          var relativeDir = path.url.dirname(relativePath);
          dirFilesMap[dir].add(relativePath);
          dir = path.url.dirname(dir);
        }
      }

      // Create an output index.html file for each directory, if one doesn't
      // exist already
      var futures = [];
      dirFilesMap.forEach((directory, files) {
        futures.add(_createOutput(directory, files, transform));
      });
      return Future.wait(futures);
    });
  }

  Future _createOutput(
      String directory, List<String> files, AggregateTransform transform) {
    var indexAsset = new AssetId(
        transform.package, path.join(directory, 'index.html'));

    return transform.hasInput(indexAsset).then((exists) {
      // Don't overwrite existing outputs!
      if (exists) return;

      // Sort alphabetically by recursive path parts.
      files.sort((String a, String b) {
        var aParts = path.split(a);
        var bParts = path.split(b);
        int diff = 0;
        int minLength = min(aParts.length, bParts.length);
        for (int i = 0; i < minLength; i++) {
          // Directories are sorted below files.
          var aIsDir = i < aParts.length - 1;
          var bIsDir = i < bParts.length - 1;
          if (aIsDir && !bIsDir) return 1;
          if (!aIsDir && bIsDir) return -1;

          // Raw string comparison, if not identical we return.
          diff = aParts[i].compareTo(bParts[i]);
          if (diff != 0) return diff;
        }
        // Identical files, shouldn't happen in practice.
        return 0;
      });

      // Create the document with a list.
      var doc = new StringBuffer(
          '<!DOCTYPE html><html><body><h1>Entry points</h1><ul>');

      // Add all the assets to the list.
      for (var file in files) {
        doc.write('<li><a href="$file">$file</a></li>');
      };

      doc.write('</ul></body></html>');

      // Output the index.html file
      transform.addOutput(new Asset.fromString(indexAsset , doc.toString()));
    });
  }

}
