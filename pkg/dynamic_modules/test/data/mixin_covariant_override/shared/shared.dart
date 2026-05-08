// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class BoxHitTestEntry extends HitTestEntry<RenderBox> {}

class RenderBox extends RenderObject {
  @override
  void handleEvent(BoxHitTestEntry entry) {}
}

abstract class RenderObject implements HitTestTarget {
  @override
  void handleEvent(covariant HitTestEntry entry) {}
}

mixin RenderObjectWithChildMixin<ChildType extends RenderObject>
    on RenderObject {}

abstract interface class HitTestTarget {
  void handleEvent(HitTestEntry<HitTestTarget> entry);
}

class HitTestEntry<T extends HitTestTarget> {}

mixin RenderProxyBoxMixin<T extends RenderBox>
    on RenderBox, RenderObjectWithChildMixin<T> {}
