// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:convert';
import 'dart:async';
import 'package:source_maps/source_maps.dart';

Element targetFileName = querySelector("#target_filename");
Element sourceFileName = querySelector("#source_filename");
DivElement generatedOutput = querySelector("#generated_output");
DivElement selectedSource = querySelector("#selected_source");
DivElement selectedOutputSpan = querySelector("#current_span");
DivElement decodedMap = querySelector("#decoded_map");
DivElement originalMap = querySelector("#original_map");

Map<TargetEntry, List<SpanElement>> targetEntryMap = {};
List<SpanElement> highlightedMapEntry = null;
List<String> target;
SingleMapping sourceMap;

void adjustDivHeightsToWindow() {
  generatedOutput.style.height = "${window.innerHeight / 3 - 50}px";
  selectedSource.style.height = "${window.innerHeight / 3 - 50}px";
  decodedMap.style.height = "${window.innerHeight / 3 - 50}px";
  originalMap.style.height = "${window.innerHeight / 3 - 50}px";
}

Future getMap() {
  Completer c = new Completer();
  HttpRequest httpRequest = new HttpRequest();
  httpRequest
    ..open('GET', '/map')
    ..onLoadEnd.listen((_) => c.complete(httpRequest.responseText))
    ..send('');
  return c.future;
}

Future fetchFile(String path) {
  Completer c = new Completer();
  HttpRequest httpRequest = new HttpRequest();
  sourceFileName.text = path;
  httpRequest
    ..open('GET', path)
    ..onLoadEnd.listen((_) => c.complete(httpRequest.responseText))
    ..send('');
  return c.future;
}

displaySource(String filename, List<String> source, TargetEntry entry) {
  int line = entry.sourceLine;
  int column = entry.sourceColumn;
  int nameId = entry.sourceNameId;
  String id = nameId == null ? null : sourceMap.names[nameId];
  selectedSource.children.clear();
  SpanElement marker = new SpanElement()
    ..className = "marker"
    ..appendText("*");
  for (int pos = 0; pos < source.length; pos++) {
    String l = source[pos];
    if (pos != line) {
      selectedSource.children.add(l.isEmpty ? new BRElement() : new DivElement()
        ..appendText(l));
    } else {
      selectedSource.children.add(new DivElement()
        ..appendText(l.substring(0, column))
        ..children.add(marker)
        ..appendText(l.substring(column)));
    }
  }
  sourceFileName.text = filename;
  marker.scrollIntoView();
}

void highlightSelectedSpan(TargetEntry entry, TargetLineEntry lineEntry) {
  selectedOutputSpan.children.clear();
  String spanEndCol;
  TargetEntry spanEnd;
  bool nextEntryIsSpanEnd = false;
  for (TargetEntry e in lineEntry.entries) {
    if (nextEntryIsSpanEnd) {
      spanEnd = e;
      break;
    }
    if (e == entry) {
      nextEntryIsSpanEnd = true;
    }
  }
  if (spanEnd == null) {
    spanEndCol = '${target[lineEntry.line].length} (EOL).';
  } else {
    spanEndCol = '${spanEnd.column}.';
  }

  String targetSpan =
      'Target:  Line ${lineEntry.line} Col. ${entry.column} - $spanEndCol';

  if (entry.sourceUrlId == null) {
    targetSpan += ' Source: unknown';
    selectedOutputSpan.children.add(getTextElement(targetSpan));
    return;
  }

  String source = sourceMap.urls[entry.sourceUrlId];
  String sourceName = source.substring(source.lastIndexOf('/') + 1);
  String sourcePoint =
      'Source: Line ${entry.sourceLine} Col. ${entry.sourceColumn}';
  sourcePoint += entry.sourceNameId == null
      ? ''
      : ' (${sourceMap.names[entry.sourceNameId]})';
  sourcePoint += ' in $sourceName';
  selectedOutputSpan.children.add(getTextElement(targetSpan));
  selectedOutputSpan.children.add(new BRElement());
  selectedOutputSpan.children.add(getTextElement(sourcePoint));

  if (highlightedMapEntry != null) {
    highlightedMapEntry[0].style.background = 'white';
    highlightedMapEntry[1].style.background = 'white';
  }

  String highlightColor = "#99ff99";
  highlightedMapEntry = targetEntryMap[entry];
  highlightedMapEntry[0]
    ..scrollIntoView()
    ..style.backgroundColor = highlightColor;
  highlightedMapEntry[1]
    ..scrollIntoView()
    ..style.backgroundColor = highlightColor;
  highlightedMapEntry[1].onMouseOver.listen((e) {
    selectedOutputSpan.style.zIndex = "2";
    selectedOutputSpan.style.visibility = "visible";
    selectedOutputSpan.style.top = "${decodedMap.offsetTo(document.body).y +
                                      decodedMap.clientHeight - 20}px";
    selectedOutputSpan.style.left = "${decodedMap.offsetTo(document.body).x}px";
    selectedOutputSpan.style.width = "${decodedMap.clientWidth}px";
  });

  highlightedMapEntry[1].onMouseOut.listen((e) {
    selectedOutputSpan.style.visibility = "hidden";
  });

  adjustDivHeightsToWindow();
}

void loadSource(TargetEntry entry) {
  if (entry.sourceUrlId == null) {
    return;
  }

  String source = sourceMap.urls[entry.sourceUrlId];
  fetchFile(
          new Uri(path: "/file", queryParameters: {"path": source}).toString())
      .then((text) => displaySource(source, text.split("\n"), entry));
  selectedSource.text = "loading";
}

