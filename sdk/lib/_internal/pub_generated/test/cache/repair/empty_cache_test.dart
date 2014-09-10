library pub_tests;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('does nothing if the cache is empty', () {
    schedulePub(
        args: ["cache", "repair"],
        output: "No packages in cache, so nothing to repair.");
  });
}
