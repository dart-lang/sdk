// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sourcemap.html_parts;

import 'sourcemap_html_helper.dart';

class Annotation {
  final id;
  final int codeOffset;
  final String title;
  final data;

  Annotation(this.id, this.codeOffset, this.title, {this.data});
}

typedef bool AnnotationFilter(Annotation annotation);
typedef AnnotationData AnnotationDataFunction(Iterable<Annotation> annotations,
    {bool forSpan});
typedef LineData LineDataFunction(lineAnnotation);

bool includeAllAnnotation(Annotation annotation) => true;

class LineData {
  final String lineClass;
  final String lineNumberClass;

  const LineData({this.lineClass: 'line', this.lineNumberClass: 'lineNumber'});
}

class AnnotationData {
  final String tag;
  final Map<String, String> properties;

  const AnnotationData(
      {this.tag: 'a', this.properties: const <String, String>{}});

  int get hashCode => tag.hashCode * 13 + properties.hashCode * 19;

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! AnnotationData) return false;
    return tag == other.tag &&
        properties.length == other.properties.length &&
        properties.keys.every((k) => properties[k] == other.properties[k]);
  }
}

AnnotationDataFunction createAnnotationDataFunction(
    {CssColorScheme colorScheme: const SingleColorScheme(),
    ElementScheme elementScheme: const ElementScheme()}) {
  return (Iterable<Annotation> annotations, {bool forSpan}) {
    return getAnnotationDataFromSchemes(annotations,
        forSpan: forSpan,
        colorScheme: colorScheme,
        elementScheme: elementScheme);
  };
}

LineData getDefaultLineData(data) => const LineData();

AnnotationData getAnnotationDataFromSchemes(Iterable<Annotation> annotations,
    {bool forSpan,
    CssColorScheme colorScheme: const SingleColorScheme(),
    ElementScheme elementScheme: const ElementScheme()}) {
  if (colorScheme.showLocationAsSpan != forSpan) return null;
  Map<String, String> data = <String, String>{};
  var id;
  if (annotations.length == 1) {
    Annotation annotation = annotations.single;
    if (annotation != null) {
      id = annotation.id;
      data['style'] = colorScheme.singleLocationToCssColor(id);
      data['title'] = annotation.title;
    }
  } else {
    id = annotations.first.id;
    List ids = [];
    for (Annotation annotation in annotations) {
      ids.add(annotation.id);
    }
    data['style'] = colorScheme.multiLocationToCssColor(ids);
    data['title'] = annotations.map((l) => l.title).join(',');
  }
  if (id != null) {
    Set ids = annotations.map((l) => l.id).toSet();
    data['tag'] = 'a';
    data['name'] = elementScheme.getName(id, ids);
    data['href'] = elementScheme.getHref(id, ids);
    data['onclick'] = elementScheme.onClick(id, ids);
    data['onmouseover'] = elementScheme.onMouseOver(id, ids);
    data['onmouseout'] = elementScheme.onMouseOut(id, ids);
    return new AnnotationData(properties: data);
  }
  return null;
}

class HtmlPrintContext {
  final int lineNoWidth;
  final bool usePre;
  final AnnotationFilter includeAnnotation;
  final AnnotationDataFunction getAnnotationData;
  final LineDataFunction getLineData;

  HtmlPrintContext(
      {this.lineNoWidth,
      this.usePre: true,
      this.includeAnnotation: includeAllAnnotation,
      this.getAnnotationData: getAnnotationDataFromSchemes,
      this.getLineData: getDefaultLineData});

  HtmlPrintContext from(
      {int lineNoWidth,
      bool usePre,
      AnnotationFilter includeAnnotation,
      AnnotationDataFunction getAnnotationData,
      LineDataFunction getLineData}) {
    return new HtmlPrintContext(
        lineNoWidth: lineNoWidth ?? this.lineNoWidth,
        usePre: usePre ?? this.usePre,
        includeAnnotation: includeAnnotation ?? this.includeAnnotation,
        getAnnotationData: getAnnotationData ?? this.getAnnotationData,
        getLineData: getLineData ?? this.getLineData);
  }
}

enum HtmlPartKind {
  CODE,
  LINE,
  CONST,
  NEWLINE,
  TEXT,
  TAG,
  LINE_NUMBER,
}

abstract class HtmlPart {
  void printHtmlOn(StringBuffer buffer, HtmlPrintContext context);

  HtmlPartKind get kind;

  toJson(JsonStrategy strategy);

  static HtmlPart fromJson(json, JsonStrategy strategy) {
    if (json is String) {
      return new ConstHtmlPart(json);
    } else {
      switch (HtmlPartKind.values[json['kind']]) {
        case HtmlPartKind.LINE:
          return HtmlLine.fromJson(json, strategy);
        case HtmlPartKind.CODE:
          return CodeLine.fromJson(json, strategy);
        case HtmlPartKind.CONST:
          return ConstHtmlPart.fromJson(json, strategy);
        case HtmlPartKind.NEWLINE:
          return const NewLine();
        case HtmlPartKind.TEXT:
          return HtmlText.fromJson(json, strategy);
        case HtmlPartKind.TAG:
          return TagPart.fromJson(json, strategy);
        case HtmlPartKind.LINE_NUMBER:
          return LineNumber.fromJson(json, strategy);
      }
      return null;
    }
  }
}

