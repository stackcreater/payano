import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/map_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/ride_model.dart';
import '../../ride/domain/ride_notifier.dart';

class LocationSearchScreen extends ConsumerStatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  ConsumerState<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends ConsumerState<LocationSearchScreen> {
  final TextEditingController _destinationController = TextEditingController();
  final MapService _mapService = MapService();
  Timer? _debounceTimer;
  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default Salem & Sona College places
    _predictions = MapService.defaultSalemPlaces;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _destinationController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _predictions = MapService.defaultSalemPlaces;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      final currentPickup = ref.read(rideNotifierProvider).pickup;
      final results = await _mapService.searchPlaces(
        query,
        proximityLat: currentPickup?.latitude,
        proximityLng: currentPickup?.longitude,
      );
      if (mounted) {
        setState(() {
          _predictions = results;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _selectPlace(PlacePrediction place) async {
    setState(() => _isLoading = true);

    LatLng coords;
    if (place.latitude != null && place.longitude != null) {
      coords = LatLng(place.latitude!, place.longitude!);
    } else {
      coords = await _mapService.getPlaceCoordinates(place.placeId, place.description) ??
          const LatLng(11.6756, 78.1470);
    }

    final point = LocationPoint(
      address: place.description,
      latitude: coords.latitude,
      longitude: coords.longitude,
      landmark: place.mainText,
    );

    ref.read(rideNotifierProvider.notifier).setDestination(point);

    if (mounted) {
      setState(() => _isLoading = false);
      context.pop();
    }
  }

  Future<void> _useCurrentLocationAsPickup() async {
    setState(() => _isLoading = true);
    final locService = ref.read(locationServiceProvider);
    final pos = await locService.getCurrentPosition();
    final point = LocationPoint(
      address: pos['address'] ?? LocationService.defaultAddress,
      latitude: pos['latitude'] as double,
      longitude: pos['longitude'] as double,
      landmark: 'Current GPS Location',
    );
    ref.read(rideNotifierProvider.notifier).setPickup(point);
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pickup set to: ${point.address}'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rideState = ref.watch(rideNotifierProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Search Destination', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      ),
      body: Column(
        children: [
          // Inputs Header Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Pickup Field (Green Dot)
                InkWell(
                  onTap: _useCurrentLocationAsPickup,
                  child: Row(
                    children: [
                      const Icon(Icons.my_location_rounded, color: AppColors.success, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F5F9),
                            borderRadius: AppRadius.borderSm,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  rideState.pickup?.address ?? LocationService.defaultAddress,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withAlpha(30),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'GPS Live',
                                  style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Destination Field (Primary Pin)
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _destinationController,
                        autofocus: true,
                        onChanged: _onSearchChanged,
                        style: TextStyle(
                          color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Where to? (e.g. Sona College, Salem)',
                          hintStyle: TextStyle(
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F5F9),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.borderSm,
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: _isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                )
                              : (_destinationController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _destinationController.clear();
                                        _onSearchChanged('');
                                      },
                                    )
                                  : null),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search Results List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _destinationController.text.isEmpty ? 'Popular in Salem / Campus' : 'Google Maps Predictions',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    if (_destinationController.text.isEmpty)
                      const Text('Campus Priority', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 8),

                ..._predictions.map((place) {
                  final isSona = place.placeId == 'sona_college_main';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSona ? AppColors.primary : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        width: isSona ? 1.5 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSona ? AppColors.primary.withAlpha(25) : const Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSona ? Icons.school_rounded : Icons.location_on,
                          color: AppColors.primary,
                          size: 19,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              place.mainText,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSona)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Default',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        place.secondaryText.isNotEmpty ? place.secondaryText : place.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                      onTap: () => _selectPlace(place),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
