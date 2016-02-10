// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sourcemap.html_parts;

import 'sourcemap_html_helper.dart';

class HtmlPrintContext {
  final int lineNoWidth;
  final bool usePre;

  HtmlPrintContext({
    this.lineNoWidth,
    this.usePre: true});
}

enum HtmlPartKind {
  CODE,
  LINE,
  CONST,
  NEWLINE,
  TEXT,
  ANCHOR,
}

abstract class HtmlPart {
  void printHtmlOn(StringBuffer buffer, HtmlPrintContext context) {}

  toJson();

  static HtmlPart fromJson(json) {
    if (json is String) {
      return new ConstHtmlPart(json);
    } else {
      switch (HtmlPartKind.values[json['kind']]) {
        case HtmlPartKind.LINE:
          return HtmlLine.fromJson(json);
        case HtmlPartKind.CODE:
          return CodeLine.fromJson(json);
        case HtmlPartKind.CONST:
          return ConstHtmlPart.fromJson(json);
        case HtmlPartKind.NEWLINE:
          return const NewLine();
        case HtmlPartKind.TEXT:
          return HtmlText.fromJson(json);
        case HtmlPartKind.ANCHOR:
          return AnchorHtmlPart.fromJson(json);
      }
    }
  }
}

class ConstHtmlPart implements HtmlPart {
  final String html;

  const ConstHtmlPart(this.html);

  @override
  void printHtmlOn(StringBuffer buffer, HtmlPrintContext context) {
    buffer.write(html);
  }

  toJson() {
    return {'kind': HtmlPartKind.CONST.index, 'html': html};
  }

  static ConstHtmlPart fromJson(Map json) {
    return new ConstHtmlPart(json['html']);
  }
}

class NewLine implements HtmlPart {
  const NewLine();

  void printHtmlOn(StringBuffer buffer, HtmlPrintContext context) {
    if (context.usePre) {
      buffer.write('\n');
    } else {
      buffer.write('<br/>');
    }
  }

  toJson() {
    return {'kind': HtmlPartKind.NEWLINE.index};
  }
}

class HtmlText implements HtmlPart {
  final String text;

  const HtmlText(this.text);

  void printHtmlOn(StringBuffer buffer, HtmlPrintContext context) {
    String escaped = escape(text);
    buffer.write(escaped);
  }

  toJson() {
    return {'kind': HtmlPartKind.TEXT.index, 'text': text};
  }

  static HtmlText fromJson(Map json) {
    return new HtmlText(json['text']);
  }
}

class AnchorHtmlPart implements HtmlPart {
  final String color;
  final String name;
  final String href;
  final String title;
  final String onclick;
  final String onmouseover;
  final String onmouseout;

  AnchorHtmlPart({
    this.color,
    this.name,
    this.href,
    this.title,
    this.onclick,
    this.onmouseover,
    this.onmouseout});

  @override
  void printHtmlOn(StringBuffer buffer, HtmlPrintContext context) {
    buffer.write('<a');
    if (href != null) {
      buffer.write(' href="${href}"');
    }
    if (name != null) {
      buffer.write(' name="${name}"');
    }
    if (title != null) {
      buffer.write(' title="${escape(title)}"');
    }
    buffer.write(' style="${color}"');
    if (onclick != null) {
      buffer.write(' onclick="${onclick}"');
    }
    if (onmouseover != null) {
      buffer.write(' onmouseover="${onmouseover}"');
    }
    if (onmouseout != null) {
      buffer.write(' onmouseout="${onmouseout}"');
    }
    buffer.write('>');
  }

  toJson() {
    return {
      'kind': HtmlPartKind.ANCHOR.index,
      'color': color,
      'name': name,
      'href': href,
      'title': title,
      'onclick': onclick,
      'onmouseover': onmouseover,
      'onmouseout': onmouseout};
  }

  static AnchorHtmlPart fromJson(Map json) {
    return new AnchorHtmlPart(
        color: json['color'],
        name: json['name'],
        href: json['href'],
        title: json['title'],
        onclick: json['onclick'],
        onmouseover: json['onmouseover'],
        onmouseout: json['onmouseout']);
  }
}

class HtmlLine implements HtmlPart {
  final List<HtmlPart> htmlParts = <HtmlPart>[];

  @override
  void printHtmlOn(StringBuffer htmlBuffer, HtmlPrintContext context) {
    for (HtmlPart part in htmlParts) {
      part.printHtmlOn(htmlBuffer, context);
    }
  }

  Map toJson() {
    return {
      'kind': HtmlPartKind.LINE.index,
      'html': htmlParts.map((p) => p.toJson()).toList(),
    };
  }

  static CodeLine fromJson(Map json) {
    HtmlLine line = new HtmlLine();
    json['html'].forEach((part) => line.htmlParts.add(HtmlPart.fromJson(part)));
    return line;
  }
}

class CodeLine extends HtmlLine {
  final int lineNo;
  final int offset;
  final StringBuffer codeBuffer = new StringBuffer();
  final List<HtmlPart> htmlParts = <HtmlPart>[];
  // TODO(johnniwinther): Make annotations serializable.
  final List<Annotation> annotations = <Annotation>[];
  String _code;

  CodeLine(this.lineNo, this.offset);

  String get code {
    if (_code == null) {
      _code = codeBuffer.toString();
    }
    return _code;
  }

  @override
  void printHtmlOn(StringBuffer htmlBuffer, HtmlPrintContext context) {
    htmlBuffer.write(lineNumber(
        lineNo, width: context.lineNoWidth, useNbsp: !context.usePre));
    for (HtmlPart part in htmlParts) {
      part.printHtmlOn(htmlBuffer, context);
    }
  }

  Map toJson() {
    return {
      'kind': HtmlPartKind.CODE.index,
      'lineNo': lineNo,
      'offset': offset,
      'code': code,
      'html': htmlParts.map((p) => p.toJson()).toList(),
    };
  }

  static CodeLine fromJson(Map json) {
    CodeLine line = new CodeLine(json['lineNo'], json['offset']);
    line.codeBuffer.write(json['code']);
    json['html'].forEach((part) => line.htmlParts.add(HtmlPart.fromJson(part)));
    return line;
  }
}

