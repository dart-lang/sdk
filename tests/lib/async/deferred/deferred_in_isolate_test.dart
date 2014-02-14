import 'dart:isolate';
import 'dart:async';
import '../../../../pkg/unittest/lib/unittest.dart';

@a import 'deferred_in_isolate_lib.dart' as lib1;
@b import 'deferred_api_library.dart' as lib2;

const a = const DeferredLibrary("lib1");
const b = const DeferredLibrary("NonExistingFile", uri: "wrong/");

loadDeferred(ports) {
  a.load().then((_) {
    ports[0].send(lib1.f());
  });
  b.load().then((b) {
    ports[1].send("No error");
    lib2.foo(20);
  }).catchError((_) {
    ports[1].send("Error caught");
  }, test: (e) => e is DeferredLoadException);
}

main() {
  test("Deferred loading in isolate", () {
    List<ReceivePort> ports = new List.generate(2, (_) => new ReceivePort());
    ports[0].first.then(expectAsync((msg) {
       expect(msg, equals("hi"));
    }));
    ports[1].first.then(expectAsync((msg) {
      expect(msg, equals("Error caught"));
    }));
    Isolate.spawn(loadDeferred, ports.map((p) => p.sendPort).toList());
  });
}
