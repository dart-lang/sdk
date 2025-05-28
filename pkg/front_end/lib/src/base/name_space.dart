// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
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
}

abstract class MutableNameSpace implements NameSpace {
  void addLocalMember(String name, NamedBuilder member, {required bool setter});
}

abstract class ComputedNameSpace implements NameSpace {
  /// Returns a filtered iterator of members and setters mapped in this name
  /// space.
  ///
  /// Only members of type [T] are included. If [parent] is provided, on members
  /// declared in [parent] are included. Duplicates are not included.
  Iterator<T> filteredIterator<T extends NamedBuilder>();
}

abstract class ComputedMutableNameSpace
    implements MutableNameSpace, ComputedNameSpace {
  factory ComputedMutableNameSpace() = ComputedMutableNameSpaceImpl._;

  /// Adds [builder] to the extensions in this name space.
  void addExtension(ExtensionBuilder builder);

  void replaceLocalMember(String name, NamedBuilder member,
      {required bool setter});
}

abstract class DeclarationNameSpace implements NameSpace {
  MemberBuilder? lookupConstructor(String name);
}

abstract class MutableDeclarationNameSpace
    implements DeclarationNameSpace, MutableNameSpace {
  void addConstructor(String name, MemberBuilder builder);
}

base class NameSpaceImpl implements MutableNameSpace {
  Map<String, LookupResult>? _content;
  Set<ExtensionBuilder>? _extensions;

  NameSpaceImpl._(
      {Map<String, LookupResult>? content, Set<ExtensionBuilder>? extensions})
      : _content = content,
        _extensions = extensions;

  @override
  void addLocalMember(String name, NamedBuilder member,
      {required bool setter}) {
    LookupResult.addNamedBuilder(_content ??= {}, name, member, setter: setter);
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
    return LookupResult.createProcessedResult(_content?[name],
        name: name,
        fileUri: fileUri,
        fileOffset: fileOffset,
        staticOnly: staticOnly);
  }

  @override
  LookupResult? lookupLocalMember(String name) => _content?[name];
}

base class ComputedMutableNameSpaceImpl implements ComputedMutableNameSpace {
  Map<String, LookupResult>? _content;
  Set<ExtensionBuilder>? _extensions;

  ComputedMutableNameSpaceImpl._();

  @override
  void addLocalMember(String name, NamedBuilder member,
      {required bool setter}) {
    Map<String, LookupResult> content = _content ??= {};
    LookupResult? existing = content[name];
    if (existing != null) {
      if (setter) {
        assert(
            existing.setable == null ||
                // Coverage-ignore(suite): Not run.
                existing.setable == member,
            "Trying to map setable $member to $name "
            "replacing the existing value ${existing.setable}");
        if (existing.getable != null) {
          content[name] = new GetableSetableResult(existing.getable!, member);
          return;
        }
      } else {
        assert(
            existing.getable == null || existing.getable == member,
            "Trying to map getable $member to $name "
            "replacing the existing value ${existing.getable}");
        if (existing.setable != null) {
          content[name] = new GetableSetableResult(member, existing.setable!);
          return;
        }
      }
    }
    if (member is LookupResult) {
      content[name] = member as LookupResult;
    } else {
      content[name] = setter
          ?
          // Coverage-ignore(suite): Not run.
          new SetableResult(member)
          : new GetableResult(member);
    }
  }

  @override
  void replaceLocalMember(String name, NamedBuilder member,
      {required bool setter}) {
    Map<String, LookupResult> content = _content!;
    LookupResult? existing = content[name];
    assert(existing != null, "No existing result for $name.");
    if (existing != null) {
      if (setter) {
        assert(
            existing.setable != null,
            "Trying to map setable $member to $name "
            "replacing the existing value ${existing.setable}");
        if (existing.getable != null) {
          // Coverage-ignore-block(suite): Not run.
          content[name] = new GetableSetableResult(existing.getable!, member);
          return;
        }
      } else {
        assert(
            existing.getable != null,
            "Trying to map setable $member to $name "
            "replacing the existing value ${existing.getable}");
        if (existing.setable != null) {
          content[name] = new GetableSetableResult(member, existing.setable!);
          return;
        }
      }
    }
    if (member is LookupResult) {
      content[name] = member as LookupResult;
    } else {
      // Coverage-ignore-block(suite): Not run.
      content[name] =
          setter ? new SetableResult(member) : new GetableResult(member);
    }
  }

  @override
  void addExtension(ExtensionBuilder builder) {
    (_extensions ??= {}).add(builder);
  }

  @override
  Iterator<T> filteredIterator<T extends NamedBuilder>() {
    return new FilteredIterator<T>(
        new LookupResultIterator(
            _content?.values.iterator,
            _extensions
                // Coverage-ignore(suite): Not run.
                ?.iterator),
        includeDuplicates: false);
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
    return LookupResult.createProcessedResult(_content?[name],
        name: name,
        fileUri: fileUri,
        fileOffset: fileOffset,
        staticOnly: staticOnly);
  }

  @override
  LookupResult? lookupLocalMember(String name) => _content?[name];
}

