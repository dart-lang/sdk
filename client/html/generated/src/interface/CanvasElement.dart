// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CanvasElement extends Element {

  int get height();

  void set height(int value);

  int get width();

  void set width(int value);

  CanvasRenderingContext getContext(String contextId = null);

  String toDataURL(String type = null);
}
