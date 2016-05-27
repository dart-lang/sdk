// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "dart:convert" show JSON;
import "package:path/path.dart" as p;
import "package:async_helper/async_helper.dart";

main() async {
  asyncStart();

  await test("file: no resolution",
    "%file/main.dart",
    file: {"main": testMain},
    expect: {"foo.x": null});

  // An HTTP script with no ".packages" file assumes a "packages" dir.
  await test("http: no resolution", "%http/main.dart",
    http: {"main": testMain},
    expect: {
      "iroot": "%http/packages/",
      // "foo": null,
      "foo/": "%http/packages/foo/",
      "foo/bar": "%http/packages/foo/bar",
      "foo.x": null,
    });

  for (var scheme in ["file", "http"]) {

    testScheme(name, main, {expect, files, args, root, config}) {
      return test("$scheme: $name", main, expect: expect,
        root: root, config: config, args: args,
        file: scheme == "file" ? files : null,
        http: scheme == "http" ? files : null);
    }

    {
      var files = {"main": testMain, "packages": fooPackage};
      // Expect implicitly detected package dir.
      await testScheme("implicit packages dir","%$scheme/main.dart",
        files: files,
        expect: {
          "iroot": "%$scheme/packages/",
          // "foo": null,
          "foo/": "%$scheme/packages/foo/",
          "foo/bar": "%$scheme/packages/foo/bar",
        });
    }

    {
      var files = {"sub": {"main": testMain, "packages": fooPackage},
                   ".packages": ""};
      // Expect implicitly detected package dir.
      await testScheme("implicit packages dir 2", "%$scheme/sub/main.dart",
        files: files,
        expect: {
          "iroot": "%$scheme/sub/packages/",
          // "foo": null,
          "foo/": "%$scheme/sub/packages/foo/",
          "foo/bar": "%$scheme/sub/packages/foo/bar",
        });
    }

    {
      var files = {"main": testMain,
                   ".packages": "foo:pkgs/foo/",
                   "pkgs": fooPackage};
      await testScheme("implicit .packages file", "%$scheme/main.dart",
        files: files,
        expect: {
          "iconf": "%$scheme/.packages",
          // "foo": null,
          "foo/": "%$scheme/pkgs/foo/",
          "foo/bar": "%$scheme/pkgs/foo/bar",
        });
    }

    {
      var files = {"main": testMain,
                   ".packages": "foo:packages/foo/",
                   "packages": fooPackage,
                   "pkgs": fooPackage};
      await testScheme("explicit package root, no slash", "%$scheme/main.dart",
        files: files,
        root: "%$scheme/pkgs",
        expect: {
          "proot": "%$scheme/pkgs/",
          "iroot": "%$scheme/pkgs/",
          // "foo": null,
          "foo/": "%$scheme/pkgs/foo/",
          "foo/bar": "%$scheme/pkgs/foo/bar",
        });
    }

    {
      var files = {"main": testMain,
                   ".packages": "foo:packages/foo/",
                   "packages": fooPackage,
                   "pkgs": fooPackage};
      await testScheme("explicit package root, slash", "%$scheme/main.dart",
        files: files,
        root: "%$scheme/pkgs",
        expect: {
          "proot": "%$scheme/pkgs/",
          "iroot": "%$scheme/pkgs/",
          // "foo": null,
          "foo/": "%$scheme/pkgs/foo/",
          "foo/bar": "%$scheme/pkgs/foo/bar",
        });
    }

    {
      var files = {"main": testMain,
                   ".packages": "foo:packages/foo/",
                   "packages": fooPackage,
                   ".pkgs": "foo:pkgs/foo/",
                   "pkgs": fooPackage};
      await testScheme("explicit package config file", "%$scheme/main.dart",
        files: files,
        config: "%$scheme/.pkgs",
        expect: {
          "pconf": "%$scheme/.pkgs",
          "iconf": "%$scheme/.pkgs",
          // "foo": null,
          "foo/": "%$scheme/pkgs/foo/",
          "foo/bar": "%$scheme/pkgs/foo/bar",
        });
    }

    {
      var files = {"main": testMain,
                   ".packages": "foo:packages/foo/",
                   "packages": fooPackage,
                   "pkgs": fooPackage};
      var dataUri = "data:,foo:%$scheme/pkgs/foo/\n";
      await testScheme("explicit data: config file", "%$scheme/main.dart",
        files: files,
        config: dataUri,
        expect: {
          "pconf": dataUri,
          "iconf": dataUri,
          // "foo": null,
          "foo/": "%$scheme/pkgs/foo/",
          "foo/bar": "%$scheme/pkgs/foo/bar",
        });
    }
  }

  {
    // With a file: URI, the lookup checks for a .packages file in superdirs.
    var files = {"sub": { "main": testMain },
                 ".packages": "foo:pkgs/foo/",
                 "pkgs": fooPackage};
    await test("file: implicit .packages file in ..", "%file/sub/main.dart",
      file: files,
      expect: {
        "iconf": "%file/.packages",
        // "foo": null,
        "foo/": "%file/pkgs/foo/",
        "foo/bar": "%file/pkgs/foo/bar",
      });
  }

  {
    // With a non-file: URI, the lookup assumes a packges/ dir.
    var files = {"sub": { "main": testMain },
                 ".packages": "foo:pkgs/foo/",
                 "pkgs": fooPackage};
    // Expect implicitly detected .package file.
    await test("http: implicit packages dir", "%http/sub/main.dart",
      http: files,
      expect: {
        "iroot": "%http/sub/packages/",
        // "foo": null,
        "foo/": "%http/sub/packages/foo/",
        "foo/bar": "%http/sub/packages/foo/bar",
        "foo.x": null,
      });
  }


  if (failingTests.isNotEmpty) {
    print("Errors found in tests:\n  ${failingTests.join("\n  ")}\n");
    exit(255);
  }
  asyncEnd();
}

