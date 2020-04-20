// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Information about the directives found in Dartdoc comments.
class DartdocDirectiveInfo {
  // TODO(brianwilkerson) Consider moving the method
  //  DartUnitHoverComputer.computeDocumentation to this class.

  /// A regular expression used to match a macro directive. There is one group
  /// that contains the name of the template.
  static final macroRegExp = RegExp(r'{@macro\s+([^}]+)}');

  /// A regular expression used to match a template directive. There are two
  /// groups. The first contains the name of the template, the second contains
  /// the body of the template.
  static final templateRegExp = RegExp(
      r'[ ]*{@template\s+(.+?)}([\s\S]+?){@endtemplate}[ ]*\n?',
      multiLine: true);

  /// A regular expression used to match a youtube or animation directive.
  ///
  /// These are in the form:
  /// `{@youtube 560 315 https://www.youtube.com/watch?v=2uaoEDOgk_I}`.
  static final videoRegExp =
      RegExp(r'{@(youtube|animation)\s+[^}]+\s+[^}]+\s+([^}]+)}');

  /// A table mapping the names of templates to the unprocessed bodies of the
  /// templates.
  final Map<String, String> templateMap = {};

  /// Initialize a newly created set of information about Dartdoc directives.
  DartdocDirectiveInfo();

  /// Add corresponding pairs from the [names] and [values] to the set of
  /// defined templates.
  void addTemplateNamesAndValues(List<String> names, List<String> values) {
    int length = names.length;
    assert(length == values.length);
    for (int i = 0; i < length; i++) {
      templateMap[names[i]] = values[i];
    }
  }

  /// Process the given Dartdoc [comment], extracting the template directive if
  /// there is one.
  void extractTemplate(String comment) {
    for (Match match in templateRegExp.allMatches(comment)) {
      String name = match.group(1).trim();
      String body = match.group(2).trim();
      templateMap[name] = _stripDelimiters(body).join('\n');
    }
  }

  /// Process the given Dartdoc [comment], replacing any known dartdoc
  /// directives with the associated content.
  ///
  /// Macro directives are replaced with the body of the corresponding template.
  ///
  /// Youtube and animation directives are replaced with markdown hyperlinks.
  String processDartdoc(String comment) {
    List<String> lines = _stripDelimiters(comment);
    for (int i = lines.length - 1; i >= 0; i--) {
      String line = lines[i];
      Match match = macroRegExp.firstMatch(line);
      if (match != null) {
        String name = match.group(1);
        String value = templateMap[name];
        if (value != null) {
          lines[i] = value;
        }
        continue;
      }

      match = videoRegExp.firstMatch(line);
      if (match != null) {
        String uri = match.group(2);
        if (uri != null && uri.isNotEmpty) {
          String label = uri;
          if (label.startsWith('https://')) {
            label = label.substring('https://'.length);
          }
          lines[i] = '[$label]($uri)';
        }
        continue;
      }
    }
    return lines.join('\n');
  }

  /// Remove the delimiters from the given [comment].
  List<String> _stripDelimiters(String comment) {
    if (comment == null) {
      return null;
    }
    //
    // Remove /** */.
    //
    if (comment.startsWith('/**')) {
      comment = comment.substring(3);
    }
    if (comment.endsWith('*/')) {
      comment = comment.substring(0, comment.length - 2);
    }
    comment = comment.trim();
    //
    // Remove leading '* ' and '/// '.
    //
    List<String> lines = comment.split('\n');
    int firstNonEmpty = lines.length + 1;
    int lastNonEmpty = -1;
    for (var i = 0; i < lines.length; i++) {
      String line = lines[i];
      line = line.trim();
      if (line.startsWith('*')) {
        line = line.substring(1);
        if (line.startsWith(' ')) {
          line = line.substring(1);
        }
      } else if (line.startsWith('///')) {
        line = line.substring(3);
        if (line.startsWith(' ')) {
          line = line.substring(1);
        }
      }
      if (line.isNotEmpty) {
        if (i < firstNonEmpty) {
          firstNonEmpty = i;
        }
        if (i > lastNonEmpty) {
          lastNonEmpty = i;
        }
      }
      lines[i] = line;
    }
    if (lastNonEmpty < firstNonEmpty) {
      // All of the lines are empty.
      return <String>[];
    }
    return lines.sublist(firstNonEmpty, lastNonEmpty + 1);
  }
}
