library docgen.utils;

import '../../../../sdk/lib/_internal/compiler/implementation/mirrors/source_mirrors.dart';
import '../../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors_util.dart'
    as dart2js_util;
import '../../../../sdk/lib/_internal/libraries.dart';

// HTML escaped version of '<' character.
const LESS_THAN = '&lt;';

/// A declaration is private if itself is private, or the owner is private.
// Issue(12202) - A declaration is public even if it's owner is private.
bool isHidden(DeclarationMirror mirror) {
  if (mirror is LibraryMirror) {
    return _isLibraryPrivate(mirror);
  } else if (mirror.owner is LibraryMirror) {
    return (mirror.isPrivate || _isLibraryPrivate(mirror.owner) ||
        mirror.isNameSynthetic);
  } else {
    return (mirror.isPrivate || isHidden(mirror.owner) ||
        mirror.isNameSynthetic);
  }
}

/// Returns true if a library name starts with an underscore, and false
/// otherwise.
///
/// An example that starts with _ is _js_helper.
/// An example that contains ._ is dart._collection.dev
bool _isLibraryPrivate(LibraryMirror mirror) {
  // This method is needed because LibraryMirror.isPrivate returns `false` all
  // the time.
  var sdkLibrary = LIBRARIES[dart2js_util.nameOf(mirror)];
  if (sdkLibrary != null) {
    return !sdkLibrary.documented;
  } else if (dart2js_util.nameOf(mirror).startsWith('_') || dart2js_util.nameOf(
      mirror).contains('._')) {
    return true;
  }
  return false;
}

/// Transforms the map by calling toMap on each value in it.
Map recurseMap(Map inputMap) {
  var outputMap = {};
  inputMap.forEach((key, value) {
    if (value is Map) {
      outputMap[key] = recurseMap(value);
    } else {
      outputMap[key] = value.toMap();
    }
  });
  return outputMap;
}

Map filterMap(Map map, Function test) {
  var exported = new Map();
  map.forEach((key, value) {
    if (test(key, value)) exported[key] = value;
  });
  return exported;
}

/// Chunk the provided name into individual parts to be resolved. We take a
/// simplistic approach to chunking, though, we break at " ", ",", "&lt;"
/// and ">". All other characters are grouped into the name to be resolved.
/// As a result, these characters will all be treated as part of the item to
/// be resolved (aka the * is interpreted literally as a *, not as an
/// indicator for bold <em>.
List<String> tokenizeComplexReference(String name) {
  var tokens = [];
  var append = false;
  var index = 0;
  while (index < name.length) {
    if (name.indexOf(LESS_THAN, index) == index) {
      tokens.add(LESS_THAN);
      append = false;
      index += LESS_THAN.length;
    } else if (name[index] == ' ' || name[index] == ',' || name[index] == '>') {
      tokens.add(name[index]);
      append = false;
      index++;
    } else {
      if (append) {
        tokens[tokens.length - 1] = tokens.last + name[index];
      } else {
        tokens.add(name[index]);
        append = true;
      }
      index++;
    }
  }
  return tokens;
}

typedef DeclarationMirror LookupFunction(DeclarationSourceMirror declaration,
    String name);

/// For a given name, determine if we need to resolve it as a qualified name
/// or a simple name in the source mirors.
LookupFunction determineLookupFunc(String name) => name.contains('.') ?
    dart2js_util.lookupQualifiedInScope :
      (mirror, name) => mirror.lookupInScope(name);
