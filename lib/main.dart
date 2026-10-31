import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

const bg = Color(0xFF101923),
    panel = Color(0xFF1B2934),
    panel2 = Color(0xFF243642),
    lime = Color(0xFFB5EA55),
    blue = Color(0xFF60B9F5),
    pink = Color(0xFFFF72AF),
    purple = Color(0xFFAB86F7),
    muted = Color(0xFF93A7B2);
InputDecoration _input(String label) => InputDecoration(
    hintText: label,
    filled: true,
    fillColor: panel2,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none));
Uri api(String path) {
  const configured = String.fromEnvironment('API_BASE_URL');
  if (configured.isNotEmpty) return Uri.parse('$configured$path');
  return kIsWeb
      ? Uri.base.resolve(path)
      : Uri.parse('https://example.invalid$path');
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KristinaApp());
}

class Lesson {
  final String id, title, subtitle, icon, color;
  final List<Question> questions;
  const Lesson(this.id, this.title, this.subtitle, this.icon, this.color,
      this.questions);
}

class Question {
  final String type, prompt, answer, detail;
  final List<String> options;
  const Question(
      this.type, this.prompt, this.answer, this.options, this.detail);
}

const lessons = <Lesson>[
  Lesson('hello', 'Say hello', 'Start with the essentials', '👋', 'green', [
    Question(
        'Choose the meaning',
        'What does “Zdravo” mean?',
        'Hello',
        ['Goodbye', 'Please', 'Hello', 'Thanks'],
        'Zdravo (Здраво) is a friendly, everyday hello.'),
    Question('Translate to Serbian', 'Hello', 'Zdravo',
        ['Hvala', 'Zdravo', 'Da', 'Ne'], 'Nice! Zdravo works any time of day.'),
    Question(
        'Choose the meaning',
        'What does “Hvala” mean?',
        'Thank you',
        ['Thank you', 'Good night', 'Sorry', 'Hello'],
        'Hvala (Хвала) means thank you.'),
    Question(
        'Complete the phrase',
        'Dobar ___ (Good day)',
        'dan',
        ['dan', 'noć', 'jutro', 'veče'],
        'Dobar dan is a polite daytime greeting.'),
  ]),
  Lesson('introductions', 'Meet & greet', 'Make a first impression', '💬',
      'blue', [
    Question(
        'Choose the meaning',
        'Ja sam Kristina.',
        'I am Kristina.',
        [
          'I am Kristina.',
          'You are Kristina.',
          'Hello Kristina.',
          'Where is Kristina?'
        ],
        'Ja sam means “I am”.'),
    Question(
        'Translate to Serbian',
        'My name is Ana.',
        'Zovem se Ana.',
        ['Ja imam Ana.', 'Zovem se Ana.', 'Ana je dobro.', 'Hvala Ana.'],
        'Zovem se literally means “I call myself”.'),
    Question(
        'Choose the meaning',
        'Kako se zoveš?',
        'What is your name?',
        [
          'How are you?',
          'What is your name?',
          'Where are you?',
          'Who is that?'
        ],
        'Zoveš is the informal “you are called”.'),
  ]),
  Lesson('polite', 'Be polite', 'Small words, big charm', '✨', 'pink', [
    Question(
        'Translate to Serbian',
        'Please',
        'Molim',
        ['Izvini', 'Molim', 'Hvala', 'Ćao'],
        'Molim can also mean “you’re welcome”.'),
    Question(
        'Choose the meaning',
        'Izvini',
        'Sorry',
        ['Please', 'Goodbye', 'Sorry', 'Yes'],
        'Use izvini with someone you know.'),
    Question(
        'Complete the phrase',
        'Hvala ___! (Thank you very much!)',
        'puno',
        ['puno', 'malo', 'dobro', 'novo'],
        'Hvala puno is a common way to thank someone warmly.'),
  ]),
  Lesson('numbers', 'Count on me', 'Numbers 1 to 10', '🔢', 'purple', [
    Question('Choose the meaning', 'jedan', 'one',
        ['three', 'one', 'five', 'two'], 'Jedan means one.'),
    Question('Choose the meaning', 'dva', 'two',
        ['one', 'four', 'two', 'seven'], 'Dva means two.'),
    Question('Translate to Serbian', 'Three', 'tri',
        ['pet', 'deset', 'tri', 'šest'], 'Tri means three.'),
  ]),
  Lesson('coffee', 'At the café', 'Order like a local', '☕', 'orange', [
    Question(
        'Translate to Serbian',
        'Coffee, please.',
        'Kafu, molim.',
        ['Vodu, hvala.', 'Kafu, molim.', 'Dobar dan.', 'Ja sam kafa.'],
        'Kafu is the form used when ordering coffee.'),
    Question('Choose the meaning', 'Voda', 'Water',
        ['Coffee', 'Water', 'Milk', 'Bread'], 'Voda means water.'),
    Question(
        'Complete the phrase',
        'Jednu kafu, ___ .',
        'molim',
        ['molim', 'hvala', 'zdravo', 'sutra'],
        'A polite order: One coffee, please.'),
  ]),
  Lesson('family', 'My people', 'Talk about family', '🏡', 'green', [
    Question(
        'Choose the meaning',
        'majka',
        'mother',
        ['father', 'sister', 'mother', 'brother'],
        'Majka is mother; mama is also common.'),
    Question('Choose the meaning', 'brat', 'brother',
        ['brother', 'father', 'friend', 'son'], 'Brat means brother.'),
    Question(
        'Translate to Serbian',
        'My sister',
        'Moja sestra',
        ['Moj brat', 'Moja sestra', 'Moja majka', 'Moj otac'],
        'Sestra is feminine, so use moja.'),
  ]),
];
const words = <List<String>>[
  ['Zdravo', 'Здраво', 'Hello', 'zdrah-voh'],
  ['Hvala', 'Хвала', 'Thank you', 'hvah-lah'],
  ['Molim', 'Молим', 'Please', 'moh-leem'],
  ['Da', 'Да', 'Yes', 'dah'],
  ['Ne', 'Не', 'No', 'neh'],
  ['Dobar dan', 'Добар дан', 'Good day', 'doh-bar dahn'],
  ['Izvini', 'Извини', 'Sorry', 'eez-vee-nee'],
  ['Voda', 'Вода', 'Water', 'voh-dah'],
  ['Kafa', 'Кафа', 'Coffee', 'kah-fah'],
  ['Jedan', 'Један', 'One', 'yeh-dahn'],
  ['Dva', 'Два', 'Two', 'dvah'],
  ['Tri', 'Три', 'Three', 'tree'],
  ['Ja sam', 'Ја сам', 'I am', 'yah sahm'],
  ['Zovem se', 'Зовем се', 'My name is', 'zoh-vem seh'],
  ['Majka', 'Мајка', 'Mother', 'mai-kah'],
  ['Brat', 'Брат', 'Brother', 'braht'],
  ['Sestra', 'Сестра', 'Sister', 'ses-trah'],
];
const wordLesson = <String>[
  'hello',
  'hello',
  'polite',
  'polite',
  'polite',
  'hello',
  'polite',
  'coffee',
  'coffee',
  'numbers',
  'numbers',
  'numbers',
  'introductions',
  'introductions',
  'family',
  'family',
  'family'
];
const letters = <List<String>>[
  ['А', 'A', 'a'],
  ['Б', 'B', 'b'],
  ['В', 'V', 'v'],
  ['Г', 'G', 'g'],
  ['Д', 'D', 'd'],
  ['Ђ', 'Đ', 'dj'],
  ['Е', 'E', 'e'],
  ['Ж', 'Ž', 'zh'],
  ['З', 'Z', 'z'],
  ['И', 'I', 'i'],
  ['Ј', 'J', 'y'],
  ['К', 'K', 'k'],
  ['Л', 'L', 'l'],
  ['Љ', 'Lj', 'ly'],
  ['М', 'M', 'm'],
  ['Н', 'N', 'n'],
  ['Њ', 'Nj', 'ny'],
  ['О', 'O', 'o'],
  ['П', 'P', 'p'],
  ['Р', 'R', 'r'],
  ['С', 'S', 's'],
  ['Т', 'T', 't'],
  ['Ћ', 'Ć', 'ch'],
  ['У', 'U', 'u'],
  ['Ф', 'F', 'f'],
  ['Х', 'H', 'h'],
  ['Ц', 'C', 'ts'],
  ['Ч', 'Č', 'ch'],
  ['Џ', 'Dž', 'j'],
  ['Ш', 'Š', 'sh'],
];

