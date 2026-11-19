// Serbian A1 for English speakers — authored source for course version 5.
//
// DRAFT: the Serbian here was written with AI help and still needs a review by
// a native speaker before it is treated as final. `npm run course:review`
// prints every Serbian line with its English for that review.
//
// Format, per lesson:
//   words    'latin = english' entries separated by '|'; add '= pronunciation'
//            to override the generated guide.
//   say      [serbian, english] sentences. Even entries become "build the
//            Serbian sentence", odd entries "listen and build the English".
//   gaps     [sentence with ___, answer, 'two distractors', english].
//   replies  [line said to you, its english, best reply, [two wrong replies]].
//   read     {text, q, a, wrong: [two], en, audio?} short reading.
// Run `node scripts/build-course.mjs` to regenerate the published JSON.

export const course = {
  id: 'serbian-en',
  title: 'Serbian for English speakers',
  version: 5,
  contentStage:
    'A1 rebuild: 44 fuller lessons with grammar, dialogues and reading. AI-drafted Serbian awaiting native-speaker review.',
};

export const units = [
  {
    id: 'a1-first-conversations', title: 'Hello & scripts',
    subtitle: 'Greet people, be polite and read both alphabets',
    outcomes: ['Greet someone at any time of day', 'Choose between ti and Vi', 'Ask how someone is', 'Read simple words in Cyrillic'],
    checkpoint: { id: 'a1-first-check', title: 'First conversations check', subtitle: 'Greetings, politeness and both scripts' },
    lessons: [
      {
        id: 'hello', title: 'Say hello', subtitle: 'Greetings for every time of day', icon: '👋', color: 'green',
        grammar: ['Greetings follow the clock', `Serbian greetings change through the day: dobro jutro in the morning, dobar dan during the day and dobro veče in the evening. Laku noć is only for bedtime or leaving late at night.

Zdravo and ćao are informal — use them with friends. Ćao means both hi and bye.

Notice dobro / dobar: "good" changes its ending to match the word after it. Jutro and veče are neuter (dobro), dan is masculine (dobar). You will see this pattern everywhere.`],
        words: 'zdravo = hello | ćao = hi / bye | dobro jutro = good morning | dobar dan = good day | dobro veče = good evening | laku noć = good night | doviđenja = goodbye | vidimo se = see you | hvala = thank you',
        say: [
          ['Dobro jutro, Kristina!', 'Good morning, Kristina!'],
          ['Ćao, vidimo se!', 'Bye, see you!'],
          ['Dobro veče, Ana!', 'Good evening, Ana!'],
          ['Laku noć i hvala!', 'Good night and thank you!'],
          ['Zdravo, Marko!', 'Hello, Marko!'],
          ['Doviđenja i hvala!', 'Goodbye and thanks!'],
        ],
        gaps: [
          ['Dobro ___, Ana!', 'jutro', 'dan noć', 'Good morning, Ana!'],
          ['___ dan!', 'Dobar', 'Dobro Laku', 'Good day!'],
          ['Laku ___!', 'noć', 'jutro dan', 'Good night!'],
        ],
        replies: [
          ['Dobro jutro!', 'Good morning!', 'Dobro jutro! Kako si?', ['Laku noć!', 'Doviđenja!']],
          ['Ćao, vidimo se sutra!', 'Bye, see you tomorrow!', 'Ćao, vidimo se!', ['Dobro jutro!', 'Dobar dan, drago mi je.']],
        ],
      },
      {
        id: 'polite', title: 'Be polite', subtitle: 'Please, thanks and the two kinds of "you"', icon: '✨', color: 'pink',
        grammar: ['Ti or Vi?', `Serbian has two words for "you". Use ti with friends, family and children. Use Vi with strangers, older people, shop staff and anyone in a formal situation. Vi is also the plural "you".

Many polite words come in both forms:
• izvini / izvinite — sorry, excuse me
• hvala ti / hvala vam — thank you

Molim is a multi-tool: "please", "you're welcome" and "pardon?" when you didn't catch something.`],
        words: 'molim = please / you are welcome | molim vas = please (formal) | hvala vam = thank you (formal) | hvala ti = thank you (informal) | izvini = sorry (informal) | izvinite = excuse me (formal) | nema problema = no problem | da = yes | ne = no',
        say: [
          ['Izvinite, molim vas.', 'Excuse me, please.'],
          ['Ne, hvala.', 'No, thanks.'],
          ['Da, hvala vam.', 'Yes, thank you.'],
          ['Hvala ti, Ana!', 'Thank you, Ana!'],
          ['Izvini, Marko!', 'Sorry, Marko!'],
        ],
        gaps: [
          ['Izvinite, ___ vas.', 'molim', 'da hvala', 'Excuse me, please.'],
          ['Hvala ___, Jelena!', 'ti', 'vam ne', 'Thank you, Jelena! (to a friend)'],
          ['Nema ___.', 'problema', 'hvala molim', 'No problem.'],
        ],
        replies: [
          ['Hvala vam!', 'Thank you!', 'Molim.', ['Izvinite.', 'Laku noć.']],
          ['Izvini!', 'Sorry!', 'Nema problema.', ['Hvala ti.', 'Dobro jutro.']],
        ],
      },
      {
        id: 'questions', title: 'How are you?', subtitle: 'Ask and answer, friendly or formal', icon: '❓', color: 'blue',
        grammar: ['Kako si? Kako ste?', `Kako si? asks a friend how they are. Kako ste? is the polite form, and also the plural.

Answer with Dobro sam — sam means "I am". Throw the question back with A ti? or A Vi?

Some words show who is speaking: a man says umoran sam, a woman says umorna sam. The extra ‑a for women is one of the most common patterns in Serbian.`],
        words: 'kako si = how are you? | kako ste = how are you? (formal) | dobro sam = I am fine | odlično = great | nije loše = not bad | tako-tako = so-so | umoran sam = I am tired (man) | umorna sam = I am tired (woman) | a ti = and you?',
        say: [
          ['Kako si, Ana?', 'How are you, Ana?'],
          ['Dobro sam, hvala. A ti?', 'I am fine, thanks. And you?'],
          ['Odlično, hvala!', 'Great, thanks!'],
          ['Kako ste danas?', 'How are you today?'],
          ['Umorna sam danas.', 'I am tired today.'],
        ],
        gaps: [
          ['Dobro ___, hvala.', 'sam', 'si ste', 'I am fine, thanks.'],
          ['Kako ___, gospodine?', 'ste', 'si sam', 'How are you, sir?'],
          ['Ja sam Ana i ___ sam.', 'umorna', 'umoran odlično', 'I am Ana and I am tired.'],
        ],
        replies: [
          ['Kako si?', 'How are you?', 'Dobro sam, hvala. A ti?', ['Zovem se Marko.', 'Laku noć!']],
          ['Kako ste?', 'How are you? (formal)', 'Odlično, hvala. A Vi?', ['Ne, hvala.', 'Umoran si.']],
        ],
        read: [{
          text: 'Kristina: Zdravo, Miloš! Kako si?\nMiloš: Nije loše, ali umoran sam. A ti?\nKristina: Odlično!',
          q: 'How is Miloš?', a: 'Not bad, but tired', wrong: ['Great', 'Very ill'],
          en: 'Kristina: Hi, Miloš! How are you? Miloš: Not bad, but I am tired. And you? Kristina: Great!',
        }],
      },
      {
        id: 'script-basics', title: 'Two alphabets', subtitle: 'Read Cyrillic and Latin', icon: '🔤', color: 'purple',
        grammar: ['One letter, one sound', `Serbian is written in two alphabets, Cyrillic (ћирилица) and Latin (latinica). Both are official and every Serb reads both.

Each letter always has the same sound, so once you know the letters you can read any word aloud.

Special Latin letters: č and ć (both close to "ch"), š (sh), ž (the s in "pleasure"), đ and dž (close to "j"), lj and nj (as in "million" and "canyon"), and j, which always sounds like "y".

Cyrillic look-alikes that sound different: В = v, Н = n, Р = r, С = s, Х = h.`],
        words: 'taksi = taxi | restoran = restaurant | muzej = museum | banka = bank | pošta = post office | apoteka = pharmacy | mama = mum | tata = dad | radio = radio',
        say: [
          ['Ovo je banka.', 'This is a bank.'],
          ['Gde je pošta?', 'Where is the post office?'],
          ['Taksi, molim vas!', 'Taxi, please!'],
          ['Mama i tata su ovde.', 'Mum and dad are here.'],
          ['Restoran je tamo.', 'The restaurant is over there.'],
        ],
        gaps: [
          ['Ovo je ___.', 'muzej', 'banka radio', 'This is a museum.'],
          ['Gde je ___?', 'apoteka', 'pošta taksi', 'Where is the pharmacy?'],
        ],
        replies: [
          ['Izvinite, gde je muzej?', 'Excuse me, where is the museum?', 'Tamo, desno.', ['Dobro sam, hvala.', 'Ja sam muzej.']],
        ],
        read: [
          { text: 'АПОТЕКА', q: 'What does this sign say?', a: 'Pharmacy', wrong: ['Post office', 'Bank'], en: 'Apoteka — pharmacy.' },
          { text: 'ПОШТА', q: 'What does this sign say?', a: 'Post office', wrong: ['Restaurant', 'Museum'], en: 'Pošta — post office.' },
          { text: 'Мама и тата су у ресторану.', q: 'Where are mum and dad?', a: 'In the restaurant', wrong: ['In the museum', 'In a taxi'], en: 'Mama i tata su u restoranu — Mum and dad are in the restaurant.' },
        ],
      },
    ],
  },
  {
    id: 'a1-who-i-am', title: 'Who I am',
    subtitle: 'Names, the verb "to be", countries and jobs',
    outcomes: ['Introduce yourself and others', 'Use sam, si, je, smo, ste, su', 'Say where you are from and where you live', 'Talk about jobs'],
    checkpoint: { id: 'a1-who-i-am-check', title: 'Who I am check', subtitle: 'Names, countries and jobs' },
    lessons: [
      {
        id: 'introductions', title: 'Meet & greet', subtitle: 'Names and introductions', icon: '💬', color: 'blue',
        grammar: ['Zovem se…', `Zovem se literally means "I call myself". The se stays and the verb changes: zovem se (I), zoveš se (you), zove se (he / she).

Ask: Kako se zoveš? (friend) or Kako se zovete? (polite).

When you meet someone, say Drago mi je — "nice to meet you". The usual answer is I meni (me too).

Introduce others with Ovo je…: Ovo je Ana, moja prijateljica.`],
        words: 'ja = I | ti = you | zovem se = my name is | kako se zoveš = what is your name? | kako se zovete = what is your name? (formal) | drago mi je = nice to meet you | i meni = me too | ovo je = this is | prijatelj = friend (man) | prijateljica = friend (woman)',
        say: [
          ['Zovem se Ana.', 'My name is Ana.'],
          ['Kako se zoveš?', 'What is your name?'],
          ['Ovo je Marko, moj prijatelj.', 'This is Marko, my friend.'],
          ['Drago mi je, Jelena.', 'Nice to meet you, Jelena.'],
          ['Ona se zove Kristina.', 'Her name is Kristina.'],
        ],
        gaps: [
          ['Kako se ___?', 'zoveš', 'zovem zove', 'What is your name?'],
          ['___ se Miloš.', 'Zovem', 'Zoveš Zove', 'My name is Miloš.'],
          ['Ovo je Ana, moja ___.', 'prijateljica', 'prijatelj sestra', 'This is Ana, my friend.'],
        ],
        replies: [
          ['Kako se zoveš?', 'What is your name?', 'Zovem se Nikola.', ['Dobro sam.', 'Drago mi je.']],
          ['Drago mi je!', 'Nice to meet you!', 'I meni!', ['Molim vas.', 'Laku noć!']],
        ],
        read: [{
          text: 'Zdravo! Zovem se Jelena. Ovo je Marko, moj prijatelj.',
          q: 'Who is Marko?', a: "Jelena's friend", wrong: ["Jelena's brother", "Jelena's teacher"],
          en: 'Hi! My name is Jelena. This is Marko, my friend.',
        }],
      },
      {
        id: 'to-be', title: 'I am, you are', subtitle: 'The verb biti, "to be"', icon: '🙋', color: 'green',
        grammar: ['Biti — to be', `ja sam · ti si · on / ona / ono je
mi smo · vi ste · oni su

The ending already tells you who, so the pronoun is often dropped: Student sam = Ja sam student.

These little forms never start a sentence: say Ja sam… or Student sam…, not Sam student.

Serbian has no "a" or "the": Ja sam student = I am a student.`],
        words: 'ja sam = I am | ti si = you are | on je = he is | ona je = she is | mi smo = we are | vi ste = you are (plural / formal) | oni su = they are | student = student (man) | studentkinja = student (woman) | ovde = here',
        say: [
          ['Ja sam student.', 'I am a student.'],
          ['Ona je studentkinja.', 'She is a student.'],
          ['Mi smo ovde.', 'We are here.'],
          ['Oni su prijatelji.', 'They are friends.'],
          ['Gde si ti?', 'Where are you?'],
          ['Vi ste Kristina?', 'Are you Kristina?'],
        ],
        gaps: [
          ['Mi ___ studenti.', 'smo', 'su ste', 'We are students.'],
          ['Ona ___ ovde.', 'je', 'sam si', 'She is here.'],
          ['Ja sam Ana. Ja sam ___.', 'studentkinja', 'student prijatelj', 'I am Ana. I am a student.'],
          ['Oni ___ prijatelji.', 'su', 'smo je', 'They are friends.'],
        ],
        replies: [
          ['Ti si Marko?', 'Are you Marko?', 'Da, ja sam Marko.', ['Da, on je Marko.', 'Ne, hvala.']],
          ['Gde ste vi?', 'Where are you? (plural)', 'Mi smo ovde.', ['Oni su ovde.', 'Ja sam student.']],
        ],
        read: [{
          text: 'Zdravo! Ja sam Nikola i ja sam student. Ovo je Jelena. Ona je moja prijateljica i ona je studentkinja.',
          q: 'What do Nikola and Jelena have in common?', a: 'They are both students', wrong: ['They are brother and sister', 'They are teachers'],
          en: 'Hi! I am Nikola and I am a student. This is Jelena. She is my friend and she is a student.',
        }],
      },
      {
        id: 'countries', title: 'Where are you from?', subtitle: 'Countries and cities', icon: '🌍', color: 'orange',
        grammar: ['Iz and u', `Iz means "from" and changes the country's ending: Srbija → iz Srbije, Engleska → iz Engleske, Amerika → iz Amerike (‑a becomes ‑e).

U means "in" and uses another ending: u Srbiji, u Engleskoj, u Londonu, u Beogradu.

For now, learn them as fixed phrases. The pattern will click with practice.`],
        words: 'odakle si = where are you from? | ja sam iz = I am from | Srbija = Serbia | Engleska = England | Amerika = America | Australija = Australia | živim u = I live in | Beograd = Belgrade | London = London | grad = city',
        say: [
          ['Ja sam iz Engleske.', 'I am from England.'],
          ['Odakle si ti?', 'Where are you from?'],
          ['Živim u Beogradu.', 'I live in Belgrade.'],
          ['Ana je iz Srbije.', 'Ana is from Serbia.'],
          ['Marko živi u Londonu.', 'Marko lives in London.'],
          ['Mi smo iz Amerike.', 'We are from America.'],
        ],
        gaps: [
          ['Ja sam iz ___.', 'Srbije', 'Srbija Srbiji', 'I am from Serbia.'],
          ['Živim u ___.', 'Beogradu', 'Beograd Londonu', 'I live in Belgrade.'],
          ['Odakle ___?', 'si', 'sam je', 'Where are you from?'],
        ],
        replies: [
          ['Odakle si?', 'Where are you from?', 'Ja sam iz Australije.', ['Zovem se Ana.', 'Ja sam iz Australija.']],
          ['Gde živiš?', 'Where do you live?', 'Živim u Srbiji.', ['Ja sam Srbija.', 'Dobro sam, hvala.']],
        ],
        read: [{
          text: 'Ovo su Ana i Marko. Ana je iz Srbije i živi u Beogradu. Marko je iz Engleske, ali sada živi u Novom Sadu.',
          q: 'Where does Marko live now?', a: 'In Novi Sad', wrong: ['In London', 'In Belgrade'],
          en: 'This is Ana and Marko. Ana is from Serbia and lives in Belgrade. Marko is from England, but now he lives in Novi Sad.',
        }],
      },
      {
        id: 'jobs', title: 'What do you do?', subtitle: 'Jobs for him and for her', icon: '💼', color: 'pink',
        grammar: ['Jobs come in pairs', `The masculine form usually ends in a consonant. The feminine form adds an ending:
• nastavnik → nastavnica
• lekar → lekarka
• konobar → konobarica
• student → studentkinja

To ask what someone does, say Šta radiš? Answer with Ja sam lekar. There is no word for "a".`],
        words: 'šta radiš = what do you do? | posao = job | nastavnik = teacher (man) | nastavnica = teacher (woman) | lekar = doctor (man) | lekarka = doctor (woman) | konobar = waiter | konobarica = waitress | programer = programmer | radim u = I work in',
        say: [
          ['Ja sam nastavnica.', 'I am a teacher.'],
          ['On je lekar.', 'He is a doctor.'],
          ['Šta radiš?', 'What do you do?'],
          ['Ona je konobarica u kafiću.', 'She is a waitress in a café.'],
          ['Radim u školi.', 'I work at a school.'],
          ['Marko je programer.', 'Marko is a programmer.'],
        ],
        gaps: [
          ['Jelena je ___.', 'lekarka', 'lekar konobar', 'Jelena is a doctor.'],
          ['Moj brat je ___.', 'nastavnik', 'nastavnica lekarka', 'My brother is a teacher.'],
          ['Ja ___ u Beogradu.', 'radim', 'radiš živi', 'I work in Belgrade.'],
        ],
        replies: [
          ['Šta radiš?', 'What do you do?', 'Ja sam programer.', ['Ja sam iz Srbije.', 'Dobro sam.']],
          ['Vi ste lekar?', 'Are you a doctor?', 'Ne, ja sam nastavnik.', ['Ne, hvala.', 'Drago mi je.']],
        ],
        read: [{
          text: 'Zovem se Nikola. Ja sam konobar u kafiću u Beogradu. Moja sestra Jelena je lekarka.',
          q: 'What does Jelena do?', a: 'She is a doctor', wrong: ['She is a waitress', 'She is a teacher'],
          en: 'My name is Nikola. I am a waiter in a café in Belgrade. My sister Jelena is a doctor.',
        }],
      },
    ],
  },
  {
    id: 'a1-things', title: 'Things around me',
    subtitle: 'Noun gender, adjectives, colours and places',
    outcomes: ['Tell masculine, feminine and neuter nouns apart', 'Make adjectives agree', 'Name colours', 'Say where things are'],
    checkpoint: { id: 'a1-things-check', title: 'Things around me check', subtitle: 'Gender, colours and places' },
    lessons: [
      {
        id: 'gender', title: 'He, she or it?', subtitle: 'Noun gender', icon: '📦', color: 'purple',
        grammar: ['Every noun has a gender', `You can almost always tell a noun's gender from its ending:
• masculine — a consonant: sto, telefon, ključ
• feminine — ‑a: knjiga, torba, olovka
• neuter — ‑o or ‑e: pismo, ogledalo, more

Gender matters because the words around a noun change to match it: moj telefon, moja knjiga, moje pismo.`],
        words: 'sto = table | telefon = phone | ključ = key | knjiga = book | torba = bag | olovka = pen | pismo = letter | ogledalo = mirror | šta je ovo = what is this?',
        say: [
          ['Šta je ovo?', 'What is this?'],
          ['Ovo je moj telefon.', 'This is my phone.'],
          ['Ovo je moja knjiga.', 'This is my book.'],
          ['Ovo je moje pismo.', 'This is my letter.'],
          ['Gde je moja torba?', 'Where is my bag?'],
          ['Ključ je na stolu.', 'The key is on the table.'],
        ],
        gaps: [
          ['Ovo je ___ telefon.', 'moj', 'moja moje', 'This is my phone.'],
          ['Ovo je ___ olovka.', 'moja', 'moj moje', 'This is my pen.'],
          ['Ovo je ___ ogledalo.', 'moje', 'moj moja', 'This is my mirror.'],
        ],
        replies: [
          ['Šta je ovo?', 'What is this?', 'Ovo je knjiga.', ['Hvala, dobro.', 'Ja sam iz Srbije.']],
        ],
      },
      {
        id: 'a1-personal-world-describing-things', title: 'Big and small', subtitle: 'Adjectives that agree', icon: '📝', color: 'orange',
        grammar: ['Adjectives copy the noun', `An adjective takes the gender of its noun:
• masculine — no ending: nov telefon
• feminine — ‑a: nova knjiga
• neuter — ‑o: novo pismo

That is why it is dobar dan but dobro jutro! Dobar loses its second a when it adds an ending: dobra, dobro.

Veliki and mali usually keep their ‑i in the masculine: veliki grad, mali stan.`],
        words: 'veliki = big | mali = small | nov = new | star = old | lep = beautiful | dobar = good | skup = expensive | jeftin = cheap | selo = village',
        say: [
          ['Beograd je veliki grad.', 'Belgrade is a big city.'],
          ['Ovo je nova knjiga.', 'This is a new book.'],
          ['Telefon je skup.', 'The phone is expensive.'],
          ['Moja torba je mala.', 'My bag is small.'],
          ['Pismo je novo i lepo.', 'The letter is new and nice.'],
          ['Ovo selo je staro.', 'This village is old.'],
        ],
        gaps: [
          ['Ovo je ___ telefon.', 'nov', 'nova novo', 'This is a new phone.'],
          ['Kafa je ___.', 'dobra', 'dobar dobro', 'The coffee is good.'],
          ['Knjiga je ___.', 'jeftina', 'jeftin skup', 'The book is cheap.'],
        ],
        replies: [
          ['Telefon je skup?', 'Is the phone expensive?', 'Ne, jeftin je.', ['Ne, jeftina je.', 'Da, hvala.']],
          ['Kakva je kafa?', 'How is the coffee?', 'Odlična je!', ['Odličan je!', 'Ja sam dobro.']],
        ],
        read: [{
          text: 'Moj grad je mali, ali lep. Moja kuća je stara, a moj telefon je nov. Knjiga je jeftina.',
          q: 'What is new?', a: 'The phone', wrong: ['The house', 'The city'],
          en: 'My town is small but beautiful. My house is old, and my phone is new. The book is cheap.',
        }],
      },
      {
        id: 'colours', title: 'Colours', subtitle: 'Red, blue, green and more', icon: '🎨', color: 'pink',
        grammar: ['Colours agree too', `Colours are adjectives, so they change like nov:
• crven telefon, crvena torba, crveno pismo
• plav, plava, plavo — blue

Beo (white) is a little special: beo telefon, bela kuća, belo pismo.

Ask about colour with Kakve je boje…? — "of what colour is…?"`],
        words: 'crven = red | plav = blue | zelen = green | žut = yellow | beo = white | crn = black | siv = grey | boja = colour | kakve je boje = what colour is it?',
        say: [
          ['Moja torba je crvena.', 'My bag is red.'],
          ['More je plavo.', 'The sea is blue.'],
          ['Sunce je žuto.', 'The sun is yellow.'],
          ['Kakve je boje knjiga?', 'What colour is the book?'],
          ['Knjiga je zelena.', 'The book is green.'],
          ['Moj telefon je siv.', 'My phone is grey.'],
        ],
        gaps: [
          ['Olovka je ___.', 'žuta', 'žut žuto', 'The pen is yellow.'],
          ['Pismo je ___.', 'belo', 'beo bela', 'The letter is white.'],
          ['Sto je ___.', 'crn', 'crna plavo', 'The table is black.'],
        ],
        replies: [
          ['Kakve je boje tvoja torba?', 'What colour is your bag?', 'Crvena je.', ['Crven je.', 'Crveno je.']],
          ['Da li je more zeleno?', 'Is the sea green?', 'Ne, more je plavo.', ['Ne, more je plava.', 'Da, hvala.']],
        ],
        read: [{
          text: 'Moja soba je mala i bela. Sto je beo, olovka je žuta, a knjiga je crna.',
          q: 'What colour is the book?', a: 'Black', wrong: ['Yellow', 'White'],
          en: 'My room is small and white. The table is white, the pen is yellow, and the book is black.',
        }],
      },
      {
        id: 'places', title: 'Where is it?', subtitle: 'Here, there, on and in', icon: '📍', color: 'blue',
        grammar: ['Gde je…?', `Gde je…? asks where something is. Answer with ovde (here), tamo (there), blizu (near) or daleko (far).

To say "on" and "in", use na and u. The noun changes its ending:
• sto → na stolu (on the table)
• torba → u torbi (in the bag)
• kuća → u kući (in the house)

Pored (next to) and ispod (under) work the same way: pored telefona, ispod stola. Learn them as phrases for now.`],
        words: 'gde je = where is | ovde = here | tamo = there | blizu = near | daleko = far | na stolu = on the table | u torbi = in the bag | pored = next to | ispod = under',
        say: [
          ['Gde je moj telefon?', 'Where is my phone?'],
          ['Telefon je na stolu.', 'The phone is on the table.'],
          ['Ključ je u torbi.', 'The key is in the bag.'],
          ['Pošta je tamo, levo.', 'The post office is there, on the left.'],
          ['Banka je blizu.', 'The bank is near.'],
          ['Torba je ispod stola.', 'The bag is under the table.'],
        ],
        gaps: [
          ['Knjiga je na ___.', 'stolu', 'sto torbi', 'The book is on the table.'],
          ['Olovka je u ___.', 'torbi', 'torba stolu', 'The pen is in the bag.'],
          ['Apoteka nije ___, blizu je.', 'daleko', 'blizu ovde', 'The pharmacy is not far, it is near.'],
        ],
        replies: [
          ['Gde je ključ?', 'Where is the key?', 'Tamo, na stolu.', ['Tamo, na sto.', 'Ključ je dobro.']],
          ['Izvinite, gde je banka?', 'Excuse me, where is the bank?', 'Desno, blizu je.', ['Hvala, dobro sam.', 'Banka je iz Srbije.']],
        ],
        read: [{
          text: 'Moja soba je mala. Sto je levo, a prozor je desno. Knjiga je na stolu, a telefon je u torbi.',
          q: 'Where is the phone?', a: 'In the bag', wrong: ['On the table', 'By the window'],
          en: 'My room is small. The table is on the left and the window is on the right. The book is on the table, and the phone is in the bag.',
        }],
      },
    ],
  },
  {
    id: 'a1-everyday-verbs', title: 'Everyday verbs',
    subtitle: 'Have, not, questions and languages',
    outcomes: ['Use imati, "to have"', 'Make sentences negative', 'Ask yes/no and wh- questions', 'Talk about the languages you speak'],
    checkpoint: { id: 'a1-verbs-check', title: 'Everyday verbs check', subtitle: 'Have, not, questions' },
    lessons: [
      {
        id: 'have', title: 'I have', subtitle: 'The verb imati', icon: '🎒', color: 'green',
        grammar: ['Imati — to have', `imam · imaš · ima · imamo · imate · imaju

Imati is a regular ‑am verb. Learn it and you know hundreds of verbs that work the same way.

After "have" (and most verbs), feminine nouns change ‑a to ‑u: Imam sestru, Imam mačku.

Masculine things stay the same (Imam auto, Imam telefon), but people and animals add ‑a: brat → Imam brata, pas → Imam psa.`],
        words: 'imam = I have | imaš = you have | ima = he / she has | imamo = we have | imate = you have (plural / formal) | imaju = they have | pas = dog | mačka = cat | auto = car',
        say: [
          ['Imam brata i sestru.', 'I have a brother and a sister.'],
          ['Imaš li psa?', 'Do you have a dog?'],
          ['Ana ima mačku.', 'Ana has a cat.'],
          ['Mi imamo auto.', 'We have a car.'],
          ['Imam novi telefon.', 'I have a new phone.'],
        ],
        gaps: [
          ['Imam ___.', 'sestru', 'sestra brat', 'I have a sister.'],
          ['Marko ___ psa.', 'ima', 'imam imaš', 'Marko has a dog.'],
          ['Imamo ___.', 'mačku', 'mačka pas', 'We have a cat.'],
        ],
        replies: [
          ['Imaš li brata?', 'Do you have a brother?', 'Da, imam brata.', ['Da, imam brat.', 'Da, ja sam brat.']],
          ['Imate li auto?', 'Do you have a car?', 'Da, imamo auto.', ['Da, imaju auto.', 'Ne, hvala.']],
        ],
        read: [{
          text: 'Jelena ima brata i sestru. Brat se zove Nikola, a sestra se zove Ana. Imaju i psa.',
          q: 'How many siblings does Jelena have?', a: 'Two', wrong: ['One', 'Three'],
          en: 'Jelena has a brother and a sister. The brother is called Nikola and the sister is called Ana. They also have a dog.',
        }],
      },
      {
        id: 'not', title: 'Not and never', subtitle: 'Saying no in a sentence', icon: '🚫', color: 'pink',
        grammar: ['Ne, nisam, nemam', `Put ne before a verb to make it negative: ne znam, ne razumem, ne radim.

Two verbs fuse with ne into one word:
• biti → nisam, nisi, nije, nismo, niste, nisu
• imati → nemam, nemaš, nema…

Nema also means "there isn't": Nema problema!

Serbian loves double negatives: Nikad ne pijem kafu (I never drink coffee). The ne stays even with nikad or ništa.`],
        words: 'nisam = I am not | nije = is not | nemam = I do not have | nema = there is not | ne znam = I do not know | ne razumem = I do not understand | nikad = never | ništa = nothing | ali = but',
        say: [
          ['Ja nisam lekar.', 'I am not a doctor.'],
          ['Nemam auto.', 'I do not have a car.'],
          ['Ne znam, izvini.', 'I do not know, sorry.'],
          ['On nije ovde.', 'He is not here.'],
          ['Ne razumem ništa.', 'I do not understand anything.'],
          ['Nikad ne pijem kafu.', 'I never drink coffee.'],
        ],
        gaps: [
          ['Ja ___ student.', 'nisam', 'nemam nije', 'I am not a student.'],
          ['Marko ___ brata.', 'nema', 'nije nemam', 'Marko does not have a brother.'],
          ['Ne razumem ___.', 'ništa', 'nikad ali', 'I do not understand anything.'],
        ],
        replies: [
          ['Ti si iz Engleske?', 'Are you from England?', 'Ne, nisam. Ja sam iz Amerike.', ['Ne, nemam.', 'Da, nisam.']],
          ['Izvinite, gde je pošta?', 'Excuse me, where is the post office?', 'Ne znam, izvinite.', ['Nemam poštu.', 'Dobro sam.']],
        ],
        read: [{
          text: 'Miloš nije student. On je programer. Nema auto, ali ima psa. Nikad ne pije kafu.',
          q: 'What does Miloš never do?', a: 'Drink coffee', wrong: ['Walk his dog', 'Work'],
          en: 'Miloš is not a student. He is a programmer. He does not have a car, but he has a dog. He never drinks coffee.',
        }],
      },
      {
        id: 'asking', title: 'Asking questions', subtitle: 'Da li, who, where, when, why', icon: '🔎', color: 'blue',
        grammar: ['Questions', `Turn any statement into a yes/no question with Da li at the front: Imaš psa → Da li imaš psa?

Or put li straight after the verb: Imaš li psa? Both are correct.

Question words go first: Šta radiš? Ko je to? Gde živiš? Kada radiš? Zašto učiš srpski?

Answer zašto (why) with zato što (because).`],
        words: 'da li = (starts a yes/no question) | šta = what | ko = who | gde = where | kada = when | zašto = why | kako = how | koliko = how much / how many | zato što = because',
        say: [
          ['Da li imaš psa?', 'Do you have a dog?'],
          ['Ko je to?', 'Who is that?'],
          ['Kada radiš?', 'When do you work?'],
          ['Zašto učiš srpski?', 'Why are you learning Serbian?'],
          ['Koliko košta kafa?', 'How much is the coffee?'],
          ['Učim srpski zato što volim Srbiju.', 'I am learning Serbian because I love Serbia.'],
        ],
        gaps: [
          ['___ je to? To je moj brat.', 'Ko', 'Šta Gde', 'Who is that? That is my brother.'],
          ['___ živiš? U Beogradu.', 'Gde', 'Kada Ko', 'Where do you live? In Belgrade.'],
          ['___ li psa?', 'Imaš', 'Imam Nemam', 'Do you have a dog?'],
        ],
        replies: [
          ['Zašto učiš srpski?', 'Why are you learning Serbian?', 'Zato što živim u Srbiji.', ['U Beogradu.', 'Da, učim.']],
          ['Ko je to?', 'Who is that?', 'To je moja sestra.', ['To je moja sestru.', 'Gde je sestra?']],
        ],
      },
      {
        id: 'languages', title: 'Do you speak Serbian?', subtitle: 'Know, understand, speak', icon: '🗣️', color: 'orange',
        grammar: ['Three verb families', `Serbian verbs fall into three families by their "I" form:
• ‑am: imam, znam
• ‑em: razumem
• ‑im: govorim, radim

The "you" form swaps ‑m for ‑š: znaš, razumeš, govoriš. For he / she, drop the ‑m: zna, razume, govori.

Life-saving phrases: Govorite li engleski? · Ponovite, molim vas. · Sporije, molim vas.`],
        words: 'znam = I know | razumem = I understand | govorim = I speak | srpski = Serbian | engleski = English | malo = a little | sporije = more slowly | ponovite = please repeat | jezik = language',
        say: [
          ['Govorim malo srpski.', 'I speak a little Serbian.'],
          ['Da li govorite engleski?', 'Do you speak English?'],
          ['Ne razumem, ponovite, molim vas.', 'I do not understand, please repeat.'],
          ['Možete li da govorite sporije?', 'Can you speak more slowly?'],
          ['Srpski je lep jezik.', 'Serbian is a beautiful language.'],
        ],
        gaps: [
          ['Ja ___ srpski.', 'govorim', 'govoriš govori', 'I speak Serbian.'],
          ['Da li ___ engleski?', 'govoriš', 'govorim govorite', 'Do you speak English?'],
          ['Ne ___.', 'razumem', 'razumeš znam', 'I do not understand.'],
        ],
        replies: [
          ['Razumeš li?', 'Do you understand?', 'Da, razumem.', ['Da, razumeš.', 'Ne, hvala.']],
          ['Govorite li srpski?', 'Do you speak Serbian?', 'Da, malo.', ['Da, mali.', 'Ja sam srpski.']],
        ],
        read: [{
          text: 'Zara je iz Engleske. Ona govori engleski i malo srpski. Kada ljudi govore brzo, ona ne razume i kaže: Sporije, molim vas!',
          q: 'What does Zara say when people speak fast?', a: 'More slowly, please!', wrong: ['Good night!', 'I am from England.'],
          en: 'Zara is from England. She speaks English and a little Serbian. When people speak fast, she does not understand and says: More slowly, please!',
        }],
      },
    ],
  },
  {
    id: 'a1-cafe-shop', title: 'Café & shop',
    subtitle: 'Numbers, prices, ordering and shopping',
    outcomes: ['Count to ten and use bigger numbers', 'Ask and understand prices', 'Order drinks politely', 'Buy food in a shop'],
    checkpoint: { id: 'a1-essentials-check', title: 'Café & shop check', subtitle: 'Numbers, prices and ordering' },
    lessons: [
      {
        id: 'numbers', title: 'Count on me', subtitle: 'Numbers one to ten', icon: '🔢', color: 'purple',
        grammar: ['Numbers that agree', `Jedan (one) is an adjective and agrees with its noun: jedan sto, jedna kafa, jedno pismo.

Dva (two) has a feminine form: dva telefona, but dve kafe.

After numbers, the noun ending changes: dve kafe, pet kafa. Don't worry about the rules yet. Learn the phrases and listen for the pattern.

Age uses imati: Imam dvadeset godina — "I have twenty years".`],
        words: 'jedan = one | dva = two | tri = three | četiri = four | pet = five | šest = six | sedam = seven | osam = eight | devet = nine | deset = ten',
        say: [
          ['Imam dva brata.', 'I have two brothers.'],
          ['Imam jednu sestru.', 'I have one sister.'],
          ['Ona ima osam godina.', 'She is eight years old.'],
          ['Imam deset knjiga.', 'I have ten books.'],
          ['Tri i četiri je sedam.', 'Three and four is seven.'],
        ],
        gaps: [
          ['Ovo je ___ olovka.', 'jedna', 'jedan jedno', 'This is one pen.'],
          ['Imam ___ telefon.', 'jedan', 'jedna jedno', 'I have one phone.'],
          ['___ i dva je pet.', 'Tri', 'Četiri Šest', 'Three and two is five.'],
        ],
        replies: [
          ['Koliko imaš godina?', 'How old are you?', 'Imam devet godina.', ['Ja sam devet godina.', 'Zovem se Devet.']],
        ],
        read: [{
          text: 'Na stolu je jedno pismo, dve knjige i tri olovke.',
          q: 'How many pens are on the table?', a: 'Three', wrong: ['Two', 'One'],
          en: 'On the table there is one letter, two books and three pens.',
        }],
      },
      {
        id: 'a1-food-shopping-money-and-quantities', title: 'How much is it?', subtitle: 'Bigger numbers and prices', icon: '💵', color: 'orange',
        grammar: ['Bigger numbers', `11–19 add ‑naest: jedanaest, dvanaest, trinaest…
Tens add ‑deset: dvadeset, trideset, četrdeset, pedeset.

Combine them freely: dvadeset pet (25), sto dvadeset (120).

Sto means both "hundred" and "table". The context decides!

Prices use the dinar: jedan dinar, dva dinara, pet dinara.`],
        words: 'jedanaest = eleven | dvadeset = twenty | trideset = thirty | pedeset = fifty | sto = one hundred | hiljada = thousand | dinar = dinar | koliko košta = how much is it? | skupo = expensive | jeftino = cheap',
        say: [
          ['Koliko košta hleb?', 'How much is the bread?'],
          ['Hleb košta pedeset dinara.', 'The bread costs fifty dinars.'],
          ['To je skupo!', 'That is expensive!'],
          ['Kafa košta sto dinara.', 'The coffee costs one hundred dinars.'],
          ['Ovo je jeftino.', 'This is cheap.'],
        ],
        gaps: [
          ['Karta košta dvadeset ___.', 'dinara', 'dinar sto', 'The ticket costs twenty dinars.'],
          ['Koliko ___ kafa?', 'košta', 'skupo dinar', 'How much is the coffee?'],
          ['Sto dinara? To je ___!', 'jeftino', 'skupo hiljada', 'One hundred dinars? That is cheap!'],
        ],
        replies: [
          ['Koliko košta sok?', 'How much is the juice?', 'Sto dvadeset dinara.', ['Sok je dobar.', 'Dvadeset godina.']],
          ['Kafa košta hiljadu dinara!', 'The coffee costs a thousand dinars!', 'Šta? To je skupo!', ['Odlično, jeftino je.', 'Ja sam hiljadu.']],
        ],
      },
      {
        id: 'coffee', title: 'At the café', subtitle: 'Order drinks like a local', icon: '☕', color: 'orange',
        grammar: ['Ordering: ‑a becomes ‑u', `When you order, the thing you want is the object, so feminine words change ‑a to ‑u:
• kafa → Jednu kafu, molim.
• voda → Vodu, molim.

Masculine and neuter drinks don't change: čaj, sok, pivo, vino.

Želim (I would like) is polite. Finish with Račun, molim! and don't forget hvala.`],
        words: 'kafa = coffee | čaj = tea | voda = water | sok = juice | pivo = beer | vino = wine | želim = I would like | šećer = sugar | sa mlekom = with milk | račun = the bill',
        say: [
          ['Jednu kafu, molim vas.', 'One coffee, please.'],
          ['Želim čaj sa mlekom.', 'I would like tea with milk.'],
          ['Račun, molim!', 'The bill, please!'],
          ['Dva piva i jedan sok, molim.', 'Two beers and one juice, please.'],
          ['Da li imate vino?', 'Do you have wine?'],
          ['Kafu bez šećera, molim.', 'Coffee without sugar, please.'],
        ],
        gaps: [
          ['Jednu ___, molim.', 'kafu', 'kafa čaj', 'One coffee, please.'],
          ['Želim ___, molim vas.', 'vodu', 'voda vino', 'I would like water, please.'],
          ['Želim ___.', 'sok', 'kafu vodu', 'I would like a juice.'],
        ],
        replies: [
          ['Izvolite, šta želite?', 'Here you are, what would you like?', 'Jednu kafu, molim.', ['Jedna kafu, molim.', 'Hvala, laku noć.']],
          ['Još nešto?', 'Anything else?', 'Ne, hvala. Račun, molim.', ['Da, ja sam račun.', 'Dobro jutro.']],
        ],
        read: [{
          text: 'Kafić „Sunce“\nKafa — 150 dinara\nČaj — 120 dinara\nSok — 180 dinara',
          audio: 'Kafić Sunce. Kafa, sto pedeset dinara. Čaj, sto dvadeset dinara. Sok, sto osamdeset dinara.',
          q: 'What is the cheapest drink?', a: 'Tea', wrong: ['Coffee', 'Juice'],
          en: 'Café "Sun": coffee 150 dinars, tea 120 dinars, juice 180 dinars.',
        }],
      },
      {
        id: 'a1-food-shopping-in-a-shop', title: 'In a shop', subtitle: 'Bread, milk and a kilo of apples', icon: '🛒', color: 'green',
        grammar: ['Shop phrases', `You will hear Izvolite (here you are / how can I help?) and Još nešto? (anything else?).

Ask with Dajte mi… (give me…) plus the item: Dajte mi hleb i mleko.

Quantities use a special ending: kilo jabuka, litar mleka. Learn them as phrases for now.

End with To je sve, hvala — that's all, thanks.`],
        words: 'hleb = bread | mleko = milk | sir = cheese | jaja = eggs | jabuke = apples | kilo = kilo | dajte mi = give me (formal) | još nešto = anything else? | to je sve = that is all | izvolite = here you are',
        say: [
          ['Dajte mi hleb, molim vas.', 'Give me bread, please.'],
          ['Kilo jabuka, molim.', 'A kilo of apples, please.'],
          ['Imate li sir?', 'Do you have cheese?'],
          ['To je sve, hvala.', 'That is all, thanks.'],
          ['Koliko koštaju jaja?', 'How much are the eggs?'],
        ],
        gaps: [
          ['To je ___, hvala.', 'sve', 'još nešto', 'That is all, thanks.'],
          ['Dajte ___ mleko.', 'mi', 'vi ti', 'Give me milk.'],
          ['Kilo ___, molim.', 'jabuka', 'jabuke mleko', 'A kilo of apples, please.'],
        ],
        replies: [
          ['Izvolite?', 'How can I help?', 'Dajte mi kilo jabuka, molim.', ['Ja sam kilo jabuka.', 'Doviđenja!']],
          ['Još nešto?', 'Anything else?', 'To je sve, hvala.', ['Da, nemam.', 'Sve je kilo.']],
        ],
        read: [{
          text: 'Lista za prodavnicu: hleb, mleko, šest jaja, kilo jabuka i sir.',
          q: 'How many eggs are on the list?', a: 'Six', wrong: ['Ten', 'One kilo'],
          en: 'Shopping list: bread, milk, six eggs, a kilo of apples and cheese.',
        }],
      },
    ],
  },
  {
    id: 'a1-my-day', title: 'My day',
    subtitle: 'Routines, meals, the time and the week',
    outcomes: ['Describe a daily routine', 'Use jesti and piti', 'Tell the time', 'Talk about days of the week'],
    checkpoint: { id: 'a1-daily-rhythm-daily-life-review', title: 'My day check', subtitle: 'Routines, meals and time' },
    lessons: [
      {
        id: 'daily-life', title: 'A simple day', subtitle: 'Present tense routines', icon: '🌤️', color: 'green',
        grammar: ['The present tense', `Almost every verb ends in ‑m in the "I" form:
• ‑am: gledam, spavam, ručam
• ‑im: radim, učim
• ‑em: ustajem, idem

Change ‑m to ‑š for "you": radiš, gledaš, ideš. Drop the ‑m for he / she: radi, gleda, ide.

Time words: ujutru (in the morning), posle podne (in the afternoon), uveče (in the evening).`],
        words: 'ustajem = I get up | radim = I work | učim = I study | ručam = I have lunch | idem = I go | gledam = I watch | spavam = I sleep | ujutru = in the morning | uveče = in the evening',
        say: [
          ['Ustajem u sedam.', 'I get up at seven.'],
          ['Ujutru radim, a uveče učim.', 'In the morning I work, and in the evening I study.'],
          ['Idem na posao.', 'I am going to work.'],
          ['Uveče gledam film.', 'In the evening I watch a film.'],
          ['Ručam u podne.', 'I have lunch at noon.'],
          ['Spavam do osam.', 'I sleep until eight.'],
        ],
        gaps: [
          ['Ana ___ u školi.', 'uči', 'učim učiš', 'Ana studies at school.'],
          ['Ja ___ film.', 'gledam', 'gleda spavam', 'I am watching a film.'],
          ['___ idem na posao.', 'Ujutru', 'Uveče Sada', 'In the morning I go to work.'],
        ],
        replies: [
          ['Šta radiš uveče?', 'What do you do in the evening?', 'Uveče gledam film.', ['Uveče gleda film.', 'Ujutru, hvala.']],
          ['Kada ustaješ?', 'When do you get up?', 'Ustajem u sedam.', ['Ustaje u sedam.', 'Spavam, hvala.']],
          ['Šta učiš?', 'What are you studying?', 'Učim srpski.', ['Uči srpski.', 'Učim u sedam.']],
        ],
        read: [{
          text: 'Miloš ustaje u sedam. Ujutru radi, a posle podne uči srpski. Uveče gleda film i spava u jedanaest.',
          q: 'What does Miloš do in the afternoon?', a: 'He studies Serbian', wrong: ['He watches a film', 'He sleeps'],
          en: 'Miloš gets up at seven. In the morning he works, and in the afternoon he studies Serbian. In the evening he watches a film and goes to sleep at eleven.',
        }],
      },
      {
        id: 'eat-drink', title: 'Eat and drink', subtitle: 'Meals and two irregular verbs', icon: '🍽️', color: 'orange',
        grammar: ['Jesti and piti', `Two very common verbs are irregular:
• jesti (eat): jedem, jedeš, jede, jedemo, jedete, jedu
• piti (drink): pijem, piješ, pije, pijemo, pijete, piju

Meals: doručak, ručak, večera. In Serbia ručak is the big meal, often eaten around two or three o'clock.

Hungry: gladan sam (man) / gladna sam (woman).`],
        words: 'jedem = I eat | pijem = I drink | jedeš = you eat | piješ = you drink | doručak = breakfast | ručak = lunch | večera = dinner | meso = meat | salata = salad | gladan sam = I am hungry (man)',
        say: [
          ['Za doručak jedem hleb i sir.', 'For breakfast I eat bread and cheese.'],
          ['Šta piješ?', 'What are you drinking?'],
          ['Ne pijem kafu.', 'I do not drink coffee.'],
          ['Ručak je u dva.', 'Lunch is at two.'],
          ['Gladna sam!', 'I am hungry!'],
          ['Za večeru jedemo salatu.', 'For dinner we eat salad.'],
        ],
        gaps: [
          ['Ja ___ vodu.', 'pijem', 'piješ pije', 'I drink water.'],
          ['Šta ___ za doručak?', 'jedeš', 'jedem piješ', 'What do you eat for breakfast?'],
          ['Marko je ___.', 'gladan', 'gladna umorna', 'Marko is hungry.'],
        ],
        replies: [
          ['Šta jedeš za doručak?', 'What do you eat for breakfast?', 'Jedem hleb i jaja.', ['Jedeš hleb i jaja.', 'Pijem doručak.']],
          ['Jesi li gladan?', 'Are you hungry?', 'Da, gladan sam!', ['Da, gladan si!', 'Ne, imam.']],
        ],
      },
      {
        id: 'time', title: 'What time is it?', subtitle: 'Hours, half past and at', icon: '🕒', color: 'blue',
        grammar: ['Telling the time', `Koliko je sati? — literally "how many hours is it?"

The word for hour changes after the number:
• jedan sat (1)
• dva, tri, četiri sata (2–4)
• pet sati and up (5–12)

Half past is i po: sedam i po = 7:30. "At" a time is u: u osam, u podne.

Timetables use the 24-hour clock.`],
        words: 'koliko je sati = what time is it? | sat = hour / clock | sada = now | sati = o\'clock (5 and up) | i po = half past | u podne = at noon | ponoć = midnight | rano = early | kasno = late | minut = minute',
        say: [
          ['Koliko je sati?', 'What time is it?'],
          ['Sada je tri sata.', 'It is three o\'clock now.'],
          ['Film je u osam sati.', 'The film is at eight o\'clock.'],
          ['Kasno je, idem kući.', 'It is late, I am going home.'],
          ['Sastanak je u devet i po.', 'The meeting is at half past nine.'],
        ],
        gaps: [
          ['Sada je dva ___.', 'sata', 'sati sat', 'It is two o\'clock now.'],
          ['Sada je deset ___.', 'sati', 'sata sat', 'It is ten o\'clock now.'],
          ['Voz polazi u šest i ___.', 'po', 'pet sat', 'The train leaves at half past six.'],
        ],
        replies: [
          ['Koliko je sati?', 'What time is it?', 'Sada je pet sati.', ['Sada je pet sata.', 'Imam pet godina.']],
          ['Kada je film?', 'When is the film?', 'U osam i po.', ['Osam godina.', 'Film je dobar.']],
        ],
        read: [{
          text: 'Kristina radi od devet do pet. U podne ruča sa koleginicom. U sedam i po uveče gleda film.',
          q: 'When does Kristina have lunch?', a: 'At noon', wrong: ['At nine', 'At half past seven'],
          en: 'Kristina works from nine to five. At noon she has lunch with a colleague. At half past seven in the evening she watches a film.',
        }],
      },
      {
        id: 'a1-daily-rhythm-days-and-dates', title: 'Days of the week', subtitle: 'Monday to Sunday', icon: '📅', color: 'pink',
        grammar: ['On Monday…', `Days are not capitalised in Serbian.

"On Monday" is u + the day. The feminine days change ‑a to ‑u:
• u ponedeljak, u utorak, u četvrtak, u petak
• but u sredu, u subotu, u nedelju

Nedelja also means "week". Danas (today), sutra (tomorrow), juče (yesterday).`],
        words: 'ponedeljak = Monday | utorak = Tuesday | sreda = Wednesday | četvrtak = Thursday | petak = Friday | subota = Saturday | nedelja = Sunday | danas = today | sutra = tomorrow | juče = yesterday',
        say: [
          ['Danas je ponedeljak.', 'Today is Monday.'],
          ['U subotu idem u Novi Sad.', 'On Saturday I am going to Novi Sad.'],
          ['U petak radim do pet.', 'On Friday I work until five.'],
          ['Juče je bila nedelja.', 'Yesterday was Sunday.'],
          ['Vidimo se u sredu!', 'See you on Wednesday!'],
        ],
        gaps: [
          ['Vidimo se u ___!', 'subotu', 'subota petak', 'See you on Saturday!'],
          ['Danas je ___.', 'četvrtak', 'sreda nedelju', 'Today is Thursday.'],
          ['U ___ ne radim.', 'nedelju', 'nedelja ponedeljak', 'On Sunday I do not work.'],
        ],
        replies: [
          ['Kada se vidimo?', 'When shall we meet?', 'U sredu u šest.', ['U sreda u šest.', 'Juče, hvala.']],
          ['Koji je danas dan?', 'What day is it today?', 'Danas je petak.', ['Danas je juče.', 'Sutra, hvala.']],
        ],
        read: [{
          text: 'Ana radi od ponedeljka do petka. U subotu ide na pijacu, a u nedelju spava do deset.',
          q: 'What does Ana do on Sunday?', a: 'She sleeps until ten', wrong: ['She goes to the market', 'She works'],
          en: 'Ana works from Monday to Friday. On Saturday she goes to the market, and on Sunday she sleeps until ten.',
        }],
      },
    ],
  },
  {
    id: 'a1-around-town', title: 'Around town',
    subtitle: 'Places, directions, transport and tickets',
    outcomes: ['Name places in town', 'Ask for and follow directions', 'Say how you travel', 'Buy a ticket at the station'],
    checkpoint: { id: 'a1-around-town-around-town-review', title: 'Around town check', subtitle: 'Places, directions and tickets' },
    lessons: [
      {
        id: 'a1-around-town-places-in-town', title: 'Places in town', subtitle: 'In the park, at school', icon: '🏙️', color: 'blue',
        grammar: ['In and at: the locative', `Where are you? U parku, u školi, u gradu.
• masculine and neuter add ‑u: park → u parku, centar → u centru
• feminine ‑a becomes ‑i: škola → u školi, bolnica → u bolnici

Some places take na instead of u: na trgu, na pijaci, na pošti, na stanici. Learn which one goes with each word.`],
        words: 'škola = school | bolnica = hospital | park = park | kafić = café | trg = square | centar = centre | pijaca = market | crkva = church | prodavnica = shop | biblioteka = library',
        say: [
          ['Ja sam u parku.', 'I am in the park.'],
          ['Moja sestra radi u bolnici.', 'My sister works at the hospital.'],
          ['Kafić je na trgu.', 'The café is on the square.'],
          ['Idem na pijacu.', 'I am going to the market.'],
          ['Biblioteka je u centru.', 'The library is in the centre.'],
          ['Deca su u školi.', 'The children are at school.'],
        ],
        gaps: [
          ['Ana je u ___.', 'školi', 'škola parku', 'Ana is at school.'],
          ['Čekam te u ___.', 'parku', 'park školi', 'I am waiting for you in the park.'],
          ['Crkva je na ___.', 'trgu', 'trg centru', 'The church is on the square.'],
        ],
        replies: [
          ['Gde si?', 'Where are you?', 'U kafiću, na trgu.', ['U kafić, na trg.', 'Dobro sam.']],
          ['Gde radi tvoj brat?', 'Where does your brother work?', 'Radi u bolnici.', ['Radi u bolnica.', 'On je brat.']],
        ],
        read: [{
          text: 'Moj grad nije veliki. U centru je trg, a na trgu su crkva i kafić. Bolnica je blizu parka.',
          q: 'What is on the square?', a: 'A church and a café', wrong: ['A hospital', 'A park'],
          en: 'My town is not big. In the centre there is a square, and on the square there are a church and a café. The hospital is near the park.',
        }],
      },
      {
        id: 'a1-around-town-left-and-right', title: 'Left and right', subtitle: 'Asking for directions', icon: '➡️', color: 'green',
        grammar: ['Polite commands', `Directions use the polite command form, which ends in ‑ite:
• idite — go
• skrenite — turn
• pitajte — ask

Idite pravo — go straight. Skrenite levo — turn left. Na semaforu — at the traffic lights.

Start with Izvinite, gde je…? (Excuse me, where is…?)`],
        words: 'levo = left | desno = right | pravo = straight on | idite = go (polite) | skrenite = turn (polite) | ulica = street | raskrsnica = crossroads | semafor = traffic light | most = bridge | na uglu = on the corner',
        say: [
          ['Idite pravo, pa skrenite levo.', 'Go straight on, then turn left.'],
          ['Pošta je na uglu.', 'The post office is on the corner.'],
          ['Skrenite desno na semaforu.', 'Turn right at the traffic light.'],
          ['Idite preko mosta.', 'Go across the bridge.'],
          ['Moja ulica je blizu.', 'My street is close.'],
        ],
        gaps: [
          ['___ levo na raskrsnici.', 'Skrenite', 'Idite Pravo', 'Turn left at the crossroads.'],
          ['Idite ___ do semafora.', 'pravo', 'levo desno', 'Go straight on to the traffic light.'],
          ['Apoteka je na ___.', 'uglu', 'ulica semaforu', 'The pharmacy is on the corner.'],
        ],
        replies: [
          ['Izvinite, gde je bolnica?', 'Excuse me, where is the hospital?', 'Idite pravo, pa desno.', ['Idem pravo, hvala.', 'Bolnica je lekar.']],
          ['Da li je daleko?', 'Is it far?', 'Ne, blizu je. Pet minuta.', ['Ne, daleko je blizu.', 'Da, pet godina.']],
        ],
        read: [{
          text: 'Od hotela idite pravo do semafora. Na semaforu skrenite levo. Muzej je na uglu, pored banke.',
          q: 'Where should you turn left?', a: 'At the traffic light', wrong: ['At the hotel', 'At the bank'],
          en: 'From the hotel go straight on to the traffic light. At the traffic light turn left. The museum is on the corner, next to the bank.',
        }],
      },
      {
        id: 'a1-around-town-public-transport', title: 'By bus or by train?', subtitle: 'Getting around', icon: '🚌', color: 'orange',
        grammar: ['How you travel', `Serbian needs no word for "by". The noun takes a new ending, ‑om or ‑em:
• autobus → autobusom
• voz → vozom
• tramvaj → tramvajem
• taksi → taksijem

On foot is peške. By car is usually kolima.`],
        words: 'autobus = bus | tramvaj = tram | voz = train | autobusom = by bus | vozom = by train | peške = on foot | stanica = stop / station | vozač = driver | putujem = I travel',
        say: [
          ['Idem na posao autobusom.', 'I go to work by bus.'],
          ['Gde je autobuska stanica?', 'Where is the bus stop?'],
          ['Putujem vozom u Niš.', 'I am travelling to Niš by train.'],
          ['Danas idem peške.', 'Today I am walking.'],
          ['Vozač je ljubazan.', 'The driver is kind.'],
        ],
        gaps: [
          ['Idem u školu ___.', 'tramvajem', 'tramvaj vozom', 'I go to school by tram.'],
          ['Putujemo ___.', 'vozom', 'voz autobusom', 'We are travelling by train.'],
          ['Čekam autobus na ___.', 'stanici', 'stanica uglu', 'I am waiting for the bus at the stop.'],
        ],
        replies: [
          ['Kako ideš na posao?', 'How do you get to work?', 'Autobusom ili peške.', ['Autobus ili peške.', 'Posao je dobar.']],
          ['Da li ovaj autobus ide u centar?', 'Does this bus go to the centre?', 'Da, ide u centar.', ['Da, idem u centar.', 'Ne, ja sam vozač.']],
        ],
        read: [{
          text: 'Jelena živi daleko od centra. Ujutru ide autobusom, a uveče tramvajem. Kada je lepo vreme, ide peške.',
          q: 'How does Jelena travel when the weather is nice?', a: 'On foot', wrong: ['By bus', 'By tram'],
          en: 'Jelena lives far from the centre. In the morning she goes by bus, and in the evening by tram. When the weather is nice, she walks.',
        }],
      },
      {
        id: 'a1-around-town-at-the-station', title: 'At the station', subtitle: 'Tickets, platforms and delays', icon: '🚉', color: 'pink',
        grammar: ['Buying a ticket', `Jednu kartu za Novi Sad, molim. Karta becomes kartu because it is the thing you are buying.

Ask Kada polazi voz? (When does the train leave?) and Sa kog perona? (From which platform?)

On the boards: polazak = departure, dolazak = arrival, kasni = delayed.`],
        words: 'karta = ticket | povratna karta = return ticket | peron = platform | polazak = departure | dolazak = arrival | kasni = is late | polazi = leaves | stiže = arrives | blagajna = ticket office | za = to / for',
        say: [
          ['Jednu kartu za Novi Sad, molim.', 'One ticket to Novi Sad, please.'],
          ['Kada polazi voz?', 'When does the train leave?'],
          ['Voz kasni deset minuta.', 'The train is ten minutes late.'],
          ['Autobus stiže u šest.', 'The bus arrives at six.'],
          ['Blagajna je levo.', 'The ticket office is on the left.'],
        ],
        gaps: [
          ['Jednu ___ za Niš, molim.', 'kartu', 'karta peron', 'One ticket to Niš, please.'],
          ['Voz polazi sa ___ dva.', 'perona', 'peron stanica', 'The train leaves from platform two.'],
          ['Voz ___ dvadeset minuta.', 'kasni', 'stiže polazi', 'The train is twenty minutes late.'],
        ],
        replies: [
          ['Sa kog perona polazi voz?', 'Which platform does the train leave from?', 'Sa perona tri.', ['Sa peron tri.', 'U tri sata, hvala.']],
          ['Povratnu kartu?', 'A return ticket?', 'Da, povratnu, molim.', ['Da, povratna, molim.', 'Ne, kasni.']],
        ],
        read: [{
          text: 'POLAZAK\nNovi Sad — 8.15 — peron 2\nNiš — 9.40 — peron 5 — kasni 10 minuta',
          audio: 'Polazak. Novi Sad, osam i petnaest, peron dva. Niš, devet i četrdeset, peron pet, kasni deset minuta.',
          q: 'Which train is late?', a: 'The train to Niš', wrong: ['The train to Novi Sad', 'Both trains'],
          en: 'Departures: Novi Sad 8:15, platform 2. Niš 9:40, platform 5, ten minutes late.',
        }],
      },
    ],
  },
  {
    id: 'a1-family-home', title: 'Family & home',
    subtitle: 'Family, my and your, rooms and people',
    outcomes: ['Talk about your family', 'Use moj, tvoj, njegov, njen', 'Describe your home', 'Describe what people are like'],
    checkpoint: { id: 'a1-personal-world-personal-details-review', title: 'Family & home check', subtitle: 'Family, possessives and home' },
    lessons: [
      {
        id: 'family', title: 'My family', subtitle: 'Parents, children and partners', icon: '🏡', color: 'green',
        grammar: ['Moj, moja, moje, moji', `"My" agrees with the noun it describes:
• moj otac, moj brat — masculine
• moja majka, moja sestra — feminine
• moje dete — neuter
• moji roditelji — plural

Mama and tata are the everyday words for mum and dad. Žena means both "woman" and "wife".`],
        words: 'porodica = family | majka = mother | otac = father | roditelji = parents | brat = brother | sestra = sister | sin = son | ćerka = daughter | muž = husband | žena = wife / woman',
        say: [
          ['Ovo je moja porodica.', 'This is my family.'],
          ['Moj otac je lekar.', 'My father is a doctor.'],
          ['Imam jednog sina i jednu ćerku.', 'I have one son and one daughter.'],
          ['Moji roditelji žive u Nišu.', 'My parents live in Niš.'],
          ['Moja žena se zove Ana.', 'My wife is called Ana.'],
        ],
        gaps: [
          ['___ otac je programer.', 'Moj', 'Moja Moji', 'My father is a programmer.'],
          ['___ sestra živi u Londonu.', 'Moja', 'Moj Moje', 'My sister lives in London.'],
          ['___ roditelji su ovde.', 'Moji', 'Moj Moja', 'My parents are here.'],
        ],
        replies: [
          ['Imaš li brata ili sestru?', 'Do you have a brother or a sister?', 'Imam jednu sestru.', ['Imam jedna sestra.', 'Ja sam sestra.']],
          ['Kako se zove tvoja majka?', "What is your mother's name?", 'Moja majka se zove Vesna.', ['Moj majka se zove Vesna.', 'Ona je majka.']],
        ],
        read: [{
          text: 'Zovem se Marko. Moja porodica nije velika: otac, majka, sestra i ja. Moja sestra ima muža i sina. Njen sin se zove Luka.',
          q: 'Who is Luka?', a: "Marko's sister's son", wrong: ["Marko's father", "Marko's brother"],
          en: 'My name is Marko. My family is not big: father, mother, sister and me. My sister has a husband and a son. Her son is called Luka.',
        }],
      },
      {
        id: 'possessives', title: 'Whose is it?', subtitle: 'My, your, his, her', icon: '🔑', color: 'purple',
        grammar: ['Possessives agree', `Possessives behave like adjectives: tvoj brat, tvoja sestra, tvoje ime.

Njegov (his) and njen (her) depend on the owner. Their ending matches the thing owned:
• njegova majka — his mother
• njen otac — her father

Vaš is also the polite "your": Kako je Vaše ime?`],
        words: 'moj = my | tvoj = your | njegov = his | njen = her | naš = our | vaš = your (plural / formal) | njihov = their | čiji = whose | ime = name',
        say: [
          ['Da li je ovo tvoja torba?', 'Is this your bag?'],
          ['Njegova sestra je lekarka.', 'His sister is a doctor.'],
          ['Njen brat živi u Americi.', 'Her brother lives in America.'],
          ['Njena kuća je mala.', 'Her house is small.'],
          ['Čiji je ovo telefon?', 'Whose phone is this?'],
          ['Kako je Vaše ime?', 'What is your name?'],
        ],
        gaps: [
          ['To je ___ otac.', 'njen', 'njena njegova', 'That is her father.'],
          ['Ovo je ___ majka.', 'njegova', 'njegov njena', 'This is his mother.'],
          ['___ kuća je velika.', 'Naša', 'Naš Vaše', 'Our house is big.'],
        ],
        replies: [
          ['Čiji je ovo ključ?', 'Whose key is this?', 'To je moj ključ.', ['To je moja ključ.', 'Ključ je na stolu.']],
          ['Da li je ovo vaša kuća?', 'Is this your house?', 'Da, to je naša kuća.', ['Da, to je naš kuća.', 'Ne, ja sam kuća.']],
        ],
      },
      {
        id: 'a1-personal-world-my-home', title: 'My home', subtitle: 'Rooms and where things are', icon: '🏠', color: 'blue',
        grammar: ['In the kitchen', `The locative again:
• feminine ‑a → ‑i: u kuhinji, u sobi
• masculine and neuter add ‑u: u stanu, u kupatilu
• kuća → u kući

Vrata (door) is always plural: Vrata su zelena.

A Serbian flat almost always has a terasa!`],
        words: 'kuća = house | stan = flat | soba = room | kuhinja = kitchen | kupatilo = bathroom | dnevna soba = living room | spavaća soba = bedroom | prozor = window | vrata = door | terasa = balcony',
        say: [
          ['Živim u malom stanu.', 'I live in a small flat.'],
          ['Mama je u kuhinji.', 'Mum is in the kitchen.'],
          ['Moj stan ima dve sobe.', 'My flat has two rooms.'],
          ['Kupatilo je desno.', 'The bathroom is on the right.'],
          ['Sedimo na terasi.', 'We are sitting on the balcony.'],
        ],
        gaps: [
          ['Tata je u ___.', 'kupatilu', 'kupatilo kuhinji', 'Dad is in the bathroom.'],
          ['Knjige su u ___.', 'sobi', 'soba stanu', 'The books are in the room.'],
          ['Vrata ___ zelena.', 'su', 'je smo', 'The door is green.'],
        ],
        replies: [
          ['Gde je kupatilo?', 'Where is the bathroom?', 'Pravo, pa levo.', ['Kupatilo je moj brat.', 'Da, imam kupatilo.']],
          ['Kakav je tvoj stan?', 'What is your flat like?', 'Mali, ali lep.', ['Mala, ali lepa.', 'U Beogradu.']],
        ],
        read: [{
          text: 'Naš stan je na trećem spratu. Ima kuhinju, kupatilo, dnevnu sobu i dve spavaće sobe. Najlepša je terasa!',
          q: 'What is the nicest part of the flat?', a: 'The balcony', wrong: ['The kitchen', 'The living room'],
          en: 'Our flat is on the third floor. It has a kitchen, a bathroom, a living room and two bedrooms. The nicest part is the balcony!',
        }],
      },
      {
        id: 'a1-personal-world-people-i-know', title: 'What are they like?', subtitle: 'Describing people', icon: '👫', color: 'pink',
        grammar: ['A disappearing a', `Some adjectives drop an a when they add an ending:
• ljubazan → ljubazna
• pametan → pametna
• zabavan → zabavna
• nizak → niska (the z becomes s, too)

Describe hair and eyes with imati: Ona ima dugu kosu i plave oči. Kosa becomes kosu, the ‑u for objects again.`],
        words: 'visok = tall | nizak = short | mlad = young | ljubazan = kind | zabavan = fun | pametan = clever | kosa = hair | oči = eyes | duga kosa = long hair | kratka kosa = short hair',
        say: [
          ['Moj brat je visok.', 'My brother is tall.'],
          ['Ona ima dugu kosu.', 'She has long hair.'],
          ['Moja baka je ljubazna.', 'My grandmother is kind.'],
          ['Marko je pametan i zabavan.', 'Marko is clever and fun.'],
          ['On ima plave oči.', 'He has blue eyes.'],
        ],
        gaps: [
          ['Jelena je ___.', 'pametna', 'pametan visok', 'Jelena is clever.'],
          ['Moja sestra je ___.', 'visoka', 'visok mlad', 'My sister is tall.'],
          ['On ima kratku ___.', 'kosu', 'kosa oči', 'He has short hair.'],
        ],
        replies: [
          ['Kakva je tvoja nastavnica?', 'What is your teacher like?', 'Ljubazna je i zabavna.', ['Ljubazan je i zabavan.', 'Ona je u školi.']],
          ['Kako izgleda tvoj brat?', 'What does your brother look like?', 'Visok je i ima kratku kosu.', ['Visoka je i ima kratka kosa.', 'Moj brat je u parku.']],
        ],
        read: [{
          text: 'Moja prijateljica Ana je visoka i ima dugu kosu. Ona je veoma pametna i zabavna. Njen brat je nizak, ali je ljubazan.',
          q: 'Who is short?', a: "Ana's brother", wrong: ['Ana', "Ana's friend"],
          en: 'My friend Ana is tall and has long hair. She is very clever and fun. Her brother is short, but he is kind.',
        }],
      },
    ],
  },
  {
    id: 'a1-free-time', title: 'Free time',
    subtitle: 'Likes, hobbies, invitations and messages',
    outcomes: ['Say what you like and dislike', 'Talk about hobbies', 'Make and answer invitations', 'Handle calls and short messages'],
    checkpoint: { id: 'a1-social-life-review', title: 'Free time check', subtitle: 'Likes, plans and messages' },
    lessons: [
      {
        id: 'a1-social-life-likes-and-dislikes', title: 'I love it!', subtitle: 'Likes and dislikes', icon: '❤️', color: 'pink',
        grammar: ['Volim vs sviđa mi se', `Volim takes an object, so feminine ‑a becomes ‑u: volim muziku, volim kafu, volim fudbal.

Sviđa mi se works the other way round. The thing is the subject and stays unchanged: Sviđa mi se muzika means "music is pleasing to me".

For plural things it's Sviđaju mi se filmovi.`],
        words: 'volim = I love / like | ne volim = I do not like | sviđa mi se = I like it | muzika = music | film = film | sport = sport | fudbal = football | kuvanje = cooking | ples = dancing | mnogo = a lot',
        say: [
          ['Volim muziku i ples.', 'I love music and dancing.'],
          ['Ne volim fudbal.', 'I do not like football.'],
          ['Sviđa mi se ovaj film.', 'I like this film.'],
          ['Mnogo volim kuvanje.', 'I really love cooking.'],
          ['Da li voliš sport?', 'Do you like sport?'],
        ],
        gaps: [
          ['Volim ___.', 'muziku', 'muzika mnogo', 'I love music.'],
          ['Sviđa mi se ___.', 'muzika', 'muziku volim', 'I like the music.'],
          ['Da li ___ kafu?', 'voliš', 'volim voli', 'Do you like coffee?'],
        ],
        replies: [
          ['Da li voliš fudbal?', 'Do you like football?', 'Ne, ne volim sport.', ['Ne, ne voliš sport.', 'Da, ja sam fudbal.']],
          ['Kako ti se sviđa Beograd?', 'How do you like Belgrade?', 'Mnogo mi se sviđa!', ['Mnogo mi volim!', 'Ja sam iz Beograda.']],
        ],
        read: [{
          text: 'Miloš voli sport, posebno fudbal. Zara ne voli fudbal, ali mnogo voli muziku i ples. Oboje vole kuvanje.',
          q: 'What do Miloš and Zara both like?', a: 'Cooking', wrong: ['Football', 'Dancing'],
          en: 'Miloš loves sport, especially football. Zara does not like football, but she really loves music and dancing. They both love cooking.',
        }],
      },
      {
        id: 'a1-daily-rhythm-hobbies-and-free-time', title: 'Hobbies', subtitle: 'What do you do for fun?', icon: '🎾', color: 'green',
        grammar: ['Hobby verbs', `Šta radiš u slobodno vreme? — What do you do in your free time?

Most hobby verbs are regular:
• ‑am: igram, slušam, čitam, plivam
• ‑im: trčim
• ‑ujem: putujem. Verbs in ‑ovati become ‑ujem: putovati → putujem, kupovati → kupujem.

Say how often: često (often), ponekad (sometimes), nikad ne (never).`],
        words: 'slobodno vreme = free time | igram = I play | slušam = I listen | čitam = I read | plivam = I swim | trčim = I run | slikam = I paint | vikend = weekend | često = often | ponekad = sometimes',
        say: [
          ['U slobodno vreme čitam knjige.', 'In my free time I read books.'],
          ['Za vikend igram fudbal.', 'At the weekend I play football.'],
          ['Često slušam muziku.', 'I often listen to music.'],
          ['Ana pliva i trči.', 'Ana swims and runs.'],
          ['Ponekad slikam.', 'Sometimes I paint.'],
        ],
        gaps: [
          ['Često ___ muziku.', 'slušam', 'čitam igram', 'I often listen to music.'],
          ['Moj brat ___ fudbal.', 'igra', 'igram slušam', 'My brother plays football.'],
          ['U slobodno ___ slikam.', 'vreme', 'vikend često', 'In my free time I paint.'],
        ],
        replies: [
          ['Šta radiš u slobodno vreme?', 'What do you do in your free time?', 'Čitam i slušam muziku.', ['Čita i sluša muziku.', 'U sedam sati.']],
          ['Igraš li tenis?', 'Do you play tennis?', 'Ne, ali često plivam.', ['Ne, ali često plivaš.', 'Tenis je skup sto.']],
        ],
        read: [{
          text: 'Nikola ima mnogo hobija. Ponedeljkom igra fudbal, sredom pliva, a petkom svira gitaru. Za vikend često putuje.',
          q: 'When does Nikola swim?', a: 'On Wednesdays', wrong: ['On Mondays', 'At the weekend'],
          en: 'Nikola has many hobbies. On Mondays he plays football, on Wednesdays he swims, and on Fridays he plays the guitar. At the weekend he often travels.',
        }],
      },
      {
        id: 'a1-social-life-invitations', title: 'Invitations', subtitle: 'Yes, no and maybe', icon: '💌', color: 'orange',
        grammar: ['Inviting and answering', `Invite with Hoćeš li…? (do you want to…?) or simply Idemo na kafu? (shall we go for coffee?).

Say yes with Može! (sure) or Važi! (deal). Say no kindly: Žao mi je, ne mogu.

Going somewhere uses u / na plus the ‑u ending: idemo u bioskop, na žurku, na kafu.`],
        words: 'hoćeš li = do you want to? | idemo = let\'s go | može = sure / OK | ne mogu = I cannot | žao mi je = I am sorry | večeras = tonight | bioskop = cinema | žurka = party | na kafu = for a coffee | slobodan sam = I am free (man)',
        say: [
          ['Idemo na kafu?', 'Shall we go for a coffee?'],
          ['Hoćeš li u bioskop večeras?', 'Do you want to go to the cinema tonight?'],
          ['Žao mi je, ne mogu.', 'I am sorry, I cannot.'],
          ['Može, vidimo se u osam!', 'Sure, see you at eight!'],
          ['U subotu je žurka kod Ane.', 'On Saturday there is a party at Ana\'s.'],
        ],
        gaps: [
          ['Idemo na ___?', 'kafu', 'kafa žurka', 'Shall we go for a coffee?'],
          ['Žao mi je, ne ___.', 'mogu', 'može idemo', 'I am sorry, I cannot.'],
          ['Hoćeš li na ___ u subotu?', 'žurku', 'žurka bioskop', 'Do you want to come to the party on Saturday?'],
        ],
        replies: [
          ['Idemo u bioskop večeras?', 'Shall we go to the cinema tonight?', 'Može! U koliko sati?', ['Može! Koliko godina?', 'Zovem se Ana.']],
          ['Hoćeš li na žurku u subotu?', 'Do you want to come to the party on Saturday?', 'Žao mi je, u subotu radim.', ['Žao mi je, ja sam žurka.', 'Može, juče.']],
        ],
        read: [{
          text: 'Ćao Ana! Hoćeš li u bioskop u petak? Film počinje u osam. Miloš',
          q: 'When does the film start?', a: 'At eight', wrong: ['On Saturday', 'At half past seven'],
          en: 'Hi Ana! Do you want to go to the cinema on Friday? The film starts at eight. Miloš',
        }],
      },
      {
        id: 'a1-social-life-on-the-phone', title: 'Calls and messages', subtitle: 'Hello? I\'m running late!', icon: '📱', color: 'purple',
        grammar: ['Friendly commands', `On the phone Serbs answer with Halo? or Molim?

Informal commands often end in ‑i: piši (write), zovi (call), javi se (get in touch).

Polite and plural forms add ‑te: pišite, zovite.

Messages are short: Kasnim 5 minuta! Stižem! Čujemo se!`],
        words: 'halo = hello (on the phone) | ko je = who is it? | poruka = message | piši mi = write to me | zovi me = call me | kasnim = I am late | stižem = I am on my way | čujemo se = talk soon | broj telefona = phone number | odmah = right away',
        say: [
          ['Halo, ko je to?', 'Hello, who is it?'],
          ['Kasnim deset minuta.', 'I am ten minutes late.'],
          ['Zovi me sutra.', 'Call me tomorrow.'],
          ['Piši mi poruku.', 'Send me a message.'],
          ['Stižem odmah!', 'I am coming right away!'],
        ],
        gaps: [
          ['___ me večeras!', 'Zovi', 'Piši Kasnim', 'Call me tonight!'],
          ['Izvini, ___ pet minuta.', 'kasnim', 'stižem zovi', 'Sorry, I am five minutes late.'],
          ['Koji je tvoj broj ___?', 'telefona', 'telefon poruka', 'What is your phone number?'],
        ],
        replies: [
          ['Halo?', 'Hello?', 'Ćao, ovde Marko!', ['Laku noć, poruka!', 'Doviđenja!']],
          ['Gde si? Čekam te!', 'Where are you? I am waiting for you!', 'Izvini, kasnim! Stižem odmah.', ['Izvini, kasni! Stiže odmah.', 'Dobro jutro, čekam.']],
        ],
        read: [{
          text: 'Poruka od Jelene: Ćao! Kasnim petnaest minuta, autobus kasni. Naruči mi kafu, molim te! Stižem.',
          q: 'Why is Jelena late?', a: 'Her bus is late', wrong: ['She overslept', 'She is at work'],
          en: 'Message from Jelena: Hi! I am fifteen minutes late, the bus is late. Order me a coffee, please! On my way.',
        }],
      },
    ],
  },
  {
    id: 'a1-plans', title: 'Plans',
    subtitle: 'The future, must and can, trips and travel',
    outcomes: ['Talk about the future with ću', 'Use moram, mogu and hoću', 'Plan a weekend trip', 'Check in at a hotel'],
    checkpoint: { id: 'a1-plans-memories-plans-and-memories-review', title: 'Plans check', subtitle: 'Future, modals and travel' },
    lessons: [
      {
        id: 'a1-plans-memories-future-with--u', title: 'I will…', subtitle: 'The future with ću', icon: '🔮', color: 'green',
        grammar: ['The future', `The future uses ću, ćeš, će, ćemo, ćete, će plus the verb.

When the verb comes first and ends in ‑ti, the ‑ti drops and the two fuse:
• raditi → radiću
• videti → videćemo
• biti → biću

Verbs in ‑ći keep a space: ići ću, doći ću.

With a pronoun or another word first: Ja ću raditi. Sutra ću raditi.`],
        words: 'radiću = I will work | ići ću = I will go | biću = I will be | videćemo = we will see | posetiću = I will visit | ostaću = I will stay | sledeće nedelje = next week | plan = plan | odmor = holiday | kod kuće = at home',
        say: [
          ['Sutra ću raditi.', 'Tomorrow I will work.'],
          ['Ići ću u Novi Sad sledeće nedelje.', 'I will go to Novi Sad next week.'],
          ['Ostaću kod kuće.', 'I will stay at home.'],
          ['Posetiću baku za vikend.', 'I will visit grandma at the weekend.'],
          ['Videćemo!', 'We will see!'],
        ],
        gaps: [
          ['Sutra ___ raditi.', 'ću', 'ćeš će', 'Tomorrow I will work.'],
          ['Da li ___ doći?', 'ćeš', 'ću će', 'Will you come?'],
          ['Marko ___ biti ovde.', 'će', 'ću ćeš', 'Marko will be here.'],
        ],
        replies: [
          ['Šta ćeš raditi za vikend?', 'What will you do at the weekend?', 'Posetiću roditelje.', ['Posetila sam roditelje.', 'Za vikend je subota.']],
          ['Hoćeš li biti kod kuće večeras?', 'Will you be at home tonight?', 'Da, biću kod kuće.', ['Da, bio sam kod kuće.', 'Kod kuće je stan.']],
        ],
        read: [{
          text: 'Sledeće nedelje Zara ide na odmor. Prvo će posetiti prijatelje u Beogradu, a onda će putovati na more.',
          q: 'Where will Zara go after Belgrade?', a: 'To the seaside', wrong: ['Home', 'To her parents'],
          en: 'Next week Zara is going on holiday. First she will visit friends in Belgrade, and then she will travel to the seaside.',
        }],
      },
      {
        id: 'must-can', title: 'Must, can, want', subtitle: 'Moram, mogu, hoću', icon: '💪', color: 'blue',
        grammar: ['Modal verb + da', `Modal verbs take da plus a present-tense verb. This is the Serbian way of saying "to":
• Moram da radim — I must work
• Mogu da dođem — I can come
• Hoću da spavam — I want to sleep

Both verbs change for the person: Moraš da učiš.

Treba mi pomoć — "help is needed to me" — means I need help.`],
        words: 'moram = I must | mogu = I can | hoću = I want | moraš = you must | možeš = you can | treba mi = I need | ne moram = I do not have to | pomoć = help | posle = later / after',
        say: [
          ['Moram da radim sutra.', 'I have to work tomorrow.'],
          ['Mogu da dođem posle.', 'I can come later.'],
          ['Hoću da spavam!', 'I want to sleep!'],
          ['Treba mi pomoć.', 'I need help.'],
          ['Ne moraš da plaćaš.', 'You do not have to pay.'],
        ],
        gaps: [
          ['Moram ___ učim.', 'da', 'ne li', 'I have to study.'],
          ['___ da dođeš u petak?', 'Možeš', 'Mogu Moraš', 'Can you come on Friday?'],
          ['Treba ___ kafa!', 'mi', 'ti vi', 'I need coffee!'],
        ],
        replies: [
          ['Možeš li da mi pomogneš?', 'Can you help me?', 'Da, mogu. Šta treba?', ['Da, moram. Šta ima?', 'Ne znam gde je pošta.']],
          ['Zašto ne možeš na žurku?', 'Why can\'t you come to the party?', 'Moram da radim.', ['Moraš da radiš.', 'Zato što je žurka.']],
        ],
        read: [{
          text: 'Sutra ne mogu da idem na posao. Moram da idem kod lekara u devet. Posle mogu da radim od kuće.',
          q: "Why can't the writer go to work tomorrow?", a: "They have a doctor's appointment", wrong: ['They are on holiday', 'They have no car'],
          en: "Tomorrow I can't go to work. I have to go to the doctor at nine. Afterwards I can work from home.",
        }],
      },
      {
        id: 'weekend-plans', title: 'Weekend plans', subtitle: 'Mountains, rivers and birthdays', icon: '🏞️', color: 'orange',
        grammar: ['Going there vs being there', `Going to a place uses u / na plus the ‑u ending. Being there uses the locative:
• Idemo na planinu → Na planini smo.
• Idemo na more → Na moru smo.
• Idemo u selo → U selu smo.

And of course: Srećan rođendan! (Happy birthday!)`],
        words: 'izlet = trip / outing | planina = mountain | more = sea / seaside | reka = river | priroda = nature | rođendan = birthday | poklon = present | roštilj = barbecue | lepo vreme = nice weather',
        say: [
          ['U subotu idemo na izlet.', 'On Saturday we are going on a trip.'],
          ['Ako je lepo vreme, idemo na planinu.', 'If the weather is nice, we will go to the mountain.'],
          ['Leti idemo na more.', 'In summer we go to the seaside.'],
          ['Moj deda živi u selu.', 'My grandpa lives in a village.'],
          ['Kupiću joj poklon za rođendan.', 'I will buy her a present for her birthday.'],
          ['Pravimo roštilj kod reke.', 'We are having a barbecue by the river.'],
        ],
        gaps: [
          ['Idemo na ___.', 'planinu', 'planina planini', 'We are going to the mountain.'],
          ['Deca su u ___.', 'selu', 'selo moru', 'The children are in the village.'],
          ['Srećan ___!', 'rođendan', 'poklon izlet', 'Happy birthday!'],
        ],
        replies: [
          ['Gde ste sada?', 'Where are you now?', 'Na planini smo!', ['Na planinu smo!', 'Idemo na planinu sutra.']],
          ['Šta ćeš kupiti Ani za rođendan?', 'What will you buy Ana for her birthday?', 'Kupiću joj knjigu.', ['Kupio sam joj knjigu juče.', 'Rođendan je u subotu.']],
        ],
        read: [{
          text: 'Za vikend idemo na izlet na Taru. To je planina u zapadnoj Srbiji. Spavaćemo u selu, a u nedelju ćemo praviti roštilj kod reke.',
          q: 'Where will they sleep?', a: 'In a village', wrong: ['In a tent by the river', 'In Belgrade'],
          en: 'At the weekend we are going on a trip to Tara. It is a mountain in western Serbia. We will sleep in a village, and on Sunday we will have a barbecue by the river.',
        }],
      },
      {
        id: 'travel', title: 'At the hotel', subtitle: 'Reservations, passports and flights', icon: '🧳', color: 'pink',
        grammar: ['Checking in', `At reception: Imam rezervaciju na ime… (I have a reservation under the name…).

Imate li slobodnu sobu? (Do you have a free room?)

Za dve noći (for two nights): noć becomes noći after two, three and four.

You will need your pasoš at check-in.`],
        words: 'hotel = hotel | rezervacija = reservation | pasoš = passport | kofer = suitcase | aerodrom = airport | recepcija = reception | noć = night | dve noći = two nights | let = flight | turista = tourist',
        say: [
          ['Imam rezervaciju za dve noći.', 'I have a reservation for two nights.'],
          ['Gde je recepcija?', 'Where is reception?'],
          ['Idem na aerodrom taksijem.', 'I am going to the airport by taxi.'],
          ['Let kasni jedan sat.', 'The flight is one hour late.'],
          ['Izvolite, ovo je moj pasoš.', 'Here you are, this is my passport.'],
        ],
        gaps: [
          ['Imam ___ na ime Petrović.', 'rezervaciju', 'rezervacija recepcija', 'I have a reservation under the name Petrović.'],
          ['Za jednu ___, molim.', 'noć', 'noći let', 'For one night, please.'],
          ['Idem na ___.', 'aerodrom', 'hotel kofer', 'I am going to the airport.'],
        ],
        replies: [
          ['Dobar dan, izvolite?', 'Good afternoon, how can I help?', 'Dobar dan, imam rezervaciju.', ['Dobar dan, ja sam rezervacija.', 'Laku noć, imam kofer.']],
          ['Vaš pasoš, molim.', 'Your passport, please.', 'Izvolite.', ['Hvala, ne volim.', 'Moj pasoš je let.']],
        ],
        read: [{
          text: 'Hotel „Dunav“\nSoba za dve osobe: 6000 dinara za noć.\nDoručak je uključen.\nRecepcija radi non-stop.',
          audio: 'Hotel Dunav. Soba za dve osobe, šest hiljada dinara za noć. Doručak je uključen. Recepcija radi non-stop.',
          q: 'Is breakfast included?', a: 'Yes', wrong: ['No', 'Only at the weekend'],
          en: 'Hotel "Danube": a double room is 6000 dinars a night. Breakfast is included. Reception is open around the clock.',
        }],
      },
    ],
  },
  {
    id: 'a1-stories', title: 'Stories & health',
    subtitle: 'The past, a weekend story, weather and feeling ill',
    outcomes: ['Say what you did with the past tense', 'Tell a short weekend story', 'Talk about the weather', 'Say what hurts'],
    checkpoint: { id: 'a1-health-weather-review', title: 'Stories & health check', subtitle: 'Past, weather and health' },
    assessment: { id: 'a1-final-journey-a1-final-assessment', title: 'A1 knowledge check', subtitle: 'Reading, listening and replies from every unit' },
    lessons: [
      {
        id: 'a1-plans-memories-simple-past', title: 'Yesterday', subtitle: 'The past tense', icon: '🕰️', color: 'purple',
        grammar: ['Was, worked, went', `The past tense is sam / si / je… plus a past form that shows the speaker's gender:
• radio — a man
• radila — a woman
• radili — a group

So Kristina says Bila sam u Beogradu and Miloš says Bio sam u Beogradu.

Ići (to go) is irregular: išao / išla.

Word order: Ja sam radio, or without the pronoun, Radio sam.`],
        words: 'prošle nedelje = last week | bio sam = I was (man) | bila sam = I was (woman) | radio sam = I worked (man) | radila sam = I worked (woman) | gledao sam = I watched (man) | išao sam = I went (man) | išla sam = I went (woman) | video sam = I saw (man) | videla sam = I saw (woman)',
        say: [
          ['Juče sam bio u Novom Sadu.', 'Yesterday I was in Novi Sad.'],
          ['Bila sam umorna.', 'I was tired.'],
          ['Prošle nedelje sam mnogo radio.', 'Last week I worked a lot.'],
          ['Gledala sam dobar film.', 'I watched a good film.'],
          ['Išli smo u bioskop.', 'We went to the cinema.'],
          ['Video sam Marka u gradu.', 'I saw Marko in town.'],
        ],
        gaps: [
          ['Ana je ___ u Beogradu.', 'bila', 'bio bili', 'Ana was in Belgrade.'],
          ['Marko je ___ film.', 'gledao', 'gledala gleda', 'Marko watched a film.'],
          ['Juče ___ radila.', 'sam', 'si je', 'Yesterday I worked.'],
        ],
        replies: [
          ['Gde si bio juče?', 'Where were you yesterday? (to a man)', 'Bio sam kod kuće.', ['Bila si kod kuće.', 'Biću kod kuće.']],
          ['Šta si radila za vikend?', 'What did you do at the weekend? (to a woman)', 'Bila sam na moru.', ['Bio si na moru.', 'Idem na more.']],
        ],
        read: [{
          text: 'Juče je Kristina išla u grad. Prvo je bila u banci, a onda je videla prijateljicu i pile su kafu.',
          q: 'What did Kristina do after the bank?', a: 'She met a friend for coffee', wrong: ['She went home', 'She went to work'],
          en: 'Yesterday Kristina went into town. First she was at the bank, and then she saw a friend and they had coffee.',
        }],
      },
      {
        id: 'a1-plans-memories-a-weekend-story', title: 'A weekend story', subtitle: 'We went, we ate, it was fun', icon: '📖', color: 'orange',
        grammar: ['We were…', `The plural past uses smo / ste / su plus ‑li: bili smo, išli smo, jeli smo, pili smo.

To say how something was, use bilo je plus an ‑o word: Bilo je lepo! Bilo je zabavno. Bilo je dosadno.

This neuter ‑o form is how Serbian describes situations in general.`],
        words: 'bili smo = we were | išli smo = we went | jeli smo = we ate | pili smo = we drank | videli smo = we saw | bilo je = it was | lepo = nice | zabavno = fun | dosadno = boring | umorni = tired (plural)',
        say: [
          ['Bili smo na moru.', 'We were at the seaside.'],
          ['Bilo je mnogo zabavno!', 'It was a lot of fun!'],
          ['Jeli smo ribu i pili smo vino.', 'We ate fish and drank wine.'],
          ['Videli smo stari grad.', 'We saw the old town.'],
          ['Uveče smo bili umorni.', 'In the evening we were tired.'],
        ],
        gaps: [
          ['Bilo je ___!', 'lepo', 'lep lepa', 'It was nice!'],
          ['___ smo u Beograd.', 'Išli', 'Bili Jeli', 'We went to Belgrade.'],
          ['Šta ste ___ za večeru?', 'jeli', 'pili išli', 'What did you eat for dinner?'],
        ],
        replies: [
          ['Kako je bilo na moru?', 'How was the seaside?', 'Bilo je odlično!', ['Bio je odlično!', 'Idemo na more.']],
          ['Šta ste radili u subotu?', 'What did you do on Saturday?', 'Išli smo na izlet.', ['Idemo na izlet.', 'Išao smo na izlet.']],
        ],
        read: [{
          text: 'Prošlog vikenda smo bili na Zlatiboru. U subotu smo išli na planinu, a uveče smo jeli roštilj. U nedelju je padala kiša, pa smo bili u hotelu. Bilo je lepo, ali smo bili umorni.',
          q: 'What did they do on Sunday?', a: 'They stayed in the hotel because of the rain', wrong: ['They went up the mountain', 'They had a barbecue'],
          en: 'Last weekend we were on Zlatibor. On Saturday we went up the mountain, and in the evening we ate barbecue. On Sunday it rained, so we stayed in the hotel. It was nice, but we were tired.',
        }],
      },
      {
        id: 'a1-health-weather-weather-today', title: 'Weather', subtitle: 'Sun, rain and snow', icon: '☀️', color: 'blue',
        grammar: ['It is warm', `Weather sentences have no "it": Toplo je (it's warm), Hladno je, Sunčano je, Oblačno je. That's the ‑o form again.

Rain and snow "fall": Pada kiša, Pada sneg. Duva vetar means the wind blows.

Vreme means both "weather" and "time".

Seasons: proleće, leto, jesen, zima. "In summer" is leti, "in winter" is zimi.`],
        words: 'vreme = weather / time | sunčano = sunny | pada kiša = it is raining | pada sneg = it is snowing | toplo = warm | hladno = cold | vetar = wind | oblačno = cloudy | leto = summer | zima = winter',
        say: [
          ['Danas je sunčano i toplo.', 'Today it is sunny and warm.'],
          ['Pada kiša, ne idem napolje.', 'It is raining, I am not going out.'],
          ['Zimi je hladno i pada sneg.', 'In winter it is cold and it snows.'],
          ['Kakvo je vreme u Londonu?', 'What is the weather like in London?'],
          ['Duva jak vetar.', 'A strong wind is blowing.'],
        ],
        gaps: [
          ['Danas je ___.', 'sunčano', 'oblačno hladno', 'Today it is sunny.'],
          ['Pada ___.', 'sneg', 'kiša vetar', 'It is snowing.'],
          ['Leti je ___.', 'toplo', 'hladno zima', 'In summer it is warm.'],
        ],
        replies: [
          ['Kakvo je vreme danas?', 'What is the weather like today?', 'Oblačno je, ali toplo.', ['Oblačan sam, ali topao.', 'Danas je ponedeljak.']],
          ['Da li pada kiša?', 'Is it raining?', 'Ne, sunčano je.', ['Ne, sunčana je.', 'Kiša je moja sestra.']],
        ],
        read: [{
          text: 'Prognoza za sutra: ujutru oblačno, posle podne pada kiša. Uveče je hladno, oko pet stepeni.',
          q: 'What will the afternoon be like?', a: 'Rainy', wrong: ['Sunny', 'Snowy'],
          en: 'Forecast for tomorrow: cloudy in the morning, rain in the afternoon. Cold in the evening, around five degrees.',
        }],
      },
      {
        id: 'a1-health-weather-feeling-well-or-ill', title: 'At the doctor', subtitle: 'What hurts?', icon: '🤒', color: 'green',
        grammar: ['It hurts me', `Boli me glava — literally "the head hurts me". The body part is the subject, and me (me) stays the same:
• Boli me stomak
• Boli me grlo
• Boli me zub

Ask: Šta te boli? (What hurts?)

Ill: bolestan sam (man) / bolesna sam (woman). Imam temperaturu means I have a fever.`],
        words: 'boli me = it hurts (me) | glava = head | stomak = stomach | grlo = throat | zub = tooth | bolestan sam = I am ill (man) | bolesna sam = I am ill (woman) | lek = medicine | prehlada = a cold | temperatura = fever / temperature',
        say: [
          ['Boli me glava.', 'I have a headache.'],
          ['Bolesna sam, imam temperaturu.', 'I am ill, I have a fever.'],
          ['Treba mi lek za grlo.', 'I need medicine for my throat.'],
          ['Šta te boli?', 'What hurts?'],
          ['Moj sin ima prehladu.', 'My son has a cold.'],
        ],
        gaps: [
          ['Boli me ___.', 'zub', 'glava lek', 'My tooth hurts.'],
          ['Marko je ___.', 'bolestan', 'bolesna umorna', 'Marko is ill.'],
          ['Imam ___.', 'temperaturu', 'temperatura prehlada', 'I have a fever.'],
        ],
        replies: [
          ['Šta te boli?', 'What hurts?', 'Boli me stomak.', ['Boli ja stomak.', 'Bolim stomak.']],
          ['Kako si danas?', 'How are you today?', 'Nisam dobro, bolestan sam.', ['Nisam dobro, bolestan si.', 'Odlično, boli me glava.']],
        ],
        read: [{
          text: 'Zara je bolesna. Boli je grlo i ima temperaturu. Ide u apoteku i kupuje lek. Danas ne ide na posao.',
          q: "Why isn't Zara going to work?", a: 'She is ill', wrong: ['It is raining', 'It is the weekend'],
          en: 'Zara is ill. Her throat hurts and she has a fever. She goes to the pharmacy and buys medicine. Today she is not going to work.',
        }],
      },
    ],
  },
];
