// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "dart:convert" show JSON;
import "package:path/path.dart" as p;
import "package:async_helper/async_helper.dart";

/// Root directory of generated files.
/// Path contains trailing slash.
/// Each configuration gets its own sub-directory.
Directory fileRoot;

/// Shared HTTP server serving the files in [httpFiles].
/// Each configuration gets its own "sub-dir" entry in `httpFiles`.
HttpServer httpServer;

/// Directory structure served by HTTP server.
Map<String, dynamic> httpFiles = {};

/// List of configurations.
List<Configuration> configurations = [];

/// Collection of failing tests and their failure messages.
///
/// Each test may fail in more than one way.
var failingTests = <String, List<String>>{};

main() async {
  asyncStart();
  await setUp();

  await runTests(); //                         //# 01: ok
  await runTests([spawn]); //                  //# 02: ok
  await runTests([spawn, spawn]); //           //# 03: ok
  await runTests([spawnUriInherit]); //        //# 04: ok
  await runTests([spawnUriInherit, spawn]); // //# 05: ok
  await runTests([spawn, spawnUriInherit]); // //# 06: ok

  // Test that spawning a new VM with file paths instead of URIs as arguments
  // gives the same URIs in the internal values.
  await runTests([asPath]); //                 //# 07: ok

  // Test that spawnUri can reproduce the behavior of VM command line parameters
  // exactly.
  // (Don't run all configuration combinations in the same test, so
  // unroll the configurations into multiple groups and run each group
  // as its own multitest.
  {
    var groupCount = 8;
    var groups = new List.generate(8, (_) => []);
    for (int i = 0; i < configurations.length; i++) {
      groups[i % groupCount].add(configurations[i]);
    }
    var group = -1;
    group = 0; //                              //# 10: ok
    group = 1; //                              //# 11: ok
    group = 2; //                              //# 12: ok
    group = 3; //                              //# 13: ok
    group = 4; //                              //# 14: ok
    group = 5; //                              //# 15: ok
    group = 6; //                              //# 16: ok
    group = 7; //                              //# 17: ok
    if (group >= 0) {
      for (var other in groups[group]) {
        await runTests([spawnUriOther(other)]);
      }
    }
  }

  await tearDown();

  if (failingTests.isNotEmpty) {
    print("Errors found in tests:");
    failingTests.forEach((test, actual) {
      print("$test:\n  ${actual.join("\n  ")}");
    });
    exit(255);
  }

  asyncEnd();
}

/// Test running the test of the configuration through [Isolate.spawn].
///
/// This should not change the expected results compared to running it
/// directly.
Configuration spawn(Configuration conf) {
  return conf.update(
      description: conf.description + "/spawn",
      main: "spawnMain",
      newArgs: [conf.mainType],
      expect: null);
}

/// Tests running a spawnUri on top of the configuration before testing.
///
/// The `spawnUri` call has no explicit root or config parameter, and
/// shouldn't search for one, so it implicitly inherits the current isolate's
/// actual root or configuration.
Configuration spawnUriInherit(Configuration conf) {
  if (conf.expect["iroot"] == null &&
      conf.expect["iconf"] == null &&
      conf.expect["pconf"] != null) {
    // This means that the specified configuration file didn't exist.
    // spawning a new URI to "inherit" that will actually do an automatic
    // package resolution search with results that are unpredictable.
    // That behavior will be tested in a setting where we have more control over
    // the files around the spawned URI.
    return null;
  }
  return conf.update(
      description: conf.description + "/spawnUri-inherit",
      main: "spawnUriMain",
      // encode null parameters as "-". Windows fails if using empty string.
      newArgs: [
        conf.mainFile,
        "-",
        "-",
        "false"
      ],
      expect: {
        "proot": conf.expect["iroot"],
        "pconf": conf.expect["iconf"],
      });
}

