// Data model for complex tests.

class Person {
  String name;
  int age;
  List<Search> searches;

  Person(this.name, this.age, this.searches);
}

class Search {
  String query;
  int rank;
  int total;
  List<Metric> metrics;

  Search(this.query, this.rank, this.total, this.metrics);
}

class Metric {
  String country;
  int quantity;

  Metric(this.country, this.quantity);

  static int grandTotal(List<Metric> metrics) {
    int total = 0;
    for (final metric in metrics) {
      total += metric.quantity;
    }

    return total;
  }
}

List<Person> get dataModel {
  List<Person> persons = [];

  List<Search> searches = [];
  List<Metric> metrics = [];

  // Snooki data
  metrics = [];
  metrics.add(new Metric("USA", 200300312));
  searches.add(new Search("intellect", 6, Metric.grandTotal(metrics), metrics));

  metrics.add(new Metric("USA", 75000000));
  metrics.add(new Metric("China", 5));
  metrics.add(new Metric("EU", 110000));
  metrics.add(new Metric("Canada", 3400000));
  metrics.add(new Metric("Mexico", 20000));
  searches.add(new Search("breading", 5, Metric.grandTotal(metrics), metrics));

  metrics = [];
  metrics.add(new Metric("USA", 5000000));
  metrics.add(new Metric("China", 3));
  metrics.add(new Metric("EU", 90000));
  metrics.add(new Metric("Canada", 3100000));
  metrics.add(new Metric("Mexico", 24000));
  searches.add(new Search("booze", 8, Metric.grandTotal(metrics), metrics));

  metrics = [];
  metrics.add(new Metric("USA", 5000000));
  metrics.add(new Metric("EU", 90000));
  metrics.add(new Metric("Canada", 300000));
  searches.add(new Search("turpitude", 10, Metric.grandTotal(metrics), metrics));

  persons.add(new Person("Snooki", 24, searches));

  // Lady Gaga
  searches = [];

  metrics = [];
  metrics.add(new Metric("USA", 11000000));
  metrics.add(new Metric("China", 5000000000));
  metrics.add(new Metric("EU", 8700000));
  metrics.add(new Metric("Canada", 3400000));
  metrics.add(new Metric("Mexico", 24349898));
  searches.add(new Search("bad romance", 3, Metric.grandTotal(metrics), metrics));

  metrics = [];
  metrics.add(new Metric("USA", 980000));
  metrics.add(new Metric("China", 187000000));
  searches.add(new Search("fashion", 7,  Metric.grandTotal(metrics), metrics));

  metrics = [];
  metrics.add(new Metric("USA", 7630000));
  searches.add(new Search("outrageous", 9,  Metric.grandTotal(metrics), metrics));

  persons.add(new Person("Lady Gaga", 25, searches));

  // Uggie (The Artist dog)
  searches = [];

  metrics = [];
  metrics.add(new Metric("USA", 1000000));
  metrics.add(new Metric("China", 34000));
  metrics.add(new Metric("EU", 11000000000));
  metrics.add(new Metric("Canada", 5023));
  metrics.add(new Metric("Mexico", 782));
  searches.add(new Search("smart", 2, Metric.grandTotal(metrics), metrics));

  metrics = [];
  metrics.add(new Metric("USA", 18900000));
  metrics.add(new Metric("China", 34000));
  metrics.add(new Metric("EU", 990000000));
  metrics.add(new Metric("Canada", 6739920));
  searches.add(new Search("cute", 4, Metric.grandTotal(metrics), metrics));

  metrics = [];
  metrics.add(new Metric("USA", 1));
  metrics.add(new Metric("China", 1500000000000));
  metrics.add(new Metric("EU", 50));
  metrics.add(new Metric("Canada", 0));
  metrics.add(new Metric("Mexico", 7801));
  searches.add(new Search("tasty", 1, Metric.grandTotal(metrics), metrics));

  persons.add(new Person("Uggie (Artist dog)", 10, searches));

  return persons;
}