final class SourceLibraryNameSpace extends NameSpaceImpl {
  SourceLibraryNameSpace(
      {required Map<String, LookupResult> super.content,
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
  sourceNameSpace as ComputedMutableNameSpaceImpl;
  dillNameSpace as ComputedMutableNameSpaceImpl;

  bool isEquivalent = true;
  StringBuffer sb = new StringBuffer();
  sb.writeln('Mismatch on ${importUri}:');

  Map<String, LookupResult>? sourceContent = sourceNameSpace._content;
  Map<String, LookupResult>? dillContent = dillNameSpace._content;

  if (sourceContent != null) {
    for (MapEntry<String, LookupResult> sourceEntry in sourceContent.entries) {
      LookupResult sourceResult = sourceEntry.value;
      LookupResult? dillResult = dillContent?[sourceEntry.key];
      if (sourceResult.getable != null) {
        if (dillResult?.getable == null) {
          if ((sourceEntry.key == 'dynamic' || sourceEntry.key == 'Never') &&
              importUri == dartCore) {
            // The source library builder for dart:core has synthetically
            // injected builders for `dynamic` and `Never` which do not have
            // corresponding classes in the AST.
          } else {
            sb.writeln(
                'No dill getable for ${sourceEntry.key}: ${sourceResult}');
            isEquivalent = false;
          }
        }
      }
      if (sourceResult.setable != null) {
        if (dillResult?.setable == null) {
          sb.writeln('No dill setable for ${sourceEntry.key}: ${sourceResult}');
          isEquivalent = false;
        }
      }
    }
  }
  if (dillContent != null) {
    for (MapEntry<String, LookupResult> dillEntry in dillContent.entries) {
      LookupResult dillResult = dillEntry.value;
      LookupResult? sourceResult = sourceContent?[dillEntry.key];
      if (dillResult.getable != null) {
        if (sourceResult?.getable != null) {
          sb.writeln('No source getable for ${dillEntry.key}=: ${dillResult}');
          isEquivalent = false;
        }
      }
      if (dillResult.setable != null) {
        if (sourceResult?.setable != null) {
          sb.writeln('No source setable for ${dillEntry.key}=: ${dillResult}');
          isEquivalent = false;
        }
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
      {super.content,
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
}

final class SourceDeclarationNameSpace extends DeclarationNameSpaceBase {
  SourceDeclarationNameSpace(
      {required Map<String, LookupResult> super.content,
      required Map<String, MemberBuilder>? super.constructors})
      : super._();
}

final class DillDeclarationNameSpace extends DeclarationNameSpaceBase {
  DillDeclarationNameSpace() : super._();
}

final class DillLibraryNameSpace extends ComputedMutableNameSpaceImpl {
  DillLibraryNameSpace() : super._();
}

final class DillExportNameSpace extends ComputedMutableNameSpaceImpl {
  DillExportNameSpace() : super._();

  /// Patch up the scope, using the two replacement maps to replace builders in
  /// scope. The replacement maps from old LibraryBuilder to map, mapping
  /// from name to new (replacement) builder.
  void patchUpScope(Map<LibraryBuilder, NameSpace> replacementNameSpaceMap) {
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
    _content?.forEach((String name, LookupResult result) {
      if (replacementNameSpaceMap.containsKey(result.getable?.parent)) {
        replacedNames.add(name);
      }
      if (replacementNameSpaceMap.containsKey(result.setable?.parent)) {
        replacedNames.add(name);
      }
    });
    if (replacedNames.isNotEmpty) {
      for (String name in replacedNames) {
        // We start be collecting the relation between an existing getter/setter
        // and the getter/setter that will replace it. This information is used
        // below to handle all the different cases that can occur.
        LookupResult existingResult = _content![name]!;
        NamedBuilder? existingGetter = existingResult.getable;
        NamedBuilder? existingSetter = existingResult.setable;
        LookupResult? replacementResult;
        if (existingGetter != null && existingSetter != null) {
          if (existingGetter == existingSetter) {
            replacementResult = replacementNameSpaceMap[existingGetter.parent]!
                .lookupLocalMember(name);
          } else {
            NamedBuilder? replacementGetter =
                replacementNameSpaceMap[existingGetter.parent]
                    ?.lookupLocalMember(name)
                    ?.getable;
            NamedBuilder? replacementSetter =
                replacementNameSpaceMap[existingSetter.parent]
                    ?.lookupLocalMember(name)
                    ?.setable;
            replacementResult = LookupResult.createResult(
                replacementGetter ?? existingGetter,
                replacementSetter ?? existingSetter);
          }
        } else if (existingGetter != null) {
          replacementResult = LookupResult.createResult(
              replacementNameSpaceMap[existingGetter.parent]
                  ?.lookupLocalMember(name)
                  ?.getable,
              null);
        } else if (existingSetter != null) {
          replacementResult = LookupResult.createResult(
              null,
              replacementNameSpaceMap[existingSetter.parent]
                  ?.lookupLocalMember(name)
                  ?.setable);
        }
        if (replacementResult != null) {
          (_content ??= // Coverage-ignore(suite): Not run.
              {})[name] = replacementResult;
        } else {
          // Coverage-ignore-block(suite): Not run.
          _content?.remove(name);
        }
      }
    }

    if (_extensions != null) {
      // Coverage-ignore-block(suite): Not run.
      bool needsPatching = false;
      for (ExtensionBuilder extensionBuilder in _extensions!) {
        if (replacementNameSpaceMap
            .containsKey(extensionBuilder.libraryBuilder)) {
          needsPatching = true;
          break;
        }
      }
      if (needsPatching) {
        Set<ExtensionBuilder> extensionsReplacement =
            new Set<ExtensionBuilder>();
        for (ExtensionBuilder extensionBuilder in _extensions!) {
          if (replacementNameSpaceMap
              .containsKey(extensionBuilder.libraryBuilder)) {
            assert(replacementNameSpaceMap[extensionBuilder.libraryBuilder]!
                    .lookupLocalMember(extensionBuilder.name)!
                    .getable !=
                null);
            extensionsReplacement.add(
                replacementNameSpaceMap[extensionBuilder.libraryBuilder]!
                    .lookupLocalMember(extensionBuilder.name)!
                    .getable as ExtensionBuilder);
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
