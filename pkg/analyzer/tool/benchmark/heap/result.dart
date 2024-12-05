// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/manifest/manifest_validator.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:collection/collection.dart';

String formatSizeInBytes(int value) {
  var buffer = StringBuffer();
  buffer.write('$value');

  var kb = value ~/ 1024;
  if (kb.abs() > 0) {
    buffer.write(' = $kb KB');
  }

  var mb = kb / 1024;
  if (mb.abs() >= 1.0) {
    buffer.write(' = ${mb.toStringAsFixed(1)} MB');
  }

  var gb = mb / 1024;
  if (gb.abs() >= 1.0) {
    buffer.write(' = ${gb.toStringAsFixed(2)} GB');
  }

  return buffer.toString();
}

void _writeDisplayText(
  TreeStringSink sink,
  BenchmarkResult result,
  BenchmarkResult? base,
) {
  switch (result) {
    case BenchmarkResultBytes():
      var sizeStr = formatSizeInBytes(result.value);
      sink.writelnWithIndent('${result.name}: $sizeStr');
      if (base is BenchmarkResultBytes) {
        var diff = result.value - base.value;
        if (diff != 0) {
          sink.withIndent(() {
            var diffStr = formatSizeInBytes(diff);
            var diffPercent = 100 * diff / base.value;
            var diffPercentStr = diffPercent.toStringAsFixed(2);
            sink.writelnWithIndent('change: $diffPercentStr% $diffStr');
          });
        }
      }
    case BenchmarkResultCompound():
      sink.writelnWithIndent(result.name);
      sink.withIndent(() {
        for (var child in result.children) {
          var childBase = base
              .ifTypeOrNull<BenchmarkResultCompound>()
              ?.children
              .firstWhereOrNull((e) => e.name == child.name);
          _writeDisplayText(sink, child, childBase);
        }
      });
    case BenchmarkResultCount():
      sink.writelnWithIndent('${result.name}: ${result.value}');
      if (base is BenchmarkResultCount) {
        var diff = result.value - base.value;
        if (diff != 0) {
          sink.withIndent(() {
            var diffPercent = 100 * diff / base.value;
            var diffPercentStr = diffPercent.toStringAsFixed(2);
            sink.writelnWithIndent('change: $diffPercentStr% $diff');
          });
        }
      }
  }
}

void _writeXmlText(TreeStringSink sink, BenchmarkResult result) {
  switch (result) {
    case BenchmarkResultBytes():
      sink.writelnWithIndent(
        "<bytes name='${result.name}' value='${result.value}'/>",
      );
    case BenchmarkResultCompound():
      sink.writelnWithIndent("<compound name='${result.name}'>");
      sink.withIndent(() {
        for (var child in result.children) {
          _writeXmlText(sink, child);
        }
      });
      sink.writelnWithIndent('</compound>');
    case BenchmarkResultCount():
      sink.writelnWithIndent(
        "<count name='${result.name}' value='${result.value}'/>",
      );
  }
}

sealed class BenchmarkResult {
  final String name;

  BenchmarkResult({
    required this.name,
  });

  String get asXmlText {
    var buffer = StringBuffer();
    var sink = TreeStringSink(sink: buffer, indent: '');
    _writeXmlText(sink, this);
    return buffer.toString();
  }

  String asDisplayText(BenchmarkResult? base) {
    var buffer = StringBuffer();
    var sink = TreeStringSink(sink: buffer, indent: '');
    _writeDisplayText(sink, this, base);
    return buffer.toString();
  }

  static BenchmarkResult fromXmlText(String text) {
    var parser = ManifestParser.general(text, uri: Uri.parse(''));
    var tagResult = parser.parseXmlTag();
    return _fromXml(tagResult.element!);
  }

  static BenchmarkResult _fromXml(XmlElement element) {
    var name = element.attributes['name']!.value;
    switch (element.name) {
      case 'compound':
        return BenchmarkResultCompound(
          name: name,
          children: element.children.map(_fromXml).toList(),
        );
      case 'count':
        return BenchmarkResultCount(
          name: name,
          value: int.parse(element.attributes['value']!.value),
        );
      case 'bytes':
        return BenchmarkResultBytes(
          name: name,
          value: int.parse(element.attributes['value']!.value),
        );
      default:
        throw UnimplementedError(element.name);
    }
  }
}

final class BenchmarkResultBytes extends BenchmarkResult {
  final int value;

  BenchmarkResultBytes({
    required super.name,
    required this.value,
  });
}

final class BenchmarkResultCompound extends BenchmarkResult {
  final List<BenchmarkResult> children = [];

  BenchmarkResultCompound({
    required super.name,
    List<BenchmarkResult>? children,
  }) {
    if (children != null) {
      this.children.addAll(children);
    }
  }

  void add(BenchmarkResult child) {
    children.add(child);
  }
}

final class BenchmarkResultCount extends BenchmarkResult {
  final int value;

  BenchmarkResultCount({
    required super.name,
    required this.value,
  });
}
