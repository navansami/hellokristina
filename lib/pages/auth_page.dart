part of '../main.dart';

enum _AuthView { welcome, signUp, logIn, forgot, forgotSent, reset, resetDone }

/// The front door: nobody gets into the app without an account. Welcome,
/// sign up, log in, forgot password and the reset-link landing all live here.
class AuthPage extends StatefulWidget {
  final AuthApi api;
  final Future<void> Function(AuthSession session) onSession;
  final String? resetToken;

  /// Called once a reset link is used up; true when the password changed.
  final void Function(bool passwordChanged)? onResetHandled;
  final String? notice;
  const AuthPage(
      {super.key,
      required this.api,
      required this.onSession,
      this.resetToken,
      this.onResetHandled,
      this.notice});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late _AuthView view =
      widget.resetToken != null ? _AuthView.reset : _AuthView.welcome;
  final name = TextEditingController(),
      username = TextEditingController(),
      email = TextEditingController(),
      identifier = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  bool remember = true, terms = false, busy = false, tried = false;
  bool showPassword = false;
  String? error;
  Map<String, String> serverErrors = {};
  late String? notice = widget.notice;

  // Live username check.
  Timer? _usernameTimer;
  String? _checkedUsername, _usernameProblem;
  bool _checkingUsername = false;

  @override
  void dispose() {
    _usernameTimer?.cancel();
    for (final c in [name, username, email, identifier, password, confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void go(_AuthView next) {
    learningFeedback.touch();
    setState(() {
      view = next;
      error = null;
      notice = null;
      tried = false;
      busy = false;
      serverErrors = {};
      password.clear();
      confirm.clear();
      showPassword = false;
    });
  }

  void _onUsernameChanged(String value) {
    _usernameTimer?.cancel();
    serverErrors.remove('username');
    final normalized = normalizeUsername(value);
    if (usernameError(normalized) != null) {
      setState(() {
        _checkingUsername = false;
        _checkedUsername = null;
      });
      return;
    }
    setState(() => _checkingUsername = true);
    _usernameTimer = Timer(const Duration(milliseconds: 450), () async {
      String? problem;
      try {
        problem = await widget.api.usernameProblem(normalized);
      } on AuthError {
        problem = null; // Offline: the server checks again on submit.
      }
      if (!mounted || normalizeUsername(username.text) != normalized) return;
      setState(() {
        _checkingUsername = false;
        _checkedUsername = normalized;
        _usernameProblem = problem;
      });
    });
  }

  String? _fieldError(String field, String? local) {
    if (serverErrors[field] != null) return serverErrors[field];
    return tried ? local : null;
  }

  String? get _usernameError {
    final local = usernameError(username.text);
    if (local != null) return _fieldError('username', local);
    if (serverErrors['username'] != null) return serverErrors['username'];
    if (_checkedUsername == normalizeUsername(username.text)) {
      return _usernameProblem;
    }
    return null;
  }

  String? get _confirmError =>
      confirm.text == password.text ? null : 'Passwords don’t match';

  Future<void> _run(Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
      serverErrors = {};
    });
    try {
      await action();
    } on AuthError catch (e) {
      if (!mounted) return;
      learningFeedback.answer(false, 0);
      setState(() {
        if (e.field != null && e.field != 'terms') {
          serverErrors = {e.field!: e.message};
        } else {
          error = e.message;
        }
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _signUp() async {
    setState(() => tried = true);
    final problems = [
      nameError(name.text),
      _usernameError,
      emailError(email.text),
      passwordError(password.text),
      _confirmError,
    ];
    if (problems.any((p) => p != null) || !terms) {
      learningFeedback.answer(false, 0);
      return;
    }
    await _run(() async {
      final session = await widget.api.signUp(
          name: name.text,
          username: normalizeUsername(username.text),
          email: email.text,
          password: password.text,
          remember: remember);
      TextInput.finishAutofillContext();
      await widget.onSession(session);
    });
  }

  Future<void> _logIn() async {
    setState(() => tried = true);
    if (identifier.text.trim().isEmpty || password.text.isEmpty) {
      learningFeedback.answer(false, 0);
      return;
    }
    await _run(() async {
      final session = await widget.api.logIn(
          identifier: identifier.text,
          password: password.text,
          remember: remember);
      TextInput.finishAutofillContext();
      await widget.onSession(session);
    });
  }

  Future<void> _forgot() async {
    setState(() => tried = true);
    if (emailError(email.text) != null) return;
    await _run(() async {
      await widget.api.forgotPassword(email.text);
      if (mounted) setState(() => view = _AuthView.forgotSent);
    });
  }

  Future<void> _reset() async {
    setState(() => tried = true);
    if (passwordError(password.text) != null || _confirmError != null) return;
    await _run(() async {
      await widget.api.resetPassword(widget.resetToken ?? '', password.text);
      widget.onResetHandled?.call(true);
      if (mounted) setState(() => view = _AuthView.resetDone);
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: view == _AuthView.welcome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) go(_AuthView.welcome);
      },
      child: Scaffold(
          backgroundColor: bg,
          body: SafeArea(
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                      position: Tween(
                                              begin: const Offset(.06, 0),
                                              end: Offset.zero)
                                          .animate(animation),
                                      child: child)),
                          child: KeyedSubtree(
                              key: ValueKey(view), child: _body())))))));