/// Tests running a spawnUri with an explicit configuration different
/// from the original configuration.
///
/// Duplicates the explicit parameters as arguments to the spawned isolate.
ConfigurationTransformer spawnUriOther(Configuration other) {
  return (Configuration conf) {
    bool search = (other.config == null) && (other.root == null);
    return conf.update(
        description: "${conf.description} -spawnUri-> ${other.description}",
        main: "spawnUriMain",
        newArgs: [
          other.mainFile,
          other.config ?? "-",
          other.root ?? "-",
          "$search"
        ],
        expect: other.expect);
  };
}

/// Convert command line parameters to file paths.
///
/// This only works on the command line, not with `spawnUri`.
Configuration asPath(Configuration conf) {
  bool change = false;

  String toPath(String string) {
    if (string == null) return null;
    if (string.startsWith("file:")) {
      change = true;
      return new File.fromUri(Uri.parse(string)).path;
    }
    return string;
  }

  var mainFile = toPath(conf.mainFile);
  var root = toPath(conf.root);
  var config = toPath(conf.config);
  if (!change) return null;
  return conf.update(
      description: conf.description + "/as path",
      mainFile: mainFile,
      root: root,
      config: config);
}

/// --------------------------------------------------------------

Future setUp() async {
  fileRoot = createTempDir();
  // print("FILES: $fileRoot");
  httpServer = await startServer(httpFiles);
  // print("HTTPS: ${httpServer.address.address}:${httpServer.port}");
  createConfigurations();
}

Future tearDown() async {
  fileRoot.deleteSync(recursive: true);
  await httpServer.close();
}

typedef Configuration ConfigurationTransformer(Configuration conf);

Future runTests([List<ConfigurationTransformer> transformations]) async {
  outer:
  for (var config in configurations) {
    if (transformations != null) {
      for (int i = transformations.length - 1; i >= 0; i--) {
        config = transformations[i](config);
        if (config == null) {
          continue outer; // Can be used to skip some tests.
        }
      }
    }
    await testConfiguration(config);
  }
}

