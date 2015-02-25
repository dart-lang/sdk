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
  factory RegExp(String source,
      {bool multiLine: false, bool caseSensitive: true}) => ((__x33) => DDC$RT
              .cast(__x33, dynamic, RegExp, "CastExact",
                  """line 130, column 8 of dart:core/regexp.dart: """,
                  __x33 is RegExp, true))(new JSSyntaxRegExp(source,
          multiLine: multiLine, caseSensitive: caseSensitive));
  Match firstMatch(String input);
  Iterable<Match> allMatches(String input, [int start = 0]);
  bool hasMatch(String input);
  String stringMatch(String input);
  String get pattern;
  bool get isMultiLine;
  bool get isCaseSensitive;
}