class KristinaApp extends StatefulWidget {
  const KristinaApp({super.key});
  @override
  State<KristinaApp> createState() => _KristinaAppState();
}

class _KristinaAppState extends State<KristinaApp> {
  int tab = 0, xp = 0, streak = 0;
  Set<String> done = {};
  String? reviewLessonId;
  String? token;
  Map<String, dynamic>? user;
  Color avatarColor = purple;
  String avatarFace = '😊';
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      done = (p.getStringList('done') ?? []).toSet();
      xp = p.getInt('xp') ?? 0;
      streak = p.getInt('streak') ?? 0;
      token = p.getString('token');
      SharedToken.value = token;
      avatarFace = p.getString('avatarFace') ?? '😊';
      avatarColor = Color(p.getInt('avatarColor') ?? purple.toARGB32());
      loading = false;
    });
    if (token != null) {
      try {
        final r = await http.get(api('/api/auth/me'),
            headers: {'Authorization': 'Bearer $token'});
        if (r.statusCode == 200 && mounted) {
          setState(() {
            user = jsonDecode(r.body)['user'];
            _applyAvatar(user);
          });
          await _syncProgress();
        } else if (r.statusCode == 401) {
          await p.remove('token');
          if (mounted)
            setState(() {
              token = null;
              SharedToken.value = null;
            });
        }
      } catch (_) {}
    }
  }

  void _applyAvatar(Map<String, dynamic>? account) {
    final avatar = account?['avatar'];
    if (avatar is! Map) return;
    if (avatar['face'] is String) avatarFace = avatar['face'];
    final hex = avatar['color'];
    if (hex is String && RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) {
      avatarColor = Color(int.parse('FF${hex.substring(1)}', radix: 16));
    }
  }

  Future<void> _syncProgress() async {
    if (token == null) return;
    try {
      final r = await http.get(api('/api/course/progress'),
          headers: {'Authorization': 'Bearer $token'});
      if (r.statusCode != 200 || !mounted) return;
      final progress = jsonDecode(r.body)['progress'] as Map<String, dynamic>?;
      setState(() {
        done.addAll(
            (progress?['completedLessons'] as List? ?? []).cast<String>());
        final suggestion = jsonDecode(r.body)['recommendation'];
        reviewLessonId = suggestion?['reason'] == 'review'
            ? suggestion['lessonId'] as String?
            : null;
        xp = (user?['xp'] as num?)?.toInt() ?? xp;
        streak = (user?['streak'] as num?)?.toInt() ?? streak;
      });
      final p = await SharedPreferences.getInstance();
      await p.setStringList('done', done.toList());
      await p.setInt('xp', xp);
      await p.setInt('streak', streak);
    } catch (_) {}
  }

  Future<void> finish(Lesson lesson, int correct, List<bool> answers) async {
    final first = !done.contains(lesson.id);
    setState(() {
      done.add(lesson.id);
      if (first) xp += 10 + correct * 5;
      streak = streak == 0 ? 1 : streak;
    });
    final p = await SharedPreferences.getInstance();
    await p.setStringList('done', done.toList());
    await p.setInt('xp', xp);
    await p.setInt('streak', streak);
    if (token != null) {
      try {
        final response = await http.post(api('/api/course/progress'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json'
            },
            body: jsonEncode({
              'lessonId': lesson.id,
              'score': 10 + correct * 5,
              'answers': answers,
              'words':
                  lesson.id == 'hello' ? ['Zdravo', 'Hvala', 'Dobar dan'] : []
            }));
        if (response.statusCode == 200) {
          final me = await http.get(api('/api/auth/me'),
              headers: {'Authorization': 'Bearer $token'});
          if (me.statusCode == 200 && mounted) {
            setState(() => user = jsonDecode(me.body)['user']);
            await _syncProgress();
          }
        }
      } catch (_) {}
    }
  }

  Future<void> auth(String email, String password, String name, bool register,
      bool remember) async {
    final r = await http.post(
        api(register ? '/api/auth/register' : '/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'remember': remember
        }));
    final data = jsonDecode(r.body);
    if (r.statusCode >= 400)
      throw Exception(data['error'] ?? 'Could not sign in');
    final p = await SharedPreferences.getInstance();
    await p.setString('token', data['token']);
    await p.remove('done');
    await p.remove('xp');
    await p.remove('streak');
    setState(() {
      token = data['token'];
      user = data['user'];
      done = {};
      xp = 0;
      streak = 0;
      SharedToken.value = token;
      _applyAvatar(user);
    });
    await _syncProgress();
  }

  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('token');
    await p.remove('done');
    await p.remove('xp');
    await p.remove('streak');
    setState(() {
      token = null;
      user = null;
      done = {};
      xp = 0;
      streak = 0;
      reviewLessonId = null;
      SharedToken.value = null;
    });
  }

  Future<void> changeAvatar(String face, Color color) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('avatarFace', face);
    await p.setInt('avatarColor', color.toARGB32());
    setState(() {
      avatarFace = face;
      avatarColor = color;
    });
    if (token != null) {
      final hex =
          color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);
      try {
        await http.patch(api('/api/auth/profile'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json'
            },
            body: jsonEncode({
              'avatar': {'face': face, 'color': '#$hex'}
            }));
      } catch (_) {}
    }
  }

  void lesson(Lesson l) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            LessonPage(lesson: l, onComplete: (n, a) => finish(l, n, a))));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Hello Kristina',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: bg,
            colorScheme: ColorScheme.fromSeed(
                seedColor: lime, brightness: Brightness.dark),
            textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme)
                .apply(bodyColor: Colors.white, displayColor: Colors.white)),
        home: loading
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : Scaffold(
                body: SafeArea(
                    child: Center(
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 980),
                            child: Column(children: [
                              Expanded(
                                  child: Row(children: [
                                if (MediaQuery.sizeOf(context).width > 720)
                                  SizedBox(
                                      width: 190,
                                      child: SideNav(
                                          tab: tab,
                                          onTap: (i) =>
                                              setState(() => tab = i))),
                                Expanded(
                                    child: IndexedStack(index: tab, children: [
                                  PathPage(
                                      done: done,
                                      reviewLessonId: reviewLessonId,
                                      xp: xp,
                                      streak: streak,
                                      onLesson: lesson,
                                      onChat: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  ChatPage(token: token)))),
                                  WordsPage(done: done),
                                  LettersPage(),
                                  FriendsPage(token: token),
                                  ProfilePage(
                                      user: user,
                                      xp: xp,
                                      streak: streak,
                                      done: done,
                                      face: avatarFace,
                                      color: avatarColor,
                                      onAvatar: changeAvatar,
                                      onAuth: auth,
                                      onLogout: logout)
                                ]))
                              ])),
                              if (MediaQuery.sizeOf(context).width <= 720)
                                BottomNav(
                                    tab: tab,
                                    onTap: (i) => setState(() => tab = i))
                            ]))))));
  }
}

class KCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final VoidCallback? onTap;
  const KCard(
      {super.key, required this.child, this.padding, this.color, this.onTap});
  @override
  Widget build(BuildContext context) => Material(
      color: color ?? panel,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
              padding: padding ?? const EdgeInsets.all(18), child: child)));
}

class KButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Color color;
  final bool outline;
  const KButton(
      {super.key,
      required this.text,
      this.onTap,
      this.color = lime,
      this.outline = false});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
              backgroundColor: outline ? panel2 : color,
              foregroundColor: outline ? Colors.white : bg,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: outline
                      ? BorderSide(color: muted.withOpacity(.25))
                      : BorderSide.none)),
          child: Text(text,
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: .8))));
}

class Kristina extends StatefulWidget {
  final double size;
  final String mood;
  const Kristina({super.key, this.size = 92, this.mood = 'happy'});
  @override
  State<Kristina> createState() => _KristinaState();
}

class _KristinaState extends State<Kristina>
    with SingleTickerProviderStateMixin {
  late AnimationController c;
  @override
  void initState() {
    super.initState();
    c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: c,
      builder: (_, child) => Transform.translate(
          offset: Offset(0, -5 * c.value),
          child: Transform.rotate(angle: (c.value - .5) * .04, child: child)),
      child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: lime, width: 4),
              boxShadow: [
                BoxShadow(color: lime.withOpacity(.18), blurRadius: 26)
              ]),
          clipBehavior: Clip.antiAlias,
          child: Image.asset('assets/kristina.jpg', fit: BoxFit.cover)));
}

class PageHead extends StatelessWidget {
  final String eyebrow, title;
  final String? subtitle;
  const PageHead(
      {super.key, required this.eyebrow, required this.title, this.subtitle});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(eyebrow.toUpperCase(),
            style: const TextStyle(
                color: lime,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 11)),
        const SizedBox(height: 6),
        Text(title,
            style: const TextStyle(
                fontSize: 29, fontWeight: FontWeight.w900, height: 1.1)),
        if (subtitle != null) ...[
          const SizedBox(height: 7),
          Text(subtitle!, style: const TextStyle(color: muted, fontSize: 14))
        ]
      ]);
}