  Widget _body() => switch (view) {
        _AuthView.welcome => _welcome(),
        _AuthView.signUp => _signUpForm(),
        _AuthView.logIn => _logInForm(),
        _AuthView.forgot => _forgotForm(),
        _AuthView.forgotSent => _message(
            emoji: '📬',
            title: 'Check your inbox',
            body: 'If there’s an account for ${email.text.trim()}, we’ve sent '
                'a link to choose a new password. It works for 1 hour. '
                'Check your spam folder if it doesn’t arrive.',
            button: 'BACK TO LOG IN',
            onTap: () => go(_AuthView.logIn)),
        _AuthView.reset => _resetForm(),
        _AuthView.resetDone => _message(
            emoji: '🔐',
            title: 'Password changed',
            body: 'You’re all set. Log in with your new password.',
            button: 'LOG IN',
            onTap: () => go(_AuthView.logIn)),
      };

  Widget _welcome() => LayoutBuilder(
      builder: (context, box) => ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                SizedBox(
                    height: math.min(360, box.maxHeight * .48),
                    child: Stack(alignment: Alignment.center, children: [
                      Positioned.fill(
                          child: DecoratedBox(
                              decoration: BoxDecoration(
                                  gradient: unitTheme(0).gradient,
                                  borderRadius: BorderRadius.circular(36)))),
                      Positioned(
                          right: -30,
                          top: -30,
                          child: _HeroBubble(size: 160, opacity: .14)),
                      Positioned(
                          left: -20,
                          bottom: -40,
                          child: _HeroBubble(size: 120, opacity: .1)),
                      Positioned(
                          bottom: 0,
                          child: AnimatedKristina(
                              width: 210,
                              height: math.min(330, box.maxHeight * .44),
                              mood: 'celebrate',
                              gaze: Offset.zero)),
                    ])),
                const SizedBox(height: 22),
                Text('Hello Kristina',
                    textAlign: TextAlign.center,
                    style: display(40, color: orange, weight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text(
                    'Learn Serbian with Kristina, Miloš and Zara. '
                    'Bite-sized lessons, real voices and friends to cheer you on.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: muted, fontSize: 15.5, height: 1.4)),
                if (notice != null) ...[
                  const SizedBox(height: 14),
                  _Banner(text: notice!, color: blue),
                ],
                const SizedBox(height: 26),
                KButton(text: 'GET STARTED', onTap: () => go(_AuthView.signUp)),
                const SizedBox(height: 12),
                KButton(
                    text: 'I ALREADY HAVE AN ACCOUNT',
                    outline: true,
                    onTap: () => go(_AuthView.logIn)),
              ]));

  Widget _header(String title, String subtitle,
          {_AuthView back = _AuthView.welcome}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconButton(
                tooltip: 'Back',
                onPressed: () => go(back),
                style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: panel2, width: 2)),
                icon: const Icon(Icons.arrow_back_rounded, color: ink)),
            const SizedBox(height: 14),
            Text(title, style: display(32, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle,
                style:
                    const TextStyle(color: muted, fontSize: 15, height: 1.35)),
          ]));

  Widget _form(List<Widget> children) => AutofillGroup(
      child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
          children: children));

  Widget _signUpForm() => _form([
        _header(
            'Create your account',
            'Takes a minute. Your progress, '
                'streak and friends are saved to it.'),
        _AuthField(
            controller: name,
            label: 'Your name',
            icon: Icons.badge_rounded,
            autofill: const [AutofillHints.name],
            capitalization: TextCapitalization.words,
            error: _fieldError('name', nameError(name.text)),
            onChanged: (_) => setState(() => serverErrors.remove('name'))),
        _AuthField(
            controller: username,
            label: 'Username',
            hint: 'Friends find you by this',
            icon: Icons.alternate_email_rounded,
            autofill: const [AutofillHints.newUsername],
            error: _usernameError,
            suffix: _usernameStatus(),
            onChanged: (value) {
              _onUsernameChanged(value);
              setState(() {});
            }),
        _AuthField(
            controller: email,
            label: 'Email',
            icon: Icons.mail_rounded,
            keyboard: TextInputType.emailAddress,
            autofill: const [AutofillHints.email],
            error: _fieldError('email', emailError(email.text)),
            onChanged: (_) => setState(() => serverErrors.remove('email'))),
        _passwordField('Password', [AutofillHints.newPassword]),
        _PasswordChecklist(password: password.text),
        const SizedBox(height: 10),
        _AuthField(
            controller: confirm,
            label: 'Confirm password',
            icon: Icons.lock_rounded,
            obscure: !showPassword,
            autofill: const [AutofillHints.newPassword],
            error: tried ? _confirmError : null,
            onChanged: (_) => setState(() {})),
        _rememberBox(),
        _Tick(
            value: terms,
            onChanged: (v) => setState(() => terms = v),
            error: tried && !terms ? 'Please accept to continue' : null,
            child: Text.rich(TextSpan(
                style: const TextStyle(fontSize: 14, color: ink),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: GestureDetector(
                          onTap: () => showTermsSheet(context),
                          child: const Text('terms and privacy notice',
                              style: TextStyle(
                                  color: blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  decoration: TextDecoration.underline)))),
                ]))),
        if (error != null) _Banner(text: error!, color: red),
        const SizedBox(height: 14),
        KButton(
            text: busy ? 'ONE MOMENT…' : 'CREATE ACCOUNT',
            color: correctGreen,
            onTap: busy ? null : _signUp),
        const SizedBox(height: 10),
        _SwitchLink(
            text: 'Already have an account?',
            action: 'Log in',
            onTap: () => go(_AuthView.logIn)),
      ]);

  Widget _logInForm() => _form([
        _header('Welcome back!', 'Kristina missed you. A little.'),
        if (notice != null) _Banner(text: notice!, color: blue),
        _AuthField(
            controller: identifier,
            label: 'Email or username',
            icon: Icons.person_rounded,
            keyboard: TextInputType.emailAddress,
            autofill: const [AutofillHints.username, AutofillHints.email],
            error: tried && identifier.text.trim().isEmpty
                ? 'Enter your email or username'
                : null,
            onChanged: (_) => setState(() {})),
        _passwordField('Password', [AutofillHints.password],
            onSubmit: _logIn,
            error:
                tried && password.text.isEmpty ? 'Enter your password' : null),
        Row(children: [
          Expanded(child: _rememberBox()),
          TextButton(
              onPressed: () => go(_AuthView.forgot),
              child: const Text('Forgot password?',
                  style: TextStyle(color: blue, fontWeight: FontWeight.w800))),
        ]),
        if (error != null) _Banner(text: error!, color: red),
        const SizedBox(height: 14),
        KButton(
            text: busy ? 'ONE MOMENT…' : 'LOG IN', onTap: busy ? null : _logIn),
        const SizedBox(height: 10),
        _SwitchLink(
            text: 'New here?',
            action: 'Create an account',
            onTap: () => go(_AuthView.signUp)),
      ]);

  Widget _forgotForm() => _form([
        _header('Forgot your password?',
            'Enter your account’s email and we’ll send you a link to choose a new one.',
            back: _AuthView.logIn),
        _AuthField(
            controller: email,
            label: 'Email',
            icon: Icons.mail_rounded,
            keyboard: TextInputType.emailAddress,
            autofill: const [AutofillHints.email],
            error: _fieldError('email', emailError(email.text)),
            onSubmit: _forgot,
            onChanged: (_) => setState(() => serverErrors.remove('email'))),
        if (error != null) _Banner(text: error!, color: red),
        const SizedBox(height: 14),
        KButton(
            text: busy ? 'SENDING…' : 'SEND RESET LINK',
            onTap: busy ? null : _forgot),
      ]);

  Widget _resetForm() => _form([
        _header('Choose a new password',
            'Pick something you don’t use anywhere else.'),
        _passwordField('New password', [AutofillHints.newPassword]),
        _PasswordChecklist(password: password.text),
        const SizedBox(height: 10),
        _AuthField(
            controller: confirm,
            label: 'Confirm new password',
            icon: Icons.lock_rounded,
            obscure: !showPassword,
            autofill: const [AutofillHints.newPassword],
            error: tried ? _confirmError : null,
            onSubmit: _reset,
            onChanged: (_) => setState(() {})),
        if (error != null) _Banner(text: error!, color: red),
        const SizedBox(height: 14),
        KButton(
            text: busy ? 'SAVING…' : 'SAVE NEW PASSWORD',
            color: correctGreen,
            onTap: busy ? null : _reset),
        const SizedBox(height: 10),
        _SwitchLink(
            text: 'Link not working?',
            action: 'Send a new one',
            onTap: () {
              widget.onResetHandled?.call(false);
              go(_AuthView.forgot);
            }),
      ]);

  Widget _message(
          {required String emoji,
          required String title,
          required String body,
          required String button,
          required VoidCallback onTap}) =>
      ListView(padding: const EdgeInsets.fromLTRB(26, 60, 26, 28), children: [
        Text(emoji,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 72)),
        const SizedBox(height: 12),
        Text(title,
            textAlign: TextAlign.center,
            style: display(30, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 15, height: 1.4)),
        const SizedBox(height: 28),
        KButton(text: button, onTap: onTap),
      ]);

  Widget _passwordField(String label, List<String> autofill,
          {VoidCallback? onSubmit, String? error}) =>
      _AuthField(
          controller: password,
          label: label,
          icon: Icons.lock_rounded,
          obscure: !showPassword,
          autofill: autofill,
          error: error ?? serverErrors['password'],
          onSubmit: onSubmit,
          suffix: IconButton(
              tooltip: showPassword ? 'Hide password' : 'Show password',
              onPressed: () => setState(() => showPassword = !showPassword),
              icon: Icon(
                  showPassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: muted)),
          onChanged: (_) => setState(() => serverErrors.remove('password')));

  Widget? _usernameStatus() {
    if (usernameError(username.text) != null) return null;
    if (_checkingUsername) {
      return const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.5)));
    }
    if (_checkedUsername == normalizeUsername(username.text)) {
      return _usernameProblem == null && serverErrors['username'] == null
          ? const Tooltip(
              message: 'Available',
              child: Icon(Icons.check_circle_rounded, color: correctGreen))
          : const Icon(Icons.cancel_rounded, color: red);
    }
    return null;
  }

  Widget _rememberBox() => _Tick(
      value: remember,
      onChanged: (v) => setState(() => remember = v),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Remember me',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        Text(
            remember
                ? 'Stay signed in on this device for 30 days'
                : 'Sign out when the app or tab is closed',
            style: const TextStyle(color: muted, fontSize: 12)),
      ]));
}

