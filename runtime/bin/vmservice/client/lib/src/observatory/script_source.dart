// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observatory;

class ScriptSourceLine extends Observable {
  final int line;
  final int numDigits;
  @observable final String src;
  @observable String paddedLine;
  ScriptSourceLine(this.line, this.numDigits, this.src) {
    paddedLine = '$line';
    for (int i = paddedLine.length; i < numDigits; i++) {
      paddedLine = ' $paddedLine';
    }
  }
}

class ScriptSource extends Observable {
  @observable String kind = '';
  @observable String url = '';
  @observable List<ScriptSourceLine> lines = toObservable([]);

  ScriptSource(Map response) {
    kind = response['kind'];
    url = response['name'];
    buildSourceLines(response['source']);
  }

  void buildSourceLines(String src) {
    List<String> splitSrc = src.split('\n');
    int numDigits = '${splitSrc.length+1}'.length;
    for (int i = 0; i < splitSrc.length; i++) {
      ScriptSourceLine sourceLine = new ScriptSourceLine(i+1, numDigits,
                                                         splitSrc[i]);
      lines.add(sourceLine);
    }
  }

  String toString() => 'ScriptSource';
}
