// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Timeout.none
library;

import 'package:test/test.dart' show Timeout;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'data_driven_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplacedByTypeTest);
  });
}

const String fixFileHeader = '''
version: 1
transforms:
''';

@reflectiveTest
class ReplacedByTypeTest extends DataDrivenBulkFixProcessorTest {
  /// Data shared by all tests, computed once.
  static (
    String lib1,
    String lib2,
    String fixData,
    String fixTemplate,
    Map<String, String> newNameOf,
  )?
  sharedData;

  static final _templateEntryRE = RegExp(r'%(\w+)%');

  Future<void> test_no_prefix_no_import() async {
    await _assertTemplatedFixes('', null);
  }

  Future<void> test_no_prefix_no_prefix() async {
    await _assertTemplatedFixes('', '');
  }

  Future<void> test_no_prefix_prefix() async {
    await _assertTemplatedFixes('', 'q');
  }

  Future<void> test_prefix_no_import() async {
    await _assertTemplatedFixes('p', null);
  }

  Future<void> test_prefix_no_prefix() async {
    await _assertTemplatedFixes('p', '');
  }

  Future<void> test_prefix_other_prefix() async {
    await _assertTemplatedFixes('p', 'q');
  }

  Future<void> test_prefix_same_prefix() async {
    await _assertTemplatedFixes('p', 'p');
  }

  void writeFix(
    StringBuffer buffer,
    TypeKind oldKind,
    TypeKind newKind,
    String oldName,
    String newName,
    bool otherLibrary,
  ) {
    if (buffer.isEmpty) buffer.write(fixFileHeader);
    var lib1Uri = importUri;
    const lib2Uri = 'package:p/lib2.dart';
    buffer.write('''
  - title: 'Replace with different type - ${oldKind.name}-${newKind.name} - $newName'
    date: 2022-09-28
    element:
      uris: ['$lib1Uri']
      ${oldKind.name}: '$oldName'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['${otherLibrary ? lib2Uri : lib1Uri}']
          ${newKind.name}: '$newName'
''');
  }

