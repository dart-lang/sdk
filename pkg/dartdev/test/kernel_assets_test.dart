// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dartdev/src/kernel_assets.dart';
import 'package:test/test.dart';

void main() {
  final fooUri = Uri.file('path/to/libfoo.so');
  final foo2Uri = Uri.file('path/to/libfoo2.so');
  final foo3Uri = Uri(path: 'libfoo3.so');
  final barUri = Uri(path: 'path/to/libbar.a');
  final blaUri = Uri(path: 'path/with spaces/bla.dll');
  final assets = KernelAssets([
    KernelAsset(
      id: 'foo',
      path: KernelAssetAbsolutePath(fooUri),
      target: .androidX64,
    ),
    KernelAsset(
      id: 'foo2',
      path: KernelAssetRelativePath(foo2Uri),
      target: .androidX64,
    ),
    KernelAsset(
      id: 'foo3',
      path: KernelAssetSystemPath(foo3Uri),
      target: .androidX64,
    ),
    KernelAsset(
      id: 'foo4',
      path: KernelAssetInExecutable(),
      target: .androidX64,
    ),
    KernelAsset(
      id: 'foo5',
      path: KernelAssetInProcess(),
      target: .androidX64,
    ),
    KernelAsset(
      id: 'bar',
      path: KernelAssetAbsolutePath(barUri),
      target: .linuxArm64,
    ),
    KernelAsset(
      id: 'bla',
      path: KernelAssetAbsolutePath(blaUri),
      target: .windowsX64,
    ),
  ]);

  const assetsDartEncoding = r'''{
  "format-version": [
    1,
    0,
    0
  ],
  "native-assets": {
    "android_x64": {
      "foo": [
        "absolute",
        "path/to/libfoo.so"
      ],
      "foo2": [
        "relative",
        "path/to/libfoo2.so"
      ],
      "foo3": [
        "system",
        "libfoo3.so"
      ],
      "foo4": [
        "executable"
      ],
      "foo5": [
        "process"
      ]
    },
    "linux_arm64": {
      "bar": [
        "absolute",
        "path/to/libbar.a"
      ]
    },
    "windows_x64": {
      "bla": [
        "absolute",
        "path\\with spaces\\bla.dll"
      ]
    }
  }
}''';

  test('asset yaml', () async {
    final fileContents = assets.toNativeAssetsFile();
    expect(
      fileContents,
      assetsDartEncoding,
    );
  });

  test('path equality', () {
    expect(
      KernelAssetAbsolutePath(Uri.parse('/path/to/libbar.a')),
      KernelAssetAbsolutePath(Uri.parse('/path/to/libbar.a')),
    );
    expect(
      KernelAssetAbsolutePath(Uri.parse('/path/to/libbar.a')),
      isNot(KernelAssetAbsolutePath(Uri.parse('/path/to/libbar2.a'))),
    );
    expect(
      KernelAssetRelativePath(Uri.parse('path/to/libbar.a')),
      KernelAssetRelativePath(Uri.parse('path/to/libbar.a')),
    );
    expect(
      KernelAssetRelativePath(Uri.parse('path/to/libbar.a')),
      isNot(KernelAssetRelativePath(Uri.parse('path/to/libbar2.a'))),
    );
    expect(
      KernelAssetSystemPath(Uri.parse('path/to/libbar.a')),
      KernelAssetSystemPath(Uri.parse('path/to/libbar.a')),
    );
    expect(
      KernelAssetSystemPath(Uri.parse('path/to/libbar.a')),
      isNot(KernelAssetSystemPath(Uri.parse('path/to/libbar2.a'))),
    );
  });

  test('toJsonForTarget', () {
    expect(
      KernelAssetAbsolutePath(
        Uri.parse('/path/to/libfoo.so'),
      ).toJsonForTarget(.linuxArm64),
      ['absolute', '/path/to/libfoo.so'],
    );

    expect(
      KernelAssetAbsolutePath(
        Uri.parse('/path/to/libfoo.so'),
      ).toJsonForTarget(.windowsArm64),
      ['absolute', '\\path\\to\\libfoo.so'],
    );

    expect(
      KernelAssetRelativePath(
        Uri.parse('path/to/libfoo.so'),
      ).toJsonForTarget(.linuxArm64),
      ['relative', 'path/to/libfoo.so'],
    );

    expect(
      KernelAssetRelativePath(
        Uri.parse('path/to/libfoo.so'),
      ).toJsonForTarget(.windowsArm64),
      ['relative', 'path\\to\\libfoo.so'],
    );

    expect(
      KernelAssetSystemPath(
        Uri.parse('path/to/libfoo.so'),
      ).toJsonForTarget(.linuxArm64),
      ['system', 'path/to/libfoo.so'],
    );

    expect(
      KernelAssetSystemPath(
        Uri.parse('path/to/libfoo.so'),
      ).toJsonForTarget(.windowsArm64),
      ['system', 'path\\to\\libfoo.so'],
    );

    expect(KernelAssetInProcess().toJsonForTarget(.linuxArm64), ['process']);

    expect(
      KernelAssetInProcess().toJsonForTarget(.windowsArm64),
      ['process'],
    );

    expect(KernelAssetInExecutable().toJsonForTarget(.linuxArm64), [
      'executable',
    ]);

    expect(
      KernelAssetInExecutable().toJsonForTarget(.windowsArm64),
      ['executable'],
    );
  });

  test('toJson', () {
    final fooUri = Uri.parse('/path/to/libfoo.so');
    final relUri = Uri.parse('path/to/libfoo.so');
    expect(
      KernelAssetAbsolutePath(fooUri).toJson(),
      ['absolute', fooUri.toFilePath()],
    );
    expect(
      KernelAssetRelativePath(relUri).toJson(),
      ['relative', relUri.toFilePath()],
    );
    expect(
      KernelAssetSystemPath(relUri).toJson(),
      ['system', relUri.toFilePath()],
    );
    expect(KernelAssetInProcess().toJson(), ['process']);
    expect(KernelAssetInExecutable().toJson(), ['executable']);
  });
}
