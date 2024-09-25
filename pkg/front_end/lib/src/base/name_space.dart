// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/name_iterator.dart';
import '../dill/dill_library_builder.dart';
import 'scope.dart';

abstract class NameSpace {
  void addLocalMember(String name, Builder member, {required bool setter});

  /// Adds [builder] to the extensions in this name space.
  void addExtension(ExtensionBuilder builder);

  Builder? lookupLocalMember(String name, {required bool setter});

  void forEachLocalMember(void Function(String name, Builder member) f);

  void forEachLocalSetter(void Function(String name, MemberBuilder member) f);

  void forEachLocalExtension(void Function(ExtensionBuilder member) f);

  Iterable<Builder> get localMembers;

  /// Returns an iterator of all members and setters mapped in this name space,
  /// including duplicate members mapped to the same name.
  Iterator<Builder> get unfilteredIterator;

  /// Returns an iterator of all members and setters mapped in this name space,
  /// including duplicate members mapped to the same name.
  ///
  /// Compared to [unfilteredIterator] this iterator also gives access to the
  /// name that the builders are mapped to.
  NameIterator get unfilteredNameIterator;

  /// Returns a filtered iterator of members and setters mapped in this name
  /// space.
  ///
  /// Only members of type [T] are included. If [parent] is provided, on members
  /// declared in [parent] are included. If [includeDuplicates] is `true`, all
  /// duplicates of the same name are included, otherwise, only the first
  /// declared member is included. If [includeAugmentations] is `true`, both
  /// original and augmenting/patching members are included, otherwise, only
  /// original members are included.
  Iterator<T> filteredIterator<T extends Builder>(
      {Builder? parent,
      required bool includeDuplicates,
      required bool includeAugmentations});

  /// Returns a filtered iterator of members and setters mapped in this name
  /// space.
  ///
  /// Only members of type [T] are included. If [parent] is provided, on members
  /// declared in [parent] are included. If [includeDuplicates] is `true`, all
  /// duplicates of the same name are included, otherwise, only the first
  /// declared member is included. If [includeAugmentations] is `true`, both
  /// original and augmenting/patching members are included, otherwise, only
  /// original members are included.
  ///
  /// Compared to [filteredIterator] this iterator also gives access to the
  /// name that the builders are mapped to.
  NameIterator<T> filteredNameIterator<T extends Builder>(
      {Builder? parent,
      required bool includeDuplicates,
      required bool includeAugmentations});
}

abstract class DeclarationNameSpace implements NameSpace {
  MemberBuilder? lookupConstructor(String name);

  void addConstructor(String name, MemberBuilder builder);

  void forEachConstructor(void Function(String, MemberBuilder) f);

  /// Returns an iterator of all constructors mapped in this scope,
  /// including duplicate constructors mapped to the same name.
  Iterator<MemberBuilder> get unfilteredConstructorIterator;

  /// Returns an iterator of all constructors mapped in this scope,
  /// including duplicate constructors mapped to the same name.
  ///
  /// Compared to [unfilteredConstructorIterator] this iterator also gives
  /// access to the name that the builders are mapped to.
  NameIterator<MemberBuilder> get unfilteredConstructorNameIterator;

  /// Returns a filtered iterator of constructors mapped in this scope.
  ///
  /// Only members of type [T] are included. If [parent] is provided, on members
  /// declared in [parent] are included. If [includeDuplicates] is `true`, all
  /// duplicates of the same name are included, otherwise, only the first
  /// declared member is included. If [includeAugmentations] is `true`, both
  /// original and augmenting/patching members are included, otherwise, only
  /// original members are included.
  Iterator<T> filteredConstructorIterator<T extends MemberBuilder>(
      {Builder? parent,
      required bool includeDuplicates,
      required bool includeAugmentations});

  /// Returns a filtered iterator of constructors mapped in this scope.
  ///
  /// Only members of type [T] are included. If [parent] is provided, on members
  /// declared in [parent] are included. If [includeDuplicates] is `true`, all
  /// duplicates of the same name are included, otherwise, only the first
  /// declared member is included. If [includeAugmentations] is `true`, both
  /// original and augmenting/patching members are included, otherwise, only
  /// original members are included.
  ///
  /// Compared to [filteredConstructorIterator] this iterator also gives access
  /// to the name that the builders are mapped to.
  NameIterator<T> filteredConstructorNameIterator<T extends MemberBuilder>(
      {Builder? parent,
      required bool includeDuplicates,
      required bool includeAugmentations});
}

class NameSpaceImpl implements NameSpace {
  Map<String, Builder>? _getables;
  Map<String, MemberBuilder>? _setables;
  Set<ExtensionBuilder>? _extensions;

  NameSpaceImpl(
      {Map<String, Builder>? getables,
      Map<String, MemberBuilder>? setables,
      Set<ExtensionBuilder>? extensions})
      : _getables = getables,
        _setables = setables,
        _extensions = extensions;

  @override
  void addLocalMember(String name, Builder member, {required bool setter}) {
    if (setter) {
      (_setables ??= {})[name] = member as MemberBuilder;
    } else {
      (_getables ??= {})[name] = member;
    }
  }

  @override
  void addExtension(ExtensionBuilder builder) {
    (_extensions ??= {}).add(builder);
  }

