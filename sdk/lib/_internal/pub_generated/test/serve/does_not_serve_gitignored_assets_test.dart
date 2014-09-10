library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration("doesn't serve .gitignored assets", () {
    ensureGit();
    d.git(
        appPath,
        [
            d.appPubspec(),
            d.dir(
                "web",
                [
                    d.file("outer.txt", "outer contents"),
                    d.dir("dir", [d.file("inner.txt", "inner contents")])]),
            d.file(".gitignore", "/web/outer.txt\n/web/dir")]).create();
    pubServe();
    requestShould404("outer.txt");
    requestShould404("dir/inner.txt");
    endPubServe();
  });
}
