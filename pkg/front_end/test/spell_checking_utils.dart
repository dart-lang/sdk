// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

enum Dictionaries {
  common,
  cfeMessages,
  cfeCode,
  cfeTests,
  // The denylist is special and is always loaded!
  denylist,
}

Map<Dictionaries, Set<String>> loadedDictionaries;

SpellingResult spellcheckString(String s,
    {List<Dictionaries> dictionaries, bool splitAsCode: false}) {
  dictionaries ??= const [Dictionaries.common];
  ensureDictionariesLoaded(dictionaries);

  List<String> wrongWords;
  List<List<String>> wrongWordsAlternatives;
  List<int> wrongWordsOffset;
  List<bool> wrongWordDenylisted;
  List<int> wordOffsets = new List<int>();
  List<String> words =
      splitStringIntoWords(s, wordOffsets, splitAsCode: splitAsCode);
  List<Set<String>> dictionariesUnpacked = [];
  for (int j = 0; j < dictionaries.length; j++) {
    Dictionaries dictionaryType = dictionaries[j];
    if (dictionaryType == Dictionaries.denylist) continue;
    Set<String> dictionary = loadedDictionaries[dictionaryType];
    dictionariesUnpacked.add(dictionary);
  }
  for (int i = 0; i < words.length; i++) {
    String word = words[i].toLowerCase();
    int offset = wordOffsets[i];
    bool found = false;

    for (int j = 0; j < dictionariesUnpacked.length; j++) {
      Set<String> dictionary = dictionariesUnpacked[j];
      if (dictionary.contains(word)) {
        found = true;
        break;
      }
    }
    if (!found) {
      wrongWords ??= new List<String>();
      wrongWords.add(word);
      wrongWordsAlternatives ??= new List<List<String>>();
      wrongWordsAlternatives.add(findAlternatives(word, dictionariesUnpacked));
      wrongWordsOffset ??= new List<int>();
      wrongWordsOffset.add(offset);
      wrongWordDenylisted ??= new List<bool>();
      wrongWordDenylisted
          .add(loadedDictionaries[Dictionaries.denylist].contains(word));
    }
  }

  return new SpellingResult(wrongWords, wrongWordsOffset, wrongWordDenylisted,
      wrongWordsAlternatives);
}

List<String> findAlternatives(String word, List<Set<String>> dictionaries) {
  List<String> result;

  bool check(String w) {
    for (int j = 0; j < dictionaries.length; j++) {
      Set<String> dictionary = dictionaries[j];
      if (dictionary.contains(w)) return true;
    }
    return false;
  }

  void ok(String w) {
    result ??= new List<String>();
    result.add(w);
  }

  // Delete a letter, insert a letter or change a letter and lookup.
  for (int i = 0; i < word.length; i++) {
    String before = word.substring(0, i);
    String after = word.substring(i + 1);
    String afterIncluding = word.substring(i);

    {
      String deletedLetter = before + after;
      if (check(deletedLetter)) ok(deletedLetter);
    }
    for (int j = 0; j < 25; j++) {
      String c = new String.fromCharCode(97 + j);
      String insertedLetter = before + c + afterIncluding;
      if (check(insertedLetter)) ok(insertedLetter);
    }
    for (int j = 0; j < 25; j++) {
      String c = new String.fromCharCode(97 + j);
      String replacedLetter = before + c + after;
      if (check(replacedLetter)) ok(replacedLetter);
    }
  }

  return result;
}

class SpellingResult {
  final List<String> misspelledWords;
  final List<int> misspelledWordsOffset;
  final List<bool> misspelledWordsDenylisted;
  final List<List<String>> misspelledWordsAlternatives;

  SpellingResult(this.misspelledWords, this.misspelledWordsOffset,
      this.misspelledWordsDenylisted, this.misspelledWordsAlternatives);
}

