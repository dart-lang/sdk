// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../kernel/constructor_tearoff_lowering.dart';
import '../kernel/late_lowering.dart' as late_lowering;

enum FieldNameType { Field, Getter, Setter, IsSetField }

enum ContainerType { Library, Class, InlineClass, Extension }

class NameScheme {
  final bool isInstanceMember;
  final ContainerName? containerName;
  final ContainerType containerType;
  final LibraryName libraryName;

  NameScheme(
      {required this.isInstanceMember,
      required this.containerName,
      required this.containerType,
      required this.libraryName})
      // ignore: unnecessary_null_comparison
      : assert(isInstanceMember != null),
        // ignore: unnecessary_null_comparison
        assert(libraryName != null),
        assert((containerName == null) ==
            (containerType == ContainerType.Library));

  bool get isStatic => !isInstanceMember;

  bool get isExtensionMember => containerType == ContainerType.Extension;

  bool get isInlineClassMember => containerType == ContainerType.InlineClass;

  MemberName getFieldMemberName(FieldNameType fieldNameType, String name,
      {required bool isSynthesized}) {
    bool hasSynthesizedName;
    switch (containerType) {
      case ContainerType.Library:
      case ContainerType.Class:
        hasSynthesizedName = isSynthesized;
        break;
      case ContainerType.InlineClass:
      case ContainerType.Extension:
        hasSynthesizedName = true;
        break;
    }
    if (hasSynthesizedName) {
      return new SynthesizedFieldName(
          libraryName, containerName, containerType, fieldNameType, name,
          isInstanceMember: isInstanceMember, isSynthesized: isSynthesized);
    } else {
      return name.startsWith('_')
          ? new PrivateMemberName(libraryName, name)
          : new PublicMemberName(name);
    }
  }

  static String createFieldName(FieldNameType fieldNameType, String name,
      {required bool isInstanceMember,
      required ContainerName? containerName,
      required ContainerType containerType,
      bool isSynthesized = false}) {
    assert(isSynthesized || fieldNameType == FieldNameType.Field,
        "Unexpected field name type for non-synthesized field: $fieldNameType");
    assert((containerName == null) == (containerType == ContainerType.Library),
        "Missing container name for ${containerType}");

    String baseName;
    switch (containerType) {
      case ContainerType.Library:
      case ContainerType.Class:
        baseName = name;
        break;
      case ContainerType.InlineClass:
      case ContainerType.Extension:
        baseName = "${containerName!.name}|${name}";
        break;
    }
    if (!isSynthesized) {
      return baseName;
    } else {
      String namePrefix = late_lowering.lateFieldPrefix;
      if (isInstanceMember) {
        namePrefix = '$namePrefix${containerName!.name}#';
      }
      switch (fieldNameType) {
        case FieldNameType.Field:
          return "$namePrefix$baseName";
        case FieldNameType.Getter:
          return baseName;
        case FieldNameType.Setter:
          return baseName;
        case FieldNameType.IsSetField:
          return "$namePrefix$baseName${late_lowering.lateIsSetSuffix}";
      }
    }
  }

  MemberName getProcedureMemberName(ProcedureKind kind, String name) {
    switch (containerType) {
      case ContainerType.Library:
      case ContainerType.Class:
        return name.startsWith('_')
            ? new PrivateMemberName(libraryName, name)
            : new PublicMemberName(name);
      case ContainerType.InlineClass:
      case ContainerType.Extension:
        return new ExtensionProcedureName(
            libraryName, containerName!, containerType, kind, name,
            isStatic: isStatic);
    }
  }

  static String _createProcedureName(
      {required ContainerName? containerName,
      required ContainerType containerType,
      required bool isStatic,
      required ProcedureKind kind,
      required String name}) {
    switch (containerType) {
      case ContainerType.Extension:
      case ContainerType.InlineClass:
        String extensionName = containerName!.name;
        String kindInfix = '';
        if (!isStatic) {
          // Instance getter and setter are converted to methods so we use an
          // infix to make their names unique.
          switch (kind) {
            case ProcedureKind.Getter:
              kindInfix = 'get#';
              break;
            case ProcedureKind.Setter:
              kindInfix = 'set#';
              break;
            case ProcedureKind.Method:
            case ProcedureKind.Operator:
              kindInfix = '';
              break;
            case ProcedureKind.Factory:
              throw new UnsupportedError(
                  'Unexpected extension method kind ${kind}');
          }
        }
        return '${extensionName}|${kindInfix}${name}';
      case ContainerType.Library:
      case ContainerType.Class:
        return name;
    }
  }

