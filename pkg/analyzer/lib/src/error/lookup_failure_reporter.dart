// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/listener.dart';

/// A lookup in the static members of the context type of a dot shorthand.
///
/// For example, `.foo` and `.foo()`.
///
/// A dot shorthand without a context type is reported as missing a context
/// instead, so this domain always has a context type.
final class DotShorthandLookupDomain extends LookupDomain {
  /// The context type of the dot shorthand.
  final TypeImpl contextType;

  /// The interface declaration that [contextType] denotes, or `null` if it
  /// doesn't denote one.
  final InterfaceElementImpl? declaration;

  /// Whether [declaration] is private to another library, so its static
  /// members were not searched.
  final bool _isPrivateDeclaration;

  /// A lookup in the declaration that [context] denotes.
  new declaration(ValidDotShorthandContextResolutionImpl context)
    : contextType = context.contextType,
      declaration = context.lookupType.element,
      _isPrivateDeclaration = false;

  /// A lookup in the context type of [context], which doesn't denote an
  /// accessible interface declaration, so nothing could be found.
  factory invalid(InvalidDotShorthandContextResolutionImpl context) {
    if (context.lookupType case InterfaceTypeImpl(:var element)) {
      if (element.isPrivate) {
        return DotShorthandLookupDomain._privateDeclaration(
          context.contextType,
          element,
        );
      }
    }
    return DotShorthandLookupDomain._noDeclaration(context.contextType);
  }

  new _noDeclaration(this.contextType)
    : declaration = null,
      _isPrivateDeclaration = false;

  new _privateDeclaration(
    this.contextType,
    InterfaceElementImpl this.declaration,
  ) : _isPrivateDeclaration = true;

  @override
  bool _isIgnored(LibraryFragmentImpl libraryFragment, String name) {
    // The invalid context type has already been reported.
    return contextType is InvalidTypeImpl;
  }

  @override
  LocatableDiagnostic _readFailure(
    String name,
    _FoundInstead foundInstead,
    ReadPosition position,
  ) {
    var declaration = this.declaration;
    if (declaration == null) {
      return diag.undefinedStaticMemberReadNoStaticMembersDotShorthand
          .withArguments(
            name: name,
            contextType: contextType.getDisplayString(),
          );
    } else if (_isPrivateDeclaration) {
      return diag.undefinedStaticMemberReadPrivateDotShorthand.withArguments(
        name: name,
        contextType: declaration.displayName,
        libraryUri: declaration.library.uri,
      );
    }

    // Only the message for a missing member names the context type; the
    // others are the messages of `StaticLookupDomain`.
    switch (foundInstead) {
      case _FoundNothing():
        var code = switch (position) {
          ReadPosition.annotation => throw StateError(
            'A dot shorthand cannot be an annotation.',
          ),
          ReadPosition.constant =>
            diag.undefinedStaticMemberReadNotFoundDotShorthandConstant,
          ReadPosition.other =>
            diag.undefinedStaticMemberReadNotFoundDotShorthand,
        };
        return code.withArguments(
          name: name,
          contextType: declaration.displayName,
          expectedKinds: StaticLookupDomain._expectedKindsOf(declaration),
        );
      case _FoundPrivate(:var libraryUri):
        return diag.undefinedStaticMemberReadPrivate.withArguments(
          name: name,
          libraryUri: libraryUri,
        );
      case _FoundDeclaration(element: ExecutableElement(isStatic: false)):
        return diag.staticAccessToInstanceMember.withArguments(name: name);
      case _FoundDeclaration(:var element):
        assert(element is SetterElement);
        return diag.undefinedStaticMemberReadSetterOnly.withArguments(
          name: name,
          containerKind: _displayKindOf(declaration),
          containerName: declaration.displayName,
        );
    }
  }

  @override
  LocatableDiagnostic? _writeFailure(String name, _FoundInstead foundInstead) {
    throw StateError('A dot shorthand cannot be written.');
  }
}