class ConstHtmlPart implements HtmlPart {
  final String html;

  const ConstHtmlPart(this.html);

  HtmlPartKind get kind => HtmlPartKind.CONST;

  @override
  void printHtmlOn(StringBuffer buffer, HtmlPrintContext context) {
    buffer.write(html);
  }

  toJson(JsonStrategy strategy) {
    return {'kind': kind.index, 'html': html};
  }

  static ConstHtmlPart fromJson(Map json, JsonStrategy strategy) {
    return new ConstHtmlPart(json['html']);
  }
}

class NewLine implements HtmlPart {
  const NewLine();

  HtmlPartKind get kind => HtmlPartKind.NEWLINE;

  void printHtmlOn(StringBuffer buffer, HtmlPrintContext context) {
    if (context.usePre) {
      buffer.write('\n');
    } else {
      buffer.write('<br/>');
    }
  }

  toJson(JsonStrategy strategy) {
    return {'kind': kind.index};
  }
}

class HtmlText implements HtmlPart {
  final String text;

  const HtmlText(this.text);

  HtmlPartKind get kind => HtmlPartKind.TEXT;

  void printHtmlOn(StringBuffer buffer, HtmlPrintContext context) {
    String escaped = escape(text);
    buffer.write(escaped);
  }

  toJson(JsonStrategy strategy) {
    return {'kind': kind.index, 'text': text};
  }

  static HtmlText fromJson(Map json, JsonStrategy strategy) {
    return new HtmlText(json['text']);
  }
}

class TagPart implements HtmlPart {
  final String tag;
  final Map<String, String> properties;
  final List<HtmlPart> content;

  TagPart(this.tag,
      {this.properties: const <String, String>{},
      this.content: const <HtmlPart>[]});

  HtmlPartKind get kind => HtmlPartKind.TAG;

  @override
  void printHtmlOn(StringBuffer buffer, HtmlPrintContext context) {
    buffer.write('<$tag');
    properties.forEach((String key, String value) {
      if (value != null) {
        buffer.write(' $key="${value}"');
      }
    });
    buffer.write('>');
    for (HtmlPart child in content) {
      child.printHtmlOn(buffer, context);
    }
    buffer.write('</$tag>');
  }

  toJson(JsonStrategy strategy) {
    return {
      'kind': kind.index,
      'tag': tag,
      'properties': properties,
      'content': content.map((p) => p.toJson(strategy)).toList()
    };
  }

  static TagPart fromJson(Map json, JsonStrategy strategy) {
    return new TagPart(json['tag'],
        properties: json['properties'],
        content: json['content'].map(HtmlPart.fromJson).toList());
  }
}

class HtmlLine implements HtmlPart {
  final List<HtmlPart> htmlParts = <HtmlPart>[];

  HtmlPartKind get kind => HtmlPartKind.LINE;

  @override
  void printHtmlOn(StringBuffer htmlBuffer, HtmlPrintContext context) {
    for (HtmlPart part in htmlParts) {
      part.printHtmlOn(htmlBuffer, context);
    }
  }

  Map toJson(JsonStrategy strategy) {
    return {
      'kind': kind.index,
      'html': htmlParts.map((p) => p.toJson(strategy)).toList(),
    };
  }

  static HtmlLine fromJson(Map json, JsonStrategy strategy) {
    HtmlLine line = new HtmlLine();
    json['html'].forEach(
        (part) => line.htmlParts.add(HtmlPart.fromJson(part, strategy)));
    return line;
  }
}

class CodePart {
  final List<Annotation> annotations;
  final String subsequentCode;

  CodePart(this.annotations, this.subsequentCode);

  void printHtmlOn(StringBuffer buffer, HtmlPrintContext context) {
    Iterable<Annotation> included =
        annotations.where(context.includeAnnotation);

    List<HtmlPart> htmlParts = <HtmlPart>[];
    if (included.isNotEmpty) {
      AnnotationData annotationData =
          context.getAnnotationData(included, forSpan: false);
      AnnotationData annotationDataForSpan =
          context.getAnnotationData(included, forSpan: true);

      String head = subsequentCode;
      String tail = '';
      if (subsequentCode.length > 1) {
        head = subsequentCode.substring(0, 1);
        tail = subsequentCode.substring(1);
      }

      if (annotationData != null && annotationDataForSpan != null) {
        htmlParts.add(new TagPart(annotationDataForSpan.tag,
            properties: annotationDataForSpan.properties,
            content: [
              new TagPart(annotationData.tag,
                  properties: annotationData.properties,
                  content: [new HtmlText(head)]),
              new HtmlText(tail)
            ]));
      } else if (annotationDataForSpan != null) {
        htmlParts.add(new TagPart(annotationDataForSpan.tag,
            properties: annotationDataForSpan.properties,
            content: [new HtmlText(subsequentCode)]));
      } else if (annotationData != null) {
        htmlParts.add(new TagPart(annotationData.tag,
            properties: annotationData.properties,
            content: [new HtmlText(head)]));
        htmlParts.add(new HtmlText(tail));
      } else {
        htmlParts.add(new HtmlText(subsequentCode));
      }
    } else {
      htmlParts.add(new HtmlText(subsequentCode));
    }

    for (HtmlPart part in htmlParts) {
      part.printHtmlOn(buffer, context);
    }
  }