void ensureDictionariesLoaded(List<Dictionaries> dictionaries) {
  void addWords(Uri uri, Set<String> dictionary) {
    for (String word in File.fromUri(uri)
        .readAsStringSync()
        .split("\n")
        .map((s) => s.toLowerCase())) {
      if (word.startsWith("#")) continue;
      int indexOfHash = word.indexOf(" #");
      if (indexOfHash >= 0) {
        // Strip out comment.
        word = word.substring(0, indexOfHash).trim();
      }
      if (word == "") continue;
      if (word.contains(" ")) throw "'$word' contains spaces";
      dictionary.add(word);
    }
  }

  loadedDictionaries ??= new Map<Dictionaries, Set<String>>();
  // Ensure the denylist is loaded.
  Set<String> denylistDictionary = loadedDictionaries[Dictionaries.denylist];
  if (denylistDictionary == null) {
    denylistDictionary = new Set<String>();
    loadedDictionaries[Dictionaries.denylist] = denylistDictionary;
    addWords(dictionaryToUri(Dictionaries.denylist), denylistDictionary);
  }

  for (int j = 0; j < dictionaries.length; j++) {
    Dictionaries dictionaryType = dictionaries[j];
    Set<String> dictionary = loadedDictionaries[dictionaryType];
    if (dictionary == null) {
      dictionary = new Set<String>();
      loadedDictionaries[dictionaryType] = dictionary;
      addWords(dictionaryToUri(dictionaryType), dictionary);
      // Check that no good words occur in the denylist.
      for (String s in dictionary) {
        if (denylistDictionary.contains(s)) {
          throw "Word '$s' in dictionary $dictionaryType "
              "is also in the denylist.";
        }
      }
    }
  }
}

Uri dictionaryToUri(Dictionaries dictionaryType) {
  switch (dictionaryType) {
    case Dictionaries.common:
      return Uri.base
          .resolve("pkg/front_end/test/spell_checking_list_common.txt");
    case Dictionaries.cfeMessages:
      return Uri.base
          .resolve("pkg/front_end/test/spell_checking_list_messages.txt");
    case Dictionaries.cfeCode:
      return Uri.base
          .resolve("pkg/front_end/test/spell_checking_list_code.txt");
    case Dictionaries.cfeTests:
      return Uri.base
          .resolve("pkg/front_end/test/spell_checking_list_tests.txt");
    case Dictionaries.denylist:
      return Uri.base
          .resolve("pkg/front_end/test/spell_checking_list_denylist.txt");
  }
  throw "Unknown Dictionary";
}

