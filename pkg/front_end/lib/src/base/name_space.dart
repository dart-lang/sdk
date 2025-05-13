// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/property_builder.dart';
import '../dill/dill_library_builder.dart';
import 'lookup_result.dart';
import 'scope.dart';
import 'uris.dart';

abstract class NameSpace {
  /// Returns the [LookupResult] for the [Builder]s of the given [name] in the
  /// name space.
  ///
  /// If [staticOnly] is `true`, instance members are not returned.
  ///
  /// If the [Builder]s are duplicates, an [AmbiguousBuilder] is created for
  /// the access, using the [fileUri] and [fileOffset].
  LookupResult? lookupLocal(String name,
      {required Uri fileUri,
      required int fileOffset,
      required bool staticOnly});

  /// Returns the [LookupResult] for the [Builder]s of the given [name] in the
  /// name space.
  ///
  /// The returned [LookupResult] contains the [Builder]s directly mapped in the
  /// name space without any filtering or processed of duplicates.
  LookupResult? lookupLocalMember(String name);

  void forEachLocalExtension(void Function(ExtensionBuilder member) f);

  /// Returns an iterator of all members and setters mapped in this name space,
  /// including duplicate members mapped to the same name.
  Iterator<NamedBuilder> get unfilteredIterator;

  /// Returns a filtered iterator of members and setters mapped in this name
  /// space.
  ///
  /// Only members of type [T] are included. If [parent] is provided, on members
  /// declared in [parent] are included. If [includeDuplicates] is `true`, all
  /// duplicates of the same name are included, otherwise, only the first
  /// declared member is included.
  Iterator<T> filteredIterator<T extends NamedBuilder>(
      {required bool includeDuplicates});
}

abstract class MutableNameSpace implements NameSpace {
  factory MutableNameSpace() = NameSpaceImpl._;

  void addLocalMember(String name, NamedBuilder member, {required bool setter});

  /// Adds [builder] to the extensions in this name space.
  void addExtension(ExtensionBuilder builder);
}

abstract class DeclarationNameSpace implements NameSpace {
  MemberBuilder? lookupConstructor(String name);

  /// Returns an iterator of all constructors mapped in this scope,
  /// including duplicate constructors mapped to the same name.
  Iterator<MemberBuilder> get unfilteredConstructorIterator;

  /// Returns a filtered iterator of constructors mapped in this scope.
  ///
  /// Only members of type [T] are included. If [parent] is provided, on members
  /// declared in [parent] are included. If [includeDuplicates] is `true`, all
  /// duplicates of the same name are included, otherwise, only the first
  /// declared member is included.
  Iterator<T> filteredConstructorIterator<T extends MemberBuilder>(
      {required bool includeDuplicates});
}

abstract class MutableDeclarationNameSpace
    implements DeclarationNameSpace, MutableNameSpace {
  void addConstructor(String name, MemberBuilder builder);
}

base class NameSpaceImpl implements NameSpace, MutableNameSpace {
  Map<String, NamedBuilder>? _getables;
  Map<String, NamedBuilder>? _setables;
  Set<ExtensionBuilder>? _extensions;

  NameSpaceImpl._(
      {Map<String, NamedBuilder>? getables,
      Map<String, NamedBuilder>? setables,
      Set<ExtensionBuilder>? extensions})
      : _getables = getables,
        _setables = setables,
        _extensions = extensions;

  @override
  void addLocalMember(String name, NamedBuilder member,
      {required bool setter}) {
    if (setter) {
      (_setables ??= {})[name] = member;
    } else {
      (_getables ??= {})[name] = member;
    }
  }

  @override
  void addExtension(ExtensionBuilder builder) {
    (_extensions ??= {}).add(builder);
  }

  @override
  Iterator<T> filteredIterator<T extends NamedBuilder>(
      {required bool includeDuplicates}) {
    return new FilteredIterator<T>(unfilteredIterator,
        includeDuplicates: includeDuplicates);
  }

  @override
  void forEachLocalExtension(void Function(ExtensionBuilder member) f) {
    _extensions?.forEach(f);
  }

  @override
  LookupResult? lookupLocal(String name,
      {required Uri fileUri,
      required int fileOffset,
      required bool staticOnly}) {
    NamedBuilder? getable = _getables?[name];
    NamedBuilder? setable = _setables?[name];
    return LookupResult.createProcessedResult(getable, setable,
        name: name,
        fileUri: fileUri,
        fileOffset: fileOffset,
        staticOnly: staticOnly);
  }

  @override
  LookupResult? lookupLocalMember(String name) {
    return LookupResult.createResult(_getables?[name], _setables?[name]);
  }

  @override
  Iterator<NamedBuilder> get unfilteredIterator => new ScopeIterator(
      _getables?.values.iterator,
      _setables?.values.iterator,
      _extensions?.iterator);
}

