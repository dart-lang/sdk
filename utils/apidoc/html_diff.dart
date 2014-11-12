// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A script to assist in documenting the difference between the dart:html API
 * and the old DOM API.
 */
library html_diff;

import 'dart:async';

import 'lib/metadata.dart';

// TODO(rnystrom): Use "package:" URL (#4968).
import '../../pkg/compiler/lib/src/mirrors/analyze.dart';
import '../../pkg/compiler/lib/src/mirrors/source_mirrors.dart';
import '../../pkg/compiler/lib/src/mirrors/mirrors_util.dart';
import '../../pkg/compiler/lib/src/source_file_provider.dart';

// TODO(amouravski): There is currently magic that looks at dart:* libraries
// rather than the declared library names. This changed due to recent syntax
// changes. We should only need to look at the library 'html'.
final List<Uri> HTML_LIBRARY_URIS = [
    new Uri(scheme: 'dart', path: 'html'),
    new Uri(scheme: 'dart', path: 'indexed_db'),
    new Uri(scheme: 'dart', path: 'svg'),
    new Uri(scheme: 'dart', path: 'web_audio')];

/**
 * A class for computing a many-to-many mapping between the types and
 * members in `dart:html` and the MDN DOM types. This mapping is
 * based on two indicators:
 *
 *   1. Auto-detected wrappers. Most `dart:html` types correspond
 *      straightforwardly to a single `@DomName` type, and
 *      have the same name.  In addition, most `dart:html` methods
 *      just call a single `@DomName` method. This class
 *      detects these simple correspondences automatically.
 *
 *   2. Manual annotations. When it's not clear which
 *      `@DomName` items a given `dart:html` item
 *      corresponds to, the `dart:html` item can be annotated in the
 *      documentation comments using the `@DomName` annotation.
 *
 * The `@DomName` annotations for types and members are of the form
 * `@DomName NAME(, NAME)*`, where the `NAME`s refer to the
 * `@DomName` types/members that correspond to the
 * annotated `dart:html` type/member. `NAME`s on member annotations
 * can refer to either fully-qualified member names (e.g.
 * `Document.createElement`) or unqualified member names
 * (e.g. `createElement`).  Unqualified member names are assumed to
 * refer to members of one of the corresponding `@DomName`
 * types.
 */
class HtmlDiff {
  /**
   * A map from `dart:html` members to the corresponding fully qualified
   * `@DomName` member(s).
   */
  final Map<String, Set<String>> htmlToDom;

  /** A map from `dart:html` types to corresponding `@DomName` types. */
  final Map<String, Set<String>> htmlTypesToDom;

  /** If true, then print warning messages. */
  final bool _printWarnings;

  static LibraryMirror dom;

  HtmlDiff({bool printWarnings: false}) :
    _printWarnings = printWarnings,
    htmlToDom = new Map<String, Set<String>>(),
    htmlTypesToDom = new Map<String, Set<String>>();

  void warn(String s) {
    if (_printWarnings) {
      print('Warning: $s');
    }
  }

  /**
   * Computes the `@DomName` to `dart:html` mapping, and
   * places it in [htmlToDom] and [htmlTypesToDom]. Before this is run, dart2js
   * should be initialized (via [parseOptions] and [initializeWorld]) and
   * [HtmlDiff.initialize] should be called.
   */
  Future run(Uri libraryRoot) {
    var result = new Completer();
    var provider = new CompilerSourceFileProvider();
    var handler = new FormattingDiagnosticHandler(provider);
    Future<MirrorSystem> analysis = analyze(
        HTML_LIBRARY_URIS, libraryRoot, null,
        provider.readStringFromUri,
        handler.diagnosticHandler);
    analysis.then((MirrorSystem mirrors) {
      for (var libraryUri in HTML_LIBRARY_URIS) {
        var library = mirrors.libraries[libraryUri];
        if (library == null) {
          warn('Could not find $libraryUri');
          result.complete(false);
        }
        for (ClassMirror type in classesOf(library.declarations)) {
          final domTypes = htmlToDomTypes(type);
          if (domTypes.isEmpty) continue;

          htmlTypesToDom.putIfAbsent(qualifiedNameOf(type),
              () => new Set()).addAll(domTypes);

          membersOf(type.declarations).forEach(
              (m) => _addMemberDiff(m, domTypes, nameOf(library)));
        }
      }
      result.complete(true);
    });
    return result.future;
  }