/// A lookup in the members of an explicit extension override.
///
/// For example, `E(x).foo` and `E(x).foo = 0`.
final class ExtensionOverrideLookupDomain extends LookupDomain {
  /// The extension that the override names.
  final ExtensionElement extension;

  new(this.extension);

  String get _extensionName {
    // An extension override can only name a named extension.
    // TODO(scheglov): Prove this with types, instead of a null check.
    return extension.name!;
  }

  @override
  LocatableDiagnostic _readFailure(
    String name,
    _FoundInstead foundInstead,
    ReadPosition position,
  ) {
    switch (foundInstead) {
      case _FoundNothing():
        return diag.undefinedExtensionMemberReadNotFound.withArguments(
          name: name,
          extensionName: _extensionName,
        );
      case _FoundPrivate(:var libraryUri):
        return diag.undefinedExtensionMemberReadPrivate.withArguments(
          name: name,
          libraryUri: libraryUri,
        );
      case _FoundDeclaration(element: ExecutableElement(isStatic: true)):
        return diag.extensionOverrideAccessToStaticMember;
      case _FoundDeclaration(:var element):
        assert(element is SetterElement);
        return diag.undefinedExtensionMemberReadSetterOnly.withArguments(
          name: name,
          extensionName: _extensionName,
        );
    }
  }

  @override
  LocatableDiagnostic? _writeFailure(String name, _FoundInstead foundInstead) {
    switch (foundInstead) {
      case _FoundNothing():
        return diag.undefinedExtensionMemberWriteNotFound.withArguments(
          name: name,
          extensionName: _extensionName,
        );
      case _FoundPrivate(:var libraryUri):
        return diag.undefinedExtensionMemberWritePrivate.withArguments(
          name: name,
          libraryUri: libraryUri,
        );
      case _FoundDeclaration(element: ExecutableElement(isStatic: true)):
        return diag.extensionOverrideAccessToStaticMember;
      case _FoundDeclaration(element: GetterElement(:var variable)):
        if (variable.isOriginGetterSetter) {
          return diag.undefinedExtensionMemberWriteGetterOnly.withArguments(
            name: name,
            extensionName: _extensionName,
          );
        } else {
          // An extension can't declare an instance field, and the field
          // declaration already reports that.
          return null;
        }
      case _FoundDeclaration(:var element):
        return diag.undefinedExtensionMemberWriteWrongKind.withArguments(
          kind: _displayKindOf(element),
          name: name,
          extensionName: _extensionName,
        );
    }
  }
}

/// A lookup in the static members of a function-type alias.
///
/// For example, `F.foo` and `F.foo = 0`. A function-type alias has no static
/// members, so every lookup in it fails.
final class FunctionTypeAliasLookupDomain extends LookupDomain {
  /// The name of the alias, with its import prefix if one is written.
  final String aliasName;

  new({required ImportPrefixReferenceImpl? importPrefix, required Token name})
    : aliasName = importPrefix != null
          ? '${importPrefix.name.lexeme}.${name.lexeme}'
          : name.lexeme;

  @override
  LocatableDiagnostic _readFailure(
    String name,
    _FoundInstead foundInstead,
    ReadPosition position,
  ) {
    return diag.undefinedStaticMemberReadNoStaticMembers.withArguments(
      name: name,
      aliasName: aliasName,
    );
  }

  @override
  LocatableDiagnostic? _writeFailure(String name, _FoundInstead foundInstead) {
    return diag.undefinedStaticMemberWriteNoStaticMembers.withArguments(
      name: name,
      aliasName: aliasName,
    );
  }
}

/// A lookup in the instance members of the static type of a receiver.
///
/// For example, `x.foo` and `x.foo = 0`. The members of applicable extensions
/// are included.
final class InstanceLookupDomain extends LookupDomain {
  /// The static type of the receiver.
  final TypeImpl receiverType;