final class SourceLibraryNameSpace extends NameSpaceImpl {
  SourceLibraryNameSpace(
      {required Map<String, NamedBuilder> super.getables,
      required Map<String, NamedBuilder> super.setables,
      required Set<ExtensionBuilder> super.extensions})
      : super._();
}

// Coverage-ignore(suite): Not run.
/// Returns a string with an error message if [sourceNameSpace] and
/// [dillNameSpace] are not equivalent.
///
/// This should be used for assertions only.
String? areNameSpacesEquivalent(
    {required Uri importUri,
    required NameSpace sourceNameSpace,
    required NameSpace dillNameSpace}) {
  sourceNameSpace as NameSpaceImpl;
  dillNameSpace as NameSpaceImpl;

  Map<String, NamedBuilder>? sourceGetables = sourceNameSpace._getables;
  Map<String, NamedBuilder>? sourceSetables = sourceNameSpace._setables;

  Map<String, NamedBuilder>? dillGetables = dillNameSpace._getables;
  Map<String, NamedBuilder>? dillSetables = dillNameSpace._setables;

  bool isEquivalent = true;
  StringBuffer sb = new StringBuffer();
  sb.writeln('Mismatch on ${importUri}:');
  if (sourceGetables != null) {
    for (MapEntry<String, NamedBuilder> sourceEntry in sourceGetables.entries) {
      Builder? dillBuilder = dillGetables?[sourceEntry.key];
      if (dillBuilder == null) {
        if ((sourceEntry.key == 'dynamic' || sourceEntry.key == 'Never') &&
            importUri == dartCore) {
          // The source library builder for dart:core has synthetically
          // injected builders for `dynamic` and `Never` which do not have
          // corresponding classes in the AST.
          continue;
        }
        sb.writeln(
            'No dill builder for ${sourceEntry.key}: ${sourceEntry.value}');
        isEquivalent = false;
      }
    }
  }
  if (dillGetables != null) {
    for (MapEntry<String, NamedBuilder> dillEntry in dillGetables.entries) {
      Builder? sourceBuilder = sourceGetables?[dillEntry.key];
      if (sourceBuilder == null) {
        sb.writeln(
            'No source builder for ${dillEntry.key}: ${dillEntry.value}');
        isEquivalent = false;
      }
    }
  }
  if (sourceSetables != null) {
    for (MapEntry<String, NamedBuilder> sourceEntry in sourceSetables.entries) {
      Builder? dillBuilder = dillGetables?[sourceEntry.key];
      if (dillBuilder == null) {
        sb.writeln(
            'No dill builder for ${sourceEntry.key}=: ${sourceEntry.value}');
        isEquivalent = false;
      }
    }
  }
  if (dillSetables != null) {
    for (MapEntry<String, NamedBuilder> dillEntry in dillSetables.entries) {
      Builder? sourceBuilder = sourceSetables?[dillEntry.key];
      if (sourceBuilder == null) {
        sourceBuilder = sourceGetables?[dillEntry.key];
        if (sourceBuilder is PropertyBuilder && sourceBuilder.hasSetter) {
          // Assignable fields can be lowered into a getter and setter.
          continue;
        }
        sb.writeln(
            'No source builder for ${dillEntry.key}=: ${dillEntry.value}');
        isEquivalent = false;
      }
    }
  }
  if (isEquivalent) {
    return null;
  }
  return sb.toString();
}

