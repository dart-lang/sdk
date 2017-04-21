/*
 * Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

// This is a small version of the co19 test
// Language/14_Types/4_Interface_Types_A11_t02.

import 'package:expect/expect.dart';

class C {}

class G<T, S, U> {}

main() {
  Expect.isTrue(new G<C126, C126, C126>() is G<C, C, C>);
}

class C1 extends C {}

class C2 extends C1 {}

class C3 extends C2 {}

class C4 extends C3 {}

class C5 extends C4 {}

class C6 extends C5 {}

class C7 extends C6 {}

class C8 extends C7 {}

class C9 extends C8 {}

class C10 extends C9 {}

class C11 extends C10 {}

class C12 extends C11 {}

class C13 extends C12 {}

class C14 extends C13 {}

class C15 extends C14 {}

class C16 extends C15 {}

class C17 extends C16 {}

class C18 extends C17 {}

class C19 extends C18 {}

class C20 extends C19 {}

class C21 extends C20 {}

class C22 extends C21 {}

class C23 extends C22 {}

class C24 extends C23 {}

class C25 extends C24 {}

class C26 extends C25 {}

class C27 extends C26 {}

class C28 extends C27 {}

class C29 extends C28 {}

class C30 extends C29 {}

class C31 extends C30 {}

class C32 extends C31 {}

class C33 extends C32 {}

class C34 extends C33 {}

class C35 extends C34 {}

class C36 extends C35 {}

class C37 extends C36 {}

class C38 extends C37 {}

class C39 extends C38 {}

class C40 extends C39 {}

class C41 extends C40 {}

class C42 extends C41 {}

class C43 extends C42 {}

class C44 extends C43 {}

class C45 extends C44 {}

class C46 extends C45 {}

class C47 extends C46 {}

class C48 extends C47 {}

class C49 extends C48 {}

class C50 extends C49 {}

class C51 extends C50 {}

class C52 extends C51 {}

class C53 extends C52 {}

class C54 extends C53 {}

class C55 extends C54 {}

class C56 extends C55 {}

class C57 extends C56 {}

class C58 extends C57 {}

class C59 extends C58 {}

class C60 extends C59 {}

class C61 extends C60 {}

class C62 extends C61 {}

class C63 extends C62 {}

class C64 extends C63 {}

class C65 extends C64 {}

class C66 extends C65 {}

class C67 extends C66 {}

class C68 extends C67 {}

class C69 extends C68 {}

class C70 extends C69 {}

class C71 extends C70 {}

class C72 extends C71 {}

class C73 extends C72 {}

class C74 extends C73 {}

class C75 extends C74 {}

class C76 extends C75 {}

class C77 extends C76 {}

class C78 extends C77 {}

class C79 extends C78 {}

class C80 extends C79 {}

class C81 extends C80 {}

class C82 extends C81 {}

class C83 extends C82 {}

class C84 extends C83 {}

class C85 extends C84 {}

class C86 extends C85 {}

class C87 extends C86 {}

class C88 extends C87 {}

class C89 extends C88 {}

class C90 extends C89 {}

class C91 extends C90 {}

class C92 extends C91 {}

class C93 extends C92 {}

class C94 extends C93 {}

class C95 extends C94 {}

class C96 extends C95 {}

class C97 extends C96 {}

class C98 extends C97 {}

class C99 extends C98 {}

class C100 extends C99 {}

class C101 extends C100 {}

class C102 extends C101 {}

class C103 extends C102 {}

class C104 extends C103 {}

class C105 extends C104 {}

class C106 extends C105 {}

class C107 extends C106 {}

class C108 extends C107 {}

class C109 extends C108 {}

class C110 extends C109 {}

class C111 extends C110 {}

class C112 extends C111 {}

class C113 extends C112 {}

class C114 extends C113 {}

class C115 extends C114 {}

class C116 extends C115 {}

class C117 extends C116 {}

class C118 extends C117 {}

class C119 extends C118 {}

class C120 extends C119 {}

class C121 extends C120 {}

class C122 extends C121 {}

class C123 extends C122 {}

class C124 extends C123 {}

class C125 extends C124 {}

class C126 extends C125 {}
