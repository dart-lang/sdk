// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const HInvalid invalidExample = HInvalidComposite(
  [
    HInvalidLeaf(0),
    HInvalidChild(
      HInvalidLeaf(0),
    ),
    HInvalidError("error message"),
  ],
);

typedef HInvalid = HBase<HKindInvalid>;
typedef HInvalidComposite<CHILD extends HInvalid>
    = HBaseComposite<HKindInvalid, CHILD>;
typedef HInvalidChild<CHILD extends HInvalid> = HBaseChild<HKindInvalid, CHILD>;
typedef HInvalidLeaf = HBaseLeaf<HKindInvalid>;
typedef HInvalidError = HBaseError<HKindInvalid>;

abstract class HBase<HKT extends HKind> implements Kind<HKT> {}

class HBaseComposite<HKT extends HKindValid, CHILD extends HBase<HKT>>
    implements HBase<HKT> {
  final List<CHILD> children;

  const HBaseComposite(
    final this.children,
  );
}

class HBaseChild<HKT extends HKindValid, CHILD extends HBase<HKT>>
    implements HBase<HKT> {
  final CHILD child;

  const HBaseChild(
    final this.child,
  );
}

class HBaseLeaf<HKT extends HKindValid> implements HBase<HKT> {
  final int data;

  const HBaseLeaf(
    final this.data,
  );
}

class HBaseError<HKT extends HKindInvalid> implements HBase<HKT> {
  final String errorMessage;

  const HBaseError(
    final this.errorMessage,
  );
}

abstract class Kind<HKT extends HKind> {}

abstract class HKind {}

abstract class HKindValid implements HKind {}

abstract class HKindInvalid implements HKindValid {}

main() {}
