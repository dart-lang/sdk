import 'dart:convert' show jsonDecode;
import 'dart:io';

void main(List<String> args) {
  var jsonPath = args[0];
  var json =
      jsonDecode(File(jsonPath).readAsStringSync()) as Map<String, Object>;
  var changes = json['changes'] as Map<String, Object>;
  var byPath = changes['byPath'] as Map<String, Object>;
  if (args.isEmpty) {
    print('''
Usage: summary_stats.dart <summary_file> [category_name]

Prints statistics of `dart migrate` suggestions summary, created with the
`--summary` flag of `dart migrate`.

If [category_name] is not given, this prints the total number of suggestions
which the tool made, per category.

If [category_name] is given, this prints the file names and suggestion counts of
each file with one or more suggestions categorized as [category_name].
''');
  } else if (args.length == 1) {
    _printTotals(byPath);
  } else {
    var category = args[1];
    _printCategory(byPath, category);
  }
}

/// Prints the file names and counts of files with suggestions of [category].
void _printCategory(Map<String, Object> byPath, String category) {
  byPath.forEach((String path, Object value) {
    var counts = value as Map<String, Object>;
    if (counts.containsKey(category)) {
      print('$path: ${counts[category]}');
    }
  });
}

/// Prints the total number of suggestions for each category.
void _printTotals(Map<String, Object> byPath) {
  var summary = <String, int>{};
  for (var file in byPath.values.cast<Map<Object, Object>>()) {
    file.forEach((category, count) {
      summary.putIfAbsent(category as String, () => 0);
      summary[category as String] += count as int;
    });
  }
  var categories = summary.keys.toList()..sort();
  for (var category in categories) {
    print('$category:  ${summary[category]}');
  }
}
