import 'b.dart' deferred as b;

void f() {
  [].removeWhere((o) => b.isB(o)); //OK
}