  MemberName getConstructorMemberName(String name, {required bool isTearOff}) {
    switch (containerType) {
      case ContainerType.Library:
      case ContainerType.Class:
        if (isTearOff) {
          name = constructorTearOffName(name);
        }
        return name.startsWith('_')
            ? new PrivateMemberName(libraryName, name)
            : new PublicMemberName(name);
      case ContainerType.InlineClass:
      case ContainerType.Extension:
        // Extension is handled here for the error case only.
        return new InlineClassConstructorName(libraryName, containerName!, name,
            isTearOff: isTearOff);
    }
  }
}

/// The part of a member name defined by a library.
///
/// This is used for creating member names together with the member builders
/// while still supporting that the resulting library is computed late.
class LibraryName {
  /// The reference to the [Library] that defines the library name scope.
  Reference _reference;

  /// [MemberName]s dependent on this library name.
  List<MemberName> _memberNames = [];

  LibraryName(this._reference);

  /// Registers [name] as dependent on this library name.
  void attachMemberName(MemberName name) {
    _memberNames.add(name);
  }

  /// Returns the current [Reference] used for creating [Name]s in this library
  /// name scope.
  Reference get reference => _reference;

  /// Updates the [Reference] that defines the library name scope.
  ///
  /// If changed, the dependent [_memberNames] are updated accordingly.
  void set reference(Reference value) {
    if (_reference != value) {
      _reference = value;
      for (MemberName name in _memberNames) {
        name.updateMemberName();
      }
    }
  }
}

/// The name of a class, inline class or extension.
abstract class ContainerName {
  /// The current name of the container.
  ///
  /// For an unnamed extension, this is initially a sentinel value, which is
  /// updated within the containing [Library] is composed.
  String get name;

  /// Registers [name] as dependent on this container name.
  void attachMemberName(MemberName name);
}

/// The name of a class or an inline classes.
class ClassName extends ContainerName {
  final String _name;

  ClassName(this._name);

  @override
  String get name => _name;

  @override
  void attachMemberName(MemberName name) {}
}

/// The name of an extension, either named or unnamed.
///
/// This is used for creating extension member names together with the member
/// builders while still supporting that the synthesized extension names for
/// unnamed extensions are computed late.
abstract class ExtensionName extends ContainerName {
  /// Updates the name for this extension.
  ///
  /// If changed, the dependent [Extension] names and [MemberName]s will be
  /// updated accordingly.
  void set name(String value);

  /// Returns `true` if this is the name of an unnamed extension.
  bool get isUnnamedExtension;

  /// Associates the [extension] with this extension name.
  ///
  /// When the [name] is updated, the name of the [extension] will be updated
  /// accordingly.
  void attachExtension(Extension extension);
}

/// The name of a named extension.
class FixedExtensionName implements ExtensionName {
  @override
  final String name;

  FixedExtensionName(this.name);

  @override
  bool get isUnnamedExtension => false;

  @override
  void set name(String value) {
    throw new UnsupportedError("Cannot change name of a fixed extension name.");
  }

  @override
  void attachExtension(Extension extension) {
    extension.name = name;
  }

  @override
  void attachMemberName(MemberName name) {}
}

/// The name of an unnamed extension.
class UnnamedExtensionName implements ExtensionName {
  static const String unnamedExtensionSentinel = '_unnamed-extension_';

  String? _name;
  Extension? _extension;

  List<MemberName> _memberNames = [];

  @override
  bool get isUnnamedExtension => true;

  @override
  String get name => _name ?? unnamedExtensionSentinel;

  @override
  void attachExtension(Extension extension) {
    _extension = extension;
    extension.name = name;
  }

  @override
  void set name(String name) {
    if (_name != name) {
      _name = name;
      _extension?.name = name;
      for (MemberName memberName in _memberNames) {
        memberName.updateMemberName();
      }
    }
  }

  @override
  void attachMemberName(MemberName name) {
    _memberNames.add(name);
  }
}

/// The name of a [Member] which support late computation of member names needed
/// for private names and names of members of unnamed extensions.
///
/// Since members are built early when library vs parts haven't been resolved
/// the private names of parts needed to be updated once the resulting [Library]
/// node has been determined, and for members of unnamed extensions, when the
/// synthesized name of the unnamed extension has been determined.
abstract class MemberName {
  factory MemberName(LibraryName libraryName, String text) =>
      text.startsWith('_')
          ? new PrivateMemberName(libraryName, text)
          : new PublicMemberName(text);

  /// Returns the current [Name] for this member name.
  Name get name;