  /// The field of the record type [receiverType] that has the name, if the
  /// lookup found one.
  ///
  /// A record field has a getter, but no setter. It isn't an [Element], so a
  /// failed write can't report it as found instead.
  final RecordTypeField? recordField;

  new(this.receiverType, {this.recordField});

  @override
  LocatableDiagnostic _readFailure(
    String name,
    _FoundInstead foundInstead,
    ReadPosition position,
  ) {
    switch (foundInstead) {
      case _FoundNothing():
        return diag.undefinedInstanceMemberReadNotFound.withArguments(
          name: name,
          type: receiverType,
        );
      case _FoundPrivate(:var libraryUri):
        return diag.undefinedInstanceMemberReadPrivate.withArguments(
          name: name,
          libraryUri: libraryUri,
        );
      case _FoundDeclaration(:var element):
        assert(element is SetterElement);
        return diag.undefinedInstanceMemberReadSetterOnly.withArguments(
          name: name,
          type: receiverType,
        );
    }
  }

  @override
  LocatableDiagnostic? _writeFailure(String name, _FoundInstead foundInstead) {
    switch (foundInstead) {
      case _FoundNothing():
        if (recordField != null) {
          return diag.undefinedInstanceMemberWriteGetterOnly.withArguments(
            name: name,
            type: receiverType,
          );
        }
        return diag.undefinedInstanceMemberWriteNotFound.withArguments(
          name: name,
          type: receiverType,
        );
      case _FoundPrivate(:var libraryUri):
        return diag.undefinedInstanceMemberWritePrivate.withArguments(
          name: name,
          libraryUri: libraryUri,
        );
      case _FoundDeclaration(element: GetterElement(:var variable)):
        if (_isInvalidInstanceField(variable)) {
          return null;
        } else if (variable is FieldElement &&
            variable.isFinal &&
            (variable.isOriginDeclaration ||
                variable.isOriginDeclaringFormalParameter)) {
          return diag.undefinedInstanceMemberWriteFinal.withArguments(
            name: name,
            type: receiverType,
          );
        } else {
          return diag.undefinedInstanceMemberWriteGetterOnly.withArguments(
            name: name,
            type: receiverType,
          );
        }
      case _FoundDeclaration(:var element):
        return diag.undefinedInstanceMemberWriteWrongKind.withArguments(
          kind: _displayKindOf(element),
          name: name,
          type: receiverType,
        );
    }
  }
}

/// A namespace in which a name was looked up.
///
/// Together with the required capability, read or write, the domain decides
/// which diagnostic reports a failed lookup.
///
/// Domains are created only when a lookup has failed, so that resolving valid
/// code, which is almost all code, doesn't allocate them.
sealed class LookupDomain {
  /// The kind of [element] as it is displayed in messages.
  ///
  /// The kinds of `dynamic` and `Never` have placeholder display names, such
  /// as `<dynamic>`, because they have no declarations.
  String _displayKindOf(Element element) {
    return switch (element) {
      DynamicElementImpl() || NeverElementImpl() => 'type',
      _ => element.kind.displayName,
    };
  }

  /// Whether a failed lookup of [name] in this domain is not reported.
  bool _isIgnored(LibraryFragmentImpl libraryFragment, String name) {
    return false;
  }

  /// Whether [variable] is an instance field whose declaration is itself an
  /// error, so that a failed write to it is a follow-up and reports nothing.
  ///
  /// An instance field can't be constant, which reports
  /// `const_instance_field`, and extensions and extension types can't declare
  /// instance fields, which reports `extension_declares_instance_field` and
  /// `extension_type_declares_instance_field`.
  bool _isInvalidInstanceField(PropertyInducingElement variable) {
    // A top-level variable can be constant.
    if (variable is! FieldElement) {
      return false;
    }

    // A static field can be constant, also in an extension.
    if (variable.isStatic) {
      return false;
    }

    // A field induced by a getter or setter stands for valid accessors, also
    // in an extension.
    if (!variable.isOriginDeclaration) {
      return false;
    }

    // An instance field can't be constant.
    if (variable.isConst) {
      return true;
    }

    // An extension can't declare instance fields.
    if (variable.enclosingElement is ExtensionElement) {
      return true;
    }

    // An extension type can't declare instance fields, other than its
    // representation field, which is a declaring formal parameter.
    if (variable.enclosingElement is ExtensionTypeElement) {
      return true;
    }

    return false;
  }

