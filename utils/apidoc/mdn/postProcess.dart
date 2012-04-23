#library("postProcess");

#import("dart:json");
#import("util.dart");

void main() {
  // Database of code documentation.
  Map<String, List> database = JSON.parse(
      fs.readFileSync('output/database.json', 'utf8'));
  final filteredDb = {};
  final obsolete = [];
  for (String type in database.getKeys()) {
    final entry = pickBestEntry(database[type], type);
    filteredDb[type] = entry;
    if (entry.containsKey("members")) {
      Map members = getMembersMap(entry);
      for (String name in members.getKeys()) {
        Map memberData = members[name];
        if (memberData['obsolete'] == true) {
          obsolete.add({'type': type, 'member' : name});
        }
      }
    }
  }
  fs.writeFileSync("output/database.filtered.json",
      JSON.stringify(filteredDb));
  fs.writeFileSync("output/obsolete.json", JSON.stringify(obsolete));
}
