library pub_tests;
import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
void main() {
  initConfig();
  integration(
      "reports previous transformers as dependencies if the "
          "transformer is transformed",
      () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "version": "1.0.0",
        "dependencies": {
          "pkg": {
            "path": "../pkg"
          },
          "qux": {
            "path": "../qux"
          }
        },
        "transformers": ["pkg", "qux"]
      })]).create();
    d.dir("pkg", [d.pubspec({
        "name": "pkg",
        "version": "1.0.0",
        "dependencies": {
          "foo": {
            "path": "../foo"
          },
          "bar": {
            "path": "../bar"
          },
          "baz": {
            "path": "../baz"
          }
        },
        "transformers": [{
            "foo": {
              "\$include": "lib/pkg.dart"
            }
          }, {
            "bar": {
              "\$exclude": "lib/transformer.dart"
            }
          }, "baz"]
      }),
          d.dir(
              "lib",
              [d.file("pkg.dart", ""), d.file("transformer.dart", transformer())])]).create();
    d.dir(
        "foo",
        [
            d.libPubspec("foo", "1.0.0"),
            d.dir("lib", [d.file("foo.dart", transformer())])]).create();
    d.dir(
        "bar",
        [
            d.libPubspec("bar", "1.0.0"),
            d.dir("lib", [d.file("bar.dart", transformer())])]).create();
    d.dir(
        "baz",
        [
            d.libPubspec("baz", "1.0.0"),
            d.dir("lib", [d.file("baz.dart", transformer())])]).create();
    d.dir(
        "qux",
        [
            d.libPubspec("qux", "1.0.0"),
            d.dir("lib", [d.file("qux.dart", transformer())])]).create();
    expectDependencies({
      'pkg': ['foo', 'bar', 'baz'],
      'foo': [],
      'bar': [],
      'baz': [],
      'qux': []
    });
  });
  integration(
      "reports all transitive package dependencies' transformers as "
          "dependencies if the transformer is transformed",
      () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "pkg": {
            "path": "../pkg"
          },
          "qux": {
            "path": "../qux"
          }
        },
        "transformers": ["pkg"]
      })]).create();
    d.dir("pkg", [d.pubspec({
        "name": "pkg",
        "version": "1.0.0",
        "dependencies": {
          "foo": {
            "path": "../foo"
          },
          "baz": {
            "path": "../baz"
          }
        },
        "transformers": ["baz"]
      }), d.dir("lib", [d.file("pkg.dart", transformer())])]).create();
    d.dir("foo", [d.pubspec({
        "name": "foo",
        "version": "1.0.0",
        "dependencies": {
          "bar": {
            "path": "../bar"
          }
        },
        "transformers": ["foo"]
      }), d.dir("lib", [d.file("foo.dart", transformer())])]).create();
    d.dir("bar", [d.pubspec({
        "name": "bar",
        "version": "1.0.0",
        "transformers": ["bar"]
      }), d.dir("lib", [d.file("bar.dart", transformer())])]).create();
    d.dir(
        "baz",
        [
            d.libPubspec("baz", "1.0.0"),
            d.dir("lib", [d.file("baz.dart", transformer())])]).create();
    d.dir("qux", [d.pubspec({
        "name": "qux",
        "version": "1.0.0",
        "transformers": ["qux"]
      }), d.dir("lib", [d.file("qux.dart", transformer())])]).create();
    expectDependencies({
      'pkg': ['foo', 'bar', 'baz'],
      'foo': [],
      'bar': [],
      'baz': [],
      'qux': []
    });
  });
  integration(
      "reports previous transformers as dependencies if a "
          "nonexistent local file is imported",
      () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "pkg": {
            "path": "../pkg"
          },
          "bar": {
            "path": "../bar"
          }
        },
        "transformers": ["pkg", "bar"]
      })]).create();
    d.dir("pkg", [d.pubspec({
        "name": "pkg",
        "version": "1.0.0",
        "dependencies": {
          "foo": {
            "path": "../foo"
          },
          "bar": {
            "path": "../bar"
          }
        },
        "transformers": [{
            "foo": {
              "\$include": "lib/pkg.dart"
            }
          }]
      }),
          d.dir(
              "lib",
              [
                  d.file("pkg.dart", ""),
                  d.file("transformer.dart", transformer(["nonexistent.dart"]))])]).create();
    d.dir(
        "foo",
        [
            d.libPubspec("foo", "1.0.0"),
            d.dir("lib", [d.file("foo.dart", transformer())])]).create();
    d.dir(
        "bar",
        [
            d.libPubspec("bar", "1.0.0"),
            d.dir("lib", [d.file("bar.dart", transformer())])]).create();
    expectDependencies({
      'pkg': ['foo'],
      'foo': [],
      'bar': []
    });
  });
  integration(
      "reports all that package's dependencies' transformers as "
          "dependencies if a non-existent file is imported from another package",
      () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {
            "path": "../foo"
          },
          "qux": {
            "path": "../qux"
          }
        },
        "transformers": ["myapp"]
      }),
          d.dir(
              "lib",
              [
                  d.file(
                      "myapp.dart",
                      transformer(["package:foo/nonexistent.dart"]))])]).create();
    d.dir("foo", [d.pubspec({
        "name": "foo",
        "version": "1.0.0",
        "dependencies": {
          "bar": {
            "path": "../bar"
          },
          "baz": {
            "path": "../baz"
          }
        },
        "transformers": ["foo"]
      }), d.dir("lib", [d.file("foo.dart", transformer())])]).create();
    d.dir("bar", [d.pubspec({
        "name": "bar",
        "version": "1.0.0",
        "transformers": ["bar"]
      }), d.dir("lib", [d.file("bar.dart", transformer())])]).create();
    d.dir("baz", [d.pubspec({
        "name": "baz",
        "version": "1.0.0",
        "transformers": ["baz"]
      }), d.dir("lib", [d.file("baz.dart", transformer())])]).create();
    d.dir("qux", [d.pubspec({
        "name": "qux",
        "version": "1.0.0",
        "transformers": ["qux"]
      }), d.dir("lib", [d.file("qux.dart", transformer())])]).create();
    expectDependencies({
      'myapp': ['foo', 'bar', 'baz'],
      'foo': [],
      'bar': [],
      'baz': [],
      'qux': []
    });
  });
  integration(
      "reports all that package's dependencies' transformers as "
          "dependencies if a non-existent transformer is used from another package",
      () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {
            "path": "../foo"
          },
          "qux": {
            "path": "../qux"
          }
        },
        "transformers": ["myapp"]
      }),
          d.dir(
              "lib",
              [
                  d.file(
                      "myapp.dart",
                      transformer(["package:foo/nonexistent.dart"]))])]).create();
    d.dir("foo", [d.pubspec({
        "name": "foo",
        "version": "1.0.0",
        "dependencies": {
          "bar": {
            "path": "../bar"
          },
          "baz": {
            "path": "../baz"
          }
        },
        "transformers": ["bar"]
      })]).create();
    d.dir(
        "bar",
        [
            d.libPubspec("bar", "1.0.0"),
            d.dir("lib", [d.file("bar.dart", transformer())])]).create();
    d.dir("baz", [d.pubspec({
        "name": "baz",
        "version": "1.0.0",
        "transformers": ["baz"]
      }), d.dir("lib", [d.file("baz.dart", transformer())])]).create();
    d.dir("qux", [d.pubspec({
        "name": "qux",
        "version": "1.0.0",
        "transformers": ["qux"]
      }), d.dir("lib", [d.file("qux.dart", transformer())])]).create();
    expectDependencies({
      'myapp': ['bar', 'baz'],
      'bar': [],
      'baz': [],
      'qux': []
    });
  });
  test("reports dependencies on transformers in past phases", () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "transformers": ["myapp/first", "myapp/second", "myapp/third"]
      }),
          d.dir(
              "lib",
              [
                  d.file("first.dart", transformer()),
                  d.file("second.dart", transformer()),
                  d.file("third.dart", transformer())])]).create();
    expectDependencies({
      'myapp/first': [],
      'myapp/second': ['myapp/first'],
      'myapp/third': ['myapp/second', 'myapp/first']
    });
  });
  integration(
      "considers the entrypoint package's dev and override " "dependencies",
      () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {
            "path": "../foo"
          }
        },
        "dev_dependencies": {
          "bar": {
            "path": "../bar"
          }
        },
        "dependency_overrides": {
          "baz": {
            "path": "../baz"
          }
        },
        "transformers": ["foo", "myapp"]
      }), d.dir("lib", [d.file("myapp.dart", transformer())])]).create();
    d.dir("foo", [d.pubspec({
        "name": "foo",
        "version": "1.0.0",
        "transformers": ["foo"]
      }), d.dir("lib", [d.file("foo.dart", transformer())])]).create();
    d.dir("bar", [d.pubspec({
        "name": "bar",
        "version": "1.0.0",
        "transformers": ["bar"]
      }), d.dir("lib", [d.file("bar.dart", transformer())])]).create();
    d.dir("baz", [d.pubspec({
        "name": "baz",
        "version": "1.0.0",
        "transformers": ["baz"]
      }), d.dir("lib", [d.file("baz.dart", transformer())])]).create();
    expectDependencies({
      'myapp': ['foo', 'bar', 'baz'],
      'foo': [],
      'bar': [],
      'baz': []
    });
  });
  integration(
      "doesn't consider a non-entrypoint package's dev and override " "dependencies",
      () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "pkg": {
            "path": "../pkg"
          }
        }
      })]).create();
    d.dir("pkg", [d.pubspec({
        "name": "pkg",
        "dependencies": {
          "foo": {
            "path": "../foo"
          }
        },
        "dev_dependencies": {
          "bar": {
            "path": "../bar"
          }
        },
        "dependency_overrides": {
          "baz": {
            "path": "../baz"
          }
        },
        "transformers": ["foo", "pkg"]
      }), d.dir("lib", [d.file("pkg.dart", transformer())])]).create();
    d.dir("foo", [d.pubspec({
        "name": "foo",
        "version": "1.0.0",
        "transformers": ["foo"]
      }), d.dir("lib", [d.file("foo.dart", transformer())])]).create();
    d.dir("bar", [d.pubspec({
        "name": "bar",
        "version": "1.0.0",
        "transformers": ["bar"]
      }), d.dir("lib", [d.file("bar.dart", transformer())])]).create();
    d.dir("baz", [d.pubspec({
        "name": "baz",
        "version": "1.0.0",
        "transformers": ["baz"]
      }), d.dir("lib", [d.file("baz.dart", transformer())])]).create();
    expectDependencies({
      'pkg': ['foo'],
      'foo': [],
      'bar': [],
      'baz': []
    });
  });
}
