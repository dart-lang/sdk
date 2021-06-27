import 'main_lib.dart';

mixin RenderAnimatedOpacityMixin<T extends RenderObject>
    on RenderObjectWithChildMixin<T> {}

class RenderAnimatedOpacity extends RenderProxyBox
    with RenderProxyBoxMixin, RenderAnimatedOpacityMixin<RenderBox> {}

main() {
  new RenderAnimatedOpacity();
}