  /// The diagnostic for a lookup of [name] at [position] that found nothing
  /// that can be read, but [foundInstead].
  LocatableDiagnostic _readFailure(
    String name,
    _FoundInstead foundInstead,
    ReadPosition position,
  );

  /// The diagnostic for a lookup of [name] that found no setter, but
  /// [foundInstead], or `null` if nothing is reported.
  LocatableDiagnostic? _writeFailure(String name, _FoundInstead foundInstead);
}

/// A reporter of names that a lookup failed to resolve for the required
/// capability.
///
/// Call sites describe the failure: the [LookupDomain] that was searched, the
/// capability, read or write, and for writes what was found instead of a
/// setter. Each domain chooses its diagnostics, and this class applies the
/// rules that are shared by all lookups, such as not reporting synthetic
/// names, and the diagnostics for what was found instead of a setter.
///
/// The family of diagnostics for each domain and capability is described in
/// https://github.com/dart-lang/sdk/issues/64411.
class LookupFailureReporter {
  final DiagnosticReporter _diagnosticReporter;
  final LibraryFragmentImpl _libraryFragment;

  new(this._diagnosticReporter, this._libraryFragment);

  /// Reports that the lookup of [name] in [domain] found nothing that can be
  /// read, invoked, or torn off.
  ///
  /// The [foundInstead] is the declaration that has the name, but can't be
  /// read, such as a setter, or a private declaration of another library. It
  /// is `null` if nothing has the name, or if the caller reports every failed
  /// read in [domain] as not found.
  ///
  /// The [position] selects the message when nothing has the name. Only a
  /// read whose value is used, not an invocation, a receiver, or the read of
  /// a compound assignment, has a position other than [ReadPosition.other].
  void reportReadFailure({
    required LookupDomain domain,
    required Token name,
    required Element? foundInstead,
    ReadPosition position = ReadPosition.other,
  }) {
    if (_isIgnored(domain, name)) {
      return;
    }
    var found = _FoundInstead.of(foundInstead, _libraryFragment.element);
    _diagnosticReporter.report(
      domain._readFailure(name.lexeme, found, position).at(name),
    );
  }

  /// Reports that the lookup of [name] in [domain] found no setter.
  ///
  /// The [foundInstead] is the declaration that has the name of the missing
  /// setter, such as a getter, a method, a function, a type, or a private
  /// declaration of another library. It is `null` if nothing has the name, or
  /// if the caller reports every missing setter in [domain] as not found.
  void reportWriteFailure({
    required LookupDomain domain,
    required Token name,
    required Element? foundInstead,
  }) {
    var found = _FoundInstead.of(foundInstead, _libraryFragment.element);
    if (found is _FoundNothing && _isIgnored(domain, name)) {
      return;
    }
    if (domain._writeFailure(name.lexeme, found) case var diagnostic?) {
      _diagnosticReporter.report(diagnostic.at(name));
    }
  }

  /// Whether a failed lookup of [name] in [domain] is not reported.
  bool _isIgnored(LookupDomain domain, Token name) {
    // The parser has already reported the missing name.
    return name.isSynthetic || domain._isIgnored(_libraryFragment, name.lexeme);
  }
}

/// A lookup in the names imported through an import prefix.
///
/// For example, `p.foo` and `p.foo = 0`.
final class PrefixedLookupDomain extends LookupDomain {
  /// The import prefix.
  final PrefixElement prefix;

  new(this.prefix);

