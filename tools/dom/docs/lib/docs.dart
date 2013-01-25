/**
 * A library for extracting the documentation from the various HTML libraries
 * ([dart:html], [dart:svg], [dart:web_audio], [dart:indexed_db]) and saving
 * those documentation comments to a JSON file.
 */

library docs;

import '../../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors.dart';
import '../../../../sdk/lib/_internal/dartdoc/lib/src/json_serializer.dart';
import '../../../../sdk/lib/_internal/dartdoc/lib/dartdoc.dart';
import '../../../../utils/apidoc/lib/metadata.dart';
import 'dart:async';
import 'dart:io';

/// The various HTML libraries.
const List<String> HTML_LIBRARY_NAMES = const ['dart:html',
                                               'dart:svg',
                                               'dart:web_audio',
                                               'dart:indexed_db'];
/**
 * Converts the libraries in [HTML_LIBRARY_NAMES] to a json file at [jsonPath]
 * given the library path at [libPath].
 *
 * The json output looks like:
 *     {
 *       $library_name: {
 *         $interface_name: {
 *           comment: "$comment"
 *           members: {
 *             $member: [
 *               $comment1,
 *               ...
 *             ],
 *             ...
 *           }
 *         },
 *         ...
 *       },
 *       ...
 *     }
 *
 * Returns `true` if any errors were encountered, `false` otherwise.
 */
bool convert(Path libPath, Path jsonPath) {
  var paths = <Path>[];
  for (var libraryName in HTML_LIBRARY_NAMES) {
    paths.add(new Path(libraryName));
  }

  // TODO(amouravski): Account for errors in compilation.
  final compilation = new Compilation.library(paths, libPath, null,
      ['--preserve-comments']);

  var convertedJson = _generateJsonFromLibraries(compilation);

  var anyErrors = _exportJsonToFile(convertedJson, jsonPath);

  return anyErrors;
}

bool _exportJsonToFile(Map convertedJson, Path jsonPath) {
  final jsonFile = new File.fromPath(jsonPath);
  var writeJson = prettySerialize(convertedJson);

  var outputStream = jsonFile.openOutputStream();
  outputStream.writeString(writeJson);

  return false;
}

Map _generateJsonFromLibraries(Compilation compilation) {
  var convertedJson = {};

  // Sort the libraries by name (not key).
  var sortedLibraries = new List<LibraryMirror>.from(
      compilation.mirrors.libraries.values.where(
          (e) => HTML_LIBRARY_NAMES.indexOf(e.uri.toString()) >= 0))
      ..sort((x, y) =>
        x.uri.toString().toUpperCase().compareTo(
        y.uri.toString().toUpperCase()));

  for (LibraryMirror libMirror in sortedLibraries) {
    print('Extracting documentation from ${libMirror.displayName}.');

    var libraryJson = {};
    var sortedClasses = _sortAndFilterMirrors(
        libMirror.classes.values.toList(), ignoreDocsEditable: true);

    for (ClassMirror classMirror in sortedClasses) {
      var classJson = {};
      var sortedMembers = _sortAndFilterMirrors(
          classMirror.members.values.toList());

      var membersJson = {};
      for (var memberMirror in sortedMembers) {
        var memberDomName = domNames(memberMirror)[0];
        var memberComment = computeUntrimmedCommentAsList(memberMirror);

        // Remove interface name from Dom Name.
        if (memberDomName.indexOf('.') >= 0) {
          memberDomName = memberDomName.slice(memberDomName.indexOf('.') + 1);
        }

        if (!memberComment.isEmpty) {
          membersJson.putIfAbsent(memberDomName, () => memberComment);
        }
      }

      // Only include the comment if DocsEditable is set.
      var classComment = computeUntrimmedCommentAsList(classMirror);
      if (!classComment.isEmpty &&
          findMetadata(classMirror.metadata, 'DocsEditable') != null) {
        classJson.putIfAbsent('comment', () => classComment);
      }
      if (!membersJson.isEmpty) {
        classJson.putIfAbsent('members', () =>
            membersJson);
      }

      if (!classJson.isEmpty) {
        libraryJson.putIfAbsent(domNames(classMirror)[0], () =>
            classJson);
      }
    }

    if (!libraryJson.isEmpty) {
      convertedJson.putIfAbsent(libMirror.displayName, () =>
          libraryJson);
    }
  }

  return convertedJson;
}

/// Filter out mirrors that are private, or which are not part of this docs
/// process. That is, ones without the DocsEditable annotation.
/// If [ignoreDocsEditable] is true, relax the restriction on @DocsEditable.
/// This is to account for classes that are defined in a template, but whose
/// members are generated.
List<DeclarationMirror> _sortAndFilterMirrors(List<DeclarationMirror> mirrors,
    {ignoreDocsEditable: false}) {

  var filteredMirrors = mirrors.where((DeclarationMirror c) =>
      !domNames(c).isEmpty &&
      !c.displayName.startsWith('_') &&
      (!ignoreDocsEditable ? (findMetadata(c.metadata, 'DocsEditable') != null)
          : true))
      .toList();

  filteredMirrors.sort((x, y) =>
    domNames(x)[0].toUpperCase().compareTo(
    domNames(y)[0].toUpperCase()));

  return filteredMirrors;
}

/// Given the class mirror, returns the names found or an empty list.
List<String> domNames(DeclarationMirror mirror) {
  var domNameMetadata = findMetadata(mirror.metadata, 'DomName');

  if (domNameMetadata != null) {
    var domNames = <String>[];
    var tags = deprecatedFutureValue(domNameMetadata.getField('name'));
    for (var s in tags.reflectee.split(',')) {
      domNames.add(s.trim());
    }

    if (domNames.length == 1 && domNames[0] == 'none') return <String>[];
    return domNames;
  } else {
    return <String>[];
  }
}