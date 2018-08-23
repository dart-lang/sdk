// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.combinator;

class Combinator {
  final bool isShow;

  final List<CombinatorIdentifier> identifiers;

  final Set<String> names;

  Combinator(
      this.isShow, this.identifiers, this.names, int charOffset, Uri fileUri);

  Combinator.hide(List<CombinatorIdentifier> identifiers,
      Iterable<String> names, int charOffset, Uri fileUri)
      : this(false, identifiers, new Set<String>.from(names), charOffset,
            fileUri);

  Combinator.show(List<CombinatorIdentifier> identifiers,
      Iterable<String> names, int charOffset, Uri fileUri)
      : this(true, identifiers, new Set<String>.from(names), charOffset,
            fileUri);

  bool get isHide => !isShow;
}

class CombinatorIdentifier {
  final int offset;
  final String name;
  final bool isSynthetic;

  CombinatorIdentifier(this.offset, this.name, this.isSynthetic);
}
