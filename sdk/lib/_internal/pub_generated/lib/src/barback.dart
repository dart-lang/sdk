library pub.barback;
import 'package:barback/barback.dart';
import 'package:path/path.dart' as p;
import 'version.dart';
final pubConstraints = {
  "barback": new VersionConstraint.parse(">=0.13.0 <0.15.1"),
  "source_span": new VersionConstraint.parse(">=1.0.0 <2.0.0"),
  "stack_trace": new VersionConstraint.parse(">=0.9.1 <2.0.0")
};
Uri idToPackageUri(AssetId id) {
  if (!id.path.startsWith('lib/')) {
    throw new ArgumentError("Asset id $id doesn't identify a library.");
  }
  return new Uri(
      scheme: 'package',
      path: p.url.join(id.package, id.path.replaceFirst('lib/', '')));
}
AssetId packagesUrlToId(Uri url) {
  var parts = p.url.split(url.path);
  if (parts.isNotEmpty && parts.first == "/") parts = parts.skip(1).toList();
  if (parts.isEmpty) return null;
  var index = parts.indexOf("packages");
  if (index == -1) return null;
  if (parts.length <= index + 1) {
    throw new FormatException(
        'Invalid URL path "${url.path}". Expected package name ' 'after "packages".');
  }
  var package = parts[index + 1];
  var assetPath = p.url.join("lib", p.url.joinAll(parts.skip(index + 2)));
  return new AssetId(package, assetPath);
}
