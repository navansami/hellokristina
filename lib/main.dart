import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'avatar/avatar_editor.dart';
import 'avatar/learner_look.dart';
import 'avatar/learner_portrait.dart';
import 'widgets/animated_kristina.dart';
import 'widgets/tactile_button.dart';
import 'widgets/learning_object.dart';
import 'widgets/word_hints.dart';
import 'feedback/learning_feedback.dart';
import 'feedback/feedback_settings.dart';
import 'practice/object_bank.dart';
import 'speech/serbian_speech.dart';
import 'speech/speech_match.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

part 'practice/round_sampler.dart';
part 'practice/practice_memory.dart';

const bg = Color(0xFF131F24),
    panel = Color(0xFF192A32),
    panel2 = Color(0xFF2C404B),
    lime = Color(0xFF78D72D),
    blue = Color(0xFF49C0F8),
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
  final String theoryTitle, theoryBody, unitTitle, level, kind;
  final int minPassPercent;
  final List<List<String>> vocabulary;
  const Lesson(
      this.id, this.title, this.subtitle, this.icon, this.color, this.questions,
      {this.theoryTitle = '',
      this.theoryBody = '',
      this.unitTitle = '',
      this.level = 'A1',
      this.kind = 'challenge',
      this.minPassPercent = 0,
      this.vocabulary = const []});
}

class Question {
  final String type, prompt, answer, detail;
  final String id, audioText, audioAsset, translation, answerLanguage;
  final List<String> options;
  const Question(this.type, this.prompt, this.answer, this.options, this.detail,
      {this.id = '',
      this.audioText = '',
      this.audioAsset = '',
      this.translation = '',
      this.answerLanguage = ''});

  Question copy({String? id, List<String>? options}) => Question(
      type, prompt, answer, options ?? this.options, detail,
      id: id ?? this.id,
      audioText: audioText,
      audioAsset: audioAsset,
      translation: translation,
      answerLanguage: answerLanguage);
}

var lessons = <Lesson>[
  Lesson('hello', 'Say hello', 'Start with the essentials', '👋', 'green', [
    Question(
        'Arrange the words',
        'Zdravo',
        'Hello',
        ['Hello', 'Goodbye', 'Please', 'Thanks'],
        'Zdravo (Здраво) is a friendly, everyday hello.',
        answerLanguage: 'en'),
    Question('Arrange the words', 'Hello', 'Zdravo',
        ['Hvala', 'Zdravo', 'Da', 'Ne'], 'Nice! Zdravo works any time of day.',
        answerLanguage: 'sr'),
    Question(
        'Arrange the words',
        'Hvala',
        'Thank you',
        ['Thank', 'you', 'Good', 'night', 'Sorry'],
        'Hvala (Хвала) means thank you.',
        answerLanguage: 'en'),
    Question(
        'Arrange the words',
        'Good day',
        'Dobar dan',
        ['dan', 'Dobar', 'noć', 'Hvala'],
        'Dobar dan is a polite daytime greeting.',
        answerLanguage: 'sr'),
  ]),
  Lesson('introductions', 'Meet & greet', 'Make a first impression', '💬',
      'blue', [
    Question(
        'Arrange the words',
        'Ja sam Kristina',
        'I am Kristina',
        ['I', 'am', 'Kristina', 'You', 'are', 'Hello'],
        'Ja sam means “I am”.',
        answerLanguage: 'en'),
    Question(
        'Arrange the words',
        'My name is Ana.',
        'Zovem se Ana',
        ['Ana', 'se', 'Zovem', 'Ja', 'sam'],
        'Zovem se literally means “I call myself”.',
        answerLanguage: 'sr'),
    Question(
        'Arrange the words',
        'Kako se zoveš?',
        'What is your name',
        ['What', 'is', 'your', 'name', 'How', 'are', 'you'],
        'Zoveš is the informal “you are called”.',
        answerLanguage: 'en'),
  ]),
  Lesson('polite', 'Be polite', 'Small words, big charm', '✨', 'pink', [
    Question('Arrange the words', 'Please', 'Molim',
        ['Izvini', 'Molim', 'Hvala', 'Ćao'],
        'Molim can also mean “you’re welcome”.',
        answerLanguage: 'sr'),
    Question('Arrange the words', 'Izvini', 'Sorry',
        ['Please', 'Goodbye', 'Sorry', 'Yes'], 'Use izvini with someone you know.',
        answerLanguage: 'en'),
    Question('Arrange the words', 'Thank you', 'Hvala',
        ['Hvala', 'Molim', 'Zdravo', 'Da'],
        'Hvala puno is a common way to thank someone warmly.',
        answerLanguage: 'sr'),
  ]),
  Lesson('numbers', 'Count on me', 'Numbers 1 to 10', '🔢', 'purple', [
    Question('Arrange the words', 'jedan', 'one',
        ['three', 'one', 'five', 'two'], 'Jedan means one.',
        answerLanguage: 'en'),
    Question('Arrange the words', 'dva', 'two',
        ['one', 'four', 'two', 'seven'], 'Dva means two.',
        answerLanguage: 'en'),
    Question('Arrange the words', 'Three', 'tri',
        ['pet', 'deset', 'tri', 'šest'], 'Tri means three.',
        answerLanguage: 'sr'),
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
    Question('Arrange the words', 'majka', 'mother',
        ['father', 'sister', 'mother', 'brother'],
        'Majka is mother; mama is also common.',
        answerLanguage: 'en'),
    Question('Arrange the words', 'brat', 'brother',
        ['brother', 'father', 'friend', 'son'], 'Brat means brother.',
        answerLanguage: 'en'),
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
          entry['pronunciation'],
          entry['audio'] ?? '',
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
                (item['options'] as List).cast<String>(), item['explanation'],
                id: item['id'] ?? '',
                audioText: item['audioText'] ?? '',
                audioAsset: item['audio'] ?? '',
                translation: item['translation'] ?? '',
                answerLanguage: item['answerLanguage'] ?? '');
          }).toList(),
          theoryTitle: data['theory']['title'],
          theoryBody: data['theory']['body'],
          unitTitle: unit['title'],
          level: unit['level'],
          kind: data['type'] ?? 'challenge',
          minPassPercent: data['minPassPercent'] ?? 0,
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

