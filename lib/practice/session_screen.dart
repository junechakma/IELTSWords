import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../app_scope.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'modes/chart_modes.dart';
import 'modes/listening_modes.dart';
import 'modes/side_modes.dart';
import 'modes/swap_modes.dart';
import 'practice_mode.dart';
import 'questions.dart';
import 'session_builder.dart';
import 'session_controller.dart';
import 'summary_view.dart';

/// Opens a practice session (or the "nothing due" screen when it is empty).
Future<void> startPractice(BuildContext context, SessionRequest request, {String? title}) {
  final scope = AppScope.of(context);
  final questions = SessionBuilder(scope.repo, scope.progress, scope.store).build(request);
  return Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => questions.isEmpty
        ? _EmptySession(mode: request.mode)
        : SessionScreen(
            controller: SessionController(mode: request.mode, questions: questions, progress: scope.progress, store: scope.store, title: title),
            request: request,
          ),
  ));
}

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, required this.controller, required this.request});
  final SessionController controller;
  final SessionRequest request;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  SessionController get c => widget.controller;

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (!c.finished && c.practised.isNotEmpty) await c.complete();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        if (c.finished) {
          return Scaffold(body: SummaryView(controller: c, request: widget.request));
        }
        final q = c.current;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _close();
          },
          child: Scaffold(
            body: _SessionInfo(
              controller: c,
              onClose: _close,
              child: Stack(
                children: [
                  Positioned.fill(child: KeyedSubtree(key: ValueKey(c.index), child: _questionWidget(q))),
                  if (c.feedback != null)
                    Positioned(left: 0, right: 0, bottom: 0, child: FeedbackPanel(feedback: c.feedback!, onContinue: c.next, seed: c.index)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _questionWidget(Question q) => switch (q) {
        SwapChoiceQ q => SwapChoiceView(q),
        SwapTypeQ q => SwapTypeView(q),
        RewriteQ q => RewriteView(q),
        SpotQ q => SpotView(q),
        BuildQ q => BuildView(q),
        DescribeQ q => DescribeView(q),
        AdjAdvQ q => AdjAdvView(q),
        LabelQ q => LabelView(q),
        OrderQ q => OrderView(q),
        FlashQ q => FlashView(q),
        MeaningQ q => MeaningView(q),
        LinkerSortQ q => LinkerSortView(q),
        RegisterQ q => RegisterView(q),
        WhereQ q => WhereView(q),
        PictureQ q => PictureView(q),
        RouteQ q => RouteView(q),
        SpellQ q => SpellView(q),
        TrapQ q => TrapView(q),
      };
}

class _SessionInfo extends InheritedWidget {
  const _SessionInfo({required this.controller, required this.onClose, required super.child});
  final SessionController controller;
  final VoidCallback onClose;
  @override
  bool updateShouldNotify(_SessionInfo old) => false;
}

/// The controller of the session a question widget sits in.
SessionController sessionOf(BuildContext context) => context.getInheritedWidgetOfExactType<_SessionInfo>()!.controller;

/// Standard question layout: coloured wavy band with the top bar and [header],
/// then [body], then [bottom] (usually a Check button).
class SessionFrame extends StatelessWidget {
  const SessionFrame({super.key, required this.header, required this.body, this.bottom, this.color});

  final Widget header;
  final Widget body;
  final Widget? bottom;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final info = context.getInheritedWidgetOfExactType<_SessionInfo>()!;
    final c = info.controller;
    final q = c.current;
    final bg = color ?? c.mode.color;
    final feedbackOpen = c.feedback != null;

    final content = [
      ClipPath(
        clipper: const WaveClipper(),
        child: Container(
          color: bg,
          padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 16, 42),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Semantics(
                    label: 'Close',
                    button: true,
                    child: GestureDetector(onTap: info.onClose, child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close_rounded, size: 24))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: c.progressValue),
                        duration: const Duration(milliseconds: 350),
                        builder: (_, v, _) => LinearProgressIndicator(
                          value: v,
                          minHeight: 7,
                          backgroundColor: Colors.white.withValues(alpha: .6),
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${c.index + 1} / ${c.questions.length}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(spacing: 6, runSpacing: 6, children: [TagChip(_modeTag(c.mode, q)), TagChip(q.tag)]),
              const SizedBox(height: 14),
              header,
            ],
          ),
        ),
      ),
    ];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: feedbackOpen ? 260 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...content,
                Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 0), child: body),
              ],
            ),
          ),
        ),
        if (bottom != null && !feedbackOpen)
          SafeArea(
            top: false,
            child: Padding(padding: const EdgeInsets.fromLTRB(16, 6, 16, 12), child: bottom!),
          ),
      ],
    );
  }

  static String _modeTag(PracticeMode m, Question q) => switch (q) {
        SwapTypeQ() => 'Swap it · type',
        _ => m == PracticeMode.review ? 'Review' : m.title,
      };
}

