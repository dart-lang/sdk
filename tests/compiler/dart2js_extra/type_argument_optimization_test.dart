// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Regression test for issue 37267.

typedef UpdateShouldNotify<T> = bool Function(T previous, T current);

typedef ValueWidgetBuilder<T> = Widget Function(
    BuildContext context, T value, Widget child);

class BuildContext {}

class Widget {}

abstract class ProxyWidget extends Widget {
  final Widget child;

  ProxyWidget({this.child});
}

abstract class InheritedWidget extends ProxyWidget {
  InheritedWidget({Widget child}) : super(child: child);
}

class InheritedProvider<T> extends InheritedWidget {
  final T _value;
  final UpdateShouldNotify<T> _updateShouldNotify;

  InheritedProvider(
      {T value, UpdateShouldNotify<T> updateShouldNotify, Widget child})
      : _value = value,
        _updateShouldNotify = updateShouldNotify,
        super(child: child);
}

class StateDelegate {}

abstract class ValueStateDelegate<T> extends StateDelegate {
  T get value;
}

class ValueStateDelegateImpl<T> implements ValueStateDelegate<T> {
  final T value;

  ValueStateDelegateImpl(this.value);
}

class DelegateWidget {
  final StateDelegate delegate;

  DelegateWidget(this.delegate);
}

abstract class Listenable {}

abstract class ValueListenable<T> extends Listenable {
  T get value;
}

class ValueListenableImpl<T> implements ValueListenable<T> {
  final T value;

  ValueListenableImpl(this.value);
}

class ValueDelegateWidget<T> extends DelegateWidget {
  ValueDelegateWidget(ValueStateDelegate<T> delegate) : super(delegate);

  @pragma('dart2js:tryInline')
  ValueStateDelegate<T> get delegate => super.delegate as ValueStateDelegate<T>;
}

class ValueListenableProvider<T>
    extends ValueDelegateWidget<ValueListenable<T>> {
  final Widget child;

  final UpdateShouldNotify<T> updateShouldNotify;

  ValueListenableProvider(ValueStateDelegate<ValueListenable<T>> delegate,
      this.updateShouldNotify, this.child)
      : super(delegate);

  Widget build() {
    return ValueListenableBuilder<T>(
      valueListenable: delegate.value,
      builder: (_, value, child) {
        return InheritedProvider<T>(
          value: value,
          updateShouldNotify: updateShouldNotify,
          child: child,
        );
      },
      child: child,
    );
  }
}

class ValueListenableBuilder<T> extends Widget {
  final ValueListenable<T> valueListenable;
  final ValueWidgetBuilder<T> builder;
  final Widget child;

  ValueListenableBuilder({this.valueListenable, this.builder, this.child});
}

void main() {
  print(create(42).valueListenable.value);
  print(create('foo').valueListenable.value);
}

ValueListenableBuilder<T> create<T>(T value) {
  ValueListenableImpl<T> valueListenable = new ValueListenableImpl<T>(value);
  ValueStateDelegateImpl<ValueListenable<T>> valueStateDelegate =
      new ValueStateDelegateImpl<ValueListenable<T>>(valueListenable);
  ValueListenableProvider<T> valueListenableProvider =
      new ValueListenableProvider<T>(valueStateDelegate, null, null);
  Widget widget = valueListenableProvider.build();
  print(value);
  return widget;
}
