import 'dart:isolate';
import 'dart:async';
import 'dart:html';
import '../../../../pkg/unittest/lib/unittest.dart';

@a import 'deferred_in_isolate_lib.dart' as lib1;
@b import 'deferred_api_library.dart' as lib2;

const a = const DeferredLibrary("lib1");
const b = const DeferredLibrary("NonExistingFile", uri: "wrong/wrong.js");

main() {
  test("Deferred loading failing to load", () {
    a.load().then(expectAsync((_) {
      expect(lib1.f(), equals("hi"));
    }));
    b.load().then((_) {
      expect(false, true);
      lib2.foo("");
    }).catchError(expectAsync((_) {
      expect(true, true);
      }), test: (e) => e is DeferredLoadException);
  });
}
