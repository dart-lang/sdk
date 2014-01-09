// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of trydart.themes;

/// Black Pastel theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/black-pastel.xml.
/// Author: David.
class Black_PastelTheme extends Theme {
  const Black_PastelTheme();

  String get name => 'Black Pastel';

  Decoration get abstractMethod => const Decoration(color: '#E0E2E4');
  Decoration get annotation => const Decoration(color: '#A082BD');
  Decoration get background => const Decoration(color: '#000000');
  Decoration get bracket => const Decoration(color: '#CCCCCC');
  Decoration get className => const Decoration(color: '#82677E');
  Decoration get commentTaskTag => const Decoration(color: '#a57b61');
  Decoration get constant => const Decoration(color: '#A082BD');
  Decoration get currentLine => const Decoration(color: '#2F393C');
  Decoration get deletionIndication => const Decoration(color: '#E0E2E4');
  Decoration get deprecatedMember => const Decoration(color: '#E0E2E4');
  Decoration get dynamicType => const Decoration(color: '#E0E2E4');
  Decoration get enumName => const Decoration(color: '#E0E2E4');
  Decoration get field => const Decoration(color: '#678CB1');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#616161');
  Decoration get findScope => const Decoration(color: '#E0E2E4');
  Decoration get foreground => const Decoration(color: '#C0C0C0');
  Decoration get inheritedMethod => const Decoration(color: '#E0E2E4');
  Decoration get interface => const Decoration(color: '#82677E');
  Decoration get javadoc => const Decoration(color: '#7D8C93');
  Decoration get javadocKeyword => const Decoration(color: '#A082BD');
  Decoration get javadocLink => const Decoration(color: '#678CB1');
  Decoration get javadocTag => const Decoration(color: '#E0E2E4');
  Decoration get keyword => const Decoration(color: '#82677E');
  Decoration get lineNumber => const Decoration(color: '#81969A');
  Decoration get localVariable => const Decoration(color: '#E0E2E4');
  Decoration get localVariableDeclaration => const Decoration(color: '#E0E2E4');
  Decoration get method => const Decoration(color: '#82677E');
  Decoration get methodDeclaration => const Decoration(color: '#82677E');
  Decoration get multiLineComment => const Decoration(color: '#7D8C93');
  Decoration get number => const Decoration(color: '#c78d9b');
  Decoration get occurrenceIndication => const Decoration(color: '#616161');
  Decoration get operator => const Decoration(color: '#E8E2B7');
  Decoration get parameterVariable => const Decoration(color: '#E0E2E4');
  Decoration get searchResultIndication => const Decoration(color: '#616161');
  Decoration get selectionBackground => const Decoration(color: '#95bed8');
  Decoration get selectionForeground => const Decoration(color: '#C0C0C0');
  Decoration get singleLineComment => const Decoration(color: '#7D8C93');
  Decoration get sourceHoverBackground => const Decoration(color: '#FFFFFF');
  Decoration get staticField => const Decoration(color: '#678CB1');
  Decoration get staticFinalField => const Decoration(color: '#E0E2E4');
  Decoration get staticMethod => const Decoration(color: '#E0E2E4');
  Decoration get string => const Decoration(color: '#c78d9b');
  Decoration get typeArgument => const Decoration(color: '#E0E2E4');
  Decoration get typeParameter => const Decoration(color: '#E0E2E4');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#616161');
}

/// Dartboard theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/dartboard.xml.
/// Author: Dart.
class DartboardTheme extends Theme {
  const DartboardTheme();

  String get name => 'Dartboard';

  Decoration get abstractMethod => const Decoration(color: '#000000');
  Decoration get annotation => const Decoration(color: '#000000');
  Decoration get background => const Decoration(color: '#fafafa');
  Decoration get bracket => const Decoration(color: '#606060');
  Decoration get builtin => const Decoration(color: '#000000', bold: true);
  Decoration get className => const Decoration(color: '#0646a7');
  Decoration get commentTaskTag => const Decoration(color: '#606060');
  Decoration get constant => const Decoration(color: '#55122a');
  Decoration get currentLine => const Decoration(color: '#F0F0F0');
  Decoration get deletionIndication => const Decoration(color: '#000000');
  Decoration get deprecatedMember => const Decoration(color: '#000000');
  Decoration get directive => const Decoration(color: '#014d64', bold: true);
  Decoration get dynamicType => const Decoration(color: '#000000');
  Decoration get enumName => const Decoration(color: '#000000');
  Decoration get field => const Decoration(color: '#87312e');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#000000');
  Decoration get findScope => const Decoration(color: '#000000');
  Decoration get foreground => const Decoration(color: '#000000');
  Decoration get getter => const Decoration(color: '#87312e');
  Decoration get inheritedMethod => const Decoration(color: '#000000');
  Decoration get interface => const Decoration(color: '#000000');
  Decoration get javadoc => const Decoration(color: '#606060');
  Decoration get javadocKeyword => const Decoration(color: '#606060');
  Decoration get javadocLink => const Decoration(color: '#606060');
  Decoration get javadocTag => const Decoration(color: '#606060');
  Decoration get keyword => const Decoration(color: '#000000', bold: true);
  Decoration get keywordReturn => const Decoration(color: '#000000', bold: true);
  Decoration get lineNumber => const Decoration(color: '#000000');
  Decoration get localVariable => const Decoration(color: '#000000');
  Decoration get localVariableDeclaration => const Decoration(color: '#000000');
  Decoration get method => const Decoration(color: '#000000');
  Decoration get methodDeclaration => const Decoration(color: '#0b5bd2', bold: true);
  Decoration get multiLineComment => const Decoration(color: '#606060');
  Decoration get multiLineString => const Decoration(color: '#679b3b');
  Decoration get number => const Decoration(color: '#000000');
  Decoration get occurrenceIndication => const Decoration(color: '#e0e0e0');
  Decoration get operator => const Decoration(color: '#000000');
  Decoration get parameterVariable => const Decoration(color: '#87312e');
  Decoration get searchResultIndication => const Decoration(color: '#D0D0D0');
  Decoration get selectionBackground => const Decoration(color: '#b6d6fd');
  Decoration get selectionForeground => const Decoration(color: '#000000');
  Decoration get setter => const Decoration(color: '#87312e');
  Decoration get singleLineComment => const Decoration(color: '#7a7a7a');
  Decoration get sourceHoverBackground => const Decoration(color: '#fbfbc8');
  Decoration get staticField => const Decoration(color: '#87312e');
  Decoration get staticFinalField => const Decoration(color: '#55122a');
  Decoration get staticMethod => const Decoration(color: '#000000');
  Decoration get staticMethodDeclaration => const Decoration(color: '#0b5bd2', bold: true);
  Decoration get string => const Decoration(color: '#679b3b');
  Decoration get typeArgument => const Decoration(color: '#033178');
  Decoration get typeParameter => const Decoration(color: '#033178');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#e0e0e0');
}

/// Debugging theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/debugging.xml.
/// Author: Debug Tool.
class DebuggingTheme extends Theme {
  const DebuggingTheme();

  String get name => 'Debugging';

  Decoration get abstractMethod => const Decoration(color: '#F00000');
  Decoration get annotation => const Decoration(color: '#F00000');
  Decoration get background => const Decoration(color: '#FFF8FF');
  Decoration get bracket => const Decoration(color: '#F00000');
  Decoration get builtin => const Decoration(color: '#F00000');
  Decoration get className => const Decoration(color: '#F00000');
  Decoration get commentTaskTag => const Decoration(color: '#F00000');
  Decoration get constant => const Decoration(color: '#F00000');
  Decoration get currentLine => const Decoration(color: '#F0F0F0');
  Decoration get deletionIndication => const Decoration(color: '#F00000');
  Decoration get deprecatedMember => const Decoration(color: '#F00000');
  Decoration get directive => const Decoration(color: '#F00000');
  Decoration get dynamicType => const Decoration(color: '#F00000');
  Decoration get enumName => const Decoration(color: '#F00000');
  Decoration get field => const Decoration(color: '#F000000');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#F00000');
  Decoration get findScope => const Decoration(color: '#F00000');
  Decoration get foreground => const Decoration(color: '#F00000');
  Decoration get getter => const Decoration(color: '#F00000');
  Decoration get inheritedMethod => const Decoration(color: '#F00000');
  Decoration get interface => const Decoration(color: '#F00000');
  Decoration get javadoc => const Decoration(color: '#F00000');
  Decoration get javadocKeyword => const Decoration(color: '#F00000');
  Decoration get javadocLink => const Decoration(color: '#F00000');
  Decoration get javadocTag => const Decoration(color: '#F00000');
  Decoration get keyword => const Decoration(color: '#F00000', bold: true);
  Decoration get keywordReturn => const Decoration(color: '#F00000', bold: true);
  Decoration get lineNumber => const Decoration(color: '#F00000');
  Decoration get localVariable => const Decoration(color: '#F00000');
  Decoration get localVariableDeclaration => const Decoration(color: '#F00000');
  Decoration get method => const Decoration(color: '#F00000');
  Decoration get methodDeclaration => const Decoration(color: '#F00000');
  Decoration get multiLineComment => const Decoration(color: '#F00000');
  Decoration get multiLineString => const Decoration(color: '#F00000');
  Decoration get number => const Decoration(color: '#F00000');
  Decoration get occurrenceIndication => const Decoration(color: '#F00000');
  Decoration get operator => const Decoration(color: '#F00000');
  Decoration get parameterVariable => const Decoration(color: '#F00000');
  Decoration get searchResultIndication => const Decoration(color: '#F00000');
  Decoration get selectionBackground => const Decoration(color: '#F000F0');
  Decoration get selectionForeground => const Decoration(color: '#F00000');
  Decoration get setter => const Decoration(color: '#F00000');
  Decoration get singleLineComment => const Decoration(color: '#F00000');
  Decoration get sourceHoverBackground => const Decoration(color: '#F00000');
  Decoration get staticField => const Decoration(color: '#F00000');
  Decoration get staticFinalField => const Decoration(color: '#F00000');
  Decoration get staticMethod => const Decoration(color: '#F00000');
  Decoration get staticMethodDeclaration => const Decoration(color: '#F00000');
  Decoration get string => const Decoration(color: '#F00000');
  Decoration get typeArgument => const Decoration(color: '#F00000');
  Decoration get typeParameter => const Decoration(color: '#F00000');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#F00000');
}