abstract base class DeclarationNameSpaceBase extends NameSpaceImpl
    implements DeclarationNameSpace, MutableDeclarationNameSpace {
  Map<String, MemberBuilder>? _constructors;

  DeclarationNameSpaceBase._(
      {super.getables,
      super.setables,
      super.extensions,
      Map<String, MemberBuilder>? constructors})
      : _constructors = constructors,
        super._();

  @override
  void addConstructor(String name, MemberBuilder builder) {
    (_constructors ??= {})[name] = builder;
  }

  @override
  MemberBuilder? lookupConstructor(String name) => _constructors?[name];

  /// Returns an iterator of all constructors mapped in this scope,
  /// including duplicate constructors mapped to the same name.
  @override
  Iterator<MemberBuilder> get unfilteredConstructorIterator =>
      new ConstructorNameSpaceIterator(_constructors?.values.iterator);

  @override
  Iterator<T> filteredConstructorIterator<T extends MemberBuilder>(
      {required bool includeDuplicates}) {
    return new FilteredIterator<T>(unfilteredConstructorIterator,
        includeDuplicates: includeDuplicates);
  }
}

final class SourceDeclarationNameSpace extends DeclarationNameSpaceBase {
  SourceDeclarationNameSpace(
      {required Map<String, NamedBuilder> super.getables,
      required Map<String, NamedBuilder> super.setables,
      required Map<String, MemberBuilder>? super.constructors})
      : super._();
}

final class DillDeclarationNameSpace extends DeclarationNameSpaceBase {
  DillDeclarationNameSpace() : super._();
}

abstract base class LazyNameSpace extends NameSpaceImpl {
  LazyNameSpace() : super._();

  /// Override this method to lazily populate the scope before access.
  void ensureNameSpace();

  @override
  Map<String, NamedBuilder>? get _getables {
    ensureNameSpace();
    return super._getables;
  }

  @override
  Map<String, NamedBuilder>? get _setables {
    ensureNameSpace();
    return super._setables;
  }

  @override
  Set<ExtensionBuilder>? get _extensions {
    ensureNameSpace();
    return super._extensions;
  }
}

final class DillLibraryNameSpace extends LazyNameSpace {
  final DillLibraryBuilder _libraryBuilder;

  DillLibraryNameSpace(this._libraryBuilder);

  @override
  void ensureNameSpace() {
    _libraryBuilder.ensureLoaded();
  }
}

final class DillExportNameSpace extends LazyNameSpace {
  final DillLibraryBuilder _libraryBuilder;

  DillExportNameSpace(this._libraryBuilder);

  @override
  void ensureNameSpace() {
    _libraryBuilder.ensureLoaded();
  }