// ---------------------------------------------------------
// Helper functionality.

var failingTests = new Set();

var fileHttpRegexp = new RegExp(r"%(?:file|http)/");

Future test(String name, String main,
            {String root, String config, List<String> args,
             Map file, Map http, Map expect}) async {
  // Default values that are easily recognized in output.
  String fileRoot = "<no files configured>";
  String httpRoot = "<not http server configured>";

  /// Replaces markers `%file/` and `%http/` with the actual locations.
  ///
  /// Accepts a `null` [source] and returns `null` again.
  String fixPaths(String source) {
    if (source == null) return null;
    var result = source.replaceAllMapped(fileHttpRegexp, (match) {
      if (source.startsWith("file", match.start + 1)) return fileRoot;
      return httpRoot;
    });
    return result;
  }

  // Set up temporary directory or HTTP server.
  Directory tmpDir;
  var https;
  if (file != null) {
    tmpDir = createTempDir();
    fileRoot = new Uri.directory(tmpDir.path).toString();
  }
  if (http != null) {
    https = await startServer(http, fixPaths);
    httpRoot = "http://${https.address.address}:${https.port}/";
  }
  if (file != null) {
    // Create files after both roots are known, to allow file content
    // to refer to the them.
    createFiles(tmpDir, file, fixPaths);
  }

  try {
    var output = await runDart(fixPaths(main),
                               root: fixPaths(root),
                               config: fixPaths(config),
                               scriptArgs: args?.map(fixPaths));
    // These expectations are default. If not overridden the value will be
    // expected to be null. That is, you can't avoid testing the actual
    // value of these, you can only change what value to expect.
    // For values not included here (commented out), the result is not tested
    // unless a value (maybe null) is provided.
    var expects = {
       "pconf":   null,
       "proot":   null,
       "iconf":   null,
       "iroot":   null,
       // "foo":   null,
       "foo/":    null,
       "foo/bar": null,
       "foo.x":  "qux",
    }..addAll(expect);
    match(JSON.decode(output), expects, fixPaths, name);
  } catch (e, s) {
    // Unexpected error calling runDart or parsing the result.
    // Report it and continue.
    print("ERROR running $name: $e\n$s");
    failingTests.add(name);
  } finally {
    if (https != null) await https.close();
    if (tmpDir != null) tmpDir.deleteSync(recursive: true);
  }
}


