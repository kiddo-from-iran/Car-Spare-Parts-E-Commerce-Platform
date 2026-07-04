import '../../constants/app_assets.dart';
import '../../models/smart_catalog.dart';

/// Applies local catalog/car asset paths to API vehicle data.
CatalogVehicleDetail localizeCatalogVehicle(CatalogVehicleDetail vehicle) {
  final image = AppAssets.smartCatalogThumbnail(vehicle.id);
  return CatalogVehicleDetail(
    id: vehicle.id,
    name: vehicle.name,
    subtitle: vehicle.subtitle,
    year: vehicle.year,
    brandLogo: vehicle.brandLogo,
    image: image,
    views: vehicle.views
        .map(
          (view) => CatalogView(
            id: view.id,
            name: view.name,
            image: AppAssets.smartCatalogViewDiagram(vehicle.id, view.id),
          ),
        )
        .toList(),
    categories: vehicle.categories,
  );
}

CatalogVehicleSummary localizeCatalogVehicleSummary(CatalogVehicleSummary vehicle) {
  return CatalogVehicleSummary(
    id: vehicle.id,
    name: vehicle.name,
    subtitle: vehicle.subtitle,
    year: vehicle.year,
    brandLogo: vehicle.brandLogo,
    image: AppAssets.smartCatalogThumbnail(vehicle.id),
  );
}

List<CatalogVehicleSummary> localizeCatalogVehicles(List<CatalogVehicleSummary> vehicles) =>
    vehicles.map(localizeCatalogVehicleSummary).toList();
