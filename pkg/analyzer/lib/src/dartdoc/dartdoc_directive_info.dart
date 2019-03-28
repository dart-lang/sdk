// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Information about the directives found in Dartdoc comments.
class DartdocDirectiveInfo {
  // TODO(brianwilkerson) Consider moving the method
  //  DartUnitHoverComputer.computeDocumentation to this class.

  /// A regular expression used to match a macro directive. There is one group
  /// that contains the name of the template.
  static final macroRegExp = new RegExp(r'{@macro\s+([^}]+)}');

  /// A regular expression used to match a template directive. There are two
  /// groups. The first contains the name of the template, the second contains
  /// the body of the template.
  static final templateRegExp = new RegExp(
      r'[ ]*{@template\s+(.+?)}([\s\S]+?){@endtemplate}[ ]*\n?',
      multiLine: true);

  /// A table mapping the names of templates to the unprocessed bodies of the
  /// templates.
  final Map<String, List<String>> _templates = {};

  /// Initialize a newly created set of information about Dartdoc directives.
  DartdocDirectiveInfo();

  /// Process the given Dartdoc [comment], extracting the template directive if
  /// there is one.
  void extractTemplate(String comment) {
    for (Match match in templateRegExp.allMatches(comment)) {
      String name = match.group(1).trim();
      String body = match.group(2).trim();
      _templates[name] = _stripDelimiters(body);
    }
  }

  /// Process the given Dartdoc [comment], replacing any macro directives with
  /// the body of the corresponding template.
  String processDartdoc(String comment) {
    List<String> lines = _stripDelimiters(comment);
    for (int i = lines.length - 1; i >= 0; i--) {
      String line = lines[i];
      Match match = macroRegExp.firstMatch(line);
      if (match != null) {
        String name = match.group(1);
        List<String> body = _templates[name];
        if (body != null) {
          lines.replaceRange(i, i + 1, body);
        }
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