  /// The name of the [prefix], which the code being analyzed used to
  /// reference it, so it isn't `null`.
  String get _prefixName => prefix.name!;

  @override
  bool _isIgnored(LibraryFragmentImpl libraryFragment, String name) {
    return libraryFragment.shouldIgnoreUndefined(
      prefix: _prefixName,
      name: name,
    );
  }

  @override
  LocatableDiagnostic _readFailure(
    String name,
    _FoundInstead foundInstead,
    ReadPosition position,
  ) {
    switch (foundInstead) {
      case _FoundNothing():
        var code = switch (position) {
          ReadPosition.annotation =>
            diag.undefinedPrefixedNameReadNotFoundAnnotation,
          ReadPosition.constant =>
            diag.undefinedPrefixedNameReadNotFoundConstant,
          ReadPosition.other => diag.undefinedPrefixedNameReadNotFound,
        };
        return code.withArguments(name: name, prefix: _prefixName);
      case _FoundPrivate(:var libraryUri):
        return diag.undefinedPrefixedNameReadPrivate.withArguments(
          name: name,
          libraryUri: libraryUri,
        );
      case _FoundDeclaration(:var element):
        // Setters, possibly ambiguous between the imported libraries.
        assert(element is SetterElement || element is MultiplyDefinedElement);
        return diag.undefinedPrefixedNameReadSetterOnly.withArguments(
          name: name,
          prefix: _prefixName,
        );
    }
  }

  @override
  LocatableDiagnostic? _writeFailure(String name, _FoundInstead foundInstead) {
    switch (foundInstead) {
      case _FoundNothing():
        return diag.undefinedPrefixedNameWriteNotFound.withArguments(
          name: name,
          prefix: _prefixName,
        );
      case _FoundPrivate(:var libraryUri):
        return diag.undefinedPrefixedNameWritePrivate.withArguments(
          name: name,
          libraryUri: libraryUri,
        );
      case _FoundDeclaration(element: GetterElement(:var variable)):
        if (variable.isOriginGetterSetter) {
          return diag.undefinedPrefixedNameWriteGetterOnly.withArguments(
            name: name,
            prefix: _prefixName,
          );
        } else if (variable.isConst) {
          return diag.undefinedPrefixedNameWriteConst.withArguments(
            name: name,
            prefix: _prefixName,
          );
        } else {
          assert(variable.isFinal);
          return diag.undefinedPrefixedNameWriteFinal.withArguments(
            name: name,
            prefix: _prefixName,
          );
        }
      case _FoundDeclaration(:var element):
        return diag.undefinedPrefixedNameWriteWrongKind.withArguments(
          kind: _displayKindOf(element),
          name: name,
          prefix: _prefixName,
        );
    }
  }
}

/// Where a read is, which selects the message when its name isn't found,
/// because the position narrows the declarations that would make the read
/// valid.
enum ReadPosition {
  /// The whole expression of an annotation, such as `@foo`, `@p.foo`, and
  /// `@C.foo`, which must denote a constant variable.
  annotation,

  /// A position that requires a constant expression, such as
  /// `const x = foo;`, `const [p.foo]`, `@A(C.foo)`, `[int a = foo]`, and
  /// `case foo:`.
  constant,

  /// Any other position.
  other;