// Creates a combination of configurations for running the Dart VM.
//
// The combinations covers most configurations of implicit and explicit
// package configurations over both file: and http: file sources.
// It also specifies the expected values of the following for a VM
// run in that configuration.
//
// * `Process.packageRoot`
// * `Process.packageConfig`
// * `Isolate.packageRoot`
// * `Isolate.packageRoot`
// * `Isolate.resolvePackageUri` of various inputs.
// * A variable defined in a library loaded using a `package:` URI.
//
// The configurations all have URIs as `root`, `config` and `mainFile` strings,
// have empty argument lists and `mainFile` points to the `main.dart` file.
void createConfigurations() {
  add(String description, String mainDir,
      {String root, String config, Map file, Map http, Map expect}) {
    var id = freshName("conf");

    file ??= {};
    http ??= {};

    // Fix-up paths.
    String fileUri = fileRoot.uri.resolve("$id/").toString();
    String httpUri =
        "http://${httpServer.address.address}:${httpServer.port}/$id/";

    String fixPath(String path) {
      return path?.replaceAllMapped(fileHttpRegexp, (match) {
        if (path.startsWith("%file/", match.start)) return fileUri;
        return httpUri;
      });
    }

    void fixPaths(Map dirs) {
      for (var name in dirs.keys) {
        var value = dirs[name];
        if (value is Map) {
          Map subDir = value;
          fixPaths(subDir);
        } else {
          var newValue = fixPath(value);
          if (newValue != value) dirs[name] = newValue;
        }
      }
    }

    if (!mainDir.endsWith("/")) mainDir += "/";
    // Insert main files into the main-dir map.
    Map mainDirMap;
    {
      if (mainDir.startsWith("%file/")) {
        mainDirMap = file;
      } else {
        mainDirMap = http;
      }
      var parts = mainDir.split('/');
      for (int i = 1; i < parts.length - 1; i++) {
        var dirName = parts[i];
        mainDirMap = mainDirMap[dirName] ?? (mainDirMap[dirName] = {});
      }
    }

    mainDirMap["main"] = testMain;
    mainDirMap["spawnMain"] = spawnMain.replaceAll("%mainDir/", mainDir);
    mainDirMap["spawnUriMain"] = spawnUriMain;

    mainDir = fixPath(mainDir);
    root = fixPath(root);
    config = fixPath(config);
    fixPaths(file);
    fixPaths(http);
    // These expectations are default. If not overridden the value will be
    // expected to be null. That is, you can't avoid testing the actual
    // value of these, you can only change what value to expect.
    // For values not included here (commented out), the result is not tested
    // unless a value (maybe null) is provided.
    fixPaths(expect);

    expect = {
      "pconf": null,
      "proot": null,
      "iconf": null,
      "iroot": null,
      "foo": null,
      "foo/": null,
      "foo/bar": null,
      "foo.x": "qux",
      "bar/bar": null,
      "relative": "relative/path",
      "nonpkg": "http://example.org/file"
    }..addAll(expect ?? const {});

    // Add http files to the http server.
    if (http.isNotEmpty) {
      httpFiles[id] = http;
    }
    // Add file files to the file system.
    if (file.isNotEmpty) {
      createFiles(fileRoot, id, file);
    }

    configurations.add(new Configuration(
        description: description,
        root: root,
        config: config,
        mainFile: mainDir + "main.dart",
        args: const [],
        expect: expect));
  }

  // The `test` function can generate file or http resources.
  // It replaces "%file/" with URI of the root directory of generated files and
  // "%http/" with the URI of the HTTP server's root in appropriate contexts
  // (all file contents and parameters).

  // Tests that only use one scheme to access files.
  for (var scheme in ["file", "http"]) {
    /// Run a test in the current scheme.
    ///
    /// The files are served either through HTTP or in a local directory.
    /// Use "%$scheme/" to refer to the root of the served files.
    addScheme(description, main, {expect, files, args, root, config}) {
      add("$scheme/$description", main,
          expect: expect,
          root: root,
          config: config,
          file: (scheme == "file") ? files : null,
          http: (scheme == "http") ? files : null);
    }

    {
      // No parameters, no .packages files or packages/ dir.
      // A "file:" source realizes there is no configuration and can't resolve
      // any packages, but a "http:" source assumes a "packages/" directory.
      addScheme("no resolution", "%$scheme/",
          files: {},
          expect: (scheme == "file")
              ? {"foo.x": null}
              : {
                  "iroot": "%http/packages/",
                  "foo": "%http/packages/foo",
                  "foo/": "%http/packages/foo/",
                  "foo/bar": "%http/packages/foo/bar",
                  "foo.x": null,
                  "bar/bar": "%http/packages/bar/bar",
                });
    }

    {
      // No parameters, no .packages files,
      // packages/ dir exists and is detected.
      var files = {"packages": fooPackage};
      addScheme("implicit packages dir", "%$scheme/", files: files, expect: {
        "iroot": "%$scheme/packages/",
        "foo": "%$scheme/packages/foo",
        "foo/": "%$scheme/packages/foo/",
        "foo/bar": "%$scheme/packages/foo/bar",
        "bar/bar": "%$scheme/packages/bar/bar",
      });
    }

    {
      // No parameters, no .packages files in current dir, but one in parent,
      // packages/ dir exists and is used.
      //
      // Should not detect the .packages file in parent directory.
      // That file is empty, so if it is used, the system cannot resolve "foo".
      var files = {
        "sub": {"packages": fooPackage},
        ".packages": ""
      };
      addScheme(
          "implicit packages dir overrides parent .packages", "%$scheme/sub/",
          files: files,
          expect: {
            "iroot": "%$scheme/sub/packages/",
            "foo": "%$scheme/sub/packages/foo",
            "foo/": "%$scheme/sub/packages/foo/",
            "foo/bar": "%$scheme/sub/packages/foo/bar",
            // "foo.x": "qux",  // Blocked by issue http://dartbug.com/26482
            "bar/bar": "%$scheme/sub/packages/bar/bar",
          });
    }

    {
      // No parameters, a .packages file next to entry is found and used.
      // A packages/ directory is ignored.
      var files = {
        ".packages": "foo:pkgs/foo/",
        "packages": {},
        "pkgs": fooPackage
      };
      addScheme("implicit .packages file", "%$scheme/", files: files, expect: {
        "iconf": "%$scheme/.packages",
        "foo/": "%$scheme/pkgs/foo/",
        "foo/bar": "%$scheme/pkgs/foo/bar",
      });
    }

    {
      // No parameters, a .packages file in parent dir, no packages/ dir.
      // With a file: URI, find the .packages file.
      // WIth a http: URI, assume a packages/ dir.
      var files = {"sub": {}, ".packages": "foo:pkgs/foo/", "pkgs": fooPackage};
      addScheme(".packages file in parent", "%$scheme/sub/",
          files: files,
          expect: (scheme == "file")
              ? {
                  "iconf": "%file/.packages",
                  "foo/": "%file/pkgs/foo/",
                  "foo/bar": "%file/pkgs/foo/bar",
                }
              : {
                  "iroot": "%http/sub/packages/",
                  "foo": "%http/sub/packages/foo",
                  "foo/": "%http/sub/packages/foo/",
                  "foo/bar": "%http/sub/packages/foo/bar",
                  "foo.x": null,
                  "bar/bar": "%http/sub/packages/bar/bar",
                });
    }

    {
      // Specified package root that doesn't exist.
      // Ignores existing .packages file and packages/ dir.
      addScheme("explicit root not there", "%$scheme/",
          files: {
            "packages": fooPackage,
            ".packages": "foo:%$scheme/packages/"
          },
          root: "%$scheme/notthere/",
          expect: {
            "proot": "%$scheme/notthere/",
            "iroot": "%$scheme/notthere/",
            "foo": "%$scheme/notthere/foo",
            "foo/": "%$scheme/notthere/foo/",
            "foo/bar": "%$scheme/notthere/foo/bar",
            "foo.x": null,
            "bar/bar": "%$scheme/notthere/bar/bar",
          });
    }

    {
      // Specified package config that doesn't exist.
      // Ignores existing .packages file and packages/ dir.
      addScheme("explicit config not there", "%$scheme/",
          files: {".packages": "foo:packages/foo/", "packages": fooPackage},
          config: "%$scheme/.notthere",
          expect: {
            "pconf": "%$scheme/.notthere",
            "iconf": null, //   <- Only there if actually loaded (unspecified).
            "foo/": null,
            "foo/bar": null,
            "foo.x": null,
          });
    }

    {
      // Specified package root with no trailing slash.
      // The Platform.packageRoot and Isolate.packageRoot has a trailing slash.
      var files = {
        ".packages": "foo:packages/foo/",
        "packages": {},
        "pkgs": fooPackage
      };
      addScheme("explicit package root, no slash", "%$scheme/",
          files: files,
          root: "%$scheme/pkgs",
          expect: {
            "proot": "%$scheme/pkgs/",
            "iroot": "%$scheme/pkgs/",
            "foo": "%$scheme/pkgs/foo",
            "foo/": "%$scheme/pkgs/foo/",
            "foo/bar": "%$scheme/pkgs/foo/bar",
            "bar/bar": "%$scheme/pkgs/bar/bar",
          });
    }

    {
      // Specified package root with trailing slash.
      var files = {
        ".packages": "foo:packages/foo/",
        "packages": {},
        "pkgs": fooPackage
      };
      addScheme("explicit package root, slash", "%$scheme/",
          files: files,
          root: "%$scheme/pkgs",
          expect: {
            "proot": "%$scheme/pkgs/",
            "iroot": "%$scheme/pkgs/",
            "foo": "%$scheme/pkgs/foo",
            "foo/": "%$scheme/pkgs/foo/",
            "foo/bar": "%$scheme/pkgs/foo/bar",
            "bar/bar": "%$scheme/pkgs/bar/bar",
          });
    }

    {
      // Specified package config.
      var files = {
        ".packages": "foo:packages/foo/",
        "packages": {},
        ".pkgs": "foo:pkgs/foo/",
        "pkgs": fooPackage
      };
      addScheme("explicit package config file", "%$scheme/",
          files: files,
          config: "%$scheme/.pkgs",
          expect: {
            "pconf": "%$scheme/.pkgs",
            "iconf": "%$scheme/.pkgs",
            "foo/": "%$scheme/pkgs/foo/",
            "foo/bar": "%$scheme/pkgs/foo/bar",
          });
    }

    {
      // Specified package config as data: URI.
      // The package config can be specified as a data: URI.
      // (In that case, relative URI references in the config file won't work).
      var files = {
        ".packages": "foo:packages/foo/",
        "packages": {},
        "pkgs": fooPackage
      };
      var dataUri = "data:,foo:%$scheme/pkgs/foo/\n";
      addScheme("explicit data: config file", "%$scheme/",
          files: files,
          config: dataUri,
          expect: {
            "pconf": dataUri,
            "iconf": dataUri,
            "foo/": "%$scheme/pkgs/foo/",
            "foo/bar": "%$scheme/pkgs/foo/bar",
          });
    }
  }

  // Tests where there are files on both http: and file: sources.

  for (var entryScheme in const ["file", "http"]) {
    for (var pkgScheme in const ["file", "http"]) {
      // Package root.
      if (entryScheme != pkgScheme) {
        // Package dir and entry point on different schemes.
        var files = {};
        var https = {};
        (entryScheme == "file" ? files : https)["main"] = testMain;
        (pkgScheme == "file" ? files : https)["pkgs"] = fooPackage;
        add("$pkgScheme pkg/$entryScheme main", "%$entryScheme/",
            file: files,
            http: https,
            root: "%$pkgScheme/pkgs/",
            expect: {
              "proot": "%$pkgScheme/pkgs/",
              "iroot": "%$pkgScheme/pkgs/",
              "foo": "%$pkgScheme/pkgs/foo",
              "foo/": "%$pkgScheme/pkgs/foo/",
              "foo/bar": "%$pkgScheme/pkgs/foo/bar",
              "bar/bar": "%$pkgScheme/pkgs/bar/bar",
              "foo.x": "qux",
            });
      }
      // Package config. The configuration file may also be on either source.
      for (var configScheme in const ["file", "http"]) {
        // Don't do the boring stuff!
        if (entryScheme == configScheme && entryScheme == pkgScheme) continue;
        // Package config, packages and entry point not all on same scheme.
        var files = {};
        var https = {};
        (entryScheme == "file" ? files : https)["main"] = testMain;
        (configScheme == "file" ? files : https)[".pkgs"] =
            "foo:%$pkgScheme/pkgs/foo/\n";
        (pkgScheme == "file" ? files : https)["pkgs"] = fooPackage;
        add("$pkgScheme pkg/$configScheme config/$entryScheme main",
            "%$entryScheme/",
            file: files,
            http: https,
            config: "%$configScheme/.pkgs",
            expect: {
              "pconf": "%$configScheme/.pkgs",
              "iconf": "%$configScheme/.pkgs",
              "foo/": "%$pkgScheme/pkgs/foo/",
              "foo/bar": "%$pkgScheme/pkgs/foo/bar",
              "foo.x": "qux",
            });
      }
    }
  }
}

