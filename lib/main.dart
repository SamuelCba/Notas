import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

const _notesBlue = Color(0xFF147EFB);
const _barHeight = 64.0;
const _barPaddingH = 20.0;
const _barPaddingV = 16.0;
const _barSpacing = 8.0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(const NotesApp()));
}

class NotesApp extends StatefulWidget {
  const NotesApp({super.key});

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notas',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: NotesScreen(
        isDarkMode: _themeMode == ThemeMode.dark,
        onThemeChanged: (isDark) {
          setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
        },
      ),
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
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const NotesScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  List<Note> notes = [];
  int _currentIndex = 0;
  bool _isMiniMode = false;
  bool _isSearching = false;
  String _searchQuery = '';
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _loadExampleNotes();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    final mini = offset > 50;
    if (mini == _isMiniMode && (offset - _scrollOffset).abs() < 2) return;
    setState(() {
      _scrollOffset = offset;
      _isMiniMode = mini;
    });
  }

  void _dismissMiniMode() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuart,
      );
    }
    setState(() {
      _isMiniMode = false;
      _isSearching = false;
    });
  }

  void _toggleSearch() {
    setState(() => _isSearching = !_isSearching);
    if (!_isSearching) {
      _searchController.clear();
      _searchQuery = '';
      _searchFocusNode.unfocus();
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  LiquidGlassSettings get _barGlassSettings => LiquidGlassSettings(
        glassColor: widget.isDarkMode ? const Color(0xCC11161E) : const Color(0x72FFFFFF),
        thickness: 34,
        blur: 4,
        chromaticAberration: .01,
        lightAngle: GlassDefaults.lightAngle,
        lightIntensity: widget.isDarkMode ? .22 : .72,
        ambientStrength: 0,
        refractiveIndex: 1.2,
        saturation: widget.isDarkMode ? 1.12 : 1.28,
        specularSharpness: GlassSpecularSharpness.medium,
      );

  List<GlassBottomBarTab> get _tabs => const [
        GlassBottomBarTab(
          label: 'Notas',
          icon: Icon(CupertinoIcons.doc_text),
          activeIcon: Icon(CupertinoIcons.doc_text),
        ),
        GlassBottomBarTab(
          label: 'Editar',
          icon: Icon(CupertinoIcons.square_pencil),
          activeIcon: Icon(CupertinoIcons.square_pencil),
        ),
        GlassBottomBarTab(
          label: 'Tareas',
          icon: Icon(CupertinoIcons.checkmark_circle),
          activeIcon: Icon(CupertinoIcons.checkmark_circle_fill),
        ),
        GlassBottomBarTab(
          label: 'Perfil',
          icon: Icon(CupertinoIcons.person_crop_circle),
          activeIcon: Icon(CupertinoIcons.person_crop_circle),
        ),
      ];

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

  void _addNote() async {
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Nueva nota',
      content: '',
      date: DateTime.now(),
    );
    final result = await Navigator.of(context).push(
      _createEditorRoute(newNote, fromPlusButton: true),
    );
    if (result != null) {
      setState(() => notes.insert(0, result));
    }
  }

  void _editNote(Note note) async {
    final result = await Navigator.of(context).push(
      _createEditorRoute(note),
    );
    if (result != null) {
      setState(() {
        final index = notes.indexWhere((n) => n.id == result.id);
        if (index != -1) notes[index] = result;
      });
    }
  }

  void _deleteNote(String id) {
    setState(() => notes.removeWhere((n) => n.id == id));
  }

  PageRouteBuilder<Note?> _createEditorRoute(
    Note note, {
    bool fromPlusButton = false,
  }) {
    return PageRouteBuilder<Note?>(
      transitionDuration: const Duration(milliseconds: 520),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      opaque: true,
      barrierColor: Colors.white,
      pageBuilder: (context, animation, secondaryAnimation) => EditNoteScreen(
        note: note,
        isDarkMode: widget.isDarkMode,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return ColoredBox(
          color: widget.isDarkMode ? const Color(0xFF0D1117) : Colors.grey.shade50,
          child: ScaleTransition(
            scale: curved.drive(Tween(begin: fromPlusButton ? 0.72 : 0.88, end: 1.0)),
            alignment: fromPlusButton ? Alignment.bottomRight : Alignment.center,
            child: child,
          ),
        );
      },
    );
  }

  List<Note> _visibleNotes() {
    Iterable<Note> source = notes;
    if (_currentIndex == 2) {
      source = source.where((note) {
        final text = '${note.title}\n${note.content}'.toLowerCase();
        return text.contains('•') ||
            text.contains('tarea') ||
            text.contains('pendiente') ||
            text.contains('comprar') ||
            text.contains('cancelar') ||
            text.contains('enviar');
      });
    }
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return source.toList();
    return source.where((note) {
      return note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query);
    }).toList();
  }

  String get _currentTitle {
    return switch (_currentIndex) {
      1 => 'Editar',
      2 => 'Tareas',
      3 => 'Perfil',
      _ => 'Notas',
    };
  }

  String get _currentSubtitle {
    if (_currentIndex == 3) return 'Ajustes de la app';
    return '${notes.length} notas';
  }

  IconData get _currentIcon {
    return switch (_currentIndex) {
      1 => CupertinoIcons.square_pencil,
      2 => CupertinoIcons.checkmark_circle_fill,
      3 => CupertinoIcons.person_crop_circle,
      _ => CupertinoIcons.doc_text,
    };
  }

  Color get _backgroundColor {
    return widget.isDarkMode ? const Color(0xFF0D1117) : Colors.grey.shade50;
  }

  Color get _cardColor {
    return widget.isDarkMode ? const Color(0xFF161B22) : Colors.white;
  }

  Color get _floatingPanelColor {
    return widget.isDarkMode ? const Color(0xFF171E27) : Colors.white;
  }

  Color get _primaryTextColor {
    return widget.isDarkMode ? const Color(0xFFF5F7FA) : Colors.black;
  }

  Color get _secondaryTextColor {
    return widget.isDarkMode ? const Color(0xFF9AA4B2) : Colors.grey.shade600;
  }

  Color get _mutedLabelColor {
    return widget.isDarkMode ? const Color(0xFF8693A6) : Colors.grey.shade500;
  }

  Color get _dateColor {
    return widget.isDarkMode ? const Color(0xFF7E8AA0) : Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final visibleNotes = _visibleNotes();
    final pinnedNotes = visibleNotes.where((n) => n.isPinned).toList();
    final unpinnedNotes = visibleNotes.where((n) => !n.isPinned).toList();
    final collapse = (_scrollOffset / 72).clamp(0.0, 1.0);
    final largeTitleOpacity = (1 - collapse).clamp(0.0, 1.0);
    final subtitleOpacity = (1 - collapse * 1.9).clamp(0.0, 1.0);
    final smallTitleOpacity = collapse.clamp(0.0, 1.0);
    final navProgress = Curves.easeOutCubic.transform(collapse);
    final fullBarOpacity = (1 - navProgress * 1.25).clamp(0.0, 1.0);
    final fullBarScale = 1 - navProgress * 0.16;
    final miniBarOpacity = (navProgress * 1.25).clamp(0.0, 1.0);
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: _backgroundColor,
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Opacity(
                      opacity: largeTitleOpacity,
                      child: Transform.translate(
                        offset: Offset(0, -12 * collapse),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentTitle,
                              style: GoogleFonts.inter(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: _primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 140),
                              opacity: subtitleOpacity,
                              child: Text(
                                _currentSubtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: _secondaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 150),
                    children: _currentIndex == 3
                        ? [_buildProfilePanel()]
                        : [
                            if (pinnedNotes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'FIJADAS',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _mutedLabelColor,
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
                                  color: _mutedLabelColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...unpinnedNotes.map((note) => _buildNoteCard(note)),
                            ],
                            if (visibleNotes.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 70),
                                child: Center(
                                  child: Text(
                                    _searchQuery.trim().isEmpty ? 'Sin tareas' : 'Sin resultados',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      color: _mutedLabelColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: topInset + 10,
            right: 16,
            child: IgnorePointer(
              ignoring: false,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: 1.0,
                child: GestureDetector(
                  onTap: _toggleSearch,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                          color: _floatingPanelColor.withValues(alpha: widget.isDarkMode ? 0.84 : 0.68),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: widget.isDarkMode
                                ? Colors.white.withValues(alpha: 0.10)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _notesBlue.withValues(alpha: widget.isDarkMode ? 0.14 : 0.08),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isSearching ? CupertinoIcons.xmark : CupertinoIcons.search,
                              size: 20,
                              color: _notesBlue,
                            ),
                            const SizedBox(width: 10),
                            const Icon(CupertinoIcons.ellipsis, size: 20, color: _notesBlue),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            left: 18,
            right: 18,
            top: _isSearching ? topInset + 58 : topInset - 90,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: _isSearching ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_isSearching,
                child: GlassSearchBar(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  placeholder: 'Buscar notas',
                  showsCancelButton: true,
                  useOwnLayer: true,
                  height: 50,
                  searchIconColor: _notesBlue,
                  clearIconColor: _notesBlue,
                  cancelButtonColor: _notesBlue,
                  settings: _barGlassSettings,
                  quality: GlassQuality.premium,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  onCancel: () {
                    setState(() {
                      _isSearching = false;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                    _searchFocusNode.unfocus();
                  },
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: smallTitleOpacity < 0.05,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 14 * smallTitleOpacity,
                    sigmaY: 14 * smallTitleOpacity,
                  ),
                  child: Container(
                    height: topInset + 54,
                    padding: EdgeInsets.only(top: topInset),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
	                          _backgroundColor.withValues(alpha: 0.78 * smallTitleOpacity),
	                          _backgroundColor.withValues(alpha: 0.36 * smallTitleOpacity),
	                          _backgroundColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 140),
                      opacity: smallTitleOpacity,
                      child: Text(
	                        _currentTitle,
	                        style: GoogleFonts.inter(
	                          fontSize: 17,
	                          fontWeight: FontWeight.w800,
	                          color: _primaryTextColor.withValues(alpha: 0.84),
	                        ),
	                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Stack(
              alignment: Alignment.center,
              children: [
                IgnorePointer(
                  ignoring: fullBarOpacity < 0.06,
                  child: Opacity(
                    opacity: fullBarOpacity,
                    child: Transform.scale(
                      scale: fullBarScale,
                      child: _buildFullBottomBar(),
                    ),
                  ),
                ),
                IgnorePointer(
                  ignoring: miniBarOpacity < 0.08,
                  child: Opacity(
                    opacity: miniBarOpacity,
                    child: Transform.scale(
                      scale: 0.84 + navProgress * 0.16,
                      child: _buildMiniBottomBar(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.22 : 0.03),
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
	                      color: _primaryTextColor,
	                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (note.isPinned)
                  Icon(Icons.push_pin, size: 16, color: Colors.amber[700]),
                PopupMenuButton(
                  icon: Icon(Icons.more_horiz, size: 20, color: _mutedLabelColor),
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
	                color: _secondaryTextColor,
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
                color: _dateColor,
              ),
            ),
          ],
        ),
      ),
    );
	  }

  Widget _buildProfilePanel() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.20 : 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _notesBlue.withValues(alpha: widget.isDarkMode ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                widget.isDarkMode ? CupertinoIcons.moon_stars_fill : CupertinoIcons.sun_max_fill,
                color: _notesBlue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modo oscuro',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isDarkMode ? 'Tema oscuro activado' : 'Tema claro activado',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoSwitch(
              value: widget.isDarkMode,
              activeTrackColor: _notesBlue,
              onChanged: widget.onThemeChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullBottomBar() {
    return GlassBottomBar(
      key: const ValueKey('full-bottom-bar'),
      tabs: _tabs,
      selectedIndex: _currentIndex,
      onTabSelected: (index) {
        if (index == _currentIndex && _isMiniMode) {
          _dismissMiniMode();
          return;
        }
        setState(() {
          _currentIndex = index;
          _isSearching = false;
        });
      },
      extraButton: GlassBottomBarExtraButton(
        icon: const Icon(CupertinoIcons.add_circled_solid),
        onTap: _addNote,
        label: 'Nueva nota',
        iconColor: _notesBlue,
        size: 58,
      ),
      barHeight: _barHeight,
      horizontalPadding: _barPaddingH,
      verticalPadding: _barPaddingV,
      spacing: _barSpacing,
      selectedIconColor: _notesBlue,
      unselectedIconColor: _notesBlue.withValues(alpha: 0.72),
      indicatorColor: _notesBlue.withValues(alpha: 0.18),
      labelFontSize: 10,
      iconSize: 27,
      iconLabelSpacing: 0,
      quality: GlassQuality.premium,
      interactionBehavior: GlassInteractionBehavior.full,
      glassSettings: _barGlassSettings,
      interactionGlowColor: _notesBlue,
    );
  }

  Widget _buildMiniBottomBar() {
    return Center(
      key: const ValueKey('mini-bottom-bar'),
      child: GestureDetector(
        onTap: _dismissMiniMode,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _floatingPanelColor.withValues(alpha: widget.isDarkMode ? 0.84 : 0.68),
                border: Border.all(
                  color: widget.isDarkMode
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _notesBlue.withValues(alpha: widget.isDarkMode ? 0.16 : 0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _currentIcon,
                  color: _notesBlue,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EditNoteScreen extends StatefulWidget {
  final Note note;
  final bool isDarkMode;

  const EditNoteScreen({
    super.key,
    required this.note,
    required this.isDarkMode,
  });

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

  void _insertAtCursor(String value) {
    final selection = contentController.selection;
    final text = contentController.text;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final next = text.replaceRange(start, end, value);
    contentController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + value.length),
    );
  }

  void _wrapSelection(String before, String after) {
    final selection = contentController.selection;
    final text = contentController.text;
    if (!selection.isValid || selection.isCollapsed) {
      _insertAtCursor('$before$after');
      contentController.selection = TextSelection.collapsed(
        offset: contentController.selection.baseOffset - after.length,
      );
      return;
    }
    final selected = text.substring(selection.start, selection.end);
    final next = text.replaceRange(selection.start, selection.end, '$before$selected$after');
    contentController.value = TextEditingValue(
      text: next,
      selection: TextSelection(
        baseOffset: selection.start + before.length,
        extentOffset: selection.end + before.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isDarkMode ? const Color(0xFF0D1117) : Colors.grey.shade50;
    final cardColor = widget.isDarkMode ? const Color(0xFF161B22) : Colors.white;
    final primaryTextColor = widget.isDarkMode ? const Color(0xFFF5F7FA) : Colors.black;
    final secondaryTextColor = widget.isDarkMode ? const Color(0xFF9AA4B2) : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Editar Nota',
          style: GoogleFonts.inter(
            color: primaryTextColor,
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
	                color: primaryTextColor,
	              ),
	              decoration: InputDecoration(
	                hintText: 'Título',
	                hintStyle: TextStyle(color: secondaryTextColor),
	                border: InputBorder.none,
	              ),
	            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: contentController,
	                style: GoogleFonts.inter(
	                  fontSize: 16,
	                  height: 1.5,
	                  color: primaryTextColor,
	                ),
	                decoration: InputDecoration(
	                  hintText: 'Escribe tu nota...',
	                  hintStyle: TextStyle(color: secondaryTextColor),
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
	                color: cardColor,
	                borderRadius: BorderRadius.circular(15),
	              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    tooltip: 'Negrita',
                    onPressed: () => _wrapSelection('**', '**'),
	                    icon: Icon(Icons.format_bold, color: secondaryTextColor),
                  ),
                  IconButton(
                    tooltip: 'Cursiva',
                    onPressed: () => _wrapSelection('_', '_'),
	                    icon: Icon(Icons.format_italic, color: secondaryTextColor),
                  ),
                  IconButton(
                    tooltip: 'Lista',
                    onPressed: () => _insertAtCursor('\n• '),
	                    icon: Icon(Icons.format_list_bulleted, color: secondaryTextColor),
                  ),
                  IconButton(
                    tooltip: 'Tarea',
                    onPressed: () => _insertAtCursor('\n☐ '),
	                    icon: Icon(Icons.check_box_outlined, color: secondaryTextColor),
                  ),
                  IconButton(
                    tooltip: 'Imagen',
                    onPressed: () => _insertAtCursor('\n[imagen] '),
	                    icon: Icon(Icons.image_outlined, color: secondaryTextColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
