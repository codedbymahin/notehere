import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../providers/note_provider.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  Note? _initialNote;
  bool _isHydrating = false;

  @override
  void initState() {
    super.initState();
    if (widget.noteId != null && widget.noteId!.isNotEmpty) {
      _hydrateFromProvider();
    }
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
      if (mounted) setState(() => _isHydrating = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.noteId != null && widget.noteId!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit note' : 'New note')),
      body: _isHydrating
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Give your note a title',
              ),
              textInputAction: TextInputAction.next,
              validator: _validateRequired,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Write your thoughts…',
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              minLines: 4,
              validator: _validateRequired,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _onSave,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isEditing ? 'Update note' : 'Save note'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                textStyle: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSaving = false;

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

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
          content: Text(provider.errorMessage ?? 'Could not save note.'),
        ),
      );
      provider.clearError();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
