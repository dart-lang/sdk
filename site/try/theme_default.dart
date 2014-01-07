// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of trydart.themes;

/// Default theme extracted from
/// editor/tools/plugins/com.google.dart.tools.deploy/themes/default.xml
class Theme {
  static named(String name) {
    if (name == null) return THEMES[0];
    return THEMES.firstWhere(
        (theme) => name == theme.name,
        orElse: () => THEMES[0]);
  }

  const Theme();

  String get name => 'Default';

  Decoration get abstractMethod => const Decoration(color: '#000000');
  Decoration get annotation => const Decoration(color: '#000000');
  Decoration get background => const Decoration(color: '#ffffff');
  Decoration get bracket => const Decoration(color: '#000000');
  Decoration get builtin => const Decoration(color: '#7e0854', bold: true);
  Decoration get className => const Decoration(color: '#000000');
  Decoration get commentTaskTag => const Decoration(color: '#606060');
  Decoration get constant => const Decoration(color: '#000000');
  Decoration get currentLine => const Decoration(color: '#F0F0F0');
  Decoration get deletionIndication => const Decoration(color: '#000000');
  Decoration get deprecatedMember => const Decoration(color: '#000000');
  Decoration get directive => const Decoration(color: '#7e0854', bold: true);
  Decoration get dynamicType => const Decoration(color: '#000000');
  Decoration get enumName => const Decoration(color: '#000000');
  Decoration get field => const Decoration(color: '#0618bd');
  Decoration get filteredSearchResultIndication =>
      const Decoration(color: '#000000');
  Decoration get findScope => const Decoration(color: '#000000');
  Decoration get foreground => const Decoration(color: '#000000');
  Decoration get getter => const Decoration(color: '#0618bd');
  Decoration get inheritedMethod => const Decoration(color: '#000000');
  Decoration get interface => const Decoration(color: '#000000');
  Decoration get javadoc => const Decoration(color: '#4162bc');
  Decoration get javadocKeyword => const Decoration(color: '#4162bc');
  Decoration get javadocLink => const Decoration(color: '#4162bc');
  Decoration get javadocTag => const Decoration(color: '#7f809e');
  Decoration get keyword => const Decoration(color: '#7e0854', bold: true);
  Decoration get keywordReturn =>
      const Decoration(color: '#7e0854', bold: true);
  Decoration get lineNumber => const Decoration(color: '#000000');
  Decoration get localVariable => const Decoration(color: '#7f1cc9');
  Decoration get localVariableDeclaration =>
      const Decoration(color: '#7f1cc9');
  Decoration get method => const Decoration(color: '#000000');
  Decoration get methodDeclaration =>
      const Decoration(color: '#0b5bd2', bold: true);
  Decoration get multiLineComment => const Decoration(color: '#4162bc');
  Decoration get multiLineString => const Decoration(color: '#2d24fb');
  Decoration get number => const Decoration(color: '#0c6f0e');
  Decoration get occurrenceIndication => const Decoration(color: '#e0e0e0');
  Decoration get operator => const Decoration(color: '#000000');
  Decoration get parameterVariable => const Decoration(color: '#87312e');
  Decoration get searchResultIndication => const Decoration(color: '#D0D0D0');
  Decoration get selectionBackground => const Decoration(color: '#b6d6fd');
  Decoration get selectionForeground => const Decoration(color: '#000000');
  Decoration get setter => const Decoration(color: '#0618bd');
  Decoration get singleLineComment => const Decoration(color: '#417e60');
  Decoration get sourceHoverBackground => const Decoration(color: '#fbfbc8');
  Decoration get staticField => const Decoration(color: '#0618bd');
  Decoration get staticFinalField => const Decoration(color: '#0618bd');
  Decoration get staticMethod => const Decoration(color: '#000000');
  Decoration get staticMethodDeclaration =>
      const Decoration(color: '#404040', bold: true);
  Decoration get string => const Decoration(color: '#2d24fb');
  Decoration get typeArgument => const Decoration(color: '#033178');
  Decoration get typeParameter => const Decoration(color: '#033178');
  Decoration get writeOccurrenceIndication =>
      const Decoration(color: '#e0e0e0');
}
