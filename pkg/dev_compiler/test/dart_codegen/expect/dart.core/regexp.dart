part of dart.core;

abstract class Match {
  int get start;
  int get end;
  String group(int group);
  String operator [](int group);
  List<String> groups(List<int> groupIndices);
  int get groupCount;
  String get input;
  Pattern get pattern;
}
abstract class RegExp implements Pattern {
  external factory RegExp(String source,
      {bool multiLine: false, bool caseSensitive: true});
  Match firstMatch(String input);
  Iterable<Match> allMatches(String input, [int start = 0]);
  bool hasMatch(String input);
  String stringMatch(String input);
  String get pattern;
  bool get isMultiLine;
  bool get isCaseSensitive;
}
