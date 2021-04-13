abstract class RenderObject {
  void handleEvent(PointerEvent event, covariant HitTestEntry entry) {}
}

mixin RenderObjectWithChildMixin<ChildType extends RenderObject>
    on RenderObject {}
