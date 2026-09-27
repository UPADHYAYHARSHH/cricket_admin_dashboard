import 'package:flutter/material.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import 'package:cricket_admin_panel/admin/data/models/sport_model.dart';
import 'sport_views.dart';

/// Result of the add / edit form.
typedef SportFormResult = ({
  String name,
  String slug,
  String iconUrl,
  String localAsset,
  String color,
  int sortOrder,
});

/// Add or edit a sport.
///
/// One dialog serves both cases, which removes the duplicated six-field form
/// that previously existed twice. Every controller is disposed on close, and a
/// blank name now reports an error instead of silently doing nothing.
class SportFormDialog extends StatefulWidget {
  const SportFormDialog({super.key, this.existing});

  /// `null` creates a new sport.
  final SportModel? existing;

  bool get isEditing => existing != null;

  static Future<SportFormResult?> show(
    BuildContext context, {
    SportModel? existing,
  }) {
    return showDialog<SportFormResult>(
      context: context,
      builder: (_) => SportFormDialog(existing: existing),
    );
  }

  @override
  State<SportFormDialog> createState() => _SportFormDialogState();
}

class _SportFormDialogState extends State<SportFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  late final TextEditingController _iconUrlController;
  late final TextEditingController _localAssetController;
  late final TextEditingController _colorController;
  late final TextEditingController _sortOrderController;

  /// True once the admin edits the slug by hand, after which it is no longer
  /// derived from the name.
  bool _slugEditedByHand = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _nameController = TextEditingController(text: existing?.name ?? '');
    _slugController = TextEditingController(text: existing?.slug ?? '');
    _iconUrlController = TextEditingController(text: existing?.iconUrl ?? '');
    _localAssetController =
        TextEditingController(text: existing?.localAsset ?? '');
    _colorController =
        TextEditingController(text: existing?.color ?? '#1B5E20');
    _sortOrderController =
        TextEditingController(text: '${existing?.sortOrder ?? 0}');

    if (existing != null && existing.slug.isNotEmpty) {
      _slugEditedByHand = true;
    }

    _colorController.addListener(_onColorChanged);
  }

  @override
  void dispose() {
    _colorController.removeListener(_onColorChanged);
    _nameController.dispose();
    _slugController.dispose();
    _iconUrlController.dispose();
    _localAssetController.dispose();
    _colorController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  void _onColorChanged() => setState(() {});

  /// Mirrors the slug derivation the previous dialog used.
  static String slugify(String input) => input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '_')
      .replaceAll(RegExp(r'_+'), '_');

  void _onNameChanged(String value) {
    if (_slugEditedByHand) return;
    _slugController.text = slugify(value);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.pop(
      context,
      (
        name: _nameController.text.trim(),
        slug: _slugController.text.trim(),
        iconUrl: _iconUrlController.text.trim(),
        localAsset: _localAssetController.text.trim(),
        color: _colorController.text.trim(),
        sortOrder: int.tryParse(_sortOrderController.text.trim()) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewColor = parseHexColor(_colorController.text);

    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit sport' : 'Add sport'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: !widget.isEditing,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g. Box Cricket',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _onNameChanged,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _slugController,
                  decoration: InputDecoration(
                    labelText: 'Slug',
                    hintText: 'box_cricket',
                    helperText: _slugEditedByHand
                        ? 'Used by the apps to identify this sport'
                        : 'Derived from the name',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => _slugEditedByHand = true,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty)
                          ? 'Slug is required'
                          : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _iconUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Icon URL (optional)',
                    hintText: 'https://…',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _localAssetController,
                  decoration: const InputDecoration(
                    labelText: 'Local asset (optional)',
                    hintText: 'assets/images/sports/sport1.png',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 10),
                      child: SportColorSwatch(
                        hex: _colorController.text,
                        size: 28,
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _colorController,
                        decoration: InputDecoration(
                          labelText: 'Colour (hex)',
                          hintText: '#1B5E20',
                          helperText: previewColor == null
                              ? 'Not a recognised hex colour'
                              : null,
                          helperStyle: previewColor == null
                              ? TextStyle(color: theme.colorScheme.error)
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            parseHexColor(value) == null
                                ? 'Enter a hex colour such as #1B5E20'
                                : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _sortOrderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sort order',
                    helperText: 'Lower numbers appear first in the apps',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) return null;
                    if (int.tryParse(trimmed) == null) {
                      return 'Must be a whole number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryDarkGreen,
          ),
          child: Text(widget.isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

/// Confirmation before deleting a sport.
Future<bool> confirmDeleteSport(
  BuildContext context,
  SportModel sport,
) async {
  final theme = Theme.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete sport'),
      content: Text(
        'Delete "${sport.name}"?\n\n'
        'It will disappear from the apps immediately, and any ground '
        'categorised under it will no longer match a sport.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}
