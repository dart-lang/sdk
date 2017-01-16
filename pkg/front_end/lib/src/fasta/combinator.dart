// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.combinator;

class Combinator {
  final bool isShow;

  final Set<String> names;

  Combinator(this.isShow, this.names);

  Combinator.show(Iterable <String> names)
      : this(true, new Set<String>.from(names));

  Combinator.hide(Iterable <String> names)
      : this(false, new Set<String>.from(names));

  bool get isHide => !isShow;
}