  void writeTemplatesFor(
    StringBuffer buffer,
    TypeKind oldKind,
    TypeKind newKind,
    String oldName,
    bool generic,
    bool removed,
  ) {
    /// There is a number of cases where a removed type is not recognized
    /// by the fix. Only correct for unprefixed names.
    const typeParams = '<T>';
    const typeArguments = '<int>';
    for (var nullable in [false, true]) {
      var isNull = nullable('Nullable');
      var q = nullable('?');
      var type = '%$oldName%${generic(typeArguments)}$q';
      buffer.write('''
// Global variable type${nullable(', nullable')}.
$type value$oldName$isNull = 0 as dynamic;

// Parameter type${nullable(', nullable')}.
void func$oldName$isNull($type input) {
  // Local variable type${nullable(', nullable')}.
  $type value = input as dynamic;
  print(value);
}

/// Type argument${nullable(', nullable')}.
List<$type> list$oldName$isNull = [];

/// Type bound${nullable(', nullable')}.
class GenericClass$oldName$isNull<T extends $type> {}

/// Cast${nullable(', nullable')}.
Object? exprCast$oldName$isNull = 0 as $type;

${removed ? '' : '''
/// Type check${nullable(', nullable')}.
bool exprCheck$oldName$isNull = 0 is $type;
'''}
bool casePatternCast$oldName$isNull(Object o) {
  switch (o) {
    // Case cast${nullable(', nullable')}.
    case _ as $type: return false;
  }
}
bool casePatternVar$oldName$isNull(Object? o) {
  switch (o) {
    // Case variable pattern${nullable(', nullable')}.
    case $type _: return false;
    case _: return true;
  }
}

void declPatterCast$oldName$isNull(Object? o) {
  // Declaration pattern cast${nullable(', nullable')}.
  var (value as $type,) = o as dynamic;
  print(value);
}

void declPatternVar$oldName$isNull(Object? o) {
  // Declaration pattern type annotation${nullable(', nullable')}.
  var ($type value,) = 0 as dynamic;
  print(value);
}
${(oldKind.canBeExtensionOnType && newKind.canBeExtensionOnType)('''
// Extension on-type${nullable(', nullable')}.
extension Ext$oldName$isNull${generic(typeParams)} on $type {}
''')}
// Extension type representation type${nullable(', nullable')}.
extension type ExtType$oldName$isNull($type _) {}

''');
    }
    // Uses where the reference cannot be explicitly nullable (not used as type,
    // or must be non-nullable.)

    var type = '%$oldName%${generic(typeArguments)}';
    buffer.write('''
${removed ? '' : '''
void tryOn$oldName(Object o) {
  try {
    throw o;
  } on $type {}
}
'''}
// As type literal.
Type typeLiteral$oldName = $type;
// As const type literal.
const Type constTypeLiteral$oldName = $type;

bool caseConst$oldName(Object o) {
  switch (o) {
    case const ($type): return false;
    case _: return true;
  }
}

bool caseObjectPattern$oldName(Object o) {
  // Object pattern check.
  switch (o) {
    case $type(): return false;
    case _: return true;
  }
}

void declObjectPattern$oldName(Object? o) {
  var ($type(runtimeType: value),) = 0 as dynamic;
  print(value);
}
${(oldKind.canBeClassSuper && newKind.canBeClassSuper)('''
class ClassExtends$oldName extends $type {}
''')}
${(oldKind.canBeClassMixin && newKind.canBeClassMixin)('''
class ClassWith$oldName with $type {}
enum EnumWith$oldName with $type { e }
''')}
${(oldKind.canBeClassInterface && newKind.canBeClassInterface)('''
abstract class ClassImplements$oldName implements $type {}
enum EnumImplements$oldName implements $type { e }
mixin MixinImplements$oldName implements $type {}
''')}
${(oldKind.canBeExtensionTypeInterface && newKind.canBeExtensionTypeInterface && !removed)('''
extension type ExtensionTypeImplements$oldName($type _) implements $type {}
''')}
${(oldKind.canBeMixinOnType && newKind.canBeMixinOnType)('''
mixin MixinOn$oldName on $type {}
''')}
''');
    // Static/constructor Member access
    buffer.writeln('var staticAccess$oldName = <Object?>[');
    // Constructors, for anything but mixins.
    if (oldKind.hasConstructors && newKind.hasConstructors) {
      for (var name in ['', '.new', '.named']) {
        for (var op in ['', 'new ', 'const ']) {
          if (!removed || op == '' && name == '') {
            buffer.writeln('  $op$type$name(),');
          }
        }
        if (name.isNotEmpty) {
          buffer.writeln('  $type$name, // Tearoff');
        }
      }
    }

    // Static member access, no generics.
    // Same code for generic and non-generic types, so only do it for one.
    if (!generic) {
      type = '%$oldName%';
      buffer.write('''
    $type.constValue, // static constant
    $type.value, // Static getter
    $type.method(), // Static method
    $type.method, // Static method tear-off,
  ];

  void staticSetter$oldName(dynamic value) {
    $type.value = value;
  }
  ''');
    } else {
      buffer.write('  ];\n');
    }
  }

  void writeTypeDeclaration(
    StringBuffer buffer,
    TypeKind kind,
    String name, {
    bool deprecated = false,
    bool generic = false,
  }) {
    const typeParameters = '<T>';
    const typeArguments = '<int>';
    if (deprecated) buffer.writeln('@deprecated');
    switch (kind) {
      // Type aliases have a helper class that they alias.
      case TypeKind.typedefKind:
        buffer.write('''
typedef $name${generic(typeParameters)} = _T$name${generic(typeParameters)};
''');
        writeTypeDeclaration(
          buffer,
          TypeKind.classKind,
          '_T$name',
          deprecated: deprecated,
          generic: generic,
        );
      case TypeKind.classKind:
        buffer.write('''
mixin class $name${generic(typeParameters)} {
  static const Object? constValue = $name${generic('<Never>')}();
  static int value = 0;
  static int method() => 0;
  const $name();
  const $name.named();
}
''');
      // Enums use a helper extension type to implement factory constructors.
      case TypeKind.enumKind:
        buffer.write('''
enum $name${generic(typeParameters)} {
  constValue${generic(typeArguments)}._();
  const $name._();
  static int value = 0;
  static int method() => 0;
  const factory $name() = _${name}Helper${generic(typeParameters)};
  const factory $name.named() = _${name}Helper${generic(typeParameters)};
}${deprecated('\n@deprecated')}
extension type const _${name}Helper${generic(typeParameters)}._($name${generic(typeParameters)} _)
    implements $name${generic(typeParameters)} {
  const _${name}Helper() : this._($name.constValue as dynamic);
}
''');
      case TypeKind.mixinKind:
        buffer.write('''
mixin $name${generic(typeParameters)} {
  static const Object? constValue = 0;
  static int value = 0;
  static int method() => 0;
}
''');
      case TypeKind.extensionTypeKind:
        buffer.write('''
extension type const $name${generic(typeParameters)}._(int _) implements Object {
  static const Object? constValue = 0;
  static int value = 0;
  static int method() => 0;
  const $name() : this._(0);
  const $name.named() : this._(0);
}
''');
    }
  }

