part of dart.core;
 abstract class Pattern {Iterable<Match> allMatches(String string, [int start = 0]);
 Match matchAsPrefix(String string, [int start = 0]);
}