/// Dart Editor theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/default.xml.
/// Author: Dart.
class Dart_EditorTheme extends Theme {
  const Dart_EditorTheme();

  String get name => 'Dart Editor';

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
  Decoration get filteredSearchResultIndication => const Decoration(color: '#000000');
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
  Decoration get keywordReturn => const Decoration(color: '#7e0854', bold: true);
  Decoration get lineNumber => const Decoration(color: '#000000');
  Decoration get localVariable => const Decoration(color: '#7f1cc9');
  Decoration get localVariableDeclaration => const Decoration(color: '#7f1cc9');
  Decoration get method => const Decoration(color: '#000000');
  Decoration get methodDeclaration => const Decoration(color: '#0b5bd2', bold: true);
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
  Decoration get staticMethodDeclaration => const Decoration(color: '#404040', bold: true);
  Decoration get string => const Decoration(color: '#2d24fb');
  Decoration get typeArgument => const Decoration(color: '#033178');
  Decoration get typeParameter => const Decoration(color: '#033178');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#e0e0e0');
}

/// frontenddev theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/frontenddev.xml.
/// Author: Plebe.
class frontenddevTheme extends Theme {
  const frontenddevTheme();

  String get name => 'frontenddev';

  Decoration get abstractMethod => const Decoration(color: '#F1C436');
  Decoration get annotation => const Decoration(color: '#999999');
  Decoration get background => const Decoration(color: '#000000');
  Decoration get bracket => const Decoration(color: '#FFFFFF');
  Decoration get className => const Decoration(color: '#9CF828');
  Decoration get commentTaskTag => const Decoration(color: '#666666');
  Decoration get currentLine => const Decoration(color: '#222220');
  Decoration get deletionIndication => const Decoration(color: '#FF0000');
  Decoration get deprecatedMember => const Decoration(color: '#FFFFFF');
  Decoration get dynamicType => const Decoration(color: '#F7C527');
  Decoration get enumName => const Decoration(color: '#408000');
  Decoration get field => const Decoration(color: '#c38705');
  Decoration get findScope => const Decoration(color: '#191919');
  Decoration get foreground => const Decoration(color: '#FFFFFF');
  Decoration get inheritedMethod => const Decoration(color: '#E3B735');
  Decoration get interface => const Decoration(color: '#87F025');
  Decoration get javadoc => const Decoration(color: '#666666');
  Decoration get javadocKeyword => const Decoration(color: '#800080');
  Decoration get javadocLink => const Decoration(color: '#666666');
  Decoration get javadocTag => const Decoration(color: '#800080');
  Decoration get keyword => const Decoration(color: '#999999');
  Decoration get lineNumber => const Decoration(color: '#999999');
  Decoration get localVariable => const Decoration(color: '#F7C527');
  Decoration get localVariableDeclaration => const Decoration(color: '#F7C527');
  Decoration get method => const Decoration(color: '#F7C527');
  Decoration get methodDeclaration => const Decoration(color: '#F1C438');
  Decoration get multiLineComment => const Decoration(color: '#666666');
  Decoration get number => const Decoration(color: '#FF0000');
  Decoration get occurrenceIndication => const Decoration(color: '#616161');
  Decoration get operator => const Decoration(color: '#FFFFFF');
  Decoration get parameterVariable => const Decoration(color: '#069609');
  Decoration get selectionBackground => const Decoration(color: '#333333');
  Decoration get selectionForeground => const Decoration(color: '#333333');
  Decoration get singleLineComment => const Decoration(color: '#666666');
  Decoration get staticField => const Decoration(color: '#FFFFFF');
  Decoration get staticFinalField => const Decoration(color: '#80FF00');
  Decoration get staticMethod => const Decoration(color: '#FFFFFF');
  Decoration get string => const Decoration(color: '#00a40f');
  Decoration get typeArgument => const Decoration(color: '#D9B0AC');
  Decoration get typeParameter => const Decoration(color: '#CDB1AD');
}

/// Gedit Original Oblivion theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/gedit-original-oblivion.xml.
/// Author: Sepehr Lajevardi.
class Gedit_Original_OblivionTheme extends Theme {
  const Gedit_Original_OblivionTheme();

  String get name => 'Gedit Original Oblivion';

  Decoration get abstractMethod => const Decoration(color: '#BED6FF');
  Decoration get annotation => const Decoration(color: '#FFFFFF');
  Decoration get background => const Decoration(color: '#2e3436');
  Decoration get bracket => const Decoration(color: '#D8D8D8');
  Decoration get className => const Decoration(color: '#bbbbbb');
  Decoration get commentTaskTag => const Decoration(color: '#CCDF32');
  Decoration get constant => const Decoration(color: '#edd400');
  Decoration get currentLine => const Decoration(color: '#555753');
  Decoration get deletionIndication => const Decoration(color: '#D25252');
  Decoration get dynamicType => const Decoration(color: '#729fcf');
  Decoration get field => const Decoration(color: '#BED6FF');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#D8D8D8');
  Decoration get findScope => const Decoration(color: '#000000');
  Decoration get foreground => const Decoration(color: '#d3d7cf');
  Decoration get inheritedMethod => const Decoration(color: '#BED6FF');
  Decoration get interface => const Decoration(color: '#D197D9');
  Decoration get javadoc => const Decoration(color: '#888a85');
  Decoration get javadocKeyword => const Decoration(color: '#888a85');
  Decoration get javadocLink => const Decoration(color: '#888a85');
  Decoration get javadocTag => const Decoration(color: '#888a85');
  Decoration get keyword => const Decoration(color: '#FFFFFF');
  Decoration get lineNumber => const Decoration(color: '#555753');
  Decoration get localVariable => const Decoration(color: '#729fcf');
  Decoration get localVariableDeclaration => const Decoration(color: '#729fcf');
  Decoration get method => const Decoration(color: '#FFFFFF');
  Decoration get methodDeclaration => const Decoration(color: '#BED6FF');
  Decoration get multiLineComment => const Decoration(color: '#888a85');
  Decoration get number => const Decoration(color: '#ce5c00');
  Decoration get occurrenceIndication => const Decoration(color: '#000000');
  Decoration get operator => const Decoration(color: '#D8D8D8');
  Decoration get parameterVariable => const Decoration(color: '#79ABFF');
  Decoration get searchResultIndication => const Decoration(color: '#eeeeec');
  Decoration get selectionBackground => const Decoration(color: '#888a85');
  Decoration get selectionForeground => const Decoration(color: '#eeeeec');
  Decoration get singleLineComment => const Decoration(color: '#888a85');
  Decoration get sourceHoverBackground => const Decoration(color: '#000000');
  Decoration get staticField => const Decoration(color: '#EFC090');
  Decoration get staticFinalField => const Decoration(color: '#EFC090');
  Decoration get staticMethod => const Decoration(color: '#BED6FF');
  Decoration get string => const Decoration(color: '#edd400');
  Decoration get typeArgument => const Decoration(color: '#BFA4A4');
  Decoration get typeParameter => const Decoration(color: '#BFA4A4');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#000000');
}

/// Havenjark theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/havenjark.xml.
/// Author: Rodrigo Franco.
class HavenjarkTheme extends Theme {
  const HavenjarkTheme();

  String get name => 'Havenjark';

  Decoration get abstractMethod => const Decoration(color: '#C0B6A8');
  Decoration get annotation => const Decoration(color: '#808080');
  Decoration get background => const Decoration(color: '#2D3639');
  Decoration get bracket => const Decoration(color: '#FFFFFF');
  Decoration get className => const Decoration(color: '#B8ADA0');
  Decoration get commentTaskTag => const Decoration(color: '#ACC1AC');
  Decoration get constant => const Decoration(color: '#93A2CC');
  Decoration get currentLine => const Decoration(color: '#00001F');
  Decoration get deprecatedMember => const Decoration(color: '#F3D651');
  Decoration get dynamicType => const Decoration(color: '#A19A83');
  Decoration get field => const Decoration(color: '#B3B784');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#3F3F6A');
  Decoration get findScope => const Decoration(color: '#B9A185');
  Decoration get foreground => const Decoration(color: '#C0B6A8');
  Decoration get inheritedMethod => const Decoration(color: '#C0B6A8');
  Decoration get interface => const Decoration(color: '#B8ADA0');
  Decoration get javadoc => const Decoration(color: '#B3B5AF');
  Decoration get javadocKeyword => const Decoration(color: '#CC9393');
  Decoration get javadocLink => const Decoration(color: '#A893CC');
  Decoration get javadocTag => const Decoration(color: '#9393CC');
  Decoration get keyword => const Decoration(color: '#A38474');
  Decoration get lineNumber => const Decoration(color: '#C0C0C0');
  Decoration get localVariable => const Decoration(color: '#A19A83');
  Decoration get localVariableDeclaration => const Decoration(color: '#A19A83');
  Decoration get method => const Decoration(color: '#DFBE95');
  Decoration get methodDeclaration => const Decoration(color: '#DFBE95');
  Decoration get multiLineComment => const Decoration(color: '#AEAEAE');
  Decoration get multiLineString => const Decoration(color: '#808080');
  Decoration get number => const Decoration(color: '#B9A185');
  Decoration get occurrenceIndication => const Decoration(color: '#616161');
  Decoration get operator => const Decoration(color: '#F0EFD0');
  Decoration get parameterVariable => const Decoration(color: '#A19A83');
  Decoration get searchResultIndication => const Decoration(color: '#464467');
  Decoration get selectionBackground => const Decoration(color: '#2A4750');
  Decoration get selectionForeground => const Decoration(color: '#C0B6A8');
  Decoration get singleLineComment => const Decoration(color: '#AEAEAE');
  Decoration get sourceHoverBackground => const Decoration(color: '#A19879');
  Decoration get staticField => const Decoration(color: '#93A2CC');
  Decoration get staticFinalField => const Decoration(color: '#93A2CC');
  Decoration get staticMethod => const Decoration(color: '#C4C4B7');
  Decoration get string => const Decoration(color: '#CC9393');
  Decoration get typeArgument => const Decoration(color: '#C0B6A8');
  Decoration get typeParameter => const Decoration(color: '#C0B6A8');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#948567');
}