  Future<void> _assertExpectedFixes(String source, String expected) async {
    var (lib1, lib2, fixData, _, _) = (sharedData ??= _generateFiles());
    setPackageContent(lib1);
    newFile('$workspaceRootPath/p/lib/lib2.dart', lib2);
    addPackageDataFile(fixData);
    await resolveTestCode(source);
    await assertHasFix(expected);
  }

  /// Checks that code in the template gets fixed.
  ///
  /// If [lib1Prefix] is non-empty, `lib1` is imported with that prefix.
  /// If it's empty, `lib1` is imported with no prefix.
  ///
  /// If [lib2Prefix] is `null`, `lib2` is not pre-imported.
  /// If non-`null`, it's imported with no prefix if empty,
  /// or that prefix if not.
  Future<void> _assertTemplatedFixes(
    String lib1Prefix,
    String? lib2Prefix,
  ) async {
    var (_, _, _, template, newNameOf) = (sharedData ??= _generateFiles());
    var lib1Import =
        '''import '$importUri'${lib1Prefix.isNotEmpty(' as $lib1Prefix')};\n''';
    var lib1PrefixDot = lib1Prefix.isEmpty ? '' : '$lib1Prefix.';
    // Lib2 import in post-fix library.
    var lib2Import =
        '''import 'package:p/lib2.dart'${(lib2Prefix != null && lib2Prefix.isNotEmpty)(' as $lib2Prefix')};\n''';
    var lib2PrefixDot = '';
    var lib2Usage = '';
    var lib2OldImport = ''; // Import in pre-fix library.
    if (lib2Prefix != null) {
      // Lib2 was imported in original.
      if (lib2Prefix.isNotEmpty) lib2PrefixDot = '$lib2Prefix.';
      lib2OldImport = lib2Import;
      // Inserted to avoid a pre-imported lib 2 being unused.
      lib2Usage = '${lib2PrefixDot}Lib2Use? dummyDeclaration;\n';
    }

    var source =
        '$lib1Import$lib2OldImport$lib2Usage${_replaceInTemplate(template, lib1PrefixDot, lib2PrefixDot, null)}';
    var expected =
        '$lib1Import$lib2Import$lib2Usage${_replaceInTemplate(template, lib1PrefixDot, lib2PrefixDot, newNameOf)}';

    await _assertExpectedFixes(source, expected);
  }