List<String> splitStringIntoWords(String s, List<int> splitOffsets,
    {bool splitAsCode: false}) {
  List<String> result = new List<String>();
  // Match whitespace and the characters "-", "=", "|", "/", ",".
  String regExpStringInner = r"\s-=\|\/,";
  if (splitAsCode) {
    // If splitting as code also split by "_", ":", ".", "(", ")", "<", ">",
    // "[", "]", "{", "}", "@", "&", "#", "?", "%", "`".
    // (As well as doing stuff to camel casing further below).
    regExpStringInner = "${regExpStringInner}_:\\.\\(\\)<>\\[\\]\{\}@&#\\?%`";
  }
  // Match one or more of the characters specified above.
  String regExp = "[$regExpStringInner]+";
  if (splitAsCode) {
    // If splitting as code we also want to remove the two characters "\n".
    regExp = "([$regExpStringInner]|(\\\\n))+";
  }

  Iterator<RegExpMatch> matchesIterator =
      new RegExp(regExp).allMatches(s).iterator;
  int latestMatch = 0;
  List<String> split = new List<String>();
  List<int> splitOffset = new List<int>();
  while (matchesIterator.moveNext()) {
    RegExpMatch match = matchesIterator.current;
    if (match.start > latestMatch) {
      split.add(s.substring(latestMatch, match.start));
      splitOffset.add(latestMatch);
    }
    latestMatch = match.end;
  }
  if (s.length > latestMatch) {
    split.add(s.substring(latestMatch, s.length));
    splitOffset.add(latestMatch);
  }

  for (int i = 0; i < split.length; i++) {
    String word = split[i];
    int offset = splitOffset[i];
    if (word.isEmpty) continue;
    int start = 0;
    int end = word.length;
    bool changedStart = false;
    while (start < end) {
      int unit = word.codeUnitAt(start);
      if (unit >= 65 && unit <= 90) {
        // A-Z => Good.
        break;
      } else if (unit >= 97 && unit <= 122) {
        // a-z => Good.
        break;
      } else {
        changedStart = true;
        start++;
      }
    }
    bool changedEnd = false;
    while (end > start) {
      int unit = word.codeUnitAt(end - 1);
      if (unit >= 65 && unit <= 90) {
        // A-Z => Good.
        break;
      } else if (unit >= 97 && unit <= 122) {
        // a-z => Good.
        break;
      } else {
        changedEnd = true;
        end--;
      }
    }
    if (changedEnd && word.codeUnitAt(end) == 41) {
      // Special case trimmed ')' if there's a '(' inside the string.
      for (int i = start; i < end; i++) {
        if (word.codeUnitAt(i) == 40) {
          end++;
          break;
        }
      }
    }
    if (start == end) continue;

    if (splitAsCode) {
      bool prevCapitalized = false;
      for (int i = start; i < end; i++) {
        bool thisCapitalized = false;
        int unit = word.codeUnitAt(i);
        if (unit >= 65 && unit <= 90) {
          thisCapitalized = true;
        } else if (unit >= 48 && unit <= 57) {
          // Number inside --- allow that.
          continue;
        }
        if (prevCapitalized && thisCapitalized) {
          // Sort-of-weird thing, something like "thisIsTheCNN". Carry on.

          // Except if the previous was an 'A' and that both the previous
          // (before that) and the next (if any) is not capitalized, i.e.
          // we special-case the case of 'A' as in 'AWord' being 'a word'.
          int prevUnit = word.codeUnitAt(i - 1);
          if (prevUnit == 65) {
            bool doSpecialCase = true;
            if (i + 1 < end) {
              int nextUnit = word.codeUnitAt(i + 1);
              if (nextUnit >= 65 && nextUnit <= 90) {
                // Next is capitalized too.
                doSpecialCase = false;
              }
            }
            if (i - 2 >= start) {
              int prevPrevUnit = word.codeUnitAt(i - 2);
              if (prevPrevUnit >= 65 && prevPrevUnit <= 90) {
                // Prev-prev was capitalized too.
                doSpecialCase = false;
              }
            }
            if (doSpecialCase) {
              result.add(word.substring(start, i));
              splitOffsets.add(offset + start);
              start = i;
            }
          }

          // And the case where the next one is not capitalized --- we must
          // assume that "TheCNNAlso" should be "The", "CNN", "Also".
          if (start < i && i + 1 < end) {
            int nextUnit = word.codeUnitAt(i + 1);
            if (nextUnit >= 97 && nextUnit <= 122) {
              // Next is not capitalized.
              result.add(word.substring(start, i));
              splitOffsets.add(offset + start);
              start = i;
            }
          }
        } else if (!prevCapitalized && thisCapitalized) {
          // Starting a new camel case word.
          if (i > start) {
            result.add(word.substring(start, i));
            splitOffsets.add(offset + start);
            start = i;
          }
        } else if (prevCapitalized && !thisCapitalized) {
          // This should have been handled above.
        } else if (!prevCapitalized && !thisCapitalized) {
          // Continued word.
        }
        if (i + 1 == end) {
          // End of string.
          if (i >= start) {
            result.add(word.substring(start, end));
            splitOffsets.add(offset + start);
          }
        }
        prevCapitalized = thisCapitalized;
      }
    } else {
      result.add(
          (changedStart || changedEnd) ? word.substring(start, end) : word);
      splitOffsets.add(offset + start);
    }
  }
  return result;
}