  /// The position of the read [node].
  static ReadPosition of(NameExpressionImpl node) {
    var parent = node.parent2;
    if (parent is AnnotationImpl) {
      return annotation;
    }

    // In `const x = foo.bar;`, the undefined `foo` is the receiver. The
    // whole `foo.bar` must be constant, so `foo` would usually be a class or
    // an import prefix, and a correction that suggests a constant variable
    // named `foo` would mislead.
    if (parent is ReceiverPropertyExtractionImpl ||
        parent is ReceiverMethodInvocationImpl) {
      return other;
    }

    // These are more positions than `AstNodeImpl.constantContext2`, which
    // decides where literals are implicitly constant: a default value and a
    // constant pattern without `const` require a constant, but
    // `[List x = []]` is not a constant default value.
    for (var current = parent; current != null; current = current.parent2) {
      switch (current) {
        // Every expression in these positions must be constant.
        case AnnotationImpl():
        case ConstantPatternImpl():
        case EnumConstantArgumentsImpl():
        case FormalParameterDefaultClauseImpl():
        case MapPatternEntryImpl():
        case RelationalPatternImpl():
        case SwitchCaseImpl():
          return constant;
        case TopLevelVariablesDeclarationImpl(:var constKeyword):
          return constKeyword != null ? constant : other;
        case VariableDeclarationListImpl(:var keyword):
          return keyword?.keyword == Keyword.CONST ? constant : other;
        // An explicitly constant expression makes its parts constant.
        case ConstructorInvocationImpl(keyword: Token(keyword: Keyword.CONST)):
        case DotShorthandConstructorInvocation2Impl(constKeyword: _?):
        case RecordLiteralImpl(constKeyword: _?):
        case TypedLiteralImpl(constKeyword: _?):
          return constant;
        case ArgumentListImpl():
        case ExpressionImpl():
        case ForElementImpl():
        case IfElementImpl():
        case InterpolationExpressionImpl():
        case MapLiteralEntryImpl():
        case NamedArgumentImpl():
        case NullAwareElementImpl():
        case RecordLiteralNamedFieldImpl():
        case SpreadElementImpl():
        case VariableBindingImpl():
          break;
        default:
          return other;
      }
    }
    return other;
  }
}

/// A lookup in the static members of a class, enum, mixin, extension type,
/// or extension.
///
/// For example, `C.foo` and `C.foo = 0`.
final class StaticLookupDomain extends LookupDomain {
  /// The declaration whose static members were searched.
  final InstanceElementImpl declaration;

  new(this.declaration);

  String get _containerKind => _displayKindOf(declaration);

  String get _containerName => declaration.displayName;

  @override
  LocatableDiagnostic _readFailure(
    String name,
    _FoundInstead foundInstead,
    ReadPosition position,
  ) {
    switch (foundInstead) {
      case _FoundNothing():
        var code = switch (position) {
          ReadPosition.annotation =>
            diag.undefinedStaticMemberReadNotFoundAnnotation,
          ReadPosition.constant =>
            diag.undefinedStaticMemberReadNotFoundConstant,
          ReadPosition.other => diag.undefinedStaticMemberReadNotFound,
        };
        return code.withArguments(
          name: name,
          containerKind: _containerKind,
          containerName: _containerName,
          expectedKinds: _expectedKindsOf(declaration),
        );
      case _FoundPrivate(:var libraryUri):
        return diag.undefinedStaticMemberReadPrivate.withArguments(
          name: name,
          libraryUri: libraryUri,
        );
      case _FoundDeclaration(element: ExecutableElement(isStatic: false)):
        return diag.staticAccessToInstanceMember.withArguments(name: name);
      case _FoundDeclaration(:var element):
        assert(element is SetterElement);
        return diag.undefinedStaticMemberReadSetterOnly.withArguments(
          name: name,
          containerKind: _containerKind,
          containerName: _containerName,
        );
    }
  }