  /// Creates the types referenced by the files to be fixed,
  /// and a template for all the occurrences of those types.
  ///
  /// * `lib1`: The primary library containing all the deprecated classes,
  ///   and some of the classes they should be replaced by.
  /// * `lib2`: Secondary library for replacing a deprecated type with
  ///   a type in another library.
  /// * `fixTemplate` is a template containing `%oldName%` where a type
  ///   to replace should go. Inserting a deprecated type and fixing
  ///   should give the corresponding name from `newNameOf`.
  /// * `fixData` the data-driven fixes mapping all deprecated types in `lib1`
  ///   to new types in `lib1` or `lib2`.
  /// * Mapping from deprecated type names to their replacement type name.
  (
    String lib1,
    String lib2,
    String fixData,
    String fixTemplate,
    Map<String, String> newNameOf,
  )
  _generateFiles() {
    var lib1Buffer = StringBuffer();
    var lib2Buffer = StringBuffer('''
class Lib2Use {} // Can be referred to avoid unused import warnings.
''');
    var fixDataBuffer = StringBuffer();

    // Contains code templates for code to fix.
    // A character sequence of `%ABCDE%` represents an occurrence of the old
    // type `ABCDE`. It will be replaced in both before source (to add prefixes
    // in some cases), and in output to insert the expected replacement.
    var templateBuffer = StringBuffer();

    /// Mapping from old deprecated name to new replacement name.
    var newNameOf = <String, String>{};

    // Go through all the combinations of kinds of type declarations, and
    // whether the replacement is in the same or another library.
    for (var newKind in TypeKind.values) {
      for (var otherLibrary in [false, true]) {
        for (var generic in [false, true]) {
          var newName = '${generic('G')}${otherLibrary('O')}$newKind';
          writeTypeDeclaration(
            otherLibrary ? lib2Buffer : lib1Buffer,
            newKind,
            newName,
            generic: generic,
          );
          for (var oldKind in TypeKind.values) {
            for (var removed in [false /*true*/]) {
              // Should also work when original type declaration is removed
              // Does not yet, not in all cases.
              var oldName = '${removed ? 'R' : 'D'}$oldKind$newName';
              assert(!newNameOf.containsKey(oldName));
              if (!removed) {
                writeTypeDeclaration(
                  lib1Buffer,
                  oldKind,
                  oldName,
                  deprecated: true,
                  generic: generic,
                );
              }
              writeFix(
                fixDataBuffer,
                oldKind,
                newKind,
                oldName,
                newName,
                otherLibrary,
              );
              newNameOf[oldName] = newName;

              writeTemplatesFor(
                templateBuffer,
                oldKind,
                newKind,
                oldName,
                generic,
                removed,
              );
            }
          }
        }
      }
    }
    return (
      lib1Buffer.toString(),
      lib2Buffer.toString(),
      fixDataBuffer.toString(),
      templateBuffer.toString(),
      newNameOf,
    );
  }

  /// Replaces `%oldName%` with either` `(prefix.)?oldName`
  /// or `(prefix.)?newName`.
  static String _replaceInTemplate(
    String template,
    String lib1PrefixDot,
    String lib2PrefixDot,
    Map<String, String>? newNameOf,
  ) {
    if (newNameOf == null) {
      // Old name, just prefix with prefix-dot if needed.
      return template.replaceAllMapped(
        _templateEntryRE,
        (m) => '$lib1PrefixDot${m[1]}',
      );
    }
    var cache = <String, String>{};
    return template.replaceAllMapped(_templateEntryRE, (m) {
      var oldName = m[1]!;

      String? newName = cache[oldName];
      if (newName != null) return newName;
      newName = newNameOf[oldName]!;
      var prefix = newName.contains('O') ? lib2PrefixDot : lib1PrefixDot;
      return cache[oldName] = '$prefix$newName';
    });
  }
}

enum TypeKind {
  classKind('class', 'C'),
  enumKind('enum', 'E'),
  extensionTypeKind('extensionType', 'X'),
  mixinKind('mixin', 'M'),
  typedefKind('typedef', 'A');

  // String used to represent kind in fix-data and pretty names.
  final String name;
  // Single character used to represent the type in constructed names.
  final String char;

  const TypeKind(this.name, this.char);

  bool get canBeClassInterface =>
      this == classKind || this == mixinKind || this == typedefKind;
  // Because class declarations here are all mixin classes.
  bool get canBeClassMixin =>
      this == classKind || this == mixinKind || this == typedefKind;
  bool get canBeClassSuper => this == classKind || this == typedefKind;
  bool get canBeExtensionOnType => true;
  bool get canBeExtensionTypeInterface =>
      canBeClassInterface || this == extensionTypeKind;
  bool get canBeMixinOnType =>
      this == classKind || this == mixinKind || this == typedefKind;
  // Mixin declarations can't declare constructors, not even factory ones. Yet.
  bool get hasConstructors => this != mixinKind;

  @override
  String toString() => char;
}

extension on bool {
  /// Choose a string based on the boolean value.
  String call(String ifTrue, [String ifFalse = '']) => this ? ifTrue : ifFalse;
}
