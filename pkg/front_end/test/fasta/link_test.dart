// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/util/link.dart' show Link, LinkBuilder;

import 'package:expect/expect.dart' show Expect;

main() {
  Link<String> strings = const Link<String>().prepend("B").prepend("A");
  Expect.stringEquals("[ A, B ]", "${strings}");
  Expect.stringEquals("[ B, A ]", "${strings.reverse()}");

  strings = (new LinkBuilder<String>()..addLast("A")..addLast("B")).toLink();

  Expect.stringEquals("[ A, B ]", "${strings}");
  Expect.stringEquals("[ B, A ]", "${strings.reverse()}");

  strings = new LinkBuilder<String>().toLink().prepend("B").prepend("A");

  Expect.stringEquals("[ A, B ]", "${strings}");
  Expect.stringEquals("[ B, A ]", "${strings.reverse()}");

  strings = const Link<String>().reverse().prepend("B").prepend("A");
  Expect.stringEquals("[ A, B ]", "${strings}");
  Expect.stringEquals("[ B, A ]", "${strings.reverse()}");

  strings = (new LinkBuilder<String>()..addLast("A")..addLast("B"))
      .toLink(const Link<String>());

  Expect.stringEquals("[ A, B ]", "${strings}");
  Expect.stringEquals("[ B, A ]", "${strings.reverse()}");
}