/// Hot Pink theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/hotpink.xml.
/// Author: KS.
class Hot_PinkTheme extends Theme {
  const Hot_PinkTheme();

  String get name => 'Hot Pink';

  Decoration get abstractMethod => const Decoration(color: '#000000');
  Decoration get annotation => const Decoration(color: '#808080');
  Decoration get background => const Decoration(color: '#FFFFFF');
  Decoration get bracket => const Decoration(color: '#000f6a');
  Decoration get builtin => const Decoration(color: '#7e0854');
  Decoration get className => const Decoration(color: '#008000', bold: true);
  Decoration get commentTaskTag => const Decoration(color: '#417e60');
  Decoration get constant => const Decoration(color: '#ae25ab');
  Decoration get currentLine => const Decoration(color: '#fff7cd');
  Decoration get deletionIndication => const Decoration(color: '#9b5656');
  Decoration get deprecatedMember => const Decoration(color: '#000000');
  Decoration get directive => const Decoration(color: '#FF4040');
  Decoration get dynamicType => const Decoration(color: '#FF4040');
  Decoration get enumName => const Decoration(color: '#000000');
  Decoration get field => const Decoration(color: '#0000C0');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#CC6633');
  Decoration get findScope => const Decoration(color: '#BCADAD');
  Decoration get foreground => const Decoration(color: '#000000');
  Decoration get getter => const Decoration(color: '#0200C0');
  Decoration get inheritedMethod => const Decoration(color: '#2c577c');
  Decoration get interface => const Decoration(color: '#000000');
  Decoration get javadoc => const Decoration(color: '#4162bc');
  Decoration get javadocKeyword => const Decoration(color: '#CC9393');
  Decoration get javadocLink => const Decoration(color: '#4162bc');
  Decoration get javadocTag => const Decoration(color: '#4162bc');
  Decoration get keyword => const Decoration(color: '#7e0854', bold: true);
  Decoration get keywordReturn => const Decoration(color: '#800390', bold: true);
  Decoration get lineNumber => const Decoration(color: '#999999');
  Decoration get localVariable => const Decoration(color: '#FF00FF');
  Decoration get localVariableDeclaration => const Decoration(color: '#008080');
  Decoration get method => const Decoration(color: '#2BA6E8');
  Decoration get methodDeclaration => const Decoration(color: '#8000FF');
  Decoration get multiLineComment => const Decoration(color: '#417e60');
  Decoration get multiLineString => const Decoration(color: '#2000FF');
  Decoration get number => const Decoration(color: '#008000');
  Decoration get occurrenceIndication => const Decoration(color: '#CC6633');
  Decoration get operator => const Decoration(color: '#5f97a9');
  Decoration get parameterVariable => const Decoration(color: '#D7721E');
  Decoration get searchResultIndication => const Decoration(color: '#CC6633');
  Decoration get selectionBackground => const Decoration(color: '#c0c0c0');
  Decoration get selectionForeground => const Decoration(color: '#FFFFFF');
  Decoration get setter => const Decoration(color: '#0200C0');
  Decoration get singleLineComment => const Decoration(color: '#417e60');
  Decoration get sourceHoverBackground => const Decoration(color: '#EEEEEE');
  Decoration get staticField => const Decoration(color: '#0000C0');
  Decoration get staticFinalField => const Decoration(color: '#464646');
  Decoration get staticMethod => const Decoration(color: '#2BA6E8', bold: true);
  Decoration get staticMethodDeclaration => const Decoration(color: '#8000FF', bold: true);
  Decoration get string => const Decoration(color: '#2000FF');
  Decoration get typeArgument => const Decoration(color: '#d07fcd');
  Decoration get typeParameter => const Decoration(color: '#D00000', bold: true);
  Decoration get writeOccurrenceIndication => const Decoration(color: '#CC6633');
}

/// Inkpot theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/inkpot.xml.
/// Author: Ciaran McCreesh.
class InkpotTheme extends Theme {
  const InkpotTheme();

  String get name => 'Inkpot';

  Decoration get background => const Decoration(color: '#1F1F27');
  Decoration get bracket => const Decoration(color: '#CFBFAD');
  Decoration get className => const Decoration(color: '#87CEFA');
  Decoration get commentTaskTag => const Decoration(color: '#FF8BFF');
  Decoration get currentLine => const Decoration(color: '#2D2D44');
  Decoration get dynamicType => const Decoration(color: '#CFBFAD');
  Decoration get enumName => const Decoration(color: '#CFBFAD');
  Decoration get foreground => const Decoration(color: '#CFBFAD');
  Decoration get interface => const Decoration(color: '#87FAC4');
  Decoration get keyword => const Decoration(color: '#808BED');
  Decoration get lineNumber => const Decoration(color: '#2B91AF');
  Decoration get localVariable => const Decoration(color: '#CFBFAD');
  Decoration get localVariableDeclaration => const Decoration(color: '#CFBFAD');
  Decoration get method => const Decoration(color: '#87CEFA');
  Decoration get methodDeclaration => const Decoration(color: '#CFBFAD');
  Decoration get multiLineComment => const Decoration(color: '#CD8B00');
  Decoration get number => const Decoration(color: '#FFCD8B');
  Decoration get occurrenceIndication => const Decoration(color: '#616161');
  Decoration get operator => const Decoration(color: '#CFBFAD');
  Decoration get selectionBackground => const Decoration(color: '#8B8BFF');
  Decoration get selectionForeground => const Decoration(color: '#404040');
  Decoration get singleLineComment => const Decoration(color: '#CD8B00');
  Decoration get sourceHoverBackground => const Decoration(color: '#FFFFFF');
  Decoration get string => const Decoration(color: '#FFCD8B');
}

/// minimal theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/minimal.xml.
/// Author: meers davy.
class minimalTheme extends Theme {
  const minimalTheme();

  String get name => 'minimal';

  Decoration get abstractMethod => const Decoration(color: '#5c8198');
  Decoration get annotation => const Decoration(color: '#AAAAFF');
  Decoration get background => const Decoration(color: '#ffffff');
  Decoration get bracket => const Decoration(color: '#000066');
  Decoration get className => const Decoration(color: '#000066');
  Decoration get commentTaskTag => const Decoration(color: '#666666');
  Decoration get currentLine => const Decoration(color: '#aaccff');
  Decoration get deletionIndication => const Decoration(color: '#aaccff');
  Decoration get deprecatedMember => const Decoration(color: '#ab2525');
  Decoration get enumName => const Decoration(color: '#000066');
  Decoration get field => const Decoration(color: '#566874');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#EFEFEF');
  Decoration get findScope => const Decoration(color: '#BCADff');
  Decoration get foreground => const Decoration(color: '#000000');
  Decoration get inheritedMethod => const Decoration(color: '#5c8198');
  Decoration get interface => const Decoration(color: '#000066');
  Decoration get javadoc => const Decoration(color: '#05314d');
  Decoration get javadocKeyword => const Decoration(color: '#05314d');
  Decoration get javadocLink => const Decoration(color: '#05314d');
  Decoration get javadocTag => const Decoration(color: '#05314d');
  Decoration get keyword => const Decoration(color: '#5c8198');
  Decoration get lineNumber => const Decoration(color: '#666666');
  Decoration get localVariable => const Decoration(color: '#5c8198');
  Decoration get localVariableDeclaration => const Decoration(color: '#5c8198');
  Decoration get method => const Decoration(color: '#5c8198');
  Decoration get methodDeclaration => const Decoration(color: '#5c8198');
  Decoration get multiLineComment => const Decoration(color: '#334466');
  Decoration get number => const Decoration(color: '#333333');
  Decoration get occurrenceIndication => const Decoration(color: '#EFEFEF');
  Decoration get operator => const Decoration(color: '#333333');
  Decoration get parameterVariable => const Decoration(color: '#5c8198');
  Decoration get searchResultIndication => const Decoration(color: '#EFEFEF');
  Decoration get selectionBackground => const Decoration(color: '#Efefff');
  Decoration get selectionForeground => const Decoration(color: '#000066');
  Decoration get singleLineComment => const Decoration(color: '#334466');
  Decoration get sourceHoverBackground => const Decoration(color: '#EEEEEE');
  Decoration get staticField => const Decoration(color: '#05314d');
  Decoration get staticFinalField => const Decoration(color: '#05314d');
  Decoration get staticMethod => const Decoration(color: '#5c8198');
  Decoration get string => const Decoration(color: '#333333');
  Decoration get typeArgument => const Decoration(color: '#5c8198');
  Decoration get typeParameter => const Decoration(color: '#5c8198');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#EFEFEF');
}

/// Monokai theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/monokai.xml.
/// Author: Truong Xuan Tinh.
class MonokaiTheme extends Theme {
  const MonokaiTheme();

  String get name => 'Monokai';

