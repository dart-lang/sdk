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
  var revisionPath = path.join(_rootDirectory, "version");
  var version = readTextFile(revisionPath).trim();
  return new Version.parse(version);
}
