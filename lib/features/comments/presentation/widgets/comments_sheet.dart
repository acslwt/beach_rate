import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/relative_time.dart';
import '../../domain/comment_validation.dart';
import '../../domain/entities/spot_comment.dart';
import '../../domain/usecases/watch_comments.dart';

/// Modal listing a spot's comments, with a field to post a new one — dumb
/// about identity (the caller supplies [loggedIn] and [onSubmit]), same
/// composition pattern as `AddSpotForm`/`AffluenceLevelPicker`.
class CommentsSheet extends StatefulWidget {
  const CommentsSheet({
    super.key,
    required this.spotName,
    required this.zoneId,
    required this.watchComments,
    required this.loggedIn,
    required this.onSubmit,
    required this.onClose,
  });

  final String spotName;
  final String zoneId;
  final WatchComments watchComments;
  final bool loggedIn;
  final Future<bool> Function(String text) onSubmit;
  final VoidCallback onClose;

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _textCtrl = TextEditingController();
  List<SpotComment>? _comments;
  StreamSubscription<List<SpotComment>>? _sub;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sub = widget.watchComments(widget.zoneId).listen((comments) {
      if (mounted) setState(() => _comments = comments);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final validationError = validateCommentText(_textCtrl.text);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final ok = await widget.onSubmit(_textCtrl.text.trim());

    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      _textCtrl.clear();
    } else {
      setState(() => _error = 'Une erreur est survenue. Réessaie.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final comments = _comments;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF283223).withValues(alpha: 0.22),
            blurRadius: 44,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Commentaires',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: appFmDark,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onClose,
                child: const Icon(Icons.close_rounded, size: 20, color: appSearchGrey),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            widget.spotName,
            style: GoogleFonts.nunito(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: appSearchGrey,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: comments == null
                ? const Center(child: CircularProgressIndicator(color: appCoral))
                : comments.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun commentaire pour l\'instant.\nSois le premier !',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: appInkMid,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: comments.length,
                        separatorBuilder: (context, i) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => _CommentTile(comment: comments[i]),
                      ),
          ),
          const SizedBox(height: 14),
          if (!widget.loggedIn)
            Text(
              'Connecte-toi pour commenter.',
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: appInkMid,
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    minLines: 1,
                    maxLines: 3,
                    style: GoogleFonts.nunito(fontSize: 13.5, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: 'Ajouter un commentaire…',
                      hintStyle: GoogleFonts.nunito(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: appSearchGrey,
                      ),
                      filled: true,
                      fillColor: appSuggHover,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submitting ? null : _submit,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _submitting ? appCoral.withValues(alpha: 0.5) : appCoral,
                      shape: BoxShape.circle,
                    ),
                    child: _submitting
                        ? const Padding(
                            padding: EdgeInsets.all(11),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 19),
                  ),
                ),
              ],
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.red.shade400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final SpotComment comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: appSuggHover,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  comment.userName,
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: appFmDark,
                  ),
                ),
              ),
              Text(
                relativeTime(comment.createdAt),
                style: GoogleFonts.nunito(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: appInkMid,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            comment.text,
            style: GoogleFonts.nunito(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: appFmDark,
            ),
          ),
        ],
      ),
    );
  }
}
