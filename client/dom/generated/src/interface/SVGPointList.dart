// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPointList {

  int get numberOfItems();

  SVGPoint appendItem(SVGPoint item);

  void clear();

  SVGPoint getItem(int index);

  SVGPoint initialize(SVGPoint item);

  SVGPoint insertItemBefore(SVGPoint item, int index);

  SVGPoint removeItem(int index);

  SVGPoint replaceItem(SVGPoint item, int index);
}