  Decoration get abstractMethod => const Decoration(color: '#BED6FF');
  Decoration get annotation => const Decoration(color: '#FFFFFF');
  Decoration get background => const Decoration(color: '#272822');
  Decoration get bracket => const Decoration(color: '#D8D8D8');
  Decoration get className => const Decoration(color: '#FFFFFF');
  Decoration get commentTaskTag => const Decoration(color: '#CCDF32');
  Decoration get constant => const Decoration(color: '#EFB571');
  Decoration get currentLine => const Decoration(color: '#3E3D32');
  Decoration get deletionIndication => const Decoration(color: '#D25252');
  Decoration get deprecatedMember => const Decoration(color: '#F8F8F2');
  Decoration get dynamicType => const Decoration(color: '#79ABFF');
  Decoration get enumName => const Decoration(color: '#66D9EF');
  Decoration get field => const Decoration(color: '#BED6FF');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#D8D8D8');
  Decoration get findScope => const Decoration(color: '#000000');
  Decoration get foreground => const Decoration(color: '#F8F8F2');
  Decoration get inheritedMethod => const Decoration(color: '#BED6FF');
  Decoration get interface => const Decoration(color: '#D197D9');
  Decoration get javadoc => const Decoration(color: '#75715E');
  Decoration get javadocKeyword => const Decoration(color: '#D9E577');
  Decoration get javadocLink => const Decoration(color: '#D9E577');
  Decoration get javadocTag => const Decoration(color: '#D9E577');
  Decoration get keyword => const Decoration(color: '#66CCB3');
  Decoration get lineNumber => const Decoration(color: '#F8F8F2');
  Decoration get localVariable => const Decoration(color: '#79ABFF');
  Decoration get localVariableDeclaration => const Decoration(color: '#BED6FF');
  Decoration get method => const Decoration(color: '#FFFFFF');
  Decoration get methodDeclaration => const Decoration(color: '#BED6FF');
  Decoration get multiLineComment => const Decoration(color: '#75715e');
  Decoration get number => const Decoration(color: '#7FB347');
  Decoration get occurrenceIndication => const Decoration(color: '#000000');
  Decoration get operator => const Decoration(color: '#D8D8D8');
  Decoration get parameterVariable => const Decoration(color: '#79ABFF');
  Decoration get searchResultIndication => const Decoration(color: '#D8D8D8');
  Decoration get selectionBackground => const Decoration(color: '#757575');
  Decoration get selectionForeground => const Decoration(color: '#D0D0D0');
  Decoration get singleLineComment => const Decoration(color: '#75715E');
  Decoration get sourceHoverBackground => const Decoration(color: '#000000');
  Decoration get staticField => const Decoration(color: '#EFC090');
  Decoration get staticFinalField => const Decoration(color: '#EFC090');
  Decoration get staticMethod => const Decoration(color: '#BED6FF');
  Decoration get string => const Decoration(color: '#E6DB74');
  Decoration get typeArgument => const Decoration(color: '#BFA4A4');
  Decoration get typeParameter => const Decoration(color: '#BFA4A4');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#000000');
}

/// Mr theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/mr.xml.
/// Author: Jongosi.
class MrTheme extends Theme {
  const MrTheme();

  String get name => 'Mr';

  Decoration get abstractMethod => const Decoration(color: '#000099');
  Decoration get annotation => const Decoration(color: '#990000');
  Decoration get background => const Decoration(color: '#FFFFFF');
  Decoration get bracket => const Decoration(color: '#000099');
  Decoration get className => const Decoration(color: '#006600');
  Decoration get commentTaskTag => const Decoration(color: '#FF3300');
  Decoration get constant => const Decoration(color: '#552200');
  Decoration get currentLine => const Decoration(color: '#D8D8D8');
  Decoration get deprecatedMember => const Decoration(color: '#D8D8D8');
  Decoration get enumName => const Decoration(color: '#FF0000');
  Decoration get field => const Decoration(color: '#000099');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#D8D8D8');
  Decoration get foreground => const Decoration(color: '#333333');
  Decoration get inheritedMethod => const Decoration(color: '#000099');
  Decoration get interface => const Decoration(color: '#666666');
  Decoration get javadoc => const Decoration(color: '#FF3300');
  Decoration get javadocKeyword => const Decoration(color: '#990099');
  Decoration get javadocLink => const Decoration(color: '#990099');
  Decoration get javadocTag => const Decoration(color: '#990099');
  Decoration get keyword => const Decoration(color: '#0000FF');
  Decoration get lineNumber => const Decoration(color: '#D8D8D8');
  Decoration get localVariable => const Decoration(color: '#0066FF');
  Decoration get localVariableDeclaration => const Decoration(color: '#000099');
  Decoration get method => const Decoration(color: '#000099');
  Decoration get methodDeclaration => const Decoration(color: '#000099');
  Decoration get multiLineComment => const Decoration(color: '#FF9900');
  Decoration get number => const Decoration(color: '#0000FF');
  Decoration get occurrenceIndication => const Decoration(color: '#000000');
  Decoration get operator => const Decoration(color: '#0000FF');
  Decoration get parameterVariable => const Decoration(color: '#0000FF');
  Decoration get searchResultIndication => const Decoration(color: '#D8D8D8');
  Decoration get selectionBackground => const Decoration(color: '#D8D8D8');
  Decoration get selectionForeground => const Decoration(color: '#333333');
  Decoration get singleLineComment => const Decoration(color: '#FF9900');
  Decoration get sourceHoverBackground => const Decoration(color: '#D8D8D8');
  Decoration get staticField => const Decoration(color: '#552200');
  Decoration get staticFinalField => const Decoration(color: '#552200');
  Decoration get staticMethod => const Decoration(color: '#990000');
  Decoration get string => const Decoration(color: '#CC0000');
  Decoration get typeArgument => const Decoration(color: '#0000FF');
  Decoration get typeParameter => const Decoration(color: '#006600');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#000000');
}

/// NightLion Aptana Theme theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/nightlion-aptana-theme.xml.
/// Author: NightLion.
class NightLion_Aptana_ThemeTheme extends Theme {
  const NightLion_Aptana_ThemeTheme();

  String get name => 'NightLion Aptana Theme';

  Decoration get annotation => const Decoration(color: '#808080');
  Decoration get background => const Decoration(color: '#1E1E1E');
  Decoration get bracket => const Decoration(color: '#FFFFFF');
  Decoration get className => const Decoration(color: '#CAE682');
  Decoration get commentTaskTag => const Decoration(color: '#ACC1AC');
  Decoration get currentLine => const Decoration(color: '#505050');
  Decoration get deprecatedMember => const Decoration(color: '#FFFFFF');
  Decoration get dynamicType => const Decoration(color: '#D4C4A9');
  Decoration get field => const Decoration(color: '#B3B784');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#3F3F6A');
  Decoration get findScope => const Decoration(color: '#BCADAD');
  Decoration get foreground => const Decoration(color: '#E2E2E2');
  Decoration get interface => const Decoration(color: '#CAE682');
  Decoration get javadoc => const Decoration(color: '#B3B5AF');
  Decoration get javadocKeyword => const Decoration(color: '#CC9393');
  Decoration get javadocLink => const Decoration(color: '#A893CC');
  Decoration get javadocTag => const Decoration(color: '#9393CC');
  Decoration get keyword => const Decoration(color: '#8DCBE2');
  Decoration get lineNumber => const Decoration(color: '#C0C0C0');
  Decoration get localVariable => const Decoration(color: '#D4C4A9');
  Decoration get localVariableDeclaration => const Decoration(color: '#D4C4A9');
  Decoration get method => const Decoration(color: '#DFBE95');
  Decoration get methodDeclaration => const Decoration(color: '#DFBE95');
  Decoration get multiLineComment => const Decoration(color: '#73879B');
  Decoration get number => const Decoration(color: '#EAB882');
  Decoration get occurrenceIndication => const Decoration(color: '#616161');
  Decoration get operator => const Decoration(color: '#F0EFD0');
  Decoration get searchResultIndication => const Decoration(color: '#464467');
  Decoration get selectionBackground => const Decoration(color: '#364656');
  Decoration get selectionForeground => const Decoration(color: '#FFFFFF');
  Decoration get singleLineComment => const Decoration(color: '#7F9F7F');
  Decoration get sourceHoverBackground => const Decoration(color: '#A19879');
  Decoration get staticField => const Decoration(color: '#93A2CC');
  Decoration get staticFinalField => const Decoration(color: '#53DCCD');
  Decoration get staticMethod => const Decoration(color: '#C4C4B7');
  Decoration get string => const Decoration(color: '#CC9393');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#948567');
}

/// Notepad++ Like theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/notepad++-like.xml.
/// Author: Vokiel.
class Notepad___LikeTheme extends Theme {
  const Notepad___LikeTheme();

  String get name => 'Notepad++ Like';

  Decoration get abstractMethod => const Decoration(color: '#FF00FF');
  Decoration get annotation => const Decoration(color: '#808080');
  Decoration get background => const Decoration(color: '#FFFFFF');
  Decoration get bracket => const Decoration(color: '#8000FF');
  Decoration get className => const Decoration(color: '#000080');
  Decoration get commentTaskTag => const Decoration(color: '#008000');
  Decoration get currentLine => const Decoration(color: '#EEEEEE');
  Decoration get deletionIndication => const Decoration(color: '#9b5656');
  Decoration get deprecatedMember => const Decoration(color: '#ab2525');
  Decoration get enumName => const Decoration(color: '#800040');
  Decoration get field => const Decoration(color: '#800080');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#EFEFEF');
  Decoration get findScope => const Decoration(color: '#BCADAD');
  Decoration get foreground => const Decoration(color: '#8000FF');
  Decoration get inheritedMethod => const Decoration(color: '#FF00FF');
  Decoration get interface => const Decoration(color: '#9b5656');
  Decoration get javadoc => const Decoration(color: '#800080');
  Decoration get javadocKeyword => const Decoration(color: '#0000FF');
  Decoration get javadocLink => const Decoration(color: '#800080');
  Decoration get javadocTag => const Decoration(color: '#801f91');
  Decoration get keyword => const Decoration(color: '#0000FF');
  Decoration get lineNumber => const Decoration(color: '#999999');
  Decoration get localVariable => const Decoration(color: '#000080');
  Decoration get localVariableDeclaration => const Decoration(color: '#000080');
  Decoration get method => const Decoration(color: '#FF00FF');
  Decoration get methodDeclaration => const Decoration(color: '#FF00FF');
  Decoration get multiLineComment => const Decoration(color: '#008000');
  Decoration get number => const Decoration(color: '#FF8000');
  Decoration get occurrenceIndication => const Decoration(color: '#EFEFEF');
  Decoration get operator => const Decoration(color: '#8000FF');
  Decoration get parameterVariable => const Decoration(color: '#0000FF');
  Decoration get searchResultIndication => const Decoration(color: '#EFEFEF');
  Decoration get selectionBackground => const Decoration(color: '#EEEEEE');
  Decoration get selectionForeground => const Decoration(color: '#000000');
  Decoration get singleLineComment => const Decoration(color: '#008000');
  Decoration get sourceHoverBackground => const Decoration(color: '#EEEEEE');
  Decoration get staticField => const Decoration(color: '#800040');
  Decoration get staticFinalField => const Decoration(color: '#800040');
  Decoration get staticMethod => const Decoration(color: '#C4C4B7');
  Decoration get string => const Decoration(color: '#808080');
  Decoration get typeArgument => const Decoration(color: '#885d3b');
  Decoration get typeParameter => const Decoration(color: '#885d3b');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#EFEFEF');
}

/// Oblivion theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/oblivion.xml.
/// Author: Roger Dudler.
class OblivionTheme extends Theme {
  const OblivionTheme();

