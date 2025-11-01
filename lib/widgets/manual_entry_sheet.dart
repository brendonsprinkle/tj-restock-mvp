import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/haptics_service.dart';
import '../state/app_state.dart';

class ManualEntrySheet extends ConsumerStatefulWidget {
  const ManualEntrySheet({super.key});

  @override
  ConsumerState<ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends ConsumerState<ManualEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _labelController = TextEditingController();

  @override
  void dispose() {
    _barcodeController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedSection = ref.read(selectedSectionProvider);
    if (selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a section first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final barcode = _barcodeController.text.trim();
    final label = _labelController.text.trim();

    final notifier = ref.read(pickEntriesProvider.notifier);
    final added = await notifier.addEntry(
      barcodeOrText: barcode.isEmpty ? 'manual:$label' : barcode,
      labelText: label.isEmpty ? null : label,
      sectionId: selectedSection.id,
    );

    if (added) {
      await HapticsService.success();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added: ${label.isEmpty ? barcode : label}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item already exists in this section'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Manual Entry',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: 'Barcode (optional)',
                hintText: 'Enter barcode number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label / Description',
                hintText: 'e.g., Pumpkin Seeds - Salted',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if ((value == null || value.trim().isEmpty) &&
                    _barcodeController.text.trim().isEmpty) {
                  return 'Please enter either a barcode or label';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Add to Pick List',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
