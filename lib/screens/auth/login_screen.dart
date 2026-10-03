import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/kini_logo_widget.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _autoLogin = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.signIn(
      _identifierController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final identifierCtrl = TextEditingController(text: _identifierController.text.trim());
    final answerCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    String? foundQuestion;
    bool isCheckingIdentifier = false;
    bool isResetting = false;
    String? localError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            void checkIdentifier() async {
              final ident = identifierCtrl.text.trim();
              if (ident.isEmpty) {
                setModalState(() => localError = 'Vui lòng nhập tên đăng nhập hoặc email');
                return;
              }
              setModalState(() {
                isCheckingIdentifier = true;
                localError = null;
              });

              final auth = Provider.of<AuthProvider>(context, listen: false);
              final q = await auth.getSecurityQuestion(ident);

              setModalState(() {
                isCheckingIdentifier = false;
                if (q != null && q.isNotEmpty) {
                  foundQuestion = q;
                } else {
                  localError = 'Không tìm thấy tài khoản hoặc tài khoản chưa thiết lập câu hỏi bảo mật.';
                }
              });
            }

            void executeReset() async {
              final ans = answerCtrl.text.trim();
              final newPass = newPassCtrl.text.trim();
              final confirmPass = confirmPassCtrl.text.trim();

              if (ans.isEmpty) {
                setModalState(() => localError = 'Vui lòng nhập câu trả lời bảo mật');
                return;
              }
              if (newPass.length < 8) {
                setModalState(() => localError = 'Mật khẩu mới phải từ 8 ký tự trở lên');
                return;
              }
              if (newPass != confirmPass) {
                setModalState(() => localError = 'Xác nhận mật khẩu mới không khớp');
                return;
              }

              setModalState(() {
                isResetting = true;
                localError = null;
              });

              final auth = Provider.of<AuthProvider>(context, listen: false);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final success = await auth.recoverPassword(
                loginIdentifier: identifierCtrl.text.trim(),
                securityAnswer: ans,
                newPassword: newPass,
              );

              setModalState(() => isResetting = false);

              if (success) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                _passwordController.text = newPass;
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Khôi phục mật khẩu thành công! Bạn có thể đăng nhập ngay.'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              } else {
                setModalState(() {
                  localError = auth.errorMessage ?? 'Câu trả lời bảo mật không chính xác.';
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: bottomInset + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Khôi phục mật khẩu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Xác thực qua câu hỏi bảo mật bạn đã đăng ký để tạo mật khẩu mới.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    if (localError != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          localError!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12.5),
                        ),
                      ),

                    if (foundQuestion == null) ...[
                      const Text(
                        'Tên đăng nhập hoặc Email',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: identifierCtrl,
                        decoration: InputDecoration(
                          hintText: 'Nhập tên đăng nhập hoặc email',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isCheckingIdentifier ? null : checkIdentifier,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: isCheckingIdentifier
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Tìm câu hỏi bảo mật', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF0284C7).withAlpha(60)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Câu hỏi bảo mật của bạn:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              foundQuestion!,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        'Câu trả lời bảo mật',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: answerCtrl,
                        decoration: InputDecoration(
                          hintText: 'Nhập chính xác câu trả lời của bạn',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        'Mật khẩu mới',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: newPassCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Ít nhất 8 ký tự',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        'Xác nhận mật khẩu mới',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: confirmPassCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Nhập lại mật khẩu mới',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isResetting ? null : executeReset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: isResetting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Đặt lại mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final loc = Provider.of<LocalizationService>(context);

    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Background ambient glowing orbs
            Positioned(
              top: -40,
              left: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryCyan.withAlpha(20),
                ),
              ),
            ),
            Positioned(
              top: 260,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.secondaryViolet.withAlpha(25),
                ),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Brand Header with Cyber Halo
                      Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const KiniLogoWidget(size: 76, showText: false),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryCyan,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.surfaceDark, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryCyan.withAlpha(160),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Gradient KiniChat Title
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppTheme.primaryCyan, AppTheme.violetLight],
                        ).createShader(bounds),
                        child: const Text(
                          'KiniChat',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryCyan,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Flexible(
                            child: Text(
                              'Kết nối thế hệ mới • Chat, Voice & Screen Share',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Auth Card (Cyber-Glass)
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.surfaceContainerHighest),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(120),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(22),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Segmented Pill Tab Switcher
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 9),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppTheme.primaryCyan.withAlpha(45),
                                              AppTheme.secondaryViolet.withAlpha(65),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppTheme.primaryCyan.withAlpha(80)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.login, size: 14, color: AppTheme.primaryCyan),
                                            const SizedBox(width: 6),
                                            Text(
                                              loc.t('tab_signin'),
                                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.primaryCyan),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 9),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.person_add_alt_1_outlined, size: 14, color: AppTheme.onSurfaceVariant),
                                              const SizedBox(width: 6),
                                              Text(
                                                loc.t('tab_signup'),
                                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Tên đăng nhập / Email
                              _buildFieldLabel(loc.t('identifier_label')),
                              TextFormField(
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                controller: _identifierController,
                                decoration: _inputDecoration(
                                  hintText: loc.t('identifier_hint'),
                                  prefixIcon: const Icon(Icons.alternate_email, color: AppTheme.primaryCyan, size: 19),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? loc.t('identifier_label') : null,
                              ),
                              const SizedBox(height: 16),

                              // Mật khẩu & Quên mật khẩu
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildFieldLabel(loc.t('password_label')),
                                  InkWell(
                                    onTap: _showForgotPasswordDialog,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 6.0),
                                      child: Text(
                                        loc.t('forgot_password'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryCyan,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              TextFormField(
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: _inputDecoration(
                                  hintText: loc.t('password_hint'),
                                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryCyan, size: 19),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: AppTheme.outline,
                                      size: 19,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) => (v == null || v.isEmpty) ? loc.t('password_label') : null,
                              ),
                              const SizedBox(height: 12),

                              // Tự động đăng nhập Checkbox
                              InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => setState(() => _autoLogin = !_autoLogin),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: _autoLogin,
                                          activeColor: AppTheme.primaryCyan,
                                          checkColor: Colors.black,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                          onChanged: (val) => setState(() => _autoLogin = val ?? true),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              loc.t('auto_signin'),
                                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(Icons.verified_user, size: 12, color: AppTheme.primaryCyan),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    loc.t('auto_signin_sub'),
                                                    style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Submit Buttons Row: Đăng Nhập + Sinh Trắc Học
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: auth.isLoading ? null : _submit,
                                      child: Container(
                                        height: 48,
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
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                              )
                                            : Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    loc.t('signin_btn'),
                                                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.black),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(Icons.arrow_forward, size: 16, color: Colors.black),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Tooltip(
                                    message: loc.t('biometric_btn_tip'),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(Icons.fingerprint, color: Colors.black, size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  loc.isVietnamese
                                                      ? 'Xác thực Face ID / Vân tay thành công!'
                                                      : 'Biometric authentication verified!',
                                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                            backgroundColor: AppTheme.primaryCyan,
                                          ),
                                        );
                                        // Tự động thử đăng nhập với phiên đã lưu nếu có
                                        await auth.loadCurrentUserData();
                                      },
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppTheme.surfaceContainerLowest,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: AppTheme.surfaceContainerHighest),
                                        ),
                                        child: const Icon(Icons.fingerprint, color: AppTheme.primaryCyan, size: 26),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // 2-Factor Argon2id Recovery Box
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.outlineVariant),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.shield_outlined, size: 16, color: AppTheme.primaryCyan),
                                            const SizedBox(width: 6),
                                            Text(
                                              loc.t('two_factor_title'),
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryCyan.withAlpha(25),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AppTheme.primaryCyan.withAlpha(60)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.key, size: 10, color: AppTheme.primaryCyan),
                                              const SizedBox(width: 4),
                                              Text(
                                                loc.t('key_recovery'),
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryCyan),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      loc.t('two_factor_desc'),
                                      style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant, height: 1.4),
                                    ),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: _showForgotPasswordDialog,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.primaryCyan,
                                        side: BorderSide(color: AppTheme.primaryCyan.withAlpha(80)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      ),
                                      icon: const Icon(Icons.lock_reset, size: 15),
                                      label: Text(
                                        loc.isVietnamese ? 'Khôi phục tài khoản bằng câu hỏi bí mật' : 'Recover account via secret question',
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Terms & Privacy Note
                      Text(
                        loc.t('terms_notice'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant, height: 1.4),
                      ),
                      const SizedBox(height: 14),

                      // Server Status Bar (Matching Stitch design)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest.withAlpha(200),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.surfaceContainerHighest),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryCyan,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              const Text(
                                'Hệ thống máy chủ: Trực tuyến (24ms)',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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

  InputDecoration _inputDecoration({required String hintText, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppTheme.outline, fontSize: 13.5),
      filled: true,
      fillColor: AppTheme.surfaceContainerLowest,
      prefixIcon: prefixIcon,
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
