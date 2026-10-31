import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
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
  final String theoryTitle, theoryBody, unitTitle, level;
  final List<List<String>> vocabulary;
  const Lesson(
      this.id, this.title, this.subtitle, this.icon, this.color, this.questions,
      {this.theoryTitle = '',
      this.theoryBody = '',
      this.unitTitle = '',
      this.level = 'A1',
      this.vocabulary = const []});
}

class Question {
  final String type, prompt, answer, detail;
  final List<String> options;
  const Question(
      this.type, this.prompt, this.answer, this.options, this.detail);
}

var lessons = <Lesson>[
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
        'Arrange the words',
        'Good day',
        'Dobar dan',
        ['dan', 'Dobar', 'noć', 'Hvala'],
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
        'Arrange the words',
        'My name is Ana.',
        'Zovem se Ana',
        ['Ana', 'se', 'Zovem', 'Ja', 'sam'],
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
    Question('Type the answer', 'Write “thank you” in Serbian', 'Hvala', [],
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
    Question(
        'Choose the image',
        'Which one is “kafa”?',
        '☕ Coffee',
        ['💧 Water', '☕ Coffee', '🥛 Milk', '🍞 Bread'],
        'Kafa means coffee. The accusative is kafu when ordering.'),
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
    Question('Arrange the words', 'My sister', 'Moja sestra',
        ['sestra', 'Moj', 'Moja', 'brat'], 'Sestra is feminine, so use moja.'),
  ]),
];
var words = <List<String>>[
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
var wordLesson = <String>[
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

void applyCourse(Map<String, dynamic> course) {
  if (course['schemaVersion'] != 1 || course['status'] != 'published') return;
  final units = (course['units'] as List).cast<Map<String, dynamic>>();
  final parsed = <Lesson>[];
  final parsedWords = <List<String>>[];
  final lessonWords = <String>[];
  for (final unit in units) {
    for (final data in (unit['lessons'] as List).cast<Map<String, dynamic>>()) {
      final vocabulary = (data['vocabulary'] as List).map((raw) {
        final entry = raw as Map<String, dynamic>;
        return [
          entry['latin'],
          entry['cyrillic'],
          entry['english'],
          entry['pronunciation']
        ].cast<String>();
      }).toList();
      parsed.add(Lesson(
          data['id'],
          data['title'],
          data['subtitle'],
          data['icon'],
          data['color'],
          (data['challenges'] as List).map((raw) {
            final item = raw as Map<String, dynamic>;
            return Question(item['type'], item['prompt'], item['answer'],
                (item['options'] as List).cast<String>(), item['explanation']);
          }).toList(),
          theoryTitle: data['theory']['title'],
          theoryBody: data['theory']['body'],
          unitTitle: unit['title'],
          level: unit['level'],
          vocabulary: vocabulary));
      for (final word in vocabulary) {
        if (parsedWords.any(
            (existing) => existing[0].toLowerCase() == word[0].toLowerCase()))
          continue;
        parsedWords.add(word);
        lessonWords.add(data['id']);
      }
    }
  }
  if (parsed.isEmpty) return;
  lessons = parsed;
  words = parsedWords;
  wordLesson = lessonWords;
}

class KristinaApp extends StatefulWidget {
  const KristinaApp({super.key});
  @override
  State<KristinaApp> createState() => _KristinaAppState();
}

class _KristinaAppState extends State<KristinaApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
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
    try {
      final bundled =
          await rootBundle.loadString('assets/course/serbian-en.v1.json');
      applyCourse(jsonDecode(bundled) as Map<String, dynamic>);
    } catch (_) {}
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
    try {
      final response = await http.get(api('/api/course/catalog'));
      if (response.statusCode == 200 && mounted) {
        setState(() => applyCourse(
            (jsonDecode(response.body) as Map<String, dynamic>)['course']));
      }
    } catch (_) {}
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
              'courseId': 'serbian-en',
              'score': 10 + correct * 5,
              'answers': answers,
              'words': lesson.vocabulary.map((word) => word[0]).toList()
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
    navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) =>
            LessonPage(lesson: l, onComplete: (n, a) => finish(l, n, a))));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        navigatorKey: navigatorKey,
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
                                      onChat: () => navigatorKey.currentState
                                          ?.push(MaterialPageRoute(
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

class SassyKristina extends StatefulWidget {
  final double width, height;
  const SassyKristina({super.key, required this.width, required this.height});
  @override
  State<SassyKristina> createState() => _SassyKristinaState();
}

class _SassyKristinaState extends State<SassyKristina>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion;
  @override
  void initState() {
    super.initState();
    motion = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2100))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: motion,
      builder: (_, child) => Transform.translate(
          offset: Offset(0, -6 * motion.value),
          child: Transform.rotate(
              angle: (motion.value - .5) * .035, child: child)),
      child: Image.asset('assets/kristina-pose.png',
          width: widget.width, height: widget.height, fit: BoxFit.contain));
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
    final nextLesson = next < 0 ? lessons.last : lessons[next];
    final completedCount =
        lessons.where((lesson) => done.contains(lesson.id)).length;
    final section = lessons
            .take(lessons.indexOf(nextLesson))
            .map((lesson) => lesson.unitTitle)
            .toSet()
            .length +
        1;
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
        children: [
          Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                                color: panel2,
                                borderRadius: BorderRadius.circular(13)),
                            child: const Center(
                                child: Text('🇷🇸',
                                    style: TextStyle(fontSize: 24)))),
                        const SizedBox(width: 10),
                        const Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('LEARNING',
                                  style: TextStyle(
                                      color: muted,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9,
                                      letterSpacing: 1.4)),
                              Text('Serbian',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17)),
                            ])),
                        _stat('🔥', '$streak', const Color(0xFFFFB654)),
                        const SizedBox(width: 8),
                        _stat('⚡', '$xp', lime),
                      ]),
                      const SizedBox(height: 24),
                      const Text('Your journey',
                          style: TextStyle(
                              fontSize: 30, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      const Text(
                          'One small win at a time. Kristina is watching. 👀',
                          style: TextStyle(color: muted, fontSize: 13)),
                      const SizedBox(height: 20),
                      Container(
                          height: 190,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7854DD),
                                    Color(0xFF4E74D5)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(25)),
                          child: Stack(children: [
                            Positioned(
                                right: -25,
                                top: -20,
                                child: Container(
                                    width: 195,
                                    height: 215,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white
                                            .withValues(alpha: .08)))),
                            Positioned(
                                right: -9,
                                bottom: -28,
                                child: const SassyKristina(
                                    width: 165, height: 220)),
                            Positioned(
                                left: 20,
                                top: 21,
                                bottom: 20,
                                right: 155,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'SECTION $section  ·  ${nextLesson.level}',
                                          style: TextStyle(
                                              color: Color(0xFFE8DCFF),
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.5,
                                              fontSize: 10)),
                                      const SizedBox(height: 6),
                                      Text(
                                          nextLesson.unitTitle.isEmpty
                                              ? 'First words,\nbig energy'
                                              : nextLesson.unitTitle,
                                          style: TextStyle(
                                              fontSize: 25,
                                              fontWeight: FontWeight.w900,
                                              height: 1.05)),
                                      const Spacer(),
                                      Text(
                                          '$completedCount of ${lessons.length} lessons complete',
                                          style: const TextStyle(
                                              color: Color(0xFFE9DDFF),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 11)),
                                      const SizedBox(height: 7),
                                      ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                              value: completedCount /
                                                  lessons.length,
                                              minHeight: 8,
                                              backgroundColor: Colors.white
                                                  .withValues(alpha: .25),
                                              valueColor:
                                                  const AlwaysStoppedAnimation(
                                                      lime))),
                                    ])),
                          ])),
                      const SizedBox(height: 13),
                      KCard(
                          color: const Color(0xFF263E37),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 13),
                          child: Row(children: [
                            const Kristina(size: 50),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(
                                    done.isEmpty
                                        ? '“Come on. I made the first lesson easy for you.”'
                                        : '“Look at you showing up. Keep that streak alive.”',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13))),
                          ])),
                      if (reviewLessonId != null &&
                          lessons.any((l) => l.id == reviewLessonId)) ...[
                        const SizedBox(height: 12),
                        KCard(
                            onTap: () => onLesson(lessons
                                .firstWhere((l) => l.id == reviewLessonId)),
                            color: const Color(0xFF4B3B2A),
                            padding: const EdgeInsets.all(15),
                            child: Row(children: [
                              const Text('🧠', style: TextStyle(fontSize: 26)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(
                                      'Kristina says: review ${lessons.firstWhere((l) => l.id == reviewLessonId).title}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900))),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: lime)
                            ])),
                      ],
                      const SizedBox(height: 27),
                      Row(children: [
                        Expanded(
                            child: Text(
                                nextLesson.unitTitle.isEmpty
                                    ? 'THE BASICS'
                                    : nextLesson.unitTitle.toUpperCase(),
                                style: TextStyle(
                                    color: lime,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.7))),
                        Text('$completedCount/${lessons.length}',
                            style: const TextStyle(
                                color: muted,
                                fontWeight: FontWeight.w900,
                                fontSize: 12)),
                      ]),
                      const SizedBox(height: 3),
                      const Text('Follow the path. Collect your wins.',
                          style: TextStyle(color: muted, fontSize: 12)),
                      const SizedBox(height: 12),
                      SizedBox(
                          height: lessons.length * 128.0 + 24,
                          child: LayoutBuilder(builder: (context, constraints) {
                            final center = constraints.maxWidth / 2;
                            return Stack(children: [
                              Positioned.fill(
                                  child: CustomPaint(
                                      painter:
                                          _PathLinePainter(completedCount))),
                              ...lessons.asMap().entries.map((e) {
                                final i = e.key, l = e.value;
                                final completed = done.contains(l.id);
                                final locked =
                                    i > 0 && !done.contains(lessons[i - 1].id);
                                final active = i == next;
                                final shift =
                                    [0.0, 74.0, 90.0, 0.0, -90.0, -74.0][i % 6];
                                return Positioned(
                                    top: i * 128.0 + 5,
                                    left: center + shift - 60,
                                    width: 120,
                                    child: Column(children: [
                                      GestureDetector(
                                          onTap: locked
                                              ? null
                                              : () => onLesson(l),
                                          child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 220),
                                              width: active ? 82 : 74,
                                              height: active ? 82 : 74,
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: locked
                                                      ? panel2
                                                      : completed
                                                          ? const Color(
                                                              0xFF5B9D2F)
                                                          : colorFor(l.color),
                                                  border: Border.all(
                                                      color: active
                                                          ? Colors.white
                                                          : Colors.white
                                                              .withValues(
                                                                  alpha: locked
                                                                      ? .07
                                                                      : .17),
                                                      width: active ? 4 : 2),
                                                  boxShadow: [
                                                    BoxShadow(
                                                        color: locked
                                                            ? Colors.transparent
                                                            : colorFor(l.color)
                                                                .withValues(
                                                                    alpha: .27),
                                                        blurRadius:
                                                            active ? 24 : 12,
                                                        offset:
                                                            const Offset(0, 8))
                                                  ]),
                                              child: Center(
                                                  child: Text(
                                                      locked
                                                          ? '🔒'
                                                          : completed
                                                              ? '✓'
                                                              : l.icon,
                                                      style: TextStyle(
                                                          fontSize: completed
                                                              ? 36
                                                              : 29,
                                                          color: bg,
                                                          fontWeight: FontWeight
                                                              .w900))))),
                                      const SizedBox(height: 8),
                                      Text(l.title,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: locked
                                                  ? muted
                                                  : Colors.white)),
                                      if (active)
                                        const Text('START HERE',
                                            style: TextStyle(
                                                color: lime,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.2)),
                                    ]));
                              }),
                            ]);
                          })),
                      const SizedBox(height: 4),
                      KCard(
                          onTap: () => onLesson(nextLesson),
                          color: const Color(0xFF294B38),
                          child: Row(children: [
                            Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                    color: lime,
                                    borderRadius: BorderRadius.circular(14)),
                                child: const Icon(Icons.play_arrow_rounded,
                                    color: bg, size: 30)),
                            const SizedBox(width: 13),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(
                                      next < 0
                                          ? 'Review your skills'
                                          : 'Continue: ${nextLesson.title}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900)),
                                  Text(nextLesson.subtitle,
                                      style: const TextStyle(
                                          color: muted, fontSize: 12)),
                                ])),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                color: lime, size: 18),
                          ])),
                      const SizedBox(height: 14),
                      KCard(
                          onTap: onChat,
                          color: const Color(0xFF302A49),
                          child: const Row(children: [
                            Text('💬', style: TextStyle(fontSize: 31)),
                            SizedBox(width: 13),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('Practice with Kristina',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900)),
                                  Text('A little chat goes a long way.',
                                      style: TextStyle(
                                          color: muted, fontSize: 12)),
                                ])),
                            Icon(Icons.chevron_right_rounded, color: purple),
                          ])),
                    ],
                  ))),
        ]);
  }

  Widget _stat(String icon, String value, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration:
          BoxDecoration(color: panel, borderRadius: BorderRadius.circular(13)),
      child: Text('$icon $value',
          style: TextStyle(
              color: color, fontWeight: FontWeight.w900, fontSize: 13)));
}

