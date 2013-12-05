// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyze_api;

import '../../../sdk/lib/_internal/libraries.dart';
import 'analyze_helper.dart';
import "package:async_helper/async_helper.dart";

/**
 * Map of white-listed warnings and errors.
 *
 * Only add a white-listing together with a bug report to dartbug.com and add
 * the bug issue number as a comment on the white-listing.
 *
 * Use an identifiable suffix of the file uri as key. Use a fixed substring of
 * the error/warning message in the list of white-listings for each file.
 */
// TODO(johnniwinther): Support canonical URIs as keys and message kinds as
// values.
const Map<String, List<String>> WHITE_LIST = const {
  // The following notices go away when bugs 15417 is fixed.
  "sdk/lib/core/map.dart": const [
      "Info: This is the method declaration."],

  // Bug 15417.
  "sdk/lib/html/dart2js/html_dart2js.dart": const ["""
Warning: '_DataAttributeMap' doesn't implement 'addAll'.
Try adding an implementation of 'addAll'.""", """
Warning: '_NamespacedAttributeMap' doesn't implement 'addAll'.
Try adding an implementation of 'addAll'.""", """
Warning: '_ElementAttributeMap' doesn't implement 'addAll'.
Try adding an implementation of 'addAll'.""", """
Warning: 'Window' doesn't implement 'clearInterval'.
Try adding an implementation of 'clearInterval'.""", """
Warning: 'Window' doesn't implement 'clearTimeout'.
Try adding an implementation of 'clearTimeout'.""", """
Warning: 'Window' doesn't implement 'setInterval'.
Try adding an implementation of 'setInterval'.""", """
Warning: 'Window' doesn't implement 'setTimeout'.
Try adding an implementation of 'setTimeout'.""", """
Warning: 'Storage' doesn't implement 'addAll'.
Try adding an implementation of 'addAll'.""",
"Info: This is the method declaration."],
};

void main() {
  var uriList = new List<Uri>();
  LIBRARIES.forEach((String name, LibraryInfo info) {
    if (info.documented) {
      uriList.add(new Uri(scheme: 'dart', path: name));
    }
  });
  asyncTest(() => analyze(uriList, WHITE_LIST));
}