/// Test that the output of running testMain matches the expectations.
///
/// The output is a string which is parse as a JSON literal.
/// The resulting map is always mapping strings to strings, or possibly `null`.
/// The expectations can have non-string values other than null,
/// they are `toString`'ed  before being compared (so the caller can use a URI
/// or a File/Directory directly as an expectation).
void match(Map actuals, Map expectations, String fixPaths(String expectation),
           String name) {
  for (var key in expectations.keys) {
    var expectation = fixPaths(expectations[key]?.toString());
    var actual = actuals[key];
    if (expectation != actual) {
      print("ERROR: $name: $key: Expected: <$expectation> Found: <$actual>");
      failingTests.add(name);
    }
  }
}

/// Script that prints the current state and the result of resolving
/// a few package URIs. This script will be invoked in different settings,
/// and the result will be parsed and compared to the expectations.
const String testMain = r"""
import "dart:convert" show JSON;
import "dart:io" show Platform, Directory;
import "dart:isolate" show Isolate;
import "package:foo/foo.dart" deferred as foo;
main(_) async {
  String platformRoot = await Platform.packageRoot;
  String platformConfig = await Platform.packageConfig;
  Directory cwd = Directory.current;
  Uri script = Platform.script;
  Uri isolateRoot = await Isolate.packageRoot;
  Uri isolateConfig = await Isolate.packageConfig;
  Uri base = Uri.base;
  Uri res1 = await Isolate.resolvePackageUri(Uri.parse("package:foo"));
  Uri res2 = await Isolate.resolvePackageUri(Uri.parse("package:foo/"));
  Uri res3 = await Isolate.resolvePackageUri(Uri.parse("package:foo/bar"));
  String fooX = await foo
    .loadLibrary()
    .timeout(const Duration(seconds: 1))
    .then((_) => foo.x, onError: (_) => null);
  print(JSON.encode({
    "cwd": cwd.path,
    "base": base?.toString(),
    "script": script?.toString(),
    "proot": platformRoot,
    "pconf": platformConfig,
    "iroot" : isolateRoot?.toString(),
    "iconf" : isolateConfig?.toString(),
    "foo": res1?.toString(),
    "foo/": res2?.toString(),
    "foo/bar": res3?.toString(),
    "foo.x": fooX?.toString(),
  }));
}
""";

/// Script that spawns a new Isolate using Isolate.spawnUri.
///
/// Takes URI of target isolate, package config and package root as
/// command line arguments. Any further arguments are forwarded to the
/// spawned isolate.
const String spawnUriMain = r"""
import "dart:isolate";
main(args) async {
  Uri target = Uri.parse(args[0]);
  Uri conf = args.length > 1 && args[1].isNotEmpty ? Uri.parse(args[1]) : null;
  Uri root = args.length > 2 && args[2].isNotEmpty ? Uri.parse(args[2]) : null;
  var restArgs = args.skip(3).toList();
  var isolate = await Isolate.spawnUri(target, restArgs,
      packageRoot: root, packageConfig: conf, paused: true);
  // Wait for isolate to exit before exiting the main isolate.
  var done = new RawReceivePort();
  done.handler = (_) { done.close(); };
  isolate.addExitHandler(done.sendPort);
  isolate.resume(isolate.pauseCapability);
}
""";

