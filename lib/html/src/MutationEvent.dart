// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface MutationEvent extends Event default MutationEventWrappingImplementation {

  MutationEvent(String type, Node relatedNode, String prevValue,
      String newValue, String attrName, int attrChange, [bool canBubble,
      bool cancelable]);

  static final int ADDITION = 2;

  static final int MODIFICATION = 1;

  static final int REMOVAL = 3;

  int get attrChange();

  String get attrName();

  String get newValue();

  String get prevValue();

  Node get relatedNode();
}
