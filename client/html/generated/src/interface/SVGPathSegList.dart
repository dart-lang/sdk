// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegList {

  int get numberOfItems();

  SVGPathSeg appendItem(SVGPathSeg newItem);

  void clear();

  SVGPathSeg getItem(int index);

  SVGPathSeg initialize(SVGPathSeg newItem);

  SVGPathSeg insertItemBefore(SVGPathSeg newItem, int index);

  SVGPathSeg removeItem(int index);

  SVGPathSeg replaceItem(SVGPathSeg newItem, int index);
}