class _KristinaAppState extends State<KristinaApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  int tab = 0, xp = 0, streak = 0;
  Set<String> done = {}, completedRounds = {};
  String? reviewLessonId;
  String? token;
  Map<String, dynamic>? user;
  LearnerLook avatar = const LearnerLook();
  bool loading = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      learningFeedback.stopSounds();
      learningFeedback.cancelHaptics();
      SerbianAudio.stop();
      SerbianSpeech.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    await learningFeedback.load();
    await SerbianAudio.loadWordIndex();
    try {
      final bundled =
          await rootBundle.loadString('assets/course/serbian-en.v1.json');
      applyCourse(jsonDecode(bundled) as Map<String, dynamic>);
    } catch (_) {}
    final p = await SharedPreferences.getInstance();
    setState(() {
      done = (p.getStringList('done') ?? []).toSet();
      completedRounds = (p.getStringList('completedRounds') ?? []).toSet();
      xp = p.getInt('xp') ?? 0;
      streak = p.getInt('streak') ?? 0;
      token = p.getString('token');
      SharedToken.value = token;
      avatar = _storedLook(p);
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

  LearnerLook _storedLook(SharedPreferences prefs) {
    final raw = prefs.getString('avatarLook');
    if (raw == null || raw.isEmpty) return const LearnerLook();
    try {
      return LearnerLook.decode(jsonDecode(raw));
    } catch (_) {
      return const LearnerLook();
    }
  }

  void _applyAvatar(Map<String, dynamic>? account) {
    final stored = account?['avatar'];
    if (stored is! Map || stored['look'] is! Map) return;
    avatar = LearnerLook.decode(stored['look']);
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
        completedRounds.addAll(
            (progress?['completedRounds'] as List? ?? []).cast<String>());
        final suggestion = jsonDecode(r.body)['recommendation'];
        reviewLessonId = suggestion?['reason'] == 'review'
            ? suggestion['lessonId'] as String?
            : null;
        xp = (user?['xp'] as num?)?.toInt() ?? xp;
        streak = (user?['streak'] as num?)?.toInt() ?? streak;
      });
      final p = await SharedPreferences.getInstance();
      await p.setStringList('done', done.toList());
      await p.setStringList('completedRounds', completedRounds.toList());
      await p.setInt('xp', xp);
      await p.setInt('streak', streak);
    } catch (_) {}
  }

  Future<void> finish(
      Lesson lesson, int correct, List<bool> answers, int roundIndex) async {
    final passed = correct * 100 >= lesson.minPassPercent * answers.length;
    final roundKey = '${lesson.id}:$roundIndex';
    final first =
        !done.contains(lesson.id) && !completedRounds.contains(roundKey);
    setState(() {
      if (passed) {
        completedRounds.add(roundKey);
        if (List.generate(5, (i) => '${lesson.id}:$i')
            .every(completedRounds.contains)) done.add(lesson.id);
      }
      if (passed && first) xp += (10 + correct * 5).clamp(0, 30);
      streak = streak == 0 ? 1 : streak;
    });
    final p = await SharedPreferences.getInstance();
    await p.setStringList('done', done.toList());
    await p.setStringList('completedRounds', completedRounds.toList());
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
              'roundIndex': roundIndex,
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
    await p.remove('completedRounds');
    await p.remove('xp');
    await p.remove('streak');
    setState(() {
      token = data['token'];
      user = data['user'];
      done = {};
      completedRounds = {};
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
    await p.remove('completedRounds');
    await p.remove('xp');
    await p.remove('streak');
    setState(() {
      token = null;
      user = null;
      done = {};
      completedRounds = {};
      xp = 0;
      streak = 0;
      reviewLessonId = null;
      SharedToken.value = null;
    });
  }

  Future<void> changeAvatar(LearnerLook look) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('avatarLook', jsonEncode(look.toJson()));
    setState(() => avatar = look);
    if (token != null) {
      try {
        await http.patch(api('/api/auth/profile'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json'
            },
            body: jsonEncode({
              'avatar': {
                'face': 'built',
                'color': look.backgroundHex,
                'look': look.toJson()
              }
            }));
      } catch (_) {}
    }
  }

  Future<void> lesson(Lesson l, [int? requestedRound]) async {
    final roundIndex = requestedRound ??
        List.generate(5, (i) => i).firstWhere(
            (i) => !completedRounds.contains('${l.id}:$i'),
            orElse: () => 4);
    final completedBefore =
        done.contains(l.id) || completedRounds.contains('${l.id}:$roundIndex');
    final memory = await PracticeMemory.load();
    final deal = buildPracticeRound(l, memory, math.Random());
    final practice = Lesson(
        l.id,
        '${l.title} · ${roundIndex + 1}/5',
        l.subtitle,
        l.icon,
        l.color,
        deal.questions.isEmpty ? l.questions : deal.questions,
        theoryTitle: l.theoryTitle,
        theoryBody: roundIndex == 0 ? l.theoryBody : '',
        unitTitle: l.unitTitle,
        level: l.level,
        kind: l.kind,
        minPassPercent: l.minPassPercent,
        vocabulary: l.vocabulary);
    navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => LessonPage(
            lesson: practice,
            alreadyCompleted: completedBefore,
            practiceRound: roundIndex,
            replacements: deal.bench,
            onRetry: () => lesson(l, roundIndex),
            onComplete: (n, a) => finish(l, n, a, roundIndex))));
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
                                      completedRounds: completedRounds,
                                      look: avatar,
                                      onProfile: () => setState(() => tab = 4),
                                      reviewLessonId: reviewLessonId,
                                      xp: xp,
                                      streak: streak,
                                      onLesson: lesson,
                                      onChat: () => navigatorKey.currentState
                                          ?.push(MaterialPageRoute(
                                              builder: (_) =>
                                                  ChatPage(token: token)))),
                                  WordsPage(done: {
                                    ...done,
                                    ...completedRounds.map((key) =>
                                        key.substring(0, key.lastIndexOf(':')))
                                  }),
                                  LettersPage(),
                                  FriendsPage(token: token),
                                  ProfilePage(
                                      user: user,
                                      xp: xp,
                                      streak: streak,
                                      done: done,
                                      look: avatar,
                                      onAvatar: changeAvatar,
                                      onClose: () => setState(() => tab = 0),
                                      onFriends: () => setState(() => tab = 3),
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

class SerbianAudio {
  static final AudioPlayer _player = AudioPlayer();
  static final FlutterTts _tts = FlutterTts();
  static final ValueNotifier<bool> speaking = ValueNotifier(false);
  static Map<String, String> _wordAssets = {};
  static Future<void>? _wordLoading;
  static int _generation = 0;
  static bool _wired = false;
  static String wordKey(String text) =>
      text.toLowerCase().replaceAll(RegExp(r'[.,!?;:“”"()]'), '').trim();
  static Future<void> loadWordIndex() => _wordLoading ??= _loadWordIndex();
  static Future<void> _loadWordIndex() async {
    try {
      _wordAssets = (jsonDecode(await rootBundle.loadString(
              'assets/audio/serbian/word-index.json')) as Map<String, dynamic>)
          .cast<String, String>();
    } catch (_) {}
  }

  static void _wire() {
    if (_wired) return;
    _wired = true;
    _player.onPlayerStateChanged
        .listen((state) => speaking.value = state == PlayerState.playing);
    _tts.setStartHandler(() => speaking.value = true);
    _tts.setCompletionHandler(() => speaking.value = false);
    _tts.setErrorHandler((_) {
      speaking.value = false;
    });
  }

  static Future<void> speakWord(String text) async {
    final generation = ++_generation;
    await loadWordIndex();
    if (generation != _generation || !learningFeedback.spokenWords) return;
    try {
      await play(text, _wordAssets[wordKey(text)] ?? '');
    } catch (_) {}
  }

  static Future<void> stop() async {
    _generation++;
    speaking.value = false;
    try {
      await _player.stop();
      await _tts.stop();
    } catch (_) {}
  }

  static Future<void> play(String text, String asset,
      {bool slow = false}) async {
    final generation = ++_generation;
    _wire();
    await learningFeedback.stopSounds();
    speaking.value = false;
    await _player.stop();
    await _tts.stop();
    if (generation != _generation) return;
    if (asset.isNotEmpty) {
      try {
        await _player.setPlaybackRate(slow ? 0.75 : 1.0);
        await _player.setSource(AssetSource(asset));
        if (generation != _generation) return;
        await _player.resume();
        return;
      } catch (_) {}
    }
    final available = await _tts.isLanguageAvailable('sr-RS');
    if (available != true && available != 1)
      throw StateError('Serbian audio is not available on this device yet.');
    if (generation != _generation) return;
    await _tts.setLanguage('sr-RS');
    await _tts.setSpeechRate(slow ? 0.32 : 0.45);
    if (generation == _generation) await _tts.speak(text);
  }
}

class SerbianAudioButton extends StatelessWidget {
  final String text, asset;
  final Color color;
  final bool slow;
  const SerbianAudioButton(
      {super.key,
      required this.text,
      this.asset = '',
      this.color = blue,
      this.slow = false});

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
      style: IconButton.styleFrom(
          backgroundColor: panel,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: panel2, width: 2))),
      tooltip: slow ? 'Play Serbian slowly' : 'Play Serbian pronunciation',
      icon: Icon(
          slow ? Icons.slow_motion_video_rounded : Icons.volume_up_rounded),
      color: color,
      onPressed: () async {
        try {
          await SerbianAudio.play(text, asset, slow: slow);
        } catch (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('$error')));
          }
        }
      });
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
  Widget build(BuildContext context) => TactileButton(
      label: text,
      onTap: onTap,
      color: outline ? panel : color,
      foreground: outline ? Colors.white : bg,
      outline: outline);
}

class Kristina extends StatelessWidget {
  final double size;
  final String mood;
  const Kristina({super.key, this.size = 92, this.mood = 'idle'});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: size,
      height: size,
      child: ClipRect(
          child: OverflowBox(
              alignment: Alignment.topCenter,
              maxWidth: size * 1.7,
              maxHeight: size * 2.55,
              child: AnimatedKristina(
                  width: size * 1.7, height: size * 2.55, mood: mood))));
}

