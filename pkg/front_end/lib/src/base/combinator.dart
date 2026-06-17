// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class CombinatorBuilder(final bool isShow, final Set<String> names) {
  new show(Iterable<String> names) : this(true, new Set<String>.of(names));

  new hide(Iterable<String> names) : this(false, new Set<String>.of(names));

  bool get isHide => !isShow;
}
