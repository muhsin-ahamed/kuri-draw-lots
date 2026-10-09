import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const KuriApp());
}

class KuriApp extends StatelessWidget {
  const KuriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'കുറി - Kuri Lucky Draw',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.notoSansMalayalamTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const KuriHomeScreen(),
    );
  }
}

class KuriHomeScreen extends StatefulWidget {
  const KuriHomeScreen({super.key});

  @override
  State<KuriHomeScreen> createState() => _KuriHomeScreenState();
}

class _KuriHomeScreenState extends State<KuriHomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late ConfettiController _confettiController;
  final ScrollController _memberScrollController = ScrollController();
  final List<GlobalKey> _memberKeys = [];

  // List of members added by user
  final List<String> _members = [];

  // History of winners drawn in current session
  final List<Map<String, String>> _drawHistory = [];

  // Shuffling & highlight animation state
  int _highlightedIndex = -1;

  // User manual view selection override (null = auto: Mobile -> Column, Web -> Row)
  bool? _userSelectedColumnView;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    _confettiController.dispose();
    _memberScrollController.dispose();
    super.dispose();
  }

  void _syncKeys() {
    while (_memberKeys.length < _members.length) {
      _memberKeys.add(GlobalKey());
    }
    if (_memberKeys.length > _members.length) {
      _memberKeys.removeRange(_members.length, _memberKeys.length);
    }
  }

  void _scrollToHighlightedIndex(int index) {
    if (index < 0 || index >= _memberKeys.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyContext = _memberKeys[index].currentContext;
      if (keyContext != null && mounted) {
        Scrollable.ensureVisible(
          keyContext,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: 0.5,
        );
      }
    });
  }

  // Add member function
  void _addMember() {
    final text = _nameController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        if (!_members.contains(text)) {
          _members.add(text);
          _nameController.clear();
        } else {
          _showSnackBar('ഈ പേര് ഇതിനകം ലിസ്റ്റിലുണ്ട്!');
        }
      });
      _focusNode.requestFocus();
    }
  }

  // Remove member function
  void _removeMember(int index) {
    setState(() {
      _members.removeAt(index);
      if (_highlightedIndex >= _members.length) {
        _highlightedIndex = -1;
      }
    });
  }

  // Clear all members
  void _clearAllMembers() {
    if (_members.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('എല്ലാ അംഗങ്ങളെയും ഒഴിവാക്കണോ?'),
        content: const Text('എല്ലാ പേരുകളും ലിസ്റ്റിൽ നിന്ന് നീക്കം ചെയ്യും.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('റദ്ദാക്കുക'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _members.clear();
                _highlightedIndex = -1;
              });
              Navigator.pop(ctx);
            },
            child: const Text('നീക്കം ചെയ്യുക'),
          ),
        ],
      ),
    );
  }

  // Draw Lot function: directly opens the Spinning Wheel Modal Popup
  void _drawLot() {
    if (_members.isEmpty) {
      _showSnackBar('ദയവായി കുറഞ്ഞത് ഒരു അംഗത്തെയെങ്കിലും ചേർക്കുക!');
      return;
    }

    _syncKeys();
    _showSpinningWheelDialog();
  }

  void _showSpinningWheelDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Spinning Wheel Dialog',
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: anim1,
            child: _SpinWheelDialog(
              members: List.unmodifiable(_members),
              onWinnerSelected: (winnerIndex, winnerName) {
                final timestamp = TimeOfDay.now().format(context);
                setState(() {
                  _highlightedIndex = winnerIndex;
                  _drawHistory.insert(0, {
                    'name': winnerName,
                    'time': timestamp,
                  });
                });
                _scrollToHighlightedIndex(winnerIndex);
              },
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.notoSansMalayalam(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E40AF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isDesktop = screenSize.width >= 900;
    final isColumnView = _userSelectedColumnView ?? isMobile;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background subtle ambient light blue glow circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFDBEAFE).withValues(alpha: 0.5),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEFF6FF).withValues(alpha: 0.8),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Main Scrollable Body
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12.0 : (isDesktop ? 24.0 : 16.0),
                    vertical: isMobile ? 12.0 : 16.0,
                  ),
                  child: Column(
                    children: [
                      // Header Widget
                      _buildHeader(isMobile),
                      SizedBox(height: isMobile ? 12 : 20),

                      // Glass Card Main Container
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(isMobile ? 20 : 28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.82),
                                borderRadius: BorderRadius.circular(isMobile ? 20 : 28),
                                border: Border.all(
                                  color: const Color(0xFFBFDBFE).withValues(alpha: 0.6),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1E40AF)
                                        .withValues(alpha: 0.06),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(isMobile ? 16 : (isDesktop ? 28 : 20)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Add Member Input Section
                                  _buildAddMemberSection(isMobile),
                                  SizedBox(height: isMobile ? 16 : 24),

                                  // Members List Title & Quick Actions Row
                                  _buildMemberListHeader(isColumnView, isMobile),
                                  const SizedBox(height: 12),

                                  // Members List Grid / Chips / Rows
                                  Expanded(
                                    child: _buildMembersList(isColumnView),
                                  ),
                                  const SizedBox(height: 16),

                                  // Main Draw Lot Button ("നറുക്കെടുക്കുക")
                                  _buildDrawButton(isMobile),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Footer copyright / info
                      const SizedBox(height: 12),
                      Text(
                        'സുതാര്യമായ കുറി നറുക്കെടുപ്പ് പ്രോഗ്രാം • Kuri Web App',
                        style: GoogleFonts.notoSansMalayalam(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // App Header Component
  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isMobile ? 6 : 12,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                  ),
                  borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: isMobile ? 22 : 26,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'കുറി',
                style: GoogleFonts.notoSansMalayalam(
                  fontSize: isMobile ? 28 : 34,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E3A8A),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'ഡിജിറ്റൽ സുതാര്യമായ കുറി നറുക്കെടുപ്പ് സംവിധാനം',
            style: GoogleFonts.notoSansMalayalam(
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // Add Member Input Section
  Widget _buildAddMemberSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.person_add_outlined,
              size: 20,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(width: 8),
            Text(
              'അംഗങ്ങളെ ചേർക്കുക',
              style: GoogleFonts.notoSansMalayalam(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _nameController,
                  focusNode: _focusNode,
                  onSubmitted: (_) => _addMember(),
                  style: GoogleFonts.notoSansMalayalam(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: isMobile
                        ? 'അംഗത്തിന്റെ പേര് നൽകുക...'
                        : 'അംഗത്തിന്റെ പേര് ഇവിടെ ടൈപ്പ് ചെയ്യുക...',
                    hintStyle: GoogleFonts.notoSansMalayalam(
                      fontSize: 14,
                      color: const Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.account_circle_outlined,
                      color: Color(0xFF3B82F6),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _addMember,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 14 : 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                label: Text(
                  'ചേർക്കുക',
                  style: GoogleFonts.notoSansMalayalam(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Member List Header
  Widget _buildMemberListHeader(bool isColumnView, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  isMobile ? 'അംഗങ്ങൾ' : 'ചേർത്ത അംഗങ്ങൾ',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSansMalayalam(
                    fontSize: isMobile ? 14 : 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_members.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // View mode toggle button (Column View vs Row View)
              Tooltip(
                message: isColumnView ? 'റോ വ്യൂവിലേക്ക് മാറ്റുക' : 'കോളം വ്യൂവിലേക്ക് മാറ്റുക',
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _userSelectedColumnView = !isColumnView;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Icon(
                      isColumnView
                          ? Icons.view_headline_rounded
                          : Icons.grid_view_rounded,
                      size: 16,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_members.isNotEmpty)
          Row(
            children: [
              TextButton.icon(
                onPressed: _clearAllMembers,
                icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                label: Text(
                  isMobile ? 'മായ്ക്കുക' : 'എല്ലാം മായ്ക്കുക',
                  style: GoogleFonts.notoSansMalayalam(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
      ],
    );
  }

  // Members List Component (Responsive: Column View on Mobile, Row View on Web)
  Widget _buildMembersList(bool isColumnView) {
    _syncKeys();

    if (_members.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.people_outline_rounded,
                    size: 36,
                    color: Color(0xFF60A5FA),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'അംഗങ്ങളെയൊന്നും ചേർത്തിട്ടില്ല!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansMalayalam(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'മുകളിലെ ബോക്സിൽ പേര് നൽകി "ചേർക്കുക" ബട്ടൺ അമർത്തുക.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansMalayalam(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isColumnView) {
      // Single Column View Layout (Mobile view: 1 item per row, 100% full width cards)
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(12),
        child: ListView.separated(
          controller: _memberScrollController,
          physics: const BouncingScrollPhysics(),
          itemCount: _members.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final memberName = _members[index];
            final isHighlighted = _highlightedIndex == index;

            return AnimatedScale(
              key: _memberKeys[index],
              scale: isHighlighted ? 1.02 : 1.0,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isHighlighted
                      ? const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  color: isHighlighted ? null : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isHighlighted
                        ? const Color(0xFF93C5FD)
                        : const Color(0xFFE2E8F0),
                    width: isHighlighted ? 2 : 1,
                  ),
                  boxShadow: isHighlighted
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2563EB)
                                .withValues(alpha: 0.35),
                            blurRadius: 14,
                            spreadRadius: 1,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    // Index Badge Avatar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? Colors.white.withValues(alpha: 0.25)
                            : const Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isHighlighted
                                ? Colors.white
                                : const Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name Text
                    Expanded(
                      child: Text(
                        memberName,
                        style: GoogleFonts.notoSansMalayalam(
                          fontSize: 15,
                          fontWeight: isHighlighted
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isHighlighted
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ),

                    // Remove Button
                    InkWell(
                      onTap: () => _removeMember(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close_rounded,
                          color: isHighlighted
                              ? Colors.white.withValues(alpha: 0.85)
                              : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    // Row View Layout (Web / Desktop view: Wrap layout with multi-column horizontal cards)
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        controller: _memberScrollController,
        physics: const BouncingScrollPhysics(),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.start,
          children: List.generate(_members.length, (index) {
            final memberName = _members[index];
            final isHighlighted = _highlightedIndex == index;

            return AnimatedScale(
              key: _memberKeys[index],
              scale: isHighlighted ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutBack,
              child: SizedBox(
                width: 185,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isHighlighted
                        ? const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isHighlighted ? null : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isHighlighted
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFFE2E8F0),
                      width: isHighlighted ? 2 : 1,
                    ),
                    boxShadow: isHighlighted
                        ? [
                            BoxShadow(
                              color: const Color(0xFF2563EB)
                                  .withValues(alpha: 0.45),
                              blurRadius: 18,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      // Index Badge Avatar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? Colors.white.withValues(alpha: 0.25)
                              : const Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isHighlighted
                                  ? Colors.white
                                  : const Color(0xFF1E40AF),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Name Text
                      Expanded(
                        child: Text(
                          memberName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.notoSansMalayalam(
                            fontSize: 14,
                            fontWeight: isHighlighted
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isHighlighted
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ),

                      // Remove Button
                      InkWell(
                        onTap: () => _removeMember(index),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Icon(
                            Icons.close_rounded,
                            color: isHighlighted
                                ? Colors.white.withValues(alpha: 0.8)
                                : const Color(0xFF94A3B8),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // Draw Button ("നറുക്കെടുക്കുക")
  Widget _buildDrawButton(bool isMobile) {
    return Container(
      width: double.infinity,
      height: isMobile ? 54 : 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _drawLot,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.casino_outlined,
                color: Colors.white,
                size: isMobile ? 22 : 26,
              ),
              const SizedBox(width: 8),
              Text(
                'നറുക്കെടുക്കുക',
                style: GoogleFonts.notoSansMalayalam(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpinWheelDialog extends StatefulWidget {
  final List<String> members;
  final Function(int winnerIndex, String winnerName) onWinnerSelected;

  const _SpinWheelDialog({
    required this.members,
    required this.onWinnerSelected,
  });

  @override
  State<_SpinWheelDialog> createState() => _SpinWheelDialogState();
}

class _SpinWheelDialogState extends State<_SpinWheelDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late ConfettiController _confettiController;

  double _startAngle = 0.0;
  double _targetAngle = 0.0;
  double _currentAngle = 0.0;

  int _currentHoverIndex = 0;
  int _winnerIndex = 0;
  bool _isSpinning = false;
  bool _hasFinished = false;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 4));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    );

    _animation.addListener(_onSpinTick);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onSpinComplete();
      }
    });

    // Automatically trigger spin on popup modal open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSpin();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _startSpin() {
    if (widget.members.isEmpty || _isSpinning) return;

    _confettiController.stop();

    _winnerIndex = _random.nextInt(widget.members.length);
    final count = widget.members.length;
    final sliceAngle = (2 * pi) / count;
    final winnerCenter = _winnerIndex * sliceAngle + (sliceAngle / 2);

    final fullSpins = 6 + _random.nextInt(3);

    final baseOffset = (1.5 * pi) - winnerCenter;
    
    _startAngle = _currentAngle % (2 * pi);
    if (_startAngle < 0) _startAngle += 2 * pi;
    
    double desiredRem = baseOffset % (2 * pi);
    if (desiredRem < 0) desiredRem += 2 * pi;

    double deltaRem = desiredRem - _startAngle;
    if (deltaRem <= 0) deltaRem += 2 * pi;

    _targetAngle = _startAngle + (fullSpins * 2 * pi) + deltaRem;

    setState(() {
      _isSpinning = true;
      _hasFinished = false;
    });

    HapticFeedback.mediumImpact();
    _controller.forward(from: 0.0);
  }

  void _onSpinTick() {
    final progress = _animation.value;
    final newAngle = _startAngle + (_targetAngle - _startAngle) * progress;

    final count = widget.members.length;
    final sliceAngle = (2 * pi) / count;

    double pointerAngle = (1.5 * pi - (newAngle % (2 * pi))) % (2 * pi);
    if (pointerAngle < 0) pointerAngle += 2 * pi;

    int newHoverIndex = (pointerAngle / sliceAngle).floor() % count;

    if (newHoverIndex != _currentHoverIndex) {
      HapticFeedback.selectionClick();
    }

    setState(() {
      _currentAngle = newAngle;
      _currentHoverIndex = newHoverIndex;
    });
  }

  void _onSpinComplete() {
    setState(() {
      _isSpinning = false;
      _hasFinished = true;
      _currentHoverIndex = _winnerIndex;
    });

    HapticFeedback.heavyImpact();
    _confettiController.play();

    widget.onWinnerSelected(_winnerIndex, widget.members[_winnerIndex]);
  }

  @override
  Widget build(BuildContext context) {
    final activeName = widget.members.isNotEmpty
        ? widget.members[_currentHoverIndex % widget.members.length]
        : '';
    final winnerName = widget.members.isNotEmpty
        ? widget.members[_winnerIndex % widget.members.length]
        : '';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // Glassmorphism Card Container
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: const Color(0xFF93C5FD).withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E40AF).withValues(alpha: 0.22),
                      blurRadius: 36,
                      spreadRadius: 4,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Subtitle Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isSpinning
                                ? Icons.sync_rounded
                                : Icons.verified_rounded,
                            size: 16,
                            color: const Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isSpinning
                                ? 'നറുക്കെടുക്കുന്നു...'
                                : 'നറുക്കെടുപ്പ് വിജയി',
                            style: GoogleFonts.notoSansMalayalam(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E40AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Spinning Wheel Widget
                    SizedBox(
                      height: 230,
                      width: 230,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: 14,
                            child: CustomPaint(
                              size: const Size(200, 200),
                              painter: WheelPainter(
                                members: widget.members,
                                currentAngle: _currentAngle,
                                highlightedIndex: _currentHoverIndex,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            child: CustomPaint(
                              size: const Size(24, 28),
                              painter: WheelPointerPainter(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Winner or Ticker Name Display Box
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _hasFinished
                          ? Container(
                              key: const ValueKey('winnerCard'),
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFEFF6FF),
                                    Color(0xFFDBEAFE),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF93C5FD),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB)
                                        .withValues(alpha: 0.12),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'ഈ മാസത്തെ കുറി ലഭിച്ചത്:',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.notoSansMalayalam(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    winnerName,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.notoSansMalayalam(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1E3A8A),
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              key: const ValueKey('tickerCard'),
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      activeName,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.notoSansMalayalam(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSpinning ? null : _startSpin,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              side: BorderSide(
                                color: _isSpinning
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF3B82F6),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              _hasFinished ? 'വീണ്ടും നറുക്കെടുക്കുക' : 'സ്പിൻ ചെയ്യുക',
                              style: GoogleFonts.notoSansMalayalam(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _isSpinning
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isSpinning
                                    ? [
                                        const Color(0xFF94A3B8),
                                        const Color(0xFF64748B)
                                      ]
                                    : [
                                        const Color(0xFF2563EB),
                                        const Color(0xFF1D4ED8),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'ശരി',
                                style: GoogleFonts.notoSansMalayalam(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Floating Trophy Icon on Top
          Positioned(
            top: -32,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E40AF).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                _hasFinished ? Icons.emoji_events_rounded : Icons.casino_rounded,
                color: Colors.amber,
                size: 34,
              ),
            ),
          ),

          // Confetti Animation overlay widget
          Positioned(
            top: -20,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 35,
              gravity: 0.15,
              emissionFrequency: 0.05,
              colors: const [
                Color(0xFF2563EB),
                Color(0xFF3B82F6),
                Color(0xFFF59E0B),
                Color(0xFF10B981),
                Color(0xFFEC4899),
                Color(0xFF8B5CF6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<String> members;
  final double currentAngle;
  final int highlightedIndex;

  WheelPainter({
    required this.members,
    required this.currentAngle,
    required this.highlightedIndex,
  });

  static const List<Color> sliceColors = [
    Color(0xFF2563EB), // Blue
    Color(0xFF7C3AED), // Purple
    Color(0xFFDB2777), // Pink
    Color(0xFFEA580C), // Orange
    Color(0xFF059669), // Emerald
    Color(0xFF0891B2), // Cyan
    Color(0xFFD97706), // Amber
    Color(0xFF4F46E5), // Indigo
    Color(0xFFE11D48), // Rose
    Color(0xFF0D9488), // Teal
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final count = members.length;
    if (count == 0) return;

    final sweepAngle = (2 * pi) / count;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(currentAngle);

    // Draw slices
    for (int i = 0; i < count; i++) {
      final startAngle = i * sweepAngle;
      final color = sliceColors[i % sliceColors.length];
      final isHighlighted = (i == highlightedIndex);

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = isHighlighted
            ? Color.alphaBlend(Colors.white.withValues(alpha: 0.35), color)
            : color;

      final path = Path()
        ..moveTo(0, 0)
        ..arcTo(
          Rect.fromCircle(center: Offset.zero, radius: radius),
          startAngle,
          sweepAngle,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);

      // Slice border line
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(path, borderPaint);

      // Radial Member label/index text
      if (count <= 16) {
        final textAngle = startAngle + (sweepAngle / 2);
        canvas.save();
        canvas.rotate(textAngle);

        final textSpan = TextSpan(
          text: count <= 8 ? members[i] : '${i + 1}',
          style: TextStyle(
            color: Colors.white,
            fontSize: count <= 6 ? 12 : 10,
            fontWeight: FontWeight.bold,
            fontFamily: GoogleFonts.notoSansMalayalam().fontFamily,
            shadows: const [
              Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(1, 1)),
            ],
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '...',
        );
        textPainter.layout(maxWidth: radius * 0.55);

        canvas.translate(radius * 0.55, -textPainter.height / 2);
        textPainter.paint(canvas, Offset.zero);

        canvas.restore();
      }
    }

    canvas.restore();

    // Outer Rim Ring
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF1E40AF)
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, rimPaint);

    final rimInnerBorder = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF93C5FD)
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 4, rimInnerBorder);

    // Decorative Pegs around rim
    const pegCount = 12;
    final pegRadius = radius - 1;
    for (int p = 0; p < pegCount; p++) {
      final pegAngle = (2 * pi / pegCount) * p;
      final pegX = center.dx + pegRadius * cos(pegAngle);
      final pegY = center.dy + pegRadius * sin(pegAngle);

      final pegPaint = Paint()
        ..color = Colors.amber
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(pegX, pegY), 3.5, pegPaint);

      final pegBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(Offset(pegX, pegY), 3.5, pegBorder);
    }

    // Central Hub Cap
    final hubRadius = radius * 0.28;
    final hubPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          const Color(0xFFDBEAFE),
          const Color(0xFF2563EB),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: hubRadius));
    canvas.drawCircle(center, hubRadius, hubPaint);

    final hubBorder = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF1E40AF)
      ..strokeWidth = 3;
    canvas.drawCircle(center, hubRadius, hubBorder);

    // Center Hub Icon / Dot
    final starPaint = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 7, starPaint);
  }

  @override
  bool shouldRepaint(covariant WheelPainter oldDelegate) {
    return oldDelegate.currentAngle != currentAngle ||
        oldDelegate.highlightedIndex != highlightedIndex ||
        oldDelegate.members != members;
  }
}

class WheelPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 - 12, 0)
      ..lineTo(size.width / 2 + 12, 0)
      ..close();

    final shadowPaint = Paint()
      ..color = Colors.black38
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path.shift(const Offset(0, 2)), shadowPaint);

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