  String get name => 'Oblivion';

  Decoration get abstractMethod => const Decoration(color: '#BED6FF');
  Decoration get annotation => const Decoration(color: '#FFFFFF');
  Decoration get background => const Decoration(color: '#1E1E1E');
  Decoration get bracket => const Decoration(color: '#D8D8D8');
  Decoration get className => const Decoration(color: '#D25252');
  Decoration get commentTaskTag => const Decoration(color: '#CCDF32');
  Decoration get constant => const Decoration(color: '#EFC090');
  Decoration get currentLine => const Decoration(color: '#2A2A2A');
  Decoration get deletionIndication => const Decoration(color: '#D25252');
  Decoration get deprecatedMember => const Decoration(color: '#D25252');
  Decoration get dynamicType => const Decoration(color: '#79ABFF');
  Decoration get enumName => const Decoration(color: '#7FB347');
  Decoration get field => const Decoration(color: '#BED6FF');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#000000');
  Decoration get findScope => const Decoration(color: '#111111');
  Decoration get foreground => const Decoration(color: '#D8D8D8');
  Decoration get inheritedMethod => const Decoration(color: '#BED6FF');
  Decoration get interface => const Decoration(color: '#D197D9');
  Decoration get javadoc => const Decoration(color: '#CCDF32');
  Decoration get javadocKeyword => const Decoration(color: '#D9E577');
  Decoration get javadocLink => const Decoration(color: '#D9E577');
  Decoration get javadocTag => const Decoration(color: '#D9E577');
  Decoration get keyword => const Decoration(color: '#FFFFFF');
  Decoration get lineNumber => const Decoration(color: '#D0D0D0');
  Decoration get localVariable => const Decoration(color: '#79ABFF');
  Decoration get localVariableDeclaration => const Decoration(color: '#BED6FF');
  Decoration get method => const Decoration(color: '#FFFFFF');
  Decoration get methodDeclaration => const Decoration(color: '#BED6FF');
  Decoration get multiLineComment => const Decoration(color: '#C7DD0C');
  Decoration get number => const Decoration(color: '#7FB347');
  Decoration get occurrenceIndication => const Decoration(color: '#000000');
  Decoration get operator => const Decoration(color: '#D8D8D8');
  Decoration get parameterVariable => const Decoration(color: '#79ABFF');
  Decoration get searchResultIndication => const Decoration(color: '#000000');
  Decoration get selectionBackground => const Decoration(color: '#404040');
  Decoration get selectionForeground => const Decoration(color: '#D0D0D0');
  Decoration get singleLineComment => const Decoration(color: '#C7DD0C');
  Decoration get sourceHoverBackground => const Decoration(color: '#000000');
  Decoration get staticField => const Decoration(color: '#EFC090');
  Decoration get staticFinalField => const Decoration(color: '#EFC090');
  Decoration get staticMethod => const Decoration(color: '#BED6FF');
  Decoration get string => const Decoration(color: '#FFC600');
  Decoration get typeArgument => const Decoration(color: '#BFA4A4');
  Decoration get typeParameter => const Decoration(color: '#BFA4A4');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#000000');
}

/// Obsidian theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/obsidian.xml.
/// Author: Morinar.
class ObsidianTheme extends Theme {
  const ObsidianTheme();

  String get name => 'Obsidian';

  Decoration get abstractMethod => const Decoration(color: '#E0E2E4');
  Decoration get annotation => const Decoration(color: '#A082BD');
  Decoration get background => const Decoration(color: '#293134');
  Decoration get bracket => const Decoration(color: '#E8E2B7');
  Decoration get className => const Decoration(color: '#678CB1');
  Decoration get commentTaskTag => const Decoration(color: '#FF8BFF');
  Decoration get constant => const Decoration(color: '#A082BD');
  Decoration get currentLine => const Decoration(color: '#2F393C');
  Decoration get deletionIndication => const Decoration(color: '#E0E2E4');
  Decoration get deprecatedMember => const Decoration(color: '#E0E2E4');
  Decoration get dynamicType => const Decoration(color: '#E0E2E4');
  Decoration get enumName => const Decoration(color: '#E0E2E4');
  Decoration get field => const Decoration(color: '#678CB1');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#616161');
  Decoration get findScope => const Decoration(color: '#E0E2E4');
  Decoration get foreground => const Decoration(color: '#E0E2E4');
  Decoration get inheritedMethod => const Decoration(color: '#E0E2E4');
  Decoration get interface => const Decoration(color: '#678CB1');
  Decoration get javadoc => const Decoration(color: '#7D8C93');
  Decoration get javadocKeyword => const Decoration(color: '#A082BD');
  Decoration get javadocLink => const Decoration(color: '#678CB1');
  Decoration get javadocTag => const Decoration(color: '#E0E2E4');
  Decoration get keyword => const Decoration(color: '#93C763');
  Decoration get lineNumber => const Decoration(color: '#81969A');
  Decoration get localVariable => const Decoration(color: '#E0E2E4');
  Decoration get localVariableDeclaration => const Decoration(color: '#E0E2E4');
  Decoration get method => const Decoration(color: '#678CB1');
  Decoration get methodDeclaration => const Decoration(color: '#E8E2B7');
  Decoration get multiLineComment => const Decoration(color: '#7D8C93');
  Decoration get number => const Decoration(color: '#FFCD22');
  Decoration get occurrenceIndication => const Decoration(color: '#616161');
  Decoration get operator => const Decoration(color: '#E8E2B7');
  Decoration get parameterVariable => const Decoration(color: '#E0E2E4');
  Decoration get searchResultIndication => const Decoration(color: '#616161');
  Decoration get selectionBackground => const Decoration(color: '#804000');
  Decoration get selectionForeground => const Decoration(color: '#E0E2E4');
  Decoration get singleLineComment => const Decoration(color: '#7D8C93');
  Decoration get sourceHoverBackground => const Decoration(color: '#FFFFFF');
  Decoration get staticField => const Decoration(color: '#678CB1');
  Decoration get staticFinalField => const Decoration(color: '#E0E2E4');
  Decoration get staticMethod => const Decoration(color: '#E0E2E4');
  Decoration get string => const Decoration(color: '#EC7600');
  Decoration get typeArgument => const Decoration(color: '#E0E2E4');
  Decoration get typeParameter => const Decoration(color: '#E0E2E4');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#616161');
}

/// Pastel theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/pastel.xml.
/// Author: Ian Kabeary.
class PastelTheme extends Theme {
  const PastelTheme();

  String get name => 'Pastel';

  Decoration get abstractMethod => const Decoration(color: '#E0E2E4');
  Decoration get annotation => const Decoration(color: '#A082BD');
  Decoration get background => const Decoration(color: '#1f2223');
  Decoration get bracket => const Decoration(color: '#95bed8');
  Decoration get className => const Decoration(color: '#678CB1');
  Decoration get commentTaskTag => const Decoration(color: '#a57b61');
  Decoration get constant => const Decoration(color: '#A082BD');
  Decoration get currentLine => const Decoration(color: '#2F393C');
  Decoration get deletionIndication => const Decoration(color: '#E0E2E4');
  Decoration get deprecatedMember => const Decoration(color: '#E0E2E4');
  Decoration get dynamicType => const Decoration(color: '#E0E2E4');
  Decoration get enumName => const Decoration(color: '#E0E2E4');
  Decoration get field => const Decoration(color: '#678CB1');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#616161');
  Decoration get findScope => const Decoration(color: '#E0E2E4');
  Decoration get foreground => const Decoration(color: '#E0E2E4');
  Decoration get inheritedMethod => const Decoration(color: '#E0E2E4');
  Decoration get interface => const Decoration(color: '#678CB1');
  Decoration get javadoc => const Decoration(color: '#7D8C93');
  Decoration get javadocKeyword => const Decoration(color: '#A082BD');
  Decoration get javadocLink => const Decoration(color: '#678CB1');
  Decoration get javadocTag => const Decoration(color: '#E0E2E4');
  Decoration get keyword => const Decoration(color: '#a57b61');
  Decoration get lineNumber => const Decoration(color: '#81969A');
  Decoration get localVariable => const Decoration(color: '#E0E2E4');
  Decoration get localVariableDeclaration => const Decoration(color: '#E0E2E4');
  Decoration get method => const Decoration(color: '#678CB1');
  Decoration get methodDeclaration => const Decoration(color: '#95bed8');
  Decoration get multiLineComment => const Decoration(color: '#7D8C93');
  Decoration get number => const Decoration(color: '#c78d9b');
  Decoration get occurrenceIndication => const Decoration(color: '#616161');
  Decoration get operator => const Decoration(color: '#E8E2B7');
  Decoration get parameterVariable => const Decoration(color: '#E0E2E4');
  Decoration get searchResultIndication => const Decoration(color: '#616161');
  Decoration get selectionBackground => const Decoration(color: '#95bed8');
  Decoration get selectionForeground => const Decoration(color: '#E0E2E4');
  Decoration get singleLineComment => const Decoration(color: '#7D8C93');
  Decoration get sourceHoverBackground => const Decoration(color: '#FFFFFF');
  Decoration get staticField => const Decoration(color: '#678CB1');
  Decoration get staticFinalField => const Decoration(color: '#E0E2E4');
  Decoration get staticMethod => const Decoration(color: '#E0E2E4');
  Decoration get string => const Decoration(color: '#c78d9b');
  Decoration get typeArgument => const Decoration(color: '#E0E2E4');
  Decoration get typeParameter => const Decoration(color: '#E0E2E4');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#616161');
}

/// RecognEyes theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/recogneyes.xml.
/// Author: Dan.
class RecognEyesTheme extends Theme {
  const RecognEyesTheme();

  String get name => 'RecognEyes';

