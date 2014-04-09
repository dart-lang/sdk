// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:barback/barback.dart';
import 'package:markdown/markdown.dart';

import 'dart:async';

class ConvertMarkdown extends Transformer {

  // A constructor named "asPlugin" is required. It can be empty, but
  // it must be present. It is how pub determines that you want this
  // class to be publicly available as a loadable transformer plugin.
  ConvertMarkdown.asPlugin();

  // Any markdown file with one of the following extensions is
  // converted to HTML.
  String get allowedExtensions => ".md .markdown .mdown";

  Future apply(Transform transform) {
    return transform.primaryInput.readAsString().then((content) {

      // The extension of the output is changed to ".html".
      var id = transform.primaryInput.id.changeExtension(".html");

      String newContent = "<html><body>"
                        + markdownToHtml(content)
                        + "</body></html>";
      transform.addOutput(new Asset.fromString(id, newContent));
    });
  }
}
