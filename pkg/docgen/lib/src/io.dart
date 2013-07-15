library io;
/// This is a helper library to make working with io easier.
// TODO(janicejl): listDir, canonicalize, resolveLink, and linkExists are from
// pub/lib/src/io.dart. If the io.dart file becomes a package, should remove
// copy of the functions.

import 'dart:collection';
import 'dart:io';
import 'package:pathos/path.dart' as path;

/// Lists the contents of [dir]. If [recursive] is `true`, lists subdirectory
/// contents (defaults to `false`). If [includeHidden] is `true`, includes files
/// and directories beginning with `.` (defaults to `false`).
///
/// The returned paths are guaranteed to begin with [dir].
List<String> listDir(String dir, {bool recursive: false,
    bool includeHidden: false}) {
  List<String> doList(String dir, Set<String> listedDirectories) {
    var contents = <String>[];

    // Avoid recursive symlinks.
    var resolvedPath = canonicalize(dir);
    if (listedDirectories.contains(resolvedPath)) return [];

    listedDirectories = new Set<String>.from(listedDirectories);
    listedDirectories.add(resolvedPath);

    var children = <String>[];
    for (var entity in new Directory(dir).listSync()) {
      if (!includeHidden && path.basename(entity.path).startsWith('.')) {
        continue;
      }

      contents.add(entity.path);
      if (entity is Directory) {
        // TODO(nweiz): don't manually recurse once issue 4794 is fixed.
        // Note that once we remove the manual recursion, we'll need to
        // explicitly filter out files in hidden directories.
        if (recursive) {
          children.addAll(doList(entity.path, listedDirectories));
        }
      }
    }

    contents.addAll(children);
    return contents;
  }

  return doList(dir, new Set<String>());
}

/// Returns the canonical path for [pathString]. This is the normalized,
/// absolute path, with symlinks resolved. As in [transitiveTarget], broken or
/// recursive symlinks will not be fully resolved.
///
/// This doesn't require [pathString] to point to a path that exists on the
/// filesystem; nonexistent or unreadable path entries are treated as normal
/// directories.
String canonicalize(String pathString) {
  var seen = new Set<String>();
  var components = new Queue<String>.from(
      path.split(path.normalize(path.absolute(pathString))));

  // The canonical path, built incrementally as we iterate through [components].
  var newPath = components.removeFirst();

  // Move through the components of the path, resolving each one's symlinks as
  // necessary. A resolved component may also add new components that need to be
  // resolved in turn.
  while (!components.isEmpty) {
    seen.add(path.join(newPath, path.joinAll(components)));
    var resolvedPath = resolveLink(
        path.join(newPath, components.removeFirst()));
    var relative = path.relative(resolvedPath, from: newPath);

    // If the resolved path of the component relative to `newPath` is just ".",
    // that means component was a symlink pointing to its parent directory. We
    // can safely ignore such components.
    if (relative == '.') continue;

    var relativeComponents = new Queue<String>.from(path.split(relative));

    // If the resolved path is absolute relative to `newPath`, that means it's
    // on a different drive. We need to canonicalize the entire target of that
    // symlink again.
    if (path.isAbsolute(relative)) {
      // If we've already tried to canonicalize the new path, we've encountered
      // a symlink loop. Avoid going infinite by treating the recursive symlink
      // as the canonical path.
      if (seen.contains(relative)) {
        newPath = relative;
      } else {
        newPath = relativeComponents.removeFirst();
        relativeComponents.addAll(components);
        components = relativeComponents;
      }
      continue;
    }

    // Pop directories off `newPath` if the component links upwards in the
    // directory hierarchy.
    while (relativeComponents.first == '..') {
      newPath = path.dirname(newPath);
      relativeComponents.removeFirst();
    }

    // If there's only one component left, [resolveLink] guarantees that it's
    // not a link (or is a broken link). We can just add it to `newPath` and
    // continue resolving the remaining components.
    if (relativeComponents.length == 1) {
      newPath = path.join(newPath, relativeComponents.single);
      continue;
    }

    // If we've already tried to canonicalize the new path, we've encountered a
    // symlink loop. Avoid going infinite by treating the recursive symlink as
    // the canonical path.
    var newSubPath = path.join(newPath, path.joinAll(relativeComponents));
    if (seen.contains(newSubPath)) {
      newPath = newSubPath;
      continue;
    }

    // If there are multiple new components to resolve, add them to the
    // beginning of the queue.
    relativeComponents.addAll(components);
    components = relativeComponents;
  }
  return newPath;
}

/// Returns the transitive target of [link] (if A links to B which links to C,
/// this will return C). If [link] is part of a symlink loop (e.g. A links to B
/// which links back to A), this returns the path to the first repeated link (so
/// `transitiveTarget("A")` would return `"A"` and `transitiveTarget("A")` would
/// return `"B"`).
///
/// This accepts paths to non-links or broken links, and returns them as-is.
String resolveLink(String link) {
  var seen = new Set<String>();
  while (linkExists(link) && !seen.contains(link)) {
    seen.add(link);
    link = path.normalize(path.join(
        path.dirname(link), new Link(link).targetSync()));
  }
  return link;
}

/// Returns whether [link] exists on the file system. This will return `true`
/// for any symlink, regardless of what it points at or whether it's broken.
bool linkExists(String link) => new Link(link).existsSync();