  Decoration get abstractMethod => const Decoration(color: '#BED6FF');
  Decoration get annotation => const Decoration(color: '#FFFFFF');
  Decoration get background => const Decoration(color: '#101020');
  Decoration get bracket => const Decoration(color: '#D0D0D0');
  Decoration get className => const Decoration(color: '#FF8080');
  Decoration get commentTaskTag => const Decoration(color: '#00FF00');
  Decoration get constant => const Decoration(color: '#FFFF00');
  Decoration get currentLine => const Decoration(color: '#202030');
  Decoration get deletionIndication => const Decoration(color: '#FFFFFF');
  Decoration get deprecatedMember => const Decoration(color: '#FFFFFF');
  Decoration get dynamicType => const Decoration(color: '#79ABFF');
  Decoration get enumName => const Decoration(color: '#FFFFFF');
  Decoration get field => const Decoration(color: '#BED6FF');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#606080');
  Decoration get findScope => const Decoration(color: '#FFFFFF');
  Decoration get foreground => const Decoration(color: '#D0D0D0');
  Decoration get inheritedMethod => const Decoration(color: '#BED6FF');
  Decoration get interface => const Decoration(color: '#D197D9');
  Decoration get javadoc => const Decoration(color: '#CCDF32');
  Decoration get javadocKeyword => const Decoration(color: '#D9E577');
  Decoration get javadocLink => const Decoration(color: '#D9E577');
  Decoration get javadocTag => const Decoration(color: '#D9E577');
  Decoration get keyword => const Decoration(color: '#00D0D0');
  Decoration get lineNumber => const Decoration(color: '#2B91AF');
  Decoration get localVariable => const Decoration(color: '#79ABFF');
  Decoration get localVariableDeclaration => const Decoration(color: '#BED6FF');
  Decoration get method => const Decoration(color: '#D0D0D0');
  Decoration get methodDeclaration => const Decoration(color: '#BED6FF');
  Decoration get multiLineComment => const Decoration(color: '#00E000');
  Decoration get number => const Decoration(color: '#FFFF00');
  Decoration get occurrenceIndication => const Decoration(color: '#000000');
  Decoration get operator => const Decoration(color: '#D0D0D0');
  Decoration get parameterVariable => const Decoration(color: '#79ABFF');
  Decoration get searchResultIndication => const Decoration(color: '#006080');
  Decoration get selectionBackground => const Decoration(color: '#0000FF');
  Decoration get selectionForeground => const Decoration(color: '#FFFFFF');
  Decoration get singleLineComment => const Decoration(color: '#00E000');
  Decoration get sourceHoverBackground => const Decoration(color: '#FFFFFF');
  Decoration get staticField => const Decoration(color: '#EFC090');
  Decoration get staticFinalField => const Decoration(color: '#EFC090');
  Decoration get staticMethod => const Decoration(color: '#BED6FF');
  Decoration get string => const Decoration(color: '#DC78DC');
  Decoration get typeArgument => const Decoration(color: '#BFA4A4');
  Decoration get typeParameter => const Decoration(color: '#BFA4A4');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#000000');
}

/// Retta theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/retta.xml.
/// Author: Eric.
class RettaTheme extends Theme {
  const RettaTheme();

  String get name => 'Retta';

  Decoration get abstractMethod => const Decoration(color: '#A4B0C0');
  Decoration get annotation => const Decoration(color: '#FFFFFF');
  Decoration get background => const Decoration(color: '#000000');
  Decoration get bracket => const Decoration(color: '#F8E1AA');
  Decoration get className => const Decoration(color: '#DE6546', bold: true);
  Decoration get commentTaskTag => const Decoration(color: '#83786E');
  Decoration get constant => const Decoration(color: '#EFC090');
  Decoration get currentLine => const Decoration(color: '#2A2A2A');
  Decoration get deletionIndication => const Decoration(color: '#DE6546');
  Decoration get deprecatedMember => const Decoration(color: '#DE6546');
  Decoration get dynamicType => const Decoration(color: '#F8E1AA');
  Decoration get enumName => const Decoration(color: '#527D5D', bold: true);
  Decoration get field => const Decoration(color: '#DE6546');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#395EB1');
  Decoration get findScope => const Decoration(color: '#FFFF00');
  Decoration get foreground => const Decoration(color: '#F8E1AA');
  Decoration get inheritedMethod => const Decoration(color: '#A4B0C0');
  Decoration get interface => const Decoration(color: '#527D5D', bold: true);
  Decoration get javadoc => const Decoration(color: '#83786E');
  Decoration get javadocKeyword => const Decoration(color: '#83786E');
  Decoration get javadocLink => const Decoration(color: '#83786E');
  Decoration get javadocTag => const Decoration(color: '#A19387');
  Decoration get keyword => const Decoration(color: '#E79E3C', bold: true);
  Decoration get lineNumber => const Decoration(color: '#C97138');
  Decoration get localVariable => const Decoration(color: '#F8E1AA');
  Decoration get localVariableDeclaration => const Decoration(color: '#F8E1AA');
  Decoration get method => const Decoration(color: '#A4B0C0');
  Decoration get methodDeclaration => const Decoration(color: '#A4B0C0');
  Decoration get multiLineComment => const Decoration(color: '#83786E');
  Decoration get number => const Decoration(color: '#D6C248');
  Decoration get occurrenceIndication => const Decoration(color: '#5E5C56');
  Decoration get operator => const Decoration(color: '#D6C248');
  Decoration get parameterVariable => const Decoration(color: '#A4B0C0');
  Decoration get searchResultIndication => const Decoration(color: '#395EB1');
  Decoration get selectionBackground => const Decoration(color: '#527D5D');
  Decoration get selectionForeground => const Decoration(color: '#F8E1AA');
  Decoration get singleLineComment => const Decoration(color: '#83786E');
  Decoration get sourceHoverBackground => const Decoration(color: '#FF00FF');
  Decoration get staticField => const Decoration(color: '#F8E1A3');
  Decoration get staticFinalField => const Decoration(color: '#F8E1A3');
  Decoration get staticMethod => const Decoration(color: '#A4B0C0');
  Decoration get string => const Decoration(color: '#D6C248');
  Decoration get typeArgument => const Decoration(color: '#BFA4A4');
  Decoration get typeParameter => const Decoration(color: '#BFA4A4');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#527D5D');
}

/// Roboticket theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/roboticket.xml.
/// Author: Robopuff.
class RoboticketTheme extends Theme {
  const RoboticketTheme();

  String get name => 'Roboticket';

  Decoration get abstractMethod => const Decoration(color: '#2C577C');
  Decoration get annotation => const Decoration(color: '#808080');
  Decoration get background => const Decoration(color: '#F5F5F5');
  Decoration get bracket => const Decoration(color: '#B05A65');
  Decoration get className => const Decoration(color: '#AB2525');
  Decoration get commentTaskTag => const Decoration(color: '#295F94');
  Decoration get constant => const Decoration(color: '#0A0B0C');
  Decoration get currentLine => const Decoration(color: '#E0E0FF');
  Decoration get deletionIndication => const Decoration(color: '#9B5656');
  Decoration get deprecatedMember => const Decoration(color: '#AB2525');
  Decoration get enumName => const Decoration(color: '#885D3B');
  Decoration get field => const Decoration(color: '#566874');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#FFDF99');
  Decoration get findScope => const Decoration(color: '#BDD8F2');
  Decoration get foreground => const Decoration(color: '#585858');
  Decoration get inheritedMethod => const Decoration(color: '#2C577C');
  Decoration get interface => const Decoration(color: '#9B5656');
  Decoration get javadoc => const Decoration(color: '#AD95AF');
  Decoration get javadocKeyword => const Decoration(color: '#CC9393');
  Decoration get javadocLink => const Decoration(color: '#AD95AF');
  Decoration get javadocTag => const Decoration(color: '#566874');
  Decoration get keyword => const Decoration(color: '#295F94');
  Decoration get lineNumber => const Decoration(color: '#AFBFCF');
  Decoration get localVariable => const Decoration(color: '#55aa55');
  Decoration get localVariableDeclaration => const Decoration(color: '#B05A65');
  Decoration get method => const Decoration(color: '#BC5A65', bold: true);
  Decoration get methodDeclaration => const Decoration(color: '#B05A65');
  Decoration get multiLineComment => const Decoration(color: '#AD95AF');
  Decoration get number => const Decoration(color: '#AF0F91');
  Decoration get occurrenceIndication => const Decoration(color: '#FFCFBB');
  Decoration get operator => const Decoration(color: '#000000');
  Decoration get parameterVariable => const Decoration(color: '#55aa55');
  Decoration get searchResultIndication => const Decoration(color: '#FFDF99');
  Decoration get selectionBackground => const Decoration(color: '#BDD8F2');
  Decoration get selectionForeground => const Decoration(color: '#484848');
  Decoration get singleLineComment => const Decoration(color: '#AD95AF');
  Decoration get sourceHoverBackground => const Decoration(color: '#EEEEEE');
  Decoration get staticField => const Decoration(color: '#885D3B');
  Decoration get staticFinalField => const Decoration(color: '#885D3B');
  Decoration get staticMethod => const Decoration(color: '#C4C4B7');
  Decoration get string => const Decoration(color: '#317ECC');
  Decoration get typeArgument => const Decoration(color: '#885D3B');
  Decoration get typeParameter => const Decoration(color: '#885D3B');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#FFCFBB');
}

/// Schuss theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/schuss.xml.
/// Author: Vasil Stoychev.
class SchussTheme extends Theme {
  const SchussTheme();

  String get name => 'Schuss';

