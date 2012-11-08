/**
 * Read database.json,
 * write database.filtered.json (with "best" entries)
 * and obsolete.json (with entries marked obsolete).
 */

library postProcess;

import 'dart:io';
import 'dart:json';
import 'util.dart';

void main() {
  // Database of code documentation.
  Map<String, List> database = JSON.parse(
      new File('output/database.json').readAsTextSync());
  final filteredDb = {};
  final obsolete = [];
  for (String type in database.keys) {
    final entry = pickBestEntry(database[type], type);
    if (entry == null) {
      print("Can't find ${type} in database.  Skipping.");
      continue;
    }
    filteredDb[type] = entry;
    if (entry.containsKey("members")) {
      Map members = getMembersMap(entry);
      for (String name in members.keys) {
        Map memberData = members[name];
        if (memberData['obsolete'] == true) {
          obsolete.add({'type': type, 'member' : name});
        }
      }
    }
  }
  writeFileSync("output/database.filtered.json", JSON.stringify(filteredDb));
  writeFileSync("output/obsolete.json", JSON.stringify(obsolete));
}
