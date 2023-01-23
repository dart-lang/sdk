import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart2js_info/info.dart';

List<RuntimeClassInfo> runtimeInfoFromAngularInfo(String angularInfoFilePath) {
  final angularInfoFile = File(angularInfoFilePath);
  final runtimeInfo = <RuntimeClassInfo>[];
  final separator = ' - ';
  for (final line in angularInfoFile.readAsLinesSync()) {
    // Ignore lines without two ' - ' separators.
    if (separator.allMatches(line).length != 2) continue;
    runtimeInfo.add(RuntimeClassInfo.fromAngularInfo(line));
  }
  return runtimeInfo;
}

class RuntimePackageInfo {
  final elements = PriorityQueue<BasicInfo>((a, b) => b.size.compareTo(a.size));

  num mainUnitSize = 0;
  num totalSize = 0;
  num unusedMainUnitSize = 0;
  num unusedSize = 0;
  num usedRatio = 0;
  num usedSize = 0;

  RuntimePackageInfo();

  void add(BasicInfo i, {bool used = true}) {
    totalSize += i.size;
    if (used) {
      usedSize += i.size;
    } else {
      unusedSize += i.size;
    }
    if (i.outputUnit!.name == 'main') {
      mainUnitSize += i.size;
      if (!used) {
        unusedMainUnitSize += i.size;
      }
    }
    elements.add(i);
    usedRatio = usedSize / totalSize;
  }
}

class RuntimeClassInfo {
  late String scheme;
  late String package;
  late String? path;
  late String name;

  late num size;
  late bool used;
  late bool inMainUnit;
  late ClassInfo info;

  bool annotated = false;

  RuntimeClassInfo();

  RuntimeClassInfo.fromQualifiedName(String qualifiedName) {
    final colonIndex = qualifiedName.indexOf(':');
    final slashIndex = qualifiedName.indexOf('/');
    final colonIndex2 = qualifiedName.lastIndexOf(':');
    scheme = qualifiedName.substring(0, colonIndex);
    package = qualifiedName.substring(colonIndex + 1, slashIndex);
    path = qualifiedName.substring(slashIndex + 1, colonIndex2);
    name = qualifiedName.substring(colonIndex2 + 1, qualifiedName.length);
  }

  /// Ingests the output from Angular's info generator.
  ///
  /// Example: 'fully:qualified/path/to/file.dart - ClassName - 123 (bytes)'
  RuntimeClassInfo.fromAngularInfo(String rawInput) {
    final separator = ' - ';
    final separatorSize = separator.length;
    // Remove the size specification.
    var input = rawInput;
    if (separator.allMatches(rawInput).length > 1) {
      input = rawInput.substring(0, rawInput.lastIndexOf(separator));
    }
    final colonIndex = input.indexOf(':');
    if (colonIndex < 0) {
      throw ArgumentError('AngularInfo format cannot accept undefined schemes.'
          ' No scheme found for: $input');
    }
    final slashIndex = input.indexOf('/');
    final spaceIndex = input.indexOf(' ');
    scheme = input.substring(0, colonIndex);
    if (slashIndex < 0) {
      path = null;
      package = input.substring(colonIndex + 1, spaceIndex);
    } else {
      package = input.substring(colonIndex + 1, slashIndex);
      path = input.substring(slashIndex + 1, spaceIndex);
    }
    name = input.substring(spaceIndex + separatorSize, input.length);
  }

  String get key =>
      '$package${path == null ? '' : '/$path'}:$name'.replaceAll('/lib/', '/');

  void annotateWithClassInfo(ClassInfo i, {bool used = true}) {
    size = i.size;
    this.used = used;
    inMainUnit = i.outputUnit!.name == 'main';
    info = i;
    annotated = true;
  }

  @override
  String toString() {
    return '$package/$path - $name';
  }
}
