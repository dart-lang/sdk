# Using Dart LSP in Vim

## Prerequisites

To use Dart’s LSP server with Vim you’ll need to be using at least version 2.2.0
of the Dart SDK (which shipped in version 1.2.1 of Flutter). A Vim plugin manager
is not required but may simplify setup. The steps below have been written assuming
use of [vim-plug](https://github.com/junegunn/vim-plug).


## Install the Plugins

Install the [dart-vim-plugin](https://github.com/dart-lang/dart-vim-plugin) and
[vim-lsc](https://github.com/natebosch/vim-lsc) plugins. Using vim-plug this can
be done by adding the following to `.vimrc` then reloading and running
`:PlugInstall`:

```
call plug#begin('~/.vim/plugged')
Plug 'dart-lang/dart-vim-plugin'
Plug 'natebosch/vim-lsc'
call plug#end()
```

Note: Other LSP plugins are available for Vim but this document assumes vim-lsc.


## Configure vim-lsc

Next tell vim-lsc how to invoke the LSP server. You’ll need the path to the Dart
SDK (which may be inside the Flutter SDK at bin/cache/dart-sdk for Flutter) and
add this to `.vimrc` and reload.

```
let g:lsc_server_commands = {'dart': '~/dart-sdk/bin/dart ~/dart-sdk/bin/snapshots/analysis_server.dart.snapshot --lsp'}
let g:lsc_auto_map = v:true " Use defaults
```

This will set up the LSP server for Dart files using default keybindings. More
info on configuring vim-lsc can be found at
[natebosch/vim-lsc#configuration](https://github.com/natebosch/vim-lsc#configuration).


## Test the Plugins

Open a Dart file in Vim and confirm that you see syntax highlighting (this is
provided by dart-vim-plugin) and that invalid code is highlighted (this is
provided by the LSP server via vim-lsc), with the error showing along the bottom
of the window.


## Keybindings and Commands

Keybindings and commands are documented in the
[vim-lsc README](https://github.com/natebosch/vim-lsc#configuration).


## Supported Features

Available features are those supported by both the vim-lsc plugin
([see here](https://github.com/natebosch/vim-lsc#features)) and the Dart LSP
server ([see here](https://github.com/dart-lang/sdk/blob/master/pkg/analysis_server/tool/lsp_spec/README.md#message-status)).


## Troubleshooting

If you find an issue with the LSP server you can enable logging in the server by
adding the following switches to the LSP server command in `.vimrc`:

```
--instrumentation-log-file /path/to/logs/lsp-vim.txt
```

Issues should be opened in the [dart-lang/sdk](https://github.com/dart-lang/sdk)
repository.
