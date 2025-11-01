import 'package:hive/hive.dart';

part 'section.g.dart';

@HiveType(typeId: 0)
class Section extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  Section({
    required this.id,
    required this.name,
  });

  static List<Section> getDefaultSections() {
    return [
      Section(id: 'dry_produce', name: 'Dry Produce (Dry Pro)'),
      Section(id: 'wet_produce', name: 'Wet Produce (Wet Pro)'),
      Section(id: 'fresh', name: 'Fresh'),
      Section(id: 'milk_yogurt', name: 'Milk/Yogurt (Box)'),
      Section(id: 'meat', name: 'Meat'),
      Section(id: 'cut_cheeses', name: 'Cut Cheeses'),
      Section(id: 'flowers', name: 'Flowers'),
      Section(id: 'coffee_tea', name: 'Coffee & Tea'),
      Section(id: 'cookie_candy', name: 'Cookie & Candy'),
      Section(id: 'snacks', name: 'Snacks'),
      Section(id: 'bread', name: 'Bread'),
      Section(id: 'dfn', name: 'DFN (Dried Fruit & Nuts)'),
      Section(id: 'beverage', name: 'Beverage'),
      Section(id: 'beer_wine', name: 'Beer & Wine'),
      Section(id: 'haba', name: 'HABA (Health & Beauty)'),
      Section(id: 'deli_dips', name: 'Deli/Dips'),
      Section(id: 'grocery', name: 'Grocery'),
      Section(id: 'frozen', name: 'Frozen'),
      Section(id: 'eggs', name: 'Eggs'),
    ];
  }
}