/// Script that spawns a new Isolate using Isolate.spawn.
const String spawnMain = r"""
import "dart:isolate";
import "testmain.dart" as test;
main() async {
  var isolate = await Isolate.spawn(test.main, [], paused: true);
  // Wait for isolate to exit before exiting the main isolate.
  var done = new RawReceivePort();
  done.handler = (_) { done.close(); };
  isolate.addExitHandler(done.sendPort);
  isolate.resume(isolate.pauseCapability);
}
""";

/// A package directory containing only one package, "foo", with one file.
const Map fooPackage = const { "foo": const { "foo": "var x = 'qux';" }};

/// Runs the Dart executable with the provided parameters.
///
/// Captures and returns the output.
Future<String> runDart(String script,
                       {String root, String config,
                        Iterable<String> scriptArgs}) async {
  // TODO: Find a way to change CWD before running script.
  var executable = Platform.executable;
  var args = [];
  if (root != null) args..add("-p")..add(root);
  if (config != null) args..add("--packages=$config");
  args.add(script);
  if (scriptArgs != null) {
    args.addAll(scriptArgs);
  }
  return Process.run(executable, args).then((results) {
    if (results.exitCode != 0) {
      throw results.stderr;
    }
    return results.stdout;
  });
}

/// Creates a number of files and subdirectories.
///
/// The [content] is the content of the directory itself. The map keys are
/// names and the values are either strings that represent Dart file contents
/// or maps that represent subdirectories.
/// Subdirectories may include a package directory. If [packageDir]
/// is provided, a `.packages` file is created for the content of that
/// directory.
void createFiles(Directory tempDir, Map content, String fixPaths(String text),
                 [String packageDir]) {
  Directory createDir(Directory base, String name) {
    Directory newDir = new Directory(p.join(base.path, name));
    newDir.createSync();
    return newDir;
  }

  void createTextFile(Directory base, String name, String content) {
    File newFile = new File(p.join(base.path, name));
    newFile.writeAsStringSync(fixPaths(content));
  }

  void createRecursive(Directory dir, Map map) {
    for (var name in map.keys) {
      var content = map[name];
      if (content is String) {
        // If the name starts with "." it's a .packages file, otherwise it's
        // a dart file. Those are the only files we care about in this test.
        createTextFile(dir,
                       name.startsWith(".") ? name : name + ".dart",
                       content);
      } else {
        assert(content is Map);
        var subdir = createDir(dir, name);
        createRecursive(subdir, content);
      }
    }
  }

  createRecursive(tempDir, content);
  if (packageDir != null) {
    // Unused?
    Map packages = content[packageDir];
    var entries =
        packages.keys.map((key) => "$key:$packageDir/$key").join("\n");
    createTextFile(tempDir, ".packages", entries);
  }
}

/// Start an HTTP server which serves a directory/file structure.
///
/// The directories and files are described by [files].
///
/// Each map key is an entry in a directory. A `Map` value is a sub-directory
/// and a `String` value is a text file.
/// The file contents are run through [fixPaths] to allow them to be self-
/// referential.
Future<HttpServer> startServer(Map files, String fixPaths(String text)) async {
  return (await HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 0))
      ..forEach((request) {
        var result = files;
        onFailure: {
          for (var part in request.uri.pathSegments) {
            if (part.endsWith(".dart")) {
              part = part.substring(0, part.length - 5);
            }
            if (result is Map) {
              result = result[part];
            } else {
              break onFailure;
            }
          }
          if (result is String) {
            request.response..write(fixPaths(result))
                            ..close();
            return;
          }
        }
        request.response..statusCode = HttpStatus.NOT_FOUND
                        ..close();
      });
}

// Counter used to avoid reusing temporary directory names.
// Some platforms are timer based, and creating two temp-dirs withing a short
// duration may cause a collision.
int tmpDirCounter = 0;

Directory createTempDir() {
  return Directory.systemTemp.createTempSync("pftest-${tmpDirCounter++}-");
}
