library pub_tests;
import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  setUp(() {
    d.dir(appPath, [d.appPubspec()]).create();
  });
  integration("the 404 page describes the missing asset", () {
    pubServe();
    scheduleRequest("packages/foo/missing.txt").then((response) {
      expect(response.statusCode, equals(404));
      expect(response.body, contains("foo"));
      expect(response.body, contains("missing.txt"));
    });
    endPubServe();
  });
  integration("the 404 page describes the error", () {
    pubServe();
    scheduleRequest("packages").then((response) {
      expect(response.statusCode, equals(404));
      expect(response.body, contains('&quot;&#x2F;packages&quot;'));
    });
    endPubServe();
  });
}