  @override
  LocatableDiagnostic? _writeFailure(String name, _FoundInstead foundInstead) {
    switch (foundInstead) {
      case _FoundNothing():
        return diag.undefinedStaticMemberWriteNotFound.withArguments(
          name: name,
          containerKind: _containerKind,
          containerName: _containerName,
        );
      case _FoundPrivate(:var libraryUri):
        return diag.undefinedStaticMemberWritePrivate.withArguments(
          name: name,
          libraryUri: libraryUri,
        );
      case _FoundDeclaration(element: ExecutableElement(isStatic: false)):
        return diag.staticAccessToInstanceMember.withArguments(name: name);
      case _FoundDeclaration(element: GetterElement(:var variable)):
        if (variable.isOriginGetterSetter) {
          return diag.undefinedStaticMemberWriteGetterOnly.withArguments(
            name: name,
            containerKind: _containerKind,
            containerName: _containerName,
          );
        } else if (variable.isConst) {
          return diag.undefinedStaticMemberWriteConst.withArguments(
            name: name,
            containerKind: _containerKind,
            containerName: _containerName,
          );
        } else {
          assert(variable.isFinal);
          return diag.undefinedStaticMemberWriteFinal.withArguments(
            name: name,
            containerKind: _containerKind,
            containerName: _containerName,
          );
        }
      case _FoundDeclaration(:var element):
        return diag.undefinedStaticMemberWriteWrongKind.withArguments(
          kind: _displayKindOf(element),
          name: name,
          containerKind: _containerKind,
          containerName: _containerName,
        );
    }
  }

  /// The kinds of declarations that a lookup in the static members of
  /// [declaration] could find, as they are displayed in messages.
  static String _expectedKindsOf(InstanceElementImpl declaration) {
    switch (declaration) {
      case ClassElementImpl():
      case ExtensionTypeElementImpl():
        return 'static member or constructor';
      case EnumElementImpl():
        return 'value or static member';
      case ExtensionElementImpl():
      case MixinElementImpl():
        return 'static member';
    }
  }
}

/// A lookup in the members that `super` refers to in the enclosing
/// declaration.
///
/// For example, `super.foo` and `super.foo = 0`. These are the members of the
/// superclass, or of the superclass constraints of a mixin.
final class SuperLookupDomain extends LookupDomain {
  /// The type of `this` in the enclosing declaration.
  final InterfaceTypeImpl type;

  new(this.type);

  @override
  LocatableDiagnostic _readFailure(
    String name,
    _FoundInstead foundInstead,
    ReadPosition position,
  ) {
    switch (foundInstead) {
      case _FoundNothing():
        return diag.undefinedSuperMemberReadNotFound.withArguments(
          name: name,
          type: type,
        );
      case _FoundPrivate(:var libraryUri):
        return diag.undefinedSuperMemberReadPrivate.withArguments(
          name: name,
          libraryUri: libraryUri,
        );
      case _FoundDeclaration(:var element):
        assert(element is SetterElement);
        return diag.undefinedSuperMemberReadSetterOnly.withArguments(
          name: name,
          type: type,
        );
    }
  }

  @override
  LocatableDiagnostic? _writeFailure(String name, _FoundInstead foundInstead) {
    switch (foundInstead) {
      case _FoundNothing():
        return diag.undefinedSuperMemberWriteNotFound.withArguments(
          name: name,
          type: type,
        );
      case _FoundPrivate(:var libraryUri):
        return diag.undefinedSuperMemberWritePrivate.withArguments(
          name: name,
          libraryUri: libraryUri,
        );
      case _FoundDeclaration(element: GetterElement(:var variable)):
        if (_isInvalidInstanceField(variable)) {
          return null;
        } else if (variable is FieldElement &&
            variable.isFinal &&
            (variable.isOriginDeclaration ||
                variable.isOriginDeclaringFormalParameter)) {
          return diag.undefinedSuperMemberWriteFinal.withArguments(
            name: name,
            type: type,
          );
        } else {
          // There is no setter in the interface that `super` has. Either no
          // superclass declares one, or the setters that the interface would
          // combine conflict, which can drop the setter of a non-final field
          // too.
          return diag.undefinedSuperMemberWriteGetterOnly.withArguments(
            name: name,
            type: type,
          );
        }
      case _FoundDeclaration(:var element):
        return diag.undefinedSuperMemberWriteWrongKind.withArguments(
          kind: _displayKindOf(element),
          name: name,
          type: type,
        );
    }
  }
}