class SassyKristina extends StatelessWidget {
  final double width, height;
  final String mood;
  const SassyKristina(
      {super.key,
      required this.width,
      required this.height,
      this.mood = 'idle'});
  @override
  Widget build(BuildContext context) =>
      AnimatedKristina(width: width, height: height, mood: mood);
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

class PathPage extends StatefulWidget {
  final Set<String> done, completedRounds;
  final String? reviewLessonId;
  final int xp, streak;
  final LearnerLook look;
  final void Function(Lesson, int) onLesson;
  final VoidCallback onChat, onProfile;
  const PathPage(
      {super.key,
      required this.done,
      required this.completedRounds,
      required this.reviewLessonId,
      required this.xp,
      required this.streak,
      required this.onLesson,
      required this.onChat,
      required this.look,
      required this.onProfile});
  @override
  State<PathPage> createState() => _PathPageState();
}

class _PathPageState extends State<PathPage> {
  final ScrollController scroll = ScrollController();
  String? _alignedLessonId;
  int _alignTries = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showActiveSection());
  }

  @override
  void didUpdateWidget(PathPage old) {
    super.didUpdateWidget(old);
    final lesson = _activeLesson();
    if (lesson != null && lesson.id != _alignedLessonId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showActiveSection());
    }
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  Lesson? _activeLesson() {
    if (lessons.isEmpty) return null;
    final next = lessons.indexWhere((l) => !widget.done.contains(l.id));
    return next < 0 ? lessons.last : lessons[next];
  }

  /// Scroll offset where [lesson] sits just under its pinned section title.
  double _offsetForLesson(Lesson lesson) {
    final titles = lessons.map((l) => l.unitTitle).toSet().toList();
    final unitIndex = titles.indexOf(lesson.unitTitle);
    if (unitIndex < 0) return 0;
    var offset = 0.0;
    for (var i = 0; i < unitIndex; i++) {
      final count = lessons.where((l) => l.unitTitle == titles[i]).length;
      offset += _sectionHeaderExtent + count * 148.0 + 30;
    }
    final indexInUnit = lessons
        .where((l) => l.unitTitle == lesson.unitTitle)
        .toList()
        .indexWhere((item) => item.id == lesson.id);
    if (indexInUnit > 0) offset += indexInUnit * 148.0;
    return offset;
  }

  void _showActiveSection() {
    final lesson = _activeLesson();
    if (!mounted || lesson == null || _alignedLessonId == lesson.id) return;
    if (!scroll.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showActiveSection());
      return;
    }
    final offset = _offsetForLesson(lesson);
    final max = scroll.position.maxScrollExtent;
    if (offset > 0 && max == 0 && _alignTries < 3) {
      _alignTries++;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showActiveSection());
      return;
    }
    scroll.jumpTo(offset.clamp(0.0, max));
    _alignedLessonId = lesson.id;
  }

  Color _sectionColor(int unitIndex) =>
      [lime, blue, purple, const Color(0xFFFFAD55), pink][unitIndex % 5];

  int count(Lesson lesson) => widget.done.contains(lesson.id)
      ? 5
      : List.generate(5, (i) => '${lesson.id}:$i')
          .where(widget.completedRounds.contains)
          .length;
  void open(Lesson lesson) {
    final total = count(lesson);
    showModalBottomSheet(
        context: context,
        backgroundColor: panel,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        builder: (context) => SafeArea(
            child: SingleChildScrollView(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                              color: muted.withValues(alpha: .4),
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 20),
                      Text(lesson.title,
                          style: const TextStyle(
                              fontSize: 25, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 5),
                      Text('$total of 5 practice sessions complete',
                          style: const TextStyle(color: muted)),
                      const SizedBox(height: 20),
                      ...List.generate(5, (i) {
                        final complete = widget.done.contains(lesson.id) ||
                            widget.completedRounds.contains('${lesson.id}:$i');
                        final available = complete || i == total;
                        return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                                enabled: available,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                        color: available ? panel2 : panel)),
                                leading: Icon(
                                    complete
                                        ? Icons.check_circle_rounded
                                        : available
                                            ? Icons.play_circle_fill_rounded
                                            : Icons.lock_outline_rounded,
                                    color: complete
                                        ? lime
                                        : available
                                            ? blue
                                            : muted),
                                title: Text('Practice ${i + 1}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color:
                                            available ? Colors.white : muted)),
                                subtitle: Text(
                                    i == 0
                                        ? 'Learn the words and phrases'
                                        : 'Revisit the words in a mixed order',
                                    style: const TextStyle(
                                        color: muted, fontSize: 12)),
                                trailing: Text('${i + 1}/5',
                                    style: const TextStyle(color: muted)),
                                onTap: available
                                    ? () {
                                        Navigator.pop(context);
                                        widget.onLesson(lesson, i);
                                      }
                                    : null));
                      }),
                    ])))));
  }

  void selectCourse() => showModalBottomSheet(
      context: context,
      backgroundColor: panel,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (context) => SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your courses',
                        style: TextStyle(
                            fontSize: 25, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 18),
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const _SerbianFlag(width: 54),
                        title: const Text('For English speakers',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 18)),
                        trailing:
                            const Icon(Icons.check_circle_rounded, color: lime),
                        onTap: () => Navigator.pop(context)),
                    const SizedBox(height: 16),
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.forum_rounded, color: blue),
                        title: const Text('Practice with Kristina'),
                        onTap: () {
                          Navigator.pop(context);
                          widget.onChat();
                        }),
                    const Text('More languages are on the way.',
                        style: TextStyle(color: muted)),
                  ]))));
  @override
  Widget build(BuildContext context) {
    final titles = lessons.map((l) => l.unitTitle).toSet().toList();
    final next = lessons.indexWhere((l) => !widget.done.contains(l.id));
    return Column(children: [
      // The learner identity stays fixed. Section titles pin inside the trail.
      Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: const BoxDecoration(
              color: bg, border: Border(bottom: BorderSide(color: panel2))),
          child: Row(children: [
            Tooltip(
                message: 'Your profile',
                child: InkWell(
                    onTap: widget.onProfile,
                    borderRadius: BorderRadius.circular(22),
                    child: LearnerBadge(look: widget.look))),
            const SizedBox(width: 16),
            Expanded(
                child: MergeSemantics(
                    child: InkWell(
                        onTap: selectCourse,
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _SerbianFlag(width: 42),
                                  Icon(Icons.expand_more_rounded,
                                      color: muted, size: 22)
                                ]))))),
            const SizedBox(width: 8),
            const Icon(Icons.local_fire_department_rounded,
                color: Color(0xFFFF9A43), size: 30),
            Text('${widget.streak}',
                style: const TextStyle(
                    color: Color(0xFFFFAB56),
                    fontWeight: FontWeight.w900,
                    fontSize: 18)),
            const SizedBox(width: 12),
            const Icon(Icons.bolt_rounded, color: Color(0xFFFFD454), size: 25),
            Text('${widget.xp}',
                style: const TextStyle(
                    color: Color(0xFFFFD454),
                    fontWeight: FontWeight.w900,
                    fontSize: 15)),
          ])),
      Expanded(
          child: CustomScrollView(controller: scroll, slivers: [
        for (var unitIndex = 0; unitIndex < titles.length; unitIndex++)
          ..._sectionSlivers(unitIndex, titles, next),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ])),
    ]);
  }

  List<Widget> _sectionSlivers(int unitIndex, List<String> titles, int next) {
    final unit =
        lessons.where((l) => l.unitTitle == titles[unitIndex]).toList();
    final color = _sectionColor(unitIndex);
    return [
      SliverMainAxisGroup(slivers: [
        SliverPersistentHeader(
            pinned: true,
            delegate: _SectionHeaderDelegate(
                title: titles[unitIndex],
                level: unit.first.level,
                index: unitIndex,
                color: color)),
        SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _unitTrail(unit, unitIndex, next, color))),
      ])
    ];
  }

  Widget _unitTrail(List<Lesson> unit, int unitIndex, int next, Color color) =>
      LayoutBuilder(builder: (context, constraints) {
        final center = constraints.maxWidth / 2;
        return SizedBox(
                            height: unit.length * 148.0 + 30,
                            child: Stack(children: [
                              Positioned.fill(
                                  child: CustomPaint(
                                      painter: _TrailLinePainter(
                                          unit.length, color))),
                              ...unit.asMap().entries.map((entry) {
                                final i = entry.key,
                                    l = entry.value,
                                    global = lessons.indexOf(entry.value);
                                final locked = global > 0 &&
                                    !widget.done
                                        .contains(lessons[global - 1].id) &&
                                    !widget.done.contains(l.id);
                                final active = global == next;
                                final shift = [
                                  0.0,
                                  62.0,
                                  82.0,
                                  24.0,
                                  -62.0,
                                  -82.0,
                                  0.0
                                ][i % 7];
                                return Positioned(
                                    top: i * 148.0 + 10,
                                    left: center + shift - 72,
                                    width: 144,
                                    child: Column(children: [
                                      if (active)
                                        Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 5),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                                color: panel,
                                                borderRadius:
                                                    BorderRadius.circular(9),
                                                border: Border.all(
                                                    color: color, width: 2)),
                                            child: Text(
                                                count(l) == 0
                                                    ? 'START'
                                                    : 'CONTINUE',
                                                style: TextStyle(
                                                    color: color,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w900))),
                                      Semantics(
                                          button: true,
                                          label:
                                              '${l.title}, ${count(l)} of 5 sessions complete${locked ? ', locked' : ''}',
                                          child: GestureDetector(
                                              onTap:
                                                  locked ? null : () => open(l),
                                              child: SizedBox(
                                                  width: 86,
                                                  height: 86,
                                                  child: CustomPaint(
                                                      painter:
                                                          _TrailCirclePainter(
                                                              count(l),
                                                              locked
                                                                  ? panel2
                                                                  : color,
                                                              locked),
                                                      child: Center(
                                                          child: Icon(
                                                              locked
                                                                  ? Icons
                                                                      .lock_rounded
                                                                  : count(l) ==
                                                                          5
                                                                      ? Icons
                                                                          .check_rounded
                                                                      : l.kind ==
                                                                              'assessment'
                                                                          ? Icons
                                                                              .emoji_events_rounded
                                                                          : l.kind ==
                                                                                  'checkpoint'
                                                                              ? Icons
                                                                                  .fitness_center_rounded
                                                                              : Icons
                                                                                  .star_rounded,
                                                              color: locked
                                                                  ? const Color(
                                                                      0xFF617780)
                                                                  : Colors
                                                                      .white,
                                                              size: 38)))))),
                                      const SizedBox(height: 7),
                                      Text(l.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color:
                                                  locked ? muted : Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                              height: 1.15)),
                                      if (count(l) > 0 && count(l) < 5)
                                        Text('${count(l)}/5',
                                            style: TextStyle(
                                                color: color,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 11)),
                                    ]));
                              }),
                              // A different friend joins each section; no duplicated hero cards.
                              Positioned(
                                  top: unit.length > 3
                                      ? (unitIndex.isEven ? 340 : 590)
                                      : 170,
                                  left: unitIndex.isEven ? 0 : null,
                                  right: unitIndex.isEven ? null : 0,
                                  child: Column(children: [
                                    AnimatedKristina(
                                        width: 100,
                                        height: 150,
                                        character: unitIndex % 3),
                                    Text(
                                        [
                                          'KRISTINA',
                                          'MILOŠ',
                                          'ZARA'
                                        ][unitIndex % 3],
                                        style: const TextStyle(
                                            color: muted,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.2))
                                  ])),
                            ]));
      });
}

