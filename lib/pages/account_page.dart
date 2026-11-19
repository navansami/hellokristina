part of '../main.dart';

/// Account settings: profile details, login and security, learning
/// preferences, signing out and deleting the account.
class AccountPage extends StatefulWidget {
  final AuthApi api;
  final String token;
  final Map<String, dynamic> user;
  final bool remembered;
  final DailyLog daily;
  final int streak;
  final LearnerLook look;
  final Future<void> Function(int goal) onGoal;
  final Future<LearnerLook> Function() onEditLook;
  final void Function(Map<String, dynamic> user) onUser;
  final Future<void> Function(AuthSession session) onSession;
  final Future<void> Function() onSignOut;
  final Future<void> Function() onDeleted;
  const AccountPage(
      {super.key,
      required this.api,
      required this.token,
      required this.user,
      required this.remembered,
      required this.daily,
      required this.streak,
      required this.look,
      required this.onGoal,
      required this.onEditLook,
      required this.onUser,
      required this.onSession,
      required this.onSignOut,
      required this.onDeleted});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late Map<String, dynamic> user = widget.user;
  late String token = widget.token;
  late LearnerLook look = widget.look;
  late DailyLog daily = widget.daily;

  String get _name => (user['name'] ?? '').toString();
  String get _username => (user['username'] ?? '').toString();
  String get _email => (user['email'] ?? '').toString();

