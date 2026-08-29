import 'package:flutter/material.dart';
import 'package:miruna/domain/cooldown.dart';
import 'package:miruna/domain/duration_format.dart';

class PeriodPicker extends StatelessWidget {
  const PeriodPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final Duration value;
  final ValueChanged<Duration> onChanged;

  @override
  Widget build(BuildContext context) {
    final isPreset = Cooldown.presets.contains(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in Cooldown.presets)
              ChoiceChip(
                label: Text(formatWarningPeriod(preset)),
                selected: value == preset,
                onSelected: (_) => onChanged(preset),
              ),
            ChoiceChip(
              label: Text(
                isPreset ? 'カスタム' : formatWarningPeriod(value),
              ),
              selected: !isPreset,
              onSelected: (_) => _pickCustom(context),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickCustom(BuildContext context) async {
    final hoursController = TextEditingController(
      text: '${value.inHours}',
    );
    final minutesController = TextEditingController(
      text: '${value.inMinutes.remainder(60)}',
    );
    final result = await showDialog<Duration>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('警告期間'),
          content: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: hoursController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '時間'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: minutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '分'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                final hours = int.tryParse(hoursController.text) ?? 0;
                final minutes = int.tryParse(minutesController.text) ?? 0;
                final duration = Duration(hours: hours, minutes: minutes);
                if (duration < const Duration(minutes: 1)) {
                  Navigator.pop(context, const Duration(minutes: 1));
                } else {
                  Navigator.pop(context, duration);
                }
              },
              child: const Text('設定'),
            ),
          ],
        );
      },
    );
    hoursController.dispose();
    minutesController.dispose();
    if (result != null) {
      onChanged(result);
    }
  }
}
