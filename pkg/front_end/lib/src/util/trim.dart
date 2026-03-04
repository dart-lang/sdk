// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:kernel/kernel.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:front_end/src/kernel/dynamic_module_validator.dart';

/// Tool to trim an .dill file.
///
/// This function reads full .dill files and trims them with a simple goal:
/// produce small .dill files that preserve all the information needed for
/// modular compilation by the bytecode compiler. This is done as a combination
/// of removing unnecessary dependencies and stripping out details, like method
/// bodies. This function would become simpler once CFE can directly produce
/// outlines matching what's needed by the bytecode compiler.
///
/// Currently this function preserves method bodies of mixin declarations and
/// const constructors, which are needed by the compiler. Currently there is not
/// a fine-grain definition of which mixin or const constructors may be used,
/// but this algorithm could be extended to handle trimming in a more fine-grain
/// fashion in the future.
///
/// This function only accepts inputs containing libraries with a Dart version
/// 3.0 or newer. That allows us to ignore legacy mixin declarations. We also
/// assume that the input .dill contains all transitive dependencies needed to
/// properly serialize and visit the AST (this typically includes platform
/// libraries).
///
/// This function expects the caller to provide details about which libraries
/// are known entry points that need to be preserved. It doesn't do a fine-grain
/// tree-shaking, but will delete libraries that can't be reached from those
/// entry points. These entry points can be derived from the
/// `dynamic_interface.yaml` used by dynamic modules.
Future<void> createTrimmedCopy(TrimOptions options) async {
  Component component = loadComponentFromBinary(options.inputPlatformPath);
  loadComponentFromBinary(options.inputAppPath, component);
  bool Function(Library) isExtendable;
  bool Function(Library) isRoot;
  if (options.dynamicInterfaceContents == null) {
    // Include all libraries from a set of user libraries.
    isExtendable = (lib) => true;
    isRoot = (Library lib) =>
        _isRootFromPatterns(lib, options.requiredUserLibraries);
  } else {
    // Include all libraries declared as accessible from the dynamic_interface
    // specification.
    DynamicInterfaceSpecification spec = new DynamicInterfaceSpecification(
      options.dynamicInterfaceContents!,
      options.dynamicInterfaceUri!,
      component,
    );
    Library enclosingLibrary(TreeNode node) => switch (node) {
      Member() => node.enclosingLibrary,
      Class() => node.enclosingLibrary,
      ExtensionTypeDeclaration() => node.enclosingLibrary,
      Library() => node,
      _ => throw 'Unexpected node ${node.runtimeType} $node',
    };
    Set<Library> extendableLibraries = spec.extendable
        .map(enclosingLibrary)
        .toSet();
    Set<Library> roots = {
      ...spec.callable.map(enclosingLibrary),
      ...extendableLibraries,
      ...spec.canBeOverridden.map(enclosingLibrary),
    };
    isExtendable = extendableLibraries.contains;
    isRoot = roots.contains;
  }
  Set<Library> included = {};
  // Validate version and clear method bodies.
  component.accept(new Trimmer(options.librariesToClear, isExtendable));

  // Include all root libraries according to flags or dynamic interface.
  addReachable(component.libraries, isRoot, included);

  // Also include libraries needed by the required platform libraries.
  addReachable(
    component.libraries,
    (Library lib) => _isRootFromPatterns(lib, options.requiredDartLibraries),
    included,
  );

  component.uriToSource.clear();
  component.setMainMethodAndMode(null, true);

  Future<void> emit(String path, bool isPlatform) async {
    Set<Library> filteredSet = included
        .where(
          (lib) => isPlatform
              ? lib.importUri.isScheme('dart')
              : !lib.importUri.isScheme('dart'),
        )
        .toSet();
    IOSink sink = new File(path).openWrite();
    BinaryPrinter printer = new BinaryPrinter(
      sink,
      libraryFilter: filteredSet.contains,
      includeSources: false,
      includeSourceBytes: false,
    );
    printer.writeComponentFile(component);
    await sink.flush();
    await sink.close();
  }

  if (options.outputPlatformPath != null) {
    await emit(options.outputPlatformPath!, true);
  }
  await emit(options.outputAppPath, false);
}

/// Helper to determine whether a library is an included root, if provided
/// with [TrimOptions.requiredUserLibraries] or
/// [TrimOptions.requiredDartLibraries].
bool _isRootFromPatterns(Library lib, Set<String> patterns) {
  List<String> prefixPatterns = patterns
      .where((p) => p.endsWith('*'))
      .map((p) => p.substring(0, p.length - 1))
      .toList();
  Set<String> exactPatterns = patterns.where((p) => !p.endsWith('*')).toSet();
  String uriString = '${lib.importUri}';
  if (exactPatterns.contains(uriString)) return true;
  if (prefixPatterns.any((p) => uriString.startsWith(p))) return true;
  return false;
}

/// Validates that all libraries with extendable classes are 3.0 or higher, then
/// trims contents as much as possible, while enabling modular compilation later
/// on.
///
/// Currently we:
///   * deletes bodies of constructors and procedures, except when deemed
///     necessary for mixin applications and constants.
///   * clear libraries whose contents are unnecessary, even if reachable.
///   * clear unnecessary field initializers.
class Trimmer extends RecursiveVisitor {
  /// Platform libraries that will be cleared internally.
  ///
  /// `Target.extraRequiredLibraries` demands that some platform libraries are
  /// always included in the platform .dill file. However, there are libraries,
  /// that are required by the target that are used only for non-release builds.
  /// Until we can tailor the required libraries to specific configurations, we
  /// add this step to remove the contents of those libraries, without removing
  /// the library node itself.
  final Set<String> librariesToClear;