  void _toast(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
        content:
            Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))));

  Future<T?> _sheet<T>(Widget child) {
    learningFeedback.touch();
    return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: bg,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (context) => Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: SafeArea(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                    child: child))));
  }

  Future<void> _editDetails() async {
    final updated = await _sheet<Map<String, dynamic>>(_DetailsSheet(
        api: widget.api, token: token, name: _name, username: _username));
    if (updated == null || !mounted) return;
    setState(() => user = updated);
    widget.onUser(updated);
    _toast('Profile updated');
  }

  Future<void> _editEmail() async {
    final updated = await _sheet<Map<String, dynamic>>(
        _EmailSheet(api: widget.api, token: token, email: _email));
    if (updated == null || !mounted) return;
    setState(() => user = updated);
    widget.onUser(updated);
    _toast('Email updated');
  }

  Future<void> _changePassword() async {
    final session = await _sheet<AuthSession>(_PasswordSheet(
        api: widget.api, token: token, remember: widget.remembered));
    if (session == null || !mounted) return;
    token = session.token;
    await widget.onSession(session);
    _toast('Password changed. Other devices were signed out.');
  }

  Future<void> _signOutEverywhere() async {
    final go = await confirmSheet(context,
        emoji: '🛡️',
        title: 'Sign out other devices?',
        body: 'Every other phone, tablet or browser signed in to your '
            'account will be signed out. You’ll stay signed in here.',
        stay: 'CANCEL',
        leave: 'SIGN OUT OTHER DEVICES');
    if (!go) return;
    try {
      final session = await widget.api
          .signOutEverywhere(token, remember: widget.remembered);
      token = session.token;
      await widget.onSession(session);
      if (mounted) _toast('Other devices were signed out');
    } on AuthError catch (e) {
      if (mounted) _toast(e.message);
    }
  }

  Future<void> _signOut() async {
    final out = await confirmSheet(context,
        emoji: '👋',
        title: 'Sign out?',
        body: 'Your progress is saved to your account. This device will '
            'forget it until you sign in again.',
        stay: 'STAY SIGNED IN',
        leave: 'SIGN OUT');
    if (!out || !mounted) return;
    Navigator.of(context).pop();
    await widget.onSignOut();
  }

  Future<void> _delete() async {
    final deleted =
        await _sheet<bool>(_DeleteSheet(api: widget.api, token: token));
    if (deleted != true || !mounted) return;
    Navigator.of(context).pop();
    await widget.onDeleted();
  }

  Future<void> _goal() async {
    await showStreakSheet(context, streak: widget.streak, log: daily,
        onGoal: (goal) async {
      if (mounted) setState(() => daily = daily.withGoal(goal));
      await widget.onGoal(goal);
    });
  }

  @override
  Widget build(BuildContext context) {
    final goalName = dailyGoalOptions
        .firstWhere((option) => option.$1 == daily.goal,
            orElse: () => (daily.goal, 'Custom'))
        .$2;
    return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                        children: [
                          Row(children: [
                            IconButton(
                                tooltip: 'Back',
                                onPressed: () => Navigator.maybePop(context),
                                icon: const Icon(Icons.arrow_back_rounded)),
                            const SizedBox(width: 4),
                            Text('Account settings', style: display(26)),
                          ]),
                          const SizedBox(height: 12),
                          _Slab(
                              child: Row(children: [
                            LearnerBadge(look: look, size: 64, radius: 32),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(_name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          display(22, weight: FontWeight.w700)),
                                  Text('@$_username',
                                      style: const TextStyle(
                                          color: muted,
                                          fontWeight: FontWeight.w800)),
                                ])),
                            TextButton.icon(
                                onPressed: () async {
                                  final updated = await widget.onEditLook();
                                  if (mounted) setState(() => look = updated);
                                },
                                icon: const Icon(Icons.brush_rounded, size: 18),
                                label: const Text('Look',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900))),
                          ])),
                          const SizedBox(height: 20),
                          const _SectionLabel('Profile'),
                          _SettingsGroup(children: [
                            _SettingsRow(
                                icon: Icons.badge_rounded,
                                color: orange,
                                label: 'Name',
                                value: _name,
                                onTap: _editDetails),
                            _SettingsRow(
                                icon: Icons.alternate_email_rounded,
                                color: purple,
                                label: 'Username',
                                value: '@$_username',
                                onTap: _editDetails),
                          ]),
                          const SizedBox(height: 20),
                          const _SectionLabel('Login and security'),
                          _SettingsGroup(children: [
                            _SettingsRow(
                                icon: Icons.mail_rounded,
                                color: blue,
                                label: 'Email',
                                value: _email,
                                onTap: _editEmail),
                            _SettingsRow(
                                icon: Icons.lock_rounded,
                                color: teal,
                                label: 'Password',
                                value: 'Change your password',
                                onTap: _changePassword),
                            _SettingsRow(
                                icon: Icons.devices_rounded,
                                color: pink,
                                label: 'Signed-in devices',
                                value: widget.remembered
                                    ? 'Here: remembered for 30 days'
                                    : 'Here: until you close the app',
                                action: 'Sign out others',
                                onTap: _signOutEverywhere),
                          ]),
                          const SizedBox(height: 20),
                          const _SectionLabel('Learning'),
                          _SettingsGroup(children: [
                            _SettingsRow(
                                icon: Icons.track_changes_rounded,
                                color: correctGreen,
                                label: 'Daily goal',
                                value: '$goalName · ${daily.goal} XP a day',
                                onTap: _goal),
                            const Padding(
                                padding: EdgeInsets.fromLTRB(16, 4, 12, 4),
                                child: FeedbackSettingsPanel()),
                          ]),
                          const SizedBox(height: 24),
                          KButton(
                              text: 'SIGN OUT', outline: true, onTap: _signOut),
                          const SizedBox(height: 28),
                          const _SectionLabel('Danger zone', color: red),
                          _Chunky(
                              fill: blush,
                              edge: const Color(0xFFF4B7BF),
                              radius: 20,
                              onTap: _delete,
                              child: const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Row(children: [
                                    Icon(Icons.delete_forever_rounded,
                                        color: red, size: 28),
                                    SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text('Delete account',
                                              style: TextStyle(
                                                  color: red,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 16)),
                                          Text(
                                              'Permanently remove your account and progress',
                                              style: TextStyle(
                                                  color: muted, fontSize: 13)),
                                        ])),
                                    Icon(Icons.chevron_right_rounded,
                                        color: red),
                                  ]))),
                        ])))));
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => _Slab(
      padding: EdgeInsets.zero,
      // A see-through Material so row splashes and switches paint above the
      // card's colour.
      child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, thickness: 1.5, color: panel2),
              children[i],
            ]
          ])));
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value,
      required this.onTap,
      this.action});
  final IconData icon;
  final Color color;
  final String label, value;
  final String? action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(children: [
            Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 21)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 15)),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: muted, fontSize: 13)),
                ])),
            if (action != null)
              Text(action!,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w900, fontSize: 13))
            else
              const Icon(Icons.chevron_right_rounded, color: muted),
          ])));
}

/// Shared layout for the edit sheets: title, fields, error and a button.
class _SheetForm extends StatelessWidget {
  const _SheetForm(
      {required this.title,
      required this.subtitle,
      required this.fields,
      required this.button,
      required this.busy,
      required this.onSave,
      this.error,
      this.danger = false});
  final String title, subtitle, button;
  final List<Widget> fields;
  final bool busy, danger;
  final String? error;
  final VoidCallback? onSave;
  @override
  Widget build(BuildContext context) => AutofillGroup(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Text(title,
                style: display(26,
                    weight: FontWeight.w700, color: danger ? red : ink)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: muted, height: 1.35)),
            const SizedBox(height: 16),
            ...fields,
            if (error != null) _Banner(text: error!, color: red),
            const SizedBox(height: 14),
            KButton(
                text: busy ? 'ONE MOMENT…' : button,
                color: danger ? red : correctGreen,
                onTap: busy ? null : onSave),
          ]));
}