  @override
  Iterator<T> filteredIterator<T extends Builder>(
      {Builder? parent,
      required bool includeDuplicates,
      required bool includeAugmentations}) {
    return new FilteredIterator<T>(unfilteredIterator,
        parent: parent,
        includeDuplicates: includeDuplicates,
        includeAugmentations: includeAugmentations);
  }

  @override
  NameIterator<T> filteredNameIterator<T extends Builder>(
      {Builder? parent,
      required bool includeDuplicates,
      required bool includeAugmentations}) {
    return new FilteredNameIterator<T>(unfilteredNameIterator,
        parent: parent,
        includeDuplicates: includeDuplicates,
        includeAugmentations: includeAugmentations);
  }

  @override
  void forEachLocalExtension(void Function(ExtensionBuilder member) f) {
    _extensions?.forEach(f);
  }

  @override
  void forEachLocalMember(void Function(String name, Builder member) f) {
    if (_getables != null) {
      for (MapEntry<String, Builder> entry in _getables!.entries) {
        f(entry.key, entry.value);
      }
    }
  }

  @override
  void forEachLocalSetter(void Function(String name, MemberBuilder member) f) {
    if (_setables != null) {
      for (MapEntry<String, MemberBuilder> entry in _setables!.entries) {
        f(entry.key, entry.value);
      }
    }
  }

  @override
  Iterable<Builder> get localMembers => _getables?.values ?? const [];

  @override
  Builder? lookupLocalMember(String name, {required bool setter}) {
    Map<String, Builder>? map = setter ? _setables : _getables;
    return map?[name];
  }

  @override
  Iterator<Builder> get unfilteredIterator => new ScopeIterator(
      _getables?.values.iterator,
      _setables?.values.iterator,
      _extensions?.iterator);

  @override
  NameIterator<Builder> get unfilteredNameIterator =>
      new ScopeNameIterator(_getables, _setables, _extensions?.iterator);
}

class DeclarationNameSpaceImpl extends NameSpaceImpl
    implements DeclarationNameSpace {
  Map<String, MemberBuilder>? _constructors;

  DeclarationNameSpaceImpl(
      {super.getables,
      super.setables,
      super.extensions,
      Map<String, MemberBuilder>? constructors})
      : _constructors = constructors;

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
  NameIterator<MemberBuilder> get unfilteredConstructorNameIterator =>
      new ConstructorNameSpaceNameIterator(
          _constructors?.keys.iterator, _constructors?.values.iterator);

  @override
  Iterator<T> filteredConstructorIterator<T extends MemberBuilder>(
      {Builder? parent,
      required bool includeDuplicates,
      required bool includeAugmentations}) {
    return new FilteredIterator<T>(unfilteredConstructorIterator,
        parent: parent,
        includeDuplicates: includeDuplicates,
        includeAugmentations: includeAugmentations);
  }

  @override
  NameIterator<T> filteredConstructorNameIterator<T extends MemberBuilder>(
      {Builder? parent,
      required bool includeDuplicates,
      required bool includeAugmentations}) {
    return new FilteredNameIterator<T>(unfilteredConstructorNameIterator,
        parent: parent,
        includeDuplicates: includeDuplicates,
        includeAugmentations: includeAugmentations);
  }

  @override
  void forEachConstructor(void Function(String, MemberBuilder) f) {
    _constructors?.forEach(f);
  }
}

abstract class LazyNameSpace extends NameSpaceImpl {
  /// Override this method to lazily populate the scope before access.
  void ensureNameSpace();

  @override
  Map<String, Builder>? get _getables {
    ensureNameSpace();
    return super._getables;
  }

  @override
  Map<String, MemberBuilder>? get _setables {
    ensureNameSpace();
    return super._setables;
  }

  @override
  Set<ExtensionBuilder>? get _extensions {
    ensureNameSpace();
    return super._extensions;
  }
}

class DillLibraryNameSpace extends LazyNameSpace {
  final DillLibraryBuilder _libraryBuilder;

  DillLibraryNameSpace(this._libraryBuilder);

  @override
  void ensureNameSpace() {
    _libraryBuilder.ensureLoaded();
  }
}

class DillExportNameSpace extends LazyNameSpace {
  final DillLibraryBuilder _libraryBuilder;

  DillExportNameSpace(this._libraryBuilder);

  @override
  void ensureNameSpace() {
    _libraryBuilder.ensureLoaded();
  }

  /// Patch up the scope, using the two replacement maps to replace builders in
  /// scope. The replacement maps from old LibraryBuilder to map, mapping
  /// from name to new (replacement) builder.
  void patchUpScope(Map<LibraryBuilder, Map<String, Builder>> replacementMap,
      Map<LibraryBuilder, Map<String, Builder>> replacementMapSetters) {
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
        Builder? existingGetter = _getables?[name];
        LibraryBuilder? replacementLibraryBuilderFromGetter;
        Builder? replacementGetterFromGetter;
        Builder? replacementSetterFromGetter;
        if (existingGetter != null &&
            replacementMap.containsKey(existingGetter.parent)) {
          replacementLibraryBuilderFromGetter =
              existingGetter.parent as LibraryBuilder;
          replacementGetterFromGetter =
              replacementMap[replacementLibraryBuilderFromGetter]![name];
          replacementSetterFromGetter =
              replacementMapSetters[replacementLibraryBuilderFromGetter]![name];
        }
        Builder? existingSetter = _setables?[name];
        LibraryBuilder? replacementLibraryBuilderFromSetter;
        Builder? replacementGetterFromSetter;
        Builder? replacementSetterFromSetter;
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
