import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  await Hive.openBox('workoutBox');
  await Hive.openBox('settingsBox');

  runApp(const WorkoutLogApp());
}

class WorkoutLogApp extends StatelessWidget {
  const WorkoutLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Logbook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.deepPurpleAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          surface: Color(0xFF1E1E1E),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// --- SCHERMATA INIZIALE ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _sleepQuality = 7.0;

  void _startWorkout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Check-in Recupero',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Come hai dormito stanotte?',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${_sleepQuality.toInt()} / 10',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent),
                  ),
                  Slider(
                    value: _sleepQuality,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: Colors.deepPurpleAccent,
                    onChanged: (val) => setModalState(() => _sleepQuality = val),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkoutScreen(sleepScore: _sleepQuality.toInt()),
                          ),
                        );
                      },
                      child: const Text('Inizia Allenamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('workoutBox');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Il Mio Logbook', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.history, color: Colors.deepPurpleAccent),
                          SizedBox(width: 10),
                          Text('Ultimi Workout Salvati', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 24),
                      Expanded(
                        child: box.isEmpty
                            ? const Center(
                                child: Text(
                                  'Nessun allenamento registrato.\nTocca il tasto in basso per iniziare!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: box.length,
                                itemBuilder: (context, index) {
                                  var session = box.getAt(index);
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text('Sessione del ${session['date']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('Sonno: ${session['sleep']}/10 - Esercizi loggati'),
                                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.fitness_center, size: 24),
                label: const Text('Avvia Nuova Sessione', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: () => _startWorkout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- SCHERMATA ALLENAMENTO ---
class WorkoutScreen extends StatefulWidget {
  final int sleepScore;
  const WorkoutScreen({super.key, required this.sleepScore});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final List<String> _routine = [
    'Panca Piana',
    'Chest-Supported High Row',
    'Squat',
  ];

  final Map<String, List<Map<String, dynamic>>> _sessionData = {};

  void _saveSession() {
    var box = Hive.box('workoutBox');
    String dateStr = DateTime.now().toString().substring(0, 10);
    
    box.add({
      'date': dateStr,
      'sleep': widget.sleepScore,
      'data': _sessionData,
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Allenamento salvato con successo! 🎉'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout (Sonno: ${widget.sleepScore}/10)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.green),
            onPressed: _saveSession,
            tooltip: 'Salva Sessione',
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _routine.length,
        itemBuilder: (context, index) {
          String exerciseName = _routine[index];
          return ExerciseCard(
            exerciseName: exerciseName,
            onSetsUpdated: (sets) {
              _sessionData[exerciseName] = sets;
            },
          );
        },
      ),
    );
  }
}

// --- CARD ESERCIZIO OTTIMIZZATA ---
class ExerciseCard extends StatefulWidget {
  final String exerciseName;
  final Function(List<Map<String, dynamic>>) onSetsUpdated;

  const ExerciseCard({super.key, required this.exerciseName, required this.onSetsUpdated});

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  final TextEditingController _repsCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  String _selectedIntensity = 'Buffer';
  int _selectedSatisfaction = 4;
  final List<Map<String, dynamic>> _sets = [];

  void _addSet() {
    if (_repsCtrl.text.isEmpty || _weightCtrl.text.isEmpty) return;

    setState(() {
      final setInfo = {
        'weight': double.parse(_weightCtrl.text),
        'reps': int.parse(_repsCtrl.text),
        'intensity': _selectedIntensity,
        'satisfaction': _selectedSatisfaction,
      };
      _sets.add(setInfo);
      _repsCtrl.clear();
      _weightCtrl.clear();
      widget.onSetsUpdated(_sets);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.exerciseName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 16),
            
            ..._sets.asMap().entries.map((e) {
              int idx = e.key + 1;
              var data = e.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    Text('Set $idx: ${data['weight']} kg x ${data['reps']} (${data['intensity']})', 
                         style: const TextStyle(fontWeight: FontWeight.w500)),
                    Row(
                      children: List.generate(
                        data['satisfaction'], 
                        (index) => const Icon(Icons.star, color: Colors.amber, size: 14),
                      ),
                    ),
                  ],
                ),
              );
            }),

            if (_sets.isNotEmpty) const Divider(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Kg', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _repsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Reps', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Buffer', label: Text('Buffer')),
                    ButtonSegment(value: 'Cedimento', label: Text('Cedimento')),
                  ],
                  selected: {_selectedIntensity},
                  onSelectionChanged: (val) => setState(() => _selectedIntensity = val.first),
                ),
                DropdownButton<int>(
                  value: _selectedSatisfaction,
                  items: [1, 2, 3, 4, 5].map((s) => DropdownMenuItem(value: s, child: Text('$s ★'))).toList(),
                  onChanged: (val) => setState(() => _selectedSatisfaction = val!),
                ),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: _addSet,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
