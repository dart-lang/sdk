library test_pub;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_process.dart';
import 'package:scheduled_test/scheduled_server.dart';
import 'package:scheduled_test/scheduled_stream.dart';
import 'package:scheduled_test/scheduled_test.dart' hide fail;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:unittest/compact_vm_config.dart';
import 'package:yaml/yaml.dart';
import '../lib/src/entrypoint.dart';
import '../lib/src/exit_codes.dart' as exit_codes;
import '../lib/src/git.dart' as gitlib;
import '../lib/src/http.dart';
import '../lib/src/io.dart';
import '../lib/src/lock_file.dart';
import '../lib/src/log.dart' as log;
import '../lib/src/package.dart';
import '../lib/src/pubspec.dart';
import '../lib/src/source/hosted.dart';
import '../lib/src/source/path.dart';
import '../lib/src/source_registry.dart';
import '../lib/src/system_cache.dart';
import '../lib/src/utils.dart';
import '../lib/src/validator.dart';
import '../lib/src/version.dart';
import 'descriptor.dart' as d;
import 'serve_packages.dart';
export 'serve_packages.dart';
initConfig() {
  useCompactVMConfiguration();
  filterStacks = true;
  unittestConfiguration.timeout = null;
}
var _server;
final _requestedPaths = <String>[];
Completer<int> _portCompleterCache;
Matcher isMinifiedDart2JSOutput =
    isNot(contains("// The code supports the following hooks"));
Matcher isUnminifiedDart2JSOutput =
    contains("// The code supports the following hooks");
Map<String, String> _packageOverrides;
final _barbackVersions = _findBarbackVersions();
final _barbackDeps = {
  new VersionConstraint.parse("<0.15.0"): {
    "source_maps": "0.9.4"
  }
};
Map<Version, String> _findBarbackVersions() {
  var versions = {};
  var currentBarback = p.join(repoRoot, 'pkg', 'barback');
  versions[new Pubspec.load(currentBarback, new SourceRegistry()).version] =
      currentBarback;
  for (var dir in listDir(p.join(repoRoot, 'third_party', 'pkg'))) {
    var basename = p.basename(dir);
    if (!basename.startsWith('barback')) continue;
    versions[new Version.parse(split1(basename, '-').last)] = dir;
  }
  return versions;
}
void withBarbackVersions(String versionConstraint, void callback()) {
  var constraint = new VersionConstraint.parse(versionConstraint);
  var validVersions = _barbackVersions.keys.where(constraint.allows);
  if (validVersions.isEmpty) {
    throw new ArgumentError(
        'No available barback version matches "$versionConstraint".');
  }
  for (var version in validVersions) {
    group("with barback $version", () {
      setUp(() {
        _packageOverrides = {};
        _packageOverrides['barback'] = _barbackVersions[version];
        _barbackDeps.forEach((constraint, deps) {
          if (!constraint.allows(version)) return;
          deps.forEach((packageName, version) {
            _packageOverrides[packageName] =
                p.join(repoRoot, 'third_party', 'pkg', '$packageName-$version');
          });
        });
        currentSchedule.onComplete.schedule(() {
          _packageOverrides = null;
        });
      });
      callback();
    });
  }
}
Completer<int> get _portCompleter {
  if (_portCompleterCache != null) return _portCompleterCache;
  _portCompleterCache = new Completer<int>();
  currentSchedule.onComplete.schedule(() {
    _portCompleterCache = null;
  }, 'clearing the port completer');
  return _portCompleterCache;
}
Future<int> get port => _portCompleter.future;
Future<List<String>> getRequestedPaths() {
  return schedule(() {
    var paths = _requestedPaths.toList();
    _requestedPaths.clear();
    return paths;
  }, "get previous network requests");
}
void serve([List<d.Descriptor> contents]) {
  var baseDir = d.dir("serve-dir", contents);
  _hasServer = true;
  schedule(() {
    return _closeServer().then((_) {
      return shelf_io.serve((request) {
        currentSchedule.heartbeat();
        var path = p.posix.fromUri(request.url.path.replaceFirst("/", ""));
        _requestedPaths.add(path);
        return validateStream(
            baseDir.load(
                path)).then((stream) => new shelf.Response.ok(stream)).catchError((error) {
          return new shelf.Response.notFound('File "$path" not found.');
        });
      }, 'localhost', 0).then((server) {
        _server = server;
        _portCompleter.complete(_server.port);
        currentSchedule.onComplete.schedule(_closeServer);
      });
    });
  }, 'starting a server serving:\n${baseDir.describe()}');
}
Future _closeServer() {
  if (_server == null) return new Future.value();
  var future = _server.close();
  _server = null;
  _hasServer = false;
  _portCompleterCache = null;
  return future;
}
bool _hasServer = false;
String yaml(value) => JSON.encode(value);
String get sandboxDir => _sandboxDir;
String _sandboxDir;
final String pkgPath =
    p.absolute(p.join(p.dirname(Platform.executable), '../../../../pkg'));
