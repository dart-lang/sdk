/**
 * Read database.json,
 * write database.filtered.json (with "best" entries)
 * and obsolete.json (with entries marked obsolete).
 */

library postProcess;

import 'dart:convert';
import 'dart:io';
import 'util.dart';

void main() {
  // Database of code documentation.
  Map<String, List> database = JSON.decode(
      new File('output/database.json').readAsStringSync());
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
  writeFileSync("output/database.filtered.json", JSON.encode(filteredDb));
  writeFileSync("output/obsolete.json", JSON.encode(obsolete));
}
