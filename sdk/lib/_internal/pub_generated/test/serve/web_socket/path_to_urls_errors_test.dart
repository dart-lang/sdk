library pub_tests;
import 'package:json_rpc_2/error_code.dart' as rpc_error_code;
import 'package:path/path.dart' as p;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';
main() {
  initConfig();
  integration("pathToUrls errors on bad inputs", () {
    d.dir(
        "foo",
        [
            d.libPubspec("foo", "1.0.0"),
            d.dir("web", [d.file("foo.txt", "foo")])]).create();
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo"
        }
      }),
          d.file("top-level.txt", "top-level"),
          d.dir("bin", [d.file("foo.txt", "foo")]),
          d.dir("lib", [d.file("myapp.dart", "myapp")])]).create();
    pubServe(shouldGetFirst: true);
    expectWebSocketError("pathToUrls", {
      "path": 123
    },
        rpc_error_code.INVALID_PARAMS,
        'Parameter "path" for method "pathToUrls" must be a string, but was ' '123.');
    expectWebSocketError("pathToUrls", {
      "path": "main.dart",
      "line": 12.34
    },
        rpc_error_code.INVALID_PARAMS,
        'Parameter "line" for method "pathToUrls" must be an integer, but was '
            '12.34.');
    expectNotServed(p.join('bin', 'foo.txt'));
    expectNotServed(p.join('nope', 'foo.txt'));
    expectNotServed(p.join("..", "bar", "lib", "bar.txt"));
    expectNotServed(p.join("..", "foo", "web", "foo.txt"));
    endPubServe();
  });
}
void expectNotServed(String path) {
  expectWebSocketError("pathToUrls", {
    "path": path
  }, NOT_SERVED, 'Asset path "$path" is not currently being served.');
}