/// A lookup of a name in the lexical scope.
///
/// For example, `foo` and `foo = 0`. Inside an instance declaration, the
/// scope includes its members, which are found through an implicit `this`.
final class UnqualifiedLookupDomain extends LookupDomain {
  @override
  bool _isIgnored(LibraryFragmentImpl libraryFragment, String name) {
    return libraryFragment.shouldIgnoreUndefined(prefix: null, name: name);
  }

  @override
  LocatableDiagnostic _readFailure(
    String name,
    _FoundInstead foundInstead,
    ReadPosition position,
  ) {
    switch (foundInstead) {
      case _FoundNothing():
      // The lookup doesn't find private names of other libraries.
      case _FoundPrivate():
        var code = switch (position) {
          ReadPosition.annotation =>
            diag.undefinedUnqualifiedNameReadNotFoundAnnotation,
          ReadPosition.constant =>
            diag.undefinedUnqualifiedNameReadNotFoundConstant,
          ReadPosition.other => diag.undefinedUnqualifiedNameReadNotFound,
        };
        return code.withArguments(name: name);
      case _FoundDeclaration():
        // Only a setter, possibly ambiguous, can be found instead of a getter.
        return diag.undefinedUnqualifiedNameReadSetterOnly.withArguments(
          name: name,
        );
    }
  }

  @override
  LocatableDiagnostic? _writeFailure(String name, _FoundInstead foundInstead) {
    switch (foundInstead) {
      case _FoundNothing():
      // The lookup doesn't find private names of other libraries.
      case _FoundPrivate():
        return diag.undefinedUnqualifiedNameWriteNotFound.withArguments(
          name: name,
        );
      case _FoundDeclaration(element: PrefixElement(name: var prefixName?)):
        return diag.prefixIdentifierNotFollowedByDot.withArguments(
          name: prefixName,
        );
      case _FoundDeclaration(element: PrefixElement()):
        return null;
      case _FoundDeclaration(element: MultiplyDefinedElement()):
        // Reported as an ambiguous import by the caller.
        return null;
      case _FoundDeclaration(element: GetterElement(:var variable)):
        if (_isInvalidInstanceField(variable)) {
          return null;
        } else if (variable.isConst) {
          return diag.undefinedUnqualifiedNameWriteConst.withArguments(
            name: name,
          );
        } else if (variable.isOriginGetterSetter) {
          return diag.undefinedUnqualifiedNameWriteGetterOnly.withArguments(
            name: name,
          );
        } else {
          return diag.undefinedUnqualifiedNameWriteFinal.withArguments(
            name: name,
          );
        }
      case _FoundDeclaration(element: VariableElement(isConst: true)):
        return diag.undefinedUnqualifiedNameWriteConst.withArguments(
          name: name,
        );
      case _FoundDeclaration(:var element):
        return diag.undefinedUnqualifiedNameWriteWrongKind.withArguments(
          kind: _displayKindOf(element),
          name: name,
        );
    }
  }
}

/// A declaration that has the name, but not the required capability, such as
/// a setter for a read, or a getter for a write.
final class _FoundDeclaration extends _FoundInstead {
  final Element element;

  new(this.element);
}

/// What a failed lookup found instead of a declaration with the required
/// capability.
sealed class _FoundInstead {
  const new();

  /// What a lookup in [library] found instead: the [element] that the caller
  /// found, or nothing if it is `null`.
  factory of(Element? element, LibraryElement library) {
    if (element == null) {
      return const _FoundNothing();
    } else if (element.isPrivate && element.library != library) {
      return _FoundPrivate(element);
    } else {
      return _FoundDeclaration(element);
    }
  }
}

/// Nothing that has the name.
final class _FoundNothing extends _FoundInstead {
  const new();
}

/// A private declaration of another library that has the name, which is
/// visible only in its own library.
final class _FoundPrivate extends _FoundInstead {
  final Element element;

  new(this.element);

  /// The URI of the library that declares the [element].
  Uri get libraryUri => element.library!.uri;
}
