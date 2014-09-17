library pub.sdk;
import 'dart:io';
import 'package:path/path.dart' as path;
import 'io.dart';
import 'version.dart';
final String rootDirectory =
    runningFromSdk ? _rootDirectory : path.join(repoRoot, "sdk");
final String _rootDirectory = path.dirname(path.dirname(Platform.executable));
Version version = _getVersion();
Version _getVersion() {
  var sdkVersion = Platform.environment["_PUB_TEST_SDK_VERSION"];
  if (sdkVersion != null) return new Version.parse(sdkVersion);
  if (runningFromSdk) {
    var version = readTextFile(path.join(_rootDirectory, "version")).trim();
    return new Version.parse(version);
  }
  var contents = readTextFile(path.join(repoRoot, "tools/VERSION"));
  parseField(name) {
    var pattern = new RegExp("^$name ([a-z0-9]+)", multiLine: true);
    var match = pattern.firstMatch(contents);
    return match[1];
  }
  var channel = parseField("CHANNEL");
  var major = parseField("MAJOR");
  var minor = parseField("MINOR");
  var patch = parseField("PATCH");
  var prerelease = parseField("PRERELEASE");
  var prereleasePatch = parseField("PRERELEASE_PATCH");
  var version = "$major.$minor.$patch";
  if (channel == "be") {
    version += "-edge";
  } else if (channel == "dev") {
    version += "-dev.$prerelease.$prereleasePatch";
  }
  return new Version.parse(version);
}