  Decoration get abstractMethod => const Decoration(color: '#2c577c');
  Decoration get annotation => const Decoration(color: '#808080');
  Decoration get background => const Decoration(color: '#FFFFFF');
  Decoration get bracket => const Decoration(color: '#000f6a');
  Decoration get className => const Decoration(color: '#ca3349');
  Decoration get commentTaskTag => const Decoration(color: '#d7d3cc');
  Decoration get constant => const Decoration(color: '#ae25ab');
  Decoration get currentLine => const Decoration(color: '#fff7cd');
  Decoration get deletionIndication => const Decoration(color: '#9b5656');
  Decoration get deprecatedMember => const Decoration(color: '#ab2525');
  Decoration get enumName => const Decoration(color: '#135a20');
  Decoration get field => const Decoration(color: '#566874');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#CC6633');
  Decoration get findScope => const Decoration(color: '#BCADAD');
  Decoration get foreground => const Decoration(color: '#430400');
  Decoration get inheritedMethod => const Decoration(color: '#2c577c');
  Decoration get interface => const Decoration(color: '#ca3349');
  Decoration get javadoc => const Decoration(color: '#05314d');
  Decoration get javadocKeyword => const Decoration(color: '#CC9393');
  Decoration get javadocLink => const Decoration(color: '#05314d');
  Decoration get javadocTag => const Decoration(color: '#05314d');
  Decoration get keyword => const Decoration(color: '#606060');
  Decoration get lineNumber => const Decoration(color: '#999999');
  Decoration get localVariable => const Decoration(color: '#2b6488');
  Decoration get localVariableDeclaration => const Decoration(color: '#ca3349');
  Decoration get method => const Decoration(color: '#797a8a');
  Decoration get methodDeclaration => const Decoration(color: '#4f6d8f');
  Decoration get multiLineComment => const Decoration(color: '#d5d9e5');
  Decoration get number => const Decoration(color: '#d0321f');
  Decoration get occurrenceIndication => const Decoration(color: '#CC6633');
  Decoration get operator => const Decoration(color: '#5f97a9');
  Decoration get parameterVariable => const Decoration(color: '#5c8198');
  Decoration get searchResultIndication => const Decoration(color: '#CC6633');
  Decoration get selectionBackground => const Decoration(color: '#f4fdff');
  Decoration get selectionForeground => const Decoration(color: '#FFFFFF');
  Decoration get singleLineComment => const Decoration(color: '#d7d3cc');
  Decoration get sourceHoverBackground => const Decoration(color: '#EEEEEE');
  Decoration get staticField => const Decoration(color: '#464646');
  Decoration get staticFinalField => const Decoration(color: '#464646');
  Decoration get staticMethod => const Decoration(color: '#797a8a');
  Decoration get string => const Decoration(color: '#585545');
  Decoration get typeArgument => const Decoration(color: '#d07fcd');
  Decoration get typeParameter => const Decoration(color: '#d07fcd');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#CC6633');
}

/// Sublime Text 2 theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/sublime-text-2.xml.
/// Author: Filip Minev.
class Sublime_Text_2Theme extends Theme {
  const Sublime_Text_2Theme();

  String get name => 'Sublime Text 2';

  Decoration get abstractMethod => const Decoration(color: '#BED6FF');
  Decoration get annotation => const Decoration(color: '#FFFFFF');
  Decoration get background => const Decoration(color: '#272822');
  Decoration get bracket => const Decoration(color: '#F9FAF4');
  Decoration get className => const Decoration(color: '#52E3F6');
  Decoration get commentTaskTag => const Decoration(color: '#FFFFFF');
  Decoration get currentLine => const Decoration(color: '#5B5A4E');
  Decoration get deletionIndication => const Decoration(color: '#FF0000');
  Decoration get deprecatedMember => const Decoration(color: '#FF0000');
  Decoration get dynamicType => const Decoration(color: '#CFBFAD');
  Decoration get field => const Decoration(color: '#CFBFAD');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#D8D8D8');
  Decoration get findScope => const Decoration(color: '#000000');
  Decoration get foreground => const Decoration(color: '#CFBFAD');
  Decoration get inheritedMethod => const Decoration(color: '#BED6FF');
  Decoration get interface => const Decoration(color: '#52E3F6');
  Decoration get javadoc => const Decoration(color: '#FFFFFF');
  Decoration get javadocKeyword => const Decoration(color: '#D9E577');
  Decoration get javadocLink => const Decoration(color: '#CFBFAD');
  Decoration get javadocTag => const Decoration(color: '#CFBFAD');
  Decoration get keyword => const Decoration(color: '#FF007F');
  Decoration get lineNumber => const Decoration(color: '#999999');
  Decoration get localVariable => const Decoration(color: '#CFBFAD');
  Decoration get localVariableDeclaration => const Decoration(color: '#CFBFAD');
  Decoration get method => const Decoration(color: '#A7EC21');
  Decoration get methodDeclaration => const Decoration(color: '#A7EC21');
  Decoration get multiLineComment => const Decoration(color: '#FFFFFF');
  Decoration get number => const Decoration(color: '#C48CFF');
  Decoration get occurrenceIndication => const Decoration(color: '#000000');
  Decoration get operator => const Decoration(color: '#FF007F');
  Decoration get parameterVariable => const Decoration(color: '#79ABFF');
  Decoration get searchResultIndication => const Decoration(color: '#D8D8D8');
  Decoration get selectionBackground => const Decoration(color: '#CC9900');
  Decoration get selectionForeground => const Decoration(color: '#404040');
  Decoration get singleLineComment => const Decoration(color: '#FFFFFF');
  Decoration get sourceHoverBackground => const Decoration(color: '#FFFFFF');
  Decoration get staticField => const Decoration(color: '#CFBFAD');
  Decoration get staticFinalField => const Decoration(color: '#CFBFAD');
  Decoration get staticMethod => const Decoration(color: '#A7EC21');
  Decoration get string => const Decoration(color: '#ECE47E');
  Decoration get typeArgument => const Decoration(color: '#BFA4A4');
  Decoration get typeParameter => const Decoration(color: '#BFA4A4');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#000000');
}

/// Sunburst theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/sunburst.xml.
/// Author: Viorel Craescu.
class SunburstTheme extends Theme {
  const SunburstTheme();

  String get name => 'Sunburst';

  Decoration get abstractMethod => const Decoration(color: '#F9F9F9');
  Decoration get annotation => const Decoration(color: '#A020F0');
  Decoration get background => const Decoration(color: '#000000');
  Decoration get bracket => const Decoration(color: '#F9F9F9');
  Decoration get className => const Decoration(color: '#F9F9F9');
  Decoration get commentTaskTag => const Decoration(color: '#A8A8A8');
  Decoration get constant => const Decoration(color: '#3D9AD6');
  Decoration get currentLine => const Decoration(color: '#2F2F2F');
  Decoration get deletionIndication => const Decoration(color: '#D25252');
  Decoration get deprecatedMember => const Decoration(color: '#F9F9F9');
  Decoration get dynamicType => const Decoration(color: '#4B9CE9');
  Decoration get enumName => const Decoration(color: '#7FB347');
  Decoration get field => const Decoration(color: '#4B9CE9');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#5A5A5A');
  Decoration get findScope => const Decoration(color: '#DDF0FF');
  Decoration get foreground => const Decoration(color: '#F9F9F9');
  Decoration get inheritedMethod => const Decoration(color: '#F9F9F9');
  Decoration get interface => const Decoration(color: '#F9F9F9');
  Decoration get javadoc => const Decoration(color: '#A8A8A8');
  Decoration get javadocKeyword => const Decoration(color: '#EA9C77');
  Decoration get javadocLink => const Decoration(color: '#548FA0');
  Decoration get javadocTag => const Decoration(color: '#A8A8A8');
  Decoration get keyword => const Decoration(color: '#EA9C77');
  Decoration get lineNumber => const Decoration(color: '#F9F9F9');
  Decoration get localVariable => const Decoration(color: '#4B9CE9');
  Decoration get localVariableDeclaration => const Decoration(color: '#4B9CE9');
  Decoration get method => const Decoration(color: '#F9F9F9');
  Decoration get methodDeclaration => const Decoration(color: '#F9F9F9');
  Decoration get multiLineComment => const Decoration(color: '#A8A8A8');
  Decoration get number => const Decoration(color: '#F9F9F9');
  Decoration get occurrenceIndication => const Decoration(color: '#5A5A5A');
  Decoration get operator => const Decoration(color: '#F9F9F9');
  Decoration get parameterVariable => const Decoration(color: '#4B9CE9');
  Decoration get searchResultIndication => const Decoration(color: '#5A5A5A');
  Decoration get selectionBackground => const Decoration(color: '#DDF0FF');
  Decoration get selectionForeground => const Decoration(color: '#000000');
  Decoration get singleLineComment => const Decoration(color: '#A8A8A8');
  Decoration get sourceHoverBackground => const Decoration(color: '#000000');
  Decoration get staticField => const Decoration(color: '#4B9CE9');
  Decoration get staticFinalField => const Decoration(color: '#4B9CE9');
  Decoration get staticMethod => const Decoration(color: '#F9F9F9');
  Decoration get string => const Decoration(color: '#76BA53');
  Decoration get typeArgument => const Decoration(color: '#4B9CE9');
  Decoration get typeParameter => const Decoration(color: '#4B9CE9');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#5A5A5A');
}

/// Tango theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/tango.xml.
/// Author: Roger Dudler.
class TangoTheme extends Theme {
  const TangoTheme();

  String get name => 'Tango';

  Decoration get abstractMethod => const Decoration(color: '#2c577c');
  Decoration get annotation => const Decoration(color: '#808080');
  Decoration get background => const Decoration(color: '#FFFFFF');
  Decoration get bracket => const Decoration(color: '#444444');
  Decoration get className => const Decoration(color: '#37550d');
  Decoration get commentTaskTag => const Decoration(color: '#17608f');
  Decoration get currentLine => const Decoration(color: '#EEEEEE');
  Decoration get deletionIndication => const Decoration(color: '#9b5656');
  Decoration get deprecatedMember => const Decoration(color: '#ab2525');
  Decoration get dynamicType => const Decoration(color: '#5c8198');
  Decoration get enumName => const Decoration(color: '#885d3b');
  Decoration get field => const Decoration(color: '#566874');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#EFEFEF');
  Decoration get findScope => const Decoration(color: '#BCADAD');
  Decoration get foreground => const Decoration(color: '#000000');
  Decoration get inheritedMethod => const Decoration(color: '#2c577c');
  Decoration get interface => const Decoration(color: '#9b5656');
  Decoration get javadoc => const Decoration(color: '#05314d');
  Decoration get javadocKeyword => const Decoration(color: '#CC9393');
  Decoration get javadocLink => const Decoration(color: '#05314d');
  Decoration get javadocTag => const Decoration(color: '#05314d');
  Decoration get keyword => const Decoration(color: '#688046');
  Decoration get lineNumber => const Decoration(color: '#999999');
  Decoration get localVariable => const Decoration(color: '#5c8198');
  Decoration get localVariableDeclaration => const Decoration(color: '#5c8198');
  Decoration get method => const Decoration(color: '#444444');
  Decoration get methodDeclaration => const Decoration(color: '#222222');
  Decoration get multiLineComment => const Decoration(color: '#17608f');
  Decoration get number => const Decoration(color: '#801f91');
  Decoration get occurrenceIndication => const Decoration(color: '#EFEFEF');
  Decoration get operator => const Decoration(color: '#000000');
  Decoration get parameterVariable => const Decoration(color: '#5c8198');
  Decoration get searchResultIndication => const Decoration(color: '#EFEFEF');
  Decoration get selectionBackground => const Decoration(color: '#EEEEEE');
  Decoration get selectionForeground => const Decoration(color: '#000000');
  Decoration get singleLineComment => const Decoration(color: '#17608f');
  Decoration get sourceHoverBackground => const Decoration(color: '#EEEEEE');
  Decoration get staticField => const Decoration(color: '#885d3b');
  Decoration get staticFinalField => const Decoration(color: '#885d3b');
  Decoration get staticMethod => const Decoration(color: '#C4C4B7');
  Decoration get string => const Decoration(color: '#92679a');
  Decoration get typeArgument => const Decoration(color: '#885d3b');
  Decoration get typeParameter => const Decoration(color: '#885d3b');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#EFEFEF');
}

