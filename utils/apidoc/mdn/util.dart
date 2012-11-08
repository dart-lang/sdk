library util;

import 'dart:io';
import 'dart:json';

Map<String, Map> _allProps;

Map<String, Map> get allProps {
  if (_allProps == null) {
    // Database of expected property names for each type in WebKit.
    _allProps = JSON.parse(
        new File('data/dartIdl.json').readAsTextSync());
  }
  return _allProps;
}

Set<String> matchedTypes;

/** Returns whether the type has any member matching the specified name. */
bool hasAny(String type, String prop) {
  final data = allProps[type];
  return data['properties'].containsKey(prop) ||
      data['methods'].containsKey(prop) ||
      data['constants'].containsKey(prop);
}

/**
 * Return the members from an [entry] as Map of member names to member
 * objects.
 */
Map getMembersMap(Map entry) {
  List<Map> rawMembers = entry["members"];
  final members = {};
  for (final entry in rawMembers) {
    members[entry['name']] = entry;
  }
  return members;
}

/**
 * Score entries using similarity heuristics calculated from the observed and
 * expected list of members. We could be much less naive and penalize spurious
 * methods, prefer entries with class level comments, etc. This method is
 * needed becase we extract entries for each of the top search results for
 * each class name and rely on these scores to determine which entry was
 * best.  Typically all scores but one will be zero.  Multiple pages have
 * non-zero scores when MDN has multiple pages on the same class or pages on
 * similar classes (e.g. HTMLElement and Element), or pages on Mozilla
 * specific classes that are similar to DOM classes (Console).
 */
num scoreEntry(Map entry, String type) {
  num score = 0;
  // TODO(jacobr): consider removing skipped entries completely instead of
  // just giving them lower scores.
  if (!entry.containsKey('skipped')) {
    score++;
  }
  if (entry.containsKey("members")) {
    Map members = getMembersMap(entry);
    for (String name in members.keys) {
      if (hasAny(type, name)) {
        score++;
      }
    }
  }
  return score;
}

/**
 * Given a list of candidates for the documentation for a type, find the one
 * that is the best.
 */
Map pickBestEntry(List entries, String type) {
  num bestScore = -1;
  Map bestEntry;
  for (Map entry in entries) {
    if (entry != null) {
      num score = scoreEntry(entry, type);
      if (score > bestScore) {
        bestScore = score;
        bestEntry = entry;
      }
    }
  }
  return bestEntry;
}

/**
 * Helper for sync creation of a whole file from a string.
 */
void writeFileSync(String filename, String data) {
  File f = new File(filename);
  RandomAccessFile raf = f.openSync(FileMode.WRITE);
  raf.writeStringSync(data);
  raf.closeSync();
}