class PathPage extends StatelessWidget {
  final Set<String> done;
  final String? reviewLessonId;
  final int xp, streak;
  final void Function(Lesson) onLesson;
  final VoidCallback onChat;
  const PathPage(
      {super.key,
      required this.done,
      required this.reviewLessonId,
      required this.xp,
      required this.streak,
      required this.onLesson,
      required this.onChat});
  @override
  Widget build(BuildContext context) {
    final next = lessons.indexWhere((l) => !done.contains(l.id));
    return ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
        children: [
          Row(children: [
            Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: panel2, borderRadius: BorderRadius.circular(12)),
                child: const Center(
                    child: Text('🇷🇸', style: TextStyle(fontSize: 24)))),
            const SizedBox(width: 10),
            const Expanded(
                child: Text('SERBIAN',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, letterSpacing: 1.5))),
            _stat('🔥', '$streak'),
            const SizedBox(width: 8),
            _stat('⚡', '$xp')
          ]),
          const SizedBox(height: 28),
          const PageHead(
              eyebrow: 'Your learning path', title: 'Ćao, superstar!'),
          const SizedBox(height: 18),
          KCard(
              color: const Color(0xFF314E45),
              child: Row(children: [
                const Kristina(size: 78),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('A little Serbian today?',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 17)),
                      const SizedBox(height: 4),
                      Text(
                          done.isEmpty
                              ? 'The first step is tiny. The bragging rights? Huge.'
                              : 'Look who’s actually showing up. I’m impressed. Mostly.',
                          style: const TextStyle(
                              color: Color(0xFFCEEBDA), fontSize: 13))
                    ]))
              ])),
          const SizedBox(height: 12),
          KCard(
              onTap: onChat,
              color: const Color(0xFF3B3152),
              child: const Row(children: [
                Text('🎙️', style: TextStyle(fontSize: 30)),
                SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Chat with Kristina',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 16)),
                      Text('Practice a little, laugh a little.',
                          style: TextStyle(color: muted, fontSize: 12))
                    ])),
                Icon(Icons.chevron_right, color: purple)
              ])),
          if (reviewLessonId != null &&
              lessons.any((lesson) => lesson.id == reviewLessonId)) ...[
            const SizedBox(height: 12),
            KCard(
                onTap: () => onLesson(lessons
                    .firstWhere((lesson) => lesson.id == reviewLessonId)),
                color: const Color(0xFF493A2D),
                child: Row(children: [
                  const Text('🧠', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Text(
                          'A quick review of ${lessons.firstWhere((lesson) => lesson.id == reviewLessonId).title} will help it stick.',
                          style: const TextStyle(fontWeight: FontWeight.w800))),
                  const Icon(Icons.arrow_forward, color: lime)
                ]))
          ],
          const SizedBox(height: 22),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('SECTION 1 · THE BASICS',
                style: TextStyle(
                    color: lime,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                    fontSize: 12)),
            Text('${done.length}/${lessons.length} lessons',
                style: const TextStyle(color: muted, fontSize: 12))
          ]),
          const SizedBox(height: 10),
          ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                  value: done.length / lessons.length,
                  minHeight: 9,
                  backgroundColor: panel2,
                  valueColor: const AlwaysStoppedAnimation(lime))),
          const SizedBox(height: 24),
          ...lessons.asMap().entries.map((entry) {
            final i = entry.key,
                l = entry.value,
                completed = done.contains(l.id),
                locked = i > 0 && !done.contains(lessons[i - 1].id);
            final active = i == next;
            return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: KCard(
                    onTap: locked ? null : () => onLesson(l),
                    color: active ? const Color(0xFF284238) : panel,
                    child: Row(children: [
                      Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                              color: completed
                                  ? lime
                                  : locked
                                      ? panel2
                                      : colorFor(l.color),
                              borderRadius: BorderRadius.circular(18)),
                          child: Center(
                              child: Text(
                                  completed
                                      ? '✓'
                                      : locked
                                          ? '🔒'
                                          : l.icon,
                                  style: TextStyle(
                                      fontSize: completed ? 28 : 25,
                                      color: bg,
                                      fontWeight: FontWeight.w900)))),
                      const SizedBox(width: 15),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(l.title,
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                    color: locked ? muted : Colors.white)),
                            Text(l.subtitle,
                                style:
                                    const TextStyle(color: muted, fontSize: 13))
                          ])),
                      Text(
                          completed
                              ? 'DONE'
                              : locked
                                  ? ''
                                  : 'START',
                          style: TextStyle(
                              color: completed ? lime : blue,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1))
                    ])));
          }),
          const SizedBox(height: 12),
          KCard(
              color: const Color(0xFF30264A),
              child: const Row(children: [
                Text('🚀', style: TextStyle(fontSize: 32)),
                SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('The road to fluent',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 16)),
                      Text('A1 → A2 → B1 → B2 → C1 → C2',
                          style:
                              TextStyle(color: Color(0xFFCCB9F3), fontSize: 12))
                    ]))
              ]))
        ]);
  }

  Widget _stat(String icon, String value) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration:
          BoxDecoration(color: panel, borderRadius: BorderRadius.circular(12)),
      child: Text('$icon $value',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)));
}

Color colorFor(String c) => switch (c) {
      'blue' => blue,
      'pink' => pink,
      'purple' => purple,
      'orange' => const Color(0xFFFFB65D),
      _ => lime
    };

class LessonPage extends StatefulWidget {
  final Lesson lesson;
  final Future<void> Function(int, List<bool>) onComplete;
  const LessonPage({super.key, required this.lesson, required this.onComplete});
  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  int index = 0, correct = 0;
  final List<bool> answers = [];
  String? selected;
  bool checked = false, finished = false;
  @override
  Widget build(BuildContext context) {
    final q = widget.lesson.questions[index];
    return Scaffold(
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.close)),
                                Expanded(
                                    child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: LinearProgressIndicator(
                                            value: finished
                                                ? 1
                                                : (index + 1) /
                                                    widget.lesson.questions
                                                        .length,
                                            minHeight: 10,
                                            backgroundColor: panel2,
                                            valueColor:
                                                const AlwaysStoppedAnimation(
                                                    lime)))),
                                const SizedBox(width: 14),
                                Text(
                                    '${index + 1}/${widget.lesson.questions.length}',
                                    style: const TextStyle(
                                        color: muted,
                                        fontWeight: FontWeight.w900))
                              ]),
                              const SizedBox(height: 34),
                              if (finished) ...[
                                const Spacer(),
                                Center(
                                    child: Column(children: [
                                  const Kristina(size: 150),
                                  const SizedBox(height: 24),
                                  const Text('Lesson complete!',
                                      style: TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 8),
                                  Text(
                                      correct == widget.lesson.questions.length
                                          ? 'Okay, show-off. That was perfect.'
                                          : 'You showed up. I’ll allow it. 😏',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: muted, fontSize: 16)),
                                  const SizedBox(height: 20),
                                  Text('⚡ +${10 + correct * 5} XP',
                                      style: const TextStyle(
                                          color: lime,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900))
                                ])),
                                const Spacer(),
                                KButton(
                                    text: 'BACK TO PATH',
                                    onTap: () => Navigator.pop(context))
                              ] else ...[
                                Text(q.type.toUpperCase(),
                                    style: const TextStyle(
                                        color: blue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.6)),
                                const SizedBox(height: 10),
                                Text(q.prompt,
                                    style: const TextStyle(
                                        fontSize: 27,
                                        fontWeight: FontWeight.w900)),
                                const SizedBox(height: 22),
                                Row(children: [
                                  const Kristina(size: 60),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: KCard(
                                          color: panel2,
                                          padding: const EdgeInsets.all(13),
                                          child: Text(
                                              checked
                                                  ? (selected == q.answer
                                                      ? 'Ha! Knew you had it.'
                                                      : 'Oops. Even legends need practice.')
                                                  : 'Go on. I’m watching. 👀',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w700))))
                                ]),
                                const SizedBox(height: 28),
                                ...q.options.map((option) => Padding(
                                    padding: const EdgeInsets.only(bottom: 11),
                                    child: KCard(
                                        onTap: checked
                                            ? null
                                            : () => setState(
                                                () => selected = option),
                                        color: checked && option == q.answer
                                            ? const Color(0xFF315840)
                                            : selected == option
                                                ? (checked
                                                    ? const Color(0xFF693B48)
                                                    : const Color(0xFF304E63))
                                                : panel,
                                        child: Row(children: [
                                          Container(
                                              width: 30,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: selected == option
                                                          ? lime
                                                          : muted
                                                              .withOpacity(.5),
                                                      width: 2),
                                                  borderRadius:
                                                      BorderRadius.circular(9)),
                                              child: Center(
                                                  child: Text(
                                                      '${q.options.indexOf(option) + 1}',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          fontSize: 13)))),
                                          const SizedBox(width: 14),
                                          Expanded(
                                              child: Text(option,
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w800)))
                                        ])))),
                                const Spacer(),
                                if (checked)
                                  Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 15),
                                      child: Text(q.detail,
                                          style: TextStyle(
                                              color: selected == q.answer
                                                  ? lime
                                                  : pink,
                                              fontWeight: FontWeight.w700))),
                                KButton(
                                    text: checked ? 'CONTINUE' : 'CHECK',
                                    onTap: selected == null
                                        ? null
                                        : () async {
                                            if (!checked) {
                                              setState(() {
                                                checked = true;
                                                answers
                                                    .add(selected == q.answer);
                                                if (selected == q.answer)
                                                  correct++;
                                              });
                                            } else if (index <
                                                widget.lesson.questions.length -
                                                    1) {
                                              setState(() {
                                                index++;
                                                selected = null;
                                                checked = false;
                                              });
                                            } else {
                                              await widget.onComplete(
                                                  correct, answers);
                                              if (mounted)
                                                setState(() => finished = true);
                                            }
                                          })
                              ]
                            ]))))));
  }
}

