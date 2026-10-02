import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SecurityQuestionPickerSheet extends StatelessWidget {
  final String selectedQuestion;

  const SecurityQuestionPickerSheet({
    super.key,
    required this.selectedQuestion,
  });

  static Future<String?> show(BuildContext context, String currentQuestion) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SecurityQuestionPickerSheet(selectedQuestion: currentQuestion),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Chọn câu hỏi bảo mật',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: AppConstants.securityQuestions.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 20,
                  endIndent: 20,
                  color: Color(0xFFE2E8F0),
                ),
                itemBuilder: (context, index) {
                  final question = AppConstants.securityQuestions[index];
                  final isSelected = question == selectedQuestion;

                  return InkWell(
                    onTap: () => Navigator.pop(context, question),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              question,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? primaryColor : const Color(0xFF334155),
                              ),
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.check_circle,
                              color: primaryColor,
                              size: 22,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