class _PathLinePainter extends CustomPainter {
  final int completed;
  _PathLinePainter(this.completed);
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width / 2;
    const shifts = [0.0, 74.0, 90.0, 0.0, -90.0, -74.0];
    final paint = Paint()
      ..color = const Color(0xFF425462)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final active = Paint()
      ..color = lime.withValues(alpha: .7)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < lessons.length - 1; i++) {
      final a = Offset(center + shifts[i % 6], i * 128.0 + 43);
      final b = Offset(center + shifts[(i + 1) % 6], (i + 1) * 128.0 + 43);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, a.dy + 58, b.dx, b.dy - 58, b.dx, b.dy);
      canvas.drawPath(path, i < completed ? active : paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PathLinePainter oldDelegate) =>
      completed != oldDelegate.completed;
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
  final List<String> picked = [];
  final TextEditingController typed = TextEditingController();
  String? selected;
  bool checked = false,
      showTheory = true,
      finished = false,
      submitting = false,
      lastCorrect = false;

  @override
  void dispose() {
    typed.dispose();
    super.dispose();
  }

  String get response {
    final q = widget.lesson.questions[index];
    if (q.type == 'Arrange the words') return picked.join(' ');
    if (q.type == 'Type the answer') return typed.text.trim();
    return selected ?? '';
  }

  bool get canCheck => response.trim().isNotEmpty;
  bool _matches(String value, String target) {
    String clean(String x) => x
        .toLowerCase()
        .replaceAll(RegExp(r'[.!?]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    return clean(value) == clean(target);
  }

  Future<void> _advance() async {
    if (submitting) return;
    final q = widget.lesson.questions[index];
    if (!checked) {
      if (!canCheck) return;
      FocusScope.of(context).unfocus();
      final right = _matches(response, q.answer);
      setState(() {
        checked = true;
        lastCorrect = right;
        answers.add(right);
        if (right) correct++;
      });
      return;
    }
    if (index < widget.lesson.questions.length - 1) {
      setState(() {
        index++;
        checked = false;
        selected = null;
        picked.clear();
        typed.clear();
      });
    } else {
      setState(() => submitting = true);
      await widget.onComplete(correct, answers);
      if (mounted)
        setState(() {
          finished = true;
          submitting = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.lesson.questions[index];
    final accent = colorFor(widget.lesson.color);
    return Scaffold(
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 660),
                    child: Column(children: [
                      Padding(
                          padding: const EdgeInsets.fromLTRB(15, 12, 20, 10),
                          child: Row(children: [
                            IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close_rounded),
                                tooltip: 'Leave lesson'),
                            const SizedBox(width: 6),
                            Expanded(
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                        value: finished
                                            ? 1
                                            : index /
                                                widget.lesson.questions.length,
                                        minHeight: 12,
                                        backgroundColor: panel2,
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                                lime)))),
                            const SizedBox(width: 13),
                            Text(
                                '${index + 1}/${widget.lesson.questions.length}',
                                style: const TextStyle(
                                    color: muted, fontWeight: FontWeight.w900)),
                          ])),
                      Expanded(
                          child: finished
                              ? _complete(accent)
                              : showTheory &&
                                      widget.lesson.theoryBody.isNotEmpty
                                  ? SingleChildScrollView(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                '${widget.lesson.level} · ${widget.lesson.unitTitle}'
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                    color: lime,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 1.2)),
                                            const SizedBox(height: 18),
                                            Text(widget.lesson.theoryTitle,
                                                style: const TextStyle(
                                                    fontSize: 28,
                                                    fontWeight:
                                                        FontWeight.w900)),
                                            const SizedBox(height: 14),
                                            Text(widget.lesson.theoryBody,
                                                style: const TextStyle(
                                                    fontSize: 17, height: 1.5)),
                                            const SizedBox(height: 26),
                                            ...widget.lesson.vocabulary.map(
                                                (word) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 10),
                                                    child: KCard(
                                                        child: Row(children: [
                                                      Expanded(
                                                          child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                            Text(word[0],
                                                                style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w900,
                                                                    fontSize:
                                                                        18)),
                                                            Text(word[1],
                                                                style: const TextStyle(
                                                                    color:
                                                                        muted))
                                                          ])),
                                                      Text(word[2],
                                                          style: const TextStyle(
                                                              color: lime,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800))
                                                    ]))))
                                          ]))
                                  : SingleChildScrollView(
                                      key: ValueKey(index),
                                      padding: const EdgeInsets.fromLTRB(
                                          23, 22, 23, 18),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(children: [
                                              Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 7),
                                                  decoration: BoxDecoration(
                                                      color: accent.withValues(
                                                          alpha: .16),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10)),
                                                  child: Text(
                                                      q.type.toUpperCase(),
                                                      style: TextStyle(
                                                          color: accent,
                                                          fontSize: 10,
                                                          letterSpacing: 1.3,
                                                          fontWeight: FontWeight
                                                              .w900))),
                                              const Spacer(),
                                              Text(widget.lesson.title,
                                                  style: const TextStyle(
                                                      color: muted,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w800)),
                                            ]),
                                            const SizedBox(height: 22),
                                            Text(q.prompt,
                                                style: const TextStyle(
                                                    fontSize: 27,
                                                    height: 1.15,
                                                    fontWeight:
                                                        FontWeight.w900)),
                                            const SizedBox(height: 20),
                                            Row(children: [
                                              const Kristina(size: 54),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                  child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 14,
                                                          vertical: 11),
                                                      decoration: BoxDecoration(
                                                          color: panel2,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      16)),
                                                      child: Text(
                                                          checked
                                                              ? (lastCorrect
                                                                  ? 'That’s the stuff. Keep going! ✨'
                                                                  : 'Close! Here’s the answer. We’ll get it. 😏')
                                                              : 'Your turn, superstar.',
                                                          style: const TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800)))),
                                            ]),
                                            const SizedBox(height: 26),
                                            if (q.type == 'Arrange the words')
                                              _arrange(q)
                                            else if (q.type ==
                                                'Type the answer')
                                              _typeAnswer(q)
                                            else if (q.type ==
                                                'Choose the image')
                                              _images(q)
                                            else
                                              _choices(q),
                                          ]))),
                      if (!finished)
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(23, 14, 23, 20),
                            decoration: const BoxDecoration(
                                color: bg,
                                border: Border(top: BorderSide(color: panel2))),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!showTheory && checked) ...[
                                    Row(children: [
                                      Icon(
                                          lastCorrect
                                              ? Icons.check_circle_rounded
                                              : Icons.info_rounded,
                                          color: lastCorrect ? lime : pink),
                                      const SizedBox(width: 8),
                                      Text(
                                          lastCorrect
                                              ? 'Brilliant!'
                                              : 'Answer: ${q.answer}',
                                          style: TextStyle(
                                              color: lastCorrect ? lime : pink,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16))
                                    ]),
                                    const SizedBox(height: 5),
                                    Text(q.detail,
                                        style: const TextStyle(
                                            color: muted, fontSize: 12)),
                                    const SizedBox(height: 12),
                                  ],
                                  KButton(
                                      text: showTheory &&
                                              widget
                                                  .lesson.theoryBody.isNotEmpty
                                          ? 'START CHALLENGE'
                                          : submitting
                                              ? 'SAVING...'
                                              : checked
                                                  ? 'CONTINUE'
                                                  : 'CHECK ANSWER',
                                      onTap: showTheory &&
                                              widget
                                                  .lesson.theoryBody.isNotEmpty
                                          ? () =>
                                              setState(() => showTheory = false)
                                          : (checked || canCheck) && !submitting
                                              ? _advance
                                              : null,
                                      color: checked && !lastCorrect
                                          ? blue
                                          : lime),
                                ])),
                    ])))));
  }

  Widget _choices(Question q) => Column(
          children: q.options.asMap().entries.map((entry) {
        final option = entry.value;
        final isSelected = selected == option;
        final reveal = checked && option == q.answer;
        return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
                onTap: checked ? null : () => setState(() => selected = option),
                child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                        color: reveal
                            ? const Color(0xFF2D5939)
                            : isSelected
                                ? const Color(0xFF304D5B)
                                : panel,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: reveal
                                ? lime
                                : isSelected
                                    ? blue
                                    : panel2,
                            width: isSelected || reveal ? 2 : 1)),
                    child: Row(children: [
                      Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: isSelected ? blue : panel2,
                              borderRadius: BorderRadius.circular(8)),
                          child: Text('${entry.key + 1}',
                              style: TextStyle(
                                  color: isSelected ? bg : muted,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12))),
                      const SizedBox(width: 13),
                      Expanded(
                          child: Text(option,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16))),
                      if (reveal) const Icon(Icons.check_rounded, color: lime),
                    ]))));
      }).toList());
  Widget _images(Question q) => LayoutBuilder(builder: (context, box) {
        final width = (box.maxWidth - 12) / 2;
        return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: q.options.map((option) {
              final parts = option.split(' ');
              final isSelected = selected == option;
              final reveal = checked && option == q.answer;
              return GestureDetector(
                  onTap:
                      checked ? null : () => setState(() => selected = option),
                  child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: width,
                      height: 136,
                      decoration: BoxDecoration(
                          color: reveal ? const Color(0xFF2D5939) : panel,
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                              color: reveal
                                  ? lime
                                  : isSelected
                                      ? blue
                                      : panel2,
                              width: isSelected || reveal ? 3 : 1)),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(parts.first,
                                style: const TextStyle(fontSize: 49)),
                            const SizedBox(height: 8),
                            Text(parts.skip(1).join(' '),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 14)),
                          ])));
            }).toList());
      });
  Widget _arrange(Question q) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('BUILD THE SENTENCE',
            style: TextStyle(
                color: muted,
                fontSize: 10,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 83),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: picked.isEmpty ? panel2 : blue, width: 2)),
            child: picked.isEmpty
                ? const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Tap words below to build your answer',
                        style: TextStyle(color: muted, fontSize: 13)))
                : Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: picked
                        .map((word) => ActionChip(
                            onPressed: checked
                                ? null
                                : () => setState(() => picked.remove(word)),
                            backgroundColor: panel2,
                            side: const BorderSide(color: blue),
                            label: Text(word,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800))))
                        .toList())),
        const SizedBox(height: 22),
        Wrap(
            spacing: 9,
            runSpacing: 9,
            children: q.options
                .where((word) => !picked.contains(word))
                .map((word) => ActionChip(
                    onPressed:
                        checked ? null : () => setState(() => picked.add(word)),
                    backgroundColor: panel2,
                    side: const BorderSide(color: Color(0xFF48616E)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                    label: Text(word,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 15))))
                .toList()),
      ]);
  Widget _typeAnswer(Question q) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('WRITE IT IN SERBIAN',
            style: TextStyle(
                color: muted,
                fontSize: 10,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        TextField(
            controller: typed,
            enabled: !checked,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _advance(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            decoration: InputDecoration(
                hintText: 'Type your answer here',
                filled: true,
                fillColor: panel,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: blue, width: 2)))),
        const SizedBox(height: 12),
        const Text(
            'Tip: accents matter in Serbian, but case and punctuation do not.',
            style: TextStyle(color: muted, fontSize: 12)),
      ]);
  Widget _complete(Color accent) => SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(
            width: 220,
            height: 250,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: accent.withValues(alpha: .12)),
            child: const SassyKristina(width: 220, height: 250)),
        const SizedBox(height: 17),
        Text(
            correct == widget.lesson.questions.length
                ? 'PERFECT LESSON!'
                : 'LESSON COMPLETE!',
            style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2)),
        const SizedBox(height: 7),
        Text(
            correct == widget.lesson.questions.length
                ? 'Okay, show-off.'
                : 'You did it, superstar!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Kristina approves. She will deny saying that later.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 13)),
        const SizedBox(height: 25),
        Row(children: [
          Expanded(
              child:
                  _resultCard('⚡', '+${10 + correct * 5}', 'XP EARNED', lime)),
          const SizedBox(width: 10),
          Expanded(
              child: _resultCard(
                  '🎯',
                  '$correct/${widget.lesson.questions.length}',
                  'CORRECT',
                  blue)),
        ]),
        const SizedBox(height: 28),
        KButton(text: 'BACK TO THE PATH', onTap: () => Navigator.pop(context)),
      ]));
  Widget _resultCard(String icon, String number, String label, Color color) =>
      Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(17)),
          child: Column(children: [
            Text(icon, style: const TextStyle(fontSize: 27)),
            const SizedBox(height: 5),
            Text(number,
                style: TextStyle(
                    color: color, fontSize: 24, fontWeight: FontWeight.w900)),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1)),
          ]));
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
  final courseJson = TextEditingController();
  String level = 'A1', result = '', courseMessage = '';
  bool loading = false, courseBusy = false, reviewed = false;

  @override
  void dispose() {
    topic.dispose();
    objectives.dispose();
    courseJson.dispose();
    super.dispose();
  }

  Future<void> loadCourse() async {
    setState(() => courseBusy = true);
    try {
      final r = await http.get(api('/api/course/catalog'));
      final body = jsonDecode(r.body);
      if (r.statusCode != 200)
        throw Exception(body['error'] ?? 'Could not load course');
      courseJson.text =
          const JsonEncoder.withIndent('  ').convert(body['course']);
      setState(() => courseMessage =
          'Published course loaded. Edit the JSON, then save a draft.');
    } catch (e) {
      setState(() => courseMessage = '$e');
    } finally {
      setState(() => courseBusy = false);
    }
  }

  Future<void> saveCourse({required bool publish}) async {
    setState(() => courseBusy = true);
    try {
      final raw = jsonDecode(courseJson.text) as Map<String, dynamic>;
      final r = await http.post(api('/api/admin/courses'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({'course': raw}));
      final body = jsonDecode(r.body);
      if (r.statusCode != 200)
        throw Exception(body['error'] ?? 'Draft failed validation');
      if (publish) {
        if (!reviewed)
          throw Exception(
              'Review the Serbian content and check the confirmation first.');
        final response = await http.patch(api('/api/admin/courses'),
            headers: {
              'Authorization': 'Bearer ${widget.token}',
              'Content-Type': 'application/json'
            },
            body: jsonEncode({'id': raw['id'], 'reviewed': true}));
        final published = jsonDecode(response.body);
        if (response.statusCode != 200)
          throw Exception(published['error'] ?? 'Publish failed');
        setState(() {
          courseMessage =
              'Published version ${published['course']['version']}. Learners will see it after refresh.';
          reviewed = false;
        });
      } else {
        setState(() =>
            courseMessage = 'Draft saved. It is not visible to learners.');
      }
    } catch (e) {
      setState(() => courseMessage = '$e');
    } finally {
      setState(() => courseBusy = false);
    }
  }

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
                const SizedBox(height: 26),
                const PageHead(
                    eyebrow: 'Course publishing',
                    title: 'Review the course',
                    subtitle:
                        'Edit the versioned JSON. Publishing requires a human content review.'),
                const SizedBox(height: 12),
                KButton(
                    text: courseBusy ? 'WORKING...' : 'LOAD PUBLISHED COURSE',
                    onTap: courseBusy ? null : loadCourse),
                const SizedBox(height: 12),
                TextField(
                    controller: courseJson,
                    minLines: 8,
                    maxLines: 16,
                    style:
                        const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    decoration: _input('Course JSON')),
                const SizedBox(height: 12),
                KButton(
                    text: 'SAVE DRAFT',
                    onTap: courseBusy ? null : () => saveCourse(publish: false),
                    color: blue),
                CheckboxListTile(
                    value: reviewed,
                    onChanged: (value) =>
                        setState(() => reviewed = value ?? false),
                    title: const Text(
                        'I reviewed the Serbian content and answer keys'),
                    controlAffinity: ListTileControlAffinity.leading),
                KButton(
                    text: 'PUBLISH REVIEWED COURSE',
                    onTap: courseBusy || !reviewed
                        ? null
                        : () => saveCourse(publish: true),
                    color: lime),
                if (courseMessage.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(courseMessage,
                          style: const TextStyle(color: muted))),
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
