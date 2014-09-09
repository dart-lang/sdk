library pub_tests;
import 'package:path/path.dart' as p;
import '../../../lib/src/io.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';
main() {
  initConfig();
  integration("pathToUrls converts asset ids to matching URL paths", () {
    d.dir(
        "foo",
        [
            d.libPubspec("foo", "1.0.0"),
            d.dir("lib", [d.file("foo.dart", "foo() => null;")])]).create();
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo"
        }
      }),
          d.dir(
              "test",
              [d.file("index.html", "<body>"), d.dir("sub", [d.file("bar.html", "bar")])]),
          d.dir("lib", [d.file("app.dart", "app() => null;")]),
          d.dir(
              "web",
              [d.file("index.html", "<body>"), d.dir("sub", [d.file("bar.html", "bar")])]),
          d.dir("randomdir", [d.file("index.html", "<body>")])]).create();
    pubServe(args: ["test", "web", "randomdir"], shouldGetFirst: true);
    expectWebSocketResult("pathToUrls", {
      "path": p.join("web", "index.html")
    }, {
      "urls": [getServerUrl("web", "index.html")]
    });
    expectWebSocketResult("pathToUrls", {
      "path": p.join("web", "sub", "bar.html")
    }, {
      "urls": [getServerUrl("web", "sub/bar.html")]
    });
    expectWebSocketResult("pathToUrls", {
      "path": p.join("test", "index.html")
    }, {
      "urls": [getServerUrl("test", "index.html")]
    });
    expectWebSocketResult("pathToUrls", {
      "path": p.join("test", "sub", "bar.html")
    }, {
      "urls": [getServerUrl("test", "sub/bar.html")]
    });
    expectWebSocketResult("pathToUrls", {
      "path": p.join("randomdir", "index.html")
    }, {
      "urls": [getServerUrl("randomdir", "index.html")]
    });
    expectWebSocketResult("pathToUrls", {
      "path": p.join("lib", "app.dart")
    }, {
      "urls": [
          getServerUrl("test", "packages/myapp/app.dart"),
          getServerUrl("web", "packages/myapp/app.dart"),
          getServerUrl("randomdir", "packages/myapp/app.dart")]
    });
    expectWebSocketResult("pathToUrls", {
      "path": p.join("packages", "myapp", "app.dart")
    }, {
      "urls": [
          getServerUrl("test", "packages/myapp/app.dart"),
          getServerUrl("web", "packages/myapp/app.dart"),
          getServerUrl("randomdir", "packages/myapp/app.dart")]
    });
    expectWebSocketResult("pathToUrls", {
      "path": p.join("packages", "foo", "foo.dart")
    }, {
      "urls": [
          getServerUrl("test", "packages/foo/foo.dart"),
          getServerUrl("web", "packages/foo/foo.dart"),
          getServerUrl("randomdir", "packages/foo/foo.dart")]
    });
    expectWebSocketResult("pathToUrls", {
      "path": p.join("..", "foo", "lib", "foo.dart")
    }, {
      "urls": [
          getServerUrl("test", "packages/foo/foo.dart"),
          getServerUrl("web", "packages/foo/foo.dart"),
          getServerUrl("randomdir", "packages/foo/foo.dart")]
    });
    expectWebSocketResult("pathToUrls", {
      "path": canonicalize(p.join(sandboxDir, "foo", "lib", "foo.dart"))
    }, {
      "urls": [
          getServerUrl("test", "packages/foo/foo.dart"),
          getServerUrl("web", "packages/foo/foo.dart"),
          getServerUrl("randomdir", "packages/foo/foo.dart")]
    });
    endPubServe();
  });
}
