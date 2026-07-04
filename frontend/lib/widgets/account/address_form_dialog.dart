import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../l10n/app_strings.dart';
import '../../models/address.dart';
import '../../theme/app_theme.dart';

class AddressFormResult {
  const AddressFormResult({
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final String address;
  final double latitude;
  final double longitude;
}

/// Full-width dialog for adding/editing a saved address with map picker.
Future<AddressFormResult?> showAddressFormDialog(
  BuildContext context, {
  UserAddress? existing,
}) {
  return showDialog<AddressFormResult>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _AddressFormDialog(existing: existing),
  );
}

class _AddressFormDialog extends StatefulWidget {
  const _AddressFormDialog({this.existing});

  final UserAddress? existing;

  @override
  State<_AddressFormDialog> createState() => _AddressFormDialogState();
}

class _AddressFormDialogState extends State<_AddressFormDialog> {
  static const _defaultCenter = LatLng(35.6892, 51.3890);

  late final TextEditingController _label;
  late final TextEditingController _address;
  late final MapController _mapController;
  LatLng? _marker;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _label = TextEditingController(text: existing?.label ?? 'خانه');
    _address = TextEditingController(text: existing?.address ?? '');
    _mapController = MapController();
    if (existing?.latitude != null && existing?.longitude != null) {
      _marker = LatLng(existing!.latitude!, existing.longitude!);
    } else {
      _marker = _defaultCenter;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_marker != null) {
        _mapController.move(_marker!, 14);
      }
    });
  }

  @override
  void dispose() {
    _label.dispose();
    _address.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _submit() {
    final label = _label.text.trim();
    final address = _address.text.trim();
    if (label.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عنوان و آدرس الزامی است')),
      );
      return;
    }
    if (_marker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('موقعیت را روی نقشه مشخص کنید')),
      );
      return;
    }
    Navigator.pop(
      context,
      AddressFormResult(
        label: label,
        address: address,
        latitude: _marker!.latitude,
        longitude: _marker!.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final dialogWidth = width > 900 ? 720.0 : (width - 32).clamp(320.0, 720.0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: 680),
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                color: AppColors.black,
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.gold, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.existing == null ? AppStrings.addAddress : AppStrings.editAddress,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textOnDark,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppColors.textOnDark),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _label,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          labelText: AppStrings.addressLabel,
                          hintText: 'مثلاً: خانه، محل کار',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _address,
                        textAlign: TextAlign.right,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: AppStrings.address,
                          hintText: 'آدرس کامل را وارد کنید',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'موقعیت روی نقشه',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'روی نقشه کلیک کنید تا محل دقیق آدرس مشخص شود',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 280,
                          child: Stack(
                            children: [
                              FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: _marker ?? _defaultCenter,
                                  initialZoom: 14,
                                  onTap: (_, point) => setState(() => _marker = point),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.jahangiri.frontend',
                                  ),
                                  if (_marker != null)
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: _marker!,
                                          width: 44,
                                          height: 44,
                                          child: const Icon(
                                            Icons.location_pin,
                                            color: AppColors.gold,
                                            size: 44,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              Positioned(
                                bottom: 10,
                                left: 10,
                                child: Material(
                                  color: AppColors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() => _marker = _defaultCenter);
                                      _mapController.move(_defaultCenter, 14);
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.my_location, size: 16, color: AppColors.gold),
                                          SizedBox(width: 6),
                                          Text('تهران', style: TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(AppStrings.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.textOnGold,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(AppStrings.save),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
