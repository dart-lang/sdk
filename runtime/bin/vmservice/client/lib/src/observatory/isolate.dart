// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observatory;

/// State for a running isolate.
class Isolate extends Observable {
  @observable Profile profile;
  @observable final Map<String, Script> scripts =
      toObservable(new Map<String, Script>());
  @observable final List<Code> codes = new List<Code>();
  @observable String id;
  @observable String name;

  Isolate(this.id, this.name);

  String toString() => '$id $name';

  Code findCodeByAddress(int address) {
    for (var i = 0; i < codes.length; i++) {
      if (codes[i].contains(address)) {
        return codes[i];
      }
    }
  }

  Code findCodeByName(String name) {
    for (var i = 0; i < codes.length; i++) {
      if (codes[i].name == name) {
        return codes[i];
      }
    }
  }

  void resetCodeTicks() {
    Logger.root.info('Reset all code ticks.');
    for (var i = 0; i < codes.length; i++) {
      codes[i].resetTicks();
    }
  }

  void updateCoverage(List coverages) {
    for (var coverage in coverages) {
      var id = coverage['script']['id'];
      var script = scripts[id];
      if (script == null) {
        script = new Script.fromMap(coverage['script']);
        scripts[id] = script;
      }
      assert(script != null);
      script._processCoverageHits(coverage['hits']);
    }
  }
}