  Map toJson(JsonStrategy strategy) {
    return {
      'annotations':
          annotations.map((a) => strategy.encodeAnnotation(a)).toList(),
      'subsequentCode': subsequentCode,
    };
  }

  static CodePart fromJson(Map json, JsonStrategy strategy) {
    return new CodePart(
        json['annotations'].map((j) => strategy.decodeAnnotation(j)).toList(),
        json['subsequentCode']);
  }
}

class LineNumber extends HtmlPart {
  final int lineNo;
  final lineAnnotation;

  LineNumber(this.lineNo, this.lineAnnotation);

  HtmlPartKind get kind => HtmlPartKind.LINE_NUMBER;

  @override
  toJson(JsonStrategy strategy) {
    return {
      'kind': kind.index,
      'lineNo': lineNo,
      'lineAnnotation': strategy.encodeLineAnnotation(lineAnnotation),
    };
  }

  static LineNumber fromJson(Map json, JsonStrategy strategy) {
    return new LineNumber(
        json['lineNo'], strategy.decodeLineAnnotation(json['lineAnnotation']));
  }

  @override
  void printHtmlOn(StringBuffer buffer, HtmlPrintContext context) {
    buffer.write(lineNumber(lineNo,
        width: context.lineNoWidth,
        useNbsp: !context.usePre,
        className: context.getLineData(lineAnnotation).lineNumberClass));
  }
}

class CodeLine extends HtmlPart {
  final Uri uri;
  final int lineNo;
  final int offset;
  final StringBuffer codeBuffer = new StringBuffer();
  final List<CodePart> codeParts = <CodePart>[];
  final List<Annotation> annotations = <Annotation>[];
  var lineAnnotation;
  String _code;

  CodeLine(this.lineNo, this.offset, {this.uri});

  HtmlPartKind get kind => HtmlPartKind.CODE;

  String get code {
    if (_code == null) {
      _code = codeBuffer.toString();
    }
    return _code;
  }

  @override
  void printHtmlOn(StringBuffer htmlBuffer, HtmlPrintContext context) {
    if (context.usePre) {
      LineData lineData = context.getLineData(lineAnnotation);
      htmlBuffer.write('<p class="${lineData.lineClass}">');
    }
    new LineNumber(lineNo, lineAnnotation).printHtmlOn(htmlBuffer, context);
    for (CodePart part in codeParts) {
      part.printHtmlOn(htmlBuffer, context);
    }
    const NewLine().printHtmlOn(htmlBuffer, context);
    if (context.usePre) {
      htmlBuffer.write('</p>');
    }
  }

  Map toJson(JsonStrategy strategy) {
    return {
      'kind': kind.index,
      'lineNo': lineNo,
      'offset': offset,
      'code': code,
      'parts': codeParts.map((p) => p.toJson(strategy)).toList(),
      'annotations':
          annotations.map((a) => strategy.encodeAnnotation(a)).toList(),
      'lineAnnotation': lineAnnotation != null
          ? strategy.encodeLineAnnotation(lineAnnotation)
          : null,
    };
  }

  static CodeLine fromJson(Map json, JsonStrategy strategy) {
    CodeLine line = new CodeLine(json['lineNo'], json['offset'],
        uri: json['uri'] != null ? Uri.parse(json['uri']) : null);
    line.codeBuffer.write(json['code']);
    json['parts'].forEach(
        (part) => line.codeParts.add(CodePart.fromJson(part, strategy)));
    json['annotations']
        .forEach((a) => line.annotations.add(strategy.decodeAnnotation(a)));
    line.lineAnnotation = json['lineAnnotation'] != null
        ? strategy.decodeLineAnnotation(json['lineAnnotation'])
        : null;
    return line;
  }
}

class JsonStrategy {
  const JsonStrategy();

  Map encodeAnnotation(Annotation annotation) {
    return {
      'id': annotation.id,
      'codeOffset': annotation.codeOffset,
      'title': annotation.title,
      'data': annotation.data,
    };
  }

  Annotation decodeAnnotation(Map json) {
    return new Annotation(json['id'], json['codeOffset'], json['title'],
        data: json['data']);
  }

  encodeLineAnnotation(lineAnnotation) => lineAnnotation;

  decodeLineAnnotation(json) => json;
}
