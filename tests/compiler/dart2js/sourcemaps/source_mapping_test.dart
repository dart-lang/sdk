// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'sourcemap_helper.dart';
import 'sourcemap_html_helper.dart';
import 'package:compiler/src/filenames.dart';

main(List<String> arguments) {
  bool showAll = false;
  Uri outputUri;
  if (arguments.isNotEmpty) {
    outputUri = Uri.base.resolve(nativeToUriPath(arguments.last));
    showAll = arguments.contains('-a');
  }
  asyncTest(() async {
    String filename =
        'tests/compiler/dart2js/sourcemaps/invokes_test_file.dart';
    SourceMapProcessor processor = new SourceMapProcessor(filename);
    List<SourceMapInfo> infoList = await processor.process(
        ['--use-new-source-info', '--csp', '--disable-inlining']);
    List<SourceMapInfo> userInfoList = <SourceMapInfo>[];
    List<SourceMapInfo> failureList = <SourceMapInfo>[];
    for (SourceMapInfo info in infoList) {
      if (info.element.library.isPlatformLibrary) continue;
      userInfoList.add(info);
      Iterable<CodePoint> missingCodePoints =
          info.codePoints.where((c) => c.isMissing);
      if (!missingCodePoints.isEmpty) {
        print('Missing code points ${missingCodePoints} for '
              '${info.element} in $filename');
        failureList.add(info);
      }
    }
    if (failureList.isNotEmpty) {
      if (outputUri == null) {
        Expect.fail(
            "Missing code points found. "
            "Run the test with a URI option, `source_mapping_test <uri>`, to "
            "create a html visualization of the missing code points.");
      } else {
        createTraceSourceMapHtml(outputUri, processor,
                                 showAll ? userInfoList : failureList);
      }
    } else if (outputUri != null) {
      createTraceSourceMapHtml(outputUri, processor, userInfoList);
    }
  });
}