// ---------------------------------------------------------
// Helper functionality.

var fileHttpRegexp = new RegExp(r"%(?:file|http)/");

// Executes a test in a configuration.
//
// The test must specify which main file to use
// (`main`, `spawnMain` or `spawnUriMain`)
// and any arguments which will be used by `spawnMain` and `spawnUriMain`.
//
// The [expect] map may be used to override the expectations of the
// configuration on a value-by-value basis. Passing, e.g., `{"pconf": null}`
// will override only the `pconf` (`Platform.packageConfig`) expectation.
Future testConfiguration(Configuration conf) async {
  print("-- ${conf.description}");
  var description = conf.description;
  try {
    var output = await execDart(conf.mainFile,
        root: conf.root, config: conf.config, scriptArgs: conf.args);
    match(JSON.decode(output), conf.expect, description, output);
  } catch (e, s) {
    // Unexpected error calling execDart or parsing the result.
    // Report it and continue.
    print("ERROR running $description: $e\n$s");
    failingTests.putIfAbsent(description, () => []).add("$e");
  }
}

/// Test that the output of running testMain matches the expectations.
///
/// The output is a string which is parse as a JSON literal.
/// The resulting map is always mapping strings to strings, or possibly `null`.
/// The expectations can have non-string values other than null,
/// they are `toString`'ed  before being compared (so the caller can use a URI
/// or a File/Directory directly as an expectation).
void match(Map actuals, Map expectations, String desc, String actualJson) {
  for (var key in expectations.keys) {
    var expectation = expectations[key]?.toString();
    var actual = actuals[key];
    if (expectation != actual) {
      print("ERROR: $desc: $key: Expected: <$expectation> Found: <$actual>");
      failingTests
          .putIfAbsent(desc, () => [])
          .add("$key: $expectation != $actual");
    }
  }
}

