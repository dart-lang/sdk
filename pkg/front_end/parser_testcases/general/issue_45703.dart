class Function {}
class C<Function> {}

typedef Function = int;
typedef F<Function> = int;

extension Function on List {}
extension E<Function> on List<Function> {}

mixin Function {}
mixin M<Function> implements List<Function> {}

void main() {
  Function ok;
  dynamic okToo;
}