const _sectionHeaderExtent = 112.0;

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title, level;
  final int index;
  final Color color;
  const _SectionHeaderDelegate(
      {required this.title,
      required this.level,
      required this.index,
      required this.color});

  @override
  double get minExtent => _sectionHeaderExtent;
  @override
  double get maxExtent => _sectionHeaderExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
        color: bg,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: DecoratedBox(
                decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(19),
                    boxShadow: [
                      BoxShadow(
                          color: Color.lerp(color, Colors.black, .25)!,
                          offset: const Offset(0, 5))
                    ]),
                child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('SECTION ${index + 1} • $level',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: bg.withValues(alpha: .65),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1)),
                            const SizedBox(height: 4),
                            Text(title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: bg,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                    height: 1.1))
                          ])),
                      const SizedBox(width: 12),
                      Icon(Icons.menu_book_rounded,
                          color: bg.withValues(alpha: .7), size: 30)
                    ])))));
  }

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate old) =>
      old.title != title ||
      old.level != level ||
      old.index != index ||
      old.color != color;
}

/// Official state flag artwork, bundled for consistent rendering on every device.
class _SerbianFlag extends StatelessWidget {
  final double width;
  const _SerbianFlag({this.width = 33});
  @override
  Widget build(BuildContext context) {
    final height = width * 2 / 3;
    final radius = BorderRadius.circular(height * .16);
    return Semantics(
        label: 'Flag of Serbia',
        image: true,
        child: SizedBox(
            width: width,
            height: height,
            child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                    borderRadius: radius,
                    border:
                        Border.all(color: Colors.white.withValues(alpha: .28))),
                child: ClipRRect(
                    borderRadius: radius,
                    child: Image.asset('assets/flags/serbia.jpg',
                        width: width,
                        height: height,
                        fit: BoxFit.fill,
                        cacheWidth: 324,
                        excludeFromSemantics: true)))));
  }
}

class _TrailLinePainter extends CustomPainter {
  final int count;
  final Color color;
  _TrailLinePainter(this.count, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = panel2.withValues(alpha: .45)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const shifts = [0.0, 62.0, 82.0, 24.0, -62.0, -82.0, 0.0];
    for (var i = 0; i < count - 1; i++) {
      final x = size.width / 2 + shifts[i % 7], y = i * 148.0 + 58;
      final nx = size.width / 2 + shifts[(i + 1) % 7],
          ny = (i + 1) * 148.0 + 58;
      canvas.drawPath(
          Path()
            ..moveTo(x, y)
            ..cubicTo(x, y + 65, nx, ny - 65, nx, ny),
          p);
    }
  }

  @override
  bool shouldRepaint(covariant _TrailLinePainter old) =>
      old.count != count || old.color != color;
}