  /// Recomputes the [name] property and, if changed, updates dependent members
  /// accordingly.
  ///
  /// This is called by [LibraryName] and [UnnamedExtensionName] when these
  /// are updated.
  void updateMemberName();

  /// Registers [member] has dependent of this member name and set the name
  /// of [member] to the current [name].
  void attachMember(Member member);
}

/// A public member name.
///
/// This never changes once created.
class PublicMemberName implements MemberName {
  @override
  final Name name;

  PublicMemberName(String text)
      : assert(!text.startsWith('_')),
        name = new Name(text);

  @override
  void updateMemberName() {}

  @override
  void attachMember(Member member) {
    member.name = name;
  }
}

/// A member name that can be updated.
abstract class UpdatableMemberName implements MemberName {
  Name? _name;
  List<Member> _members = [];

  Name _createName();

  @override
  Name get name => _name ??= _createName();

  @override
  void attachMember(Member member) {
    member.name = name;
    _members.add(member);
  }

  @override
  void updateMemberName() {
    Name name = _createName();
    if (_name != name) {
      for (Member member in _members) {
        member.name = name;
      }
    }
  }
}

/// A private member name.
///
/// This depends on a [LibraryName] and is updated when the reference of the
/// [LibraryName] is changed.
class PrivateMemberName extends UpdatableMemberName {
  final LibraryName _libraryName;
  final String _text;

  PrivateMemberName(this._libraryName, this._text)
      : assert(_text.startsWith('_')) {
    _libraryName.attachMemberName(this);
  }

  @override
  Name _createName() {
    return new Name.byReference(_text, _libraryName.reference);
  }
}

/// A name for an extension procedure.
///
/// This depends on a [LibraryName] and an [ContainerName] and is updated the
/// reference of the [LibraryName] or the name of the [ContainerName] is
/// changed.
class ExtensionProcedureName extends UpdatableMemberName {
  final LibraryName _libraryName;
  final ContainerName _containerName;
  final ContainerType _containerType;
  final ProcedureKind _kind;
  final bool isStatic;
  final String _text;

  ExtensionProcedureName(this._libraryName, this._containerName,
      this._containerType, this._kind, this._text,
      {required this.isStatic}) {
    _libraryName.attachMemberName(this);
    _containerName.attachMemberName(this);
  }

  @override
  Name _createName() {
    return new Name.byReference(
        NameScheme._createProcedureName(
            containerName: _containerName,
            containerType: _containerType,
            isStatic: isStatic,
            kind: _kind,
            name: _text),
        _libraryName.reference);
  }
}

/// A name for an inline class constructor.
///
/// This depends on a [LibraryName] and an [ContainerName] and is updated the
/// reference of the [LibraryName] or the name of the [ContainerName] is
/// changed.
class InlineClassConstructorName extends UpdatableMemberName {
  final LibraryName _libraryName;
  final ContainerName _containerName;
  final bool isTearOff;
  final String _text;

  InlineClassConstructorName(this._libraryName, this._containerName, this._text,
      {required this.isTearOff}) {
    _libraryName.attachMemberName(this);
    _containerName.attachMemberName(this);
  }

  @override
  Name _createName() {
    String className = _containerName.name;
    // Constructors and tear-offs are converted to methods so we use an
    // infix to make their names unique.
    String name;
    if (isTearOff) {
      name = constructorTearOffName(_text);
    } else {
      name = _text;
    }
    return new Name.byReference('${className}|${name}', _libraryName.reference);
  }
}

/// A name of a synthesized field.
///
/// This depends on a [LibraryName] and an [ExtensionName] and is updated the
/// reference of the [LibraryName] or the name of the [ExtensionName] is
/// changed.
class SynthesizedFieldName extends UpdatableMemberName {
  final LibraryName _libraryName;
  final ContainerName? _containerName;
  final ContainerType _containerType;
  final FieldNameType _type;
  final bool isInstanceMember;
  final bool isSynthesized;
  final String _text;

  SynthesizedFieldName(this._libraryName, this._containerName,
      this._containerType, this._type, this._text,
      {required this.isInstanceMember, required this.isSynthesized}) {
    _libraryName.attachMemberName(this);
    _containerName?.attachMemberName(this);
  }

  @override
  Name _createName() {
    return new Name.byReference(
        NameScheme.createFieldName(_type, _text,
            isInstanceMember: isInstanceMember,
            containerName: _containerName,
            containerType: _containerType,
            isSynthesized: isSynthesized),
        _libraryName.reference);
  }
}
