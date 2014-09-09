library descriptor;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:scheduled_test/scheduled_server.dart';
import 'package:scheduled_test/descriptor.dart';
import '../lib/src/io.dart';
import '../lib/src/utils.dart';
import 'descriptor/git.dart';
import 'descriptor/tar.dart';
import 'test_pub.dart';
export 'package:scheduled_test/descriptor.dart';
export 'descriptor/git.dart';
export 'descriptor/tar.dart';
GitRepoDescriptor git(String name, [Iterable<Descriptor> contents]) =>
    new GitRepoDescriptor(name, contents == null ? <Descriptor>[] : contents);
TarFileDescriptor tar(String name, [Iterable<Descriptor> contents]) =>
    new TarFileDescriptor(name, contents == null ? <Descriptor>[] : contents);
Descriptor get validPackage =>
    dir(
        appPath,
        [
            libPubspec("test_pkg", "1.0.0"),
            file("LICENSE", "Eh, do what you want."),
            dir("lib", [file("test_pkg.dart", "int i = 1;")])]);
FileDescriptor outOfDateSnapshot(String name) =>
    binaryFile(name, readBinaryFile(testAssetPath('out-of-date.snapshot')));
Descriptor pubspec(Map contents) {
  return async(
      awaitObject(
          contents).then(
              (resolvedContents) => file("pubspec.yaml", yaml(resolvedContents))));
}
Descriptor appPubspec([Map dependencies]) {
  var map = {
    "name": "myapp"
  };
  if (dependencies != null) map["dependencies"] = dependencies;
  return pubspec(map);
}
Descriptor libPubspec(String name, String version, {Map deps, String sdk}) {
  var map = packageMap(name, version, deps);
  if (sdk != null) map["environment"] = {
    "sdk": sdk
  };
  return pubspec(map);
}
Descriptor libDir(String name, [String code]) {
  if (code == null) code = name;
  return dir("lib", [file("$name.dart", 'main() => "$code";')]);
}
Descriptor gitPackageRevisionCacheDir(String name, [int modifier]) {
  var value = name;
  if (modifier != null) value = "$name $modifier";
  return pattern(
      new RegExp("$name${r'-[a-f0-9]+'}"),
      (dirName) => dir(dirName, [libDir(name, value)]));
}
Descriptor gitPackageRepoCacheDir(String name) {
  return pattern(
      new RegExp("$name${r'-[a-f0-9]+'}"),
      (dirName) =>
          dir(dirName, [dir('hooks'), dir('info'), dir('objects'), dir('refs')]));
}
Descriptor packagesDir(Map<String, String> packages) {
  var contents = <Descriptor>[];
  packages.forEach((name, version) {
    if (version == null) {
      contents.add(nothing(name));
    } else {
      contents.add(
          dir(name, [file("$name.dart", 'main() => "$name $version";')]));
    }
  });
  return dir(packagesPath, contents);
}
Descriptor cacheDir(Map packages, {bool includePubspecs: false}) {
  var contents = <Descriptor>[];
  packages.forEach((name, versions) {
    if (versions is! List) versions = [versions];
    for (var version in versions) {
      var packageContents = [libDir(name, '$name $version')];
      if (includePubspecs) {
        packageContents.add(libPubspec(name, version));
      }
      contents.add(dir("$name-$version", packageContents));
    }
  });
  return hostedCache(contents);
}
Descriptor hostedCache(Iterable<Descriptor> contents) {
  return dir(
      cachePath,
      [dir('hosted', [async(port.then((p) => dir('localhost%58$p', contents)))])]);
}
Descriptor credentialsFile(ScheduledServer server, String accessToken,
    {String refreshToken, DateTime expiration}) {
  return async(server.url.then((url) {
    return dir(
        cachePath,
        [
            file(
                'credentials.json',
                new oauth2.Credentials(
                    accessToken,
                    refreshToken,
                    url.resolve('/token'),
                    ['https://www.googleapis.com/auth/userinfo.email'],
                    expiration).toJson())]);
  }));
}
DirectoryDescriptor appDir([Map dependencies]) =>
    dir(appPath, [appPubspec(dependencies)]);
