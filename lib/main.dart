import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
    statusBarColor: Colors.transparent,
  ));

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
  bool _isSearchExpanded = false;
  bool _manualExpand = false;
  double _manualExpandOffset = 0;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _loadExampleNotes();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    
    // Si el usuario expandió manualmente, evitamos que vuelva a mini 
    // hasta que haga un scroll significativo desde ese punto
    if (_manualExpand) {
      if ((offset - _manualExpandOffset).abs() > 60) {
        setState(() => _manualExpand = false);
      } else {
        _scrollOffset = offset;
        return;
      }
    }

    final mini = !_isSearchExpanded && offset > 50;
    if (mini == _isMiniMode && (offset - _scrollOffset).abs() < 2) return;
    setState(() {
      _scrollOffset = offset;
      _isMiniMode = mini;
    });
  }

  void _dismissMiniMode() {
    setState(() {
      _isMiniMode = false;
      _isSearchExpanded = false;
      _manualExpand = true;
      _manualExpandOffset = _scrollController.hasClients ? _scrollController.offset : 0;
    });
    _searchFocusNode.unfocus();
    _searchController.clear();
  }

  LiquidGlassSettings get _barGlassSettings => LiquidGlassSettings(
        glassColor: widget.isDarkMode ? const Color(0xCC11161E) : const Color(0x8AFFFFFF),
        thickness: 34,
        blur: 12,
        chromaticAberration: .01,
        lightAngle: GlassDefaults.lightAngle,
        lightIntensity: widget.isDarkMode ? .22 : .82,
        ambientStrength: 0,
        refractiveIndex: 1.25,
        saturation: widget.isDarkMode ? 1.12 : 1.4,
        specularSharpness: GlassSpecularSharpness.medium,
      );

  List<GlassBottomBarTab> get _tabs => const [
        GlassBottomBarTab(
          label: 'Notas',
          icon: Icon(CupertinoIcons.doc_text),
          activeIcon: Icon(CupertinoIcons.doc_text),
        ),
        GlassBottomBarTab(
          label: 'Ai',
          icon: Icon(CupertinoIcons.sparkles),
          activeIcon: Icon(CupertinoIcons.sparkles),
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
      Note(
        id: '4',
        title: 'Recordatorio de llamadas',
        content: 'Llamar al proveedor y confirmar horario.',
        date: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      Note(
        id: '5',
        title: 'Lista de compras',
        content: 'Pan\nLeche\nCafé\nFruta\nAgua',
        date: DateTime.now().subtract(const Duration(hours: 9)),
      ),
      Note(
        id: '6',
        title: 'Resumen de reunión',
        content: 'Revisar entrega\nAjustar tiempos\nEnviar actualización',
        date: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Note(
        id: '7',
        title: 'Ideas para la IA',
        content: 'Responder rápido\nSugerir acciones\nResumir notas largas',
        date: DateTime.now().subtract(const Duration(days: 4)),
      ),
      Note(
        id: '8',
        title: 'Pendiente del proyecto',
        content: 'Subir cambios al repo\nVerificar build\nDescargar APK',
        date: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Note(
        id: '9',
        title: 'Música para estudiar',
        content: 'Lofi suave\nVolumen bajo\nSin letra',
        date: DateTime.now().subtract(const Duration(days: 6)),
      ),
      Note(
        id: '10',
        title: 'Notas de prueba',
        content: 'Scroll largo para ver la animación del navbar.',
        date: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }

  void _addNote() async {
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '',
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
    
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      source = source.where((note) {
        return note.title.toLowerCase().contains(query) ||
               note.content.toLowerCase().contains(query);
      });
    }

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
    return source.toList();
  }

  Color get _backgroundColor {
    return widget.isDarkMode ? const Color(0xFF0D1117) : const Color(0xFFF0F2F5);
  }

  Color get _cardColor {
    return widget.isDarkMode ? const Color(0xFF161B22) : Colors.white;
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

  LiquidGlassSettings get _triggerGlassSettings => LiquidGlassSettings(
        glassColor: widget.isDarkMode ? const Color(0xAA1C1C1E) : const Color(0x78FFFFFF),
        thickness: 18,
        blur: 3,
        lightIntensity: 0.4,
        ambientStrength: 0.08,
        chromaticAberration: 0.01,
        refractiveIndex: 1.2,
        saturation: 1.15,
        specularSharpness: GlassSpecularSharpness.medium,
      );

  @override
  Widget build(BuildContext context) {
    final visibleNotes = _visibleNotes();
    final pinnedNotes = visibleNotes.where((n) => n.isPinned).toList();
    final unpinnedNotes = visibleNotes.where((n) => !n.isPinned).toList();
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: _backgroundColor,
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 80, 16, 150),
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
                              'Sin notas',
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
          // Top Gradient Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topInset + 100,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _backgroundColor,
                      _backgroundColor,
                      _backgroundColor.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Bottom Gradient Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 120,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      _backgroundColor,
                      _backgroundColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: topInset + 10,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 56,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.2 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'Notas',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _primaryTextColor,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildTopMoreMenuButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 10 + _barHeight + 18,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              scale: 1 - (_scrollOffset / 220).clamp(0.0, 0.16),
              child: _buildFloatingComposeButton(),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: GlassSearchableBottomBar(
              isSearchActive: _isMiniMode || _isSearchExpanded,
              selectedIndex: _currentIndex,
              onTabSelected: (index) {
                if (_isMiniMode) {
                  _dismissMiniMode();
                  return;
                }
                if (index == _currentIndex && _isSearchExpanded) {
                  setState(() => _isSearchExpanded = false);
                  return;
                }
                setState(() => _currentIndex = index);
              },
              barHeight: _barHeight,
              searchBarHeight: 50.0,
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
              searchConfig: GlassSearchBarConfig(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autoFocusOnExpand: false,
                showsCancelButton: true,
                expandWhenActive: true,
                hintText: 'Buscar notas',
                onSearchToggle: (active) {
                  if (active) {
                    if (_isMiniMode) {
                      _dismissMiniMode();
                    } else {
                      setState(() {
                        _isSearchExpanded = true;
                      });
                    }
                  } else {
                    setState(() {
                      _isSearchExpanded = false;
                      _isMiniMode = false;
                    });
                    _searchFocusNode.unfocus();
                  }
                },
                searchIconColor: _notesBlue,
                textInputAction: TextInputAction.search,
                collapsedLogoBuilder: (context) {
                  final tab = _tabs[_currentIndex];
                  return GestureDetector(
                    onTap: _dismissMiniMode,
                    child: Center(
                      child: IconTheme(
                        data: const IconThemeData(color: _notesBlue, size: 30),
                        child: tab.activeIcon ?? tab.icon,
                      ),
                    ),
                  );
                },
              ),
              tabs: _tabs,
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
                      child: Text(
                        note.isPinned ? 'Desfijar' : 'Fijar',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _primaryTextColor),
                      ),
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
            RichText(
              text: NoteFormatter.buildTextSpan(
                text: note.content.isEmpty ? 'Sin contenido' : note.content,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _secondaryTextColor,
                  height: 1.4,
                ),
                isDarkMode: widget.isDarkMode,
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

  Widget _buildFloatingComposeButton() {
    return GlassButton(
      onTap: _addNote,
      width: 60,
      height: 60,
      shape: const LiquidOval(),
      settings: _triggerGlassSettings,
      quality: GlassQuality.premium,
      useOwnLayer: true,
      stretch: 0.24,
      icon: Icon(
        CupertinoIcons.square_pencil,
        color: widget.isDarkMode ? Colors.white : Colors.black87,
        size: 28,
      ),
    );
  }

  Widget _buildTopMoreMenuButton() {
    final menuColor = widget.isDarkMode
        ? const Color(0xFF1C1C1E)
        : const Color(0xFFF2F2F7);
    final menuBorder = widget.isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: menuColor,
          elevation: 18,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: menuBorder),
          ),
        ),
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        offset: const Offset(0, 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: menuBorder),
        ),
        color: menuColor,
        onSelected: (value) {
          switch (value) {
            case 'new':
              _addNote();
              break;
            case 'theme':
              widget.onThemeChanged(!widget.isDarkMode);
              break;
            case 'profile':
              setState(() => _currentIndex = 3);
              break;
          }
        },
        itemBuilder: (context) => [
          _menuPopupItem(
            value: 'new',
            icon: CupertinoIcons.square_pencil,
            label: 'Nueva nota',
          ),
          _menuPopupItem(
            value: 'theme',
            icon: widget.isDarkMode
                ? CupertinoIcons.sun_max_fill
                : CupertinoIcons.moon_stars_fill,
            label: widget.isDarkMode ? 'Modo claro' : 'Modo oscuro',
          ),
          _menuPopupItem(
            value: 'profile',
            icon: CupertinoIcons.person_crop_circle,
            label: 'Perfil',
          ),
        ],
        child: Container(
          width: 52,
          height: 42,
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            CupertinoIcons.line_horizontal_3_decrease,
            color: widget.isDarkMode ? Colors.white : Colors.black87,
            size: 24,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuPopupItem({
    required String value,
    required IconData icon,
    required String label,
  }) {
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final iconColor = widget.isDarkMode ? Colors.white70 : Colors.black54;
    return PopupMenuItem<String>(
      value: value,
      height: 46,
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

}

class NoteFormatter {
  static final RegExp _headingPrefix = RegExp(r'^(#{1,3})\s+');
  static final RegExp _listPrefix = RegExp(r'^(?:[•☐☑]\s+|\d+\.\s+)');
  static final RegExp _inlineToken = RegExp(
    r'(\*\*[^*\n]+?\*\*)|(_[^_\n]+?_)|(<u>.+?</u>)|(<highlight>.+?</highlight>)|(~~[^~\n]+?~~)',
  );

  static String cleanText(String raw) {
    final cleanLines = normalizeLegacySyntax(raw).split('\n').map((line) {
      return line
          .replaceFirst(_headingPrefix, '')
          .replaceFirst(_listPrefix, '');
    }).join('\n');

    return cleanLines
        .replaceAllMapped(RegExp(r'\*\*([^*\n]+?)\*\*'), (match) => match.group(1)!)
        .replaceAllMapped(RegExp(r'_([^_\n]+?)_'), (match) => match.group(1)!)
        .replaceAllMapped(RegExp(r'<u>(.*?)</u>'), (match) => match.group(1)!)
        .replaceAllMapped(RegExp(r'<highlight>(.*?)</highlight>'), (match) => match.group(1)!)
        .replaceAllMapped(RegExp(r'~~([^~\n]+?)~~'), (match) => match.group(1)!);
  }

  static TextSpan buildTextSpan({
    required String text,
    TextStyle? style,
    required bool isDarkMode,
    bool hideSyntax = false,
  }) {
    final children = <TextSpan>[];
    final lines = normalizeLegacySyntax(text).split('\n');
    const hiddenStyle = TextStyle(
      color: Colors.transparent,
      fontSize: 0.01,
      height: 0.01,
      decoration: TextDecoration.none,
    );

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final heading = _headingPrefix.firstMatch(line);
      final prefix = heading?.group(0) ?? '';
      final body = heading == null ? line : line.substring(prefix.length);
      final lineStyle = _styleForHeading(heading?.group(1)?.length, style);

      if (hideSyntax && prefix.isNotEmpty) {
        children.add(TextSpan(text: prefix, style: hiddenStyle));
      }
      children.addAll(_buildInlineSpans(
        body,
        lineStyle,
        hiddenStyle,
        isDarkMode,
        hideSyntax,
      ));
      if (i < lines.length - 1) {
        children.add(TextSpan(text: '\n', style: style));
      }
    }

    return TextSpan(style: style, children: children);
  }

  static String normalizeLegacySyntax(String raw) {
    return raw.replaceAllMapped(
      RegExp(r'<h([123])>(.*?)</h\1>', dotAll: true),
      (match) => '${List.filled(int.parse(match.group(1)!), '#').join()} ${match.group(2)!}',
    );
  }

  static TextStyle? _styleForHeading(int? level, TextStyle? baseStyle) {
    if (level == null) return baseStyle;
    final headingStyle = switch (level) {
      1 => const TextStyle(fontSize: 28, height: 1.2, fontWeight: FontWeight.w800),
      2 => const TextStyle(fontSize: 23, height: 1.25, fontWeight: FontWeight.w800),
      _ => const TextStyle(fontSize: 19, height: 1.35, fontWeight: FontWeight.w700),
    };
    return baseStyle?.merge(headingStyle) ?? headingStyle;
  }

  static List<TextSpan> _buildInlineSpans(
    String line,
    TextStyle? baseStyle,
    TextStyle hiddenStyle,
    bool isDarkMode,
    bool hideSyntax,
  ) {
    final spans = <TextSpan>[];
    var lastEnd = 0;

    for (final match in _inlineToken.allMatches(line)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: line.substring(lastEnd, match.start), style: baseStyle));
      }

      final token = match.group(0)!;
      late final String open;
      late final String close;
      late final TextStyle tokenStyle;

      if (token.startsWith('**')) {
        open = '**';
        close = '**';
        tokenStyle = const TextStyle(fontWeight: FontWeight.w800);
      } else if (token.startsWith('_')) {
        open = '_';
        close = '_';
        tokenStyle = const TextStyle(fontStyle: FontStyle.italic);
      } else if (token.startsWith('<u>')) {
        open = '<u>';
        close = '</u>';
        tokenStyle = const TextStyle(decoration: TextDecoration.underline);
      } else if (token.startsWith('<highlight>')) {
        open = '<highlight>';
        close = '</highlight>';
        tokenStyle = TextStyle(
          backgroundColor: const Color(0xFFEBB119).withValues(alpha: isDarkMode ? 0.34 : 0.28),
        );
      } else {
        open = '~~';
        close = '~~';
        tokenStyle = const TextStyle(decoration: TextDecoration.lineThrough);
      }

      final inner = token.substring(open.length, token.length - close.length);
      if (hideSyntax) spans.add(TextSpan(text: open, style: hiddenStyle));
      spans.add(TextSpan(text: inner, style: baseStyle?.merge(tokenStyle) ?? tokenStyle));
      if (hideSyntax) spans.add(TextSpan(text: close, style: hiddenStyle));
      lastEnd = match.end;
    }

    if (lastEnd < line.length) {
      spans.add(TextSpan(text: line.substring(lastEnd), style: baseStyle));
    }

    return spans;
  }
}

class RichTextController extends TextEditingController {
  final bool isDarkMode;
  RichTextController({super.text, required this.isDarkMode});

  String get visibleText => NoteFormatter.cleanText(text);

  // Verifica si el cursor está dentro de un tipo de etiqueta
  bool isStyleActive(String pattern) {
    if (!selection.isValid) return false;
    final String currentText = text;
    final int cursor = selection.baseOffset;
    
    // Búsqueda simple: ¿hay una etiqueta de apertura antes y una de cierre después?
    // Esto es una simplificación, pero sirve para feedback visual
    int openIdx = currentText.lastIndexOf(pattern.split('|')[0], cursor);
    int closeIdx = currentText.indexOf(pattern.split('|')[1], cursor);
    
    return openIdx != -1 && closeIdx != -1 && openIdx < closeIdx;
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    return NoteFormatter.buildTextSpan(
      text: text,
      style: style,
      isDarkMode: isDarkMode,
      hideSyntax: true,
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

class _EditNoteScreenState extends State<EditNoteScreen> with SingleTickerProviderStateMixin {
  late TextEditingController titleController;
  late RichTextController contentController;
  late bool isPinned;
  bool _isFormatBarExpanded = false;
  bool _isApplyingAutoFormat = false;
  String _lastEditedText = '';
  DateTime? selectedDate;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note.title);
    contentController = RichTextController(text: widget.note.content, isDarkMode: widget.isDarkMode);
    _lastEditedText = widget.note.content;
    _charCount = contentController.visibleText.length;
    selectedDate = widget.note.date;
    isPinned = widget.note.isPinned;
    
    contentController.addListener(() {
      setState(() {
        _charCount = contentController.visibleText.length;
      });
    });
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
    _lastEditedText = next;
  }

  void _wrapSelection(String before, String after) {
    final selection = contentController.selection;
    final text = contentController.text;
    if (!selection.isValid || selection.isCollapsed) {
      _insertAtCursor('$before$after');
      contentController.selection = TextSelection.collapsed(
        offset: contentController.selection.baseOffset - after.length,
      );
      _lastEditedText = contentController.text;
      return;
    }

    final selected = text.substring(selection.start, selection.end);
    if (selected.startsWith(before) && selected.endsWith(after)) {
      final inner = selected.substring(before.length, selected.length - after.length);
      final next = text.replaceRange(selection.start, selection.end, inner);
      contentController.value = TextEditingValue(
        text: next,
        selection: TextSelection(
          baseOffset: selection.start,
          extentOffset: selection.start + inner.length,
        ),
      );
      _lastEditedText = next;
      return;
    }

    final next = text.replaceRange(selection.start, selection.end, '$before$selected$after');
    contentController.value = TextEditingValue(
      text: next,
      selection: TextSelection(
        baseOffset: selection.start + before.length,
        extentOffset: selection.end + before.length,
      ),
    );
    _lastEditedText = next;
  }

  ({int start, int end}) _selectedLineRange() {
    final text = contentController.text;
    final selection = contentController.selection;
    final rawStart = selection.isValid ? selection.start : text.length;
    final rawEnd = selection.isValid ? selection.end : text.length;
    final start = rawStart.clamp(0, text.length).toInt();
    final end = rawEnd.clamp(0, text.length).toInt();
    final lineStart = text.lastIndexOf('\n', start == 0 ? 0 : start - 1) + 1;
    var lineEnd = text.indexOf('\n', end);
    if (lineEnd == -1) lineEnd = text.length;
    return (start: lineStart, end: lineEnd);
  }

  void _replaceSelectedLines(String Function(List<String> lines) transform) {
    final text = contentController.text;
    final range = _selectedLineRange();
    final block = text.substring(range.start, range.end);
    final nextBlock = transform(block.split('\n'));
    final next = text.replaceRange(range.start, range.end, nextBlock);

    contentController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: range.start + nextBlock.length),
    );
    _lastEditedText = next;
  }

  void _applyParagraphStyle(int level) {
    final marker = '${List.filled(level, '#').join()} ';
    _replaceSelectedLines((lines) {
      final activeLines = lines.where((line) => line.trim().isNotEmpty);
      final allActive = activeLines.isNotEmpty &&
          activeLines.every((line) => line.startsWith(marker));

      return lines.map((line) {
        final body = line.replaceFirst(RegExp(r'^#{1,3}\s+'), '');
        if (allActive) return body;
        return '$marker$body';
      }).join('\n');
    });
  }

  void _toggleLinePrefix(String prefix) {
    _replaceSelectedLines((lines) {
      final activeLines = lines.where((line) => line.trim().isNotEmpty);
      final allActive = activeLines.isNotEmpty &&
          activeLines.every((line) => line.startsWith(prefix));

      return lines.map((line) {
        final body = line
            .replaceFirst(RegExp(r'^#{1,3}\s+'), '')
            .replaceFirst(RegExp(r'^(?:[•☐☑]\s+|\d+\.\s+)'), '');
        if (allActive) return body;
        return '$prefix$body';
      }).join('\n');
    });
  }

  void _toggleNumberedList() {
    _replaceSelectedLines((lines) {
      final activeLines = lines.where((line) => line.trim().isNotEmpty);
      final allActive = activeLines.isNotEmpty &&
          activeLines.every((line) => RegExp(r'^\d+\.\s+').hasMatch(line));
      var index = 1;

      return lines.map((line) {
        final body = line
            .replaceFirst(RegExp(r'^#{1,3}\s+'), '')
            .replaceFirst(RegExp(r'^(?:[•☐☑]\s+|\d+\.\s+)'), '');
        if (allActive) return body;
        return '${index++}. $body';
      }).join('\n');
    });
  }

  bool _isParagraphStyleActive(int level) {
    final text = contentController.text;
    final selection = contentController.selection;
    if (!selection.isValid) return false;
    final cursor = selection.baseOffset.clamp(0, text.length).toInt();
    final lineStart = text.lastIndexOf('\n', cursor == 0 ? 0 : cursor - 1) + 1;
    return text.substring(lineStart).startsWith('${List.filled(level, '#').join()} ');
  }

  bool _isLinePrefixActive(Pattern prefix) {
    final text = contentController.text;
    final selection = contentController.selection;
    if (!selection.isValid) return false;
    final cursor = selection.baseOffset.clamp(0, text.length).toInt();
    final lineStart = text.lastIndexOf('\n', cursor == 0 ? 0 : cursor - 1) + 1;
    final line = text.substring(lineStart);
    if (prefix is RegExp) return prefix.hasMatch(line);
    return line.startsWith(prefix.toString());
  }

  void _handleBodyChanged(String value) {
    if (_isApplyingAutoFormat) {
      _lastEditedText = value;
      return;
    }

    final selection = contentController.selection;
    final cursor = selection.isValid ? selection.baseOffset : -1;
    final insertedReturn = value.length == _lastEditedText.length + 1 &&
        cursor > 0 &&
        value[cursor - 1] == '\n';

    if (!insertedReturn) {
      _lastEditedText = value;
      return;
    }

    final previousLineEnd = cursor - 1;
    final previousLineStart = previousLineEnd <= 0
        ? 0
        : value.lastIndexOf('\n', previousLineEnd - 1) + 1;
    final previousLine = value.substring(previousLineStart, previousLineEnd);
    final marker = _continuationMarker(previousLine);
    if (marker == null) {
      _lastEditedText = value;
      return;
    }

    final body = previousLine.substring(marker.length);
    _isApplyingAutoFormat = true;
    if (body.trim().isEmpty) {
      final next = value.replaceRange(previousLineStart, previousLineEnd, '');
      contentController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: previousLineStart),
      );
      _lastEditedText = next;
    } else {
      final nextMarker = _nextContinuationMarker(marker);
      final next = value.replaceRange(cursor, cursor, nextMarker);
      contentController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: cursor + nextMarker.length),
      );
      _lastEditedText = next;
    }
    _isApplyingAutoFormat = false;
  }

  String? _continuationMarker(String line) {
    final match = RegExp(r'^(?:• |☐ |\d+\. )').firstMatch(line);
    return match?.group(0);
  }

  String _nextContinuationMarker(String marker) {
    final numbered = RegExp(r'^(\d+)\. $').firstMatch(marker);
    if (numbered == null) return marker;
    final next = int.parse(numbered.group(1)!) + 1;
    return '$next. ';
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isDarkMode ? const Color(0xFF000000) : const Color(0xFFF0F2F5);
    final cardColor = widget.isDarkMode ? const Color(0xFF121212) : Colors.white;
    final primaryTextColor = widget.isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = widget.isDarkMode ? const Color(0xFF757575) : Colors.grey.shade600;
    const accentColor = Color(0xFFEBB119);

    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: accentColor,
          selectionColor: accentColor.withValues(alpha: 0.3),
          selectionHandleColor: accentColor,
        ),
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.chevron_back, color: _notesBlue, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        isPinned ? CupertinoIcons.pin_fill : CupertinoIcons.pin,
                        color: isPinned ? Colors.amber[700] : secondaryTextColor,
                        size: 22,
                      ),
                      onPressed: () => setState(() => isPinned = !isPinned),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final updatedNote = Note(
                          id: widget.note.id,
                          title: titleController.text.isEmpty ? 'Sin título' : titleController.text,
                          content: contentController.text,
                          date: selectedDate ?? DateTime.now(),
                          isPinned: isPinned,
                        );
                        Navigator.pop(context, updatedNote);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _notesBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Listo',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Título',
                      hintStyle: TextStyle(color: secondaryTextColor),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        DateFormat('d MMMM yyyy, HH:mm').format(selectedDate ?? DateTime.now()),
                        style: GoogleFonts.inter(fontSize: 12, color: secondaryTextColor),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('|', style: TextStyle(color: secondaryTextColor)),
                      ),
                      Text(
                        '$_charCount caracteres',
                        style: GoogleFonts.inter(fontSize: 12, color: secondaryTextColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      TextField(
                        controller: contentController,
                        onChanged: _handleBodyChanged,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          height: 1.6,
                          color: primaryTextColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Empiece a escribir',
                          hintStyle: TextStyle(color: secondaryTextColor.withValues(alpha: 0.5)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        maxLines: null,
                        scrollPhysics: const NeverScrollableScrollPhysics(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            _buildDynamicBottomToolbar(cardColor, secondaryTextColor, primaryTextColor, accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicBottomToolbar(Color cardColor, Color secondaryColor, Color primaryColor, Color accentColor) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 8, MediaQuery.paddingOf(context).bottom + 8),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _isFormatBarExpanded 
                ? _buildTextFormatMode(secondaryColor, primaryColor, accentColor)
                : _buildInitialMode(secondaryColor),
            ),
          ),
          _buildToggleButton(primaryColor),
        ],
      ),
    );
  }

  Widget _buildToggleButton(Color color) {
    return AnimatedRotation(
      duration: const Duration(milliseconds: 350),
      turns: _isFormatBarExpanded ? 0.25 : 0.0,
      curve: Curves.easeInOutBack,
      child: IconButton(
        icon: _isFormatBarExpanded 
          ? Icon(CupertinoIcons.xmark, color: color)
          : Text(
              'T',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
        onPressed: () => setState(() => _isFormatBarExpanded = !_isFormatBarExpanded),
      ),
    );
  }

  Widget _buildInitialMode(Color color) {
    return Row(
      key: const ValueKey('initial'),
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _toolbarIconButton(CupertinoIcons.sparkles, () {}, color, isAi: true),
        _toolbarIconButton(CupertinoIcons.mic, () {}, color),
        _toolbarIconButton(CupertinoIcons.photo, () {}, color),
        _toolbarIconButton(CupertinoIcons.scribble, () {}, color),
        _toolbarIconButton(CupertinoIcons.checkmark_square, () => _toggleLinePrefix('☐ '), color),
      ],
    );
  }

  Widget _buildTextFormatMode(Color secondaryColor, Color primaryColor, Color accentColor) {
    return SizedBox(
      key: const ValueKey('format'),
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _toolbarIconButton(CupertinoIcons.pencil_outline, () => _wrapSelection('<highlight>', '</highlight>'), secondaryColor, isActive: contentController.isStyleActive('<highlight>|</highlight>')),
          _textFormatButton('H₁', () => _applyParagraphStyle(1), 20, primaryColor, isActive: _isParagraphStyleActive(1)),
          _textFormatButton('H₂', () => _applyParagraphStyle(2), 18, primaryColor, isActive: _isParagraphStyleActive(2)),
          _textFormatButton('H₃', () => _applyParagraphStyle(3), 16, primaryColor, isActive: _isParagraphStyleActive(3)),
          _toolbarIconButton(CupertinoIcons.bold, () => _wrapSelection('**', '**'), primaryColor, isActive: contentController.isStyleActive('**|**')),
          _toolbarIconButton(CupertinoIcons.italic, () => _wrapSelection('_', '_'), primaryColor, isActive: contentController.isStyleActive('_|_')),
          _toolbarIconButton(CupertinoIcons.underline, () => _wrapSelection('<u>', '</u>'), primaryColor, isActive: contentController.isStyleActive('<u>|</u>')),
          _toolbarIconButton(CupertinoIcons.strikethrough, () => _wrapSelection('~~', '~~'), primaryColor, isActive: contentController.isStyleActive('~~|~~')),
          _toolbarIconButton(CupertinoIcons.list_bullet, () => _toggleLinePrefix('• '), primaryColor, isActive: _isLinePrefixActive('• ')),
          _toolbarIconButton(CupertinoIcons.list_number, _toggleNumberedList, primaryColor, isActive: _isLinePrefixActive(RegExp(r'^\d+\.\s+'))),
          _toolbarIconButton(CupertinoIcons.quote_bubble, () => _wrapSelection('\n> ', '\n'), primaryColor),
          _toolbarIconButton(CupertinoIcons.text_alignleft, () {}, primaryColor),
          _toolbarIconButton(CupertinoIcons.text_aligncenter, () {}, primaryColor),
          _toolbarIconButton(CupertinoIcons.increase_indent, () {}, primaryColor),
        ],
      ),
    );
  }

  Widget _toolbarIconButton(IconData icon, VoidCallback onTap, Color color, {bool isAi = false, bool isActive = false}) {
    return IconButton(
      icon: isAi 
        ? ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.purple, Colors.blue, Colors.orange],
            ).createShader(bounds),
            child: Icon(icon, color: Colors.white),
          )
        : Icon(icon, color: isActive ? _notesBlue : color),
      onPressed: onTap,
    );
  }

  Widget _textFormatButton(String label, VoidCallback onTap, double fontSize, Color textColor, {bool isActive = false}) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          color: isActive ? _notesBlue : textColor,
        ),
      ),
    );
  }
}
