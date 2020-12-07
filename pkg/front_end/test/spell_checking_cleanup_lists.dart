// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'spell_checking_utils.dart' as spell;

main() {
  {
    spell.ensureDictionariesLoaded([spell.Dictionaries.common]);
    Set<String> commonWords =
        spell.loadedDictionaries[spell.Dictionaries.common];
    for (spell.Dictionaries dictionary in spell.Dictionaries.values) {
      if (dictionary == spell.Dictionaries.common) continue;
      Uri uri = spell.dictionaryToUri(dictionary);
      List<String> keep = <String>[];
      for (String line in new File.fromUri(uri).readAsLinesSync()) {
        if (!commonWords.contains(line)) {
          keep.add(line);
        }
      }
      keep.add("");
      new File.fromUri(uri).writeAsStringSync(keep.join("\n"));
    }
  }

  {
    spell.ensureDictionariesLoaded([spell.Dictionaries.cfeCode]);
    Set<String> codeWords =
        spell.loadedDictionaries[spell.Dictionaries.cfeCode];
    Uri uri = spell.dictionaryToUri(spell.Dictionaries.cfeTests);
    List<String> keep = <String>[];
    for (String line in new File.fromUri(uri).readAsLinesSync()) {
      if (!codeWords.contains(line)) {
        keep.add(line);
      }
    }
    keep.add("");
    new File.fromUri(uri).writeAsStringSync(keep.join("\n"));
  }
}