  /// Subset of libraries that may contain extendable classes according to the
  /// dynamic interface (defaults to all libraries if the dynamic interface is
  /// not provided).
  ///
  /// Used by the trimmer to determine whether legacy mixins may be at play in
  /// the dynamic interface.
  final bool Function(Library) isExtendable;

  /// Whether we are within a mixin declaration in an extendable library, and
  /// hence member bodies need to be preserved.
  bool preserveMemberBodies = false;

  Trimmer(this.librariesToClear, this.isExtendable);

  @override
  void visitLibrary(Library node) {
    Uri uri = node.importUri;
    if (isExtendable(node) && node.languageVersion.major < 3) {
      print(
        'Error: Only libraries 3.0 or newer may be used for extendable '
        'classes. The library `"$uri" includes extendable classes, but has '
        'version ${node.languageVersion.toText()}, which is older than 3.0.',
      );
      exit(1);
    }

    if (librariesToClear.contains(uri.toString())) {
      node.classes.clear();
      node.procedures.clear();
      node.extensions.clear();
      node.fields.clear();
      node.typedefs.clear();
      node.extensionTypeDeclarations.clear();
      node.parts.clear();
      node.dependencies.clear();
      node.additionalExports.clear();
      return;
    }

    super.visitLibrary(node);
  }

  @override
  void visitClass(Class node) {
    preserveMemberBodies =
        isExtendable(node.enclosingLibrary) &&
        (node.isMixinClass || node.isMixinDeclaration);
    super.visitClass(node);
    preserveMemberBodies = false;
  }

  @override
  void visitConstructor(Constructor node) {
    // Mixin class constructors are not needed, only mixin method bodies.
    node.function.body = null;

    // Initializers can be removed in general, except for initializers of const
    // constructors. Those are needed for constant evaluation in the CFE and
    // proper canonicalization.
    if (!node.isConst) {
      node.initializers.clear();
    }
  }

  @override
  void visitProcedure(Procedure node) {
    // Keep bodies of const factories.
    if (node.isConst) return;
    // Preserve method bodies of mixin declarations, these are copied when
    // mixins are applied in subtypes.
    if (!preserveMemberBodies) {
      node.function.body = null;
    }
  }

  @override
  void visitField(Field node) {
    // Constant initializers are necessary for constant evaluation
    if (node.isConst) return;
    if (!node.isStatic && node.enclosingClass!.hasConstConstructor) return;

    // Unfortunately a `null` initializer may be misinterpreted by the CFE or
    // the compiler. Ideally the kernel representation should have a sentinel
    // marker so the actual initializer could be removed.
    //
    // These exceptions are a result of this issue:
    // * Late final fields (may get an implicit setter)
    // * Static fields (may change the code generated for accessing the field)
    if (node.isLate && node.isFinal) return;
    if (node.isStatic) return;

    // Preserve field initializers in mixin declarations, these are copied when
    // mixins are applied in subtypes.
    if (!preserveMemberBodies) {
      node.initializer = null;
    }
  }
}

/// Select [libraries] whose import belongs to any of the [patterns] and
/// any other transitively reachable library.
void addReachable(
  List<Library> libraries,
  bool Function(Library) isRoot,
  Set<Library> result,
) {
  List<Library> pending = [
    for (Library lib in libraries)
      if (isRoot(lib)) lib,
  ];

  while (!pending.isEmpty) {
    Library lib = pending.removeLast();
    if (result.add(lib)) {
      pending.addAll(lib.dependencies.map((dep) => dep.targetLibrary));
    }
  }
}

/// Options to configure the behavior of [createTrimmedCopy].
class TrimOptions {
  /// Path to the input dill file containing the application contents.
  final String inputAppPath;

  /// Path to the input dill file containing the platform libraries.
  final String inputPlatformPath;

  /// Path to the output dill file containing the application contents.
  final String outputAppPath;

  /// Path to the output dill file containing the platform libraries.
  final String? outputPlatformPath;

  /// Contents of the `dynamic_interface.yaml` file, used to compute required
  /// user libraries.
  ///
  /// Must be null if [requiredUserLibraries] is not empty.
  // Note: we do not provide a file-system path in order to support kernel files
  // that use custom schemes (e.g. not `file:/`).
  final String? dynamicInterfaceContents;

  /// Base uri of the `dynamic_interface.yaml` needed to resolve library
  /// references within that file. This can be a `file:` or a custom scheme Uri.
  final Uri? dynamicInterfaceUri;

  /// User libraries that must be preserved in the .dill file.
  final Set<String> requiredUserLibraries;

  /// Platform libraries that must be preserved in the .dill file.
  ///
  /// Leave empty to produce a .dill containing user-code only.
  final Set<String> requiredDartLibraries;

  /// Libraries that are not needed for production builds and that should
  /// be possible to clear when trimming .dill files, even if they need
  /// to be present in the dill file for other reasons.
  final Set<String> librariesToClear;

  TrimOptions({
    required this.inputAppPath,
    required this.inputPlatformPath,
    required this.outputAppPath,
    required this.outputPlatformPath,
    this.dynamicInterfaceContents,
    this.dynamicInterfaceUri,
    this.requiredUserLibraries = const {},
    required this.requiredDartLibraries,
    this.librariesToClear = const {},
  }) {
    if (dynamicInterfaceContents != null && requiredUserLibraries.isNotEmpty) {
      throw new ArgumentError(
        'Both dynamic interface and required user '
        'libraries specified at once. Only one expected',
      );
    }
    if (dynamicInterfaceContents == null && requiredUserLibraries.isEmpty) {
      throw new ArgumentError(
        'Both dynamic interface and required user '
        'libraries missing. Only one expected',
      );
    }
  }
}