/// Vibrant Ink theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/vibrantink.xml.
/// Author: indiehead.
class Vibrant_InkTheme extends Theme {
  const Vibrant_InkTheme();

  String get name => 'Vibrant Ink';

  Decoration get abstractMethod => const Decoration(color: '#F1C436');
  Decoration get background => const Decoration(color: '#191919');
  Decoration get bracket => const Decoration(color: '#FFFFFF');
  Decoration get className => const Decoration(color: '#9CF828');
  Decoration get commentTaskTag => const Decoration(color: '#800080');
  Decoration get currentLine => const Decoration(color: '#222220');
  Decoration get deletionIndication => const Decoration(color: '#FF0000');
  Decoration get deprecatedMember => const Decoration(color: '#FFFFFF');
  Decoration get dynamicType => const Decoration(color: '#3C758D');
  Decoration get enumName => const Decoration(color: '#408000');
  Decoration get field => const Decoration(color: '#357A8F');
  Decoration get findScope => const Decoration(color: '#191919');
  Decoration get foreground => const Decoration(color: '#FFFFFF');
  Decoration get inheritedMethod => const Decoration(color: '#E3B735');
  Decoration get interface => const Decoration(color: '#87F025');
  Decoration get javadoc => const Decoration(color: '#8C3FC8');
  Decoration get javadocKeyword => const Decoration(color: '#800080');
  Decoration get javadocLink => const Decoration(color: '#814582');
  Decoration get javadocTag => const Decoration(color: '#800080');
  Decoration get keyword => const Decoration(color: '#EC691E');
  Decoration get lineNumber => const Decoration(color: '#666666');
  Decoration get localVariable => const Decoration(color: '#3C758D');
  Decoration get localVariableDeclaration => const Decoration(color: '#357A92');
  Decoration get method => const Decoration(color: '#F7C527');
  Decoration get methodDeclaration => const Decoration(color: '#F1C438');
  Decoration get multiLineComment => const Decoration(color: '#8C3FC8');
  Decoration get number => const Decoration(color: '#477488');
  Decoration get occurrenceIndication => const Decoration(color: '#616161');
  Decoration get operator => const Decoration(color: '#FFFFFF');
  Decoration get parameterVariable => const Decoration(color: '#408000');
  Decoration get selectionBackground => const Decoration(color: '#414C3B');
  Decoration get selectionForeground => const Decoration(color: '#FFFFFF');
  Decoration get singleLineComment => const Decoration(color: '#8146A2');
  Decoration get staticField => const Decoration(color: '#FFFFFF');
  Decoration get staticFinalField => const Decoration(color: '#80FF00');
  Decoration get staticMethod => const Decoration(color: '#FFFFFF');
  Decoration get string => const Decoration(color: '#477488');
  Decoration get typeArgument => const Decoration(color: '#D9B0AC');
  Decoration get typeParameter => const Decoration(color: '#CDB1AD');
}

/// Wombat theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/wombat.xml.
/// Author: Lars H. Nielsen.
class WombatTheme extends Theme {
  const WombatTheme();

  String get name => 'Wombat';

  Decoration get annotation => const Decoration(color: '#808080');
  Decoration get background => const Decoration(color: '#242424');
  Decoration get bracket => const Decoration(color: '#f3f6ee');
  Decoration get className => const Decoration(color: '#cae682');
  Decoration get commentTaskTag => const Decoration(color: '#ACC1AC');
  Decoration get currentLine => const Decoration(color: '#656565');
  Decoration get deprecatedMember => const Decoration(color: '#FFFFFF');
  Decoration get dynamicType => const Decoration(color: '#D4C4A9');
  Decoration get field => const Decoration(color: '#cae682');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#3f3f6a');
  Decoration get findScope => const Decoration(color: '#BCADAD');
  Decoration get foreground => const Decoration(color: '#f6f3e8');
  Decoration get interface => const Decoration(color: '#CAE682');
  Decoration get javadoc => const Decoration(color: '#b3b5af');
  Decoration get javadocKeyword => const Decoration(color: '#f08080');
  Decoration get javadocLink => const Decoration(color: '#a7a7d1');
  Decoration get javadocTag => const Decoration(color: '#a7a7d1');
  Decoration get keyword => const Decoration(color: '#8ac6f2');
  Decoration get lineNumber => const Decoration(color: '#656565');
  Decoration get localVariable => const Decoration(color: '#D4C4A9');
  Decoration get localVariableDeclaration => const Decoration(color: '#D4C4A9');
  Decoration get method => const Decoration(color: '#f3f6ee');
  Decoration get methodDeclaration => const Decoration(color: '#f3f6ee');
  Decoration get multiLineComment => const Decoration(color: '#99968b');
  Decoration get number => const Decoration(color: '#f08080');
  Decoration get occurrenceIndication => const Decoration(color: '#616161');
  Decoration get operator => const Decoration(color: '#f3f6ee');
  Decoration get searchResultIndication => const Decoration(color: '#464467');
  Decoration get selectionBackground => const Decoration(color: '#898941');
  Decoration get selectionForeground => const Decoration(color: '#000000');
  Decoration get singleLineComment => const Decoration(color: '#99968b');
  Decoration get sourceHoverBackground => const Decoration(color: '#a19879');
  Decoration get staticField => const Decoration(color: '#93A2CC');
  Decoration get staticFinalField => const Decoration(color: '#53dccd');
  Decoration get staticMethod => const Decoration(color: '#C4C4B7');
  Decoration get string => const Decoration(color: '#95e454');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#948567');
}

/// Zenburn theme extracted from
/// ../editor/tools/plugins/com.google.dart.tools.deploy/themes/zenburn.xml.
/// Author: Janni Nurminen.
class ZenburnTheme extends Theme {
  const ZenburnTheme();

  String get name => 'Zenburn';

  Decoration get annotation => const Decoration(color: '#808080');
  Decoration get background => const Decoration(color: '#404040');
  Decoration get bracket => const Decoration(color: '#FFFFFF');
  Decoration get className => const Decoration(color: '#CAE682');
  Decoration get commentTaskTag => const Decoration(color: '#ACC1AC');
  Decoration get currentLine => const Decoration(color: '#505050');
  Decoration get deprecatedMember => const Decoration(color: '#FFFFFF');
  Decoration get dynamicType => const Decoration(color: '#D4C4A9');
  Decoration get field => const Decoration(color: '#B3B784');
  Decoration get filteredSearchResultIndication => const Decoration(color: '#3F3F6A');
  Decoration get findScope => const Decoration(color: '#BCADAD');
  Decoration get foreground => const Decoration(color: '#F6F3E8');
  Decoration get interface => const Decoration(color: '#CAE682');
  Decoration get javadoc => const Decoration(color: '#B3B5AF');
  Decoration get javadocKeyword => const Decoration(color: '#CC9393');
  Decoration get javadocLink => const Decoration(color: '#A893CC');
  Decoration get javadocTag => const Decoration(color: '#9393CC');
  Decoration get keyword => const Decoration(color: '#EFEFAF');
  Decoration get lineNumber => const Decoration(color: '#C0C0C0');
  Decoration get localVariable => const Decoration(color: '#D4C4A9');
  Decoration get localVariableDeclaration => const Decoration(color: '#D4C4A9');
  Decoration get method => const Decoration(color: '#DFBE95');
  Decoration get methodDeclaration => const Decoration(color: '#DFBE95');
  Decoration get multiLineComment => const Decoration(color: '#7F9F7F');
  Decoration get number => const Decoration(color: '#8ACCCF');
  Decoration get occurrenceIndication => const Decoration(color: '#616161');
  Decoration get operator => const Decoration(color: '#F0EFD0');
  Decoration get searchResultIndication => const Decoration(color: '#464467');
  Decoration get selectionBackground => const Decoration(color: '#898941');
  Decoration get selectionForeground => const Decoration(color: '#000000');
  Decoration get singleLineComment => const Decoration(color: '#7F9F7F');
  Decoration get sourceHoverBackground => const Decoration(color: '#A19879');
  Decoration get staticField => const Decoration(color: '#93A2CC');
  Decoration get staticFinalField => const Decoration(color: '#53DCCD');
  Decoration get staticMethod => const Decoration(color: '#C4C4B7');
  Decoration get string => const Decoration(color: '#CC9393');
  Decoration get writeOccurrenceIndication => const Decoration(color: '#948567');
}

/// List of known themes. The default is the first theme.
const List<Theme> THEMES = const <Theme> [
    const Theme(),
    const Black_PastelTheme(),
    const DartboardTheme(),
    const DebuggingTheme(),
    const Dart_EditorTheme(),
    const frontenddevTheme(),
    const Gedit_Original_OblivionTheme(),
    const HavenjarkTheme(),
    const Hot_PinkTheme(),
    const InkpotTheme(),
    const minimalTheme(),
    const MonokaiTheme(),
    const MrTheme(),
    const NightLion_Aptana_ThemeTheme(),
    const Notepad___LikeTheme(),
    const OblivionTheme(),
    const ObsidianTheme(),
    const PastelTheme(),
    const RecognEyesTheme(),
    const RettaTheme(),
    const RoboticketTheme(),
    const SchussTheme(),
    const Sublime_Text_2Theme(),
    const SunburstTheme(),
    const TangoTheme(),
    const Vibrant_InkTheme(),
    const WombatTheme(),
    const ZenburnTheme(),
];