class _TrailCirclePainter extends CustomPainter {
  final int completed;
  final Color color;
  final bool locked;
  _TrailCirclePainter(this.completed, this.color, this.locked);
  @override
  void paint(Canvas c, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final p = Paint()..isAntiAlias = true;
    p.color = Color.lerp(color, Colors.black, .28)!;
    c.drawCircle(center + const Offset(0, 5), 33, p);
    p.color = color;
    c.drawCircle(center, 33, p);
    p.color = Colors.white.withValues(alpha: locked ? 0.025 : 0.12);
    c.drawOval(
        Rect.fromCenter(
            center: center - const Offset(8, 12), width: 36, height: 18),
        p);
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      p.color = i < completed ? color : panel2;
      c.drawArc(
          Rect.fromCircle(center: center, radius: 40),
          -math.pi / 2 + i * 2 * math.pi / 5 + .07,
          2 * math.pi / 5 - .14,
          false,
          p);
    }
  }

  @override
  bool shouldRepaint(covariant _TrailCirclePainter old) =>
      old.completed != completed || old.color != color || old.locked != locked;
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
  final bool alreadyCompleted;
  final int practiceRound;
  final Future<void> Function(int, List<bool>) onComplete;
  final VoidCallback? onRetry;
  final List<Question> replacements;
  const LessonPage(
      {super.key,
      required this.lesson,
      required this.onComplete,
      this.alreadyCompleted = false,
      this.practiceRound = 0,
      this.replacements = const [],
      this.onRetry});
  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage>
    with SingleTickerProviderStateMixin {
  int index = 0, correct = 0, answerRun = 0, bestRun = 0;
  final List<bool> answers = [];
  final List<int> picked = [];
  late final List<Question> round;
  late final List<Question> spares;
  late final AnimationController _wave;
  String? selected;
  String transcript = '';
  bool checked = false,
      showTheory = true,
      finished = false,
      submitting = false,
      lastCorrect = false,
      listening = false;

  @override
  void initState() {
    super.initState();
    round = [...widget.lesson.questions];
    spares = [...widget.replacements];
    _wave = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _replaceUnanswerable();
  }

  @override
  void dispose() {
    SerbianSpeech.stop();
    SerbianAudio.stop();
    learningFeedback.stopSounds();
    learningFeedback.cancelHaptics();
    _wave.dispose();
    guidePages.dispose();
    super.dispose();
  }

  bool _isTyping(Question question) =>
      question.type == 'Type the answer' || question.type == 'Listen and type';

  void _replaceUnanswerable() {
    for (var i = 0; i < round.length; i++) {
      final question = round[i];
      if (_isTyping(question) ||
          (question.type == 'Speak the phrase' && !SerbianSpeech.supported)) {
        round[i] = _replacementFor(question);
      }
    }
  }

  Question _replacementFor(Question current) {
    final at = spares.indexWhere((question) =>
        question.type != 'Speak the phrase' &&
        !_isTyping(question) &&
        !round.any((item) => item.id.isNotEmpty && item.id == question.id));
    if (at >= 0) return spares.removeAt(at);
    return _tilesInstead(current);
  }

  Question _tilesInstead(Question current) {
    final phrase = current.answer
        .replaceAll(RegExp(r'[.,!?;:“”"]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    final tokens =
        phrase.split(' ').where((word) => word.isNotEmpty).toList();
    final options = [...tokens];
    for (final extra in ['hvala', 'molim', 'da', 'ne', 'zdravo']) {
      if (options.length >= tokens.length + 3) break;
      if (options.any((item) => foldSerbian(item) == foldSerbian(extra))) {
        continue;
      }
      options.add(extra);
    }
    return Question(
        'Arrange the words',
        current.translation.trim().isNotEmpty
            ? current.translation
            : current.prompt,
        phrase.isEmpty ? current.answer : phrase,
        options,
        current.detail,
        id: current.id.isEmpty ? '' : 'swap:${current.id}',
        audioText: current.audioText,
        audioAsset: current.audioAsset,
        answerLanguage: 'sr');
  }

  void _swapOutSpeak() {
    if (!mounted || checked || finished) return;
    if (round[index].type != 'Speak the phrase' && !_isTyping(round[index])) {
      return;
    }
    SerbianSpeech.stop();
    _wave.stop();
    final replacement = _replacementFor(round[index]);
    setState(() {
      round[index] = replacement;
      listening = false;
      transcript = '';
      selected = null;
      picked.clear();
    });
  }

  String get response {
    final q = round[index];
    if (q.type == 'Arrange the words' || q.type == 'Listen and arrange')
      return picked.map((i) => q.options[i]).join(' ');
    if (q.type == 'Speak the phrase') return transcript.trim();
    return selected ?? '';
  }

  bool get canCheck => response.trim().isNotEmpty;
  bool _matches(String value, String target) {
    if (round[index].type == 'Speak the phrase') {
      return speechMatches(value, target);
    }
    String clean(String x) => x
        .toLowerCase()
        .replaceAll(RegExp(r'[.,!?;:]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    return clean(value) == clean(target);
  }

  void _clearAnswer() {
    SerbianSpeech.stop();
    _wave.stop();
    listening = false;
    transcript = '';
    selected = null;
    picked.clear();
  }

  Future<void> _toggleMic() async {
    if (checked) return;
    if (listening) {
      SerbianSpeech.stop();
      _wave.stop();
      setState(() => listening = false);
      return;
    }
    unawaited(SerbianAudio.stop());
    unawaited(learningFeedback.stopSounds());
    final questionIndex = index;
    final started = await SerbianSpeech.start(onResult: (text) {
      if (!mounted || index != questionIndex || checked) return;
      transcript = text;
      if (speechMatches(text, round[questionIndex].answer)) {
        _advance();
        return;
      }
      setState(() {});
    }, onEnd: () {
      if (!mounted || index != questionIndex || checked) return;
      _wave.stop();
      listening = false;
      if (transcript.trim().isEmpty) {
        setState(() {});
        return;
      }
      _advance();
    }, onError: (_) {
      if (!mounted || index != questionIndex || checked) return;
      _swapOutSpeak();
    });
    if (!mounted || index != questionIndex || checked) return;
    if (!started) {
      _swapOutSpeak();
      return;
    }
    _wave.repeat();
    setState(() {
      listening = true;
      transcript = '';
    });
  }

  Future<void> _advance() async {
    if (submitting) return;
    final q = round[index];
    if (!checked) {
      if (!canCheck) return;
      SerbianSpeech.stop();
      _wave.stop();
      listening = false;
      FocusScope.of(context).unfocus();
      final right = _matches(response, q.answer);
      answerRun = right ? answerRun + 1 : 0;
      bestRun = math.max(bestRun, answerRun);
      setState(() {
        checked = true;
        lastCorrect = right;
        answers.add(right);
        if (right) correct++;
      });
      unawaited(_answerFeedback(right, answerRun, index));
      return;
    }
    learningFeedback.tap(sound: false);
    learningFeedback.stopSounds();
    if (index < round.length - 1) {
      setState(() {
        index++;
        checked = false;
        _clearAnswer();
      });
    } else {
      setState(() => submitting = true);
      try {
        await PracticeMemory.record(round, answers);
      } catch (_) {}
      await widget.onComplete(correct, answers);
      if (mounted)
        setState(() {
          finished = true;
          submitting = false;
        });
      if (mounted)
        learningFeedback.complete(
            passed: correct * 100 >=
                widget.lesson.minPassPercent * round.length,
            perfect: correct == round.length);
    }
  }

  Future<void> _answerFeedback(bool right, int run, int questionIndex) async {
    await SerbianAudio.stop();
    if (mounted && checked && index == questionIndex)
      learningFeedback.answer(right, run);
  }

  void _selectionFeedback(Question q, String word) {
    final spoken = learningFeedback.shouldSpeakSelection(q.answerLanguage);
    learningFeedback.tap(sound: !spoken);
    if (spoken) unawaited(SerbianAudio.speakWord(word));
  }

  int _castIndex() =>
      (widget.lesson.id.codeUnits.fold<int>(0, (sum, unit) => sum + unit) +
          index) %
      3;

  String _heading(Question q) => q.type == 'Speak the phrase'
      ? 'Repeat after ${const ['Kristina', 'Miloš', 'Zara'][_castIndex()]}'
      : q.type == 'Listen and arrange'
          ? 'Translate what you hear'
          : q.type.startsWith('Listen')
              ? 'What do you hear?'
              : switch (q.type) {
                  'Arrange the words' => 'Translate this sentence',
                  'Complete the sentence' => 'Complete the sentence',
                  'Choose the image' => 'Select the correct image',
                  'Translate to Serbian' => 'How do you say this?',
                  _ => 'Choose the correct meaning',
                };

  final PageController guidePages = PageController();
  int guidePage = 0;

  @override
  Widget build(BuildContext context) {
    final q = round[index];
    final guide = showTheory && widget.lesson.theoryBody.isNotEmpty;
    return Scaffold(
        backgroundColor: bg,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: LayoutBuilder(
                        builder: (context, viewport) =>
                            Stack(fit: StackFit.expand, children: [
                              Column(children: [
                                SizedBox(
                                    height: 48,
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Row(children: [
                                          IconButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              icon: const Icon(
                                                  Icons.close_rounded,
                                                  color: muted),
                                              tooltip: 'Leave lesson'),
                                          const SizedBox(width: 6),
                                          Expanded(
                                              child: TweenAnimationBuilder<double>(
                                                  tween: Tween(
                                                      end: finished
                                                          ? 1
                                                          : (index + (checked ? 1 : 0)) /
                                                              round.length),
                                                  duration: const Duration(
                                                      milliseconds: 350),
                                                  builder: (_, value, __) => ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      child: LinearProgressIndicator(
                                                          value: value,
                                                          minHeight: 13,
                                                          backgroundColor:
                                                              panel2,
                                                          valueColor:
                                                              const AlwaysStoppedAnimation(
                                                                  lime))))),
                                          const SizedBox(width: 6),
                                          IconButton(
                                              tooltip: 'Learning feedback',
                                              onPressed: () =>
                                                  showFeedbackSettings(context),
                                              icon: const Icon(
                                                  Icons.tune_rounded,
                                                  color: muted,
                                                  size: 21)),
                                        ]))),
                                Expanded(
                                    child: Padding(
                                        padding: EdgeInsets.fromLTRB(
                                            20,
                                            viewport.maxHeight < 600 ? 6 : 12,
                                            20,
                                            8),
                                        child: finished
                                            ? _completeViewport()
                                            : guide
                                                ? _guideViewport()
                                                : _exerciseViewport(q))),
                                // Reserve only the resting action bar height. Feedback paints over the exercise.
                                if (!finished)
                                  SizedBox(
                                      height:
                                          viewport.maxHeight < 600 ? 78 : 89),
                              ]),
                              if (!finished)
                                Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: AnimatedSize(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        alignment: Alignment.bottomCenter,
                                        curve: Curves.easeOutCubic,
                                        child: _footer(q, guide,
                                            viewport.maxHeight < 600))),
                            ]))))));
  }

  Widget _exerciseViewport(Question q) =>
      LayoutBuilder(builder: (context, space) {
        final short = space.maxHeight < 380;
        final headingHeight = short ? 38.0 : 52.0;
        final sceneHeight =
            (space.maxHeight * (short ? 0.25 : 0.29)).clamp(48.0, 145.0);
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                  height: headingHeight,
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                              width: space.maxWidth,
                              child: Text(_heading(q),
                                  maxLines: 2,
                                  style: TextStyle(
                                      fontSize: short ? 22 : 25,
                                      height: 1.1,
                                      fontWeight: FontWeight.w900)))))),
              SizedBox(height: sceneHeight, child: _scene(q, sceneHeight)),
              SizedBox(height: short ? 10 : 18),
              Expanded(
                  child: q.type == 'Arrange the words' ||
                          q.type == 'Listen and arrange'
                      ? _arrangeViewport(q)
                      : q.type == 'Speak the phrase'
                          ? _speakViewport()
                          : _choicesViewport(q)),
            ]);
      });

  Widget _scene(Question q, double height) {
    final listen = q.type.startsWith('Listen');
    final mood = checked
        ? (lastCorrect
            ? (answerRun >= 5
                ? 'hot'
                : answerRun >= 3
                    ? 'celebrate'
                    : 'correct')
            : 'wrong')
        : 'idle';
    final character = _castIndex();
    return Row(children: [
      if (height >= 72) ...[
        ValueListenableBuilder<bool>(
            valueListenable: SerbianAudio.speaking,
            builder: (_, speaking, __) => AnimatedKristina(
                width: height * .64,
                height: height,
                mood: !checked && speaking ? 'speaking' : mood,
                character: character)),
        const SizedBox(width: 10)
      ],
      Expanded(
          child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 12, vertical: height < 90 ? 6 : 10),
              decoration: BoxDecoration(
                  border: Border.all(color: panel2, width: 2),
                  borderRadius: BorderRadius.circular(16)),
              child: listen
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      SerbianAudioButton(
                          text: q.audioText, asset: q.audioAsset),
                      const SizedBox(width: 12),
                      SerbianAudioButton(
                          text: q.audioText, asset: q.audioAsset, slow: true),
                    ])
                  : Row(children: [
                      if (q.audioText.isNotEmpty &&
                          (q.type == 'Choose the meaning' ||
                              q.type == 'Choose the image' ||
                              q.type == 'Speak the phrase' ||
                              (q.type == 'Arrange the words' &&
                                  q.answerLanguage == 'en'))) ...[
                        SerbianAudioButton(
                            text: q.audioText, asset: q.audioAsset),
                        const SizedBox(width: 8)
                      ],
                      Expanded(
                          child: LayoutBuilder(
                              builder: (context, box) => FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                      width: box.maxWidth,
                                      child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _hintPrompt(q),
                                            if (q.translation.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text('Meaning: ${q.translation}',
                                                  style: const TextStyle(
                                                      color: muted,
                                                      fontSize: 13,
                                                      height: 1.3))
                                            ]
                                          ]))))),
                    ]))),
    ]);
  }

  Widget _hintPrompt(Question q) {
    final vocabulary = [...widget.lesson.vocabulary, ...words];
    var prompt = q.prompt;
    if (q.type == 'Complete the sentence' && selected != null) {
      prompt = prompt.replaceFirst('___', selected!);
    }
    if ((q.type == 'Choose the meaning' && prompt.startsWith('What does')) ||
        (q.type == 'Choose the image' && prompt.startsWith('Which one'))) {
      if (q.audioText.isNotEmpty) prompt = q.audioText;
    }
    return Wrap(
        spacing: 4,
        runSpacing: 3,
        children: prompt.split(RegExp(r'\s+')).map((token) {
          final hint = wordHintFor(token, prompt, vocabulary);
          final label = Text(token,
              style: TextStyle(
                  fontSize: 18,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  decoration: hint == null ? null : TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dashed,
                  decorationColor: muted,
                  decorationThickness: 1.5));
          if (hint == null) return label;
          return Builder(
              builder: (wordContext) => Semantics(
                  button: true,
                  label: 'Hint for $token',
                  child: InkWell(
                      onTap: () => _showHint(wordContext, hint, q),
                      borderRadius: BorderRadius.circular(4),
                      child: label)));
        }).toList());
  }

  void _showHint(BuildContext wordContext, WordHint hint, Question q) {
    final box = wordContext.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final rect = box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
    showMenu<void>(
        context: context,
        color: panel,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: panel2, width: 2)),
        position: RelativeRect.fromRect(rect, Offset.zero & overlay.size),
        items: [
          PopupMenuItem<void>(
              enabled: false,
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hint.term,
                            style: const TextStyle(
                                color: blue,
                                fontSize: 18,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text(hint.meaning,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                height: 1.3)),
                        if (q.audioText.isNotEmpty) ...[
                          const Divider(color: panel2, height: 22),
                          const Text('IN THIS EXERCISE',
                              style: TextStyle(
                                  color: muted,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9,
                                  letterSpacing: 1)),
                          const SizedBox(height: 5),
                          Text(
                              q.type == 'Complete the sentence'
                                  ? q.prompt
                                  : q.audioText,
                              maxLines: 3,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.3))
                        ],
                      ])))
        ]);
  }

  Widget
      _choicesViewport(Question q) => LayoutBuilder(builder: (context, space) {
            final image = q.type == 'Choose the image';
            final columns =
                image || (space.maxHeight < 196 && q.options.length > 2)
                    ? 2
                    : 1;
            final rows = (q.options.length / columns).ceil();
            final height =
                math.min(space.maxHeight, rows * (image ? 140.0 : 62.0));
            return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                    height: height,
                    child: Column(
                        children: List.generate(
                            rows,
                            (row) => Expanded(
                                child: Padding(
                                    padding: EdgeInsets.only(
                                        bottom: row == rows - 1 ? 3 : 8),
                                    child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children:
                                            List.generate(columns, (column) {
                                          final i = row * columns + column;
                                          if (i >= q.options.length)
                                            return const Expanded(
                                                child: SizedBox());
                                          final option = q.options[i],
                                              picture = image
                                                  ? PictureOption.parse(option)
                                                  : null,
                                              chosen = selected == option,
                                              reveal =
                                                  checked && option == q.answer,
                                              wrong =
                                                  checked && chosen && !reveal;
                                          final edge = reveal
                                              ? lime
                                              : wrong
                                                  ? const Color(0xFFFF7279)
                                                  : chosen
                                                      ? blue
                                                      : panel2;
                                          return Expanded(
                                              child: Padding(
                                                  padding: EdgeInsets.only(
                                                      right:
                                                          column < columns - 1
                                                              ? 8
                                                              : 0),
                                                  child: Semantics(
                                                      button: true,
                                                      selected: chosen,
                                                      label: picture?.label ??
                                                          option,
                                                      child: GestureDetector(
                                                          onTap: checked
                                                              ? null
                                                              : () {
                                                                  setState(() =>
                                                                      selected =
                                                                          option);
                                                                  _selectionFeedback(
                                                                      q,
                                                                      option);
                                                                },
                                                          child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          5),
                                                              decoration:
                                                                  BoxDecoration(
                                                                      color: reveal
                                                                          ? const Color(0xFF234830)
                                                                          : wrong
                                                                              ? const Color(0xFF45262C)
                                                                              : chosen
                                                                                  ? const Color(0xFF163A4C)
                                                                                  : panel,
                                                                      border: Border.all(color: edge, width: 2),
                                                                      borderRadius: BorderRadius.circular(14),
                                                                      boxShadow: [
                                                                    BoxShadow(
                                                                        color:
                                                                            edge,
                                                                        offset: const Offset(
                                                                            0,
                                                                            3))
                                                                  ]),
                                                              child: picture !=
                                                                      null
                                                                  ? Column(
                                                                      children: [
                                                                          Expanded(
                                                                              child: FittedBox(child: LearningObject(name: picture.key))),
                                                                          Text(
                                                                              picture.label,
                                                                              maxLines: 1,
                                                                              overflow: TextOverflow.ellipsis,
                                                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))
                                                                        ])
                                                                  : Row(
                                                                      children: [
                                                                        if (columns ==
                                                                            1) ...[
                                                                          Text(
                                                                              '${i + 1}',
                                                                              style: TextStyle(color: chosen ? blue : muted, fontSize: 12, fontWeight: FontWeight.w900)),
                                                                          const SizedBox(
                                                                              width: 12)
                                                                        ],
                                                                        Expanded(
                                                                            child:
                                                                                LayoutBuilder(builder: (context, box) => FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: SizedBox(width: box.maxWidth, child: Text(option, maxLines: 4, style: const TextStyle(fontSize: 16, height: 1.2, fontWeight: FontWeight.w800)))))),
                                                                        if (reveal) ...[
                                                                          const SizedBox(
                                                                              width: 4),
                                                                          const Icon(
                                                                              Icons.check_rounded,
                                                                              color: lime,
                                                                              size: 20)
                                                                        ]
                                                                      ],
                                                                    ))))));
                                        }))))))));
          });

  Widget _tile(String word, VoidCallback? onTap, double font) => Semantics(
      button: true,
      label: word,
      child: GestureDetector(
          onTap: onTap,
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                  color: bg,
                  border: Border.all(color: const Color(0xFF435761), width: 2),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF435761), offset: Offset(0, 3))
                  ]),
              child: Text(word,
                  style: TextStyle(
                      fontSize: font, fontWeight: FontWeight.w800)))));
  Widget _tileBank(List<Widget> tiles, {bool answer = false}) => LayoutBuilder(
      builder: (context, box) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: answer ? Alignment.topLeft : Alignment.topCenter,
          child: SizedBox(
              width: box.maxWidth,
              child: Wrap(
                  alignment:
                      answer ? WrapAlignment.start : WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 10,
                  children: tiles))));
  void _moveTile(int from, int to) {
    if (checked ||
        from == to ||
        from < 0 ||
        to < 0 ||
        from >= picked.length ||
        to >= picked.length) return;
    setState(() {
      final token = picked.removeAt(from);
      picked.insert(to, token);
    });
    learningFeedback.tap(sound: !SerbianAudio.speaking.value);
  }

  void _removeTile(int position) {
    setState(() => picked.removeAt(position));
    learningFeedback.tap(sound: !SerbianAudio.speaking.value);
  }

  Widget _selectedTile(Question q, int position, double font) {
    final word = q.options[picked[position]];
    Widget tile() =>
        _tile(word, checked ? null : () => _removeTile(position), font);
    if (checked) return tile();
    return DragTarget<int>(
        onWillAcceptWithDetails: (details) => details.data != position,
        onAcceptWithDetails: (details) => _moveTile(details.data, position),
        builder: (context, candidates, _) => AnimatedScale(
            scale: candidates.isEmpty ? 1 : 1.06,
            duration: const Duration(milliseconds: 120),
            child: Semantics(
                hint: 'Tap to return this word. Hold and drag to reorder.',
                customSemanticsActions: {
                  if (position > 0)
                    const CustomSemanticsAction(label: 'Move word left'): () =>
                        _moveTile(position, position - 1),
                  if (position < picked.length - 1)
                    const CustomSemanticsAction(label: 'Move word right'): () =>
                        _moveTile(position, position + 1),
                },
                child: LongPressDraggable<int>(
                    data: position,
                    feedback: Material(
                        color: Colors.transparent,
                        child: _tile(word, null, font)),
                    childWhenDragging: Opacity(opacity: .2, child: tile()),
                    child: tile()))));
  }

  Widget _arrangeViewport(Question q) =>
      LayoutBuilder(builder: (context, space) {
        final font = space.maxWidth < 340 ? 15.0 : 17.0;
        return Column(children: [
          Expanded(
              flex: 4,
              child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(color: panel2, width: 2),
                          bottom: BorderSide(color: panel2, width: 2))),
                  child: _tileBank(
                      List.generate(
                          picked.length,
                          (position) => KeyedSubtree(
                              key: ValueKey('answer-token-$position'),
                              child: _selectedTile(q, position, font))),
                      answer: true))),
          SizedBox(height: space.maxHeight < 180 ? 10 : 20),
          Expanded(
              flex: 5,
              child: _tileBank(q.options
                  .asMap()
                  .entries
                  .map((entry) => IgnorePointer(
                      key: ValueKey('bank-token-${entry.key}'),
                      ignoring: checked || picked.contains(entry.key),
                      child: Opacity(
                          opacity: picked.contains(entry.key) ? 0.12 : 1.0,
                          child: _tile(entry.value, () {
                            setState(() => picked.add(entry.key));
                            _selectionFeedback(q, entry.value);
                          }, font))))
                  .toList())),
        ]);
      });
  Widget _speakViewport() {
    return Column(children: [
      if (transcript.isNotEmpty)
        Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(transcript,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800))),
      Semantics(
          button: true,
          label: listening ? 'Stop microphone' : 'Speak the phrase',
          child: GestureDetector(
              onTap: checked ? null : _toggleMic,
              child: Container(
                  height: 58,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: blue,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Color(0xFF1899D6), offset: Offset(0, 4))
                      ]),
                  child: listening
                      ? AnimatedBuilder(
                          animation: _wave,
                          builder: (_, __) => Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (bar) {
                                final height = 8 +
                                    16 *
                                        (.5 +
                                            .5 *
                                                math.sin(_wave.value *
                                                        math.pi *
                                                        2 +
                                                    bar));
                                return Container(
                                    width: 6,
                                    height: height,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(4)));
                              })))
                      : const Icon(Icons.mic_rounded,
                          color: Colors.white, size: 30)))),
    ]);
  }

  Widget _footer(Question q, bool guide, bool compact) => Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, compact ? 9 : 14, 20, compact ? 12 : 18),
      decoration: BoxDecoration(
          color: checked && !guide
              ? (lastCorrect
                  ? const Color(0xFF173D30)
                  : const Color(0xFF45262C))
              : bg,
          border: const Border(top: BorderSide(color: panel2))),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (checked && !guide) ...[
              Row(children: [
                Icon(
                    lastCorrect
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: lastCorrect ? lime : pink,
                    size: 23),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        lastCorrect
                            ? (answerRun >= 3
                                ? '$answerRun in a row!'
                                : 'Nicely done!')
                            : 'Let’s get this one.',
                        style: TextStyle(
                            color: lastCorrect ? lime : pink,
                            fontSize: compact ? 18 : 20,
                            fontWeight: FontWeight.w900))),
                if (q.audioText.isNotEmpty)
                  SizedBox(
                      height: 34,
                      child: SerbianAudioButton(
                          text: q.audioText,
                          asset: q.audioAsset,
                          color: lastCorrect ? lime : pink))
              ]),
              if (!lastCorrect)
                Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text('Answer: ${q.answer}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800))),
              GestureDetector(
                  onTap: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                              backgroundColor: panel,
                              title: const Text('Why this answer?'),
                              content: Text(q.detail),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('GOT IT'))
                              ])),
                  child: Text(q.detail,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: Color(0xFFCFDCE2)))),
              const SizedBox(height: 8),
            ],
            if (!guide && q.type == 'Speak the phrase' && !checked)
              TextButton(
                  onPressed: _swapOutSpeak,
                  child: const Text("CAN'T SPEAK NOW",
                      style: TextStyle(
                          color: muted,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .6,
                          fontSize: 13)))
            else
              KButton(
                  text: guide
                      ? 'START PRACTICE'
                      : submitting
                          ? 'SAVING…'
                          : checked
                              ? 'CONTINUE'
                              : 'CHECK',
                  color:
                      checked && !lastCorrect ? const Color(0xFFFF7279) : lime,
                  onTap: guide
                      ? () => setState(() => showTheory = false)
                      : (checked || canCheck) && !submitting
                          ? _advance
                          : null),
          ]));

  Widget _guideViewport() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${widget.lesson.level} • LESSON GUIDE',
            style: const TextStyle(
                color: blue,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1)),
        const SizedBox(height: 6),
        SizedBox(
            height: 52,
            child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                    width: math.min(560, MediaQuery.sizeOf(context).width - 40),
                    child: Text(widget.lesson.theoryTitle,
                        maxLines: 2,
                        style: const TextStyle(
                            fontSize: 25,
                            height: 1.15,
                            fontWeight: FontWeight.w900))))),
        Expanded(
            child: PageView(
                controller: guidePages,
                onPageChanged: (page) => setState(() => guidePage = page),
                children: [
              LayoutBuilder(
                  builder: (context, box) => Column(children: [
                        SizedBox(
                            height: box.maxHeight * .36,
                            child: const AnimatedKristina()),
                        const SizedBox(height: 10),
                        Expanded(
                            child: LayoutBuilder(
                                builder: (context, textBox) => FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.topLeft,
                                    child: SizedBox(
                                        width: textBox.maxWidth,
                                        child: Text(widget.lesson.theoryBody,
                                            style: const TextStyle(
                                                fontSize: 18, height: 1.5))))))
                      ])),
              ...List.generate(
                  (widget.lesson.vocabulary.length / 3).ceil(),
                  (page) => Column(
                      children: widget.lesson.vocabulary
                          .skip(page * 3)
                          .take(3)
                          .map((word) => Expanded(
                              child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                      border:
                                          Border.all(color: panel2, width: 2),
                                      borderRadius: BorderRadius.circular(14)),
                                  child: Row(children: [
                                    Expanded(
                                        child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(word[0],
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          fontSize: 19)),
                                                  Text(word[1],
                                                      style: const TextStyle(
                                                          color: muted,
                                                          fontSize: 13)),
                                                  Text(word[2],
                                                      style: const TextStyle(
                                                          color: blue,
                                                          fontSize: 15))
                                                ]))),
                                    SerbianAudioButton(
                                        text: word[0],
                                        asset: word.length > 4 ? word[4] : '')
                                  ]))))
                          .toList())),
            ])),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
              tooltip: 'Previous guide page',
              onPressed: guidePage > 0
                  ? () => guidePages.previousPage(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut)
                  : null,
              icon: const Icon(Icons.chevron_left_rounded)),
          Text(
              '${guidePage + 1} / ${1 + (widget.lesson.vocabulary.length / 3).ceil()}',
              style: const TextStyle(color: muted, fontSize: 12)),
          IconButton(
              tooltip: 'Next guide page',
              onPressed:
                  guidePage < (widget.lesson.vocabulary.length / 3).ceil()
                      ? () => guidePages.nextPage(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut)
                      : null,
              icon: const Icon(Icons.chevron_right_rounded))
        ]),
        const Text('AI-generated pronunciation',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 10)),
      ]);

  Widget _completeViewport() => LayoutBuilder(builder: (context, space) {
        final passed =
            correct * 100 >= widget.lesson.minPassPercent * round.length;
        return Column(children: [
          Expanded(
              child: AnimatedKristina(
                  width: 220,
                  height: space.maxHeight * .44,
                  mood: passed
                      ? (correct == round.length ? 'hot' : 'celebrate')
                      : 'wrong')),
          Text(
              passed
                  ? (widget.practiceRound == 4
                      ? 'CIRCLE COMPLETE!'
                      : 'PRACTICE ${widget.practiceRound + 1} COMPLETE!')
                  : 'KEEP PRACTICING',
              style: const TextStyle(
                  color: lime,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                  passed
                      ? (correct == round.length
                          ? 'Flawless. Look at you!'
                          : bestRun >= 3
                              ? '$bestRun in a row. Keep it up!'
                              : 'You did it, superstar!')
                      : 'Let’s try that again.',
                  style: const TextStyle(
                      fontSize: 27, fontWeight: FontWeight.w900))),
          const SizedBox(height: 12),
          SizedBox(
              height: 80,
              child: Row(children: [
                Expanded(
                    child: _metric(
                        Icons.bolt_rounded,
                        passed && !widget.alreadyCompleted
                            ? '+${(10 + correct * 5).clamp(0, 30)}'
                            : '+0',
                        'XP',
                        lime)),
                const SizedBox(width: 10),
                Expanded(
                    child: _metric(
                        Icons.check_circle_rounded,
                        '$correct/${round.length}',
                        'CORRECT',
                        blue))
              ])),
          const SizedBox(height: 18),
          KButton(
              text: passed ? 'BACK TO THE TRAIL' : 'TRY AGAIN',
              onTap: () {
                if (passed) {
                  Navigator.pop(context);
                } else if (widget.onRetry != null) {
                  final retry = widget.onRetry!;
                  Navigator.pop(context);
                  retry();
                } else {
                  setState(() {
                    index = 0;
                    correct = 0;
                    answerRun = 0;
                    bestRun = 0;
                    answers.clear();
                    picked.clear();
                    checked = false;
                    finished = false;
                    showTheory = false;
                    _clearAnswer();
                  });
                }
              }),
          const SizedBox(height: 12),
        ]);
      });
  Widget _metric(IconData icon, String value, String label, Color color) =>
      Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(value,
                  style: TextStyle(
                      color: color, fontSize: 22, fontWeight: FontWeight.w900)),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 10, fontWeight: FontWeight.w900))
            ])
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
          const SizedBox(height: 7),
          const Text('Audio pronunciations are AI-generated.',
              style: TextStyle(color: muted, fontSize: 12)),
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
                          child: SerbianAudioButton(
                              text: e.value[0],
                              asset: e.value.length > 4 ? e.value[4] : '')),
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
                  LearnerBadge(
                      look: LearnerLook.fromAvatar(f['avatar'],
                          seed: (f['name'] ?? '').toString()),
                      size: 42,
                      radius: 21),
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
  final LearnerLook look;
  final Future<void> Function(LearnerLook) onAvatar;
  final VoidCallback onClose;
  final VoidCallback onFriends;
  final Future<void> Function(String, String, String, bool, bool) onAuth;
  final Future<void> Function() onLogout;
  const ProfilePage(
      {super.key,
      required this.user,
      required this.xp,
      required this.streak,
      required this.done,
      required this.look,
      required this.onAvatar,
      required this.onClose,
      required this.onFriends,
      required this.onAuth,
      required this.onLogout});
  @override
  Widget build(BuildContext context) {
    final ink = look.backgroundColor.computeLuminance() > .55
        ? const Color(0xFF131F24)
        : Colors.white;
    final created = user?['createdAt'];
    final year = created is String ? DateTime.tryParse(created)?.year : null;
    final name = user?['name'] as String? ?? 'Your name';
    return ListView(padding: EdgeInsets.zero, children: [
      ColoredBox(
          color: look.backgroundColor,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Column(children: [
                SizedBox(
                    height: 48,
                    child: Stack(alignment: Alignment.center, children: [
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 52),
                          child: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: ink,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900))),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                              tooltip: 'Close',
                              onPressed: onClose,
                              icon: Icon(Icons.close_rounded, color: ink))),
                      Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                              tooltip: 'Settings',
                              onPressed: () => showFeedbackSettings(context),
                              icon: Icon(Icons.settings_rounded, color: ink)))
                    ])),
                Text(year == null ? 'Learning Serbian' : 'Learning since $year',
                    style: TextStyle(
                        color: ink.withValues(alpha: .72),
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                GestureDetector(
                    onTap: () => _editAvatar(context),
                    child: Semantics(
                        button: true,
                        label: 'Edit avatar',
                        child: SizedBox(
                            width: 260,
                            height: 240,
                            child: LearnerPortrait(look: look))))
              ]))),
      Transform.translate(
          offset: const Offset(0, -36),
          child: DecoratedBox(
              decoration: const BoxDecoration(
                  color: bg,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28))),
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                            user == null
                                ? 'Sign in to save your look'
                                : '@${user!['username']}${year == null ? '' : ' · JOINED $year'}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: muted,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .4,
                                fontSize: 13)),
                        const SizedBox(height: 18),
                        Row(children: [
                          _stat(const _SerbianFlag(), 'Courses'),
                          _stat(
                              Text('$streak',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900)),
                              'Streak'),
                          _stat(
                              Text('${done.length}',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900)),
                              'Lessons'),
                        ]),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                            onPressed: onFriends,
                            icon: const Icon(Icons.person_add_alt_1,
                                color: Colors.white),
                            label: const Text('ADD FRIENDS',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .6)),
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: panel2, width: 2),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14))),
                        const SizedBox(height: 18),
                        Material(
                            color: const Color(0xFF3C2F78),
                            borderRadius: BorderRadius.circular(22),
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 18, 18, 16),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Shape your look',
                                          style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w900,
                                              height: 1.05)),
                                      const SizedBox(height: 6),
                                      const Text(
                                          'Mix skin, hair, glasses, and clothes. It stays on your profile.',
                                          style: TextStyle(
                                              color: Color(0xFFD9D0F2),
                                              fontSize: 13)),
                                      const SizedBox(height: 14),
                                      Material(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          child: InkWell(
                                              onTap: () => _editAvatar(context),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              child: const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 14),
                                                  child: Center(
                                                      child: Text(
                                                          'EDIT YOUR LOOK',
                                                          style: TextStyle(
                                                              color: blue,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900,
                                                              letterSpacing:
                                                                  .4))))))
                                    ]))),
                        const SizedBox(height: 22),
                        const Text('OVERVIEW',
                            style: TextStyle(
                                color: muted,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.3,
                                fontSize: 12)),
                        const SizedBox(height: 12),
                        Row(children: [
                          const Icon(Icons.local_fire_department_rounded,
                              color: Color(0xFFFF9A43), size: 28),
                          const SizedBox(width: 6),
                          Text('$streak days',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(width: 22),
                          const _SerbianFlag(),
                          const SizedBox(width: 8),
                          Text('$xp XP',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 16)),
                        ]),
                        const SizedBox(height: 22),
                        Row(children: [
                          Expanded(
                              child:
                                  _badge('👋', 'First hello', done.isNotEmpty)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _badge('🔥', 'On a roll', streak >= 3)),
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
                            const Icon(Icons.verified_user_outlined,
                                color: lime),
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
                                        builder: (_) => AdminPage(
                                            token: SharedToken.value))),
                                child: const Row(children: [
                                  Icon(Icons.admin_panel_settings, color: blue),
                                  SizedBox(width: 12),
                                  Expanded(
                                      child: Text('Course studio',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w900))),
                                  Icon(Icons.chevron_right)
                                ])),
                          const SizedBox(height: 12),
                          KButton(
                              text: 'SIGN OUT',
                              outline: true,
                              onTap: () => onLogout())
                        ]
                      ]))))
    ]);
  }

  Widget _stat(Widget value, String label) => Expanded(
      child: Column(children: [
        SizedBox(height: 32, child: Center(child: value)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: muted, fontSize: 12, fontWeight: FontWeight.w800))
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

  void _editAvatar(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AvatarEditor(look: look, onDone: onAvatar)));
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
  static const icons = [
    Icons.cottage_rounded,
    Icons.auto_stories_rounded,
    Icons.translate_rounded,
    Icons.diversity_1_rounded,
    Icons.face_rounded
  ];
  static const colors = [
    Color(0xFFFFB94A),
    Color(0xFF59C5F5),
    Color(0xFFAB8AF3),
    Color(0xFFFF86BE),
    Color(0xFF63D6B6)
  ];
  static const names = [
    'Course trail',
    'Words',
    'Letters',
    'Friends',
    'Profile'
  ];
  @override
  Widget build(BuildContext context) => Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
          color: bg, border: Border(top: BorderSide(color: panel2, width: 2))),
      child: Row(
          children: List.generate(
              5,
              (i) => Expanded(
                  child: Tooltip(
                      message: names[i],
                      child: Semantics(
                          selected: tab == i,
                          label: names[i],
                          button: true,
                          child: Center(
                              child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                      onTap: () => onTap(i),
                                      borderRadius: BorderRadius.circular(16),
                                      child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 180),
                                          width: 54,
                                          height: 52,
                                          decoration: BoxDecoration(
                                              color: tab == i
                                                  ? const Color(0xFF1C3542)
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                  color: tab == i
                                                      ? const Color(0xFF4387A3)
                                                      : Colors.transparent,
                                                  width: 2)),
                                          child:
                                              Icon(icons[i], color: colors[i], size: 31)))))))))));
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
                leading: Icon(BottomNav.icons[i], color: BottomNav.colors[i]),
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
