// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String merge(String base, String reference) {
  if (base == "") return "/$reference";
  return "${base.substring(0, base.lastIndexOf("/") + 1)}$reference";
}

String removeDotSegments(String path) {
  List<String> output = [];
  bool appendSlash = false;
  for (String segment in path.split("/")) {
    appendSlash = false;
    if (segment == "..") {
      if (!output.isEmpty &&
          ((output.length != 1) || (output[0] != ""))) output.removeLast();
      appendSlash = true;
    } else if ("." == segment) {
      appendSlash = true;
    } else {
      output.add(segment);
    }
  }
  if (appendSlash) output.add("");
  return Strings.join(output, "/");
}
