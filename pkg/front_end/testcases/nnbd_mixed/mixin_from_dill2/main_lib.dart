class Offset {}

class AbstractNode {}

mixin DiagnosticableTreeMixin {}

abstract class HitTestTarget {}

class HitTestResult {}

class BoxHitTestResult extends HitTestResult {}

abstract class RenderObject extends AbstractNode
    with DiagnosticableTreeMixin
    implements HitTestTarget {}

abstract class RenderBox extends RenderObject {
  bool hitTest(BoxHitTestResult result, {required Offset position}) => false;
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      false;
}

mixin RenderObjectWithChildMixin<ChildType extends RenderObject>
    on RenderObject {
  ChildType? _child;

  /// The render object's unique child
  ChildType? get child => _child;
}

mixin RenderProxyBoxMixin<T extends RenderBox>
    on RenderBox, RenderObjectWithChildMixin<T> {
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return child?.hitTest(result, position: position) ?? false;
  }
}

class RenderProxyBox extends RenderBox
    with
        RenderObjectWithChildMixin<RenderBox>,
        RenderProxyBoxMixin<RenderBox> {}