  /// Patch up the scope, using the two replacement maps to replace builders in
  /// scope. The replacement maps from old LibraryBuilder to map, mapping
  /// from name to new (replacement) builder.
  void patchUpScope(
      Map<LibraryBuilder, Map<String, NamedBuilder>> replacementMap,
      Map<LibraryBuilder, Map<String, NamedBuilder>> replacementMapSetters) {
    // In the following we refer to non-setters as 'getters' for brevity.
    //
    // We have to replace all getters and setters in [_locals] and [_setters]
    // with the corresponding getters and setters in [replacementMap]
    // and [replacementMapSetters].
    //
    // Since field builders can be replaced by getter and setter builders and
    // vice versa when going from source to dill builder and back, we might not
    // have a 1-to-1 relationship between the existing and replacing builders.
    //
    // For this reason we start by collecting the names of all getters/setters
    // that need (some) replacement. Afterwards we go through these names
    // handling both getters and setters at the same time.
    Set<String> replacedNames = {};
    _getables?.forEach((String name, Builder builder) {
      if (replacementMap.containsKey(builder.parent)) {
        replacedNames.add(name);
      }
    });
    _setables?.forEach((String name, Builder builder) {
      if (replacementMapSetters.containsKey(builder.parent)) {
        replacedNames.add(name);
      }
    });
    if (replacedNames.isNotEmpty) {
      for (String name in replacedNames) {
        // We start be collecting the relation between an existing getter/setter
        // and the getter/setter that will replace it. This information is used
        // below to handle all the different cases that can occur.
        NamedBuilder? existingGetter = _getables?[name];
        LibraryBuilder? replacementLibraryBuilderFromGetter;
        NamedBuilder? replacementGetterFromGetter;
        NamedBuilder? replacementSetterFromGetter;
        if (existingGetter != null &&
            replacementMap.containsKey(existingGetter.parent)) {
          replacementLibraryBuilderFromGetter =
              existingGetter.parent as LibraryBuilder;
          replacementGetterFromGetter =
              replacementMap[replacementLibraryBuilderFromGetter]![name];
          replacementSetterFromGetter =
              replacementMapSetters[replacementLibraryBuilderFromGetter]![name];
        }
        NamedBuilder? existingSetter = _setables?[name];
        LibraryBuilder? replacementLibraryBuilderFromSetter;
        NamedBuilder? replacementGetterFromSetter;
        NamedBuilder? replacementSetterFromSetter;
        if (existingSetter != null &&
            replacementMap.containsKey(existingSetter.parent)) {
          replacementLibraryBuilderFromSetter =
              existingSetter.parent as LibraryBuilder;
          replacementGetterFromSetter =
              replacementMap[replacementLibraryBuilderFromSetter]![name];
          replacementSetterFromSetter =
              replacementMapSetters[replacementLibraryBuilderFromSetter]![name];
        }

        if (existingGetter == null) {
          // Coverage-ignore-block(suite): Not run.
          // No existing getter.
          if (replacementGetterFromSetter != null) {
            // We might have had one implicitly from the setter. Use it here,
            // if so. (This is currently not possible, but added to match the
            // case for setters below.)
            (_getables ??= {})[name] = replacementGetterFromSetter;
          }
        } else if (existingGetter.parent ==
            replacementLibraryBuilderFromGetter) {
          // The existing getter should be replaced.
          if (replacementGetterFromGetter != null) {
            // With a new getter.
            (_getables ??= // Coverage-ignore(suite): Not run.
                {})[name] = replacementGetterFromGetter;
          } else {
            // Coverage-ignore-block(suite): Not run.
            // With `null`, i.e. removed. This means that the getter is
            // implicitly available through the setter. (This is currently not
            // possible, but handled here to match the case for setters below).
            _getables?.remove(name);
          }
        } else {
          // Leave the getter in - it wasn't replaced.
        }
        if (existingSetter == null) {
          // No existing setter.
          if (replacementSetterFromGetter != null) {
            // We might have had one implicitly from the getter. Use it here,
            // if so.
            (_setables ??= // Coverage-ignore(suite): Not run.
                {})[name] = replacementSetterFromGetter as MemberBuilder;
          }
        } else if (existingSetter.parent ==
            replacementLibraryBuilderFromSetter) {
          // The existing setter should be replaced.
          if (replacementSetterFromSetter != null) {
            // With a new setter.
            (_setables ??= // Coverage-ignore(suite): Not run.
                {})[name] = replacementSetterFromSetter as MemberBuilder;
          } else {
            // With `null`, i.e. removed. This means that the setter is
            // implicitly available through the getter. This happens when the
            // getter is a field builder for an assignable field.
            _setables?.remove(name);
          }
        } else {
          // Leave the setter in - it wasn't replaced.
        }
      }
    }
    if (_extensions != null) {
      // Coverage-ignore-block(suite): Not run.
      bool needsPatching = false;
      for (ExtensionBuilder extensionBuilder in _extensions!) {
        if (replacementMap.containsKey(extensionBuilder.libraryBuilder)) {
          needsPatching = true;
          break;
        }
      }
      if (needsPatching) {
        Set<ExtensionBuilder> extensionsReplacement =
            new Set<ExtensionBuilder>();
        for (ExtensionBuilder extensionBuilder in _extensions!) {
          if (replacementMap.containsKey(extensionBuilder.libraryBuilder)) {
            assert(replacementMap[extensionBuilder.libraryBuilder]![
                    extensionBuilder.name] !=
                null);
            extensionsReplacement.add(replacementMap[extensionBuilder
                .libraryBuilder]![extensionBuilder.name] as ExtensionBuilder);
            break;
          } else {
            extensionsReplacement.add(extensionBuilder);
          }
        }
        _extensions!.clear();
        extensionsReplacement.addAll(extensionsReplacement);
      }
    }
  }
}
