// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGTransformList {

  int get numberOfItems();

  SVGTransform appendItem(SVGTransform item);

  void clear();

  SVGTransform consolidate();

  SVGTransform createSVGTransformFromMatrix(SVGMatrix matrix);

  SVGTransform getItem(int index);

  SVGTransform initialize(SVGTransform item);

  SVGTransform insertItemBefore(SVGTransform item, int index);

  SVGTransform removeItem(int index);

  SVGTransform replaceItem(SVGTransform item, int index);
}
