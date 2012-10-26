#import('dart:html');
#source('realviews.dart');

class Division {
  String name;
  int id;
  List<Product> products;

  Division(this.name, this.id, this.products);
}

class Product {
  int id;
  String name;
  int users;
  List<YTD_Sales> sales;

  Product(this.id, this.name, this.users, this.sales);
}

class YTD_Sales {
  int yearly;
  String country;

  YTD_Sales(this.yearly, this.country);
}

// TODO(terry): Remove use for debug only.
void debug() {
  try {
    throw "DEBUG";
  } catch (e) {
    print("DEBUGBREAK");
  }
}

void main() {
  List<Division> divisions = [];
  List<Product> products;
  List<YTD_Sales> sales;

  products = [];
  sales = [];
  sales.add(new YTD_Sales(52000000, "USA"));
  sales.add(new YTD_Sales(550000, "China"));
  sales.add(new YTD_Sales(56000000, "EU"));
  sales.add(new YTD_Sales(510000, "Canada"));
  sales.add(new YTD_Sales(58700028, "Mexico"));
  products.add(new Product(100, "Gmail", 75000000, sales));

  sales = [];
  sales.add(new YTD_Sales(12000000, "USA"));
  sales.add(new YTD_Sales(50000, "China"));
  sales.add(new YTD_Sales(6000000, "EU"));
  sales.add(new YTD_Sales(10000, "Canada"));
  sales.add(new YTD_Sales(8700028, "Mexico"));
  products.add(new Product(101, "Talk", 5000000, sales));
  divisions.add(new Division("Apps", 1, products));

  products = [];
  sales = [];
  sales.add(new YTD_Sales(200000, "USA"));
  sales.add(new YTD_Sales(20000, "China"));
  sales.add(new YTD_Sales(2200000, "EU"));
  sales.add(new YTD_Sales(10000, "Canada"));
  sales.add(new YTD_Sales(100, "Mexico"));
  products.add(new Product(200, "iGoogle", 2000000, sales));
  divisions.add(new Division("Misc", 3, products));

  products = [];
  sales = [];
  sales.add(new YTD_Sales(1200, "USA"));
  sales.add(new YTD_Sales(50, "China"));
  sales.add(new YTD_Sales(600, "EU"));
  sales.add(new YTD_Sales(10, "Canada"));
  sales.add(new YTD_Sales(8, "Mexico"));
  products.add(new Product(300, "Dart", 2000, sales));
  divisions.add(new Division("Chrome", 2, products));

  products = [];
  sales = [];
  divisions.add(new Division("Search", 4, products));

  var header = new Header("Google World Wide", new Date.now());
  var listView = new DivisionSales(divisions);

  document.body.elements.add(header.root);                 // Add top view.
  document.body.elements.add(listView.root);               // Add list view.

  // Hookup events.
  for (var elem in listView.productZippy) {
    elem.on.click.add((MouseEvent e) {
      var expandCollapseElem = e.toElement;

      DivElement salesDiv = expandCollapseElem.parent.elements.last;

      bool showSales = (salesDiv.classes.contains(DivisionSales.showSales));

      expandCollapseElem.innerHTML = showSales ? "&#9654;": "&#9660;";
      expandCollapseElem.classes.remove(showSales ? DivisionSales.expand : DivisionSales.collapse);
      expandCollapseElem.classes.add(showSales ? DivisionSales.collapse : DivisionSales.expand);

      salesDiv.classes.clear();
      salesDiv.classes.add(showSales ? DivisionSales.hideSales : DivisionSales.showSales);
    });
  }
}

