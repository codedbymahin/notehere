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
  static const int _titleMaxLength = 80;
  static const int _descriptionMaxLength = 2000;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocus = FocusNode();

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
    super.dispose();
  }

  String? _validateTitle(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Please enter a title.';
    return null;
  }

  String? _validateDescription(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Description cannot be empty.';
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit note' : 'New note')),
      body: _isHydrating
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    TextFormField(
                      controller: _titleController,
                      focusNode: _titleFocus,
                      maxLength: _titleMaxLength,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      style: theme.textTheme.titleMedium,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        hintText: 'Give your note a title',
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: _validateTitle,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      maxLength: _descriptionMaxLength,
                      maxLines: 10,
                      minLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Write your thoughts…',
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: _validateDescription,
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _onSave,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isEditing ? 'Update note' : 'Save note'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        textStyle: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isEditing
                          ? 'Changes are saved instantly to the cloud.'
                          : 'Your note will be saved instantly to the cloud.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