class _AuthField extends StatelessWidget {
  const _AuthField(
      {required this.controller,
      required this.label,
      required this.icon,
      this.hint,
      this.error,
      this.suffix,
      this.obscure = false,
      this.keyboard,
      this.autofill = const [],
      this.capitalization = TextCapitalization.none,
      this.onChanged,
      this.onSubmit});
  final TextEditingController controller;
  final String label;
  final String? hint, error;
  final IconData icon;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? keyboard;
  final List<String> autofill;
  final TextCapitalization capitalization;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: 2));
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboard,
            autofillHints: autofill,
            textCapitalization: capitalization,
            autocorrect: false,
            enableSuggestions: !obscure,
            onChanged: onChanged,
            onSubmitted: onSubmit == null ? null : (_) => onSubmit!(),
            textInputAction:
                onSubmit == null ? TextInputAction.next : TextInputAction.done,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                errorText: error,
                errorMaxLines: 3,
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(icon, color: muted),
                suffixIcon: suffix,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                enabledBorder: border(panel2),
                focusedBorder: border(purple),
                errorBorder: border(red),
                focusedErrorBorder: border(red))));
  }
}

/// A rounded tick box with a label and an optional error.
class _Tick extends StatelessWidget {
  const _Tick(
      {required this.value,
      required this.onChanged,
      required this.child,
      this.error});
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget child;
  final String? error;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              learningFeedback.tap(sound: false);
              onChanged(!value);
            },
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                          color: value ? correctGreen : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: error != null
                                  ? red
                                  : value
                                      ? correctGreen
                                      : const Color(0xFFC9C3D8),
                              width: 2)),
                      child: value
                          ? const Icon(Icons.check_rounded,
                              size: 18, color: Colors.white)
                          : null),
                  const SizedBox(width: 12),
                  Expanded(child: child),
                ]))),
        if (error != null)
          Padding(
              padding: const EdgeInsets.only(left: 38),
              child: Text(error!,
                  style: const TextStyle(color: red, fontSize: 12))),
      ]));
}

