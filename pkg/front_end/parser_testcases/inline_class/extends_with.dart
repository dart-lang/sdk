extension type ET1(int i) extends Foo {}
extension type ET2(int i) with Foo {}
extension type ET3(int i) with Foo, Bar {}
extension type ET4(int i) extends Foo with Bar {}
extension type ET5(int i) extends Foo with Bar, Baz {}
extension type ET6(int i) extends Foo implements Bar {}
extension type ET7(int i) with Foo implements Bar {}
extension type ET8(int i) with Foo, Bar implements Baz {}
extension type ET9(int i) extends Foo with Bar implements Baz {}
extension type ET10(int i) extends Foo with Bar, Baz implements Boz {}
extension type ET11(int i) implements Bar extends Foo {}
extension type ET12(int i) implements Bar with Foo {}
extension type ET13(int i) implements Bar with Foo, Bar {}
extension type ET14(int i) implements Bar extends Foo with Bar {}
extension type ET15(int i) implements Bar extends Foo with Bar, Baz {}
extension type ET16(int i) implements Bar extends Foo implements Bar {}
extension type ET17(int i) implements Bar with Foo implements Bar {}
extension type ET18(int i) implements Bar with Foo, Bar implements Baz {}
extension type ET19(int i) implements Bar extends Foo with Bar implements Baz {}
extension type ET20(int i) implements Bar extends Foo with Bar, Baz implements Boz {}
extension type ET21(int i) implements Bar implements Boz {}
extension type ET22(int i) extends Bar extends Boz {}
extension type ET23(int i) extends Bar, Boz {}
