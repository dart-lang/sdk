// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Combinator {
  final bool isShow;
  final Set<String> names;

  Combinator(this.isShow, this.names);

  Combinator.show(Iterable<String> names) : this(true, names.toSet());

  Combinator.hide(Iterable<String> names) : this(false, names.toSet());

  bool get isHide => !isShow;
}
