// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:package_config/package_config.dart';

import 'find_sdk_root.dart';
import 'suite.dart';

Future<void> writePackageConfig(
    Module module, Set<Module> transitiveDependencies, Uri root) async {
  const packageConfigJsonPath = ".dart_tool/package_config.json";
  var sdkRoot = await findRoot();
  Uri packageConfigUri = sdkRoot.resolve(packageConfigJsonPath);
  var packageConfig = await loadPackageConfigUri(packageConfigUri);

  // We create a package_config.json file to support the CFE in (a) determine
  // the default nullability if the current module is a package, and (b)
  // resolve `package:` imports. Technically the latter shouldn't be necessary,
  // but the CFE requires that if a `package:` URI of a dependency is used in an
  // import, then we need that package entry in the associated file. In fact,
  // after it checks that the definition exists, the CFE will not actually use
  // the resolved URI if a library for the import URI is already found in one of
  // the provide .dill files of the dependencies. For that reason, and to ensure
  // that a step only has access to the files provided in a module, we generate
  // a config file with invalid folders for other packages.
  // TODO(sigmund): follow up with the CFE to see if we can remove the need
  // for these dummy entries.
  var packagesJson = [];
  if (module.isPackage) {
    packagesJson.add(_packageConfigEntry(
        module.name, Uri.parse('../${module.packageBase}')));
  }

  int unusedNum = 0;
  for (Module dependency in transitiveDependencies) {
    if (dependency.isPackage) {
      // rootUri should be ignored for dependent modules, so we pass in a
      // bogus value.
      var rootUri = Uri.parse('unused$unusedNum');
      unusedNum++;

      var dependentPackage = packageConfig[dependency.name];
      var packageJson = dependentPackage == null
          ? _packageConfigEntry(dependency.name, rootUri)
          : _packageConfigEntry(dependentPackage.name, rootUri,
              version: dependentPackage.languageVersion);
      packagesJson.add(packageJson);
    }
  }

  await File.fromUri(root.resolve(packageConfigJsonPath))
      .create(recursive: true);
  await File.fromUri(root.resolve(packageConfigJsonPath)).writeAsString('{'
      '  "configVersion": ${packageConfig.version},'
      '  "packages": [ ${packagesJson.join(',')} ]'
      '}');
}

String _packageConfigEntry(String name, Uri root,
    {Uri packageRoot, LanguageVersion version}) {
  var fields = [
    '"name": "${name}"',
    '"rootUri": "$root"',
    if (packageRoot != null) '"packageUri": "$packageRoot"',
    if (version != null) '"languageVersion": "$version"'
  ];
  return '{${fields.join(',')}}';
}