const String improt = "import"; // Avoid multitest import rewriting.

/// Script that prints the current state and the result of resolving
/// a few package URIs. This script will be invoked in different settings,
/// and the result will be parsed and compared to the expectations.
const String testMain = """
$improt "dart:convert" show JSON;
$improt "dart:io" show Platform, Directory;
$improt "dart:isolate" show Isolate;
$improt "package:foo/foo.dart" deferred as foo;
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
  Uri res4 = await Isolate.resolvePackageUri(Uri.parse("package:bar/bar"));
  Uri res5 = await Isolate.resolvePackageUri(Uri.parse("relative/path"));
  Uri res6 = await Isolate.resolvePackageUri(
      Uri.parse("http://example.org/file"));
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
    "bar/bar": res4?.toString(),
    "relative": res5?.toString(),
    "nonpkg": res6?.toString(),
  }));
}
""";

/// Script that spawns a new Isolate using Isolate.spawnUri.
///
/// Takes URI of target isolate, package config, package root and
/// automatic package resolution-flag parameters as command line arguments.
/// Any further arguments are forwarded to the spawned isolate.
const String spawnUriMain = """
$improt "dart:isolate";
$improt "dart:async";
main(args) async {
  Uri target = Uri.parse(args[0]);
  Uri config = (args[1] == "-") ? null : Uri.parse(args[1]);
  Uri root = (args[2] == "-") ? null : Uri.parse(args[2]);
  bool search = args[3] == "true";
  var restArgs = args.skip(4).toList();
  // Port keeps isolate alive until spawned isolate terminates.
  var port = new RawReceivePort();
  port.handler = (res) async {
    port.close();  // Close on exit or first error.
    if (res != null) {
      await new Future.error(res[0], new StackTrace.fromString(res[1]));
    }
  };
  Isolate.spawnUri(target, restArgs, null,
                   packageRoot: root, packageConfig: config,
                   automaticPackageResolution: search,
                   onError: port.sendPort, onExit: port.sendPort);
}
""";