  /**
   * Records the `@DomName` to `dart:html` mapping for
   * [htmlMember] (from `dart:html`). [domTypes] are the
   * `@DomName` type values that correspond to [htmlMember]'s
   * defining type.
   */
  void _addMemberDiff(DeclarationMirror htmlMember, List<String> domTypes,
      String libraryName) {
    var domMembers = htmlToDomMembers(htmlMember, domTypes);
    if (htmlMember == null && !domMembers.isEmpty) {
      warn('$libraryName member '
           '${htmlMember.owner.simpleName}.'
           '${htmlMember.simpleName} has no corresponding '
           '$libraryName member.');
    }

    if (htmlMember == null) return;
    if (!domMembers.isEmpty) {
      htmlToDom[qualifiedNameOf(htmlMember)] = domMembers;
    }
  }

  /**
   * Returns the `@DomName` type values that correspond to
   * [htmlType] from `dart:html`. This can be the empty list if no
   * correspondence is found.
   */
  List<String> htmlToDomTypes(ClassMirror htmlType) {
    if (htmlType.simpleName == null) return <String>[];

    final domNameMetadata = findMetadata(htmlType.metadata, 'DomName');
    if (domNameMetadata != null) {
      var domNames = <String>[];
      var names = domNameMetadata.getField(symbolOf('name'));
      for (var s in names.reflectee.split(',')) {
        domNames.add(s.trim());
      }

      if (domNames.length == 1 && domNames[0] == 'none') return <String>[];
      return domNames;
    }
    return <String>[];
  }

  /**
   * Returns the `@DomName` member values that correspond to
   * [htmlMember] from `dart:html`. This can be the empty set if no
   * correspondence is found.  [domTypes] are the
   * `@DomName` type values that correspond to [htmlMember]'s
   * defining type.
   */
  Set<String> htmlToDomMembers(DeclarationMirror htmlMember,
                               List<String> domTypes) {
    if (htmlMember.isPrivate) return new Set();

    final domNameMetadata = findMetadata(htmlMember.metadata, 'DomName');
    if (domNameMetadata != null) {
      var domNames = <String>[];
      var names = domNameMetadata.getField(symbolOf('name'));
      for (var s in names.reflectee.split(',')) {
        domNames.add(s.trim());
      }

      if (domNames.length == 1 && domNames[0] == 'none') return new Set();
      final members = new Set();
      domNames.forEach((name) {
        var nameMembers = _membersFromName(name, domTypes);
        if (nameMembers.isEmpty) {
          if (name.contains('.')) {
            warn('no member $name');
          } else {
            final options = <String>[];
            for (var t in domTypes) {
              options.add('$t.$name');
            }
            options.join(' or ');
            warn('no member $options');
          }
        }
        members.addAll(nameMembers);
      });
      return members;
    }

    return new Set();
  }

  /**
   * Returns the `@DomName` strings that are indicated by
   * [name]. [name] can be either an unqualified member name
   * (e.g. `createElement`), in which case it's treated as the name of
   * a member of one of [defaultTypes], or a fully-qualified member
   * name (e.g. `Document.createElement`), in which case it's treated as a
   * member of the @DomName element (`Document` in this case).
   */
  Set<String> _membersFromName(String name, List<String> defaultTypes) {
    if (!name.contains('.', 0)) {
      if (defaultTypes.isEmpty) {
        warn('no default type for $name');
        return new Set();
      }
      final members = new Set<String>();
      defaultTypes.forEach((t) { members.add('$t.$name'); });
      return members;
    }

    if (name.split('.').length != 2) {
      warn('invalid member name ${name}');
      return new Set();
    }
    return new Set.from([name]);
  }
}