/// Live hints under a new password: they turn green as each rule is met.
class _PasswordChecklist extends StatelessWidget {
  const _PasswordChecklist({required this.password});
  final String password;
  @override
  Widget build(BuildContext context) {
    final rules = [
      ('8+ characters', password.length >= 8),
      ('a letter', RegExp(r'[A-Za-z]').hasMatch(password)),
      ('a number', RegExp(r'[0-9]').hasMatch(password)),
    ];
    return Wrap(spacing: 8, runSpacing: 6, children: [
      for (final (label, ok) in rules)
        AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
            decoration: BoxDecoration(
                color: ok ? mint : panel2.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(ok ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 16, color: ok ? correctGreen : muted),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: ok ? green : muted)),
            ])),
    ]);
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: .3), width: 1.5)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(color == red ? Icons.error_rounded : Icons.info_rounded,
            color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, height: 1.3))),
      ]));
}

class _SwitchLink extends StatelessWidget {
  const _SwitchLink(
      {required this.text, required this.action, required this.onTap});
  final String text, action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(text, style: const TextStyle(color: muted)),
            TextButton(
                onPressed: onTap,
                child: Text(action,
                    style: const TextStyle(
                        color: blue, fontWeight: FontWeight.w900))),
          ]);
}

/// A plain-language summary of what the app keeps and shows.
Future<void> showTermsSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: bg,
    showDragHandle: true,
    builder: (context) => SafeArea(
        child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .8),
            child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  Text('Terms and privacy', style: display(26)),
                  const SizedBox(height: 12),
                  for (final (title, body) in const [
                    (
                      'What we keep',
                      'Your name, username, email, a securely hashed version '
                          'of your password (never the password itself), your '
                          'lesson progress, XP, streak and avatar.'
                    ),
                    (
                      'Who sees what',
                      'Friends you add see your name, username, avatar, XP and '
                          'the lessons you finish. Your email stays private.'
                    ),
                    (
                      'Your email',
                      'Used for your account only, for example to send a '
                          'password-reset link when you ask for one.'
                    ),
                    (
                      'Audio and content',
                      'Pronunciation audio is AI-generated. Lessons are '
                          'reviewed, but mistakes can slip through.'
                    ),
                    (
                      'Be kind',
                      'Friends and the feed are for cheering each other on.'
                    ),
                  ]) ...[
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(body,
                        style: const TextStyle(
                            color: muted, height: 1.4, fontSize: 14)),
                    const SizedBox(height: 14),
                  ],
                ]))));
