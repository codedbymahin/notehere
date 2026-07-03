import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../providers/note_provider.dart';
import '../widgets/centered_max_width.dart';

/// Screen used for both creating and editing a note.
///
/// When [noteId] is provided the screen looks up the note in the
/// provider's cache (or fetches it from Firestore) and pre-fills the
/// form with its current values.
class AddEditNoteScreen extends StatefulWidget {
  const AddEditNoteScreen({super.key, this.noteId});

  final String? noteId;

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  static const int _titleMaxLength = 80;
  static const int _descriptionMaxLength = 4000;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocus = FocusNode();
  final _descriptionFocus = FocusNode();

  Note? _initialNote;
  bool _isHydrating = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onTextChanged);
    _descriptionController.addListener(_onTextChanged);
    if (_isEditing) {
      _hydrateFromProvider();
    } else {
      // Auto-focus the title field on create so the keyboard is ready.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _titleFocus.requestFocus();
      });
    }
  }

  bool get _isEditing => widget.noteId != null && widget.noteId!.isNotEmpty;

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _hydrateFromProvider() async {
    setState(() => _isHydrating = true);
    try {
      final note = await context.read<NoteProvider>().getNote(widget.noteId!);
      if (!mounted) return;
      if (note != null) {
        _initialNote = note;
        _titleController.text = note.title;
        _descriptionController.text = note.description;
      }
    } finally {
      if (mounted) {
        setState(() => _isHydrating = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _titleFocus.requestFocus();
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _descriptionController.removeListener(_onTextChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  String? _validateTitle(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Please give your note a title.';
    return null;
  }

  String? _validateDescription(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Add a description before saving.';
    return null;
  }

  Future<void> _onSave() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<NoteProvider>();

    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        final updated =
            (_initialNote ?? Note.newDraft(title: '', description: ''))
                .copyWith(
                  id: widget.noteId,
                  title: _titleController.text.trim(),
                  description: _descriptionController.text.trim(),
                );
        await provider.updateNote(updated);
      } else {
        await provider.createNote(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.lastActionMessage ??
                (_isEditing ? 'Note updated.' : 'Note created.'),
          ),
        ),
      );
      provider.clearLastActionMessage();
      navigator.pop();
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Could not save the note.'),
        ),
      );
      provider.clearError();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit note' : 'New note'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete note',
              icon: const Icon(Icons.delete_outline),
              onPressed: _isSaving ? null : () => _confirmDelete(context),
            ),
        ],
      ),
      body: _isHydrating
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    CenteredMaxWidth(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Update your note' : 'Start writing',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isEditing
                                ? 'Refine the title and details below.'
                                : 'Capture an idea before it slips away.',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CenteredMaxWidth(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: TextFormField(
                        controller: _titleController,
                        focusNode: _titleFocus,
                        maxLength: _titleMaxLength,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.sentences,
                        onFieldSubmitted: (_) =>
                            _descriptionFocus.requestFocus(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Give your note a title',
                          counterText: '',
                        ),
                        validator: _validateTitle,
                      ),
                    ),
                    CenteredMaxWidth(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: TextFormField(
                        controller: _descriptionController,
                        focusNode: _descriptionFocus,
                        maxLength: _descriptionMaxLength,
                        maxLines: 12,
                        minLines: 8,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                        style: theme.textTheme.bodyLarge,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Write your thoughts…',
                          alignLabelWithHint: true,
                        ),
                        validator: _validateDescription,
                      ),
                    ),
                    CenteredMaxWidth(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _onSave,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(_isEditing ? 'Update note' : 'Save note'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(64),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    CenteredMaxWidth(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: Text(
                        _isEditing
                            ? 'Changes are saved instantly to the cloud.'
                            : 'Your note will be saved instantly to the cloud.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final provider = context.read<NoteProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text(
          'This note will be removed from your collection. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(
                dialogContext,
              ).colorScheme.errorContainer,
              foregroundColor: Theme.of(
                dialogContext,
              ).colorScheme.onErrorContainer,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    try {
      await provider.deleteNote(widget.noteId!);
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Note deleted')));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Could not delete the note.'),
        ),
      );
      provider.clearError();
    }
  }
}