/// Script that spawns a new Isolate using Isolate.spawn.
///
/// Uses the first argument to select which target to spawn.
/// Should be either "test", "uri" or "spawn".
const String spawnMain = """
$improt "dart:async";
$improt "dart:isolate";
$improt "%mainDir/main.dart" as test;
$improt "%mainDir/spawnUriMain.dart" as spawnUri;
main(List<String> args) async {
  // Port keeps isolate alive until spawned isolate terminates.
  var port = new RawReceivePort();
  port.handler = (res) async {
    port.close();  // Close on exit or first error.
    if (res != null) {
      await new Future.error(res[0], new StackTrace.fromString(res[1]));
    }
  };
  var arg = args.first;
  var rest = args.skip(1).toList();
  var target;
  if (arg == "main") {
    target = test.main;
  } else if (arg == "spawnUriMain") {
    target = spawnUri.main;
  } else {
    target = main;
  }
  Isolate.spawn(target, rest, onError: port.sendPort, onExit: port.sendPort);
}
""";

/// A package directory containing only one package, "foo", with one file.
const Map fooPackage = const {
  "foo": const {"foo": "var x = 'qux';"}
};

/// Runs the Dart executable with the provided parameters.
///
/// Captures and returns the output.
Future<String> execDart(String script,
    {String root, String config, Iterable<String> scriptArgs}) async {
  var checked = false;
  assert((checked = true));
  // TODO: Find a way to change CWD before running script.
  var executable = Platform.executable;
  var args = [];
  if (checked) args.add("--checked");
  if (root != null) args.add("--package-root=$root");
  if (config != null) args.add("--packages=$config");
  args.add(script);
  if (scriptArgs != null) {
    args.addAll(scriptArgs);
  }
  return Process.run(executable, args).then((results) {
    if (results.exitCode != 0 || results.stderr.isNotEmpty) {
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
void createFiles(Directory tempDir, String subDir, Map content) {
  Directory createDir(Directory base, String name) {
    Directory newDir = new Directory(p.join(base.path, name));
    newDir.createSync();
    return newDir;
  }

  void createTextFile(Directory base, String name, String content) {
    File newFile = new File(p.join(base.path, name));
    newFile.writeAsStringSync(content);
  }

  void createRecursive(Directory dir, Map map) {
    for (var name in map.keys) {
      var content = map[name];
      if (content is String) {
        // If the name starts with "." it's a .packages file, otherwise it's
        // a dart file. Those are the only files we care about in this test.
        createTextFile(
            dir, name.startsWith(".") ? name : name + ".dart", content);
      } else {
        assert(content is Map);
        var subdir = createDir(dir, name);
        createRecursive(subdir, content);
      }
    }
  }

  createRecursive(createDir(tempDir, subDir), content);
}

/// Start an HTTP server which serves a directory/file structure.
///
/// The directories and files are described by [files].
///
/// Each map key is an entry in a directory. A `Map` value is a sub-directory
/// and a `String` value is a text file.
/// The file contents are run through [fixPaths] to allow them to be self-
/// referential.
Future<HttpServer> startServer(Map files) async {
  return (await HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 0))
    ..forEach((request) {
      var result = files;
      onFailure:
      {
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
          request.response
            ..write(result)
            ..close();
          return;
        }
      }
      request.response
        ..statusCode = HttpStatus.NOT_FOUND
        ..close();
    });
}

// Counter used to avoid reusing temporary file or directory names.
//
// Used when adding extra files to an existing directory structure,
// and when creating temporary directories.
//
// Some platform temporary-directory implementations are timer based,
// and creating two temp-dirs withing a short duration may cause a collision.
int tmpNameCounter = 0;

// Fresh file name.
String freshName([String base = "tmp"]) => "$base${tmpNameCounter++}";

Directory createTempDir() {
  return Directory.systemTemp.createTempSync(freshName("pftest-"));
}

typedef void ConfigUpdate(Configuration configuration);

/// The configuration for a single test.
class Configuration {
  /// The "description" of the test - a description of the set-up.
  final String description;

  /// The package root parameter passed to the Dart isolate.
  ///
  /// At most one of [root] and [config] should be supplied. If both are
  /// omitted, a VM will search for a packages file or dir.
  final String root;

  /// The package configuration file location passed to the Dart isolate.
  final String config;

  /// Path to the main file to run.
  final String mainFile;

  /// List of arguments to pass to the main function.
  final List<String> args;

  /// The expected values for `Platform.package{Root,Config}`,
  /// `Isolate.package{Root,Config}` and resolution of package URIs
  /// in a `foo` package.
  ///
  /// The results are found by running the `main.dart` file inside [mainDir].
  /// The tests can run this file after doing other `spawn` or `spawnUri` calls.
  final Map expect;

  Configuration(
      {this.description,
      this.root,
      this.config,
      this.mainFile,
      this.args,
      this.expect});

  // Gets the type of main file, one of `main`, `spawnMain` or `spawnUriMain`.
  String get mainType {
    var lastSlash = mainFile.lastIndexOf("/");
    if (lastSlash < 0) {
      // Assume it's a Windows path.
      lastSlash = mainFile.lastIndexOf(r"\");
    }
    var name = mainFile.substring(lastSlash + 1, mainFile.length - 5);
    assert(name == "main" || name == "spawnMain" || name == "spawnUriMain");
    return name;
  }

  String get mainPath {
    var lastSlash = mainFile.lastIndexOf("/");
    if (lastSlash < 0) {
      // Assume it's a Windows path.
      lastSlash = mainFile.lastIndexOf(r"\");
    }
    return mainFile.substring(0, lastSlash + 1);
  }

  /// Create a new configuration from the old one.
  ///
  /// [description] is new description.
  ///
  /// [main] is one of `main`, `spawnMain` or `spawnUriMain`, and changes
  /// the [Configuration.mainFile] to a different file in the same directory.
  ///
  /// [mainFile] overrides [Configuration.mainFile] completely, and ignores
  /// [main].
  ///
  /// [newArgs] are prepended to the existing [Configuration.args].
  ///
  /// [args] overrides [Configuration.args] completely and ignores [newArgs].
  ///
  /// [expect] overrides individual expectations.
  ///
  /// [root] and [config] overrides the existing values.
  Configuration update(
      {String description,
      String main,
      String mainFile,
      String root,
      String config,
      List<String> args,
      List<String> newArgs,
      Map expect}) {
    return new Configuration(
        description: description ?? this.description,
        root: root ?? this.root,
        config: config ?? this.config,
        mainFile: mainFile ??
            ((main == null) ? this.mainFile : "${this.mainPath}$main.dart"),
        args: args ??
            (<String>[]
              ..addAll(newArgs ?? const <String>[])
              ..addAll(this.args)),
        expect: expect == null ? this.expect : new Map.from(this.expect)
          ..addAll(expect ?? const {}));
  }

  // For debugging.
  String toString() {
    return "Configuration($description\n"
        "  root  : $root\n"
        "  config: $config\n"
        "  main  : $mainFile\n"
        "  args  : ${args.map((x) => '"$x"').join(" ")}\n"
        ") : expect {\n${expect.keys.map((k) =>
           '  "$k"'.padRight(6) + ":${JSON.encode(expect[k])}\n").join()}"
        "}";
  }
}

// Inserts the file with generalized [name] at [path] with [content].
//
// The [path] is a directory where the file is created. It must start with
// either '%file/' or '%http/' to select the structure to put it into.
//
// The [name] should not have a trailing ".dart" for Dart files. Any file
// not starting with "." is assumed to be a ".dart" file.
void insertFileAt(
    Map file, Map http, String path, String name, String content) {
  var parts = path.split('/').toList();
  var dir = (parts[0] == "%file") ? file : http;
  for (var i = 1; i < parts.length - 1; i++) {
    var entry = parts[i];
    dir = dir[entry] ?? (dir[entry] = {});
  }
  dir[name] = content;
}