class WordsPage extends StatefulWidget {
  final Set<String> done;
  const WordsPage({super.key, required this.done});
  @override
  State<WordsPage> createState() => _WordsPageState();
}

class _WordsPageState extends State<WordsPage> {
  String query = '';
  int? open;
  @override
  Widget build(BuildContext context) {
    final learned = words
        .asMap()
        .entries
        .where((entry) => widget.done.contains(wordLesson[entry.key]))
        .map((entry) => entry.value)
        .toList();
    final list = learned
        .where(
            (w) => w.any((x) => x.toLowerCase().contains(query.toLowerCase())))
        .toList();
    return ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
        children: [
          const PageHead(
              eyebrow: 'Your word bank',
              title: 'Words you know',
              subtitle: 'Tiny words. Big main character energy.'),
          const SizedBox(height: 22),
          KCard(
              color: const Color(0xFF263B4B),
              child: Row(children: [
                const Text('📚', style: TextStyle(fontSize: 35)),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('${learned.length} words collected',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w900)),
                      const Text('Review a little every day.',
                          style: TextStyle(color: muted, fontSize: 13))
                    ]))
              ])),
          const SizedBox(height: 20),
          TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: muted),
                  hintText: 'Search Serbian or English',
                  filled: true,
                  fillColor: panel,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none))),
          const SizedBox(height: 18),
          const Text('THE STARTER COLLECTION',
              style: TextStyle(
                  color: lime,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  fontSize: 12)),
          if (learned.isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Finish your first lesson to collect words.',
                    style: TextStyle(color: muted))),
          const SizedBox(height: 10),
          ...list.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: KCard(
                  onTap: () =>
                      setState(() => open = open == e.key ? null : e.key),
                  child: Column(children: [
                    Row(children: [
                      Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                              color: panel2,
                              borderRadius: BorderRadius.circular(12)),
                          child:
                              const Icon(Icons.volume_up_rounded, color: blue)),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(e.value[0],
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w900)),
                            Text(e.value[1],
                                style:
                                    const TextStyle(color: muted, fontSize: 13))
                          ])),
                      Text(e.value[2],
                          style: const TextStyle(
                              color: lime, fontWeight: FontWeight.w800))
                    ]),
                    if (open == e.key) ...[
                      const Divider(height: 22, color: panel2),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text('SAY IT  ·  ${e.value[3]}',
                              style: const TextStyle(
                                  color: blue,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 1)))
                    ]
                  ]))))
        ]);
  }
}

class LettersPage extends StatefulWidget {
  const LettersPage({super.key});
  @override
  State<LettersPage> createState() => _LettersPageState();
}

class _LettersPageState extends State<LettersPage> {
  int selected = 0;
  @override
  Widget build(BuildContext context) {
    final l = letters[selected];
    return ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
        children: [
          const PageHead(
              eyebrow: 'Theory lab',
              title: 'Crack the Cyrillic code',
              subtitle: 'Thirty letters. You’ve got this.'),
          const SizedBox(height: 22),
          KCard(
              color: const Color(0xFF32284A),
              child: Row(children: [
                Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                        color: purple, borderRadius: BorderRadius.circular(22)),
                    child: Center(
                        child: Text(l[0],
                            style: const TextStyle(
                                fontSize: 62,
                                fontWeight: FontWeight.w900,
                                color: bg)))),
                const SizedBox(width: 18),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('${l[0]}  =  ${l[1]}',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('Sounds like “${l[2]}”',
                          style: const TextStyle(color: muted)),
                      const SizedBox(height: 7),
                      const Text('Tap any letter to explore.',
                          style: TextStyle(
                              color: purple,
                              fontWeight: FontWeight.w800,
                              fontSize: 12))
                    ]))
              ])),
          const SizedBox(height: 26),
          const Text('SERBIAN CYRILLIC',
              style: TextStyle(
                  color: lime,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontSize: 12)),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, c) {
            final width = c.maxWidth;
            final cell = (width - 5 * 9) / 6;
            return Wrap(
                spacing: 9,
                runSpacing: 9,
                children: letters
                    .asMap()
                    .entries
                    .map((e) => GestureDetector(
                        onTap: () => setState(() => selected = e.key),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: cell,
                            height: cell,
                            decoration: BoxDecoration(
                                color: selected == e.key ? purple : panel,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                    color:
                                        selected == e.key ? purple : panel2)),
                            child: Center(
                                child: Text(e.value[0],
                                    style: TextStyle(
                                        fontSize: width > 500 ? 29 : 23,
                                        fontWeight: FontWeight.w900,
                                        color: selected == e.key
                                            ? bg
                                            : Colors.white))))))
                    .toList());
          }),
          const SizedBox(height: 24),
          KCard(
              child: const Row(children: [
            Text('💡', style: TextStyle(fontSize: 30)),
            SizedBox(width: 12),
            Expanded(
                child: Text(
                    'Serbian uses both Cyrillic and Latin. You’ll see both as you learn.',
                    style: TextStyle(color: muted, fontSize: 13)))
          ]))
        ]);
  }
}