SpanElement createSpan(
    String content, TargetEntry entry, TargetLineEntry lineEntry) {
  return new SpanElement()
    ..addEventListener('click', (e) {
      loadSource(entry);
      highlightSelectedSpan(entry, lineEntry);
    }, false)
    ..className = "range${entry.sourceUrlId % 4}"
    ..appendText(content);
}

Element getLineNumberElement(int line) {
  SpanElement result = new SpanElement();
  result.style.fontFamily = "Courier";
  result.style.fontSize = "10pt";
  result.appendText("${line} ");
  return result;
}

Element getTextElement(String text) {
  SpanElement result = new SpanElement();
  result.text = text;
  return result;
}

addTargetLine(int lineNumber, String content, TargetLineEntry lineEntry) {
  if (content.isEmpty) {
    generatedOutput.children
        .add(new DivElement()..children.add(getLineNumberElement(lineNumber)));
    return;
  }
  if (lineEntry == null) {
    generatedOutput.children.add(new DivElement()
      ..children.add(getLineNumberElement(lineNumber))
      ..children.add(getTextElement(content)));
    return;
  }
  DivElement div = new DivElement();
  div.children.add(getLineNumberElement(lineNumber));

  int pos = 0;
  TargetEntry previous = null;
  for (TargetEntry next in lineEntry.entries) {
    if (previous == null) {
      if (pos < next.column) {
        div.appendText(content.substring(pos, next.column));
      }
      if (content.length == next.column) {
        div.children.add(createSpan(" ", next, lineEntry));
      }
    } else {
      if (next.column <= content.length) {
        String token = content.substring(pos, next.column);
        div.children.add(createSpan(token, previous, lineEntry));
      }
      if (content.length == next.column) {
        div.children.add(createSpan(" ", next, lineEntry));
      }
    }
    pos = next.column;
    previous = next;
  }
  String token = content.substring(pos);
  if (previous == null) {
    div.appendText(token);
  } else {
    div..children.add(createSpan(token, previous, lineEntry));
  }
  generatedOutput.children.add(div);
}

// Display the target source in the HTML.
void displayTargetSource() {
  List<TargetLineEntry> targetLines = sourceMap.lines;
  int linesIndex = 0;
  for (int line = 0; line < target.length; line++) {
    TargetLineEntry entry = null;
    if (linesIndex < targetLines.length &&
        targetLines[linesIndex].line == line) {
      entry = targetLines[linesIndex];
      linesIndex++;
    }
    if (entry != null) {
      addTargetLine(line, target[line], entry);
    } else {
      addTargetLine(line, target[line], null);
    }
  }
}

String getMappedData(String mapFileContent) {
  // Source map contains mapping information in this format:
  // "mappings": "A;A,yC;"
  List<String> mapEntry = mapFileContent.split('mappings');
  return mapEntry[mapEntry.length - 1].split('"')[2];
}

SpanElement createMapSpan(String segment) {
  return new SpanElement()..text = segment;
}

SpanElement createDecodedMapSpan(TargetEntry entry) {
  return new SpanElement()
    ..text = '(${entry.column}, ${entry.sourceUrlId},'
        ' ${entry.sourceLine},'
        ' ${entry.sourceColumn})';
}

displayMap(String mapFileContent) {
  String mappedData = getMappedData(mapFileContent);
  int sourceMapLine = 0;
  for (String group in mappedData.split(';')) {
    if (group.length == 0) continue;

    List<String> segments = [];
    if (!group.contains(',')) {
      segments.add(group);
    } else {
      segments = group.split(',');
    }

    TargetLineEntry targetLineEntry = sourceMap.lines[sourceMapLine];
    decodedMap.children.add(getLineNumberElement(targetLineEntry.line));
    originalMap.children.add(getLineNumberElement(targetLineEntry.line));
    bool first = true;
    int entryNumber = 0;
    for (String segment in segments) {
      TargetEntry entry = targetLineEntry.entries[entryNumber];
      SpanElement orignalMapSpan = createMapSpan(segment);
      SpanElement decodedMapSpan = createDecodedMapSpan(entry);
      if (first) {
        first = false;
      } else {
        originalMap.children.add(getTextElement(', '));
        decodedMap.children.add(getTextElement(', '));
      }
      originalMap.children.add(orignalMapSpan);
      decodedMap.children.add(decodedMapSpan);
      ++entryNumber;
      targetEntryMap.putIfAbsent(entry, () => [orignalMapSpan, decodedMapSpan]);
    }
    originalMap.children.add(new BRElement());
    decodedMap.children.add(new BRElement());
    ++sourceMapLine;
  }
}

void main() {
  Future load(String q) => fetchFile(
      new Uri(path: "/file", queryParameters: {"path": q}).toString());

  getMap().then((mapFileName) {
    load(mapFileName).then((mapFileContent) {
      sourceMap = new SingleMapping.fromJson(JSON.decode(mapFileContent));
      displayMap(mapFileContent);
      targetFileName.text = sourceMap.targetUrl;
      load(targetFileName.text).then((targetFileContent) {
        target = targetFileContent.split('\n');
        displayTargetSource();
        adjustDivHeightsToWindow();
      });
    });
  });

  sourceFileName.text = "<source not selected>";
}
