import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/input_field.dart';
import '../widgets/primary_button.dart';

class AddIntervalSheet extends StatefulWidget {
  final String? initialId;
  final String? initialName;
  final int? initialDurationSeconds;
  final int? initialColorValue;
  final Function(String name, int duration, int color) onSave;

  const AddIntervalSheet({
    Key? key,
    this.initialId,
    this.initialName,
    this.initialDurationSeconds,
    this.initialColorValue,
    required this.onSave,
  }) : super(key: key);

  @override
  _AddIntervalSheetState createState() => _AddIntervalSheetState();
}

class _AddIntervalSheetState extends State<AddIntervalSheet> {
  late TextEditingController _nameController;
  late TextEditingController _minController;
  late TextEditingController _secController;
  late int _selectedColor;

  final List<Color> _availableColors = const [
    Color(0xFF3B82F6), // Focus (Blue)
    Color(0xFF10B981), // Rest (Green)
    Color(0xFFF59E0B), // Warm (Orange)
    Color(0xFFEF4444), // Warning (Red)
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    final dur = widget.initialDurationSeconds ?? 60;
    _minController = TextEditingController(text: (dur ~/ 60).toString());
    _secController = TextEditingController(text: (dur % 60).toString());
    _selectedColor = widget.initialColorValue ?? _availableColors[0].value;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors(isDark);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.initialId == null ? "Add Interval" : "Edit Interval",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          InputField(
            label: "Interval Name",
            controller: _nameController,
            hintText: "e.g., Work, Rest",
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InputField(
                  label: "Minutes",
                  controller: _minController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InputField(
                  label: "Seconds",
                  controller: _secController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Color",
            style: TextStyle(fontSize: 12, color: colors.mutedText, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: _availableColors.map((color) {
              final isSelected = _selectedColor == color.value;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color.value;
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: colors.primaryText, width: 3) : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: "Save Interval",
              onPressed: () {
                final name = _nameController.text.trim().isEmpty ? "Interval" : _nameController.text.trim();
                final min = int.tryParse(_minController.text) ?? 0;
                final sec = int.tryParse(_secController.text) ?? 0;
                final totalSec = (min * 60) + sec;
                
                if (totalSec > 0) {
                  widget.onSave(name, totalSec, _selectedColor);
                  Navigator.pop(context);
                }
              },
            ),
          )
        ],
      ),
    );
  }
}
