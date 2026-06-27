import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../painters/search_icon_painter.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isFocused ? appFmGreen : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF28321E).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CustomPaint(
            size: const Size(20, 20),
            painter: SearchIconPainter(color: appSearchGrey),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: appFmDark,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: isFocused
                    ? 'Plages, lacs, rivières'
                    : 'Cherche un endroit pour te rafraîchir…',
                hintStyle: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: appSearchGrey,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (isFocused)
            GestureDetector(
              onTap: onClear,
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: appClearBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: appClearIcon, size: 14),
              ),
            ),
        ],
      ),
    );
  }
}