class _DetailsSheet extends StatefulWidget {
  const _DetailsSheet(
      {required this.api,
      required this.token,
      required this.name,
      required this.username});
  final AuthApi api;
  final String token, name, username;
  @override
  State<_DetailsSheet> createState() => _DetailsSheetState();
}

class _DetailsSheetState extends State<_DetailsSheet> {
  late final name = TextEditingController(text: widget.name),
      username = TextEditingController(text: widget.username);
  bool busy = false;
  String? error;
  Map<String, String> fieldErrors = {};

  @override
  void dispose() {
    name.dispose();
    username.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final local = {
      if (nameError(name.text) != null) 'name': nameError(name.text)!,
      if (usernameError(username.text) != null)
        'username': usernameError(username.text)!,
    };
    if (local.isNotEmpty) return setState(() => fieldErrors = local);
    setState(() {
      busy = true;
      error = null;
      fieldErrors = {};
    });
    try {
      final user = await widget.api.updateDetails(widget.token,
          name: name.text, username: normalizeUsername(username.text));
      if (mounted) Navigator.pop(context, user);
    } on AuthError catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        if (e.field != null) {
          fieldErrors = {e.field!: e.message};
        } else {
          error = e.message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => _SheetForm(
          title: 'Edit profile',
          subtitle: 'Friends see your name and find you by your username.',
          busy: busy,
          error: error,
          button: 'SAVE',
          onSave: _save,
          fields: [
            _AuthField(
                controller: name,
                label: 'Your name',
                icon: Icons.badge_rounded,
                capitalization: TextCapitalization.words,
                autofill: const [AutofillHints.name],
                error: fieldErrors['name'],
                onChanged: (_) => setState(() => fieldErrors.remove('name'))),
            _AuthField(
                controller: username,
                label: 'Username',
                icon: Icons.alternate_email_rounded,
                error: fieldErrors['username'],
                onSubmit: _save,
                onChanged: (_) =>
                    setState(() => fieldErrors.remove('username'))),
          ]);
}

class _EmailSheet extends StatefulWidget {
  const _EmailSheet(
      {required this.api, required this.token, required this.email});
  final AuthApi api;
  final String token, email;
  @override
  State<_EmailSheet> createState() => _EmailSheetState();
}

class _EmailSheetState extends State<_EmailSheet> {
  late final email = TextEditingController(text: widget.email);
  final password = TextEditingController();
  bool busy = false, show = false;
  String? error;
  Map<String, String> fieldErrors = {};

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final local = {
      if (emailError(email.text) != null) 'email': emailError(email.text)!,
      if (password.text.isEmpty) 'currentPassword': 'Enter your password',
    };
    if (local.isNotEmpty) return setState(() => fieldErrors = local);
    setState(() {
      busy = true;
      error = null;
      fieldErrors = {};
    });
    try {
      final user =
          await widget.api.updateEmail(widget.token, email.text, password.text);
      if (mounted) Navigator.pop(context, user);
    } on AuthError catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        if (e.field != null) {
          fieldErrors = {e.field!: e.message};
        } else {
          error = e.message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => _SheetForm(
          title: 'Change email',
          subtitle: 'You’ll log in and get password-reset links here.',
          busy: busy,
          error: error,
          button: 'SAVE EMAIL',
          onSave: _save,
          fields: [
            _AuthField(
                controller: email,
                label: 'New email',
                icon: Icons.mail_rounded,
                keyboard: TextInputType.emailAddress,
                autofill: const [AutofillHints.email],
                error: fieldErrors['email'],
                onChanged: (_) => setState(() => fieldErrors.remove('email'))),
            _AuthField(
                controller: password,
                label: 'Current password',
                icon: Icons.lock_rounded,
                obscure: !show,
                autofill: const [AutofillHints.password],
                error: fieldErrors['currentPassword'],
                onSubmit: _save,
                suffix: _ShowPassword(
                    shown: show, onTap: () => setState(() => show = !show)),
                onChanged: (_) =>
                    setState(() => fieldErrors.remove('currentPassword'))),
          ]);
}

class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet(
      {required this.api, required this.token, required this.remember});
  final AuthApi api;
  final String token;
  final bool remember;
  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final current = TextEditingController(),
      next = TextEditingController(),
      confirm = TextEditingController();
  bool busy = false, show = false;
  String? error;
  Map<String, String> fieldErrors = {};

  @override
  void dispose() {
    current.dispose();
    next.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final local = {
      if (current.text.isEmpty)
        'currentPassword': 'Enter your current password',
      if (passwordError(next.text) != null)
        'newPassword': passwordError(next.text)!,
      if (confirm.text != next.text) 'confirm': 'Passwords don’t match',
    };
    if (local.isNotEmpty) return setState(() => fieldErrors = local);
    setState(() {
      busy = true;
      error = null;
      fieldErrors = {};
    });
    try {
      final session = await widget.api.changePassword(widget.token,
          current: current.text, next: next.text, remember: widget.remember);
      TextInput.finishAutofillContext();
      if (mounted) Navigator.pop(context, session);
    } on AuthError catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        if (e.field != null) {
          fieldErrors = {e.field!: e.message};
        } else {
          error = e.message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => _SheetForm(
          title: 'Change password',
          subtitle: 'For safety, other devices will be signed out.',
          busy: busy,
          error: error,
          button: 'CHANGE PASSWORD',
          onSave: _save,
          fields: [
            _AuthField(
                controller: current,
                label: 'Current password',
                icon: Icons.lock_open_rounded,
                obscure: !show,
                autofill: const [AutofillHints.password],
                error: fieldErrors['currentPassword'],
                suffix: _ShowPassword(
                    shown: show, onTap: () => setState(() => show = !show)),
                onChanged: (_) =>
                    setState(() => fieldErrors.remove('currentPassword'))),
            _AuthField(
                controller: next,
                label: 'New password',
                icon: Icons.lock_rounded,
                obscure: !show,
                autofill: const [AutofillHints.newPassword],
                error: fieldErrors['newPassword'],
                onChanged: (_) =>
                    setState(() => fieldErrors.remove('newPassword'))),
            _PasswordChecklist(password: next.text),
            const SizedBox(height: 10),
            _AuthField(
                controller: confirm,
                label: 'Confirm new password',
                icon: Icons.lock_rounded,
                obscure: !show,
                autofill: const [AutofillHints.newPassword],
                error: fieldErrors['confirm'],
                onSubmit: _save,
                onChanged: (_) =>
                    setState(() => fieldErrors.remove('confirm'))),
          ]);
}

class _DeleteSheet extends StatefulWidget {
  const _DeleteSheet({required this.api, required this.token});
  final AuthApi api;
  final String token;
  @override
  State<_DeleteSheet> createState() => _DeleteSheetState();
}

class _DeleteSheetState extends State<_DeleteSheet> {
  final password = TextEditingController();
  bool busy = false, understood = false, show = false;
  String? error, passwordProblem;

  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (password.text.isEmpty) {
      return setState(() => passwordProblem = 'Enter your password');
    }
    setState(() {
      busy = true;
      error = null;
      passwordProblem = null;
    });
    try {
      await widget.api.deleteAccount(widget.token, password.text);
      if (mounted) Navigator.pop(context, true);
    } on AuthError catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        if (e.field == 'currentPassword') {
          passwordProblem = e.message;
        } else {
          error = e.message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => _SheetForm(
          title: 'Delete your account?',
          subtitle: 'This permanently deletes your account, progress, XP, '
              'streak, friends and feed posts. It can’t be undone.',
          danger: true,
          busy: busy,
          error: error,
          button: 'DELETE MY ACCOUNT',
          onSave: understood ? _delete : null,
          fields: [
            _AuthField(
                controller: password,
                label: 'Your password',
                icon: Icons.lock_rounded,
                obscure: !show,
                autofill: const [AutofillHints.password],
                error: passwordProblem,
                suffix: _ShowPassword(
                    shown: show, onTap: () => setState(() => show = !show)),
                onChanged: (_) => setState(() => passwordProblem = null)),
            _Tick(
                value: understood,
                onChanged: (v) => setState(() => understood = v),
                child: const Text('I understand this can’t be undone',
                    style: TextStyle(fontWeight: FontWeight.w800))),
          ]);
}

class _ShowPassword extends StatelessWidget {
  const _ShowPassword({required this.shown, required this.onTap});
  final bool shown;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton(
      tooltip: shown ? 'Hide password' : 'Show password',
      onPressed: onTap,
      icon: Icon(
          shown ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          color: muted));
}
