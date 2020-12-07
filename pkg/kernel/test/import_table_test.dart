import 'package:kernel/import_table.dart';

main() {
  List<String> paths = <String>[];
  paths.add("file://");
  paths.add("file:///a");
  paths.add("file:///a/b");
  paths.add("file:///a/b/c");

  int end = paths.length;
  for (int i = 0; i < end; i++) {
    paths.add(paths[i] + "/d.dart");
    paths.add(paths[i] + "/e.dart");
    paths.add(paths[i] + "/");
  }
  paths[0] = "file:///";
  paths.sort();
  for (int i = 0; i < paths.length; i++) {
    for (int j = 0; j < paths.length; j++) {
      check(paths[i], paths[j]);
    }
  }
  check("", "");
}

void check(String target, String ref) {
  Uri uriTarget = Uri.parse(target);
  Uri uriRef = Uri.parse(ref);
  String relative = relativeUriPath(uriTarget, uriRef);
  if (Uri.base.resolveUri(uriTarget) !=
      Uri.base.resolveUri(uriRef).resolve(relative)) {
    throw "Failure on '$target' and '$ref': Got '$relative' which resolves to "
        "${uriRef.resolve(relative)}";
  }
}
