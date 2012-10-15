#library('dart2js_mirrors_test');

#import('dart:mirrors');
#import("../../../pkg/unittest/unittest.dart");

void main() {
  try {
    print(currentMirrorSystem());
    fail("UnsupportedOperationException expected");
  } on UnsupportedOperationException catch (e) {
    print(e);
  }
  try {
    print(mirrorSystemOf(null));
    fail("UnsupportedOperationException expected");
  } on UnsupportedOperationException catch (e) {
    print(e);
  }
  try {
    print(reflect(null));
    fail("UnsupportedOperationException expected");
  } on UnsupportedOperationException catch (e) {
    print(e);
  }
}