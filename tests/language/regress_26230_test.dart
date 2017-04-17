// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _RenderTabBar extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TabBarParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TabBarParentData> {}

class RenderObject {}

class RenderSector extends RenderObject {}

class RenderBox extends RenderObject {}

class ParentData {}

class BoxParentData extends ParentData {}

class SectorParentData extends ParentData {}

class ContainerParentDataMixin<ChildType extends RenderObject> {}

class ContainerRenderObjectMixin<ChildType extends RenderObject,
    ParentDataType extends ContainerParentDataMixin<ChildType>> {}

class SectorChildListParentData extends SectorParentData
    with ContainerParentDataMixin<RenderSector> {}

class RenderDecoratedSector extends RenderSector {}

class RenderSectorWithChildren extends RenderDecoratedSector
    with ContainerRenderObjectMixin<RenderSector, SectorChildListParentData> {}

class ContainerBoxParentDataMixin<ChildType extends RenderObject>
    extends BoxParentData with ContainerParentDataMixin<ChildType> {}

class RenderBoxContainerDefaultsMixin<ChildType extends RenderBox,
        ParentDataType extends ContainerBoxParentDataMixin<ChildType>>
    implements ContainerRenderObjectMixin<ChildType, ParentDataType> {}

class FlexParentData extends ContainerBoxParentDataMixin<RenderBox> {}

class _TabBarParentData extends ContainerBoxParentDataMixin<RenderBox> {}

main() {
  new _RenderTabBar();
}
