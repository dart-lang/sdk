import 'package:ddc/runtime/dart_logging_runtime.dart' as ddc;
import 'package:unittest/unittest.dart';

class A<T> {
  T x;
  A(this.x);
}

class B extends A<String> {
  B() : super("B!");
}

void runTest() {
  var astring = new A<String>("").runtimeType;
  var l = [new A<String>("hello"), new A("world"), new B(), 42];
  for (var item in l) {
    try {
      ddc.cast(item, astring);
    } catch (e) {
      // Do nothing
    }
  }
}

final expected = '''
Key dart_logging_runtime_test.dart 18:15 in runTest:
 - success: 2 (0.5)
 - failure: 1 (0.25)
 - mismatch: 1 (0.25)
 - error: 0 (0.0)
''';

void main() {
  test('summary', () {
    runTest();
    var output = ddc.summary();
    expect(output, equals(expected));
  });

  test('handler', () {
    int ddcFailures = 0;
    int dartFailures = 0;
    ddc.castRecordHandler = (String key, ddc.CastRecord record) {
      ddcFailures += (record.ddcSuccess) ? 0 : 1;
      dartFailures += (record.dartSuccess) ? 0 : 1;
    };
    runTest();
    expect(ddcFailures, equals(2));
    expect(dartFailures, equals(1));
  });
}