class FriendsPage extends StatefulWidget {
  final String? token;
  const FriendsPage({super.key, required this.token});
  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  List<dynamic> friends = [], feed = [];
  bool busy = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(covariant FriendsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token) {
      if (widget.token == null) {
        setState(() {
          friends = [];
          feed = [];
        });
      } else {
        load();
      }
    }
  }

  Future<void> load() async {
    if (widget.token == null) return;
    try {
      final h = {'Authorization': 'Bearer ${widget.token}'};
      final responses = await Future.wait([
        http.get(api('/api/social/friends'), headers: h),
        http.get(api('/api/social/feed'), headers: h)
      ]);
      if (mounted)
        setState(() {
          friends = jsonDecode(responses[0].body)['friends'] ?? [];
          feed = jsonDecode(responses[1].body)['items'] ?? [];
        });
    } catch (_) {}
  }

  Future<void> addFriend() async {
    final c = TextEditingController();
    await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                backgroundColor: panel,
                title: const Text('Find a friend'),
                content: TextField(
                    controller: c,
                    decoration:
                        const InputDecoration(hintText: 'Their username')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('CANCEL')),
                  TextButton(
                      onPressed: () async {
                        try {
                          final r = await http.post(api('/api/social/friends'),
                              headers: {
                                'Authorization': 'Bearer ${widget.token}',
                                'Content-Type': 'application/json'
                              },
                              body: jsonEncode({'username': c.text}));
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(r.statusCode == 200
                                  ? 'Friend added!'
                                  : jsonDecode(r.body)['error'] ??
                                      'Could not add friend')));
                          load();
                        } catch (_) {
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                      child: const Text('ADD'))
                ]));
  }

  Future<void> like(String id) async {
    try {
      await http.post(api('/api/social/feed'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({'itemId': id}));
      load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.fromLTRB(22, 24, 22, 30), children: [
        const PageHead(
            eyebrow: 'Together is better',
            title: 'Friends & feed',
            subtitle: 'Cheer each other on. Lovingly, of course.'),
        const SizedBox(height: 22),
        KCard(
            color: const Color(0xFF29415B),
            child: Row(children: [
              const Text('👯', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 15),
              const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Learning is more fun together',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    Text('Find your language people.',
                        style: TextStyle(color: muted, fontSize: 13))
                  ])),
              if (widget.token != null)
                IconButton(
                    onPressed: addFriend,
                    icon: const Icon(Icons.person_add_alt_1, color: blue))
            ])),
        const SizedBox(height: 22),
        if (widget.token == null)
          KCard(
              child: const Text(
                  'Create an account from Profile to add friends and share your wins.',
                  style: TextStyle(color: muted)))
        else ...[
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('YOUR CREW',
                style: TextStyle(
                    color: lime,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    fontSize: 12)),
            TextButton(
                onPressed: addFriend,
                child: const Text('+ ADD FRIEND',
                    style: TextStyle(color: blue, fontWeight: FontWeight.w900)))
          ]),
          if (friends.isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Text(
                    'Your crew starts with one friend. Invite someone by username.',
                    style: TextStyle(color: muted)))
          else
            ...friends.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: KCard(
                    child: Row(children: [
                  CircleAvatar(
                      backgroundColor: purple,
                      child: Text((f['name'] ?? '?')
                          .toString()
                          .substring(0, 1)
                          .toUpperCase())),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(f['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w900))),
                  Text('⚡ ${f['xp'] ?? 0}',
                      style: const TextStyle(
                          color: lime, fontWeight: FontWeight.w900))
                ])))),
          const SizedBox(height: 18),
          const Text('LATEST WINS',
              style: TextStyle(
                  color: lime,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  fontSize: 12)),
          const SizedBox(height: 10),
          if (feed.isEmpty)
            KCard(
                child: const Text(
                    'The feed is quiet. Finish a lesson and make some noise!',
                    style: TextStyle(color: muted)))
          else
            ...feed.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: KCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          '${f['actorName'] ?? 'A learner'} finished ${f['lessonId'] ?? 'a lesson'} 🎉',
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text('⚡ +${f['xp'] ?? 0} XP',
                          style: const TextStyle(color: lime)),
                      const SizedBox(height: 8),
                      TextButton.icon(
                          onPressed: () => like(f['id']),
                          icon: Icon(
                              f['liked'] == true
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: pink),
                          label: Text('${f['likeCount'] ?? 0} likes',
                              style: const TextStyle(color: muted)))
                    ]))))
        ]
      ]);
}

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic>? user;
  final int xp, streak;
  final Set<String> done;
  final String face;
  final Color color;
  final Future<void> Function(String, Color) onAvatar;
  final Future<void> Function(String, String, String, bool, bool) onAuth;
  final Future<void> Function() onLogout;
  const ProfilePage(
      {super.key,
      required this.user,
      required this.xp,
      required this.streak,
      required this.done,
      required this.face,
      required this.color,
      required this.onAvatar,
      required this.onAuth,
      required this.onLogout});
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.fromLTRB(22, 24, 22, 30), children: [
        const PageHead(
            eyebrow: 'Your story',
            title: 'Look at you go',
            subtitle: 'Every little win counts.'),
        const SizedBox(height: 22),
        KCard(
            color: const Color(0xFF25374B),
            child: Column(children: [
              Row(children: [
                GestureDetector(
                    onTap: () => _avatarDialog(context),
                    child: Stack(children: [
                      CircleAvatar(
                          radius: 42,
                          backgroundColor: color,
                          child:
                              Text(face, style: const TextStyle(fontSize: 43))),
                      const Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                              radius: 12,
                              backgroundColor: blue,
                              child: Icon(Icons.edit, size: 13, color: bg)))
                    ])),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(user?['name'] ?? 'Serbian superstar',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 20)),
                      Text(
                          user == null
                              ? 'Your journey starts here'
                              : '@${user!['username']}',
                          style: const TextStyle(color: muted, fontSize: 13))
                    ]))
              ]),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: _metric('⚡', '$xp', 'Total XP')),
                const SizedBox(width: 9),
                Expanded(child: _metric('🔥', '$streak', 'Day streak')),
                const SizedBox(width: 9),
                Expanded(child: _metric('🏆', '${done.length}', 'Lessons'))
              ])
            ])),
        const SizedBox(height: 22),
        const Text('YOUR LOOK',
            style: TextStyle(
                color: lime,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                fontSize: 12)),
        const SizedBox(height: 10),
        KCard(
            onTap: () => _avatarDialog(context),
            child: const Row(children: [
              Text('🎨', style: TextStyle(fontSize: 27)),
              SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Avatar builder',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    Text('Make it unmistakably you.',
                        style: TextStyle(color: muted, fontSize: 13))
                  ])),
              Icon(Icons.chevron_right, color: muted)
            ])),
        const SizedBox(height: 22),
        const Text('MILESTONES',
            style: TextStyle(
                color: lime,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                fontSize: 12)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _badge('👋', 'First hello', done.isNotEmpty)),
          const SizedBox(width: 10),
          Expanded(child: _badge('🔥', 'On a roll', streak >= 3)),
          const SizedBox(width: 10),
          Expanded(child: _badge('⭐', '50 XP', xp >= 50))
        ]),
        const SizedBox(height: 22),
        if (user == null)
          KButton(
              text: 'CREATE ACCOUNT / SIGN IN',
              onTap: () => _authDialog(context))
        else ...[
          KCard(
              child: Row(children: [
            const Icon(Icons.verified_user_outlined, color: lime),
            const SizedBox(width: 12),
            Expanded(
                child: Text(user!['email'] ?? '',
                    style: const TextStyle(color: muted)))
          ])),
          const SizedBox(height: 12),
          if (user!['role'] == 'admin')
            KCard(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AdminPage(token: SharedToken.value))),
                child: const Row(children: [
                  Icon(Icons.admin_panel_settings, color: blue),
                  SizedBox(width: 12),
                  Expanded(
                      child: Text('Course studio',
                          style: TextStyle(fontWeight: FontWeight.w900))),
                  Icon(Icons.chevron_right)
                ])),
          const SizedBox(height: 12),
          KButton(text: 'SIGN OUT', outline: true, onTap: () => onLogout())
        ]
      ]);
  Widget _metric(String icon, String value, String label) => Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration:
          BoxDecoration(color: panel, borderRadius: BorderRadius.circular(15)),
      child: Column(children: [
        Text('$icon $value',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        Text(label, style: const TextStyle(color: muted, fontSize: 10))
      ]));
  Widget _badge(String icon, String label, bool unlocked) => Container(
      height: 96,
      decoration: BoxDecoration(
          color: unlocked ? const Color(0xFF3B344B) : panel,
          borderRadius: BorderRadius.circular(17)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(unlocked ? icon : '🔒', style: const TextStyle(fontSize: 25)),
        const SizedBox(height: 5),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: unlocked ? Colors.white : muted))
      ]));
  void _avatarDialog(BuildContext context) {
    const faces = ['😊', '😎', '🤠', '🦊', '🐻', '🐱', '👽', '🤩'];
    const colors = [
      purple,
      blue,
      pink,
      lime,
      Color(0xFFFFB65D),
      Color(0xFF65D9C1)
    ];
    showModalBottomSheet(
        context: context,
        backgroundColor: panel,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        builder: (ctx) => Padding(
            padding: const EdgeInsets.all(24),
            child: SafeArea(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Build your avatar',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  const Text('Pick a face with personality.',
                      style: TextStyle(color: muted)),
                  const SizedBox(height: 20),
                  Wrap(
                      spacing: 11,
                      runSpacing: 11,
                      children: faces
                          .map((f) => GestureDetector(
                              onTap: () {
                                onAvatar(f, color);
                                Navigator.pop(ctx);
                              },
                              child: CircleAvatar(
                                  radius: 31,
                                  backgroundColor: color,
                                  child: Text(f,
                                      style: const TextStyle(fontSize: 32)))))
                          .toList()),
                  const SizedBox(height: 25),
                  const Text('PICK A COLOR',
                      style: TextStyle(
                          color: lime,
                          fontSize: 12,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Wrap(
                      spacing: 13,
                      children: colors
                          .map((c) => GestureDetector(
                              onTap: () {
                                onAvatar(face, c);
                                Navigator.pop(ctx);
                              },
                              child: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: c,
                                  child: c == color
                                      ? const Icon(Icons.check, color: bg)
                                      : null)))
                          .toList()),
                  const SizedBox(height: 20)
                ]))));
  }

  void _authDialog(BuildContext context) {
    final email = TextEditingController(),
        password = TextEditingController(),
        name = TextEditingController();
    bool register = true, remember = true, busy = false;
    String? error;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: panel,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setSheet) => Padding(
                padding: EdgeInsets.fromLTRB(
                    24, 24, 24, MediaQuery.viewInsetsOf(ctx).bottom + 24),
                child: SafeArea(
                    child: SingleChildScrollView(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                      Text(register ? 'Join the fun' : 'Welcome back',
                          style: const TextStyle(
                              fontSize: 25, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 5),
                      Text(
                          register
                              ? 'Save your progress and find your crew.'
                              : 'Kristina missed you. A little.',
                          style: const TextStyle(color: muted)),
                      const SizedBox(height: 20),
                      if (register) ...[
                        TextField(
                            controller: name, decoration: _input('Your name')),
                        const SizedBox(height: 12)
                      ],
                      TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _input('Email')),
                      const SizedBox(height: 12),
                      TextField(
                          controller: password,
                          obscureText: true,
                          decoration: _input('Password (8+ characters)')),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                          value: remember,
                          onChanged: (v) =>
                              setSheet(() => remember = v ?? true),
                          title: const Text('Remember me for 7 days',
                              style: TextStyle(fontSize: 13)),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: lime),
                      if (error != null)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(error!,
                                style: const TextStyle(color: pink))),
                      KButton(
                          text: busy
                              ? 'ONE MOMENT...'
                              : register
                                  ? 'CREATE ACCOUNT'
                                  : 'SIGN IN',
                          onTap: busy
                              ? null
                              : () async {
                                  setSheet(() {
                                    busy = true;
                                    error = null;
                                  });
                                  try {
                                    await onAuth(email.text, password.text,
                                        name.text, register, remember);
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  } catch (e) {
                                    setSheet(() {
                                      busy = false;
                                      error = e
                                          .toString()
                                          .replaceFirst('Exception: ', '');
                                    });
                                  }
                                }),
                      const SizedBox(height: 8),
                      Center(
                          child: TextButton(
                              onPressed: () =>
                                  setSheet(() => register = !register),
                              child: Text(
                                  register
                                      ? 'Already have an account? Sign in'
                                      : 'New here? Create an account',
                                  style: const TextStyle(color: blue))))
                    ]))))));
  }

  InputDecoration _input(String label) => InputDecoration(
      hintText: label,
      filled: true,
      fillColor: panel2,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none));
}

