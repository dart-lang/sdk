// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/* To regenerate this file:

1. Build and download highlight.zip for Dart [1].
2. Extract highlight.zip, and find styles/androidstudio.css.
3. Run:

       sed -i -e '/^const _highlightCss =/{
       r'<(echo 'const _highlightCss = "'"$(base64 < styles/androidstudio.css)"'";')'
       d
       }' highlight_css.dart

[1] https://highlightjs.org/download/
*/

import 'dart:convert';

const _highlightCss =
    'LyoKRGF0ZTogMjQgRmV2IDIwMTUKQXV0aG9yOiBQZWRybyBPbGl2ZWlyYSA8a2FueXR1QGdtYWlsIC4gY29tPgoqLwoKLmhsanMgewogIGNvbG9yOiAjYTliN2M2OwogIGJhY2tncm91bmQ6ICMyODJiMmU7CiAgZGlzcGxheTogYmxvY2s7CiAgb3ZlcmZsb3cteDogYXV0bzsKICBwYWRkaW5nOiAwLjVlbTsKfQoKLmhsanMtbnVtYmVyLAouaGxqcy1saXRlcmFsLAouaGxqcy1zeW1ib2wsCi5obGpzLWJ1bGxldCB7CiAgY29sb3I6ICM2ODk3QkI7Cn0KCi5obGpzLWtleXdvcmQsCi5obGpzLXNlbGVjdG9yLXRhZywKLmhsanMtZGVsZXRpb24gewogIGNvbG9yOiAjY2M3ODMyOwp9CgouaGxqcy12YXJpYWJsZSwKLmhsanMtdGVtcGxhdGUtdmFyaWFibGUsCi5obGpzLWxpbmsgewogIGNvbG9yOiAjNjI5NzU1Owp9CgouaGxqcy1jb21tZW50LAouaGxqcy1xdW90ZSB7CiAgY29sb3I6ICM4MDgwODA7Cn0KCi5obGpzLW1ldGEgewogIGNvbG9yOiAjYmJiNTI5Owp9CgouaGxqcy1zdHJpbmcsCi5obGpzLWF0dHJpYnV0ZSwKLmhsanMtYWRkaXRpb24gewogIGNvbG9yOiAjNkE4NzU5Owp9CgouaGxqcy1zZWN0aW9uLAouaGxqcy10aXRsZSwKLmhsanMtdHlwZSB7CiAgY29sb3I6ICNmZmM2NmQ7Cn0KCi5obGpzLW5hbWUsCi5obGpzLXNlbGVjdG9yLWlkLAouaGxqcy1zZWxlY3Rvci1jbGFzcyB7CiAgY29sb3I6ICNlOGJmNmE7Cn0KCi5obGpzLWVtcGhhc2lzIHsKICBmb250LXN0eWxlOiBpdGFsaWM7Cn0KCi5obGpzLXN0cm9uZyB7CiAgZm9udC13ZWlnaHQ6IGJvbGQ7Cn0K';

String decodeHighlightCss() =>
    String.fromCharCodes(base64Decode(_highlightCss));
