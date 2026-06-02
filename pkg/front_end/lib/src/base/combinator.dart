// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class CombinatorBuilder {
  final bool isShow;

  final Set<String> names;

  new(this.isShow, this.names, int charOffset, Uri fileUri);

  new show(Iterable<String> names, int charOffset, Uri fileUri)
    : this(true, new Set<String>.of(names), charOffset, fileUri);

  new hide(Iterable<String> names, int charOffset, Uri fileUri)
    : this(false, new Set<String>.of(names), charOffset, fileUri);

  bool get isHide => !isShow;
}