class SharedToken {
  static String? value;
}

class BottomNav extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onTap;
  const BottomNav({super.key, required this.tab, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
      decoration: const BoxDecoration(
          color: panel, border: Border(top: BorderSide(color: panel2))),
      padding: const EdgeInsets.only(top: 8, bottom: 5),
      child: Row(
          children: List.generate(
              5,
              (i) => Expanded(
                  child: InkWell(
                      onTap: () => onTap(i),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(['🏠', '📖', '🔤', '👯', '👤'][i],
                            style: const TextStyle(fontSize: 23)),
                        const SizedBox(height: 2),
                        Text(
                            [
                              'PATH',
                              'WORDS',
                              'LETTERS',
                              'FRIENDS',
                              'PROFILE'
                            ][i],
                            style: TextStyle(
                                fontSize: 9,
                                color: tab == i ? lime : muted,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .3))
                      ]))))));
}

class SideNav extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onTap;
  const SideNav({super.key, required this.tab, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
      color: panel,
      child: Column(children: [
        const Padding(
            padding: EdgeInsets.fromLTRB(20, 30, 12, 30),
            child: Text('HELLO\nKRISTINA',
                style: TextStyle(
                    color: lime,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    height: 1))),
        ...List.generate(
            5,
            (i) => ListTile(
                onTap: () => onTap(i),
                selected: tab == i,
                selectedTileColor: panel2,
                leading: Text(['🏠', '📖', '🔤', '👯', '👤'][i]),
                title: Text(
                    ['Path', 'Words', 'Letters', 'Friends', 'Profile'][i],
                    style: TextStyle(
                        color: tab == i ? lime : muted,
                        fontWeight: FontWeight.w900,
                        fontSize: 13))))
      ]));
}

