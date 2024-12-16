import 'dart:convert';

class Questionnaire {
  final int? id;
  final int polygoneId;

  // Different types of questions
  final String landUseType; // Dropdown (Maison, Cimetière, Terrain vide, etc.)
  final bool isOccupied; // Boolean
  final int? householdCount; // Numeric input
  final String buildingType; // Dropdown (Moderne, Traditionnel, En construction, etc.)
  final String roofMaterial; // Dropdown
  final bool hasElectricity; // Boolean
  final bool hasWaterAccess; // Boolean
  final String ownershipStatus; // Dropdown
  final String? additionalComments; // Text input

  Questionnaire({
    this.id,
    required this.polygoneId,
    required this.landUseType,
    required this.isOccupied,
    this.householdCount,
    required this.buildingType,
    required this.roofMaterial,
    required this.hasElectricity,
    required this.hasWaterAccess,
    required this.ownershipStatus,
    this.additionalComments,
  });

  // Convert to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'polygone_id': polygoneId,
      'land_use_type': landUseType,
      'is_occupied': isOccupied ? 1 : 0,
      'household_count': householdCount,
      'building_type': buildingType,
      'roof_material': roofMaterial,
      'has_electricity': hasElectricity ? 1 : 0,
      'has_water_access': hasWaterAccess ? 1 : 0,
      'ownership_status': ownershipStatus,
      'additional_comments': additionalComments,
    };
  }

  // Create from Map retrieved from database
  factory Questionnaire.fromMap(Map<String, dynamic> map) {
    return Questionnaire(
      id: map['id'],
      polygoneId: map['polygone_id'],
      landUseType: map['land_use_type'],
      isOccupied: map['is_occupied'] == 1,
      householdCount: map['household_count'],
      buildingType: map['building_type'],
      roofMaterial: map['roof_material'],
      hasElectricity: map['has_electricity'] == 1,
      hasWaterAccess: map['has_water_access'] == 1,
      ownershipStatus: map['ownership_status'],
      additionalComments: map['additional_comments'],
    );
  }

  // JSON serialization
  String toJson() => json.encode(toMap());
  factory Questionnaire.fromJson(String source) =>
      Questionnaire.fromMap(json.decode(source));
}