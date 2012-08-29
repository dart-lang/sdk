// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * [SearchText] represent the search field text. The text is viewed in three
 * ways: [text] holds the original search text, used for performing
 * case-sensitive matches, [lowerCase] holds the lower-case search text, used
 * for performing case-insenstive matches, [camelCase] holds a camel-case
 * interpretation of the search text, used to order matches in camel-case.
 */
class SearchText {
  final String text;
  final String lowerCase;
  final String camelCase;

  SearchText(String searchText)
      : text = searchText,
        lowerCase = searchText.toLowerCase(),
        camelCase = searchText.isEmpty() ? ''
            : '${searchText.substring(0, 1).toUpperCase()}'
              '${searchText.substring(1)}';

  int get length() => text.length;

  bool isEmpty() => length == 0;
}

/**
 * [StringMatch] represents the case-insensitive matching of [searchText] as a
 * substring within a [text].
 */
class StringMatch {
  final SearchText searchText;
  final String text;
  final int matchOffset;
  final int matchEnd;

  StringMatch(this.searchText,
              this.text, this.matchOffset, this.matchEnd);

  /**
   * Returns the HTML representation of the match.
   */
  String toHtml() {
    return '${text.substring(0, matchOffset)}'
           '<span class="drop-down-link-highlight">$matchText</span>'
           '${text.substring(matchEnd)}';
  }

  String get matchText() =>
      text.substring(matchOffset, matchEnd);

  /**
   * Is [:true:] iff [searchText] matches the full [text] case-sensitively.
   */
  bool get isFullMatch() => text == searchText.text;

  /**
   * Is [:true:] iff [searchText] matches a substring of [text]
   * case-sensitively.
   */
  bool get isExactMatch() => matchText == searchText.text;

  /**
   * Is [:true:] iff [searchText] matches a substring of [text] when
   * [searchText] is interpreted as camel case.
   */
  bool get isCamelCaseMatch() => matchText == searchText.camelCase;
}

/**
 * [Result] represents a match of the search text on a library, type or member.
 */
class Result {
  final StringMatch prefix;
  final StringMatch match;

  final String library;
  final String type;
  final String args;
  final String kind;
  final String url;

  TableRowElement row;

  Result(this.match, this.kind, this.url,
         [this.library, this.type, String args, this.prefix])
      : this.args = args != null ? '&lt;$args&gt;' : '';

  bool get isTopLevel() => prefix == null && type == null;

  void addRow(TableElement table) {
    if (row != null) return;

    clickHandler(Event event) {
      window.location.href = url;
      hideDropDown();
    }

    row = table.insertRow(table.rows.length);
    row.classes.add('drop-down-link-tr');
    row.on.mouseDown.add((event) => hideDropDownSuspend = true);
    row.on.click.add(clickHandler);
    row.on.mouseUp.add((event) => hideDropDownSuspend = false);
    var sb = new StringBuffer();
    sb.add('<td class="drop-down-link-td">');
    sb.add('<table class="drop-down-table"><tr><td colspan="2">');
    if (kind == GETTER) {
      sb.add('get ');
    } else if (kind == SETTER) {
      sb.add('set ');
    }
    sb.add(match.toHtml());
    if (kind == CLASS || kind == INTERFACE || kind == TYPEDEF) {
      sb.add(args);
    } else if (kind == CONSTRUCTOR || kind == METHOD) {
      sb.add('(...)');
    }
    sb.add('</td></tr><tr><td class="drop-down-link-kind">');
    sb.add(kindToString(kind));
    if (prefix != null) {
      sb.add(' in ');
      sb.add(prefix.toHtml());
      sb.add(args);
    } else if (type != null) {
      sb.add(' in ');
      sb.add(type);
      sb.add(args);
    }

    sb.add('</td><td class="drop-down-link-library">');
    if (library != null) {
      sb.add('library $library');
    }
    sb.add('</td></tr></table></td>');
    row.innerHTML = sb.toString();
  }
}

/**
 * Creates a [StringMatch] object for [text] if a substring matches
 * [searchText], or returns [: null :] if no match is found.
 */
StringMatch obtainMatch(SearchText searchText, String text) {
  if (searchText.isEmpty()) {
    return new StringMatch(searchText, text, 0, 0);
  }
  int offset = text.toLowerCase().indexOf(searchText.lowerCase);
  if (offset != -1) {
    return new StringMatch(searchText, text,
                           offset, offset + searchText.length);
  }
  return null;
}

/**
 * Compares [a] and [b], regarding [:true:] smaller than [:false:].
 *
 * [:null:]-values are not handled.
 */
int compareBools(bool a, bool b) {
  if (a == b) return 0;
  return a ? -1 : 1;
}

/**
 * Used to sort the search results heuristically to show the more relevant match
 * in the top of the dropdown.
 */
int resultComparator(Result a, Result b) {
  // Favor top level entities.
  int result = compareBools(a.isTopLevel, b.isTopLevel);
  if (result != 0) return result;

  if (a.prefix != null && b.prefix != null) {
    // Favor full prefix matches.
    result = compareBools(a.prefix.isFullMatch, b.prefix.isFullMatch);
    if (result != 0) return result;
  }

  // Favor matches in the start.
  result = compareBools(a.match.matchOffset == 0,
                        b.match.matchOffset == 0);
  if (result != 0) return result;

  // Favor matches to the end. For example, prefer 'cancel' over 'cancelable'
  result = compareBools(a.match.matchEnd == a.match.text.length,
                        b.match.matchEnd == b.match.text.length);
  if (result != 0) return result;

  // Favor exact case-sensitive matches.
  result = compareBools(a.match.isExactMatch, b.match.isExactMatch);
  if (result != 0) return result;

  // Favor matches that do not break camel-case.
  result = compareBools(a.match.isCamelCaseMatch, b.match.isCamelCaseMatch);
  if (result != 0) return result;

  // Favor matches close to the begining.
  result = a.match.matchOffset.compareTo(b.match.matchOffset);
  if (result != 0) return result;

  if (a.type != null && b.type != null) {
    // Favor short type names over long.
    result = a.type.length.compareTo(b.type.length);
    if (result != 0) return result;

    // Sort type alphabetically.
    // TODO(4805): Use [:type.compareToIgnoreCase] when supported.
    result = a.type.toLowerCase().compareTo(b.type.toLowerCase());
    if (result != 0) return result;
  }

  // Sort match alphabetically.
  // TODO(4805): Use [:text.compareToIgnoreCase] when supported.
  return a.match.text.toLowerCase().compareTo(b.match.text.toLowerCase());
}