final String cachePath = "cache";
final String appPath = "myapp";
final String packagesPath = "$appPath/packages";
bool _abortScheduled = false;
class RunCommand {
  static final get = new RunCommand(
      'get',
      new RegExp(r'Got dependencies!|Changed \d+ dependenc(y|ies)!'));
  static final upgrade = new RunCommand(
      'upgrade',
      new RegExp(r'(No dependencies changed\.|Changed \d+ dependenc(y|ies)!)$'));
  static final downgrade = new RunCommand(
      'downgrade',
      new RegExp(r'(No dependencies changed\.|Changed \d+ dependenc(y|ies)!)$'));
  final String name;
  final RegExp success;
  RunCommand(this.name, this.success);
}
void forBothPubGetAndUpgrade(void callback(RunCommand command)) {
  group(RunCommand.get.name, () => callback(RunCommand.get));
  group(RunCommand.upgrade.name, () => callback(RunCommand.upgrade));
}
void pubCommand(RunCommand command, {Iterable<String> args, output, error,
    warning, int exitCode}) {
  if (error != null && warning != null) {
    throw new ArgumentError("Cannot pass both 'error' and 'warning'.");
  }
  var allArgs = [command.name];
  if (args != null) allArgs.addAll(args);
  if (output == null) output = command.success;
  if (error != null && exitCode == null) exitCode = 1;
  if (error != null) output = null;
  if (warning != null) error = warning;
  schedulePub(args: allArgs, output: output, error: error, exitCode: exitCode);
}
void pubGet({Iterable<String> args, output, error, warning, int exitCode}) {
  pubCommand(
      RunCommand.get,
      args: args,
      output: output,
      error: error,
      warning: warning,
      exitCode: exitCode);
}
void pubUpgrade({Iterable<String> args, output, error, warning, int exitCode}) {
  pubCommand(
      RunCommand.upgrade,
      args: args,
      output: output,
      error: error,
      warning: warning,
      exitCode: exitCode);
}
void pubDowngrade({Iterable<String> args, output, error, warning, int exitCode})
    {
  pubCommand(
      RunCommand.downgrade,
      args: args,
      output: output,
      error: error,
      warning: warning,
      exitCode: exitCode);
}
ScheduledProcess pubRun({bool global: false, Iterable<String> args}) {
  var pubArgs = global ? ["global", "run"] : ["run"];
  pubArgs.addAll(args);
  var pub = startPub(args: pubArgs);
  pub.stdout.expect(consumeWhile(startsWith("Loading")));
  return pub;
}
void integration(String description, void body()) =>
    _integration(description, body, test);
void solo_integration(String description, void body()) =>
    _integration(description, body, solo_test);
