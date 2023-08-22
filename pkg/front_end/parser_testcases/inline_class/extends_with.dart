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