class AdminPage extends StatefulWidget {
  final String? token;
  const AdminPage({super.key, required this.token});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final topic = TextEditingController(), objectives = TextEditingController();
  String level = 'A1', result = '';
  bool loading = false;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Course studio'), backgroundColor: bg),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: ListView(padding: const EdgeInsets.all(22), children: [
                const PageHead(
                    eyebrow: 'Admin workspace',
                    title: 'Create a lesson draft',
                    subtitle: 'AI drafts need human review before publishing.'),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                    value: level,
                    items: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                        .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                        .toList(),
                    onChanged: (v) => setState(() => level = v ?? 'A1'),
                    decoration: _input('Level')),
                const SizedBox(height: 12),
                TextField(
                    controller: topic,
                    decoration: _input('Topic, e.g. directions')),
                const SizedBox(height: 12),
                TextField(
                    controller: objectives,
                    maxLines: 3,
                    decoration: _input('Learning objectives')),
                const SizedBox(height: 18),
                KButton(
                    text: loading ? 'GENERATING...' : 'GENERATE DRAFT',
                    onTap: loading
                        ? null
                        : () async {
                            setState(() => loading = true);
                            try {
                              final r = await http.post(
                                  api('/api/admin/generate'),
                                  headers: {
                                    'Authorization': 'Bearer ${widget.token}',
                                    'Content-Type': 'application/json'
                                  },
                                  body: jsonEncode({
                                    'level': level,
                                    'topic': topic.text,
                                    'objectives': objectives.text
                                  }));
                              setState(() => result =
                                  const JsonEncoder.withIndent('  ')
                                      .convert(jsonDecode(r.body)));
                            } catch (e) {
                              setState(() => result = '$e');
                            } finally {
                              setState(() => loading = false);
                            }
                          }),
                const SizedBox(height: 20),
                if (result.isNotEmpty)
                  KCard(
                      child: SelectableText(result,
                          style: const TextStyle(fontSize: 12, color: muted)))
              ]))));
}

class ChatPage extends StatefulWidget {
  final String? token;
  const ChatPage({super.key, required this.token});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final input = TextEditingController();
  final messages = <Map<String, String>>[
    {
      'role': 'assistant',
      'text':
          'Ćao! Ready to practice Serbian? Tell me what you learned today. And yes, I’ll notice if you try to dodge the question. 😏'
    }
  ];
  bool busy = false;
  Future<void> send() async {
    final message = input.text.trim();
    if (message.isEmpty || busy) return;
    input.clear();
    setState(() {
      messages.add({'role': 'user', 'text': message});
      busy = true;
    });
    try {
      final r = await http.post(api('/api/course/chat'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({'message': message}));
      final data = jsonDecode(r.body);
      setState(() => messages.add({
            'role': 'assistant',
            'text': r.statusCode == 200
                ? data['reply']
                : data['error'] ?? 'Try again shortly.'
          }));
    } catch (_) {
      setState(() => messages.add({
            'role': 'assistant',
            'text': 'I lost my train of thought. Try again?'
          }));
    } finally {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar:
          AppBar(backgroundColor: bg, title: const Text('Chat with Kristina')),
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(children: [
                    Expanded(
                        child: ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                          ...messages.map((m) => Align(
                              alignment: m['role'] == 'user'
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (m['role'] != 'user') ...[
                                          const Kristina(size: 38),
                                          const SizedBox(width: 9)
                                        ],
                                        Flexible(
                                            child: KCard(
                                                color: m['role'] == 'user'
                                                    ? const Color(0xFF315840)
                                                    : panel,
                                                child: Text(m['text']!,
                                                    style: const TextStyle(
                                                        fontSize: 14))))
                                      ])))),
                          if (busy)
                            const Padding(
                                padding: EdgeInsets.all(14),
                                child: Text('Kristina is thinking...',
                                    style: TextStyle(color: muted)))
                        ])),
                    if (widget.token == null)
                      const Padding(
                          padding: EdgeInsets.all(18),
                          child: Text(
                              'Sign in from Profile to chat with Kristina.',
                              style: TextStyle(color: muted)))
                    else
                      Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            Expanded(
                                child: TextField(
                                    controller: input,
                                    onSubmitted: (_) => send(),
                                    decoration:
                                        _input('Say something in Serbian...'))),
                            const SizedBox(width: 8),
                            IconButton.filled(
                                onPressed: busy ? null : send,
                                icon: const Icon(Icons.send),
                                style: IconButton.styleFrom(
                                    backgroundColor: lime, foregroundColor: bg))
                          ]))
                  ])))));
}