void _integration(String description, void body(), [Function testFn]) {
  testFn(description, () {
    currentSchedule.timeout *= 2;
    if (Platform.operatingSystem == "windows") {
      currentSchedule.timeout *= 2;
    }
    _sandboxDir = createSystemTempDir();
    d.defaultRoot = sandboxDir;
    currentSchedule.onComplete.schedule(
        () => deleteEntry(_sandboxDir),
        'deleting the sandbox directory');
    body();
  });
}
String get testDirectory => p.absolute(p.dirname(libraryPath('test_pub')));
void scheduleRename(String from, String to) {
  schedule(
      () => renameDir(p.join(sandboxDir, from), p.join(sandboxDir, to)),
      'renaming $from to $to');
}
void scheduleSymlink(String target, String symlink) {
  schedule(
      () => createSymlink(p.join(sandboxDir, target), p.join(sandboxDir, symlink)),
      'symlinking $target to $symlink');
}
void schedulePub({List args, output, error, outputJson,
    Future<Uri> tokenEndpoint, int exitCode: exit_codes.SUCCESS}) {
  assert(output == null || outputJson == null);
  var pub = startPub(args: args, tokenEndpoint: tokenEndpoint);
  pub.shouldExit(exitCode);
  var failures = [];
  var stderr;
  expect(
      Future.wait(
          [pub.stdoutStream().toList(), pub.stderrStream().toList()]).then((results) {
    var stdout = results[0].join("\n");
    stderr = results[1].join("\n");
    if (outputJson == null) {
      _validateOutput(failures, 'stdout', output, stdout);
      return null;
    }
    return awaitObject(outputJson).then((resolved) {
      _validateOutputJson(failures, 'stdout', resolved, stdout);
    });
  }).then((_) {
    _validateOutput(failures, 'stderr', error, stderr);
    if (!failures.isEmpty) throw new TestFailure(failures.join('\n'));
  }), completes);
}
ScheduledProcess startPublish(ScheduledServer server, {List args}) {
  var tokenEndpoint =
      server.url.then((url) => url.resolve('/token').toString());
  if (args == null) args = [];
  args = flatten(['lish', '--server', tokenEndpoint, args]);
  return startPub(args: args, tokenEndpoint: tokenEndpoint);
}
void confirmPublish(ScheduledProcess pub) {
  pub.stdout.expect(startsWith('Publishing test_pkg 1.0.0 to '));
  pub.stdout.expect(
      emitsLines(
          "|-- LICENSE\n" "|-- lib\n" "|   '-- test_pkg.dart\n" "'-- pubspec.yaml\n" "\n"
              "Looks great! Are you ready to upload your package (y/n)?"));
  pub.writeLine("y");
}
String _pathInSandbox(String relPath) {
  return p.join(p.absolute(sandboxDir), relPath);
}
Map getPubTestEnvironment([String tokenEndpoint]) {
  var environment = {};
  environment['_PUB_TESTING'] = 'true';
  environment['PUB_CACHE'] = _pathInSandbox(cachePath);
  environment['_PUB_TEST_SDK_VERSION'] = "0.1.2+3";
  if (tokenEndpoint != null) {
    environment['_PUB_TEST_TOKEN_ENDPOINT'] = tokenEndpoint.toString();
  }
  return environment;
}
ScheduledProcess startPub({List args, Future<String> tokenEndpoint}) {
  ensureDir(_pathInSandbox(appPath));
  var dartBin = Platform.executable;
  if (dartBin.contains(Platform.pathSeparator)) {
    dartBin = p.absolute(dartBin);
  }
  var pubPath = p.join(p.dirname(dartBin), 'snapshots/pub.dart.snapshot');
  var dartArgs = [pubPath, '--verbose'];
  dartArgs.addAll(args);
  if (tokenEndpoint == null) tokenEndpoint = new Future.value();
  var environmentFuture = tokenEndpoint.then((tokenEndpoint) {
    var environment = getPubTestEnvironment(tokenEndpoint);
    if (_hasServer) {
      return port.then((p) {
        environment['PUB_HOSTED_URL'] = "http://localhost:$p";
        return environment;
      });
    }
    return environment;
  });
  return new PubProcess.start(
      dartBin,
      dartArgs,
      environment: environmentFuture,
      workingDirectory: _pathInSandbox(appPath),
      description: args.isEmpty ? 'pub' : 'pub ${args.first}');
}
class PubProcess extends ScheduledProcess {
  Stream<Pair<log.Level, String>> _log;
  Stream<String> _stdout;
  Stream<String> _stderr;
  PubProcess.start(executable, arguments, {workingDirectory, environment,
      String description, Encoding encoding: UTF8})
      : super.start(
          executable,
          arguments,
          workingDirectory: workingDirectory,
          environment: environment,
          description: description,
          encoding: encoding);
  Stream<Pair<log.Level, String>> _logStream() {
    if (_log == null) {
      _log = mergeStreams(
          _outputToLog(super.stdoutStream(), log.Level.MESSAGE),
          _outputToLog(super.stderrStream(), log.Level.ERROR));
    }
    var pair = tee(_log);
    _log = pair.first;
    return pair.last;
  }
  final _logLineRegExp = new RegExp(r"^([A-Z ]{4})[:|] (.*)$");
  final _logLevels = [
      log.Level.ERROR,
      log.Level.WARNING,
      log.Level.MESSAGE,
      log.Level.IO,
      log.Level.SOLVER,
      log.Level.FINE].fold(<String, log.Level>{}, (levels, level) {
    levels[level.name] = level;
    return levels;
  });
  Stream<Pair<log.Level, String>> _outputToLog(Stream<String> stream,
      log.Level defaultLevel) {
    var lastLevel;
    return stream.map((line) {
      var match = _logLineRegExp.firstMatch(line);
      if (match == null) return new Pair<log.Level, String>(defaultLevel, line);
      var level = _logLevels[match[1]];
      if (level == null) level = lastLevel;
      lastLevel = level;
      return new Pair<log.Level, String>(level, match[2]);
    });
  }
  Stream<String> stdoutStream() {
    if (_stdout == null) {
      _stdout = _logStream().expand((entry) {
        if (entry.first != log.Level.MESSAGE) return [];
        return [entry.last];
      });
    }
    var pair = tee(_stdout);
    _stdout = pair.first;
    return pair.last;
  }
  Stream<String> stderrStream() {
    if (_stderr == null) {
      _stderr = _logStream().expand((entry) {
        if (entry.first != log.Level.ERROR &&
            entry.first != log.Level.WARNING) {
          return [];
        }
        return [entry.last];
      });
    }
    var pair = tee(_stderr);
    _stderr = pair.first;
    return pair.last;
  }
}
String get _packageRoot => p.absolute(Platform.packageRoot);
void ensureGit() {
  if (Platform.operatingSystem == "windows") {
    currentSchedule.timeout = new Duration(seconds: 30);
  }
  if (!gitlib.isInstalled) {
    throw new Exception("Git must be installed to run this test.");
  }
}
void makeGlobalPackage(String package, String version,
    Iterable<d.Descriptor> contents, {Iterable<String> pkg, Map<String,
    String> hosted}) {
  serveNoPackages();
  d.hostedCache([d.dir("$package-$version", contents)]).create();
  var lockFile = _createLockFile(pkg: pkg, hosted: hosted);
  var id =
      new PackageId(package, "hosted", new Version.parse(version), package);
  lockFile.packages[package] = id;
  var sources = new SourceRegistry();
  sources.register(new HostedSource());
  sources.register(new PathSource());
  d.dir(
      cachePath,
      [
          d.dir(
              "global_packages",
              [d.file("$package.lock", lockFile.serialize(null, sources))])]).create();
}
void createLockFile(String package, {Iterable<String> sandbox,
    Iterable<String> pkg, Map<String, String> hosted}) {
  var lockFile = _createLockFile(sandbox: sandbox, pkg: pkg, hosted: hosted);
  var sources = new SourceRegistry();
  sources.register(new HostedSource());
  sources.register(new PathSource());
  d.file(
      p.join(package, 'pubspec.lock'),
      lockFile.serialize(null, sources)).create();
}
LockFile _createLockFile({Iterable<String> sandbox, Iterable<String> pkg,
    Map<String, String> hosted}) {
  var dependencies = {};
  if (sandbox != null) {
    for (var package in sandbox) {
      dependencies[package] = '../$package';
    }
  }
  if (pkg != null) {
    _addPackage(String package) {
      if (dependencies.containsKey(package)) return;
      var packagePath;
      if (package == 'barback' && _packageOverrides == null) {
        throw new StateError(
            "createLockFile() can only create a lock file "
                "with a barback dependency within a withBarbackVersions() " "block.");
      }
      if (_packageOverrides.containsKey(package)) {
        packagePath = _packageOverrides[package];
      } else {
        packagePath = p.join(pkgPath, package);
      }
      dependencies[package] = packagePath;
      var pubspec = loadYaml(readTextFile(p.join(packagePath, 'pubspec.yaml')));
      var packageDeps = pubspec['dependencies'];
      if (packageDeps == null) return;
      packageDeps.keys.forEach(_addPackage);
    }
    pkg.forEach(_addPackage);
  }
  var lockFile = new LockFile.empty();
  dependencies.forEach((name, dependencyPath) {
    var id = new PackageId(name, 'path', new Version(0, 0, 0), {
      'path': dependencyPath,
      'relative': p.isRelative(dependencyPath)
    });
    lockFile.packages[name] = id;
  });
  if (hosted != null) {
    hosted.forEach((name, version) {
      var id = new PackageId(name, 'hosted', new Version.parse(version), name);
      lockFile.packages[name] = id;
    });
  }
  return lockFile;
}
void useMockClient(MockClient client) {
  var oldInnerClient = innerHttpClient;
  innerHttpClient = client;
  currentSchedule.onComplete.schedule(() {
    innerHttpClient = oldInnerClient;
  }, 'de-activating the mock client');
}
Map packageMap(String name, String version, [Map dependencies]) {
  var package = {
    "name": name,
    "version": version,
    "author": "Natalie Weizenbaum <nweiz@google.com>",
    "homepage": "http://pub.dartlang.org",
    "description": "A package, I guess."
  };
  if (dependencies != null) package["dependencies"] = dependencies;
  return package;
}
String testAssetPath(String target) {
  var libPath = libraryPath('test_pub');
  libPath = libPath.replaceAll('pub_generated', 'pub');
  return p.join(p.dirname(libPath), 'asset', target);
}
Map packageVersionApiMap(Map pubspec, {bool full: false}) {
  var name = pubspec['name'];
  var version = pubspec['version'];
  var map = {
    'pubspec': pubspec,
    'version': version,
    'url': '/api/packages/$name/versions/$version',
    'archive_url': '/packages/$name/versions/$version.tar.gz',
    'new_dartdoc_url': '/api/packages/$name/versions/$version' '/new_dartdoc',
    'package_url': '/api/packages/$name'
  };
  if (full) {
    map.addAll({
      'downloads': 0,
      'created': '2012-09-25T18:38:28.685260',
      'libraries': ['$name.dart'],
      'uploader': ['nweiz@google.com']
    });
  }
  return map;
}
void _validateOutput(List<String> failures, String pipe, expected,
    String actual) {
  if (expected == null) return;
  if (expected is String) {
    _validateOutputString(failures, pipe, expected, actual);
  } else {
    if (expected is RegExp) expected = matches(expected);
    expect(actual, expected);
  }
}
void _validateOutputString(List<String> failures, String pipe, String expected,
    String actual) {
  var actualLines = actual.split("\n");
  var expectedLines = expected.split("\n");
  if (expectedLines.last.trim() == '') {
    expectedLines.removeLast();
  }
  var results = [];
  var failed = false;
  var length = max(expectedLines.length, actualLines.length);
  for (var i = 0; i < length; i++) {
    if (i >= actualLines.length) {
      failed = true;
      results.add('? ${expectedLines[i]}');
    } else if (i >= expectedLines.length) {
      failed = true;
      results.add('X ${actualLines[i]}');
    } else {
      var expectedLine = expectedLines[i].trim();
      var actualLine = actualLines[i].trim();
      if (expectedLine != actualLine) {
        failed = true;
        results.add('X ${actualLines[i]}');
      } else {
        results.add('| ${actualLines[i]}');
      }
    }
  }
  if (failed) {
    failures.add('Expected $pipe:');
    failures.addAll(expectedLines.map((line) => '| $line'));
    failures.add('Got:');
    failures.addAll(results);
  }
}
void _validateOutputJson(List<String> failures, String pipe, expected,
    String actualText) {
  var actual;
  try {
    actual = JSON.decode(actualText);
  } on FormatException catch (error) {
    failures.add('Expected $pipe JSON:');
    failures.add(expected);
    failures.add('Got invalid JSON:');
    failures.add(actualText);
  }
  expect(actual, expected);
}
typedef Validator ValidatorCreator(Entrypoint entrypoint);
Future<Pair<List<String>, List<String>>>
    schedulePackageValidation(ValidatorCreator fn) {
  return schedule(() {
    var cache = new SystemCache.withSources(p.join(sandboxDir, cachePath));
    return new Future.sync(() {
      var validator = fn(new Entrypoint(p.join(sandboxDir, appPath), cache));
      return validator.validate().then((_) {
        return new Pair(validator.errors, validator.warnings);
      });
    });
  }, "validating package");
}
Matcher pairOf(Matcher firstMatcher, Matcher lastMatcher) =>
    new _PairMatcher(firstMatcher, lastMatcher);
class _PairMatcher extends Matcher {
  final Matcher _firstMatcher;
  final Matcher _lastMatcher;
  _PairMatcher(this._firstMatcher, this._lastMatcher);
  bool matches(item, Map matchState) {
    if (item is! Pair) return false;
    return _firstMatcher.matches(item.first, matchState) &&
        _lastMatcher.matches(item.last, matchState);
  }
  Description describe(Description description) {
    return description.addAll("(", ", ", ")", [_firstMatcher, _lastMatcher]);
  }
}
StreamMatcher emitsLines(String output) => inOrder(output.split("\n"));
