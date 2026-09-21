import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  List<LocationPoint> _searchHits = [];

  final List<LocationPoint> _popularPlaces = [
    LocationPoint(
      address: 'Koramangala 5th Block, Forum Mall Junction, Bengaluru',
      latitude: 12.9352,
      longitude: 77.6245,
      landmark: 'Popular Hotspot',
    ),
    LocationPoint(
      address: 'Indiranagar 100ft Road, Metro Station, Bengaluru',
      latitude: 12.9784,
      longitude: 77.6408,
      landmark: 'Shopping & Dining',
    ),
    LocationPoint(
      address: 'Whitefield ITPL Main Road, Tech Park, Bengaluru',
      latitude: 12.9863,
      longitude: 77.7380,
      landmark: 'IT Hub',
    ),
    LocationPoint(
      address: 'Electronic City Phase 1, Elevated Expressway, Bengaluru',
      latitude: 12.8452,
      longitude: 77.6602,
      landmark: 'Tech Campus',
    ),
    LocationPoint(
      address: 'Kempegowda International Airport (BLR), Devanahalli',
      latitude: 13.1986,
      longitude: 77.7066,
      landmark: 'Airport Terminal',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchHits = _popularPlaces;
  }

  void _filterPlaces(String query) {
    if (query.isEmpty) {
      setState(() => _searchHits = _popularPlaces);
    } else {
      setState(() {
        _searchHits = _popularPlaces
            .where((p) => p.address.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  void _selectLocation(LocationPoint point) {
    ref.read(rideNotifierProvider.notifier).setDestination(point);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rideState = ref.watch(rideNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Destination'),
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
                Row(
                  children: [
                    const Icon(Icons.circle, color: AppColors.success, size: 14),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Text(
                          rideState.pickup?.address ?? 'Current Location',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Destination Field (Yellow Pin)
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _destinationController,
                        autofocus: true,
                        onChanged: _filterPlaces,
                        decoration: InputDecoration(
                          hintText: 'Where to? (e.g. Koramangala)',
                          hintStyle: TextStyle(
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.borderSm,
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Saved & Popular Search Results List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Popular Destinations',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 10),
                ..._searchHits.map((place) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                    ),
                    title: Text(
                      place.address.split(',').first,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Text(
                      place.address,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        place.landmark,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    onTap: () => _selectLocation(place),
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
