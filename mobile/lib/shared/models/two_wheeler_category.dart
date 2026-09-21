import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum TwoWheelerType { lite, moto, ev, express }

class TwoWheelerCategory {
  final String id;
  final String title;
  final String description;
  final TwoWheelerType type;
  final double baseFare;
  final double pricePerKm;
  final double pricePerMinute;
  final double platformFee;
  final double minimumFare;
  final int capacity;
  final String estimatedEtaText;
  final Color themeColor;
  final IconData iconData;

  const TwoWheelerCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.baseFare,
    required this.pricePerKm,
    required this.pricePerMinute,
    this.platformFee = 5.0,
    this.minimumFare = 25.0,
    this.capacity = 1,
    required this.estimatedEtaText,
    required this.themeColor,
    required this.iconData,
  });

  // Calculate estimated fare formula: base + (dist * rate) + (min * rate) + platformFee
  double calculateFare({required double distanceKm, required double durationMins, double surgeMultiplier = 1.0}) {
    double fare = baseFare + (distanceKm * pricePerKm) + (durationMins * pricePerMinute) + platformFee;
    fare = fare * surgeMultiplier;
    return fare < minimumFare ? minimumFare : fare;
  }

  static const List<TwoWheelerCategory> categories = [
    TwoWheelerCategory(
      id: 'cat_lite',
      title: 'Payano Lite',
      description: 'Compact scooter • Quick & economical',
      type: TwoWheelerType.lite,
      baseFare: 15.0,
      pricePerKm: 7.5,
      pricePerMinute: 1.0,
      capacity: 1,
      estimatedEtaText: '2 mins away',
      themeColor: AppColors.bikeLite,
      iconData: Icons.two_wheeler_outlined,
    ),
    TwoWheelerCategory(
      id: 'cat_moto',
      title: 'Payano Moto',
      description: 'Standard commuter bike • Fast rides',
      type: TwoWheelerType.moto,
      baseFare: 20.0,
      pricePerKm: 9.0,
      pricePerMinute: 1.2,
      capacity: 1,
      estimatedEtaText: '3 mins away',
      themeColor: AppColors.bikeMoto,
      iconData: Icons.two_wheeler,
    ),
    TwoWheelerCategory(
      id: 'cat_ev',
      title: 'Payano Green EV',
      description: 'Zero emission • Eco electric scooter',
      type: TwoWheelerType.ev,
      baseFare: 18.0,
      pricePerKm: 8.0,
      pricePerMinute: 1.0,
      capacity: 1,
      estimatedEtaText: '4 mins away',
      themeColor: AppColors.bikeEV,
      iconData: Icons.electric_bike,
    ),
    TwoWheelerCategory(
      id: 'cat_express',
      title: 'Payano Priority',
      description: 'Top rated driver • Instant pickup',
      type: TwoWheelerType.express,
      baseFare: 30.0,
      pricePerKm: 12.0,
      pricePerMinute: 1.5,
      capacity: 1,
      estimatedEtaText: '1 min away',
      themeColor: AppColors.bikeExpress,
      iconData: Icons.speed,
    ),
  ];
}
