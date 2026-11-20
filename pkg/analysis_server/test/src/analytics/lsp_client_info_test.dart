// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analytics/lsp_client_info.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LspClientInfoTest);
  });
}

@reflectiveTest
class LspClientInfoTest {
  void test_name_known() {
    expect(lspClientNameForAnalytics('Neovim'), 'neovim');
    expect(lspClientNameForAnalytics('coc.nvim'), 'neovim');
    expect(lspClientNameForAnalytics('vim-lsp'), 'vim');
    expect(lspClientNameForAnalytics('Zed'), 'zed');
    expect(lspClientNameForAnalytics('helix'), 'helix');
    expect(lspClientNameForAnalytics('emacs'), 'emacs');
    expect(lspClientNameForAnalytics('Eglot'), 'emacs');
    expect(lspClientNameForAnalytics('Sublime Text LSP'), 'sublime');
    expect(lspClientNameForAnalytics('Kate'), 'kate');
    expect(lspClientNameForAnalytics('Visual Studio Code'), 'vscode');
  }

  void test_name_unknown() {
    expect(lspClientNameForAnalytics(''), otherLspClientName);
    expect(lspClientNameForAnalytics('My Editor'), otherLspClientName);
  }

  void test_version_invalid() {
    expect(lspClientVersionForAnalytics('neovim', null), '');
    expect(lspClientVersionForAnalytics('neovim', ''), '');
    expect(lspClientVersionForAnalytics('neovim', 'nightly build'), '');
    expect(lspClientVersionForAnalytics('neovim', '1.2.3.4.5'), '');
    expect(lspClientVersionForAnalytics('neovim', '1.2.3abc'), '');
    expect(lspClientVersionForAnalytics('neovim', '1${'0' * 20}'), '');
  }

  void test_version_suffixDropped() {
    expect(
      lspClientVersionForAnalytics(
        'neovim',
        '3.15.0-edge.102a906efed696bade9fb25b04cb28b1d1af0602',
      ),
      '3.15.0',
    );
    expect(lspClientVersionForAnalytics('neovim', '0.11.0-dev.1'), '0.11.0');
    expect(lspClientVersionForAnalytics('zed', '0.160.1+stable'), '0.160.1');
    expect(lspClientVersionForAnalytics('helix', '24.07 (abc123)'), '24.07');
  }

  void test_version_unknownClient() {
    expect(lspClientVersionForAnalytics(otherLspClientName, '1.0.0'), '');
  }

  void test_version_valid() {
    expect(lspClientVersionForAnalytics('neovim', '0.10.2'), '0.10.2');
    expect(lspClientVersionForAnalytics('neovim', 'v0.10.2'), '0.10.2');
    expect(lspClientVersionForAnalytics('helix', '24.07'), '24.07');
    expect(lspClientVersionForAnalytics('kate', '1.2.3.4'), '1.2.3.4');
  }
}
