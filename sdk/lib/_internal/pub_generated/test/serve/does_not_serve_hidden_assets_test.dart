library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration("doesn't serve hidden assets", () {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir(
                "web",
                [
                    d.file(".outer.txt", "outer contents"),
                    d.dir(".dir", [d.file("inner.txt", "inner contents")])])]).create();
    pubServe();
    requestShould404(".outer.txt");
    requestShould404(".dir/inner.txt");
    endPubServe();
  });
}
