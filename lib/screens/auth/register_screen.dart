import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/app_theme.dart';
import '../../widgets/kini_logo_widget.dart';
import '../../widgets/security_question_picker_sheet.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedSecurityQuestion = AppConstants.securityQuestions.first;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register(
      username: _usernameController.text,
      password: _passwordController.text,
      displayName: _displayNameController.text,
      securityQuestion: _selectedSecurityQuestion,
      securityAnswer: _securityAnswerController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo tài khoản KINI thành công! Chào mừng bạn.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Đăng ký thất bại. Vui lòng kiểm tra lại thông tin.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _selectSecurityQuestion() async {
    final result = await SecurityQuestionPickerSheet.show(context, _selectedSecurityQuestion);
    if (result != null && mounted) {
      setState(() {
        _selectedSecurityQuestion = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.primaryCyan),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo KINI chuẩn Vibrant Cyber-Glass
                  const Center(
                    child: KiniLogoWidget(size: 76, showText: true),
                  ),
                  const SizedBox(height: 24),

                  // Tiêu đề & phụ đề
                  const Text(
                    'Tạo tài khoản KINI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chọn thông tin nhận diện và cách tự khôi phục mật khẩu của bạn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppTheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 1. Tên đăng nhập
                  _buildFieldLabel('Tên đăng nhập'),
                  TextFormField(
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    controller: _usernameController,
                    decoration: _inputDecoration(
                      hintText: 'Chỉ chữ, số, chấm, gạch dưới hoặc ngang',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Vui lòng nhập tên đăng nhập';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(v.trim())) {
                        return 'Chỉ chấp nhận chữ, số, dấu chấm, gạch dưới hoặc ngang';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. Mật khẩu
                  _buildFieldLabel('Mật khẩu'),
                  TextFormField(
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _inputDecoration(
                      hintText: 'Ít nhất 8 ký tự',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppTheme.outline,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 8) {
                        return 'Mật khẩu phải từ 8 ký tự trở lên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. Tên tài khoản
                  _buildFieldLabel('Tên tài khoản'),
                  TextFormField(
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    controller: _displayNameController,
                    decoration: _inputDecoration(
                      hintText: 'Tên hiển thị với bạn bè',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Vui lòng nhập tên hiển thị';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 4. Câu hỏi bảo mật
                  _buildFieldLabel('Câu hỏi bảo mật'),
                  InkWell(
                    onTap: _selectSecurityQuestion,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedSecurityQuestion,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryCyan),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. Câu trả lời bảo mật
                  _buildFieldLabel('Câu trả lời bảo mật'),
                  TextFormField(
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    controller: _securityAnswerController,
                    decoration: _inputDecoration(
                      hintText: 'Ghi nhớ chính xác câu trả lời',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Vui lòng nhập câu trả lời bảo mật';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Nút Tạo tài khoản Cyber-Glass
                  GestureDetector(
                    onTap: auth.isLoading ? null : _submit,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryCyan, AppTheme.secondaryViolet],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryCyan.withAlpha(90),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                            )
                          : const Text(
                              'Tạo tài khoản',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Link Đã có tài khoản? Đăng nhập
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: RichText(
                        text: const TextSpan(
                          text: 'Đã có tài khoản? ',
                          style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Đăng nhập',
                              style: TextStyle(
                                color: AppTheme.primaryCyan,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
          color: AppTheme.onSurface,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hintText, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppTheme.outline, fontSize: 13.5),
      filled: true,
      fillColor: AppTheme.surfaceContainerLowest,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.outlineVariant),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: AppTheme.primaryCyan, width: 1.5),
      ),
    );
  }
}
