import 'dart:core' as core;

import 'b.dart' deferred as b;

void f() {
  [].removeWhere((o) => b.isB(o)); //OK
  [].forEach((e) { core.print(e); }); //LINT
}
