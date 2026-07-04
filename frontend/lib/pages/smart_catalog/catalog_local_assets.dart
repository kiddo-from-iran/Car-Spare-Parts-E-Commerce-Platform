import '../../constants/app_assets.dart';
import '../../models/smart_catalog.dart';

String _resolveVehicleImage(String vehicleId, String apiImage) {
  if (apiImage.isNotEmpty) return apiImage;
  return AppAssets.smartCatalogThumbnail(vehicleId);
}

String _resolveViewImage(String vehicleId, String viewId, String apiImage) {
  if (apiImage.isNotEmpty) return apiImage;
  return AppAssets.smartCatalogViewDiagram(vehicleId, viewId);
}

/// Keeps uploaded/API image URLs; falls back to bundled assets for legacy catalogs.
CatalogVehicleDetail localizeCatalogVehicle(CatalogVehicleDetail vehicle) {
  return CatalogVehicleDetail(
    id: vehicle.id,
    name: vehicle.name,
    subtitle: vehicle.subtitle,
    year: vehicle.year,
    brandLogo: vehicle.brandLogo,
    image: _resolveVehicleImage(vehicle.id, vehicle.image),
    views: vehicle.views
        .map(
          (view) => CatalogView(
            id: view.id,
            name: view.name,
            image: _resolveViewImage(vehicle.id, view.id, view.image),
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
    image: _resolveVehicleImage(vehicle.id, vehicle.image),
  );
}

List<CatalogVehicleSummary> localizeCatalogVehicles(List<CatalogVehicleSummary> vehicles) =>
    vehicles.map(localizeCatalogVehicleSummary).toList();
