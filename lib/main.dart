import 'package:flutter/material.dart';
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
                  // Botón de búsqueda estilo Xiaomi
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 20, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Icon(Icons.more_vert, size: 20, color: Colors.grey[600]),
                      ],
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
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),

      // Navbar flotante estilo iOS (como en la segunda foto)
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.note_alt_outlined, 0),
            _buildNavItem(Icons.edit_note_outlined, 1),
            _buildNavItem(Icons.search_outlined, 2),
            _buildNavItem(Icons.person_outline, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.blue : Colors.grey[500],
          size: 24,
        ),
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
              color: Colors.black.withOpacity(0.03),
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
