import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ai_bot_icon.dart';
import 'models/rag_appointment.dart';
import 'services/ai_assistant_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

// ── Local chat message model ─────────────────────────────────────────────────
class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// AI Assistant Screen
// ═════════════════════════════════════════════════════════════════════════════

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen>
    with TickerProviderStateMixin {
  final _service = AiAssistantService.instance;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocusNode = FocusNode();

  List<RagAppointment> _appointments = [];
  final List<_ChatMessage> _messages = [];
  String? _selectedEncounterId;
  RagAppointment? _selectedAppointment;

  bool _isLoadingAppointments = true;
  bool _isTyping = false;
  bool _showAll = false;
  bool _isListCollapsed = false;
  String? _error;

  // Speech to Text properties
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  double _speechLevel = 0;

  late AnimationController _pulseCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;

  static const _suggestedQuestions = [
    'Prescriptions?',
    'Diagnosis?',
    'Follow-up?',
    'Lab results?',
    'Summary?',
    'Next visit?',
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _initSpeech();
    _loadAppointments();
  }

  Future<void> _initSpeech() async {
    try {
      await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          debugPrint("Speech status: $status");
          if (status == 'done' || status == 'notListening' || status == 'inactive') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() => _isListening = false);
        },
      );
    } catch (e) {
      debugPrint("Speech init error: $e");
    }
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        setState(() {
          _isListening = true;
          _speechLevel = 0;
        });
        await _speech.listen(
          onResult: (result) {
            if (!mounted) return;
            setState(() {
              _textController.text = result.recognizedWords;
              // Keep cursor at the end
              _textController.selection = TextSelection.fromPosition(
                TextPosition(offset: _textController.text.length),
              );
            });
          },
          onSoundLevelChange: (level) {
            if (!mounted) return;
            setState(() => _speechLevel = level);
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required')),
          );
        }
      }
    } else {
      await _speech.stop();
      setState(() => _isListening = false);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoadingAppointments = true;
      _error = null;
    });
    try {
      final appts = await _service.getRagAppointments();
      if (!mounted) return;
      setState(() {
        _appointments = appts;
        _isLoadingAppointments = false;
      });
      _fadeCtrl.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAppointments = false;
        _error = e.toString();
      });
    }
  }

  void _selectAppointment(RagAppointment appt) {
    if (_selectedEncounterId == appt.encounterId) return;
    setState(() {
      _selectedEncounterId = appt.encounterId;
      _selectedAppointment = appt;
      _messages.clear();
      _isListCollapsed = true;
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _selectedEncounterId == null) return;

    final question = text.trim();
    _textController.clear();

    setState(() {
      _messages.add(_ChatMessage(
        text: question,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final answer = await _service.askQuestion(
        encounterId: _selectedEncounterId!,
        question: question,
      );
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text: answer.answer,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text: 'Sorry, I couldn\'t process your question. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: Column(
        children: [
          _buildHeader(),
          _buildAppointmentSelector(),
          Expanded(child: _buildChatArea()),
          _buildSuggestionsRow(),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Premium Gradient Header ──────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00897B), Color(0xFF00BFA5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x4000BFA5),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Health Assistant',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      _selectedAppointment != null
                          ? 'Dr. ${_selectedAppointment!.doctorName} · ${_selectedAppointment!.formattedDate}'
                          : 'Select an appointment to start',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Appointment Selector Strip ───────────────────────────────────────────
  Widget _buildAppointmentSelector() {
    if (_isLoadingAppointments) {
      return Container(
        height: 100,
        color: Colors.white,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child:
                CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.statusCancelled, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Failed to load appointments',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.statusCancelled),
              ),
            ),
            TextButton(
              onPressed: _loadAppointments,
              child: Text('Retry',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ],
        ),
      );
    }

    if (_appointments.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(Icons.event_busy_rounded, color: Colors.grey.shade400, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No Clinical Records',
                      style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain)),
                  Text(
                    'Complete an appointment to use the AI assistant.',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final displayList =
        _showAll ? _appointments : _appointments.take(3).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isListCollapsed = !_isListCollapsed),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded,
                          size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
                      const SizedBox(width: 6),
                      Text(
                        'Your Appointments',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDeep.withValues(alpha: 0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 250),
                        turns: _isListCollapsed ? 0 : 0.5, // Down when closed, Up when open
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: AppColors.primary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 8),
                if (_appointments.length > 3 && !_isListCollapsed)
                  GestureDetector(
                    onTap: () => setState(() => _showAll = !_showAll),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _showAll ? 'Show Less' : 'Show All',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              children: [
                if (!_isListCollapsed) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      itemCount: displayList.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final appt = displayList[index];
                        final isSelected =
                            _selectedEncounterId == appt.encounterId;
                        return _AppointmentChip(
                          appointment: appt,
                          isSelected: isSelected,
                          onTap: () => _selectAppointment(appt),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ] else
                  const SizedBox(height: 14), // Added padding for collapsed state
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    if (_messages.isEmpty && !_isTyping) {
      return _buildSelectedWelcomeState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _TypingIndicator(key: const ValueKey('typing'));
        }
        final msg = _messages[index];
        return _ChatBubble(message: msg, key: ValueKey('msg_$index'));
      },
    );
  }

  Widget _buildSelectedWelcomeState() {
    if (_selectedAppointment == null) return _buildEmptyChatState();

    return Center(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 60,
                      height: 60,
                      child: Center(
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 44,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ask a question about visit with',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dr. ${_selectedAppointment!.doctorName}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      width: 40,
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You can ask about medications,\ndiagnosis, or follow-up instructions.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMain.withValues(alpha: 0.6),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChatState() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing AI brain animation
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, _) {
                  return Transform.scale(
                    scale: 0.95 + (0.1 * _pulseAnim.value),
                    child: const SizedBox(
                      width: 90,
                      height: 90,
                      child: Center(
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                'Select an appointment above',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a past appointment to ask questions about your visit, prescriptions, and more.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      child: Column(
        children: [
          // AI Greeting
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.06),
                  AppColors.primaryDeep.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                const SizedBox(
                  width: 52,
                  height: 52,
                  child: Center(
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 38,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hello! I\'m your AI Health Assistant',
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ask me anything about your appointment with Dr. ${_selectedAppointment?.doctorName ?? ''}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Suggestion chips
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'SUGGESTED QUESTIONS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDeep.withValues(alpha: 0.6),
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._suggestedQuestions.map((q) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SuggestionChip(
                  question: q,
                  onTap: () => _sendMessage(q),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSuggestionsRow() {
    final shouldShow = _selectedEncounterId != null &&
        _textController.text.trim().isEmpty;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: shouldShow
          ? Container(
              key: const ValueKey('suggestions_visible'),
              height: 40,
              margin: const EdgeInsets.only(bottom: 4),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _suggestedQuestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final question = _suggestedQuestions[index];
                  return GestureDetector(
                    onTap: () => _sendMessage(question),
                    child: Chip(
                      label: Text(
                        question,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                      backgroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.1),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  );
                },
              ),
            )
          : const SizedBox(
              key: ValueKey('suggestions_hidden'),
              height: 0,
            ),
    );
  }

  // ── Input Bar ────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    final isEnabled = _selectedEncounterId != null && !_isTyping;
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 4,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isEnabled ? Colors.white : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(28),
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
                border: Border.all(
                  color: isEnabled
                      ? AppColors.primary.withValues(alpha: 0.25)
                      : Colors.grey.shade300,
                  width: isEnabled ? 1.5 : 1,
                ),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _inputFocusNode,
                enabled: isEnabled,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMain),
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: isEnabled ? _sendMessage : null,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: _isListening
                      ? 'Listening...'
                      : (isEnabled
                          ? 'Ask about your visit...'
                          : 'Select an appointment first'),
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  border: InputBorder.none,
                  suffixIcon: isEnabled
                      ? _VoiceRippleButton(
                          isListening: _isListening,
                          onToggle: _toggleListening,
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(
            isEnabled: isEnabled && _textController.text.trim().isNotEmpty,
            onSend: () => _sendMessage(_textController.text),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Voice Ripple Button
// ═════════════════════════════════════════════════════════════════════════════

class _VoiceRippleButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onToggle;

  const _VoiceRippleButton({required this.isListening, required this.onToggle});

  @override
  State<_VoiceRippleButton> createState() => _VoiceRippleButtonState();
}

class _VoiceRippleButtonState extends State<_VoiceRippleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isListening) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(_VoiceRippleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening) {
      _ctrl.repeat();
    } else {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggle,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isListening)
              AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) {
                  return Opacity(
                    opacity: 1 - _ctrl.value,
                    child: Container(
                      width: 36 + (14 * _ctrl.value),
                      height: 36 + (14 * _ctrl.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            // Inner icon container
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isListening
                    ? Colors.redAccent
                    : AppColors.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                widget.isListening ? Icons.stop_rounded : Icons.mic_rounded,
                color: widget.isListening ? Colors.white : AppColors.primary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Appointment Chip
// ═════════════════════════════════════════════════════════════════════════════

class _AppointmentChip extends StatelessWidget {
  final RagAppointment appointment;
  final bool isSelected;
  final VoidCallback onTap;

  const _AppointmentChip({
    required this.appointment,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 190,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : const Color(0xFFE0E4E8),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Dr. ${appointment.doctorName}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? AppColors.primaryDeep
                              : AppColors.textMain,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  appointment.doctorSpecialty,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 11, color: AppColors.primary.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(
                      appointment.formattedDate,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.schedule_rounded,
                        size: 11, color: AppColors.primary.withValues(alpha: 0.6)),
                    const SizedBox(width: 3),
                    Text(
                      appointment.formattedTime,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  IconData _specialtyIcon(String specialty) {
    final s = specialty.toLowerCase();
    if (s.contains('cardi')) return Icons.favorite_rounded;
    if (s.contains('dermat')) return Icons.face_rounded;
    if (s.contains('pediatr')) return Icons.child_care_rounded;
    if (s.contains('neuro')) return Icons.psychology_rounded;
    if (s.contains('ortho')) return Icons.accessibility_new_rounded;
    return Icons.medical_services_rounded;
  }
}


// ═════════════════════════════════════════════════════════════════════════════
// Chat Bubble
// ═════════════════════════════════════════════════════════════════════════════

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const SizedBox(
              width: 30,
              height: 30,
              child: Center(child: AiBotIcon(size: 22)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF00897B), Color(0xFF00BFA5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isUser ? Colors.white : AppColors.textMain,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Typing Indicator (3 bouncing dots)
// ═════════════════════════════════════════════════════════════════════════════

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({super.key});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(
            width: 30,
            height: 30,
            child: Center(child: AiBotIcon(size: 22)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i * 0.2;
                    final t = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
                    final y = -6 * sin(t * pi);
                    return Transform.translate(
                      offset: Offset(0, y),
                      child: Container(
                        margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary
                              .withValues(alpha: 0.4 + 0.6 * (1 - t)),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Suggestion Chip
// ═════════════════════════════════════════════════════════════════════════════

class _SuggestionChip extends StatelessWidget {
  final String question;
  final VoidCallback onTap;

  const _SuggestionChip({required this.question, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                question,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.primary.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Animated Send Button
// ═════════════════════════════════════════════════════════════════════════════

class _SendButton extends StatefulWidget {
  final bool isEnabled;
  final VoidCallback onSend;

  const _SendButton({required this.isEnabled, required this.onSend});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.85,
      upperBound: 1.0,
    );
    _ctrl.value = 1.0;
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isEnabled ? (_) => _ctrl.reverse() : null,
      onTapUp: widget.isEnabled
          ? (_) {
              _ctrl.forward();
              widget.onSend();
            }
          : null,
      onTapCancel: widget.isEnabled ? () => _ctrl.forward() : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 400),
        scale: widget.isEnabled ? 1.0 : 0.85,
        curve: Curves.elasticOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: widget.isEnabled
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.isEnabled ? null : Colors.grey.shade200,
            boxShadow: widget.isEnabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: RotationTransition(
                  turns: animation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                ),
              );
            },
            child: Icon(
              Icons.send_rounded,
              key: ValueKey('icon_${widget.isEnabled}'),
              color: widget.isEnabled ? Colors.white : Colors.grey.shade400,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
