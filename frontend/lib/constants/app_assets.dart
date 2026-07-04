/// Local image assets for homepage, about page, and category carousels.
class AppAssets {
  static const _root = 'lib/assets/images';

  static const cars = <({String name, String path})>[
    (name: 'پژو ۲۰۶', path: '$_root/cars/206.png'),
    (name: 'پژو ۲۰۶ SD', path: '$_root/cars/206sd.png'),
    (name: 'پژو ۴۰۵', path: '$_root/cars/405.png'),
    (name: 'پژو پارس', path: '$_root/cars/پارس.png'),
    (name: 'سمند', path: '$_root/cars/سمند.png'),
    (name: 'سمند سورن', path: '$_root/cars/سورن.png'),
    (name: 'دنا', path: '$_root/cars/دنا.png'),
    (name: 'رانا', path: '$_root/cars/رانا.png'),
    (name: 'تندر ۹۰', path: '$_root/cars/تندر-90.png'),
    (name: 'هایما', path: '$_root/cars/هایما.png'),
  ];

  static const equipments = <({String name, String path})>[
    (name: 'فن توربو', path: '$_root/equipments/2-fan-turbo-2.jpg'),
    (name: 'لنت ترمز', path: '$_root/equipments/brake-pad.jpg'),
    (name: 'کیت کلاچ', path: '$_root/equipments/clutch-kit.jpg'),
    (name: 'وایر شمع', path: '$_root/equipments/Engine-spark-plug-wire.jpg'),
    (name: 'قطعه KDS', path: '$_root/equipments/kds-.jpg'),
    (name: 'شمع', path: '$_root/equipments/spark-plug.jpg'),
    (name: 'قاب تسمه تایم', path: '$_root/equipments/Time-belt-frame.jpg'),
    (name: 'بلبرینگ تسمه', path: '$_root/equipments/Timing-belt-bearing.jpg'),
    (name: 'تسمه تایم', path: '$_root/equipments/Timing-belt.jpg'),
    (name: 'دیسک چرخ', path: '$_root/equipments/wheel-disc.jpg'),
  ];

  static const slideshow = [
    '$_root/slideshow/انواع-قطعات-مصرفی-خودرو-دکتر-یدکی (1).jpg',
    '$_root/slideshow/با-اسنپ-قسطی-بخر2.jpg',
  ];

  static const aboutUs = '$_root/about us/images.png';

  static const mapEmbedUrl =
      'https://maps.google.com/maps?q=35.8242,50.9910&z=15&hl=fa&output=embed';

  /// Interactive diagram images — prefer [catalog] folder, then [cars] for front view only.
  static const catalogDiagrams = <String, String>{
    'peugeot-pars': '$_root/catalog/persia.png',
    'samand-ef7': '$_root/catalog/samand.jpg',
  };

  /// Per-view diagram overrides: `vehicleId:viewId` → asset path.
  static const catalogViewDiagrams = <String, String>{
    // Add entries here as view-specific assets are provided.
  };

  static const _primaryDiagramViews = {'front', 'exterior'};

  static const vehicleDiagramFallbacks = <String, String>{
    'peugeot-206': '$_root/cars/206.png',
    'peugeot-pars': '$_root/cars/پارس.png',
    'peugeot-405': '$_root/cars/405.png',
    'samand-ef7': '$_root/cars/سمند.png',
    'dena-plus': '$_root/cars/دنا.png',
    'rana': '$_root/cars/رانا.png',
    'tara': '$_root/cars/روآ.png',
    'shahin': '$_root/cars/206.png',
  };

  static String smartCatalogDiagram(String vehicleId) =>
      catalogDiagrams[vehicleId] ??
      vehicleDiagramFallbacks[vehicleId] ??
      '$_root/cars/206.png';

  /// Returns a local asset path for a specific view, or empty when no image exists yet.
  static String smartCatalogViewDiagram(String vehicleId, String viewId) {
    final viewKey = '$vehicleId:$viewId';
    if (catalogViewDiagrams.containsKey(viewKey)) {
      return catalogViewDiagrams[viewKey]!;
    }
    if (_primaryDiagramViews.contains(viewId) && catalogDiagrams.containsKey(vehicleId)) {
      return catalogDiagrams[vehicleId]!;
    }
    return '';
  }

  static String smartCatalogThumbnail(String vehicleId) => smartCatalogDiagram(vehicleId);
}
