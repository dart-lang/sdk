library pub.source.unknown;
import 'dart:async';
import '../package.dart';
import '../pubspec.dart';
import '../source.dart';
class UnknownSource extends Source {
  final String name;
  UnknownSource(this.name);
  bool operator ==(other) => other is UnknownSource && other.name == name;
  int get hashCode => name.hashCode;
  Future<Pubspec> doDescribe(PackageId id) =>
      throw new UnsupportedError(
          "Cannot describe a package from unknown source '$name'.");
  Future get(PackageId id, String symlink) =>
      throw new UnsupportedError("Cannot get an unknown source '$name'.");
  Future<String> getDirectory(PackageId id) =>
      throw new UnsupportedError(
          "Cannot find a package from an unknown source '$name'.");
  bool descriptionsEqual(description1, description2) =>
      description1 == description2;
  dynamic parseDescription(String containingPath, description,
      {bool fromLockFile: false}) =>
      description;
}
