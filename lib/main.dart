import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const NotesApp());

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notas',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const NotesScreen(),
    );
  }
}

class Note {
  String id;
  String title;
  String content;
  DateTime date;
  bool isPinned;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.isPinned = false,
  });
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> notes = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadExampleNotes();
  }

  void _loadExampleNotes() {
    notes = [
      Note(
        id: '1',
        title: 'Comprar la entrada...',
        content: 'Antes de comprar revisar precios\n23 de Abril',
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Note(
        id: '2',
        title: 'Tareas pendientes',
        content: '• Enviar mensajes\n• Comprar\n• Cancelar\n• Guardar cambios',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Note(
        id: '3',
        title: 'Ideas para la app',
        content: 'Agregar etiquetas\nSincronización en la nube\nModo oscuro',
        date: DateTime.now(),
      ),
    ];
  }

  void _addNote() {
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Nueva nota',
      content: '',
      date: DateTime.now(),
    );
    setState(() => notes.insert(0, newNote));
    _editNote(newNote);
  }

  void _editNote(Note note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditNoteScreen(note: note),
      ),
    );
    if (result != null && result is Note) {
      setState(() {
        final index = notes.indexWhere((n) => n.id == result.id);
        if (index != -1) notes[index] = result;
      });
    }
  }

  void _deleteNote(String id) {
    setState(() => notes.removeWhere((n) => n.id == id));
  }

  @override
  Widget build(BuildContext context) {
    final pinnedNotes = notes.where((n) => n.isPinned).toList();
    final unpinnedNotes = notes.where((n) => !n.isPinned).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header estilo Xiaomi Notes
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const AppBrandIcon(size: 42),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mis Notas',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${notes.length} notas',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.68),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.08),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.search, size: 20, color: Colors.blue.shade600),
                            const SizedBox(width: 10),
                            Icon(CupertinoIcons.ellipsis, size: 20, color: Colors.blue.shade600),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lista de notas
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (pinnedNotes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'FIJADAS',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...pinnedNotes.map((note) => _buildNoteCard(note)),
                  ],
                  if (unpinnedNotes.isNotEmpty) ...[
                    if (pinnedNotes.isNotEmpty) const SizedBox(height: 16),
                    Text(
                      'NOTAS',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...unpinnedNotes.map((note) => _buildNoteCard(note)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),

      // Botón flotante de añadir (estilo Xiaomi/iOS)
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton(
          onPressed: _addNote,
          backgroundColor: Colors.blue,
          elevation: 0,
          child: const Icon(CupertinoIcons.add, color: Colors.white, size: 28),
        ),
      ),

      bottomNavigationBar: LiquidGlassBottomNav(
        currentIndex: _currentIndex,
        onChanged: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    return GestureDetector(
      onTap: () => _editNote(note),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (note.isPinned)
                  Icon(Icons.push_pin, size: 16, color: Colors.amber[700]),
                PopupMenuButton(
                  icon: Icon(Icons.more_horiz, size: 20, color: Colors.grey[500]),
                  onSelected: (value) {
                    if (value == 'delete') _deleteNote(note.id);
                    if (value == 'pin') {
                      setState(() => note.isPinned = !note.isPinned);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'pin',
                      child: Text(note.isPinned ? 'Desfijar' : 'Fijar'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.content.isEmpty ? 'Sin contenido' : note.content,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text(
              DateFormat('dd MMM yyyy - HH:mm').format(note.date),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppBrandIcon extends StatelessWidget {
  const AppBrandIcon({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        color: Colors.blue.shade600,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SvgPicture.asset('assets/ic-notes.svg'),
    );
  }
}

class LiquidGlassBottomNav extends StatelessWidget {
  const LiquidGlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const _items = [
    CupertinoIcons.doc_text,
    CupertinoIcons.square_pencil,
    CupertinoIcons.search,
    CupertinoIcons.person_crop_circle,
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.54),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: Colors.white.withValues(alpha: 0.76), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_items.length, (index) {
                return Expanded(
                  child: _LiquidGlassNavItem(
                    icon: _items[index],
                    selected: currentIndex == index,
                    onTap: () => onChanged(index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiquidGlassNavItem extends StatelessWidget {
  const _LiquidGlassNavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        scale: selected ? 1.05 : 1,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: selected ? 58 : 46,
            height: 46,
            decoration: BoxDecoration(
              color: selected ? Colors.blue.withValues(alpha: 0.16) : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected ? Colors.white.withValues(alpha: 0.82) : Colors.transparent,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 9),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: selected ? 1 : 0,
                  child: Container(
                    width: 30,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                Icon(
                  icon,
                  color: selected ? Colors.blue.shade700 : Colors.blue.withValues(alpha: 0.56),
                  size: selected ? 25 : 23,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EditNoteScreen extends StatefulWidget {
  final Note note;

  const EditNoteScreen({super.key, required this.note});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note.title);
    contentController = TextEditingController(text: widget.note.content);
    selectedDate = widget.note.date;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Editar Nota',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              final updatedNote = Note(
                id: widget.note.id,
                title: titleController.text.isEmpty ? 'Sin título' : titleController.text,
                content: contentController.text,
                date: selectedDate ?? DateTime.now(),
                isPinned: widget.note.isPinned,
              );
              Navigator.pop(context, updatedNote);
            },
            child: Text(
              'Guardar',
              style: GoogleFonts.inter(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: 'Título',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: contentController,
                style: GoogleFonts.inter(fontSize: 16, height: 1.5),
                decoration: const InputDecoration(
                  hintText: 'Escribe tu nota...',
                  border: InputBorder.none,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.format_bold, color: Colors.grey[600]),
                  Icon(Icons.format_italic, color: Colors.grey[600]),
                  Icon(Icons.format_list_bulleted, color: Colors.grey[600]),
                  Icon(Icons.check_box_outlined, color: Colors.grey[600]),
                  Icon(Icons.image_outlined, color: Colors.grey[600]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
