// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library link_helper;

import 'package:compiler/src/util/util.dart';
import 'package:compiler/src/util/util_implementation.dart';

Link LinkFromList(List list) {
  switch (list.length) {
    case 0:
      return new Link();
    case 1:
      return new LinkEntry(list[0]);
    case 2:
      return new LinkEntry(list[0], new LinkEntry(list[1]));
    case 3:
      return new LinkEntry(
          list[0], new LinkEntry(list[1], new LinkEntry(list[2])));
  }
  Link link = new Link();
  for (int i = list.length; i > 0; i--) {
    link = link.prepend(list[i - 1]);
  }
  return link;
}