/// Slides up after an answer: mascot reaction, message and Continue.
class FeedbackPanel extends StatelessWidget {
  const FeedbackPanel({super.key, required this.feedback, required this.onContinue, this.seed = 0});
  final AnswerFeedback feedback;
  final VoidCallback onContinue;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, mascot) = switch (feedback.verdict) {
      Verdict.right => (const Color(0xFFE6EDCF), const Color(0xFF4F6414), Mascot.pick(Mascot.correct, seed)),
      Verdict.tooPlain => (const Color(0xFFF8DAD3), const Color(0xFFA3321A), Mascot.pick(Mascot.wrong, seed)),
      Verdict.wrong => (const Color(0xFFF8DAD3), const Color(0xFFA3321A), Mascot.pick(Mascot.wrong, seed + 1)),
    };
    Widget m = MascotImage(mascot, size: 64, sticker: true);
    m = feedback.correct
        ? m.animate().scaleXY(begin: .6, end: 1, duration: 380.ms, curve: Curves.elasticOut).then().moveY(begin: 0, end: -6, duration: 160.ms).then().moveY(begin: 0, end: 6, duration: 160.ms)
        : m.animate().shakeX(hz: 5, amount: 5, duration: 450.ms);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, -4))],
      ),
      padding: EdgeInsets.fromLTRB(20, 18, 20, 14 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              m,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(feedback.title, style: TextStyle(fontSize: 21, color: fg, fontWeight: FontWeight.w500)),
                    if (feedback.answer != null) ...[
                      const SizedBox(height: 4),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: 'Band 8: ', style: TextStyle(color: fg, fontSize: 14)),
                        TextSpan(text: feedback.answer, style: TextStyle(color: fg, fontSize: 14.5, fontWeight: FontWeight.w600)),
                      ])),
                    ],
                    if (feedback.body != null) ...[
                      const SizedBox(height: 4),
                      Text(feedback.body!, style: TextStyle(color: fg, fontSize: 13.5, height: 1.35)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PillButton(feedback.correct ? 'Continue' : 'Got it', dark: true, onTap: onContinue),
        ],
      ),
    ).animate().moveY(begin: 60, end: 0, duration: 260.ms, curve: Curves.easeOutCubic).fadeIn(duration: 200.ms);
  }
}

/// An answer card that turns green / red once answered.
class AnswerCard extends StatelessWidget {
  const AnswerCard({super.key, required this.text, required this.onTap, this.state = AnswerState.idle, this.note, this.selected = false, this.fontSize = 17, this.child});
  final String text;
  final VoidCallback? onTap;
  final AnswerState state;
  final String? note;
  final bool selected;
  final double fontSize;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final (border, bg) = switch (state) {
      AnswerState.right => (AppColors.olive, const Color(0xFFF1F5E4)),
      AnswerState.wrong => (AppColors.rust, const Color(0xFFFBEAE5)),
      AnswerState.idle => (selected ? AppColors.ink : Colors.transparent, AppColors.card),
    };
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 15, 14, 15),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border, width: 2)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  child ?? Text(text, style: TextStyle(fontSize: fontSize, height: 1.3)),
                  if (note != null) ...[
                    const SizedBox(height: 6),
                    Text(note!, style: TextStyle(fontSize: 12.5, color: state == AnswerState.wrong ? AppColors.rust : AppColors.inkSoft)),
                  ],
                ],
              ),
            ),
            if (state == AnswerState.right) const Icon(Icons.check_rounded, color: AppColors.olive),
            if (state == AnswerState.wrong) const Icon(Icons.close_rounded, color: AppColors.rust),
          ],
        ),
      ),
    ).animate(target: state == AnswerState.wrong ? 1 : 0).shakeX(hz: 4, amount: 4, duration: 350.ms);
  }
}

enum AnswerState { idle, right, wrong }

/// A white prompt card inside the coloured band.
class PromptCard extends StatelessWidget {
  const PromptCard({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 16)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(22)),
        child: child,
      );
}

class _EmptySession extends StatelessWidget {
  const _EmptySession({required this.mode});
  final PracticeMode mode;

  @override
  Widget build(BuildContext context) {
    final review = mode == PracticeMode.review;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [const BackPill(), Expanded(child: Text(mode.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge)), const SizedBox(width: 46)]),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: EmptyState(
                    mascot: Mascot.pick(Mascot.empty, math.Random().nextInt(2)),
                    title: review ? 'Nothing to review today' : 'Nothing to practise here yet',
                    message: review ? 'Swaps come back after 1, 2, 4, 7 and 15 days.\nPractise a new chart and they will return here.' : 'This mode needs content that is not available for this choice.',
                    action: review ? 'Try a new chart' : 'Back',
                    onAction: () {
                      Navigator.of(context).pop();
                      if (review) {
                        final repo = AppScope.of(context).repo;
                        final (t, s) = repo.todaysPractice(DateTime.now());
                        startPractice(context, SessionRequest(PracticeMode.swapIt, topicId: t.id, slot: s));
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
