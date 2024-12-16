import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/questionnaire.dart';
import '../providers/app_state_provider.dart';
import '../services/database_helper.dart';

class QuestionnaireScreen extends StatefulWidget {
  final int polygonId;

  const QuestionnaireScreen({super.key, required this.polygonId});

  @override
  _QuestionnaireScreenState createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();

  // Dropdown options
  final List<String> landUseTypes = [
    'Maison',
    'Cimetière',
    'Terrain vide',
    'Commerce',
    'Espace public',
    'Autre'
  ];

  final List<String> buildingTypes = [
    'Moderne',
    'Traditionnel',
    'En construction',
    'Abandonné',
    'Autre'
  ];

  final List<String> roofMaterials = [
    'Tôle',
    'Tuile',
    'Béton',
    'Chaume',
    'Autre'
  ];

  final List<String> ownershipStatuses = [
    'Propriété privée',
    'Location',
    'Terrain communal',
    'Terrain public',
    'Autre'
  ];

  // Form controllers
  String? _landUseType;
  bool _isOccupied = false;
  int? _householdCount;
  String? _buildingType;
  String? _roofMaterial;
  bool _hasElectricity = false;
  bool _hasWaterAccess = false;
  String? _ownershipStatus;
  String? _additionalComments;

  @override
  void initState() {
    super.initState();
    _checkExistingQuestionnaire();
  }

  Future<void> _checkExistingQuestionnaire() async {
    final existingQuestionnaire = await DatabaseHelper.instance
        .getQuestionnaireByPolygonId(widget.polygonId);

    if (existingQuestionnaire != null) {
      _showExistingQuestionnaireDialog(existingQuestionnaire);
    }
  }

  void _showExistingQuestionnaireDialog(Questionnaire existingQuestionnaire) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Questionnaire existant'),
        content: const Text('Un questionnaire existe déjà pour ce polygone. Voulez-vous le remplacer ?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _populateExistingQuestionnaire(existingQuestionnaire);
            },
            child: const Text('Oui'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Non'),
          ),
        ],
      ),
    );
  }

  void _populateExistingQuestionnaire(Questionnaire questionnaire) {
    setState(() {
      _landUseType = questionnaire.landUseType;
      _isOccupied = questionnaire.isOccupied;
      _householdCount = questionnaire.householdCount;
      _buildingType = questionnaire.buildingType;
      _roofMaterial = questionnaire.roofMaterial;
      _hasElectricity = questionnaire.hasElectricity;
      _hasWaterAccess = questionnaire.hasWaterAccess;
      _ownershipStatus = questionnaire.ownershipStatus;
      _additionalComments = questionnaire.additionalComments;
    });
  }

  void _submitQuestionnaire() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final questionnaire = Questionnaire(
        polygoneId: widget.polygonId,
        landUseType: _landUseType!,
        isOccupied: _isOccupied,
        householdCount: _householdCount,
        buildingType: _buildingType!,
        roofMaterial: _roofMaterial!,
        hasElectricity: _hasElectricity,
        hasWaterAccess: _hasWaterAccess,
        ownershipStatus: _ownershipStatus!,
        additionalComments: _additionalComments,
      );

      // First delete any existing questionnaire
      await DatabaseHelper.instance.deleteQuestionnaireForPolygon(widget.polygonId);

      // Insert new questionnaire
      final result = await DatabaseHelper.instance.insertQuestionnaire(questionnaire);

      if (result != -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Questionnaire enregistré avec succès')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'enregistrement'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Questionnaire du Polygone'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Land Use Type Dropdown
              DropdownButtonFormField<String>(
                value: _landUseType,
                decoration: const InputDecoration(
                  labelText: 'Type d\'occupation du terrain',
                ),
                items: landUseTypes.map((type) =>
                    DropdownMenuItem(value: type, child: Text(type))
                ).toList(),
                validator: (value) => value == null ? 'Veuillez sélectionner un type' : null,
                onChanged: (value) => setState(() => _landUseType = value),
              ),

              // Occupation Status
              SwitchListTile(
                title: const Text('Le terrain est-il occupé ?'),
                value: _isOccupied,
                onChanged: (bool value) => setState(() => _isOccupied = value),
              ),

              // Household Count (only if occupied)
              if (_isOccupied)
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nombre de ménages',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Veuillez entrer un nombre';
                    return null;
                  },
                  onSaved: (value) => _householdCount = int.tryParse(value ?? '0'),
                ),

              // Building Type Dropdown
              DropdownButtonFormField<String>(
                value: _buildingType,
                decoration: const InputDecoration(
                  labelText: 'Type de bâtiment',
                ),
                items: buildingTypes.map((type) =>
                    DropdownMenuItem(value: type, child: Text(type))
                ).toList(),
                validator: (value) => value == null ? 'Veuillez sélectionner un type' : null,
                onChanged: (value) => setState(() => _buildingType = value),
              ),

              // Roof Material Dropdown
              DropdownButtonFormField<String>(
                value: _roofMaterial,
                decoration: const InputDecoration(
                  labelText: 'Matériau de toiture',
                ),
                items: roofMaterials.map((material) =>
                    DropdownMenuItem(value: material, child: Text(material))
                ).toList(), // Correction : .tolist() -> .toList()
                validator: (value) => value == null ? 'Veuillez sélectionner un matériau' : null,
                onChanged: (value) => setState(() => _roofMaterial = value),
              ),

              // Electricity and Water Access
              CheckboxListTile(
                title: const Text('Accès à l\'électricité'),
                value: _hasElectricity,
                onChanged: (bool? value) => setState(() => _hasElectricity = value ?? false),
              ),
              CheckboxListTile(
                title: const Text('Accès à l\'eau'),
                value: _hasWaterAccess,
                onChanged: (bool? value) => setState(() => _hasWaterAccess = value ?? false),
              ),

              // Ownership Status Dropdown
              DropdownButtonFormField<String>(
                value: _ownershipStatus,
                decoration: const InputDecoration(
                  labelText: 'Statut de propriété',
                ),
                items: ownershipStatuses.map((status) =>
                    DropdownMenuItem(value: status, child: Text(status))
                ).toList(),
                validator: (value) => value == null ? 'Veuillez sélectionner un statut' : null,
                onChanged: (value) => setState(() => _ownershipStatus = value),
              ),

              // Additional Comments
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Commentaires supplémentaires',
                  hintText: 'Informations complémentaires...',
                ),
                maxLines: 3,
                onSaved: (value) => _additionalComments = value,
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _submitQuestionnaire,
                child: const Text('Enregistrer le Questionnaire'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}