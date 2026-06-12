import 'package:flutter/material.dart';

class FirstAidScreen extends StatefulWidget {
  const FirstAidScreen({super.key});

  @override
  State<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  final List<FirstAidGuide> _allGuides = [
    FirstAidGuide(
      title: 'CPR (Cardiopulmonary Resuscitation)',
      description: 'Perform when someone is unconscious and not breathing normally.',
      steps: [
        'Call emergency services.',
        'Place the heel of your hand on the center of the person\'s chest.',
        'Place the other hand on top and interlock fingers.',
        'Push hard and fast (100-120 compressions per minute).',
        'Give 2 rescue breaths after every 30 compressions if trained.',
        'Continue until help arrives or the person breathes normally.',
      ],
      icon: Icons.favorite,
    ),
    FirstAidGuide(
      title: 'Choking',
      description: 'Perform Heimlich maneuver if someone cannot breathe, cough, or speak.',
      steps: [
        'Stand behind the person.',
        'Place one foot slightly in front of the other for balance.',
        'Wrap your arms around their waist.',
        'Make a fist with one hand and place it slightly above their navel.',
        'Grasp your fist with your other hand.',
        'Perform quick, upward thrusts as if trying to lift the person in the air.',
      ],
      icon: Icons.restaurant,
    ),
    FirstAidGuide(
      title: 'Burns',
      description: 'Immediate action to reduce tissue damage.',
      steps: [
        'Cool the burn under cool running water for at least 10-20 minutes.',
        'Remove any tight clothing or jewelry near the burn.',
        'Do NOT apply ice, butter, or ointment directly to a major burn.',
        'Cover the burn loosely with a sterile, non-fluffy dressing or cling film.',
        'Seek medical help if the burn is severe or larger than the victim\'s hand.',
      ],
      icon: Icons.local_fire_department,
    ),
    FirstAidGuide(
      title: 'Severe Bleeding',
      description: 'How to stop critical blood loss.',
      steps: [
        'Apply direct, firm pressure to the wound with a clean cloth.',
        'Keep applying pressure constantly.',
        'If blood soaks through, do NOT remove the cloth; add more on top.',
        'Elevate the injured area if possible.',
        'Call emergency services immediately.',
      ],
      icon: Icons.bloodtype,
    ),
    FirstAidGuide(
      title: 'Heart Attack',
      description: 'Signs and immediate response.',
      steps: [
        'Call emergency services immediately.',
        'Have the person sit down, rest, and try to keep calm.',
        'Loosen any tight clothing.',
        'If they have prescribed chest-pain medication (e.g. nitroglycerin), help them take it.',
        'If not allergic, have them chew an aspirin.',
        'Begin CPR if they become unconscious and stop breathing.',
      ],
      icon: Icons.monitor_heart,
    ),
  ];

  List<FirstAidGuide> _filteredGuides = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredGuides = _allGuides;
    _searchController.addListener(_filterGuides);
  }

  void _filterGuides() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredGuides = _allGuides
          .where((guide) => guide.title.toLowerCase().contains(query) || guide.description.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('First Aid Guide'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search for emergencies...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _filteredGuides.isEmpty
                ? const Center(child: Text('No guides found.'))
                : ListView.builder(
                    itemCount: _filteredGuides.length,
                    itemBuilder: (context, index) {
                      final guide = _filteredGuides[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ExpansionTile(
                          leading: Icon(guide.icon, color: Theme.of(context).primaryColor, size: 36),
                          title: Text(guide.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(guide.description),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: guide.steps
                                    .asMap()
                                    .entries
                                    .map((entry) => Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${entry.key + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                              Expanded(child: Text(entry.value)),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class FirstAidGuide {
  final String title;
  final String description;
  final List<String> steps;
  final IconData icon;

  FirstAidGuide({
    required this.title,
    required this.description,
    required this.steps,
    required this.icon,
  });
}
